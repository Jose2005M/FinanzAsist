import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

/// Esquema compartido de cuentas y registros del negocio; migra sin borrar datos.
class BaseDatosLocal {
  BaseDatosLocal({DatabaseFactory? factory, this.ruta})
    : factory = factory ?? databaseFactory;

  /// Versión del esquema que crea y entiende esta compilación.
  static const version = 6;
  static const _auxiliares = ['-wal', '-shm', '-journal'];

  final DatabaseFactory factory;
  final String? ruta;
  Future<Database>? _apertura;
  Future<void>? _mantenimiento;

  Future<String> get ubicacion async =>
      ruta ?? path.join(await factory.getDatabasesPath(), 'finanzasist.db');

  /// Espera a que termine una exportación o restauración antes de abrir.
  Future<Database> get abrir async {
    while (_mantenimiento != null) {
      await _mantenimiento;
    }
    return _apertura ??= _abrir().catchError((Object error) {
      _apertura = null;
      throw error;
    });
  }

  Future<Database> _abrir() async {
    return factory.openDatabase(
      await ubicacion,
      options: OpenDatabaseOptions(
        version: version,
        onUpgrade: (db, anterior, actual) async {
          if (anterior < 2) await _crearGastos(db);
          if (anterior < 3) await _crearCuentas(db);
          if (anterior < 4) await _crearGuias(db);
          if (anterior < 5) await _agregarRol(db);
          if (anterior < 6) await _usuariosPorEmpresa(db);
        },
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: (db, version) async {
          await db.execute('CREATE TABLE empresas (id TEXT PRIMARY KEY)');
          await db.execute(
            'CREATE TABLE usuarios (empresa TEXT NOT NULL, id TEXT NOT NULL, PRIMARY KEY (empresa, id), FOREIGN KEY (empresa) REFERENCES empresas(id))',
          );
          await db.execute(
            'CREATE TABLE productos (empresa TEXT NOT NULL, id TEXT NOT NULL, nombre TEXT NOT NULL, cantidad INTEGER NOT NULL CHECK(cantidad >= 0), costo INTEGER NOT NULL CHECK(costo >= 0), precio INTEGER NOT NULL CHECK(precio >= 0), PRIMARY KEY (empresa, id), FOREIGN KEY (empresa) REFERENCES empresas(id))',
          );
          await db.execute(
            'CREATE TABLE operaciones (empresa TEXT NOT NULL, id TEXT NOT NULL, usuario TEXT NOT NULL, tipo TEXT NOT NULL, fecha TEXT NOT NULL, datos TEXT NOT NULL, PRIMARY KEY (empresa, id), FOREIGN KEY (empresa, usuario) REFERENCES usuarios(empresa, id))',
          );
          await db.execute(
            'CREATE TABLE movimientos (empresa TEXT NOT NULL, operacion TEXT NOT NULL, producto TEXT NOT NULL, usuario TEXT NOT NULL, fecha TEXT NOT NULL, tipo TEXT NOT NULL, cantidad INTEGER NOT NULL, saldo INTEGER NOT NULL CHECK(saldo >= 0), motivo TEXT NOT NULL, PRIMARY KEY (empresa, operacion, producto), FOREIGN KEY (empresa, producto) REFERENCES productos(empresa, id), FOREIGN KEY (empresa, operacion) REFERENCES operaciones(empresa, id), FOREIGN KEY (empresa, usuario) REFERENCES usuarios(empresa, id))',
          );
          await _crearGastos(db);
          await _crearCuentas(db);
          await _crearGuias(db);
          await _agregarRol(db);
          await _usuariosPorEmpresa(db);
        },
      ),
    );
  }

