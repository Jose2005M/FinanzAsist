import 'dart:io';
import 'dart:typed_data';

import 'package:sqflite/sqflite.dart';

import 'autenticacion_local.dart';
import 'base_datos_local.dart';

class RespaldoException implements Exception {
  const RespaldoException(this.mensaje);
  final String mensaje;
  @override
  String toString() => mensaje;
}

/// Exporta y restaura exclusivamente los datos de una empresa.
/// Desde el acceso solo agrega empresas que todavía no estén en el teléfono.
class RespaldoLocal {
  RespaldoLocal({
    required this.base,
    this.tamanoMaximo = tamanoMaximoPredeterminado,
  });

  static const tamanoMaximoPredeterminado = 100 * 1024 * 1024;
  static const _encabezado = 'SQLite format 3\u0000';
  static const _noEsRespaldo = 'El archivo no es un respaldo de FinanzAsist.';
  static const _danado =
      'El respaldo está dañado o incompleto. Prueba con otra copia.';

  /// Columnas que la aplicación lee de cada tabla y versión que la creó.
  static const _esquema = <String, (int, List<String>)>{
    'empresas': (1, ['id']),
    'usuarios': (1, ['empresa', 'id']),
    'productos': (
      1,
      ['empresa', 'id', 'nombre', 'cantidad', 'costo', 'precio'],
    ),
    'operaciones': (1, ['empresa', 'id', 'usuario', 'tipo', 'fecha', 'datos']),
    'movimientos': (
      1,
      [
        'empresa',
        'operacion',
        'producto',
        'usuario',
        'fecha',
        'tipo',
        'cantidad',
        'saldo',
        'motivo',
      ],
    ),
    'gastos': (
      2,
      [
        'empresa',
        'id',
        'usuario',
        'fecha',
        'concepto',
        'categoria',
        'valor',
        'registrado',
      ],
    ),
    'cuentas': (
      3,
      [
        'id',
        'empresa',
        'usuario',
        'nombre_empresa',
        'nombre',
        'correo',
        'sal',
        'hash',
        'iteraciones',
        'activa',
      ],
    ),
    'guias_vistas': (4, ['cuenta', 'modulo']),
  };

  /// Columnas añadidas después de crear su tabla: (tabla, columna, versión).
  static const _columnasAgregadas = [('cuentas', 'rol', 5)];

  final BaseDatosLocal base;
  final int tamanoMaximo;

  static String nombreArchivo(String empresa, DateTime fecha) {
    var nombre = empresa.toLowerCase();
    const acentos = 'áàäâéèëêíìïîóòöôúùüûñ';
    const simples = 'aaaaeeeeiiiioooouuuun';
    for (var i = 0; i < acentos.length; i++) {
      nombre = nombre.replaceAll(acentos[i], simples[i]);
    }
    nombre = nombre
        .replaceAll(RegExp(r'[\u0300-\u036f]'), '')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-');
    if (nombre.length > 40) nombre = nombre.substring(0, 40);
    nombre = nombre.replaceAll(RegExp(r'^-+|-+$'), '');
    if (nombre.isEmpty) nombre = 'empresa';
    String dos(int n) => n.toString().padLeft(2, '0');
    return 'finanzasist-$nombre-${fecha.year}-${dos(fecha.month)}-'
        '${dos(fecha.day)}-${dos(fecha.hour)}${dos(fecha.minute)}.db';
  }

  Future<bool> restauracionSinSesion() async {
    await base.abrir;
    return true;
  }

  // Orden de inserción según las claves foráneas del esquema vigente.
  static const _tablas = [
    'empresas',
    'usuarios',
    'cuentas',
    'productos',
    'operaciones',
    'movimientos',
    'gastos',
    'guias_vistas',
  ];

  Future<Directory> _temporal() async {
    final carpeta = File(await base.ubicacion).parent;
    await carpeta.create(recursive: true);
    // createTemp crea la carpeta DENTRO de `carpeta`, con este prefijo.
    return carpeta.createTemp('finanzasist-respaldo-');
  }

  Future<Map<String, List<Map<String, Object?>>>> _leerEmpresa(
    DatabaseExecutor db,
    String empresa,
  ) async {
    final filas = <String, List<Map<String, Object?>>>{};
    for (final tabla in _tablas) {
      filas[tabla] = await db.query(
        tabla,
        where: tabla == 'empresas'
            ? 'id = ?'
            : tabla == 'guias_vistas'
            ? 'cuenta IN (SELECT id FROM cuentas WHERE empresa = ? AND rol <> \'administrador\')'
            : tabla == 'cuentas'
            ? "empresa = ? AND rol <> 'administrador'"
            : 'empresa = ?',
        whereArgs: [empresa],
      );
    }
    return filas;
  }

