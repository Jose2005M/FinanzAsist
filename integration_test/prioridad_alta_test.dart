import 'package:finanzasist/data/almacen_guias.dart';
import 'package:finanzasist/data/repositorio_sqlite.dart';
import 'package:finanzasist/main.dart';
import 'package:finanzasist/models/guia_modulo.dart';
import 'package:finanzasist/models/operacion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Importes seguros, descarte, borradores y navegación con SQLite',
    (tester) async {
      final ruta = path.join(
        await getDatabasesPath(),
        'qa-prioridad-${nuevoId()}.db',
      );
      var repo = RepositorioSqlite(ruta: ruta);
      addTearDown(() async {
        await repo.cerrar();
        await deleteDatabase(ruta);
      });
      final producto = await repo.crearProducto(
        nombre: 'Arroz QA',
        costoCompra: 6000,
        precioVenta: 10000,
      );
      await repo.confirmarOperacion(
        SolicitudOperacion(
          id: nuevoId(),
          tipo: TipoOperacion.inicial,
          motivo: 'Apertura QA',
          lineas: [
            LineaOperacion(
              productoId: producto.id,
              cantidad: 10,
              valorUnitario: 6000,
            ),
          ],
        ),
      );
      var superficie = false;
      Future<void> captura(String nombre) async {
        if (!const bool.fromEnvironment('CAPTURAS')) return;
        if (!superficie) {
          await binding.convertFlutterSurfaceToImage();
          superficie = true;
        }
        await tester.pumpAndSettle();
        await binding.takeScreenshot(nombre);
      }

      Future<void> pulsar(Finder finder) async {
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
        await Scrollable.ensureVisible(tester.element(finder), alignment: 0.5);
        await tester.pumpAndSettle();
        await tester.tap(finder.hitTestable());
        await tester.pumpAndSettle();
      }

      Future<void> escribir(String clave, String texto) async {
        final campo = find.byKey(ValueKey(clave));
        await tester.ensureVisible(campo);
        await tester.pumpAndSettle();
        binding.focusedEditable = null;
        await tester.enterText(campo, texto);
        await tester.pumpAndSettle();
      }

      await tester.pumpWidget(
        FinanzAsistApp(
          repositorio: repo,
          almacenGuias: AlmacenGuiasMemoria(vistas: ModuloGuia.values.toSet()),
        ),
      );
      await tester.pumpAndSettle();
      await pulsar(find.byTooltip('Registrar producto'));
      await escribir('nombre-producto', 'Café QA');
      await escribir('costo-producto', '6.000');
      await escribir('precio-producto', '12000');
      await pulsar(find.byKey(const ValueKey('guardar-producto')));
      expect(
        find.text('Sin miles y máximo 2 decimales. Ej.: 6000,50'),
        findsOneWidget,
      );
      expect(await repo.obtenerTodos(), hasLength(1));
      await captura('prioridad-importe-ambiguo');
      await escribir('costo-producto', '6000,50');
      expect(find.text('Se registrará: \$ 6.000,50 COP'), findsOneWidget);
      await captura('prioridad-equivalencia-cop');

      await pulsar(find.byType(BackButton));
      await captura('prioridad-descartar-cambios');
      await pulsar(find.byKey(const ValueKey('seguir-editando')));
      await pulsar(find.byKey(const ValueKey('modulo-gastos')));
      expect(find.byKey(const ValueKey('nuevo-gasto')), findsOneWidget);
      await pulsar(find.byKey(const ValueKey('modulo-inventario')));
      expect(find.text('Café QA'), findsOneWidget);
      await pulsar(find.byType(BackButton));
      await pulsar(find.byKey(const ValueKey('descartar-cambios')));
      expect(await repo.obtenerTodos(), hasLength(1));

      await pulsar(find.byKey(const ValueKey('modulo-ventas')));
      await pulsar(find.byKey(const ValueKey('nueva-venta')));
      await pulsar(find.byType(DropdownButtonFormField<String>));
      await pulsar(find.text('Arroz QA').last);
      await escribir('cantidad-linea-0', '2');
      await pulsar(find.byKey(const ValueKey('modulo-compras')));
      await pulsar(find.byKey(const ValueKey('nueva-compra')));
      await pulsar(find.byType(DropdownButtonFormField<String>));
      await pulsar(find.text('Arroz QA').last);
      await escribir('cantidad-linea-0', '5');
      await pulsar(find.byKey(const ValueKey('revisar-operacion')));
      await pulsar(find.byKey(const ValueKey('confirmar-operacion')));
      await pulsar(find.byKey(const ValueKey('modulo-reportes')));
      await pulsar(find.byKey(const ValueKey('periodo-rapido-0')));
      await captura('prioridad-navegacion-directa');
      await pulsar(find.byKey(const ValueKey('modulo-ventas')));
      final cantidad = tester.widget<EditableText>(
        find.descendant(
          of: find.byKey(const ValueKey('cantidad-linea-0')),
          matching: find.byType(EditableText),
        ),
      );
      expect(cantidad.controller.text, '2');
      await pulsar(find.byKey(const ValueKey('revisar-operacion')));
      expect(find.text('Existencias después: 13 unidades'), findsOneWidget);
      await pulsar(find.text('Volver a editar'));
      await captura('prioridad-borrador-conservado');
      await pulsar(find.byKey(const ValueKey('revisar-operacion')));
      await pulsar(find.byKey(const ValueKey('confirmar-operacion')));
      await pulsar(find.byKey(const ValueKey('modulo-inventario')));
      expect(find.text('13 unidades disponibles'), findsOneWidget);

      await pulsar(find.byKey(const ValueKey('modulo-gastos')));
      await pulsar(find.byKey(const ValueKey('nuevo-gasto')));
      await pulsar(find.byKey(const ValueKey('fecha-gasto')));
      await pulsar(find.text('Usar fecha'));
      await escribir('concepto-gasto', 'Servicio de energía');
      await pulsar(find.byKey(const ValueKey('categoria-gasto')));
      await pulsar(find.text('Servicios').last);
      await escribir('valor-gasto', '6000,50');
      await pulsar(find.byKey(const ValueKey('guardar-gasto')));
      await pulsar(find.byKey(const ValueKey('modulo-reportes')));
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('reporte-ingresos-netos')))
            .data,
        '\$ 20.000 COP',
      );
      expect(
        tester.widget<Text>(find.byKey(const ValueKey('reporte-gastos'))).data,
        '\$ 6.000,50 COP',
      );
      expect(
        tester
            .widget<Text>(
              find.byKey(const ValueKey('reporte-utilidad-resultante')),
            )
            .data,
        '\$ 1.999,50 COP',
      );
      await Scrollable.ensureVisible(
        tester.element(
          find.byKey(const ValueKey('reporte-utilidad-resultante')),
        ),
      );
      await captura('prioridad-reporte-actualizado');

      await repo.cerrar();
      repo = RepositorioSqlite(ruta: ruta);
      expect((await repo.obtenerPorId(producto.id))!.cantidad, 13);
      expect((await repo.obtenerGastos()).single.valorCentavos, 600050);
      expect(tester.takeException(), isNull);
    },
  );
}
