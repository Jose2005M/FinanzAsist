import 'package:finanzasist/models/gasto.dart';
import 'package:finanzasist/models/reglas_inventario.dart';
import 'package:finanzasist/models/validacion_producto.dart';
import 'package:finanzasist/utils/entrada_importe.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Admite pesos sin miles y decimales explícitos con punto o coma', () {
    for (final caso in [
      ('6000', 6000.0),
      ('6000,50', 6000.5),
      ('6000.50', 6000.5),
      (' 0,01 ', 0.01),
      ('0', 0.0),
    ]) {
      expect(EntradaImporte.leer(caso.$1), caso.$2);
      expect(ReglasInventario.importe(caso.$1), isNull);
    }
  });
  test('Todos los validadores rechazan miles ambiguos sin convertirlos a seis pesos', () {
    for (final texto in [
      '6.000',
      '6,000',
      '1.000.000',
      '1,000.00',
      '6 000',
      '1.234,50',
      '1e3',
    ]) {
      expect(EntradaImporte.leer(texto), isNull);
      expect(ValidacionProducto.leerImporte(texto), isNull);
      expect(ReglasInventario.importe(texto), isNotNull);
      expect(ValidacionProducto.costo(texto), isNotNull);
      expect(ValidacionProducto.precio(texto), isNotNull);
      expect(ValidacionGasto.valor(texto), isNotNull);
    }
  });
  test(
    'Conserva límites de dominio, valores negativos y precisión de centavos',
    () {
      expect(ReglasInventario.importe('-1'), isNotNull);
      expect(ReglasInventario.importe('0.001'), isNotNull);
      expect(ReglasInventario.importe('99999999999999999999'), isNotNull);
      expect(ValidacionGasto.valor('0'), isNotNull);
      expect(
        ValidacionProducto.costo('-1'),
        'El costo de compra no puede ser negativo',
      );
      expect(
        ValidacionProducto.precio('-1'),
        'El precio de venta no puede ser negativo',
      );
      for (final valor in [0.0, 6000.5, 9999999.99]) {
        expect(
          EntradaImporte.leer(EntradaImporte.paraFormulario(valor)),
          valor,
        );
      }
    },
  );
}
