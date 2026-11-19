import 'dart:async';

import 'package:finanzasist/data/administracion_dispositivo.dart';
import 'package:finanzasist/data/autenticacion_local.dart';
import 'package:finanzasist/data/base_datos_local.dart';
import 'package:finanzasist/screens/acceso_screen.dart';
import 'package:finanzasist/screens/administracion_screen.dart';
import 'package:finanzasist/screens/crear_administrador_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class GestionFalsa implements GestionDispositivo {
  GestionFalsa({this.fallarCarga = false, this.errorAccion});
  bool fallarCarga;
  AccesoException? errorAccion;
  final claves = <String, String>{};
  List<CuentaResumen> cuentas = [
    const CuentaResumen(
      id: 'admin',
      empresa: 'Administración',
      propietario: 'Laura Gómez',
      correo: 'admin@finanzasist.com',
      rol: RolCuenta.administrador,
      activa: true,
    ),
    const CuentaResumen(
      id: 'dueno',
      empresa: 'Tienda Central',
      propietario: 'Jose Torres',
      correo: 'dueno@empresa.com',
      rol: RolCuenta.propietario,
      activa: true,
    ),
  ];

  @override
  Future<List<EmpresaDispositivo>> listarEmpresas() async {
    if (fallarCarga) throw const AccesoException('Tu sesión no es válida.');
    final nombres = cuentas
        .where((c) => c.rol != RolCuenta.administrador)
        .map((c) => c.empresa)
        .toSet();
    return [
      for (final nombre in nombres)
        EmpresaDispositivo(
          id: nombre,
          nombre: nombre,
          cuentas: List.unmodifiable(cuentas.where((c) => c.empresa == nombre)),
        ),
    ];
  }

  @override
  Future<void> cambiarEstado(String cuentaId, {required bool activa}) async {
    if (errorAccion case final error?) throw error;
    cuentas = [
      for (final c in cuentas)
        c.id == cuentaId
            ? CuentaResumen(
                id: c.id,
                empresa: c.empresa,
                propietario: c.propietario,
                correo: c.correo,
                rol: c.rol,
                activa: activa,
              )
            : c,
    ];
  }

  @override
  Future<void> restablecerClave(String cuentaId, String nuevaClave) async {
    if (errorAccion case final error?) throw error;
    claves[cuentaId] = nuevaClave;
  }
}

class AutenticacionFalsa extends AutenticacionLocal {
  AutenticacionFalsa({this.permiteAdministrador = true, this.error})
    : super(base: BaseDatosLocal(factory: databaseFactoryFfi));
  final bool permiteAdministrador;
  final AccesoException? error;
  final llamadas = <(DatosAdministrador, String, String)>[];

  @override
  Future<bool> puedeCrearAdministrador() async => permiteAdministrador;

  @override
  Future<void> crearAdministrador(
    DatosAdministrador datos, {
    required String correoPropietario,
    required String clavePropietario,
  }) async {
    llamadas.add((datos, correoPropietario, clavePropietario));
    if (error case final error?) throw error;
  }
}

class GestionPendiente extends GestionFalsa {
  final respuesta = Completer<List<EmpresaDispositivo>>();
  @override
  Future<List<EmpresaDispositivo>> listarEmpresas() => respuesta.future;
}

