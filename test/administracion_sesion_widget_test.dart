@Timeout.factor(4)
library;

import 'dart:io';

import 'package:finanzasist/data/autenticacion_local.dart';
import 'package:finanzasist/data/base_datos_local.dart';
import 'package:finanzasist/screens/administracion_screen.dart';
import 'package:finanzasist/screens/negocio_screen.dart';
import 'package:finanzasist/screens/sesion_screen.dart';
import 'package:finanzasist/widgets/guia_modulo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Directory carpeta;
  late String plantilla;
  setUpAll(() async {
    sqfliteFfiInit();
    carpeta = await Directory.systemTemp.createTemp('admin-widget-');
    plantilla = '${carpeta.path}/plantilla.db';
    final base = BaseDatosLocal(factory: databaseFactoryFfi, ruta: plantilla);
    final auth = AutenticacionLocal(base: base);
    try {
      await auth.registrar(
        const DatosRegistro(
          empresa: 'Empresa',
          propietario: 'Propietaria',
          correo: 'duena@empresa.com',
          clave: 'clave propietaria',
        ),
      );
      auth.cerrarSesion();
      await auth.crearAdministrador(
        const DatosAdministrador(
          nombre: 'Administradora',
          correo: 'admin@empresa.com',
          clave: 'clave administradora',
        ),
        correoPropietario: 'duena@empresa.com',
        clavePropietario: 'clave propietaria',
      );
    } finally {
      auth.dispose();
      await base.cerrar();
    }
  });
  tearDownAll(() => carpeta.delete(recursive: true));

  testWidgets(
    'la sesión de administrador muestra solo su panel, sin negocio ni guías',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final ruta = '${carpeta.path}/caso.db';
      final base = BaseDatosLocal(factory: databaseFactoryFfi, ruta: ruta);
      final auth = AutenticacionLocal(base: base);
      addTearDown(() async {
        auth.dispose();
        await base.cerrar();
      });
      await tester.runAsync(() async {
        await File(plantilla).copy(ruta);
        await auth.iniciarSesion('admin@empresa.com', 'clave administradora');
        await tester.pumpWidget(
          MaterialApp(home: SesionScreen(autenticacion: auth)),
        );
        // Espera la consulta real del panel, fuera del reloj simulado del tester.
        await (await base.abrir).transaction((_) async {});
      });
      await tester.pumpAndSettle();
      expect(find.byType(AdministracionScreen), findsOneWidget);
      expect(find.text('Usuarios del dispositivo'), findsOneWidget);
      expect(find.byType(NegocioScreen), findsNothing);
      expect(find.byType(AreaGuias), findsNothing);
      expect(
        find.byKey(const ValueKey('estado-admin@empresa.com')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
