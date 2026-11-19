import 'dart:typed_data';

import 'package:finanzasist/data/autenticacion_local.dart';
import 'package:finanzasist/data/base_datos_local.dart';
import 'package:finanzasist/data/repositorio_simulado.dart';
import 'package:finanzasist/data/respaldo_local.dart';
import 'package:finanzasist/data/selector_archivos.dart';
import 'package:finanzasist/screens/acceso_screen.dart';
import 'package:finanzasist/screens/inventario_screen.dart';
import 'package:finanzasist/widgets/acciones_respaldo.dart';
import 'package:finanzasist/widgets/guia_modulo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'soporte_guias.dart';

final _bytes = Uint8List.fromList([1, 2, 3]);

class RespaldoFalso extends RespaldoLocal {
  RespaldoFalso({this.sinCuentas = true, this.error})
    : super(base: BaseDatosLocal(factory: databaseFactoryFfi));
  bool sinCuentas;
  RespaldoException? error;
  final restaurados = <Uint8List>[];
  int exportaciones = 0;

  @override
  Future<bool> restauracionSinSesion() async => sinCuentas;

  @override
  Future<Uint8List> exportar({SesionEmpresa? sesion}) async {
    if (error case final error?) throw error;
    exportaciones++;
    return _bytes;
  }

  @override
  Future<void> restaurar(Uint8List bytes, {SesionEmpresa? sesion}) async {
    if (error case final error?) throw error;
    restaurados.add(bytes);
    sinCuentas = false;
  }
}

class SelectorFalso implements SelectorArchivos {
  SelectorFalso({this.cancelar = false});
  final bool cancelar;
  final guardados = <String, Uint8List>{};
  int elecciones = 0;

  @override
  Future<bool> guardar({
    required String nombre,
    required Uint8List bytes,
  }) async {
    if (cancelar) return false;
    guardados[nombre] = bytes;
    return true;
  }

  @override
  Future<Uint8List?> elegir({required int tamanoMaximo}) async {
    elecciones++;
    return cancelar ? null : _bytes;
  }
}

