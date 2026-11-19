// PBKDF2 con 600 000 iteraciones: en paralelo con otros archivos que
// también derivan claves, una prueba puede superar los 30 s por defecto.
@Timeout.factor(4)
library;

import 'dart:io';

import 'package:finanzasist/data/administracion_local.dart';
import 'package:finanzasist/data/autenticacion_local.dart';
import 'package:finanzasist/data/base_datos_local.dart';
import 'package:finanzasist/data/repositorio_sqlite.dart';
import 'package:finanzasist/data/respaldo_local.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const clave = 'mi frase de acceso 2026';
const claveAdmin = 'clave del administrador';
const propietario = DatosRegistro(
  empresa: 'Tienda Central',
  propietario: 'Jose Torres',
  correo: 'dueno@empresa.com',
  clave: clave,
);
const otroPropietario = DatosRegistro(
  empresa: 'Otra Tienda',
  propietario: 'Ana Ruiz',
  correo: 'ana@otra.com',
  clave: clave,
);
const administrador = DatosAdministrador(
  nombre: 'Laura Gómez',
  correo: 'admin@finanzasist.com',
  clave: claveAdmin,
);

Matcher accesoCon(String texto) => throwsA(
  isA<AccesoException>().having((e) => e.mensaje, 'mensaje', contains(texto)),
);

/// Cuentas creadas una sola vez: cada PBKDF2 cuesta 600 000 iteraciones y
/// repetirlo en cada prueba hace lenta toda la suite.
enum Plantilla { unPropietario, unPropietarioYAdmin, dos, dosYAdmin }

