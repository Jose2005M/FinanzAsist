import 'package:flutter_test/flutter_test.dart';
import 'package:finanzasist/data/producto_repository.dart';
import 'package:finanzasist/data/repositorio_simulado.dart';

void main() {
  test('El inventario contiene cinco productos identificables', () async {
    final repositorio = RepositorioSimulado(retardo: Duration.zero);
    final productos = await repositorio.obtenerTodos();

    expect(productos, hasLength(5));
    expect(productos.map((p) => p.id).toSet(), hasLength(5));
    final azucar = productos.singleWhere((p) => p.id == 'P003');
    expect(azucar.nombre, 'Azúcar de 1 kg');
    expect(azucar.cantidad, 15);
    expect(productos.singleWhere((p) => p.id == 'P005').cantidad, 0);
  });

  test(
    'El detalle devuelve el producto del identificador solicitado',
    () async {
      final repositorio = RepositorioSimulado(retardo: Duration.zero);

      final producto = await repositorio.obtenerPorId('P002');
      expect(producto?.nombre, 'Aceite de 1 litro');
      expect(producto?.cantidad, 12);
      expect(await repositorio.obtenerPorId('NO-EXISTE'), isNull);
    },
  );

  test(
    'El primer registro llena un inventario vacío con una sola entrada',
    () async {
      final repositorio = RepositorioSimulado(retardo: Duration.zero);
      repositorio.seleccionarEscenario(EscenarioInventario.vacio);
      expect(await repositorio.obtenerTodos(), isEmpty);

      final nuevo = await repositorio.crearProducto(
        nombre: '  Café de 500 g  ',
        costoCompra: 8000,
        precioVenta: 11000,
      );
      final productos = await repositorio.obtenerTodos();
      expect(productos, hasLength(1));
      expect(productos.single.id, nuevo.id);
      expect(productos.single.nombre, 'Café de 500 g');
      expect(productos.single.cantidad, 0);
    },
  );
}
