import 'package:finanzasist/data/repositorio_simulado.dart';
import 'package:finanzasist/main.dart';
import 'package:finanzasist/models/fecha_negocio.dart';
import 'package:finanzasist/models/gasto.dart';
import 'package:finanzasist/models/operacion.dart';
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

Future<void> abrir(WidgetTester tester, RepositorioSimulado repo) async {
  tester.view.physicalSize = const Size(360, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    FinanzAsistApp(repositorio: repo, almacenGuias: guiasRevisadas()),
  );
  await tester.pumpAndSettle();
}

Future<void> completar(WidgetTester tester) async {
  await pulsar(tester, find.byKey(const ValueKey('fecha-gasto')));
  await pulsar(tester, find.text('Usar fecha'));
  await tester.enterText(
    find.byKey(const ValueKey('concepto-gasto')),
    'Servicio de energía',
  );
  await pulsar(tester, find.byKey(const ValueKey('categoria-gasto')));
  await tester.tap(find.text('Servicios').last);
  await tester.pumpAndSettle();
  await tester.enterText(find.byKey(const ValueKey('valor-gasto')), '80000');
}

void main() {
  testWidgets(
    'HU10 campos obligatorios, fecha en español y valor positivo a 360 dp',
    (tester) async {
      final repo = RepositorioSimulado(
        retardo: Duration.zero,
        productosIniciales: [],
      );
      await abrir(tester, repo);
      await pulsar(tester, find.text('Gastos'));
      expect(find.text('Aún no tienes gastos registrados'), findsOneWidget);
      await pulsar(tester, find.byKey(const ValueKey('nuevo-gasto')));
      await pulsar(tester, find.byKey(const ValueKey('guardar-gasto')));
      expect(find.text('Selecciona una fecha válida'), findsOneWidget);
      expect(find.text('Escribe el concepto del gasto'), findsOneWidget);
      expect(find.text('Selecciona una categoría'), findsOneWidget);
      await completar(tester);
      await tester.enterText(find.byKey(const ValueKey('valor-gasto')), '0');
      await pulsar(tester, find.byKey(const ValueKey('guardar-gasto')));
      expect(find.text('El valor debe ser mayor que cero'), findsOneWidget);
      expect(await repo.obtenerGastos(), isEmpty);
      await tester.enterText(
        find.byKey(const ValueKey('valor-gasto')),
        '80000',
      );
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      await tester.pumpAndSettle();
      await pulsar(tester, find.byKey(const ValueKey('guardar-gasto')));
      expect(find.text('Servicio de energía'), findsOneWidget);
      expect(find.text('\$ 80.000 COP'), findsOneWidget);
      expect((await repo.obtenerGastos()).single.valorCentavos, 8000000);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Gasto bloquea doble toque mientras se guarda', (tester) async {
    final repo = _GastoLento();
    await abrir(tester, repo);
    await pulsar(tester, find.text('Gastos'));
    await pulsar(tester, find.byKey(const ValueKey('nuevo-gasto')));
    await completar(tester);
    final guardar = find.byKey(const ValueKey('guardar-gasto'));
    await tester.ensureVisible(guardar);
    await tester.pumpAndSettle();
    await tester.tap(guardar);
    await tester.pump();
    expect(tester.widget<FilledButton>(guardar).onPressed, isNull);
    await tester.tap(guardar);
    await tester.pumpAndSettle();
    expect(await repo.obtenerGastos(), hasLength(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Cancelar gasto no crea registros', (tester) async {
    final repo = RepositorioSimulado(retardo: Duration.zero);
    await abrir(tester, repo);
    await pulsar(tester, find.text('Gastos'));
    await pulsar(tester, find.byKey(const ValueKey('nuevo-gasto')));
    await completar(tester);
    await pulsar(tester, find.text('Cancelar'));
    await pulsar(tester, find.byKey(const ValueKey('descartar-cambios')));
    expect(await repo.obtenerGastos(), isEmpty);
  });

  testWidgets('HU14 reporte vacío y fechas invertidas a 360 dp', (
    tester,
  ) async {
    final repo = RepositorioSimulado(
      retardo: Duration.zero,
      productosIniciales: [],
    );
    await abrir(tester, repo);
    await pulsar(tester, find.text('Reportes'));
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('reporte-utilidad-resultante')),
      220,
    );
    expect(find.text('No hay operaciones para este período'), findsOneWidget);
    expect(
      tester
          .widget<Text>(
            find.byKey(const ValueKey('reporte-utilidad-resultante')),
          )
          .data,
      '\$ 0 COP',
    );
    await pulsar(tester, find.byKey(const ValueKey('desde-reporte')));
    // Cambia a entrada de texto para seleccionar una fecha posterior a Hasta.
    await pulsar(
      tester,
      find.byTooltip(
        MaterialLocalizations.of(tester.element(find.byType(DatePickerDialog)))
            .inputDateModeButtonLabel,
      ),
    );
    final fecha = FechaNegocio.hoy().add(const Duration(days: 1));
    await tester.enterText(
      find.byType(TextField).last,
      FechaNegocio.mostrar(fecha),
    );
    await pulsar(tester, find.text('Usar fecha'));
    await pulsar(tester, find.byKey(const ValueKey('consultar-reporte')));
    expect(
      find.text('La fecha inicial no puede ser posterior a la final'),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('reporte-utilidad-resultante')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'HU14 utilidad incluye gastos y conserva costo histórico tras editar catálogo',
    (tester) async {
      final repo = RepositorioSimulado(
        retardo: Duration.zero,
        productosIniciales: [],
      );
      await tester.runAsync(() async {
        final producto = await repo.crearProducto(
          nombre: 'Café',
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
        await repo.registrarGasto(
          SolicitudGasto(
            id: nuevoId(),
            fecha: FechaNegocio.hoy(),
            concepto: 'Gastos del período',
            categoria: 'Servicios',
            valor: 150000,
          ),
        );
        await repo.actualizarProducto(
          id: producto.id,
          nombre: 'Café',
          costoCompra: 70000,
          precioVenta: 120000,
        );
      });
      await abrir(tester, repo);
      await pulsar(tester, find.text('Reportes'));
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('reporte-utilidad-resultante')),
        200,
      );
      expect(
        tester
            .widget<Text>(
              find.byKey(const ValueKey('reporte-utilidad-resultante')),
            )
            .data,
        '\$ 250.000 COP',
      );
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('reporte-costo-ventas')))
            .data,
        '\$ 500.000 COP',
      );
      expect(tester.takeException(), isNull);
    },
  );
}

class _GastoLento extends RepositorioSimulado {
  _GastoLento() : super(retardo: Duration.zero, productosIniciales: []);
  @override
  Future<Gasto> registrarGasto(SolicitudGasto solicitud) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return super.registrarGasto(solicitud);
  }
}
