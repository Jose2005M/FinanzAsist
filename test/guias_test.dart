import 'dart:io';

import 'package:finanzasist/data/almacen_guias.dart';
import 'package:finanzasist/data/autenticacion_local.dart';
import 'package:finanzasist/data/base_datos_local.dart';
import 'package:finanzasist/models/guia_modulo.dart';
import 'package:finanzasist/viewmodels/guias_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();

  test(
    'Las preferencias recuerdan cada módulo al reconstruir la ayuda',
    () async {
      final almacen = AlmacenGuiasMemoria();
      final primero = GuiasViewModel(almacen);
      await primero.cargar();
      expect(primero.vista(ModuloGuia.inventario), isFalse);
      expect(await primero.marcarVista(ModuloGuia.inventario), isTrue);
      primero.dispose();

      final segundo = GuiasViewModel(almacen);
      await segundo.cargar();
      expect(segundo.vista(ModuloGuia.inventario), isTrue);
      expect(segundo.vista(ModuloGuia.ventas), isFalse);
      segundo.dispose();
    },
  );

  test(
    'Si falla el almacenamiento la guía sigue disponible y puede ocultarse',
    () async {
      final modelo = GuiasViewModel(_AlmacenFallido());
      await modelo.cargar();
      expect(modelo.cargando, isFalse);
      expect(await modelo.marcarVista(ModuloGuia.gastos), isFalse);
      expect(modelo.vista(ModuloGuia.gastos), isTrue);
      modelo.dispose();
    },
  );

  test(
    'SQLite conserva las guías por cuenta y rechaza la sesión cerrada',
    () async {
      final directorio = await Directory.systemTemp.createTemp(
        'finanzasist-guias-',
      );
      final ruta = '${directorio.path}/preferencias.db';
      final base = BaseDatosLocal(factory: databaseFactoryFfi, ruta: ruta);
      final auth = AutenticacionLocal(base: base);
      addTearDown(() async {
        auth.dispose();
        await base.cerrar();
        await directorio.delete(recursive: true);
      });
      DatosRegistro registro(String correo) => DatosRegistro(
        empresa: 'Tienda de prueba',
        propietario: 'Propietario',
        correo: correo,
        clave: 'Acceso26',
      );
      await auth.registrar(registro('uno@tienda.com'));
      final primero = AlmacenGuiasSqlite(base: base, sesion: auth.sesion!);
      await primero.marcarVista(ModuloGuia.inventario);
      await primero.marcarVista(ModuloGuia.inventario);
      expect(await primero.leerVistas(), {ModuloGuia.inventario});
      expect(await (await base.abrir).query('guias_vistas'), hasLength(1));
      auth.cerrarSesion();
      await expectLater(primero.leerVistas(), throwsA(isA<AccesoException>()));
      await expectLater(
        primero.marcarVista(ModuloGuia.ventas),
        throwsA(isA<AccesoException>()),
      );

      await auth.registrar(registro('dos@tienda.com'));
      final segundo = AlmacenGuiasSqlite(base: base, sesion: auth.sesion!);
      expect(await segundo.leerVistas(), isEmpty);
      await segundo.marcarVista(ModuloGuia.ventas);
      auth.cerrarSesion();

      await base.cerrar();
      final reabierta = BaseDatosLocal(factory: databaseFactoryFfi, ruta: ruta);
      final nuevaAuth = AutenticacionLocal(base: reabierta);
      addTearDown(() async {
        nuevaAuth.dispose();
        await reabierta.cerrar();
      });
      await nuevaAuth.iniciarSesion('uno@tienda.com', 'Acceso26');
      final regreso = AlmacenGuiasSqlite(
        base: reabierta,
        sesion: nuevaAuth.sesion!,
      );
      expect(await regreso.leerVistas(), {ModuloGuia.inventario});
    },
  );

  test('Migrar v3 a v4 añade preferencias y conserva los datos del negocio', () async {
    final base = BaseDatosLocal(
      factory: databaseFactoryFfi,
      ruta: inMemoryDatabasePath,
    );
    addTearDown(base.cerrar);
    final db = await base.abrir;
    await db.insert('empresas', {'id': 'empresa-anterior'});
    await db.insert('productos', {
      'empresa': 'empresa-anterior',
      'id': 'producto',
      'nombre': 'Arroz',
      'cantidad': 7,
      'costo': 600000,
      'precio': 1000000,
    });
    // Abre un archivo v3 real para ejecutar onUpgrade, sin tocar la base del usuario.
    final ruta =
        '${(await databaseFactoryFfi.getDatabasesPath())}/qa-guias-${DateTime.now().microsecondsSinceEpoch}.db';
    final anterior = await databaseFactoryFfi.openDatabase(
      ruta,
      options: OpenDatabaseOptions(
        version: 3,
        onCreate: (copia, _) async {
          final tablas = await db.rawQuery(
            "SELECT sql FROM sqlite_master WHERE type = 'table' AND name NOT LIKE 'sqlite_%' AND name != 'guias_vistas'",
          );
          for (final tabla in tablas) {
            await copia.execute(tabla['sql'] as String);
          }
          await copia.insert('empresas', {'id': 'empresa-anterior'});
          await copia.insert('productos', (await db.query('productos')).single);
        },
      ),
    );
    await anterior.close();
    final actual = BaseDatosLocal(factory: databaseFactoryFfi, ruta: ruta);
    try {
      final migrada = await actual.abrir;
      expect(await migrada.getVersion(), BaseDatosLocal.version);
      expect((await migrada.query('productos')).single['cantidad'], 7);
      expect(await migrada.query('guias_vistas'), isEmpty);
    } finally {
      await actual.cerrar();
      await databaseFactoryFfi.deleteDatabase(ruta);
    }
  });
}

class _AlmacenFallido implements AlmacenGuias {
  @override
  Future<Set<ModuloGuia>> leerVistas() async => throw StateError('lectura');
  @override
  Future<void> marcarVista(ModuloGuia modulo) async =>
      throw StateError('escritura');
}
