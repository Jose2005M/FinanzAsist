import 'dart:async';

import 'package:finanzasist/data/repositorio_simulado.dart';
import 'package:finanzasist/main.dart';
import 'package:finanzasist/models/fecha_negocio.dart';
import 'package:finanzasist/models/producto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'soporte_guias.dart';

Future<void> pulsar(WidgetTester tester, Finder finder) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  await Scrollable.ensureVisible(tester.element(finder), alignment: 0.5);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<RepositorioSimulado> abrir(
  WidgetTester tester, {
  RepositorioSimulado? repo,
  bool grande = false,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = grande
      ? const Size(320, 640)
      : const Size(390, 844);
  addTearDown(tester.view.reset);
  final datos =
      repo ??
      RepositorioSimulado(
        retardo: Duration.zero,
        productosIniciales: const [
          Producto(
            id: 'A',
            nombre: 'Arroz',
            cantidad: 10,
            costoCompra: 6000,
            precioVenta: 10000,
          ),
          Producto(
            id: 'B',
            nombre: 'Café',
            cantidad: 4,
            costoCompra: 4000,
            precioVenta: 8000,
          ),
        ],
      );
  await tester.pumpWidget(
    FinanzAsistApp(repositorio: datos, almacenGuias: guiasRevisadas()),
  );
  await tester.pumpAndSettle();
  if (grande) {
    final data = MediaQuery.of(tester.element(find.byType(Scaffold).first));
    await tester.pumpWidget(
      MediaQuery(
        data: data.copyWith(textScaler: const TextScaler.linear(2)),
        child: FinanzAsistApp(
          repositorio: datos,
          almacenGuias: guiasRevisadas(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }
  return datos;
}

Future<void> completarProducto(WidgetTester tester) async {
  for (final campo in [
    ('nombre-producto', 'Panela'),
    ('costo-producto', '6000,50'),
    ('precio-producto', '10000'),
  ]) {
    await tester.ensureVisible(find.byKey(ValueKey(campo.$1)));
    await tester.enterText(find.byKey(ValueKey(campo.$1)), campo.$2);
  }
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'El detalle abierto actualiza unidades al regresar de una venta',
    (tester) async {
      await abrir(tester);
      await pulsar(tester, find.byKey(const ValueKey('producto-A')));
      await tester.drag(find.byType(ListView), const Offset(0, -120));
      await tester.pumpAndSettle();
      final anterior = tester
          .widget<ListView>(find.byType(ListView))
          .controller!
          .offset;
      await pulsar(tester, find.byKey(const ValueKey('modulo-ventas')));
      await pulsar(tester, find.byKey(const ValueKey('nueva-venta')));
      await pulsar(tester, find.byType(DropdownButtonFormField<String>));
      await pulsar(tester, find.text('Arroz').last);
      await tester.enterText(
        find.byKey(const ValueKey('cantidad-linea-0')),
        '2',
      );
      await pulsar(tester, find.byKey(const ValueKey('revisar-operacion')));
      await pulsar(tester, find.byKey(const ValueKey('confirmar-operacion')));
      await pulsar(tester, find.byKey(const ValueKey('modulo-inventario')));
      expect(find.text('Detalle del producto'), findsOneWidget);
      expect(find.text('8 unidades'), findsOneWidget);
      expect(
        tester.widget<ListView>(find.byType(ListView)).controller!.offset,
        anterior,
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'Una compra renueva existencias de una venta abierta sin borrar sus valores',
    (tester) async {
      await abrir(tester);
      await pulsar(tester, find.byKey(const ValueKey('modulo-ventas')));
      await pulsar(tester, find.byKey(const ValueKey('nueva-venta')));
      await pulsar(tester, find.byType(DropdownButtonFormField<String>));
      await pulsar(tester, find.text('Arroz').last);
      await tester.enterText(
        find.byKey(const ValueKey('cantidad-linea-0')),
        '12',
      );
      await tester.enterText(
        find.byKey(const ValueKey('valor-linea-0-A')),
        '12345,50',
      );
      await tester.enterText(
        find.byKey(const ValueKey('descuento-venta')),
        '500',
      );
      await pulsar(tester, find.byKey(const ValueKey('modulo-compras')));
      await pulsar(tester, find.byKey(const ValueKey('nueva-compra')));
      await pulsar(tester, find.byType(DropdownButtonFormField<String>));
      await pulsar(tester, find.text('Arroz').last);
      await tester.enterText(
        find.byKey(const ValueKey('cantidad-linea-0')),
        '5',
      );
      await pulsar(tester, find.byKey(const ValueKey('revisar-operacion')));
      await pulsar(tester, find.byKey(const ValueKey('confirmar-operacion')));
      await pulsar(tester, find.byKey(const ValueKey('modulo-ventas')));
      String escrito(String clave) => tester
          .widget<EditableText>(
            find.descendant(
              of: find.byKey(ValueKey(clave)),
              matching: find.byType(EditableText),
            ),
          )
          .controller
          .text;
      expect(escrito('cantidad-linea-0'), '12');
      expect(escrito('valor-linea-0-A'), '12345,50');
      expect(escrito('descuento-venta'), '500');
      await pulsar(tester, find.byKey(const ValueKey('revisar-operacion')));
      expect(find.text('Existencias después: 3 unidades'), findsOneWidget);
      expect(find.text('No hay existencias suficientes'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'El aviso de descarte es accesible con teclado y texto al 200 %',
    (tester) async {
      await abrir(tester, grande: true);
      await pulsar(tester, find.byTooltip('Registrar producto'));
      await tester.enterText(
        find.byKey(const ValueKey('nombre-producto')),
        'Borrador',
      );
      tester.view.viewInsets = const FakeViewPadding(bottom: 230);
      await tester.pumpAndSettle();
      await pulsar(tester, find.byType(BackButton));
      expect(find.text('¿Descartar los cambios?'), findsOneWidget);
      await pulsar(tester, find.byKey(const ValueKey('seguir-editando')));
      expect(find.text('Borrador'), findsOneWidget);
      await pulsar(tester, find.byType(BackButton));
      await pulsar(tester, find.byKey(const ValueKey('descartar-cambios')));
      expect(find.byKey(const ValueKey('guardar-producto')), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Las consultas conservan el desplazamiento y volver regresa a Inventario',
    (tester) async {
      await abrir(tester);
      await pulsar(tester, find.byKey(const ValueKey('modulo-reportes')));
      await tester.drag(find.byType(ListView).first, const Offset(0, -300));
      await tester.pumpAndSettle();
      final anterior = tester
          .widget<ListView>(find.byType(ListView).first)
          .controller!
          .offset;
      expect(anterior, greaterThan(0));
      await pulsar(tester, find.byKey(const ValueKey('modulo-gastos')));
      await pulsar(tester, find.byKey(const ValueKey('modulo-reportes')));
      expect(
        tester.widget<ListView>(find.byType(ListView).first).controller!.offset,
        anterior,
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        0,
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('El producto muestra COP y no guarda un importe ambiguo', (
    tester,
  ) async {
    final repo = await abrir(tester);
    await pulsar(tester, find.byTooltip('Registrar producto'));
    await completarProducto(tester);
    expect(find.text('Se registrará: \$ 6.000,50 COP'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('costo-producto')),
      '6.000',
    );
    await pulsar(tester, find.byKey(const ValueKey('guardar-producto')));
    expect(
      find.text('Sin miles y máximo 2 decimales. Ej.: 6000,50'),
      findsOneWidget,
    );
    await tester.runAsync(
      () async => expect(await repo.obtenerTodos(), hasLength(2)),
    );
    await tester.enterText(
      find.byKey(const ValueKey('costo-producto')),
      '6000,50',
    );
    await pulsar(tester, find.byKey(const ValueKey('guardar-producto')));
    expect(find.byKey(const ValueKey('guardar-producto')), findsNothing);
    await tester.runAsync(() async {
      expect((await repo.obtenerTodos()).last.costoCompra, 6000.5);
    });
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Volver protege cambios y salir de un producto vacío no pregunta',
    (tester) async {
      final repo = await abrir(tester);
      await pulsar(tester, find.byTooltip('Registrar producto'));
      await pulsar(tester, find.byType(BackButton));
      expect(find.text('¿Descartar los cambios?'), findsNothing);
      await pulsar(tester, find.byTooltip('Registrar producto'));
      await tester.enterText(
        find.byKey(const ValueKey('nombre-producto')),
        'Borrador',
      );
      await pulsar(tester, find.byType(BackButton));
      expect(find.text('¿Descartar los cambios?'), findsOneWidget);
      await pulsar(tester, find.byKey(const ValueKey('seguir-editando')));
      expect(find.text('Borrador'), findsOneWidget);
      await pulsar(tester, find.byType(BackButton));
      await pulsar(tester, find.byKey(const ValueKey('descartar-cambios')));
      await tester.runAsync(
        () async => expect(await repo.obtenerTodos(), hasLength(2)),
      );
    },
  );

  testWidgets('Cancelar y el regreso del sistema protegen un gasto escrito', (
    tester,
  ) async {
    final repo = await abrir(tester);
    await pulsar(tester, find.byKey(const ValueKey('modulo-gastos')));
    await pulsar(tester, find.byKey(const ValueKey('nuevo-gasto')));
    await tester.enterText(
      find.byKey(const ValueKey('concepto-gasto')),
      'Energía',
    );
    await pulsar(tester, find.text('Cancelar'));
    await pulsar(tester, find.byKey(const ValueKey('seguir-editando')));
    expect(find.text('Energía'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('¿Descartar los cambios?'), findsOneWidget);
    await pulsar(tester, find.byKey(const ValueKey('descartar-cambios')));
    await tester.runAsync(
      () async => expect(await repo.obtenerGastos(), isEmpty),
    );
  });

  testWidgets(
    'Cambiar de módulo conserva búsqueda, período y borrador de venta',
    (tester) async {
      final repo = await abrir(tester);
      await tester.enterText(
        find.byKey(const ValueKey('buscar-producto')),
        'Arroz',
      );
      await pulsar(tester, find.byKey(const ValueKey('modulo-reportes')));
      await pulsar(tester, find.byKey(const ValueKey('periodo-rapido-0')));
      await pulsar(tester, find.byKey(const ValueKey('modulo-ventas')));
      await pulsar(tester, find.byKey(const ValueKey('nueva-venta')));
      await pulsar(tester, find.byType(DropdownButtonFormField<String>));
      await pulsar(tester, find.text('Arroz').last);
      await tester.enterText(
        find.byKey(const ValueKey('cantidad-linea-0')),
        '2',
      );
      await pulsar(tester, find.byKey(const ValueKey('modulo-gastos')));
      expect(find.byKey(const ValueKey('nuevo-gasto')), findsOneWidget);
      await pulsar(tester, find.byKey(const ValueKey('modulo-ventas')));
      final cantidad = tester.widget<EditableText>(
        find.descendant(
          of: find.byKey(const ValueKey('cantidad-linea-0')),
          matching: find.byType(EditableText),
        ),
      );
      expect(cantidad.controller.text, '2');
      await pulsar(tester, find.byKey(const ValueKey('revisar-operacion')));
      await pulsar(tester, find.byKey(const ValueKey('confirmar-operacion')));
      await pulsar(tester, find.byKey(const ValueKey('modulo-inventario')));
      expect(find.byKey(const ValueKey('producto-A')), findsOneWidget);
      expect(find.text('8 unidades disponibles'), findsOneWidget);
      expect(find.byKey(const ValueKey('producto-B')), findsNothing);
      await pulsar(tester, find.byKey(const ValueKey('modulo-reportes')));
      expect(
        find.text('Desde: ${FechaNegocio.mostrar(FechaNegocio.hoy())}'),
        findsOneWidget,
      );
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('reporte-ingresos-netos')))
            .data,
        '\$ 20.000 COP',
      );
      await tester.runAsync(
        () async => expect((await repo.obtenerPorId('A'))!.cantidad, 8),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Durante el guardado del producto no se puede volver ni cambiar de módulo',
    (tester) async {
      final repo = _RepositorioLento();
      await abrir(tester, repo: repo);
      await pulsar(tester, find.byTooltip('Registrar producto'));
      await completarProducto(tester);
      final guardar = find.byKey(const ValueKey('guardar-producto'));
      await tester.ensureVisible(guardar);
      await tester.pumpAndSettle();
      await tester.tap(guardar);
      await tester.pump();
      await tester.binding.handlePopRoute();
      await tester.tap(find.byKey(const ValueKey('modulo-gastos')));
      await tester.pump();
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        0,
      );
      expect(tester.widget<FilledButton>(guardar).onPressed, isNull);
      repo.continuar.complete();
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('guardar-producto')), findsNothing);
      await tester.runAsync(
        () async => expect(await repo.obtenerTodos(), hasLength(1)),
      );
    },
  );
}

class _RepositorioLento extends RepositorioSimulado {
  _RepositorioLento() : super(retardo: Duration.zero, productosIniciales: []);
  final continuar = Completer<void>();
  @override
  Future<Producto> crearProducto({
    required String nombre,
    required double costoCompra,
    required double precioVenta,
  }) async {
    await continuar.future;
    return super.crearProducto(
      nombre: nombre,
      costoCompra: costoCompra,
      precioVenta: precioVenta,
    );
  }
}