  /// Versión 6: empleados de una empresa y un único propietario por empresa.
  /// onCreate/onUpgrade ya están dentro de una transacción con FK activas.
  Future<void> _usuariosPorEmpresa(DatabaseExecutor db) async {
    await db.execute('DROP INDEX IF EXISTS un_administrador');
    final esquema = await db.rawQuery(
      "SELECT sql FROM sqlite_master WHERE type = 'table' AND name = 'cuentas'",
    );
    final actualizado = (esquema.single['sql'] as String).contains(
      "'encargado'",
    );
    if (!actualizado) {
      final administradores = await db.query(
        'cuentas',
        columns: ['id', 'empresa', 'usuario'],
        where: "rol = 'administrador'",
      );
      for (final administrador in administradores) {
        await db.delete(
          'guias_vistas',
          where: 'cuenta = ?',
          whereArgs: [administrador['id']],
        );
        await db.delete(
          'cuentas',
          where: 'id = ?',
          whereArgs: [administrador['id']],
        );
        await db.delete(
          'usuarios',
          where: 'empresa = ? AND id = ?',
          whereArgs: [administrador['empresa'], administrador['usuario']],
        );
        await db.rawDelete(
          '''DELETE FROM empresas WHERE id = ?
          AND NOT EXISTS (SELECT 1 FROM usuarios WHERE empresa = empresas.id)
          AND NOT EXISTS (SELECT 1 FROM productos WHERE empresa = empresas.id)''',
          [administrador['empresa']],
        );
      }
      await db.execute('''CREATE TABLE cuentas_v6 (
        id TEXT PRIMARY KEY,
        empresa TEXT NOT NULL,
        usuario TEXT NOT NULL,
        nombre_empresa TEXT NOT NULL,
        nombre TEXT NOT NULL,
        correo TEXT NOT NULL UNIQUE COLLATE NOCASE,
        sal TEXT NOT NULL,
        hash TEXT NOT NULL,
        iteraciones INTEGER NOT NULL CHECK(iteraciones >= 600000),
        activa INTEGER NOT NULL DEFAULT 1 CHECK(activa IN (0, 1)),
        rol TEXT NOT NULL DEFAULT 'propietario'
          CHECK(rol IN ('propietario', 'encargado', 'vendedor', 'consulta')),
        FOREIGN KEY(empresa, usuario) REFERENCES usuarios(empresa, id)
      )''');
      await db.execute(
        '''INSERT INTO cuentas_v6
        (id, empresa, usuario, nombre_empresa, nombre, correo, sal, hash, iteraciones, activa, rol)
        SELECT id, empresa, usuario, nombre_empresa, nombre, correo, sal, hash, iteraciones, activa, rol FROM cuentas''',
      );
      // foreign_keys=OFF no surte efecto dentro de una transacción, y diferir
      // las FK tampoco basta: al borrar `cuentas` cada guía cuenta como una
      // violación que la tabla renombrada no compensa y el COMMIT falla.
      // Se apartan las guías, se reconstruye su tabla padre y se reinsertan.
      final guias = await db.query('guias_vistas');
      await db.delete('guias_vistas');
      await db.execute('DROP TABLE cuentas');
      await db.execute('ALTER TABLE cuentas_v6 RENAME TO cuentas');
      for (final guia in guias) {
        await db.insert('guias_vistas', guia);
      }
    }
    await db.execute(
      "CREATE UNIQUE INDEX IF NOT EXISTS un_propietario_por_empresa ON cuentas(empresa) WHERE rol = 'propietario'",
    );
  }

  /// Versión 5: las cuentas existentes quedan como propietarias y el índice
  /// parcial permite un solo administrador por dispositivo.
  Future<void> _agregarRol(DatabaseExecutor db) async {
    final columnas = await db.rawQuery('PRAGMA table_info(cuentas)');
    if (!columnas.any((columna) => columna['name'] == 'rol')) {
      await db.execute(
        "ALTER TABLE cuentas ADD COLUMN rol TEXT NOT NULL DEFAULT 'propietario' CHECK(rol IN ('propietario', 'administrador'))",
      );
    }
    await db.execute(
      "CREATE UNIQUE INDEX IF NOT EXISTS un_administrador ON cuentas(rol) WHERE rol = 'administrador'",
    );
  }

