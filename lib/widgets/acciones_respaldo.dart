import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/autenticacion_local.dart';
import '../data/respaldo_local.dart';
import '../data/selector_archivos.dart';

/// Recorridos de exportar y restaurar con sus diálogos y mensajes.
class AccionesRespaldo {
  AccionesRespaldo({required this.respaldo, required this.selector});

  final RespaldoLocal respaldo;
  final SelectorArchivos selector;
  bool _ocupado = false;

  static const _errorSistema =
      'No pudimos usar el archivo elegido. Inténtalo de nuevo.';

  Future<void> exportar(BuildContext context, {SesionEmpresa? sesion}) async {
    if (_ocupado) return;
    _ocupado = true;
    final mensajes = ScaffoldMessenger.of(context);
    try {
      final bytes = await respaldo.exportar(sesion: sesion);
      final guardado = await selector.guardar(
        nombre: RespaldoLocal.nombreArchivo(DateTime.now()),
        bytes: bytes,
      );
      if (guardado) {
        _avisar(
          mensajes,
          'Respaldo guardado. Contiene todos los datos del negocio: '
          'consérvalo en un lugar seguro.',
        );
      }
    } on RespaldoException catch (error) {
      _avisar(mensajes, error.mensaje);
    } on PlatformException {
      _avisar(mensajes, _errorSistema);
    } finally {
      _ocupado = false;
    }
  }

  /// Devuelve `true` si los datos del dispositivo se reemplazaron.
  Future<bool> restaurar(BuildContext context, {SesionEmpresa? sesion}) async {
    if (_ocupado) return false;
    _ocupado = true;
    final mensajes = ScaffoldMessenger.of(context);
    try {
      final bytes = await selector.elegir(tamanoMaximo: respaldo.tamanoMaximo);
      if (bytes == null || !context.mounted) return false;
      if (!await _confirmar(context)) return false;
      await respaldo.restaurar(bytes, sesion: sesion);
      _avisar(
        mensajes,
        'Respaldo restaurado. Inicia sesión con una cuenta del respaldo.',
      );
      return true;
    } on RespaldoException catch (error) {
      _avisar(mensajes, error.mensaje);
    } on PlatformException {
      _avisar(mensajes, _errorSistema);
    } finally {
      _ocupado = false;
    }
    return false;
  }

  Future<bool> _confirmar(BuildContext context) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('¿Reemplazar los datos?'),
          content: const Text(
            'Las cuentas, productos, compras, ventas y gastos de este '
            'dispositivo se reemplazarán por los del respaldo. '
            'No se puede deshacer.\n\n'
            'Si quieres conservar los datos actuales, exporta un respaldo '
            'antes. Después deberás iniciar sesión con una cuenta del '
            'respaldo.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              key: const ValueKey('confirmar-restauracion'),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Reemplazar datos'),
            ),
          ],
        ),
      ) ??
      false;

  void _avisar(ScaffoldMessengerState mensajes, String texto) => mensajes
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(texto)));
}
