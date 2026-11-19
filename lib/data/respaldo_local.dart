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

/// Exporta y restaura el archivo SQLite completo de este dispositivo.
/// Si hay cuentas registradas, ambas acciones exigen una sesión válida.
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

  static String nombreArchivo(DateTime fecha) {
    String dos(int n) => n.toString().padLeft(2, '0');
    return 'finanzasist-respaldo-${fecha.year}-${dos(fecha.month)}-'
        '${dos(fecha.day)}-${dos(fecha.hour)}${dos(fecha.minute)}.db';
  }

  /// En un dispositivo sin cuentas se puede restaurar desde la pantalla de
  /// acceso; con cuentas, solo el propietario con sesión iniciada.
  Future<bool> restauracionSinSesion() async =>
      !await _hayCuentas(await base.abrir);

  Future<Uint8List> exportar({SesionEmpresa? sesion}) async {
    await _autorizar(sesion);
    try {
      return await base.leerArchivo();
    } on FileSystemException {
      throw const RespaldoException(
        'No pudimos leer los datos para exportarlos. Inténtalo de nuevo.',
      );
    }
  }

  /// Reemplaza todos los datos del dispositivo por los del respaldo.
  /// Si el archivo no es válido, los datos actuales quedan intactos.
  Future<void> restaurar(Uint8List bytes, {SesionEmpresa? sesion}) async {
    _verificarArchivo(bytes);
    await _autorizar(sesion);
    final candidato = '${await base.ubicacion}.restaurando';
    try {
      await File(candidato).writeAsBytes(bytes, flush: true);
      await _validar(candidato);
      await base.reemplazarArchivo(candidato);
    } on DatabaseException {
      throw const RespaldoException(_danado);
    } on FileSystemException {
      throw const RespaldoException(
        'No pudimos guardar el respaldo en el dispositivo. '
        'Revisa el espacio disponible e inténtalo de nuevo.',
      );
    } finally {
      final archivo = File(candidato);
      if (await archivo.exists()) await archivo.delete();
      await BaseDatosLocal.borrarAuxiliares(candidato);
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

  Future<bool> _hayCuentas(DatabaseExecutor db) async =>
      (await db.query('cuentas', columns: ['id'], limit: 1)).isNotEmpty;

  Future<void> _autorizar(SesionEmpresa? sesion) async {
    final db = await base.abrir;
    if (!await _hayCuentas(db)) return;
    if (sesion == null) {
      throw const RespaldoException('Inicia sesión para usar los respaldos.');
    }
    try {
      await sesion.verificar(db);
    } on AccesoException catch (error) {
      throw RespaldoException(error.mensaje);
    }
    // El respaldo copia la base entera: con varias empresas expondría o
    // borraría los datos de las demás.
    final cuentas =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM cuentas WHERE rol = ?', [
            RolCuenta.propietario.name,
          ]),
        ) ??
        0;
    if (cuentas > 1) {
      throw const RespaldoException(
        'Este dispositivo tiene varias empresas. Los respaldos solo están '
        'disponibles cuando hay una sola cuenta.',
      );
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
        if (!existentes.containsAll(esperadas)) {
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
