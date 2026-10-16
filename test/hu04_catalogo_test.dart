import 'package:flutter_test/flutter_test.dart';
import 'package:finanzasist/data/producto_repository.dart';
import 'package:finanzasist/data/repositorio_simulado.dart';
import 'package:finanzasist/viewmodels/inventario_view_model.dart';

void main() {
  test(
    'HU04 CA01 registra costo 6000 y precio 10000 en una sola entrada',
    () async {
      final repositorio = RepositorioSimulado(retardo: Duration.zero);
      final producto = await repositorio.crearProducto(
        nombre: '  Café de 500 g  ',
        costoCompra: 6000,
        precioVenta: 10000,
      );
      final catalogo = await repositorio.obtenerTodos();

      expect(catalogo, hasLength(6));
      expect(catalogo.where((p) => p.id == producto.id), hasLength(1));
      expect(producto.nombre, 'Café de 500 g');
      expect(producto.costoCompra, 6000);
      expect(producto.precioVenta, 10000);
      expect(producto.cantidad, 0);
    },
  );

  test(
    'HU04 CA02 actualiza conservando identificador y 20 existencias',
    () async {
      final repositorio = RepositorioSimulado(retardo: Duration.zero);
      final producto = await repositorio.actualizarProducto(
        id: 'P001',
        nombre: 'Arroz de 1 kg Premium',
        costoCompra: 6000,
        precioVenta: 10000,
      );
      final catalogo = await repositorio.obtenerTodos();

      expect(catalogo, hasLength(5));
      expect(catalogo.map((p) => p.id).toSet(), hasLength(5));
      expect(producto.id, 'P001');
      expect(producto.nombre, 'Arroz de 1 kg Premium');
      expect(producto.cantidad, 20);
      expect(producto.costoCompra, 6000);
      expect(producto.precioVenta, 10000);
      expect(catalogo.singleWhere((p) => p.id == 'P002').precioVenta, 9000);
    },
  );

  test(
    'HU04 CA03 rechaza datos inválidos tanto en altas como en ediciones',
    () async {
      final repositorio = RepositorioSimulado(retardo: Duration.zero);
      Future<void> comprobar(String nombre, double costo, double precio) async {
        await expectLater(
          repositorio.crearProducto(
            nombre: nombre,
            costoCompra: costo,
            precioVenta: precio,
          ),
          throwsArgumentError,
        );
        await expectLater(
          repositorio.actualizarProducto(
            id: 'P001',
            nombre: nombre,
            costoCompra: costo,
            precioVenta: precio,
          ),
          throwsArgumentError,
        );
      }

      await comprobar('   ', 6000, 10000);
      await comprobar('Arroz', -1, 10000);
      await comprobar('Arroz', 6000, -1);
      await comprobar('Arroz', double.nan, 10000);
      await comprobar('Arroz', 6000, double.infinity);

      final catalogo = await repositorio.obtenerTodos();
      expect(catalogo, hasLength(5));
      final arroz = await repositorio.obtenerPorId('P001');
      expect(arroz?.nombre, 'Arroz de 1 kg');
      expect(arroz?.costoCompra, 3500);
      expect(arroz?.precioVenta, 4500);
      expect(arroz?.cantidad, 20);
    },
  );

  test('Editar un identificador inexistente no agrega otro producto', () async {
    final repositorio = RepositorioSimulado(retardo: Duration.zero);
    await expectLater(
      repositorio.actualizarProducto(
        id: 'NO-EXISTE',
        nombre: 'Café',
        costoCompra: 6000,
        precioVenta: 10000,
      ),
      throwsA(isA<ProductoNoEncontradoException>()),
    );
    expect(await repositorio.obtenerTodos(), hasLength(5));
  });

  test(
    'La edición refresca la lista del ViewModel con los nuevos valores',
    () async {
      final vm = InventarioViewModel(
        RepositorioSimulado(retardo: Duration.zero),
      );
      addTearDown(vm.dispose);
      await vm.cargar();
      await vm.actualizarProducto(
        id: 'P003',
        nombre: 'Azúcar de 1 kg',
        costoCompra: '6000',
        precioVenta: '10000',
      );

      final producto = vm.productos.singleWhere((p) => p.id == 'P003');
      expect(producto.cantidad, 15);
      expect(producto.costoCompra, 6000);
      expect(producto.precioVenta, 10000);
      expect(vm.productos, hasLength(5));
      expect(vm.guardando, isFalse);
    },
  );

  test('Un segundo envío durante la edición no reemplaza el primero', () async {
    final repositorio = RepositorioSimulado(
      retardo: const Duration(milliseconds: 1),
    );
    final vm = InventarioViewModel(repositorio);
    addTearDown(vm.dispose);
    final primero = vm.actualizarProducto(
      id: 'P001',
      nombre: 'Arroz de 1 kg',
      costoCompra: '6000',
      precioVenta: '10000',
    );
    final segundo = vm.actualizarProducto(
      id: 'P001',
      nombre: 'Arroz de 1 kg',
      costoCompra: '7000',
      precioVenta: '11000',
    );
    await Future.wait([primero, segundo]);
    final producto = await repositorio.obtenerPorId('P001');
    expect(producto?.costoCompra, 6000);
    expect(producto?.precioVenta, 10000);
    expect(vm.productos, hasLength(5));
  });

  test(
    'Una edición fallida libera el formulario para volver a guardar',
    () async {
      final vm = InventarioViewModel(
        RepositorioSimulado(retardo: Duration.zero),
      );
      addTearDown(vm.dispose);
      await expectLater(
        vm.actualizarProducto(
          id: 'NO-EXISTE',
          nombre: 'Arroz',
          costoCompra: '6000',
          precioVenta: '10000',
        ),
        throwsA(isA<ProductoNoEncontradoException>()),
      );
      expect(vm.guardando, isFalse);
      await vm.actualizarProducto(
        id: 'P001',
        nombre: 'Arroz de 1 kg',
        costoCompra: '6000',
        precioVenta: '10000',
      );
      expect(
        vm.productos.singleWhere((p) => p.id == 'P001').precioVenta,
        10000,
      );
    },
  );
}