  Future<void> _crearGastos(DatabaseExecutor db) => db.execute(
    'CREATE TABLE gastos (empresa TEXT NOT NULL, id TEXT NOT NULL, usuario TEXT NOT NULL, fecha TEXT NOT NULL, concepto TEXT NOT NULL, categoria TEXT NOT NULL, valor INTEGER NOT NULL CHECK(valor > 0), registrado TEXT NOT NULL, PRIMARY KEY (empresa, id), FOREIGN KEY (empresa, usuario) REFERENCES usuarios(empresa, id))',
  );

  Future<void> _crearGuias(DatabaseExecutor db) => db.execute('''
    CREATE TABLE IF NOT EXISTS guias_vistas (
      cuenta TEXT NOT NULL,
      modulo TEXT NOT NULL,
      PRIMARY KEY (cuenta, modulo),
      FOREIGN KEY (cuenta) REFERENCES cuentas(id)
    )
  ''');

  Future<void> _crearCuentas(DatabaseExecutor db) => db.execute('''
    CREATE TABLE cuentas (
      id TEXT PRIMARY KEY,
      empresa TEXT NOT NULL UNIQUE,
      usuario TEXT NOT NULL,
      nombre_empresa TEXT NOT NULL,
      nombre TEXT NOT NULL,
      correo TEXT NOT NULL UNIQUE COLLATE NOCASE,
      sal TEXT NOT NULL,
      hash TEXT NOT NULL,
      iteraciones INTEGER NOT NULL CHECK(iteraciones >= 600000),
      activa INTEGER NOT NULL DEFAULT 1 CHECK(activa IN (0, 1)),
      FOREIGN KEY(empresa, usuario) REFERENCES usuarios(empresa, id)
    )
  ''');

  /// Ejecuta [accion] con el archivo cerrado. Las transacciones en curso
  /// terminan antes y nadie puede abrir la base hasta que [accion] acabe.
  Future<T> conArchivoCerrado<T>(
    Future<T> Function(String ubicacion) accion,
  ) async {
    while (_mantenimiento != null) {
      await _mantenimiento;
    }
    final fin = Completer<void>();
    _mantenimiento = fin.future;
    try {
      // Una apertura fallida no tiene nada que cerrar.
      final db = await _apertura?.then<Database?>(
        (db) => db,
        onError: (Object _) => null,
      );
      _apertura = null;
      if (db != null) {
        // La transacción vacía espera a que terminen las que están en curso.
        await db.transaction((_) async {});
        await db.close();
      }
      return await accion(await ubicacion);
    } finally {
      _mantenimiento = null;
      fin.complete();
    }
  }

  /// Copia completa y consistente del archivo de la base.
  Future<Uint8List> leerArchivo() =>
      conArchivoCerrado((ubicacion) => File(ubicacion).readAsBytes());

  /// Sustituye la base por el archivo [candidato] y aplica las migraciones.
  /// Si la nueva base no abre, recupera el archivo anterior.
  Future<void> reemplazarArchivo(String candidato) =>
      conArchivoCerrado((destino) async {
        final actual = File(destino);
        final anterior = File('$destino.anterior');
        final habiaArchivo = await actual.exists();
        if (habiaArchivo) await actual.copy(anterior.path);
        try {
          await borrarAuxiliares(destino);
          await File(candidato).copy(destino);
          await (await _abrir()).close();
        } catch (_) {
          await borrarAuxiliares(destino);
          if (habiaArchivo) {
            await anterior.copy(destino);
          } else if (await actual.exists()) {
            await actual.delete();
          }
          rethrow;
        } finally {
          if (await anterior.exists()) await anterior.delete();
        }
      });

  /// Borra los archivos de diario y WAL que SQLite deja junto a [ubicacion].
  static Future<void> borrarAuxiliares(String ubicacion) async {
    for (final sufijo in _auxiliares) {
      final archivo = File('$ubicacion$sufijo');
      if (await archivo.exists()) await archivo.delete();
    }
  }

  Future<void> cerrar() async {
    final apertura = _apertura;
    _apertura = null;
    if (apertura != null) await (await apertura).close();
  }
}
