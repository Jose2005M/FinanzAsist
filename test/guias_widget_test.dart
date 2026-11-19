import 'package:finanzasist/data/almacen_guias.dart';
import 'package:finanzasist/data/repositorio_simulado.dart';
import 'package:finanzasist/main.dart';
import 'package:finanzasist/models/fecha_negocio.dart';
import 'package:finanzasist/models/guia_modulo.dart';
import 'package:finanzasist/models/producto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> pulsar(WidgetTester tester, Finder finder) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  await Scrollable.ensureVisible(tester.element(finder), alignment: 0.5);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> abrir(
  WidgetTester tester, {
  AlmacenGuias? guias,
  bool grande = false,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = grande
      ? const Size(320, 640)
      : const Size(390, 844);
  addTearDown(tester.view.reset);
  final app = FinanzAsistApp(
    almacenGuias: guias,
    repositorio: RepositorioSimulado(
      retardo: Duration.zero,
      productosIniciales: const [
        Producto(
          id: 'A',
          nombre: 'Café molido',
          cantidad: 8,
          costoCompra: 6000,
          precioVenta: 10000,
        ),
        Producto(
          id: 'B',
          nombre: 'Arroz de 1 kg',
          cantidad: 4,
          costoCompra: 3000,
          precioVenta: 5000,
        ),
      ],
    ),
  );
  await tester.pumpWidget(app);
  await tester.pumpAndSettle();
  if (grande) {
    final data = MediaQuery.of(tester.element(find.byType(Scaffold).first));
    await tester.pumpWidget(
      MediaQuery(
        data: data.copyWith(textScaler: const TextScaler.linear(2)),
        child: app,
      ),
    );
    await tester.pumpAndSettle();
  }
}

void main() {
  testWidgets(
    'La guía inicial mantiene contraste y controles táctiles accesibles',
    (tester) async {
      await abrir(tester);
      final semantica = tester.ensureSemantics();
      try {
        await pulsar(
          tester,
          find.byKey(const ValueKey('guia-pasos-inventario')),
        );
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
      } finally {
        semantica.dispose();
      }
    },
  );
  testWidgets(
    'Cada módulo explica su propósito y permite cerrar y reabrir la guía',
    (tester) async {
      await abrir(tester);
      for (final modulo in ModuloGuia.values) {
        if (modulo != ModuloGuia.inventario) {
          await pulsar(
            tester,
            find.byType(NavigationDestination).at(modulo.index),
          );
        }
        expect(find.text(modulo.proposito), findsOneWidget);
        await pulsar(
          tester,
          find.byKey(ValueKey('guia-entendido-${modulo.name}')),
        );
        expect(find.text(modulo.proposito), findsNothing);
        await pulsar(tester, find.byKey(ValueKey('guia-abrir-${modulo.name}')));
        expect(find.text('1. ${modulo.pasos.first}'), findsOneWidget);
        await pulsar(
          tester,
          find.byKey(ValueKey('guia-omitir-${modulo.name}')),
        );
        if (modulo != ModuloGuia.inventario) {
          await pulsar(tester, find.byType(BackButton));
          await pulsar(
            tester,
            find.byType(NavigationDestination).at(modulo.index),
          );
          expect(
            find.byKey(ValueKey('guia-abrir-${modulo.name}')),
            findsOneWidget,
          );
          await pulsar(tester, find.byType(BackButton));
        }
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets('La guía no vuelve a abrirse al reconstruir la aplicación', (
    tester,
  ) async {
    final almacen = AlmacenGuiasMemoria();
    await abrir(tester, guias: almacen);
    await pulsar(
      tester,
      find.byKey(const ValueKey('guia-entendido-inventario')),
    );
    await tester.pumpWidget(const SizedBox.shrink());
    await abrir(tester, guias: almacen);
    expect(find.byKey(const ValueKey('guia-abrir-inventario')), findsOneWidget);
    expect(find.text(ModuloGuia.inventario.proposito), findsNothing);
  });

  testWidgets(
    'Ayuda con texto al 200 % permite ver pasos y continuar usando el módulo',
    (tester) async {
      await abrir(tester, grande: true);
      await pulsar(tester, find.byKey(const ValueKey('guia-pasos-inventario')));
      await pulsar(
        tester,
        find.byKey(const ValueKey('guia-entendido-inventario')),
      );
      await pulsar(tester, find.byTooltip('Registrar producto'));
      expect(find.byKey(const ValueKey('guardar-producto')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Buscar ignora mayúsculas y tildes, y permite recuperar la lista',
    (tester) async {
      await abrir(
        tester,
        guias: AlmacenGuiasMemoria(vistas: ModuloGuia.values.toSet()),
      );
      final buscar = find.byKey(const ValueKey('buscar-producto'));
      await tester.enterText(buscar, 'CAFE');
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('producto-A')), findsOneWidget);
      expect(find.byKey(const ValueKey('producto-B')), findsNothing);
      await tester.enterText(buscar, 'inexistente');
      await tester.pumpAndSettle();
      expect(find.text('No encontramos ese producto'), findsOneWidget);
      await pulsar(tester, find.byTooltip('Limpiar búsqueda'));
      expect(find.byKey(const ValueKey('producto-A')), findsOneWidget);
      expect(find.byKey(const ValueKey('producto-B')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Períodos rápidos consultan hoy y siete días incluidos automáticamente',
    (tester) async {
      await abrir(
        tester,
        guias: AlmacenGuiasMemoria(vistas: ModuloGuia.values.toSet()),
      );
      await pulsar(tester, find.byType(NavigationDestination).at(4));
      final hoy = FechaNegocio.hoy();
      await pulsar(tester, find.byKey(const ValueKey('periodo-rapido-0')));
      expect(find.text('Desde: ${FechaNegocio.mostrar(hoy)}'), findsOneWidget);
      expect(
        find.text(
          '${FechaNegocio.mostrar(hoy)} al ${FechaNegocio.mostrar(hoy)}',
        ),
        findsOneWidget,
      );
      await pulsar(tester, find.byKey(const ValueKey('periodo-rapido-1')));
      expect(
        find.text(
          'Desde: ${FechaNegocio.mostrar(hoy.subtract(const Duration(days: 6)))}',
        ),
        findsOneWidget,
      );
      await pulsar(tester, find.byKey(const ValueKey('periodo-rapido-2')));
      expect(
        find.text(
          'Desde: ${FechaNegocio.mostrar(DateTime.utc(hoy.year, hoy.month))}',
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('reporte-utilidad-resultante')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
