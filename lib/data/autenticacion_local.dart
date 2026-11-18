import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../models/operacion.dart';
import 'base_datos_local.dart';

class AccesoException implements Exception {
  const AccesoException(this.mensaje);
  final String mensaje;
  @override
  String toString() => mensaje;
}

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

/// Solo AutenticacionLocal puede emitir una sesión. Se revoca en memoria
/// y se verifica contra la cuenta dentro de cada transacción del negocio.
class SesionEmpresa {
  SesionEmpresa._(Map<String, Object?> row)
    : cuentaId = row['id'] as String,
      empresaId = row['empresa'] as String,
      usuarioId = row['usuario'] as String,
      empresa = row['nombre_empresa'] as String,
      propietario = row['nombre'] as String,
      correo = row['correo'] as String;

  final String cuentaId;
  final String empresaId;
  final String usuarioId;
  final String empresa;
  final String propietario;
  final String correo;
  bool _activa = true;

  Future<void> verificar(DatabaseExecutor db) async {
    if (!_activa) {
      throw const AccesoException('Tu sesión terminó. Inicia sesión.');
    }
    final cuentas = await db.query(
      'cuentas',
      columns: ['id'],
      where: 'id = ? AND empresa = ? AND usuario = ? AND activa = 1',
      whereArgs: [cuentaId, empresaId, usuarioId],
    );
    if (!_activa || cuentas.isEmpty) {
      throw const AccesoException('Tu sesión no es válida. Inicia sesión.');
    }
  }
}

// Se ejecuta fuera del hilo de UI para mantener el formulario receptivo.
Future<List<int>> _derivarClave((String, List<int>, int) datos) async {
  final algoritmo = Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: datos.$3,
    bits: 256,
  );
  final key = await algoritmo.deriveKeyFromPassword(
    password: datos.$1,
    nonce: datos.$2,
  );
  return key.extractBytes();
}

class AutenticacionLocal extends ChangeNotifier {
  AutenticacionLocal({required this.base});
  final BaseDatosLocal base;
  static const iteraciones = 600000;
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

  Future<void> registrar(DatosRegistro datos) => _ejecutar(() async {
    datos.validar();
    final correo = DatosRegistro.normalizarCorreo(datos.correo);
    final db = await base.abrir;
    if ((await db.query(
      'cuentas',
      columns: ['id'],
      where: 'correo = ?',
      whereArgs: [correo],
    )).isNotEmpty) {
      throw const AccesoException(
        'Este correo ya tiene una cuenta. Inicia sesión.',
      );
    }
    final azar = Random.secure();
    final sal = List<int>.generate(32, (_) => azar.nextInt(256));
    final hash = await compute(_derivarClave, (datos.clave, sal, iteraciones));
    return db.transaction((tx) async {
      // Repetir bajo la transacción evita duplicados y empresas huérfanas.
      if ((await tx.query(
        'cuentas',
        columns: ['id'],
        where: 'correo = ?',
        whereArgs: [correo],
      )).isNotEmpty) {
        throw const AccesoException(
          'Este correo ya tiene una cuenta. Inicia sesión.',
        );
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
      final usuarioId = nuevoId();
      await tx.insert('empresas', {
        'id': empresaId,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
      await tx.insert('usuarios', {'empresa': empresaId, 'id': usuarioId});
      final cuenta = <String, Object?>{
        'id': nuevoId(),
        'empresa': empresaId,
        'usuario': usuarioId,
        'nombre_empresa': datos.empresa.trim(),
        'nombre': datos.propietario.trim(),
        'correo': correo,
        'sal': base64Encode(sal),
        'hash': base64Encode(hash),
        'iteraciones': iteraciones,
        'activa': 1,
      };
      await tx.insert('cuentas', cuenta);
      return cuenta;
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
    // Igual trabajo de derivación para un correo inexistente y uno registrado.
    final sal = cuenta == null
        ? List<int>.filled(32, 0)
        : base64Decode(cuenta['sal'] as String);
    final hash = await compute(_derivarClave, (
      clave,
      sal,
      cuenta?['iteraciones'] as int? ?? iteraciones,
    ));
    final esperado = cuenta == null
        ? List<int>.filled(32, 0)
        : base64Decode(cuenta['hash'] as String);
    var diferencia = hash.length ^ esperado.length;
    for (var i = 0; i < hash.length && i < esperado.length; i++) {
      diferencia |= hash[i] ^ esperado[i];
    }
    if (cuenta == null || diferencia != 0 || cuenta['activa'] != 1) {
      throw const AccesoException('Correo o contraseña incorrectos.');
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
