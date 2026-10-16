class Producto {
  const Producto({
    required this.id,
    required this.nombre,
    required this.cantidad,
    required this.costoCompra,
    required this.precioVenta,
  });

  final String id;
  final String nombre;
  final int cantidad;
  final double costoCompra;
  final double precioVenta;
}
