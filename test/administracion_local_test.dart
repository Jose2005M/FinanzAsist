// PBKDF2 con 600 000 iteraciones: en paralelo con otros archivos que
// también derivan claves, una prueba puede superar los 30 s por defecto.
@Timeout.factor(4)
library;

import 'dart:io';

import 'package:finanzasist/data/administracion_dispositivo.dart';
import 'package:finanzasist/data/autenticacion_local.dart';
import 'package:finanzasist/data/base_datos_local.dart';
import 'package:finanzasist/data/repositorio_sqlite.dart';
import 'package:finanzasist/data/respaldo_local.dart';
import 'package:finanzasist/data/usuarios_empresa.dart';
import 'package:finanzasist/models/operacion.dart';
import 'package:finanzasist/models/reporte_financiero.dart';
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
    await preparar(Plantilla.unPropietario, null, (a) async {
      await a.registrar(propietario);
      await UsuariosEmpresa(base: a.base, sesion: a.sesion!).crearUsuario(
        const DatosUsuario(
          nombre: 'Trabajador',
          correo: 'empleado@empresa.com',
          clave: clave,
          rol: RolCuenta.vendedor,
        ),
      );
    });
    await preparar(
      Plantilla.unPropietarioYAdmin,
      Plantilla.unPropietario,
      crearAdmin,
    );
    await preparar(Plantilla.dos, Plantilla.unPropietario, (a) async {
      await a.registrar(otroPropietario);
      await UsuariosEmpresa(base: a.base, sesion: a.sesion!).crearUsuario(
        const DatosUsuario(
          nombre: 'Consulta',
          correo: 'consulta@otra.com',
          clave: clave,
          rol: RolCuenta.consulta,
        ),
      );
    });
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

  AdministracionDispositivo administracion() =>
      AdministracionDispositivo(base: base, sesion: auth.sesion!);

  Future<String> idCuenta(String correo) async =>
      (await (await base.abrir).query(
            'cuentas',
            columns: ['id'],
            where: 'correo = ?',
            whereArgs: [correo],
          )).single['id']
          as String;

  Future<List<CuentaResumen>> listarCuentas() async =>
      (await administracion().listarEmpresas())
          .expand((e) => e.cuentas)
          .toList();

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
      final db = await base.abrir;
      final antes = [
        await db.query('cuentas'),
        await db.query('empresas'),
        await db.query('usuarios'),
      ];
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
      expect([
        await db.query('cuentas'),
        await db.query('empresas'),
        await db.query('usuarios'),
      ], antes);
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
        repositorio.crearProducto(
          nombre: 'Producto',
          costoCompra: 1,
          precioVenta: 2,
        ),
        throwsA(isA<AccesoException>()),
      );
      await expectLater(
        repositorio.confirmarOperacion(
          SolicitudOperacion(
            id: 'denegada',
            tipo: TipoOperacion.compra,
            lineas: [
              LineaOperacion(
                productoId: 'producto',
                cantidad: 1,
                valorUnitario: 1,
              ),
            ],
          ),
        ),
        throwsA(isA<AccesoException>()),
      );
      await expectLater(
        repositorio.obtenerGastos(),
        throwsA(isA<AccesoException>()),
      );
      await expectLater(
        repositorio.obtenerReporte(
          PeriodoReporte(desde: DateTime(2026), hasta: DateTime(2026, 12, 31)),
        ),
        throwsA(isA<AccesoException>()),
      );
      await expectLater(
        UsuariosEmpresa(base: base, sesion: auth.sesion!).listarUsuarios(),
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
      await expectLater(listarCuentas(), accesoCon('Solo el administrador'));
      await expectLater(
        administracion().cambiarEstado(
          await idCuenta('empleado@empresa.com'),
          activa: false,
        ),
        accesoCon('Solo el administrador'),
      );
      await expectLater(
        administracion().restablecerClave(
          await idCuenta('empleado@empresa.com'),
          'nueva clave segura',
        ),
        accesoCon('Solo el administrador'),
      );
    });

    test('el respaldo cuenta solo las cuentas de propietario', () async {
      await usar(Plantilla.unPropietarioYAdmin);
      await auth.iniciarSesion(propietario.correo, clave);

      final bytes = await RespaldoLocal(base: base)
          .exportar(sesion: auth.sesion);

      expect(bytes, isNotEmpty);
      final adminAuth = AutenticacionLocal(base: base);
      addTearDown(adminAuth.dispose);
      await adminAuth.iniciarSesion(administrador.correo, claveAdmin);
      await expectLater(
        RespaldoLocal(base: base).restaurar(bytes, sesion: adminAuth.sesion),
        throwsA(isA<RespaldoException>()),
      );
    });
  });

  group('Gestión de cuentas', () {
    setUp(entrarComoAdministrador);

    for (final correo in [propietario.correo, 'empleado@empresa.com']) {
      test(
        '$correo: desactivar corta la sesión y reactivar la devuelve',
        () async {
          final otra = AutenticacionLocal(base: base);
          addTearDown(otra.dispose);
          await otra.iniciarSesion(correo, clave);
          final repo = RepositorioSqlite.conSesion(
            base: base,
            sesion: otra.sesion!,
          );
          final id = otra.sesion!.cuentaId;
          await repo.obtenerTodos();
          await administracion().cambiarEstado(id, activa: false);
          await expectLater(
            repo.obtenerTodos(),
            throwsA(isA<AccesoException>()),
          );
          await administracion().cambiarEstado(id, activa: true);
          expect(await repo.obtenerTodos(), isEmpty);
        },
      );

      test('$correo: restablecer exige la nueva contraseña', () async {
        final otra = AutenticacionLocal(base: base);
        addTearDown(otra.dispose);
        await otra.iniciarSesion(correo, clave);
        final repo = RepositorioSqlite.conSesion(
          base: base,
          sesion: otra.sesion!,
        );
        await administracion().restablecerClave(
          await idCuenta(correo),
          'nueva clave segura',
        );
        await expectLater(repo.obtenerTodos(), throwsA(isA<AccesoException>()));
        otra.cerrarSesion();
        await expectLater(
          otra.iniciarSesion(correo, clave),
          accesoCon('incorrectos'),
        );
        await otra.iniciarSesion(correo, 'nueva clave segura');
        expect(otra.sesion!.correo, correo);
      });
    }

    test('agrupa propietarios y trabajadores sin la empresa interna', () async {
      final empresas = await administracion().listarEmpresas();
      expect(empresas.map((e) => e.nombre), ['Otra Tienda', 'Tienda Central']);
      expect(empresas.map((e) => e.cuentas.length), [2, 2]);
      expect(empresas.first.cuentas.map((c) => c.correo), [
        'ana@otra.com',
        'consulta@otra.com',
      ]);
      expect(empresas.last.cuentas.map((c) => c.correo), [
        'dueno@empresa.com',
        'empleado@empresa.com',
      ]);
      for (final empresa in empresas) {
        expect(empresa.cuentas.first.rol, RolCuenta.propietario);
        expect(
          empresa.cuentas.every((c) => c.rol != RolCuenta.administrador),
          isTrue,
        );
      }
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
        (await listarCuentas()).firstWhere((c) => c.id == id).activa,
        isTrue,
      );
      await duenoApp.iniciarSesion(propietario.correo, clave);
      expect(duenoApp.sesion!.esAdministrador, isFalse);
    });

    test('una sesión de administrador cerrada no administra', () async {
      final admin = auth.sesion!;
      auth.cerrarSesion();
      await expectLater(
        AdministracionDispositivo(base: base, sesion: admin).listarEmpresas(),
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
        accesoCon('cuentas de administrador'),
      );
      await expectLater(
        administracion().restablecerClave(id, 'nueva clave segura'),
        accesoCon('cuentas de administrador'),
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

  test(
    'sin propietarios activos no ofrece crear administrador ni modifica datos',
    () async {
      await usar(Plantilla.unPropietario);
      final db = await base.abrir;
      await db.update('cuentas', {'activa': 0}, where: "rol = 'propietario'");
      final antes = [
        await db.query('cuentas'),
        await db.query('usuarios'),
        await db.query('empresas'),
      ];
      expect(await auth.puedeCrearAdministrador(), isFalse);
      await expectLater(
        crearAdministrador(),
        accesoCon('propietario incorrectos'),
      );
      expect([
        await db.query('cuentas'),
        await db.query('usuarios'),
        await db.query('empresas'),
      ], antes);
    },
  );

  test('un empleado activo no puede autorizar el alta', () async {
    await usar(Plantilla.unPropietario);
    await expectLater(
      auth.crearAdministrador(
        administrador,
        correoPropietario: 'empleado@empresa.com',
        clavePropietario: clave,
      ),
      accesoCon('propietario incorrectos'),
    );
    expect(await (await base.abrir).query('cuentas'), hasLength(2));
  });

  test(
    'migra v6 a v7 conservando cuentas y guías; admite un solo administrador',
    () async {
      await usar(Plantilla.unPropietario);
      final db = await base.abrir;
      final cuentas = await db.query('cuentas', orderBy: 'id');
      await db.transaction((tx) async {
        // Reconstruye el CHECK exacto de v6, no solo el número de versión.
        final esquema =
            (await tx.rawQuery(
                  "SELECT sql FROM sqlite_master WHERE name = 'cuentas' AND type = 'table'",
                )).single['sql']
                as String;
        await tx.execute(
          esquema
              .replaceFirst('"cuentas"', 'cuentas_v6')
              .replaceFirst(
                'CREATE TABLE cuentas (',
                'CREATE TABLE cuentas_v6 (',
              )
              .replaceFirst(", 'administrador'", ''),
        );
        await tx.execute('INSERT INTO cuentas_v6 SELECT * FROM cuentas');
        await tx.execute('DROP TABLE cuentas');
        await tx.execute('ALTER TABLE cuentas_v6 RENAME TO cuentas');
        await tx.execute(
          "CREATE UNIQUE INDEX un_propietario_por_empresa ON cuentas(empresa) WHERE rol = 'propietario'",
        );
        for (final cuenta in cuentas) {
          await tx.insert('guias_vistas', {
            'cuenta': cuenta['id'],
            'modulo': 'inventario',
          });
        }
        await tx.execute('PRAGMA user_version = 6');
      });
      final guias = await db.query('guias_vistas', orderBy: 'cuenta');
      await base.cerrar();
      final migrada = await base.abrir;
      expect(await migrada.getVersion(), BaseDatosLocal.version);
      expect(await migrada.query('cuentas', orderBy: 'id'), cuentas);
      expect(await migrada.query('guias_vistas', orderBy: 'cuenta'), guias);
      expect(await migrada.rawQuery('PRAGMA foreign_key_check'), isEmpty);
      await crearAdministrador();
      final admin = (await migrada.query(
        'cuentas',
        where: "rol = 'administrador'",
      )).single;
      await expectLater(
        migrada.insert(
          'cuentas',
          Map<String, Object?>.from(admin)
            ..addAll({'id': 'otro-admin', 'correo': 'otro-admin@empresa.com'}),
        ),
        throwsA(isA<DatabaseException>()),
      );
      // Repetir la migración sobre el esquema ya actualizado es idempotente.
      await migrada.execute('PRAGMA user_version = 6');
      await base.cerrar();
      expect(await (await base.abrir).query('cuentas'), hasLength(3));
      expect(
        await (await base.abrir).query('guias_vistas', orderBy: 'cuenta'),
        guias,
      );
      expect(
        await (await base.abrir).rawQuery('PRAGMA foreign_key_check'),
        isEmpty,
      );
    },
  );
}
