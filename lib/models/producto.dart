class Producto {
  const Producto({
    required this.id,
    required this.nombre,
    required this.cantidad,
    required this.costoCompra,
    required this.precioVenta,
    this.empresaId = 'negocio-local',
  });

  final String id;
  final String nombre;
  final int cantidad;
  final double costoCompra;
  final double precioVenta;
  final String empresaId;

  Producto conCantidad(int valor) => Producto(
    id: id,
    nombre: nombre,
    cantidad: valor,
    costoCompra: costoCompra,
    precioVenta: precioVenta,
    empresaId: empresaId,
  );
}
