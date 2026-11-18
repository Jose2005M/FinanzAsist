import 'package:flutter/foundation.dart';

import '../data/negocio_repository.dart';
import '../models/fecha_negocio.dart';
import '../models/operacion.dart';
import '../models/reporte_financiero.dart';

class ReportesViewModel extends ChangeNotifier {
  ReportesViewModel(this.repositorio, {DateTime? ahora}) {
    hasta = FechaNegocio.hoy(ahora);
    desde = DateTime.utc(hasta.year, hasta.month);
  }
  final NegocioRepository repositorio;
  late DateTime desde;
  late DateTime hasta;
  ReporteFinanciero? reporte;
  bool cargando = false;
  String? error;
  bool _cerrado = false;
  int _solicitud = 0;

  void cambiarFechas({DateTime? inicio, DateTime? fin}) {
    if (_cerrado) return;
    _solicitud++;
    if (inicio != null) desde = FechaNegocio.dia(inicio);
    if (fin != null) hasta = FechaNegocio.dia(fin);
    reporte = null;
    error = null;
    cargando = false;
    notifyListeners();
  }

  Future<void> consultar() async {
    if (_cerrado) return;
    final solicitud = ++_solicitud;
    error = PeriodoReporte.validar(desde, hasta);
    reporte = null;
    if (error != null) {
      cargando = false;
      notifyListeners();
      return;
    }
    cargando = true;
    notifyListeners();
    try {
      final resultado = await repositorio.obtenerReporte(
        PeriodoReporte(desde: desde, hasta: hasta),
      );
      if (_cerrado || solicitud != _solicitud) return;
      reporte = resultado;
    } on ReglaNegocioException catch (e) {
      if (_cerrado || solicitud != _solicitud) return;
      error = e.mensaje;
    } catch (_) {
      if (_cerrado || solicitud != _solicitud) return;
      error = 'No pudimos generar el reporte. Reintenta la consulta.';
    }
    cargando = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _cerrado = true;
    _solicitud++;
    super.dispose();
  }
}
