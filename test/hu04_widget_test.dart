import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finanzasist/data/repositorio_simulado.dart';
import 'package:finanzasist/main.dart';

Future<RepositorioSimulado> abrirCatalogo(WidgetTester tester) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(360, 800);
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  final repositorio = RepositorioSimulado(
    retardo: const Duration(milliseconds: 30),
  );
  await tester.pumpWidget(FinanzAsistApp(repositorio: repositorio));
  await tester.pumpAndSettle();
  return repositorio;
}

Future<void> abrirEdicion(WidgetTester tester, String id) async {
  final fila = find.byKey(ValueKey('producto-$id'));
  await tester.scrollUntilVisible(fila, 160);
  await tester.tap(fila);
  await tester.pumpAndSettle();
  final editar = find.byKey(const ValueKey('editar-producto'));
  await tester.ensureVisible(editar);
  await tester.pumpAndSettle();
  await tester.tap(editar);
  await tester.pumpAndSettle();
}

Future<void> guardarFormulario(WidgetTester tester) async {
  final boton = find.byKey(const ValueKey('guardar-producto'));
  await tester.ensureVisible(boton);
  await tester.pumpAndSettle();
  await tester.tap(boton);
  await tester.pumpAndSettle();
}

Future<T> resolverConsulta<T>(WidgetTester tester, Future<T> consulta) async {
  // Avanza el reloj simulado de testWidgets para resolver el retardo de 30 ms.
  await tester.pump(const Duration(milliseconds: 40));
  return consulta;
}

void main() {
  testWidgets('HU04 CA01 muestra costo 6000 y precio 10000 al registrar', (
    tester,
  ) async {
    final repositorio = await abrirCatalogo(tester);
    await tester.tap(find.byTooltip('Registrar producto'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('nombre-producto')),
      'Café',
    );
    await tester.enterText(
      find.byKey(const ValueKey('costo-producto')),
      '6000',
    );
    await tester.enterText(
      find.byKey(const ValueKey('precio-producto')),
      '10000',
    );
    await guardarFormulario(tester);

    final fila = find.byKey(const ValueKey('producto-P006'));
    await tester.scrollUntilVisible(fila, 180);
    await tester.tap(fila);
    await tester.pumpAndSettle();
    expect(find.text('Café'), findsOneWidget);
    expect(find.text('\$ 6.000 COP'), findsOneWidget);
    expect(find.text('\$ 10.000 COP'), findsOneWidget);
    expect(
      await resolverConsulta(tester, repositorio.obtenerTodos()),
      hasLength(6),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('HU04 CA02 refresca detalle y catálogo conservando el id', (
    tester,
  ) async {
    final repositorio = await abrirCatalogo(tester);
    await abrirEdicion(tester, 'P001');
    final costo = tester.widget<TextFormField>(
      find.byKey(const ValueKey('costo-producto')),
    );
    expect(costo.controller?.text, '3500');
    expect(find.text('Identificador: P001'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('nombre-producto')),
      'Arroz de 1 kg Premium',
    );
    await tester.enterText(
      find.byKey(const ValueKey('costo-producto')),
      '6000',
    );
    await tester.enterText(
      find.byKey(const ValueKey('precio-producto')),
      '10000',
    );
    await guardarFormulario(tester);

    expect(find.text('Detalle del producto'), findsOneWidget);
    expect(find.text('P001'), findsOneWidget);
    expect(find.text('20 unidades'), findsOneWidget);
    expect(find.text('\$ 6.000 COP'), findsOneWidget);
    expect(find.text('\$ 10.000 COP'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pageBack();
    await tester.pumpAndSettle();
    final fila = find.byKey(const ValueKey('producto-P001'));
    await tester.ensureVisible(fila);
    await tester.pumpAndSettle();
    expect(find.text('Arroz de 1 kg Premium'), findsOneWidget);
    expect(find.text('Venta: \$ 10.000 COP'), findsOneWidget);
    expect(
      await resolverConsulta(tester, repositorio.obtenerTodos()),
      hasLength(5),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('HU04 CA03 señala campos inválidos sin agregar un producto', (
    tester,
  ) async {
    final repositorio = await abrirCatalogo(tester);
    await tester.tap(find.byTooltip('Registrar producto'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('nombre-producto')),
      '   ',
    );
    await tester.enterText(
      find.byKey(const ValueKey('costo-producto')),
      '-6000',
    );
    await tester.enterText(
      find.byKey(const ValueKey('precio-producto')),
      '-10000',
    );
    await guardarFormulario(tester);

    expect(find.text('Escribe el nombre del producto'), findsOneWidget);
    expect(
      find.text('El costo de compra no puede ser negativo'),
      findsOneWidget,
    );
    expect(
      find.text('El precio de venta no puede ser negativo'),
      findsOneWidget,
    );
    expect(
      await resolverConsulta(tester, repositorio.obtenerTodos()),
      hasLength(5),
    );
    expect(tester.takeException(), isNull);

    await tester.enterText(
      find.byKey(const ValueKey('nombre-producto')),
      'Café',
    );
    await tester.enterText(
      find.byKey(const ValueKey('costo-producto')),
      '6000',
    );
    await tester.enterText(
      find.byKey(const ValueKey('precio-producto')),
      '10000',
    );
    await guardarFormulario(tester);
    expect(find.text('Inventario'), findsOneWidget);
    expect(
      await resolverConsulta(tester, repositorio.obtenerTodos()),
      hasLength(6),
    );
  });

  testWidgets('Regresar sin guardar conserva el producto original', (
    tester,
  ) async {
    final repositorio = await abrirCatalogo(tester);
    await abrirEdicion(tester, 'P002');
    await tester.enterText(
      find.byKey(const ValueKey('nombre-producto')),
      'Nombre que no se guardará',
    );
    await tester.enterText(
      find.byKey(const ValueKey('costo-producto')),
      '6000',
    );
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('Detalle del producto'), findsOneWidget);
    expect(find.text('Aceite de 1 litro'), findsOneWidget);
    expect(find.text('\$ 7.000 COP'), findsOneWidget);
    final producto = await resolverConsulta(
      tester,
      repositorio.obtenerPorId('P002'),
    );
    expect(producto?.costoCompra, 7000);
    expect(producto?.cantidad, 12);
  });

  testWidgets(
    'El botón deshabilitado evita guardar dos veces durante el envío',
    (tester) async {
      final repositorio = await abrirCatalogo(tester);
      await tester.tap(find.byTooltip('Registrar producto'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('nombre-producto')),
        'Café',
      );
      await tester.enterText(
        find.byKey(const ValueKey('costo-producto')),
        '6000',
      );
      await tester.enterText(
        find.byKey(const ValueKey('precio-producto')),
        '10000',
      );
      final guardar = find.byKey(const ValueKey('guardar-producto'));
      await tester.ensureVisible(guardar);
      await tester.pumpAndSettle();
      await tester.tap(guardar);
      await tester.pump();
      final boton = tester.widget<FilledButton>(guardar);
      expect(boton.onPressed, isNull);
      await tester.tap(guardar);
      await tester.pumpAndSettle();

      final productos = await resolverConsulta(
        tester,
        repositorio.obtenerTodos(),
      );
      expect(productos, hasLength(6));
      expect(productos.where((p) => p.nombre == 'Café'), hasLength(1));
    },
  );
}
