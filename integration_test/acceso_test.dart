import 'package:finanzasist/data/autenticacion_local.dart';
import 'package:finanzasist/data/base_datos_local.dart';
import 'package:finanzasist/data/repositorio_sqlite.dart';
import 'package:finanzasist/main.dart';
import 'package:finanzasist/models/guia_modulo.dart';
import 'package:finanzasist/widgets/guia_modulo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

const claveQa = 'Acceso26';

class AutenticacionObservada extends AutenticacionLocal {
  AutenticacionObservada({required super.base});
  int intentos = 0;
  bool claveEsperada = false;
  @override
  Future<void> iniciarSesion(String correo, String clave) {
    intentos++;
    claveEsperada = clave == claveQa;
    return super.iniciarSesion(correo, clave);
  }
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Registro con 8 caracteres, salida, reingreso y limpieza de rutas',
    (tester) async {
      final ruta = path.join(
        await getDatabasesPath(),
        'qa-acceso-${DateTime.now().microsecondsSinceEpoch}.db',
      );
      final base = BaseDatosLocal(ruta: ruta);
      final auth = AutenticacionObservada(base: base);
      addTearDown(() async {
        auth.dispose();
        await base.cerrar();
        await deleteDatabase(ruta);
      });
      var superficieLista = false;
      Future<void> captura(String nombre) async {
        if (!const bool.fromEnvironment('CAPTURAS')) return;
        if (!superficieLista) {
          await binding.convertFlutterSurfaceToImage();
          superficieLista = true;
        }
        await tester.pumpAndSettle();
        await binding.takeScreenshot(nombre);
      }

      Future<void> pulsar(Finder boton) async {
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
        await Scrollable.ensureVisible(tester.element(boton), alignment: 0.5);
        await tester.pumpAndSettle();
        await tester.tap(boton.hitTestable());
        await tester.pumpAndSettle();
      }

      await tester.pumpWidget(FinanzAsistApp(autenticacion: auth));
      await tester.pumpAndSettle();
      await captura('acceso-inicio');
      await pulsar(find.byKey(const ValueKey('cambiar-acceso')));
      for (final campo in <String, String>{
        'empresa-registro': 'Tienda Los Juanchos',
        'propietario-registro': 'Propietario de prueba',
        'correo-acceso': 'pruebas@finanzasist.local',
        'clave-acceso': claveQa,
        'confirmacion-registro': claveQa,
      }.entries) {
        final finder = find.byKey(ValueKey(campo.key));
        await tester.ensureVisible(finder);
        await tester.enterText(finder, campo.value);
      }
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await captura('acceso-registro');
      await pulsar(find.byKey(const ValueKey('enviar-acceso')));
      expect(find.text('Tienda Los Juanchos'), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);

      for (final modulo in ModuloGuia.values) {
        if (modulo != ModuloGuia.inventario) {
          await pulsar(find.byType(NavigationDestination).at(modulo.index));
        }
        expect(find.text(modulo.proposito), findsOneWidget);
        await Scrollable.ensureVisible(
          tester.element(find.byType(GuiaModulo)),
          alignment: 0.1,
        );
        await tester.pumpAndSettle();
        await captura('guia-${modulo.name}');
        await pulsar(find.byKey(ValueKey('guia-entendido-${modulo.name}')));
        await pulsar(find.byKey(ValueKey('guia-abrir-${modulo.name}')));
        expect(find.text('1. ${modulo.pasos.first}'), findsOneWidget);
        await pulsar(find.byKey(ValueKey('guia-omitir-${modulo.name}')));
        if (modulo != ModuloGuia.inventario) {
          await pulsar(find.byType(BackButton));
        }
      }
      expect(await (await base.abrir).query('guias_vistas'), hasLength(5));

      final anterior = RepositorioSqlite.conSesion(
        base: base,
        sesion: auth.sesion!,
      );
      final producto = await anterior.crearProducto(
        nombre: 'Producto de mi empresa',
        costoCompra: 6000,
        precioVenta: 10000,
      );
      await pulsar(find.byTooltip('Actualizar inventario'));
      expect(find.text('Producto de mi empresa'), findsOneWidget);
      await captura('acceso-empresa');
      await pulsar(find.byTooltip('Cuenta de empresa'));
      await pulsar(find.text('Cerrar sesión'));
      expect(find.text('Inicia sesión'), findsOneWidget);
      expect(find.text('Producto de mi empresa'), findsNothing);
      expect(find.byType(NavigationBar), findsNothing);
      await expectLater(
        anterior.obtenerTodos(),
        throwsA(isA<AccesoException>()),
      );

      await tester.enterText(
        find.byKey(const ValueKey('correo-acceso')),
        'pruebas@finanzasist.local',
      );
      await tester.enterText(
        find.byKey(const ValueKey('clave-acceso')),
        'contraseña incorrecta',
      );
      await pulsar(find.byKey(const ValueKey('enviar-acceso')));
      expect(find.text('Correo o contraseña incorrectos.'), findsOneWidget);
      expect(auth.sesion, isNull);
      await captura('acceso-error');
      // El binding de integración conserva focusedEditable después de unfocus.
      // Restablecerlo permite que enterText vuelva a conectar el mismo campo.
      binding.focusedEditable = null;
      await tester.enterText(
        find.byKey(const ValueKey('clave-acceso')),
        claveQa,
      );
      await tester.pumpAndSettle();
      expect(
        tester
                .widget<TextFormField>(
                  find.byKey(const ValueKey('clave-acceso')),
                )
                .controller!
                .text ==
            claveQa,
        isTrue,
      );
      await pulsar(find.byKey(const ValueKey('enviar-acceso')));
      expect(auth.intentos, 2);
      expect(auth.claveEsperada, isTrue);
      expect(auth.sesion, isNotNull);
      expect(
        find.byKey(const ValueKey('guia-abrir-inventario')),
        findsOneWidget,
      );
      expect(find.text(ModuloGuia.inventario.proposito), findsNothing);
      expect(find.text('Producto de mi empresa'), findsOneWidget);

      await pulsar(find.byKey(ValueKey('producto-${producto.id}')));
      expect(find.text('Detalle del producto'), findsOneWidget);
      // Una salida con una ruta de detalle abierta elimina el navegador completo.
      auth.cerrarSesion();
      await tester.pumpAndSettle();
      expect(find.text('Inicia sesión'), findsOneWidget);
      expect(find.text('Detalle del producto'), findsNothing);
      expect(find.text('Producto de mi empresa'), findsNothing);
      expect(
        Navigator.of(tester.element(find.text('Inicia sesión'))).canPop(),
        isFalse,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