void main() {
  late AutenticacionLocal auth;
  setUp(
    () => auth = AutenticacionLocal(
      base: BaseDatosLocal(factory: databaseFactoryFfi),
    ),
  );
  tearDown(() => auth.dispose());

  Future<void> abrirAcceso(
    WidgetTester tester,
    AccionesRespaldo respaldo,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: AccesoScreen(autenticacion: auth, respaldo: respaldo),
      ),
    );
    await tester.pumpAndSettle();
  }

  final botonAcceso = find.byKey(const ValueKey('restaurar-respaldo-acceso'));

  Future<void> tocarRestaurarEnAcceso(WidgetTester tester) async {
    await tester.ensureVisible(botonAcceso);
    await tester.pumpAndSettle();
    await tester.tap(botonAcceso);
    await tester.pumpAndSettle();
  }

  group('Restaurar desde la pantalla de acceso', () {
    testWidgets('solo se ofrece si el dispositivo no tiene cuentas', (
      tester,
    ) async {
      final conCuentas = RespaldoFalso(sinCuentas: false);
      await abrirAcceso(
        tester,
        AccionesRespaldo(respaldo: conCuentas, selector: SelectorFalso()),
      );
      expect(botonAcceso, findsNothing);
    });

    testWidgets('confirma, restaura y oculta la opción', (tester) async {
      final respaldo = RespaldoFalso();
      await abrirAcceso(
        tester,
        AccionesRespaldo(respaldo: respaldo, selector: SelectorFalso()),
      );

      await tocarRestaurarEnAcceso(tester);
      expect(find.text('¿Reemplazar los datos?'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('confirmar-restauracion')));
      await tester.pumpAndSettle();

      expect(respaldo.restaurados, [_bytes]);
      expect(find.textContaining('Respaldo restaurado'), findsOneWidget);
      expect(botonAcceso, findsNothing);
    });

    testWidgets('cancelar la confirmación no cambia los datos', (tester) async {
      final respaldo = RespaldoFalso();
      await abrirAcceso(
        tester,
        AccionesRespaldo(respaldo: respaldo, selector: SelectorFalso()),
      );

      await tocarRestaurarEnAcceso(tester);
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(respaldo.restaurados, isEmpty);
      expect(botonAcceso, findsOneWidget);
    });

    testWidgets('cancelar la elección de archivo no pide confirmación', (
      tester,
    ) async {
      final respaldo = RespaldoFalso();
      final selector = SelectorFalso(cancelar: true);
      await abrirAcceso(
        tester,
        AccionesRespaldo(respaldo: respaldo, selector: selector),
      );

      await tocarRestaurarEnAcceso(tester);

      expect(selector.elecciones, 1);
      expect(find.text('¿Reemplazar los datos?'), findsNothing);
      expect(respaldo.restaurados, isEmpty);
    });

    testWidgets('muestra el motivo si el archivo no es válido', (tester) async {
      final respaldo = RespaldoFalso(
        error: const RespaldoException(
          'El archivo no es un respaldo de FinanzAsist.',
        ),
      );
      await abrirAcceso(
        tester,
        AccionesRespaldo(respaldo: respaldo, selector: SelectorFalso()),
      );

      await tocarRestaurarEnAcceso(tester);
      await tester.tap(find.byKey(const ValueKey('confirmar-restauracion')));
      await tester.pumpAndSettle();

      expect(
        find.text('El archivo no es un respaldo de FinanzAsist.'),
        findsOneWidget,
      );
      expect(botonAcceso, findsOneWidget);
    });
  });

  group('Menú de la cuenta', () {
    Future<void> abrirInventario(
      WidgetTester tester, {
      required AccionesRespaldo respaldo,
      required VoidCallback alRestaurar,
    }) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) =>
              AreaGuias(almacen: guiasRevisadas(), child: child!),
          home: Builder(
            builder: (context) => InventarioScreen(
              repositorio: RepositorioSimulado(retardo: Duration.zero),
              empresa: 'Tienda Central',
              correo: 'dueno@empresa.com',
              cerrarSesion: () {},
              exportarRespaldo: () => respaldo.exportar(context),
              restaurarRespaldo: () async {
                if (await respaldo.restaurar(context)) alRestaurar();
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> elegir(WidgetTester tester, String clave) async {
      await tester.tap(find.byTooltip('Cuenta de empresa'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ValueKey(clave)));
      await tester.pumpAndSettle();
    }

    testWidgets('exporta con un nombre de archivo fechado', (tester) async {
      final respaldo = RespaldoFalso(sinCuentas: false);
      final selector = SelectorFalso();
      await abrirInventario(
        tester,
        respaldo: AccionesRespaldo(respaldo: respaldo, selector: selector),
        alRestaurar: () {},
      );

      await elegir(tester, 'menu-exportar-respaldo');

      expect(selector.guardados.values.single, _bytes);
      expect(
        selector.guardados.keys.single,
        matches(RegExp(r'^finanzasist-respaldo-\d{4}-\d{2}-\d{2}-\d{4}\.db$')),
      );
      expect(find.textContaining('Respaldo guardado'), findsOneWidget);
    });

    testWidgets('cancelar el guardado no muestra confirmación', (tester) async {
      final respaldo = RespaldoFalso(sinCuentas: false);
      await abrirInventario(
        tester,
        respaldo: AccionesRespaldo(
          respaldo: respaldo,
          selector: SelectorFalso(cancelar: true),
        ),
        alRestaurar: () {},
      );

      await elegir(tester, 'menu-exportar-respaldo');

      expect(respaldo.exportaciones, 1);
      expect(find.textContaining('Respaldo guardado'), findsNothing);
    });

    testWidgets('restaurar confirma y avisa para cerrar la sesión', (
      tester,
    ) async {
      final respaldo = RespaldoFalso(sinCuentas: false);
      var sesionCerrada = false;
      await abrirInventario(
        tester,
        respaldo: AccionesRespaldo(
          respaldo: respaldo,
          selector: SelectorFalso(),
        ),
        alRestaurar: () => sesionCerrada = true,
      );

      await elegir(tester, 'menu-restaurar-respaldo');
      await tester.tap(find.byKey(const ValueKey('confirmar-restauracion')));
      await tester.pumpAndSettle();

      expect(respaldo.restaurados, [_bytes]);
      expect(sesionCerrada, isTrue);
    });

    testWidgets('sin respaldo configurado el menú no ofrece las opciones', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) =>
              AreaGuias(almacen: guiasRevisadas(), child: child!),
          home: InventarioScreen(
            repositorio: RepositorioSimulado(retardo: Duration.zero),
            empresa: 'Tienda Central',
            correo: 'dueno@empresa.com',
            cerrarSesion: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Cuenta de empresa'));
      await tester.pumpAndSettle();

      expect(find.text('Exportar respaldo'), findsNothing);
      expect(find.text('Restaurar respaldo'), findsNothing);
      expect(find.text('Cerrar sesión'), findsOneWidget);
    });
  });
}
