import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../models/operacion.dart';
import 'base_datos_local.dart';
import 'claves.dart';

class AccesoException implements Exception {
  const AccesoException(this.mensaje);
  final String mensaje;
  @override
  String toString() => mensaje;
}

/// El propietario gestiona su negocio; el administrador solo las cuentas.
enum RolCuenta { propietario, administrador }

class DatosRegistro {
  static const longitudMinimaClave = 8;
  static const longitudMaximaClave = 128;

  const DatosRegistro({
    required this.empresa,
    required this.propietario,
    required this.correo,
    required this.clave,
  });
  final String empresa;
  final String propietario;
  final String correo;
  final String clave;

  static String normalizarCorreo(String valor) => valor.trim().toLowerCase();
  static String? validarCorreo(String? valor) {
    final correo = normalizarCorreo(valor ?? '');
    if (correo.isEmpty) return 'Escribe tu correo electrónico.';
    if (correo.length > 254 ||
        !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(correo)) {
      return 'Escribe un correo válido, como nombre@empresa.com.';
    }
    return null;
  }

  static String? validarNombre(String? valor, String campo, int maximo) {
    final nombre = (valor ?? '').trim();
    if (nombre.isEmpty) return 'Escribe $campo.';
    if (nombre.runes.length < 2 || nombre.runes.length > maximo) {
      return 'Usa entre 2 y $maximo caracteres.';
    }
    return null;
  }

  static String? validarClave(String? valor) {
    final longitud = (valor ?? '').runes.length;
    if (longitud < longitudMinimaClave || longitud > longitudMaximaClave) {
      return 'Usa entre $longitudMinimaClave y $longitudMaximaClave caracteres.';
    }
    return null;
  }

  void validar() {
    for (final error in [
      validarNombre(empresa, 'el nombre de la empresa', 120),
      validarNombre(propietario, 'tu nombre', 100),
      validarCorreo(correo),
      validarClave(clave),
    ]) {
      if (error != null) throw AccesoException(error);
    }
  }
}

class DatosAdministrador {
  const DatosAdministrador({
    required this.nombre,
    required this.correo,
    required this.clave,
  });
  final String nombre;
  final String correo;
  final String clave;

  void validar() {
    for (final error in [
      DatosRegistro.validarNombre(nombre, 'el nombre del administrador', 100),
      DatosRegistro.validarCorreo(correo),
      DatosRegistro.validarClave(clave),
    ]) {
      if (error != null) throw AccesoException(error);
    }
  }
}

/// Solo AutenticacionLocal puede emitir una sesión. Se revoca en memoria
/// y se verifica contra la cuenta dentro de cada transacción.
class SesionEmpresa {
  SesionEmpresa._(Map<String, Object?> row)
    : cuentaId = row['id'] as String,
      empresaId = row['empresa'] as String,
      usuarioId = row['usuario'] as String,
      empresa = row['nombre_empresa'] as String,
      propietario = row['nombre'] as String,
      correo = row['correo'] as String,
      rol = RolCuenta.values.byName(row['rol'] as String);

  final String cuentaId;
  final String empresaId;
  final String usuarioId;
  final String empresa;
  final String propietario;
  final String correo;
  final RolCuenta rol;
  bool _activa = true;

  bool get esAdministrador => rol == RolCuenta.administrador;

  /// Acceso a los datos del negocio: solo para propietarios.
  Future<void> verificar(DatabaseExecutor db) => _verificar(
    db,
    RolCuenta.propietario,
    'La cuenta de administrador no accede a los datos de los negocios.',
  );

  /// Gestión de cuentas: solo para el administrador.
  Future<void> verificarAdministrador(DatabaseExecutor db) => _verificar(
    db,
    RolCuenta.administrador,
    'Solo el administrador puede gestionar las cuentas.',
  );

