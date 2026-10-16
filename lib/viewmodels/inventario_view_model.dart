import 'package:flutter/foundation.dart';

import '../data/producto_repository.dart';
import '../models/producto.dart';
import '../models/validacion_producto.dart';

enum EstadoInventario { cargando, conDatos, vacio, error }

class InventarioViewModel extends ChangeNotifier {
  InventarioViewModel(this._repositorio);

  final ProductoRepository _repositorio;
  EstadoInventario _estado = EstadoInventario.cargando;
  List<Producto> _productos = const [];
  bool _guardando = false;
  bool _eliminado = false;
  int _solicitudActual = 0;

  EstadoInventario get estado => _estado;
  List<Producto> get productos => _productos;
  bool get guardando => _guardando;
  EscenarioInventario get escenario => _repositorio.escenario;

  void _notificar() {
    if (!_eliminado) notifyListeners();
  }

  Future<void> cargar() async {
    if (_eliminado) return;
    final solicitud = ++_solicitudActual;
    _estado = EstadoInventario.cargando;
    _productos = const [];
    _notificar();

    try {
      final productos = await _repositorio.obtenerTodos();
      if (_eliminado || solicitud != _solicitudActual) return;
      _productos = List<Producto>.unmodifiable(productos);
      _estado = productos.isEmpty
          ? EstadoInventario.vacio
          : EstadoInventario.conDatos;
    } catch (_) {
      if (_eliminado || solicitud != _solicitudActual) return;
      _estado = EstadoInventario.error;
    }
    _notificar();
  }

  Future<void> cambiarEscenario(EscenarioInventario escenario) async {
    if (_eliminado || _guardando) return;
    _repositorio.seleccionarEscenario(escenario);
    await cargar();
  }

  String? validarNombre(String? nombre) => ValidacionProducto.nombre(nombre);
  String? validarCosto(String? texto) => ValidacionProducto.costo(texto);
  String? validarPrecio(String? texto) => ValidacionProducto.precio(texto);

  Future<void> registrarProducto({
    required String nombre,
    required String costoCompra,
    required String precioVenta,
  }) async {
    // Bloqueo inmediato para evitar crear dos registros por doble toque.
    if (_guardando || _eliminado) return;

    final error =
        validarNombre(nombre) ??
        validarCosto(costoCompra) ??
        validarPrecio(precioVenta);
    if (error != null) throw ArgumentError(error);

    _guardando = true;
    _notificar();
    try {
      await _repositorio.crearProducto(
        nombre: nombre,
        costoCompra: ValidacionProducto.leerImporte(costoCompra)!,
        precioVenta: ValidacionProducto.leerImporte(precioVenta)!,
      );
      await cargar();
    } finally {
      _guardando = false;
      _notificar();
    }
  }

  Future<void> actualizarProducto({
    required String id,
    required String nombre,
    required String costoCompra,
    required String precioVenta,
  }) async {
    if (_guardando || _eliminado) return;
    final error =
        validarNombre(nombre) ??
        validarCosto(costoCompra) ??
        validarPrecio(precioVenta);
    if (error != null) throw ArgumentError(error);

    _guardando = true;
    _notificar();
    try {
      await _repositorio.actualizarProducto(
        id: id,
        nombre: nombre,
        costoCompra: ValidacionProducto.leerImporte(costoCompra)!,
        precioVenta: ValidacionProducto.leerImporte(precioVenta)!,
      );
      await cargar();
    } finally {
      _guardando = false;
      _notificar();
    }
  }

  @override
  void dispose() {
    _eliminado = true;
    _solicitudActual++;
    super.dispose();
  }
}