void main() {
  void pantallaMovil(WidgetTester tester) {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  group('Panel de administración', () {
    Future<void> abrir(
      WidgetTester tester,
      GestionFalsa gestion, {
      VoidCallback? cerrarSesion,
    }) async {
      pantallaMovil(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: AdministracionScreen(
            administracion: gestion,
            administrador: gestion.cuentas.first,
            cerrarSesion: cerrarSesion ?? () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> tocar(WidgetTester tester, Finder boton) async {
      await tester.ensureVisible(boton);
      await tester.pumpAndSettle();
      await tester.tap(boton);
      await tester.pumpAndSettle();
    }

    final estadoDueno = find.byKey(const ValueKey('estado-dueno@empresa.com'));
    final claveDueno = find.byKey(const ValueKey('clave-dueno@empresa.com'));

    testWidgets('lista los usuarios; el administrador no tiene acciones', (
      tester,
    ) async {
      await abrir(tester, GestionFalsa());

      expect(find.text('Administrador (tú)'), findsOneWidget);
      expect(find.text('Tienda Central'), findsOneWidget);
      expect(find.text('dueno@empresa.com'), findsOneWidget);
      expect(find.text('Activa'), findsNWidgets(2));
      expect(
        find.byKey(const ValueKey('estado-admin@finanzasist.com')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('clave-admin@finanzasist.com')),
        findsNothing,
      );
      expect(estadoDueno, findsOneWidget);
      expect(claveDueno, findsOneWidget);
    });

    testWidgets('muestra carga mientras espera la consulta', (tester) async {
      final gestion = GestionPendiente();
      pantallaMovil(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: AdministracionScreen(
            administracion: gestion,
            administrador: gestion.cuentas.first,
            cerrarSesion: () {},
          ),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      gestion.respuesta.complete(const []);
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Administrador (tú)'), findsOneWidget);
    });

    testWidgets('desactivar pide confirmación y actualiza el estado', (
      tester,
    ) async {
      final gestion = GestionFalsa();
      await abrir(tester, gestion);

      await tocar(tester, estadoDueno);
      expect(find.text('¿Desactivar la cuenta?'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('confirmar-desactivar')));
      await tester.pumpAndSettle();

      expect(gestion.cuentas[1].activa, isFalse);
      expect(find.text('Desactivada'), findsOneWidget);
      expect(
        find.text('Cuenta de Tienda Central desactivada.'),
        findsOneWidget,
      );

      // Activar no necesita confirmación.
      await tocar(tester, estadoDueno);
      expect(gestion.cuentas[1].activa, isTrue);
    });

    testWidgets(
      'agrupa trabajadores con su propietario a 360 dp y tolera textos largos',
      (tester) async {
        final gestion = GestionFalsa();
        gestion.cuentas.addAll([
          CuentaResumen(
            id: 'empleado',
            empresa: 'Tienda Central',
            propietario: 'Nombre de trabajador muy largo para comprobar el ancho de pantalla',
            correo: 'trabajador.con.correo.muy.largo@empresa.com',
            rol: RolCuenta.encargado,
            activa: true,
          ),
          CuentaResumen(
            id: 'otra',
            empresa: 'Otra empresa',
            propietario: 'Otra propietaria',
            correo: 'otra@empresa.com',
            rol: RolCuenta.propietario,
            activa: false,
          ),
        ]);
        await abrir(tester, gestion);
        expect(find.text('Tienda Central'), findsOneWidget);
        await tester.scrollUntilVisible(
          find.byKey(
            const ValueKey(
              'estado-trabajador.con.correo.muy.largo@empresa.com',
            ),
          ),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text(RolCuenta.encargado.etiqueta), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tocar(
          tester,
          find.byKey(
            const ValueKey(
              'estado-trabajador.con.correo.muy.largo@empresa.com',
            ),
          ),
        );
        await tester.tap(find.byKey(const ValueKey('confirmar-desactivar')));
        await tester.pumpAndSettle();
        expect(
          gestion.cuentas.firstWhere((c) => c.id == 'empleado').activa,
          isFalse,
        );
        await tester.scrollUntilVisible(
          find.text('Otra empresa'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text('Otra empresa'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('cancelar la desactivación no cambia la cuenta', (
      tester,
    ) async {
      final gestion = GestionFalsa();
      await abrir(tester, gestion);

      await tocar(tester, estadoDueno);
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(gestion.cuentas[1].activa, isTrue);
    });

    testWidgets('restablecer valida y guarda la nueva contraseña', (
      tester,
    ) async {
      final gestion = GestionFalsa();
      await abrir(tester, gestion);
      final guardar = find.byKey(const ValueKey('guardar-nueva-clave'));

      await tocar(tester, claveDueno);
      await tester.enterText(
        find.byKey(const ValueKey('nueva-clave')),
        'corta',
      );
      await tester.tap(guardar);
      await tester.pumpAndSettle();
      expect(find.text('Usa entre 8 y 128 caracteres.'), findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey('nueva-clave')),
        'clave restablecida 1',
      );
      await tester.enterText(
        find.byKey(const ValueKey('confirmar-nueva-clave')),
        'otra distinta 123',
      );
      await tester.tap(guardar);
      await tester.pumpAndSettle();
      expect(find.text('Las contraseñas deben coincidir.'), findsOneWidget);
      expect(gestion.claves, isEmpty);

      await tester.enterText(
        find.byKey(const ValueKey('confirmar-nueva-clave')),
        'clave restablecida 1',
      );
      await tester.tap(guardar);
      await tester.pumpAndSettle();

      expect(gestion.claves, {'dueno': 'clave restablecida 1'});
      expect(find.textContaining('Contraseña restablecida'), findsOneWidget);
    });

    testWidgets('muestra el error de una acción rechazada', (tester) async {
      final gestion = GestionFalsa(
        errorAccion: const AccesoException('La cuenta no existe.'),
      );
      await abrir(tester, gestion);

      await tocar(tester, estadoDueno);
      await tester.tap(find.byKey(const ValueKey('confirmar-desactivar')));
      await tester.pumpAndSettle();

      expect(find.text('La cuenta no existe.'), findsOneWidget);
      expect(gestion.cuentas[1].activa, isTrue);
    });

    testWidgets('error al cargar ofrece reintentar', (tester) async {
      final gestion = GestionFalsa(fallarCarga: true);
      await abrir(tester, gestion);
      expect(find.text('Tu sesión no es válida.'), findsOneWidget);

      gestion.fallarCarga = false;
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();

      expect(find.text('Tienda Central'), findsOneWidget);
    });

    testWidgets('cerrar sesión llama a la autenticación', (tester) async {
      var cerrada = false;
      await abrir(tester, GestionFalsa(), cerrarSesion: () => cerrada = true);

      await tester.tap(find.byKey(const ValueKey('cerrar-sesion-admin')));

      expect(cerrada, isTrue);
    });
  });

  group('Crear administrador', () {
    Future<void> abrir(WidgetTester tester, AutenticacionFalsa auth) async {
      pantallaMovil(tester);
      addTearDown(auth.dispose);
      await tester.pumpWidget(
        MaterialApp(home: AccesoScreen(autenticacion: auth)),
      );
      await tester.pumpAndSettle();
    }

    final enlace = find.byKey(const ValueKey('crear-administrador-acceso'));

    Future<void> abrirFormulario(WidgetTester tester) async {
      await tester.ensureVisible(enlace);
      await tester.pumpAndSettle();
      await tester.tap(enlace);
      await tester.pumpAndSettle();
    }

    Future<void> llenar(WidgetTester tester) async {
      for (final (clave, valor) in [
        ('correo-propietario', 'dueno@empresa.com'),
        ('clave-propietario', 'mi frase de acceso 2026'),
        ('nombre-admin', 'Laura Gómez'),
        ('correo-admin', 'admin@finanzasist.com'),
        ('clave-admin', 'clave del administrador'),
        ('confirmar-clave-admin', 'clave del administrador'),
      ]) {
        await tester.enterText(find.byKey(ValueKey(clave)), valor);
      }
    }

    Future<void> enviar(WidgetTester tester) async {
      final boton = find.byKey(const ValueKey('crear-admin'));
      await tester.ensureVisible(boton);
      await tester.pumpAndSettle();
      await tester.tap(boton);
      await tester.pumpAndSettle();
    }

    testWidgets('el acceso no lo ofrece si no está permitido', (tester) async {
      await abrir(tester, AutenticacionFalsa(permiteAdministrador: false));
      expect(enlace, findsNothing);
    });

    testWidgets('valida los campos antes de enviar', (tester) async {
      final auth = AutenticacionFalsa();
      await abrir(tester, auth);
      await abrirFormulario(tester);

      await enviar(tester);

      expect(auth.llamadas, isEmpty);
      expect(
        find.text('Escribe la contraseña del propietario.'),
        findsOneWidget,
      );
    });

    testWidgets('muestra el rechazo y conserva el formulario', (tester) async {
      final auth = AutenticacionFalsa(
        error: const AccesoException(
          'Correo o contraseña del propietario incorrectos.',
        ),
      );
      await abrir(tester, auth);
      await abrirFormulario(tester);
      await llenar(tester);

      await enviar(tester);

      expect(
        find.text('Correo o contraseña del propietario incorrectos.'),
        findsOneWidget,
      );
      expect(find.byType(CrearAdministradorScreen), findsOneWidget);
    });

    testWidgets('envía los datos y vuelve al terminar', (tester) async {
      final auth = AutenticacionFalsa();
      await abrir(tester, auth);
      await abrirFormulario(tester);
      await llenar(tester);

      await enviar(tester);

      final (datos, correo, clave) = auth.llamadas.single;
      expect(datos.nombre, 'Laura Gómez');
      expect(datos.correo, 'admin@finanzasist.com');
      expect(datos.clave, 'clave del administrador');
      expect(correo, 'dueno@empresa.com');
      expect(clave, 'mi frase de acceso 2026');
      expect(find.byType(CrearAdministradorScreen), findsNothing);
    });
  });
}
