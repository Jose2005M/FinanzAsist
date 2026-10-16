import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:finanzasist/data/producto_repository.dart';
import 'package:finanzasist/data/repositorio_simulado.dart';
import 'package:finanzasist/models/producto.dart';
import 'package:finanzasist/viewmodels/detalle_producto_view_model.dart';
import 'package:finanzasist/viewmodels/inventario_view_model.dart';

void main() {
  test('La lista representa los cuatro estados y permite reintentar', () async {
    final vm = InventarioViewModel(RepositorioSimulado(retardo: Duration.zero));
    addTearDown(vm.dispose);

    expect(vm.estado, EstadoInventario.cargando);
    await vm.cargar();
    expect(vm.estado, EstadoInventario.conDatos);
    expect(vm.productos, hasLength(5));

    await vm.cambiarEscenario(EscenarioInventario.vacio);
    expect(vm.estado, EstadoInventario.vacio);
    expect(vm.productos, isEmpty);

    await vm.cambiarEscenario(EscenarioInventario.error);
    expect(vm.estado, EstadoInventario.error);
    expect(vm.productos, isEmpty);
    await vm.cargar();
    expect(vm.estado, EstadoInventario.conDatos);

    unawaited(vm.cambiarEscenario(EscenarioInventario.cargando));
    expect(vm.estado, EstadoInventario.cargando);
    await vm.cambiarEscenario(EscenarioInventario.conDatos);
    expect(vm.estado, EstadoInventario.conDatos);
  });

  test('Una respuesta antigua no reemplaza la consulta más reciente', () async {
    final repositorio = _RepositorioControlado();
    final vm = InventarioViewModel(repositorio);
    addTearDown(vm.dispose);

    final primera = vm.cargar();
    final segunda = vm.cargar();
    repositorio.solicitudes[1].complete([
      RepositorioSimulado.productosEjemplo[2],
    ]);
    await segunda;
    repositorio.solicitudes[0].complete([]);
    await primera;

    expect(vm.estado, EstadoInventario.conDatos);
    expect(vm.productos.single.id, 'P003');
  });

  test(
    'Cerrar la pantalla durante una consulta no notifica después de dispose',
    () async {
      final repositorio = _RepositorioControlado();
      final vm = InventarioViewModel(repositorio);
      final carga = vm.cargar();
      vm.dispose();
      repositorio.solicitudes.single.complete([]);
      await carga;
    },
  );

  test(
    'El costo negativo impide modificar los cinco productos existentes',
    () async {
      final repositorio = RepositorioSimulado(retardo: Duration.zero);
      final vm = InventarioViewModel(repositorio);
      addTearDown(vm.dispose);

      await expectLater(
        vm.registrarProducto(
          nombre: 'Café',
          costoCompra: '-3500',
          precioVenta: '4500',
        ),
        throwsArgumentError,
      );
      expect(await repositorio.obtenerTodos(), hasLength(5));
      expect(vm.guardando, isFalse);
    },
  );

  test('Dos solicitudes simultáneas crean un solo producto', () async {
    final vm = InventarioViewModel(
      RepositorioSimulado(retardo: const Duration(milliseconds: 1)),
    );
    addTearDown(vm.dispose);

    final primera = vm.registrarProducto(
      nombre: 'Café de 500 g',
      costoCompra: '8000',
      precioVenta: '11000',
    );
    final segunda = vm.registrarProducto(
      nombre: 'Café de 500 g',
      costoCompra: '8000',
      precioVenta: '11000',
    );
    await Future.wait([primera, segunda]);

    expect(vm.productos, hasLength(6));
    expect(
      vm.productos.where((p) => p.nombre == 'Café de 500 g'),
      hasLength(1),
    );
    expect(vm.guardando, isFalse);
  });

  test('El detalle informa que un identificador no existe', () async {
    final vm = DetalleProductoViewModel(
      repositorio: RepositorioSimulado(retardo: Duration.zero),
      productoId: 'NO-EXISTE',
    );
    addTearDown(vm.dispose);

    await vm.cargar();
    expect(vm.estado, EstadoDetalle.error);
    expect(vm.producto, isNull);
    expect(vm.mensajeError, 'No encontramos este producto');
  });
}

class _RepositorioControlado implements ProductoRepository {
  final solicitudes = <Completer<List<Producto>>>[];

  @override
  EscenarioInventario get escenario => EscenarioInventario.conDatos;

  @override
  void seleccionarEscenario(EscenarioInventario escenario) {}

  @override
  Future<List<Producto>> obtenerTodos() {
    final solicitud = Completer<List<Producto>>();
    solicitudes.add(solicitud);
    return solicitud.future;
  }

  @override
  Future<Producto?> obtenerPorId(String id) async => null;

  @override
  Future<Producto> crearProducto({
    required String nombre,
    required double costoCompra,
    required double precioVenta,
  }) => throw UnimplementedError();

  @override
  Future<Producto> actualizarProducto({
    required String id,
    required String nombre,
    required double costoCompra,
    required double precioVenta,
  }) => throw UnimplementedError();
}