void main() {
  sqfliteFfiInit();
  late Directory directorio;
  late BaseDatosLocal base;
  late AutenticacionLocal auth;
  late Directory plantillas;
  String rutaPlantilla(Plantilla p) => '${plantillas.path}/${p.name}.db';

  setUpAll(() async {
    plantillas = await Directory.systemTemp.createTemp('finanzasist-plant-');
    Future<void> preparar(
      Plantilla destino,
      Plantilla? origen,
      Future<void> Function(AutenticacionLocal auth) accion,
    ) async {
      if (origen != null) {
        await File(rutaPlantilla(origen)).copy(rutaPlantilla(destino));
      }
      final base = BaseDatosLocal(
        factory: databaseFactoryFfi,
        ruta: rutaPlantilla(destino),
      );
      final auth = AutenticacionLocal(base: base);
      await accion(auth);
      auth.dispose();
      await base.cerrar();
    }

    Future<void> crearAdmin(AutenticacionLocal auth) => auth.crearAdministrador(
      administrador,
      correoPropietario: propietario.correo,
      clavePropietario: clave,
    );
    await preparar(
      Plantilla.unPropietario,
      null,
      (a) => a.registrar(propietario),
    );
    await preparar(
      Plantilla.unPropietarioYAdmin,
      Plantilla.unPropietario,
      crearAdmin,
    );
    await preparar(
      Plantilla.dos,
      Plantilla.unPropietario,
      (a) => a.registrar(otroPropietario),
    );
    await preparar(Plantilla.dosYAdmin, Plantilla.dos, crearAdmin);
  });
  tearDownAll(() => plantillas.delete(recursive: true));

  setUp(() async {
    directorio = await Directory.systemTemp.createTemp('finanzasist-admin-');
    base = BaseDatosLocal(
      factory: databaseFactoryFfi,
      ruta: '${directorio.path}/finanzasist.db',
    );
    auth = AutenticacionLocal(base: base);
  });
  tearDown(() async {
    auth.dispose();
    await base.cerrar();
    await directorio.delete(recursive: true);
  });

  Future<void> usar(Plantilla plantilla) async {
    await base.cerrar();
    await File(rutaPlantilla(plantilla)).copy(base.ruta!);
  }

  Future<void> registrarPropietarios() => usar(Plantilla.dos);

  Future<void> entrarComoAdministrador() async {
    await usar(Plantilla.dosYAdmin);
    await auth.iniciarSesion(administrador.correo, claveAdmin);
  }

  Future<void> crearAdministrador() => auth.crearAdministrador(
    administrador,
    correoPropietario: propietario.correo,
    clavePropietario: clave,
  );

  AdministracionLocal administracion() =>
      AdministracionLocal(base: base, sesion: auth.sesion!);

  Future<String> idCuenta(String correo) async =>
      (await administracion().listarCuentas())
          .firstWhere((c) => c.correo == correo)
          .id;

  group('Crear administrador', () {
    test('no se ofrece en un dispositivo sin cuentas', () async {
      expect(await auth.puedeCrearAdministrador(), isFalse);
      await expectLater(
        crearAdministrador(),
        accesoCon('Correo o contraseña del propietario incorrectos'),
      );
    });

    test('con la autorización de un propietario inicia su sesión', () async {
      await registrarPropietarios();
      expect(await auth.puedeCrearAdministrador(), isTrue);

      await crearAdministrador();

      expect(auth.sesion!.esAdministrador, isTrue);
      expect(auth.sesion!.propietario, 'Laura Gómez');
      expect(await auth.puedeCrearAdministrador(), isFalse);
    });

    test('rechaza credenciales de propietario incorrectas', () async {
      await registrarPropietarios();
      for (final (correo, claveDada) in [
        (propietario.correo, 'otra frase de acceso'),
        ('nadie@empresa.com', clave),
      ]) {
        await expectLater(
          auth.crearAdministrador(
            administrador,
            correoPropietario: correo,
            clavePropietario: claveDada,
          ),
          accesoCon('Correo o contraseña del propietario incorrectos'),
        );
      }
      expect(auth.sesion, isNull);
      expect(await auth.puedeCrearAdministrador(), isTrue);
    });

    test('un propietario desactivado no puede autorizar', () async {
      await registrarPropietarios();
      await (await base.abrir).update(
        'cuentas',
        {'activa': 0},
        where: 'correo = ?',
        whereArgs: [propietario.correo],
      );
      await expectLater(
        crearAdministrador(),
        accesoCon('Correo o contraseña del propietario incorrectos'),
      );
    });

    test('solo puede existir un administrador', () async {
      await usar(Plantilla.dosYAdmin);

      await expectLater(
        auth.crearAdministrador(
          const DatosAdministrador(
            nombre: 'Segundo Admin',
            correo: 'otro-admin@finanzasist.com',
            clave: claveAdmin,
          ),
          correoPropietario: otroPropietario.correo,
          clavePropietario: clave,
        ),
        accesoCon('Ya existe un administrador'),
      );
    });

    test('valida los datos y que el correo no esté registrado', () async {
      await registrarPropietarios();
      for (final (datos, mensaje) in [
        (
          const DatosAdministrador(
            nombre: 'Laura',
            correo: 'admin@finanzasist.com',
            clave: 'corta',
          ),
          'Usa entre 8 y 128 caracteres.',
        ),
        (
          const DatosAdministrador(
            nombre: 'Laura',
            correo: 'no-es-correo',
            clave: claveAdmin,
          ),
          'Escribe un correo válido',
        ),
        (
          const DatosAdministrador(
            nombre: 'Laura',
            correo: ' ANA@otra.com ',
            clave: claveAdmin,
          ),
          'Este correo ya tiene una cuenta',
        ),
      ]) {
        await expectLater(
          auth.crearAdministrador(
            datos,
            correoPropietario: propietario.correo,
            clavePropietario: clave,
          ),
          accesoCon(mensaje),
        );
      }
      expect(await auth.puedeCrearAdministrador(), isTrue);
    });

    test('el administrador vuelve a entrar con su correo y clave', () async {
      await usar(Plantilla.dosYAdmin);

      await auth.iniciarSesion(administrador.correo, claveAdmin);

      expect(auth.sesion!.esAdministrador, isTrue);
    });
  });

  group('Permisos por rol', () {
    test('el administrador no accede a los datos de ningún negocio', () async {
      await entrarComoAdministrador();

      final repositorio = RepositorioSqlite.conSesion(
        base: base,
        sesion: auth.sesion!,
      );
      await expectLater(
        repositorio.obtenerTodos(),
        throwsA(isA<AccesoException>()),
      );
      await expectLater(
        RespaldoLocal(base: base).exportar(sesion: auth.sesion),
        throwsA(isA<RespaldoException>()),
      );
    });

    test('un propietario no puede usar la administración', () async {
      await usar(Plantilla.unPropietario);
      await auth.iniciarSesion(propietario.correo, clave);
      await expectLater(
        administracion().listarCuentas(),
        accesoCon('Solo el administrador'),
      );
    });

    test('el respaldo cuenta solo las cuentas de propietario', () async {
      await usar(Plantilla.unPropietarioYAdmin);
      await auth.iniciarSesion(propietario.correo, clave);

      final bytes = await RespaldoLocal(base: base)
          .exportar(sesion: auth.sesion);

      expect(bytes, isNotEmpty);
    });
  });

  group('Gestión de cuentas', () {
    setUp(entrarComoAdministrador);

    test('lista todas las cuentas sin datos de contraseña', () async {
      final cuentas = await administracion().listarCuentas();

      expect(cuentas.map((c) => c.correo), [
        'admin@finanzasist.com',
        'ana@otra.com',
        'dueno@empresa.com',
      ]);
      final admin = cuentas.first;
      expect(admin.rol, RolCuenta.administrador);
      expect(admin.propietario, 'Laura Gómez');
      final ana = cuentas[1];
      expect(ana.rol, RolCuenta.propietario);
      expect(ana.empresa, 'Otra Tienda');
      expect(ana.propietario, 'Ana Ruiz');
      expect(ana.activa, isTrue);
    });

    test('desactivar impide el acceso y reactivar lo devuelve', () async {
      final id = await idCuenta(propietario.correo);

      await administracion().cambiarEstado(id, activa: false);
      final duenoApp = AutenticacionLocal(base: base);
      addTearDown(duenoApp.dispose);
      await expectLater(
        duenoApp.iniciarSesion(propietario.correo, clave),
        accesoCon('desactivada'),
      );
      // Sin la contraseña correcta no se revela el estado de la cuenta.
      await expectLater(
        duenoApp.iniciarSesion(propietario.correo, 'otra frase de acceso'),
        accesoCon('Correo o contraseña incorrectos'),
      );

      await administracion().cambiarEstado(id, activa: true);
      expect(
        (await administracion().listarCuentas())
            .firstWhere((c) => c.id == id)
            .activa,
        isTrue,
      );
      await duenoApp.iniciarSesion(propietario.correo, clave);
      expect(duenoApp.sesion!.esAdministrador, isFalse);
    });

    test('una sesión de administrador cerrada no administra', () async {
      final admin = auth.sesion!;
      auth.cerrarSesion();
      await expectLater(
        AdministracionLocal(base: base, sesion: admin).listarCuentas(),
        accesoCon('Tu sesión'),
      );
    });

    test('desactivar invalida la sesión abierta del propietario', () async {
      final adminAuth = auth;
      final otraApp = AutenticacionLocal(base: base);
      addTearDown(otraApp.dispose);
      await otraApp.iniciarSesion(propietario.correo, clave);
      final repositorio = RepositorioSqlite.conSesion(
        base: base,
        sesion: otraApp.sesion!,
      );
      await repositorio.obtenerTodos();

      await administracion().cambiarEstado(
        await idCuenta(propietario.correo),
        activa: false,
      );

      await expectLater(
        repositorio.obtenerTodos(),
        throwsA(isA<AccesoException>()),
      );
      expect(adminAuth.sesion!.esAdministrador, isTrue);
    });

    test('no puede desactivarse ni cambiar su propia clave aquí', () async {
      final id = await idCuenta(administrador.correo);
      await expectLater(
        administracion().cambiarEstado(id, activa: false),
        accesoCon('cuentas de propietario'),
      );
      await expectLater(
        administracion().restablecerClave(id, 'nueva clave segura'),
        accesoCon('cuentas de propietario'),
      );
    });

    test('restablecer la contraseña reemplaza la anterior', () async {
      final id = await idCuenta(propietario.correo);

      await administracion().restablecerClave(id, 'clave restablecida 1');
      auth.cerrarSesion();

      await expectLater(
        auth.iniciarSesion(propietario.correo, clave),
        accesoCon('Correo o contraseña incorrectos'),
      );
      await auth.iniciarSesion(propietario.correo, 'clave restablecida 1');
      expect(auth.sesion!.correo, propietario.correo);
    });

    test('valida la nueva contraseña y la cuenta', () async {
      final id = await idCuenta(propietario.correo);
      await expectLater(
        administracion().restablecerClave(id, 'corta'),
        accesoCon('Usa entre 8 y 128 caracteres.'),
      );
      await expectLater(
        administracion().restablecerClave('no-existe', 'clave valida 123'),
        accesoCon('no existe'),
      );
      await expectLater(
        administracion().cambiarEstado('no-existe', activa: false),
        accesoCon('no existe'),
      );
    });
  });

  test('migra cuentas de la versión 4 como propietarias', () async {
    await usar(Plantilla.unPropietario);
    final db = await base.abrir;
    await db.execute('DROP INDEX un_administrador');
    await db.execute('ALTER TABLE cuentas DROP COLUMN rol');
    await db.execute('PRAGMA user_version = 4');
    auth.dispose();
    await base.cerrar();
    base = BaseDatosLocal(factory: databaseFactoryFfi, ruta: base.ruta);
    auth = AutenticacionLocal(base: base);

    await auth.iniciarSesion(propietario.correo, clave);

    expect(await (await base.abrir).getVersion(), BaseDatosLocal.version);
    expect(auth.sesion!.esAdministrador, isFalse);
    expect(await auth.puedeCrearAdministrador(), isTrue);
  });
}
