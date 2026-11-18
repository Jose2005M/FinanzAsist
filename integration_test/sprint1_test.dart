import 'package:finanzasist/data/repositorio_sqlite.dart';
import 'package:finanzasist/main.dart';
import 'package:finanzasist/data/almacen_guias.dart';
import 'package:finanzasist/models/guia_modulo.dart';
import 'package:finanzasist/models/operacion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

Future<void> pulsar(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Sprint 1 Android: producto, apertura, ajuste, compra, venta y reapertura SQLite',
    (tester) async {
      const capturas = bool.fromEnvironment('CAPTURAS');
      var superficieConvertida = false;
      Future<void> capturar(String nombre) async {
        if (!capturas) return;
        if (!superficieConvertida) {
          await binding.convertFlutterSurfaceToImage();
          superficieConvertida = true;
        }
        await tester.pumpAndSettle();
        await binding.takeScreenshot(nombre);
      }

      // Empresa de prueba independiente: nunca modifica los registros del negocio local.
      final empresa = 'qa-${nuevoId()}';
      final rutaQa = path.join(await getDatabasesPath(), '$empresa.db');
      var repo = RepositorioSqlite(
        ruta: rutaQa,
        empresaId: empresa,
        usuarioId: 'prueba-android',
      );
      addTearDown(() async {
        await repo.cerrar();
        await deleteDatabase(rutaQa);
      });
      await tester.pumpWidget(
        FinanzAsistApp(
          repositorio: repo,
          almacenGuias: AlmacenGuiasMemoria(vistas: ModuloGuia.values.toSet()),
        ),
      );
      await tester.pumpAndSettle();
      await capturar('01-inventario-vacio');
      await pulsar(tester, find.byKey(const ValueKey('registrar-desde-vacio')));
      await tester.enterText(
        find.byKey(const ValueKey('nombre-producto')),
        'Arroz QA',
      );
      await tester.enterText(
        find.byKey(const ValueKey('costo-producto')),
        '6000',
      );
      await tester.enterText(
        find.byKey(const ValueKey('precio-producto')),
        '10000',
      );
      await capturar('02-producto');
      await pulsar(tester, find.byKey(const ValueKey('guardar-producto')));
      final producto = (await repo.obtenerTodos()).single;
      await pulsar(tester, find.byKey(ValueKey('producto-${producto.id}')));
      await pulsar(tester, find.byKey(const ValueKey('existencias-iniciales')));
      await tester.enterText(
        find.byKey(const ValueKey('cantidad-linea-0')),
        '20',
      );
      await tester.enterText(
        find.byKey(const ValueKey('motivo-movimiento')),
        'Inventario de apertura',
      );
      await pulsar(tester, find.byKey(const ValueKey('revisar-operacion')));
      await pulsar(tester, find.byKey(const ValueKey('confirmar-operacion')));
      expect(find.text('20 unidades'), findsOneWidget);
      await capturar('03-detalle-apertura');
      await pulsar(tester, find.byKey(const ValueKey('ajustar-inventario')));
      await tester.enterText(
        find.byKey(const ValueKey('cantidad-linea-0')),
        '-10',
      );
      await tester.enterText(
        find.byKey(const ValueKey('motivo-movimiento')),
        'Conteo QA',
      );
      await capturar('04-ajuste');
      await pulsar(tester, find.byKey(const ValueKey('revisar-operacion')));
      await pulsar(tester, find.byKey(const ValueKey('confirmar-operacion')));
      expect(find.text('10 unidades'), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      for (final compra in [true, false]) {
        await pulsar(tester, find.text(compra ? 'Compras' : 'Ventas'));
        await pulsar(
          tester,
          find.byKey(ValueKey(compra ? 'nueva-compra' : 'nueva-venta')),
        );
        await pulsar(tester, find.byType(DropdownButtonFormField<String>));
        await tester.tap(find.text('Arroz QA').last);
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const ValueKey('cantidad-linea-0')),
          compra ? '5' : '4',
        );
        if (!compra) {
          await tester.enterText(
            find.byKey(const ValueKey('descuento-venta')),
            '2000',
          );
        }
        await pulsar(tester, find.byKey(const ValueKey('revisar-operacion')));
        expect(
          find.text(compra ? 'Total: \$ 30.000 COP' : 'Total: \$ 38.000 COP'),
          findsOneWidget,
        );
        await capturar(compra ? '05-compra-resumen' : '06-venta-resumen');
        await pulsar(tester, find.byKey(const ValueKey('confirmar-operacion')));
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
        expect(
          find.text('${compra ? 15 : 11} unidades disponibles'),
          findsOneWidget,
        );
      }
      await capturar('07-inventario-once');
      final buscar = find.byKey(const ValueKey('buscar-producto'));
      await tester.ensureVisible(buscar);
      await tester.enterText(buscar, 'ARROZ');
      await tester.pumpAndSettle();
      expect(find.text('11 unidades disponibles'), findsOneWidget);
      await capturar('guias-busqueda-producto');
      await tester.enterText(buscar, 'no existe');
      await tester.pumpAndSettle();
      expect(find.text('No encontramos ese producto'), findsOneWidget);
      await pulsar(tester, find.byTooltip('Limpiar búsqueda'));
      expect(find.text('11 unidades disponibles'), findsOneWidget);
      await repo.cerrar();
      repo = RepositorioSqlite(
        ruta: rutaQa,
        empresaId: empresa,
        usuarioId: 'prueba-android',
      );
      expect((await repo.obtenerTodos()).single.cantidad, 11);
      expect(await repo.obtenerMovimientos(), hasLength(4));
      expect(
        (await repo.obtenerOperaciones(tipo: TipoOperacion.venta))
            .single
            .totalCentavos,
        3800000,
      );
      await repo.cerrar();
      expect(tester.takeException(), isNull);
    },
  );
}
