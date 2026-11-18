import 'package:flutter/foundation.dart';

import '../data/negocio_repository.dart';
import '../models/gasto.dart';
import '../models/operacion.dart';
import '../models/validacion_producto.dart';

class GastosViewModel extends ChangeNotifier {
  GastosViewModel(this.repositorio);
  final NegocioRepository repositorio;
  List<Gasto> gastos = const [];
  bool cargando = true;
  String? error;
  bool _cerrado = false;
  int _solicitud = 0;

  Future<void> cargar() async {
    if (_cerrado) return;
    final solicitud = ++_solicitud;
    cargando = true;
    error = null;
    notifyListeners();
    try {
      final resultado = await repositorio.obtenerGastos();
      if (_cerrado || solicitud != _solicitud) return;
      gastos = List.unmodifiable(resultado);
    } catch (_) {
      if (_cerrado || solicitud != _solicitud) return;
      error = 'No pudimos cargar los gastos. Reintenta la consulta.';
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

class FormularioGastoViewModel extends ChangeNotifier {
  FormularioGastoViewModel(this.repositorio);
  final NegocioRepository repositorio;
  final String id = nuevoId();
  DateTime? fecha;
  String concepto = '';
  String? categoria;
  String valor = '';
  bool guardando = false;
  String? error;
  bool _cerrado = false;

  Future<Gasto?> guardar() async {
    if (_cerrado || guardando) return null;
    guardando = true;
    error = null;
    notifyListeners();
    try {
      return await repositorio.registrarGasto(
        SolicitudGasto(
          id: id,
          fecha: fecha,
          concepto: concepto,
          categoria: categoria ?? '',
          valor: ValidacionProducto.leerImporte(valor) ?? -1,
        ),
      );
    } on ReglaNegocioException catch (e) {
      error = e.mensaje;
    } catch (_) {
      error =
          'No pudimos guardar el gasto. Conservamos los datos para reintentar.';
    } finally {
      guardando = false;
      if (!_cerrado) notifyListeners();
    }
    return null;
  }

  @override
  void dispose() {
    _cerrado = true;
    super.dispose();
  }
}
