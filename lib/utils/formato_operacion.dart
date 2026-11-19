import '../models/operacion.dart';

String nombreOperacion(TipoOperacion tipo) => switch (tipo) {
  TipoOperacion.inicial => 'Existencias iniciales',
  TipoOperacion.ajuste => 'Ajuste de inventario',
  TipoOperacion.compra => 'Compra',
  TipoOperacion.venta => 'Venta',
};

String fechaColombia(DateTime fecha) {
  final local = fecha.toUtc().subtract(const Duration(hours: 5));
  String dos(int valor) => valor.toString().padLeft(2, '0');
  return '${dos(local.day)}/${dos(local.month)}/${local.year} ${dos(local.hour)}:${dos(local.minute)}';
}
