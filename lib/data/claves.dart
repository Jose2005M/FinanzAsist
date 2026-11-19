import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';

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

/// Contraseñas con PBKDF2-SHA256 y sal aleatoria por cuenta.
abstract final class Claves {
  static const iteraciones = 600000;
  static const _bytesSal = 32;

  /// Sal y hash en base64, listos para guardar en la tabla de cuentas.
  static Future<({String sal, String hash})> nueva(String clave) async {
    final azar = Random.secure();
    final sal = List<int>.generate(_bytesSal, (_) => azar.nextInt(256));
    final hash = await compute(_derivarClave, (clave, sal, iteraciones));
    return (sal: base64Encode(sal), hash: base64Encode(hash));
  }

  /// Compara en tiempo constante. Sin [cuenta] hace el mismo trabajo y
  /// devuelve `false`, para no revelar qué correos están registrados.
  static Future<bool> coincide(
    String clave,
    Map<String, Object?>? cuenta,
  ) async {
    final sal = cuenta == null
        ? List<int>.filled(_bytesSal, 0)
        : base64Decode(cuenta['sal'] as String);
    final hash = await compute(_derivarClave, (
      clave,
      sal,
      cuenta?['iteraciones'] as int? ?? iteraciones,
    ));
    final esperado = cuenta == null
        ? List<int>.filled(_bytesSal, 0)
        : base64Decode(cuenta['hash'] as String);
    var diferencia = hash.length ^ esperado.length;
    for (var i = 0; i < hash.length && i < esperado.length; i++) {
      diferencia |= hash[i] ^ esperado[i];
    }
    return cuenta != null && diferencia == 0;
  }
}
