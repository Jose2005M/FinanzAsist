import 'package:flutter/foundation.dart';

import '../data/autenticacion_local.dart';
import '../data/usuarios_empresa.dart';

class UsuariosEmpresaViewModel extends ChangeNotifier {
  UsuariosEmpresaViewModel(this.usuarios);
  final GestionUsuariosEmpresa usuarios;

  List<UsuarioEmpresa> lista = const [];
  bool cargando = true;
  String? error;

  /// Hay una modificación en curso; las acciones quedan deshabilitadas.
  bool procesando = false;
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
      final resultado = await usuarios.listarUsuarios();
      if (_cerrado || solicitud != _solicitud) return;
      lista = List.unmodifiable(resultado);
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

  /// Cada acción devuelve el mensaje de error, o `null` si se completó.
  Future<String?> cambiarEstado(UsuarioEmpresa u, {required bool activa}) =>
      _modificar(() => usuarios.cambiarEstado(u.id, activa: activa));

  Future<String?> cambiarRol(UsuarioEmpresa u, RolCuenta rol) =>
      _modificar(() => usuarios.cambiarRol(u.id, rol));

  Future<String?> restablecerClave(UsuarioEmpresa u, String clave) =>
      _modificar(() => usuarios.restablecerClave(u.id, clave));

  Future<String?> _modificar(Future<void> Function() accion) async {
    if (procesando || _cerrado) return null;
    procesando = true;
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
    procesando = false;
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
