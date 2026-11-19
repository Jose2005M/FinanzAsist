@Timeout.factor(4)
library;

import 'dart:io';

import 'package:finanzasist/data/autenticacion_local.dart';
import 'package:finanzasist/data/base_datos_local.dart';
import 'package:finanzasist/data/repositorio_sqlite.dart';
import 'package:finanzasist/data/usuarios_empresa.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const clave = 'clave segura para pruebas';
const empleado = DatosUsuario(
  nombre: 'Luisa Torres',
  correo: 'luisa@empresa.com',
  clave: clave,
  rol: RolCuenta.vendedor,
);

void main() {
  sqfliteFfiInit();
  late Directory plantillas;
  late Directory dir;
  late BaseDatosLocal base;
  late AutenticacionLocal auth;
  late UsuariosEmpresa servicio;
  late String empleadoId;
  late String ajenoId;

  setUpAll(() async {
    plantillas = await Directory.systemTemp.createTemp(
      'fa-usuarios-plantilla-',
    );
    final plantilla = BaseDatosLocal(
      factory: databaseFactoryFfi,
      ruta: '${plantillas.path}/plantilla.db',
    );
    final acceso = AutenticacionLocal(base: plantilla);
    await acceso.registrar(
      const DatosRegistro(
        empresa: 'Tienda Uno',
        propietario: 'Ana Pérez',
        correo: 'ana@empresa.com',
        clave: clave,
      ),
    );
    final usuarios = UsuariosEmpresa(base: plantilla, sesion: acceso.sesion!);
    await usuarios.crearUsuario(empleado);
    empleadoId = (await usuarios.listarUsuarios()).last.id;
    acceso.cerrarSesion();
    await acceso.registrar(
      const DatosRegistro(
        empresa: 'Tienda Dos',
        propietario: 'Juan Pérez',
        correo: 'juan@otra.com',
        clave: clave,
      ),
    );
    ajenoId = acceso.sesion!.cuentaId;
    acceso.dispose();
    await plantilla.cerrar();
  });
  tearDownAll(() => plantillas.delete(recursive: true));
  setUp(() async {
    dir = await Directory.systemTemp.createTemp('fa-usuarios-');
    final ruta = '${dir.path}/datos.db';
    await File('${plantillas.path}/plantilla.db').copy(ruta);
    base = BaseDatosLocal(factory: databaseFactoryFfi, ruta: ruta);
    auth = AutenticacionLocal(base: base);
    await auth.iniciarSesion('ana@empresa.com', clave);
    servicio = UsuariosEmpresa(base: base, sesion: auth.sesion!);
  });
  tearDown(() async {
    auth.dispose();
    await base.cerrar();
    await dir.delete(recursive: true);
  });

  test('lista solo su empresa y el propietario primero', () async {
    final usuarios = await servicio.listarUsuarios();
    expect(usuarios.map((u) => u.correo), ['ana@empresa.com', empleado.correo]);
    expect(usuarios.first.rol, RolCuenta.propietario);
    expect(usuarios.last.nombre, empleado.nombre);
    expect(usuarios.last.activa, isTrue);
  });

  test(
    'empleado creado inicia sesión con rol y usuario propios en la empresa',
    () async {
      final propietario = auth.sesion!;
      auth.cerrarSesion();
      await auth.iniciarSesion(empleado.correo, clave);
      expect(auth.sesion!.rol, RolCuenta.vendedor);
      expect(auth.sesion!.empresaId, propietario.empresaId);
      expect(auth.sesion!.usuarioId, isNot(propietario.usuarioId));
      expect(auth.sesion!.puede(Permiso.registrarVentas), isTrue);
      expect(auth.sesion!.puede(Permiso.gestionarUsuarios), isFalse);
    },
  );

  test(
    'rechaza correo duplicado sin distinguir mayúsculas ni empresa',
    () async {
      for (final correo in [' LUISA@empresa.com ', 'JUAN@otra.com']) {
        await expectLater(
          servicio.crearUsuario(
            DatosUsuario(
              nombre: 'Otro empleado',
              correo: correo,
              clave: clave,
              rol: RolCuenta.consulta,
            ),
          ),
          throwsA(isA<AccesoException>()),
        );
      }
      expect((await servicio.listarUsuarios()).length, 2);
    },
  );

  test('rechaza propietario y valida nombre correo y contraseña', () async {
    for (final datos in [
      const DatosUsuario(
        nombre: 'Otro dueño',
        correo: 'otro@empresa.com',
        clave: clave,
        rol: RolCuenta.propietario,
      ),
      const DatosUsuario(
        nombre: '',
        correo: 'otro@empresa.com',
        clave: clave,
        rol: RolCuenta.consulta,
      ),
      const DatosUsuario(
        nombre: 'Otro usuario',
        correo: 'incorrecto',
        clave: clave,
        rol: RolCuenta.consulta,
      ),
      const DatosUsuario(
        nombre: 'Otro usuario',
        correo: 'otro@empresa.com',
        clave: 'corta',
        rol: RolCuenta.consulta,
      ),
      DatosUsuario(
        nombre: 'Otro usuario',
        correo: 'otro@empresa.com',
        clave: 'x' * 129,
        rol: RolCuenta.consulta,
      ),
    ]) {
      await expectLater(
        servicio.crearUsuario(datos),
        throwsA(isA<AccesoException>()),
      );
    }
    expect((await servicio.listarUsuarios()).length, 2);
  });

  test('no modifica al propietario, cuentas ajenas ni inexistentes', () async {
    for (final id in [auth.sesion!.cuentaId, ajenoId, 'inexistente']) {
      await expectLater(
        servicio.cambiarEstado(id, activa: false),
        throwsA(isA<AccesoException>()),
      );
      await expectLater(
        servicio.cambiarRol(id, RolCuenta.consulta),
        throwsA(isA<AccesoException>()),
      );
      await expectLater(
        servicio.restablecerClave(id, 'nueva contraseña'),
        throwsA(isA<AccesoException>()),
      );
    }
    expect((await servicio.listarUsuarios()).every((u) => u.activa), isTrue);
  });

  test('desactivar corta la sesión abierta en su siguiente consulta y permite reactivar', () async {
    final acceso = AutenticacionLocal(base: base);
    addTearDown(acceso.dispose);
    await acceso.iniciarSesion(empleado.correo, clave);
    final repositorio = RepositorioSqlite.conSesion(
      base: base,
      sesion: acceso.sesion!,
    );
    await repositorio.obtenerTodos();
    await servicio.cambiarEstado(empleadoId, activa: false);
    await expectLater(
      repositorio.obtenerTodos(),
      throwsA(isA<AccesoException>()),
    );
    acceso.cerrarSesion();
    await expectLater(
      acceso.iniciarSesion(empleado.correo, clave),
      throwsA(isA<AccesoException>()),
    );
    await servicio.cambiarEstado(empleadoId, activa: true);
    await acceso.iniciarSesion(empleado.correo, clave);
    expect(acceso.sesion!.rol, RolCuenta.vendedor);
  });

  test(
    'cambiar rol invalida sesión antigua y nuevo acceso aplica permisos',
    () async {
      final acceso = AutenticacionLocal(base: base);
      addTearDown(acceso.dispose);
      await acceso.iniciarSesion(empleado.correo, clave);
      final anterior = acceso.sesion!;
      await servicio.cambiarRol(empleadoId, RolCuenta.encargado);
      await expectLater(
        anterior.verificar(await base.abrir),
        throwsA(isA<AccesoException>()),
      );
      await expectLater(
        servicio.cambiarRol(empleadoId, RolCuenta.propietario),
        throwsA(isA<AccesoException>()),
      );
      acceso.cerrarSesion();
      await acceso.iniciarSesion(empleado.correo, clave);
      expect(acceso.sesion!.rol, RolCuenta.encargado);
    },
  );

  test(
    'restablecer contraseña sustituye la anterior y valida longitud',
    () async {
      await expectLater(
        servicio.restablecerClave(empleadoId, 'corta'),
        throwsA(isA<AccesoException>()),
      );
      await servicio.restablecerClave(empleadoId, 'nueva contraseña segura');
      auth.cerrarSesion();
      await expectLater(
        auth.iniciarSesion(empleado.correo, clave),
        throwsA(isA<AccesoException>()),
      );
      await auth.iniciarSesion(empleado.correo, 'nueva contraseña segura');
      expect(auth.sesion!.cuentaId, empleadoId);
    },
  );

  test(
    'empleado no puede gestionar usuarios ni mediante llamadas directas',
    () async {
      auth.cerrarSesion();
      await auth.iniciarSesion(empleado.correo, clave);
      servicio = UsuariosEmpresa(base: base, sesion: auth.sesion!);
      await expectLater(
        servicio.listarUsuarios(),
        throwsA(isA<AccesoException>()),
      );
      await expectLater(
        servicio.crearUsuario(empleado),
        throwsA(isA<AccesoException>()),
      );
      await expectLater(
        servicio.cambiarEstado(empleadoId, activa: false),
        throwsA(isA<AccesoException>()),
      );
      await expectLater(
        servicio.cambiarRol(empleadoId, RolCuenta.consulta),
        throwsA(isA<AccesoException>()),
      );
      await expectLater(
        servicio.restablecerClave(empleadoId, 'nueva contraseña'),
        throwsA(isA<AccesoException>()),
      );
      await expectLater(
        auth.sesion!.verificar(
          await base.abrir,
          permiso: Permiso.gestionarUsuarios,
        ),
        throwsA(
          isA<AccesoException>().having(
            (e) => e.mensaje,
            'mensaje',
            'Tu rol no permite esta acción.',
          ),
        ),
      );
    },
  );
}