  Future<void> _verificar(
    DatabaseExecutor db,
    RolCuenta esperado,
    String sinPermiso,
  ) async {
    if (!_activa) {
      throw const AccesoException('Tu sesión terminó. Inicia sesión.');
    }
    if (rol != esperado) throw AccesoException(sinPermiso);
    final cuentas = await db.query(
      'cuentas',
      columns: ['id'],
      where:
          'id = ? AND empresa = ? AND usuario = ? AND rol = ? AND activa = 1',
      whereArgs: [cuentaId, empresaId, usuarioId, rol.name],
    );
    if (!_activa || cuentas.isEmpty) {
      throw const AccesoException('Tu sesión no es válida. Inicia sesión.');
    }
  }
}

class AutenticacionLocal extends ChangeNotifier {
  AutenticacionLocal({required this.base});
  final BaseDatosLocal base;
  static const iteraciones = Claves.iteraciones;
  static const _correoEnUso = 'Este correo ya tiene una cuenta. Inicia sesión.';
  static const _propietarioIncorrecto =
      'Correo o contraseña del propietario incorrectos.';
  static const _yaHayAdministrador =
      'Ya existe un administrador en este dispositivo.';

  SesionEmpresa? _sesion;
  SesionEmpresa? get sesion => _sesion;
  bool _ocupada = false;
  bool _cerrada = false;
  int _intento = 0;

  Future<void> _ejecutar(Future<Map<String, Object?>> Function() accion) async {
    if (_cerrada || _ocupada || _sesion != null) {
      throw const AccesoException('Espera a que termine el acceso actual.');
    }
    _ocupada = true;
    final intento = ++_intento;
    try {
      final cuenta = await accion();
      if (_cerrada || intento != _intento) {
        throw const AccesoException(
          'El acceso fue cancelado. Inténtalo de nuevo.',
        );
      }
      _sesion = SesionEmpresa._(cuenta);
      notifyListeners();
    } on AccesoException {
      rethrow;
    } catch (_) {
      throw const AccesoException(
        'No pudimos completar el acceso. Inténtalo de nuevo.',
      );
    } finally {
      _ocupada = false;
    }
  }

  Future<bool> _correoRegistrado(DatabaseExecutor db, String correo) async =>
      (await db.query(
        'cuentas',
        columns: ['id'],
        where: 'correo = ?',
        whereArgs: [correo],
      )).isNotEmpty;

