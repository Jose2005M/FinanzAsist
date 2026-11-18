import 'package:finanzasist/data/repositorio_simulado.dart';
import 'package:finanzasist/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'soporte_guias.dart';

Future<void> abrir(WidgetTester tester, {bool ampliado = false}) async {
  tester.view.physicalSize = ampliado
      ? const Size(320, 640)
      : const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final app = FinanzAsistApp(
    almacenGuias: guiasRevisadas(),
    repositorio: RepositorioSimulado(retardo: Duration.zero),
  );
  await tester.pumpWidget(app);
  if (ampliado) {
    final contexto = tester.element(find.byType(Scaffold).first);
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQuery.of(contexto)
            .copyWith(textScaler: const TextScaler.linear(2)),
        child: app,
      ),
    );
  }
  await tester.pumpAndSettle();
}

Future<void> pulsar(WidgetTester tester, Finder finder) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  await Scrollable.ensureVisible(tester.element(finder), alignment: 0.5);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Inventario y registro se desplazan con texto al 200 %', (
    tester,
  ) async {
    await abrir(tester, ampliado: true);
    await tester.scrollUntilVisible(
      find.byType(Card),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.byType(Card).first.hitTestable(), findsOneWidget);
    await pulsar(tester, find.byTooltip('Registrar producto'));
    tester.view.viewInsets = const FakeViewPadding(bottom: 250);
    await tester.pumpAndSettle();
    await pulsar(tester, find.byKey(const ValueKey('guardar-producto')));
    expect(find.text('Escribe el nombre del producto'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final modulo in ['Compras', 'Ventas', 'Gastos']) {
    testWidgets('$modulo y su formulario admiten 320 dp y texto al 200 %', (
      tester,
    ) async {
      await abrir(tester, ampliado: true);
      await pulsar(
        tester,
        find
            .byType(NavigationDestination)
            .at(
              modulo == 'Compras'
                  ? 1
                  : modulo == 'Ventas'
                  ? 2
                  : 3,
            ),
      );
      final clave = switch (modulo) {
        'Compras' => 'nueva-compra',
        'Ventas' => 'nueva-venta',
        _ => 'nuevo-gasto',
      };
      await pulsar(tester, find.byKey(ValueKey(clave)));
      await pulsar(tester, find.text('Cancelar'));
      expect(find.byKey(ValueKey(clave)), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Reporte completo accesible con texto al 200 %', (tester) async {
    await abrir(tester, ampliado: true);
    await pulsar(tester, find.byType(NavigationDestination).at(4));
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('reporte-utilidad-resultante')),
      240,
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('reporte-utilidad-resultante')).hitTestable(),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Módulos conservan contraste y controles táctiles accesibles', (
    tester,
  ) async {
    await abrir(tester);
    final semantica = tester.ensureSemantics();
    try {
      for (final modulo in [
        'Inventario',
        'Compras',
        'Ventas',
        'Gastos',
        'Reportes',
      ]) {
        if (modulo != 'Inventario') {
          await pulsar(tester, find.text(modulo));
        }
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        if (modulo != 'Inventario') {
          await pulsar(tester, find.byType(BackButton));
        }
      }
    } finally {
      semantica.dispose();
    }
  });
}
