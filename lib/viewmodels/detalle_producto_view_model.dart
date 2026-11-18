import 'package:flutter/foundation.dart';

import '../data/producto_repository.dart';
import '../data/negocio_repository.dart';
import '../models/operacion.dart';
import '../models/producto.dart';

enum EstadoDetalle { cargando, contenido, error }

class DetalleProductoViewModel extends ChangeNotifier {
  DetalleProductoViewModel({
    required this.repositorio,
    required this.productoId,
  });

  final ProductoRepository repositorio;
  final String productoId;
  EstadoDetalle _estado = EstadoDetalle.cargando;
  Producto? _producto;
  List<MovimientoInventario> movimientos = const [];
  String _mensajeError = '';
  bool _eliminado = false;
  int _solicitudActual = 0;

  EstadoDetalle get estado => _estado;
  Producto? get producto => _producto;
  String get mensajeError => _mensajeError;

  Future<void> cargar({bool mostrarCarga = true}) async {
    if (_eliminado) return;
    final solicitud = ++_solicitudActual;
    if (mostrarCarga) {
      _estado = EstadoDetalle.cargando;
      _producto = null;
    }
    notifyListeners();
    try {
      final producto = await repositorio.obtenerPorId(productoId);
      final fuente = repositorio;
      final historial = fuente is NegocioRepository
          ? await fuente.obtenerMovimientos(productoId: productoId)
          : <MovimientoInventario>[];
      if (_eliminado || solicitud != _solicitudActual) return;
      _producto = producto;
      movimientos = historial;
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