  Future<int> _contar(DatabaseExecutor db, RolCuenta rol) async =>
      Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM cuentas WHERE rol = ?', [
          rol.name,
        ]),
      ) ??
      0;

  Future<void> registrar(DatosRegistro datos) => _ejecutar(() async {
    datos.validar();
    final correo = DatosRegistro.normalizarCorreo(datos.correo);
    final db = await base.abrir;
    if (await _correoRegistrado(db, correo)) {
      throw const AccesoException(_correoEnUso);
    }
    final clave = await Claves.nueva(datos.clave);
    return db.transaction((tx) async {
      // Repetir bajo la transacción evita duplicados y empresas huérfanas.
      if (await _correoRegistrado(tx, correo)) {
        throw const AccesoException(_correoEnUso);
      }
      final primera = (await tx.query(
        'cuentas',
        columns: ['id'],
        limit: 1,
      )).isEmpty;
      final anteriores = await tx.query(
        'empresas',
        where: 'id = ?',
        whereArgs: ['negocio-local'],
      );
      final empresaId = primera && anteriores.isNotEmpty
          ? 'negocio-local'
          : nuevoId();
      return _insertarCuenta(
        tx,
        empresaId: empresaId,
        nombreEmpresa: datos.empresa.trim(),
        nombre: datos.propietario.trim(),
        correo: correo,
        clave: clave,
        rol: RolCuenta.propietario,
      );
    });
  });

  Future<Map<String, Object?>> _insertarCuenta(
    Transaction tx, {
    required String empresaId,
    required String nombreEmpresa,
    required String nombre,
    required String correo,
    required ({String sal, String hash}) clave,
    required RolCuenta rol,
  }) async {
    final usuarioId = nuevoId();
    await tx.insert('empresas', {
      'id': empresaId,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
    await tx.insert('usuarios', {'empresa': empresaId, 'id': usuarioId});
    final cuenta = <String, Object?>{
      'id': nuevoId(),
      'empresa': empresaId,
      'usuario': usuarioId,
      'nombre_empresa': nombreEmpresa,
      'nombre': nombre,
      'correo': correo,
      'sal': clave.sal,
      'hash': clave.hash,
      'iteraciones': iteraciones,
      'activa': 1,
      'rol': rol.name,
    };
    await tx.insert('cuentas', cuenta);
    return cuenta;
  }

  /// El administrador se crea una sola vez y con la autorización de un
  /// propietario activo, para que nadie más pueda ver las cuentas.
  Future<bool> puedeCrearAdministrador() async {
    final db = await base.abrir;
    return await _contar(db, RolCuenta.propietario) > 0 &&
        await _contar(db, RolCuenta.administrador) == 0;
  }

  Future<void> crearAdministrador(
    DatosAdministrador datos, {
    required String correoPropietario,
    required String clavePropietario,
  }) => _ejecutar(() async {
    datos.validar();
    final correo = DatosRegistro.normalizarCorreo(datos.correo);
    final db = await base.abrir;
    if (await _contar(db, RolCuenta.administrador) > 0) {
      throw const AccesoException(_yaHayAdministrador);
    }
    final filas = await db.query(
      'cuentas',
      where: 'correo = ? AND rol = ?',
      whereArgs: [
        DatosRegistro.normalizarCorreo(correoPropietario),
        RolCuenta.propietario.name,
      ],
    );
    final duenio = filas.isEmpty ? null : filas.single;
    if (!await Claves.coincide(clavePropietario, duenio) ||
        duenio?['activa'] != 1) {
      throw const AccesoException(_propietarioIncorrecto);
    }
    if (await _correoRegistrado(db, correo)) {
      throw const AccesoException(_correoEnUso);
    }
    final clave = await Claves.nueva(datos.clave);
    return db.transaction((tx) async {
      if (await _contar(tx, RolCuenta.administrador) > 0) {
        throw const AccesoException(_yaHayAdministrador);
      }
      if (await _correoRegistrado(tx, correo)) {
        throw const AccesoException(_correoEnUso);
      }
      // La empresa propia del administrador nunca tiene datos de negocio.
      return _insertarCuenta(
        tx,
        empresaId: nuevoId(),
        nombreEmpresa: 'Administración',
        nombre: datos.nombre.trim(),
        correo: correo,
        clave: clave,
        rol: RolCuenta.administrador,
      );
    });
  });

  Future<void> iniciarSesion(
    String correo,
    String clave,
  ) => _ejecutar(() async {
    if (DatosRegistro.validarCorreo(correo) != null ||
        clave.isEmpty ||
        clave.runes.length > DatosRegistro.longitudMaximaClave) {
      throw const AccesoException('Correo o contraseña incorrectos.');
    }
    final db = await base.abrir;
    final filas = await db.query(
      'cuentas',
      where: 'correo = ?',
      whereArgs: [DatosRegistro.normalizarCorreo(correo)],
    );
    final cuenta = filas.isEmpty ? null : filas.single;
    // Mismo trabajo de derivación para un correo inexistente y uno registrado.
    final valida = await Claves.coincide(clave, cuenta);
    if (cuenta == null || !valida) {
      throw const AccesoException('Correo o contraseña incorrectos.');
    }
    // Solo quien conoce la contraseña sabe que la cuenta está desactivada.
    if (cuenta['activa'] != 1) {
      throw const AccesoException(
        'Esta cuenta está desactivada. Pide al administrador que la active.',
      );
    }
    final actuales = await db.query(
      'cuentas',
      where: 'id = ? AND activa = 1 AND hash = ? AND sal = ?',
      whereArgs: [cuenta['id'], cuenta['hash'], cuenta['sal']],
    );
    if (actuales.isEmpty) {
      throw const AccesoException('Correo o contraseña incorrectos.');
    }
    return actuales.single;
  });

  void cerrarSesion() {
    ++_intento;
    _sesion?._activa = false;
    _sesion = null;
    if (!_cerrada) notifyListeners();
  }

  @override
  void dispose() {
    _cerrada = true;
    cerrarSesion();
    super.dispose();
  }
}
