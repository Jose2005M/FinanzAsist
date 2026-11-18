import 'package:finanzasist/data/repositorio_sqlite.dart';
import 'package:finanzasist/main.dart';
import 'package:finanzasist/data/almacen_guias.dart';
import 'package:finanzasist/models/guia_modulo.dart';
import 'package:finanzasist/models/fecha_negocio.dart';
import 'package:finanzasist/models/operacion.dart';
import 'package:finanzasist/models/reporte_financiero.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

Future<void> pulsar(WidgetTester tester, Finder finder) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  await Scrollable.ensureVisible(tester.element(finder), alignment: 0.5);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Android: gastos y reporte de utilidad 250000 con costos históricos',
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

      final empresa = 'qa-finanzas-${nuevoId()}';
      final rutaQa = path.join(await getDatabasesPath(), '$empresa.db');
      var repo = RepositorioSqlite(
        ruta: rutaQa,
        empresaId: empresa,
        usuarioId: 'prueba-finanzas',
      );
      addTearDown(() async {
        await repo.cerrar();
        await deleteDatabase(rutaQa);
      });
      final producto = await repo.crearProducto(
        nombre: 'Café QA',
        costoCompra: 50000,
        precioVenta: 100000,
      );
      await repo.confirmarOperacion(
        SolicitudOperacion(
          id: nuevoId(),
          tipo: TipoOperacion.compra,
          lineas: [
            LineaOperacion(
              productoId: producto.id,
              cantidad: 10,
              valorUnitario: 60000,
            ),
          ],
        ),
      );
      await repo.confirmarOperacion(
        SolicitudOperacion(
          id: nuevoId(),
          tipo: TipoOperacion.venta,
          descuento: 100000,
          lineas: [
            LineaOperacion(
              productoId: producto.id,
              cantidad: 10,
              valorUnitario: 100000,
            ),
          ],
        ),
      );
      await repo.actualizarProducto(
        id: producto.id,
        nombre: producto.nombre,
        costoCompra: 70000,
        precioVenta: 120000,
      );
      await tester.pumpWidget(
        FinanzAsistApp(
          repositorio: repo,
          almacenGuias: AlmacenGuiasMemoria(vistas: ModuloGuia.values.toSet()),
        ),
      );
      await tester.pumpAndSettle();
      await pulsar(tester, find.text('Gastos'));
      for (final valor in ['80000', '70000']) {
        await pulsar(tester, find.byKey(const ValueKey('nuevo-gasto')));
        await pulsar(tester, find.byKey(const ValueKey('fecha-gasto')));
        await pulsar(tester, find.text('Usar fecha'));
        await tester.enterText(
          find.byKey(const ValueKey('concepto-gasto')),
          valor == '80000' ? 'Servicio de energía' : 'Arriendo QA',
        );
        await pulsar(tester, find.byKey(const ValueKey('categoria-gasto')));
        await tester.tap(
          find.text(valor == '80000' ? 'Servicios' : 'Arriendo').last,
        );
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const ValueKey('valor-gasto')),
          valor,
        );
        await pulsar(tester, find.byKey(const ValueKey('guardar-gasto')));
      }
      expect(find.text('\$ 80.000 COP'), findsOneWidget);
      expect(find.text('\$ 70.000 COP'), findsOneWidget);
      await capturar('08-gastos');
      await pulsar(tester, find.byType(BackButton));
      await pulsar(tester, find.text('Reportes'));
      await pulsar(tester, find.byKey(const ValueKey('periodo-rapido-0')));
      expect(
        find.text('Desde: ${FechaNegocio.mostrar(FechaNegocio.hoy())}'),
        findsOneWidget,
      );
      await capturar('guias-reporte-hoy');
      await pulsar(tester, find.byKey(const ValueKey('periodo-rapido-2')));
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('reporte-ingresos-netos')))
            .data,
        '\$ 900.000 COP',
      );
      await capturar('09-reporte-ingresos');
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('reporte-utilidad-resultante')),
        180,
      );
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('reporte-costo-ventas')))
            .data,
        '\$ 500.000 COP',
      );
      expect(
        tester
            .widget<Text>(
              find.byKey(const ValueKey('reporte-utilidad-resultante')),
            )
            .data,
        '\$ 250.000 COP',
      );
      await capturar('10-reporte-utilidad');
      await repo.cerrar();
      repo = RepositorioSqlite(
        ruta: rutaQa,
        empresaId: empresa,
        usuarioId: 'prueba-finanzas',
      );
      expect(await repo.obtenerGastos(), hasLength(2));
      final hoy = FechaNegocio.hoy();
      final reporte = await repo.obtenerReporte(
        PeriodoReporte(desde: DateTime.utc(hoy.year, hoy.month), hasta: hoy),
      );
      expect(reporte.utilidadResultanteCentavos, 25000000);
      await repo.cerrar();
      expect(tester.takeException(), isNull);
    },
  );
}
