class ValidacionProducto {
  static String? nombre(String? texto) {
    if (texto == null || texto.trim().isEmpty) {
      return 'Escribe el nombre del producto';
    }
    return null;
  }

  static double? leerImporte(String? texto) {
    if (texto == null) return null;
    return double.tryParse(texto.trim().replaceAll(',', '.'));
  }

  static String? costo(String? texto) {
    final valor = leerImporte(texto);
    if (valor == null || !valor.isFinite) return 'Escribe un costo válido';
    if (valor < 0) return 'El costo de compra no puede ser negativo';
    return null;
  }

  static String? precio(String? texto) {
    final valor = leerImporte(texto);
    if (valor == null || !valor.isFinite) return 'Escribe un precio válido';
    if (valor < 0) return 'El precio de venta no puede ser negativo';
    return null;
  }

  static void verificar({
    required String nombreProducto,
    required double costoCompra,
    required double precioVenta,
  }) {
    final error =
        nombre(nombreProducto) ??
        costo(costoCompra.toString()) ??
        precio(precioVenta.toString());
    if (error != null) throw ArgumentError(error);
  }
}
