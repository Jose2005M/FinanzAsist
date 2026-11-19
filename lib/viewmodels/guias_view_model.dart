import 'package:flutter/foundation.dart';

import '../data/almacen_guias.dart';
import '../models/guia_modulo.dart';

class GuiasViewModel extends ChangeNotifier {
  GuiasViewModel(this._almacen);
  final AlmacenGuias _almacen;
  final Set<ModuloGuia> _vistas = {};
  bool cargando = true;
  bool _cerrado = false;

  bool vista(ModuloGuia modulo) => _vistas.contains(modulo);

  Future<void> cargar() async {
    try {
      final vistas = await _almacen.leerVistas();
      if (_cerrado) return;
      _vistas.addAll(vistas);
    } catch (_) {
      // La ayuda sigue disponible si no se pueden leer las preferencias.
    }
    if (_cerrado) return;
    cargando = false;
    notifyListeners();
  }

  Future<bool> marcarVista(ModuloGuia modulo) async {
    if (_cerrado) return false;
    _vistas.add(modulo);
    notifyListeners();
    try {
      await _almacen.marcarVista(modulo);
      return true;
    } catch (_) {
      // Respeta la decisión durante la sesión, aunque falle la persistencia.
      return false;
    }
  }

  @override
  void dispose() {
    _cerrado = true;
    super.dispose();
  }
}
