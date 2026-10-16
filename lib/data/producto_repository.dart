import '../models/producto.dart';

enum EscenarioInventario { conDatos, vacio, error, cargando }

abstract interface class ProductoRepository {
  EscenarioInventario get escenario;

  // Herramienta de desarrollo para preparar datos y errores simulados.
  void seleccionarEscenario(EscenarioInventario escenario);

  Future<List<Producto>> obtenerTodos();
  Future<Producto?> obtenerPorId(String id);

  Future<Producto> crearProducto({
    required String nombre,
    required double costoCompra,
    required double precioVenta,
  });

  Future<Producto> actualizarProducto({
    required String id,
    required String nombre,
    required double costoCompra,
    required double precioVenta,
  });
}

class ProductoNoEncontradoException implements Exception {
  const ProductoNoEncontradoException();

  @override
  String toString() => 'El producto ya no está disponible';
}
