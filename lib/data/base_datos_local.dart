import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

/// Esquema compartido de cuentas y registros del negocio; migra sin borrar datos.
class BaseDatosLocal {
  BaseDatosLocal({DatabaseFactory? factory, this.ruta})
    : _factory = factory ?? databaseFactory;
  final DatabaseFactory _factory;
  final String? ruta;
  Future<Database>? _apertura;
  Future<Database> get abrir =>
      _apertura ??= _abrir().catchError((Object error) {
        _apertura = null;
        throw error;
      });
  Future<Database> _abrir() async {
    final ubicacion =
        ruta ?? path.join(await _factory.getDatabasesPath(), 'finanzasist.db');
    return _factory.openDatabase(
      ubicacion,
      options: OpenDatabaseOptions(
        version: 4,
        onUpgrade: (db, anterior, actual) async {
          if (anterior < 2) await _crearGastos(db);
          if (anterior < 3) await _crearCuentas(db);
          if (anterior < 4) await _crearGuias(db);
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
        },
      ),
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

  Future<void> cerrar() async {
    final apertura = _apertura;
    _apertura = null;
    if (apertura != null) await (await apertura).close();
  }
}
