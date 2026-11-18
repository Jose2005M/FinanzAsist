import 'reglas_inventario.dart';
import '../utils/entrada_importe.dart';

class ValidacionProducto {
  static String? nombre(String? texto) {
    if (texto == null || texto.trim().isEmpty) {
      return 'Escribe el nombre del producto';
    }
    return null;
  }

  static double? leerImporte(String? texto) {
    return EntradaImporte.leer(texto);
  }

  static String? costo(String? texto) {
    final valor = leerImporte(texto);
    if (valor == null || !valor.isFinite) {
      return EntradaImporte.error(texto, invalido: 'Escribe un costo válido');
    }
    if (valor < 0) return 'El costo de compra no puede ser negativo';
    return ReglasInventario.importe(texto);
  }

  static String? precio(String? texto) {
    final valor = leerImporte(texto);
    if (valor == null || !valor.isFinite) {
      return EntradaImporte.error(texto, invalido: 'Escribe un precio válido');
    }
    if (valor < 0) return 'El precio de venta no puede ser negativo';
    return ReglasInventario.importe(texto);
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