  Future<void> _insertar(
    DatabaseExecutor db,
    Map<String, List<Map<String, Object?>>> filas, {
    bool conservarEmpresa = false,
  }) async {
    for (final tabla in _tablas) {
      if (conservarEmpresa && tabla == 'empresas') continue;
      for (final fila in filas[tabla]!) {
        await db.insert(tabla, fila);
      }
    }
  }

  Future<Uint8List> exportar({SesionEmpresa? sesion}) async {
    final db = await base.abrir;
    final filas = await db.transaction((tx) async {
      await _autorizar(tx, sesion);
      return _leerEmpresa(tx, sesion!.empresaId);
    });
    Directory? temporal;
    BaseDatosLocal? copia;
    try {
      temporal = await _temporal();
      copia = BaseDatosLocal(
        factory: base.factory,
        ruta: '${temporal.path}/empresa.db',
      );
      await (await copia.abrir).transaction((tx) => _insertar(tx, filas));
      return await copia.leerArchivo();
    } on DatabaseException {
      throw const RespaldoException(_danado);
    } on FileSystemException {
      throw const RespaldoException(
        'No pudimos leer los datos para exportarlos. Inténtalo de nuevo.',
      );
    } finally {
      try {
        await copia?.cerrar();
      } finally {
        if (temporal != null) await temporal.delete(recursive: true);
      }
    }
  }

  Future<void> restaurar(Uint8List bytes, {SesionEmpresa? sesion}) async {
    _verificarArchivo(bytes);
    final destino = await base.abrir;
    if (sesion != null) {
      await destino.transaction((tx) => _autorizar(tx, sesion));
    }
    Directory? temporal;
    BaseDatosLocal? copia;
    try {
      temporal = await _temporal();
      final ruta = '${temporal.path}/empresa.db';
      await File(ruta).writeAsBytes(bytes, flush: true);
      await _validar(ruta);
      copia = BaseDatosLocal(factory: base.factory, ruta: ruta);
      final origen = await copia.abrir;
      final empresas = await origen.rawQuery('''
        SELECT e.id FROM empresas e
        WHERE NOT EXISTS (SELECT 1 FROM cuentas c
          WHERE c.empresa = e.id AND c.rol = 'administrador')
        AND (EXISTS (SELECT 1 FROM usuarios u WHERE u.empresa = e.id)
          OR EXISTS (SELECT 1 FROM productos p WHERE p.empresa = e.id))
      ''');
      if (empresas.length > 1) {
        throw const RespaldoException(
          'El respaldo contiene varias empresas. Usa un respaldo de una sola empresa.',
        );
      }
      if (empresas.isEmpty) throw const RespaldoException(_noEsRespaldo);
      final empresa = empresas.single['id'];
      if (empresa is! String) throw const RespaldoException(_noEsRespaldo);
      final filas = await _leerEmpresa(origen, empresa);
      final tienePropietario = filas['cuentas']!.any(
        (c) => c['rol'] == 'propietario',
      );
      // Todo el trabajo de archivo termina antes de modificar el teléfono.
      await copia.cerrar();
      copia = null;
      await temporal.delete(recursive: true);
      temporal = null;
      await destino.transaction((tx) async {
        if (sesion != null) {
          await _autorizar(tx, sesion);
          if (sesion.empresaId != empresa) {
            throw const RespaldoException('Este respaldo es de otra empresa');
          }
        }
        if (!tienePropietario && (sesion != null || await _hayCuentas(tx))) {
          throw const RespaldoException(
            'Este respaldo antiguo sin propietario solo se puede restaurar en un teléfono sin cuentas.',
          );
        }
        final existe = (await tx.query(
          'empresas',
          where: 'id = ?',
          whereArgs: [empresa],
        )).isNotEmpty;
        if (sesion == null && existe) {
          throw const RespaldoException(
            'Esta empresa ya está en el teléfono. Inicia sesión como su propietario para restaurarla',
          );
        }
        // Comprueba también ids globales: nunca reemplazar cuentas ajenas.
        for (final cuenta in filas['cuentas']!) {
          final choque = await tx.query(
            'cuentas',
            columns: ['id'],
            where: '(empresa <> ? OR rol = ?) AND (correo = ? COLLATE NOCASE OR id = ?)',
            whereArgs: [
              empresa,
              'administrador',
              cuenta['correo'],
              cuenta['id'],
            ],
          );
          if (choque.isNotEmpty) {
            throw const RespaldoException(
              'Un correo o identificador del respaldo ya pertenece a otra cuenta del teléfono.',
            );
          }
        }
        if (sesion != null) {
          await tx.delete(
            'guias_vistas',
            where: 'cuenta IN (SELECT id FROM cuentas WHERE empresa = ?)',
            whereArgs: [empresa],
          );
          for (final tabla in [
            'movimientos',
            'operaciones',
            'gastos',
            'productos',
            'cuentas',
            'usuarios',
          ]) {
            await tx.delete(tabla, where: 'empresa = ?', whereArgs: [empresa]);
          }
        }
        await _insertar(tx, filas, conservarEmpresa: existe);
      });
    } on DatabaseException {
      throw const RespaldoException(_danado);
    } on FileSystemException {
      throw const RespaldoException(
        'No pudimos guardar el respaldo en el dispositivo. Revisa el espacio disponible e inténtalo de nuevo.',
      );
    } finally {
      try {
        await copia?.cerrar();
      } finally {
        if (temporal != null) await temporal.delete(recursive: true);
      }
    }
  }

