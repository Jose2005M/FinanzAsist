import 'package:flutter/foundation.dart';

import '../data/producto_repository.dart';
import '../models/producto.dart';

enum EstadoDetalle { cargando, contenido, error }

class DetalleProductoViewModel extends ChangeNotifier {
  DetalleProductoViewModel({
    required ProductoRepository repositorio,
    required this.productoId,
  }) : _repositorio = repositorio;

  final ProductoRepository _repositorio;
  final String productoId;
  EstadoDetalle _estado = EstadoDetalle.cargando;
  Producto? _producto;
  String _mensajeError = '';
  bool _eliminado = false;
  int _solicitudActual = 0;

  EstadoDetalle get estado => _estado;
  Producto? get producto => _producto;
  String get mensajeError => _mensajeError;

  Future<void> cargar() async {
    if (_eliminado) return;
    final solicitud = ++_solicitudActual;
    _estado = EstadoDetalle.cargando;
    _producto = null;
    notifyListeners();
    try {
      final producto = await _repositorio.obtenerPorId(productoId);
      if (_eliminado || solicitud != _solicitudActual) return;
      _producto = producto;
      _estado = producto == null
          ? EstadoDetalle.error
          : EstadoDetalle.contenido;
      _mensajeError = producto == null ? 'No encontramos este producto' : '';
    } catch (_) {
      if (_eliminado || solicitud != _solicitudActual) return;
      _estado = EstadoDetalle.error;
      _mensajeError = 'No pudimos cargar el producto';
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _eliminado = true;
    _solicitudActual++;
    super.dispose();
  }
}
