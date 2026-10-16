import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finanzasist/data/repositorio_simulado.dart';
import 'package:finanzasist/main.dart';
import 'package:finanzasist/models/producto.dart';

void configurarPantalla(WidgetTester tester) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(360, 800);
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

Future<void> abrirInventario(WidgetTester tester) async {
  configurarPantalla(tester);
  await tester.pumpWidget(
    FinanzAsistApp(
      repositorio: RepositorioSimulado(
        retardo: const Duration(milliseconds: 10),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'Los cuatro estados se muestran a 360 dp y el error se recupera',
    (tester) async {
      await abrirInventario(tester);
      expect(find.text('Arroz de 1 kg'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('escenario-vacio')));
      await tester.pumpAndSettle();
      expect(find.text('Aún no tienes productos'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('registrar-desde-vacio')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);

      await tester.tap(find.byKey(const ValueKey('escenario-error')));
      await tester.pumpAndSettle();
      expect(find.text('No pudimos cargar el inventario'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();
      expect(find.text('Arroz de 1 kg'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('escenario-cargando')));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('Consultando inventario...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.byKey(const ValueKey('escenario-conDatos')));
      await tester.pumpAndSettle();
      expect(find.text('Arroz de 1 kg'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'El detalle mantiene la identidad y las existencias del producto',
    (tester) async {
      await abrirInventario(tester);
      final producto = find.byKey(const ValueKey('producto-P003'));
      await tester.ensureVisible(producto);
      await tester.pumpAndSettle();
      await tester.tap(producto);
      await tester.pumpAndSettle();

      expect(find.text('Detalle del producto'), findsOneWidget);
      expect(find.text('Azúcar de 1 kg'), findsOneWidget);
      expect(find.text('P003'), findsOneWidget);
      expect(find.text('15 unidades'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Inventario'), findsOneWidget);
    },
  );

  testWidgets('Un producto con cero unidades se identifica como agotado', (
    tester,
  ) async {
    await abrirInventario(tester);
    final producto = find.byKey(const ValueKey('producto-P005'));
    await tester.scrollUntilVisible(producto, 180);
    await tester.tap(producto);
    await tester.pumpAndSettle();

    expect(find.text('Jabón en barra'), findsOneWidget);
    expect(find.text('0 unidades'), findsOneWidget);
    expect(find.text('Agotado'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Registrar desde vacío agrega el producto y vuelve al inventario',
    (tester) async {
      await abrirInventario(tester);
      await tester.tap(find.byKey(const ValueKey('escenario-vacio')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('registrar-desde-vacio')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey('nombre-producto')),
        'Café de 500 g',
      );
      await tester.enterText(
        find.byKey(const ValueKey('costo-producto')),
        '8000',
      );
      await tester.enterText(
        find.byKey(const ValueKey('precio-producto')),
        '11000',
      );
      await tester.ensureVisible(find.text('Guardar producto'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Guardar producto'));
      await tester.pumpAndSettle();

      expect(find.text('Inventario'), findsOneWidget);
      expect(find.text('Café de 500 g'), findsOneWidget);
      expect(find.text('0 unidades disponibles'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Los nombres largos se muestran completos a 360 dp', (
    tester,
  ) async {
    configurarPantalla(tester);
    const nombre =
        'Detergente líquido para ropa delicada presentación '
        'familiar de 4 litros';
    await tester.pumpWidget(
      FinanzAsistApp(
        repositorio: RepositorioSimulado(
          retardo: Duration.zero,
          productosIniciales: const [
            Producto(
              id: 'LARGO',
              nombre: nombre,
              cantidad: 15,
              costoCompra: 10000,
              precioVenta: 14000,
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    final texto = tester.widget<Text>(find.text(nombre));
    expect(texto.maxLines, isNull);
    expect(texto.overflow, isNot(TextOverflow.ellipsis));
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const ValueKey('producto-LARGO')));
    await tester.pumpAndSettle();
    expect(find.text(nombre), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