  void _verificarArchivo(Uint8List bytes) {
    if (bytes.isEmpty) throw const RespaldoException('El archivo está vacío.');
    if (bytes.length > tamanoMaximo) {
      throw const RespaldoException(
        'El archivo es demasiado grande para ser un respaldo de FinanzAsist.',
      );
    }
    final encabezado = _encabezado.codeUnits;
    if (bytes.length < encabezado.length) {
      throw const RespaldoException(_noEsRespaldo);
    }
    for (var i = 0; i < encabezado.length; i++) {
      if (bytes[i] != encabezado[i]) {
        throw const RespaldoException(_noEsRespaldo);
      }
    }
  }

  /// Cuentas de algún negocio; el administrador del dispositivo no cuenta.
  Future<bool> _hayCuentas(DatabaseExecutor db) async => (await db.query(
    'cuentas',
    columns: ['id'],
    where: 'rol <> ?',
    whereArgs: [RolCuenta.administrador.name],
    limit: 1,
  )).isNotEmpty;

  Future<void> _autorizar(DatabaseExecutor db, SesionEmpresa? sesion) async {
    if (sesion == null) {
      throw const RespaldoException(
        'Inicia sesión como propietario para usar los respaldos.',
      );
    }
    try {
      await sesion.verificar(db, permiso: Permiso.gestionarRespaldos);
    } on AccesoException catch (error) {
      throw RespaldoException(error.mensaje);
    }
  }

  Future<void> _validar(String ruta) async {
    final db = await base.factory.openDatabase(ruta);
    try {
      final integridad = await db.rawQuery('PRAGMA integrity_check');
      if (integridad.length != 1 || integridad.single.values.single != 'ok') {
        throw const RespaldoException(_danado);
      }
      final version =
          Sqflite.firstIntValue(await db.rawQuery('PRAGMA user_version')) ?? 0;
      if (version > BaseDatosLocal.version) {
        throw const RespaldoException(
          'El respaldo se creó con una versión más nueva de FinanzAsist. '
          'Actualiza la aplicación para restaurarlo.',
        );
      }
      if (version < 1) throw const RespaldoException(_noEsRespaldo);
      final tablas = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type = 'table' AND name NOT LIKE 'sqlite_%'",
      );
      if (tablas.any(
        (t) =>
            !_esquema.containsKey(t['name']) && t['name'] != 'android_metadata',
      )) {
        throw const RespaldoException(_noEsRespaldo);
      }
      // Nunca ejecutar disparadores provenientes de un archivo externo al migrarlo.
      if ((await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type IN ('trigger', 'view')",
      )).isNotEmpty) {
        throw const RespaldoException(_noEsRespaldo);
      }
      for (final MapEntry(key: tabla, value: (desde, columnas))
          in _esquema.entries) {
        if (version < desde) continue;
        // El nombre de la tabla proviene de la constante, no del archivo.
        final esperadas = [
          ...columnas,
          for (final (otra, columna, agregada) in _columnasAgregadas)
            if (otra == tabla && version >= agregada) columna,
        ];
        final info = await db.rawQuery('PRAGMA table_info("$tabla")');
        final existentes = info.map((columna) => columna['name']).toSet();
        if (existentes.length != esperadas.length ||
            !existentes.containsAll(esperadas)) {
          throw const RespaldoException(_noEsRespaldo);
        }
      }
      if ((await db.rawQuery('PRAGMA foreign_key_check')).isNotEmpty) {
        throw const RespaldoException(_danado);
      }
    } finally {
      await db.close();
    }
  }
}
