import 'package:flutter/foundation.dart';

import '../data/administracion_dispositivo.dart';
import '../data/autenticacion_local.dart';

class AdministracionViewModel extends ChangeNotifier {
  AdministracionViewModel(this.administracion);
  final GestionDispositivo administracion;

  List<EmpresaDispositivo> empresas = const [];
  bool cargando = true;
  String? error;

  /// Cuenta que se está modificando; sus acciones quedan deshabilitadas.
  String? procesando;
  bool _cerrado = false;
  int _solicitud = 0;

  static const _errorGenerico =
      'No pudimos completar la acción. Inténtalo de nuevo.';

  Future<void> cargar() async {
    if (_cerrado) return;
    final solicitud = ++_solicitud;
    cargando = true;
    error = null;
    notifyListeners();
    try {
      final resultado = await administracion.listarEmpresas();
      if (_cerrado || solicitud != _solicitud) return;
      empresas = resultado;
    } on AccesoException catch (e) {
      if (_cerrado || solicitud != _solicitud) return;
      error = e.mensaje;
    } on Exception {
      if (_cerrado || solicitud != _solicitud) return;
      error = 'No pudimos cargar los usuarios. Reintenta la consulta.';
    }
    cargando = false;
    notifyListeners();
  }

  /// Devuelve el mensaje de error, o `null` si la acción se completó.
  Future<String?> cambiarEstado(CuentaResumen cuenta, {required bool activa}) =>
      _modificar(
        cuenta,
        () => administracion.cambiarEstado(cuenta.id, activa: activa),
      );

  Future<String?> restablecerClave(CuentaResumen cuenta, String clave) =>
      _modificar(
        cuenta,
        () => administracion.restablecerClave(cuenta.id, clave),
      );

  Future<String?> _modificar(
    CuentaResumen cuenta,
    Future<void> Function() accion,
  ) async {
    if (procesando != null || _cerrado) return null;
    procesando = cuenta.id;
    notifyListeners();
    String? resultado;
    try {
      await accion();
    } on AccesoException catch (e) {
      resultado = e.mensaje;
    } on Exception {
      resultado = _errorGenerico;
    }
    if (_cerrado) return resultado;
    procesando = null;
    await cargar();
    return resultado;
  }

  @override
  void dispose() {
    _cerrado = true;
    _solicitud++;
    super.dispose();
  }
}
