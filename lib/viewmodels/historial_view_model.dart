import 'package:flutter/foundation.dart';

import '../data/negocio_repository.dart';
import '../models/operacion.dart';

class HistorialViewModel extends ChangeNotifier {
  HistorialViewModel(this.repositorio, this.tipo);
  final NegocioRepository repositorio;
  final TipoOperacion tipo;
  List<Operacion> operaciones = const [];
  Map<String, String> responsables = const {};
  bool cargando = true;
  String? error;
  bool _cerrado = false;

  Future<void> cargar() async {
    cargando = true;
    error = null;
    if (!_cerrado) notifyListeners();
    try {
      operaciones = await repositorio.obtenerOperaciones(tipo: tipo);
      responsables = await repositorio.obtenerResponsables();
    } catch (_) {
      error = 'No pudimos cargar las operaciones. Reintenta la consulta.';
    }
    cargando = false;
    if (!_cerrado) notifyListeners();
  }

  @override
  void dispose() {
    _cerrado = true;
    super.dispose();
  }
}
