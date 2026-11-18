import 'package:finanzasist/data/repositorio_simulado.dart';
import 'package:finanzasist/main.dart';
import 'package:finanzasist/models/operacion.dart';
import 'package:finanzasist/models/producto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'soporte_guias.dart';

Future<RepositorioSimulado> iniciar(
  WidgetTester tester, {
  int cantidad = 15,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(360, 800);
  addTearDown(tester.view.reset);
  final repo = RepositorioSimulado(
    retardo: const Duration(milliseconds: 30),
    productosIniciales: [
      Producto(
        id: 'A',
        nombre: 'Arroz de 1 kg',
        cantidad: cantidad,
        costoCompra: 3500,
        precioVenta: 10000,
      ),
    ],
  );
  await tester.pumpWidget(
    FinanzAsistApp(repositorio: repo, almacenGuias: guiasRevisadas()),
  );
  await tester.pumpAndSettle();
  return repo;
}

Future<void> pulsar(WidgetTester tester, Finder finder) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  await Scrollable.ensureVisible(tester.element(finder), alignment: 0.5);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> preparar(
  WidgetTester tester,
  TipoOperacion tipo, {
  String cantidad = '4',
}) async {
  await pulsar(
    tester,
    find.text(tipo == TipoOperacion.compra ? 'Compras' : 'Ventas'),
  );
  await pulsar(
    tester,
    find.byKey(
      ValueKey(tipo == TipoOperacion.compra ? 'nueva-compra' : 'nueva-venta'),
    ),
  );
  await pulsar(tester, find.byType(DropdownButtonFormField<String>));
  await tester.tap(find.text('Arroz de 1 kg').last);
  await tester.pumpAndSettle();
  await tester.enterText(
    find.byKey(const ValueKey('cantidad-linea-0')),
    cantidad,
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'HU05 CA03 venta confirma una vez y refresca 15 a 11 en lista y detalle',
    (tester) async {
      final repo = await iniciar(tester);
      await preparar(tester, TipoOperacion.venta);
      await tester.enterText(
        find.byKey(const ValueKey('descuento-venta')),
        '2000',
      );
      await pulsar(tester, find.byKey(const ValueKey('revisar-operacion')));
      expect(find.text('Total: \$ 38.000 COP'), findsOneWidget);
      expect(find.text('Existencias después: 11 unidades'), findsOneWidget);
      expect(tester.takeException(), isNull);
      final confirmar = find.byKey(const ValueKey('confirmar-operacion'));
      await tester.ensureVisible(confirmar);
      await tester.tap(confirmar);
      await tester.pump();
      expect(tester.widget<FilledButton>(confirmar).onPressed, isNull);
      await tester.tap(confirmar);
      await tester.pumpAndSettle();
      expect(find.text('\$ 38.000 COP'), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('11 unidades disponibles'), findsOneWidget);
      await pulsar(tester, find.byKey(const ValueKey('producto-A')));
      expect(find.text('11 unidades'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Venta · -4 unidades'), 140);
      await tester.pumpAndSettle();
      expect(find.text('Venta · -4 unidades'), findsOneWidget);
      expect(tester.takeException(), isNull);
      final consulta = repo.obtenerOperaciones(tipo: TipoOperacion.venta);
      await tester.pump(const Duration(milliseconds: 50));
      expect(await consulta, hasLength(1));
    },
  );

  for (final tipo in [TipoOperacion.compra, TipoOperacion.venta]) {
    testWidgets('${tipo.name}: cancelar el resumen mantiene el inventario', (
      tester,
    ) async {
      final repo = await iniciar(tester);
      await preparar(tester, tipo);
      await pulsar(tester, find.byKey(const ValueKey('revisar-operacion')));
      await pulsar(tester, find.text('Cancelar'));
      await pulsar(tester, find.byKey(const ValueKey('descartar-cambios')));
      expect(await repo.obtenerOperaciones(), isEmpty);
      final consulta = repo.obtenerPorId('A');
      await tester.pump(const Duration(milliseconds: 50));
      expect((await consulta)!.cantidad, 15);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'HU07 borrador sobrevive a pausa y resumen cabe con teclado a 360 dp',
    (tester) async {
      final repo = await iniciar(tester, cantidad: 10);
      await preparar(tester, TipoOperacion.compra);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      final campo = tester.widget<TextFormField>(
        find.byKey(const ValueKey('cantidad-linea-0')),
      );
      expect(campo.initialValue, '4');
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      await tester.pumpAndSettle();
      await pulsar(tester, find.byKey(const ValueKey('revisar-operacion')));
      expect(find.text('Total: \$ 14.000 COP'), findsOneWidget);
      expect(tester.takeException(), isNull);
      expect(await repo.obtenerOperaciones(), isEmpty);
      tester.view.viewInsets = FakeViewPadding.zero;
      await pulsar(tester, find.byKey(const ValueKey('confirmar-operacion')));
      expect(find.text('\$ 14.000 COP'), findsOneWidget);
    },
  );

  testWidgets('HU06 valida motivo junto al campo y refleja apertura y ajuste', (
    tester,
  ) async {
    await iniciar(tester, cantidad: 0);
    await pulsar(tester, find.byKey(const ValueKey('producto-A')));
    await pulsar(tester, find.byKey(const ValueKey('existencias-iniciales')));
    await tester.enterText(
      find.byKey(const ValueKey('cantidad-linea-0')),
      '20',
    );
    await pulsar(tester, find.byKey(const ValueKey('revisar-operacion')));
    expect(find.text('Indica el motivo del movimiento'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('motivo-movimiento')),
      'Inventario de apertura',
    );
    await pulsar(tester, find.byKey(const ValueKey('revisar-operacion')));
    await pulsar(tester, find.byKey(const ValueKey('confirmar-operacion')));
    expect(find.text('20 unidades'), findsOneWidget);
    await pulsar(tester, find.byKey(const ValueKey('ajustar-inventario')));
    await tester.enterText(
      find.byKey(const ValueKey('cantidad-linea-0')),
      '-2',
    );
    await tester.enterText(
      find.byKey(const ValueKey('motivo-movimiento')),
      'Diferencia de conteo',
    );
    await pulsar(tester, find.byKey(const ValueKey('revisar-operacion')));
    await pulsar(tester, find.byKey(const ValueKey('confirmar-operacion')));
    expect(find.text('18 unidades'), findsOneWidget);
    expect(find.text('Diferencia de conteo'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'HU08 muestra errores de cantidad y descuento junto a sus campos',
    (tester) async {
      final repo = await iniciar(tester, cantidad: 3);
      await preparar(tester, TipoOperacion.venta);
      await pulsar(tester, find.byKey(const ValueKey('revisar-operacion')));
      expect(find.text('No hay existencias suficientes'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('cantidad-linea-0')),
        '2',
      );
      await tester.enterText(
        find.byKey(const ValueKey('descuento-venta')),
        '20001',
      );
      await pulsar(tester, find.byKey(const ValueKey('revisar-operacion')));
      expect(
        find.text('El descuento debe estar entre cero y el subtotal'),
        findsOneWidget,
      );
      expect(await repo.obtenerOperaciones(), isEmpty);
      expect(tester.takeException(), isNull);
    },
  );
}
