import 'dart:async';

import 'package:finanzasist/data/autenticacion_local.dart';
import 'package:finanzasist/data/base_datos_local.dart';
import 'package:finanzasist/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class AccesoFallido extends AutenticacionLocal {
  AccesoFallido() : super(base: BaseDatosLocal(factory: databaseFactoryFfi));
  @override
  Future<bool> puedeCrearAdministrador() async => false;
  int llamadas = 0;
  @override
  Future<void> iniciarSesion(String correo, String clave) async {
    llamadas++;
    throw const AccesoException('Correo o contraseña incorrectos.');
  }

  @override
  Future<void> registrar(DatosRegistro datos) async {
    llamadas++;
    throw const AccesoException(
      'Este correo ya tiene una cuenta. Inicia sesión.',
    );
  }
}

class AccesoLento extends AutenticacionLocal {
  AccesoLento() : super(base: BaseDatosLocal(factory: databaseFactoryFfi));
  @override
  Future<bool> puedeCrearAdministrador() async => false;
  final respuesta = Completer<void>();
  int llamadas = 0;
  @override
  Future<void> iniciarSesion(String correo, String clave) {
    llamadas++;
    return respuesta.future;
  }
}

void main() {
  late AccesoFallido auth;
  setUp(() => auth = AccesoFallido());
  tearDown(() => auth.dispose());

  Future<void> abrir(
    WidgetTester tester, {
    bool registro = false,
    bool grande = false,
    Size tamano = const Size(360, 800),
  }) async {
    tester.view.physicalSize = tamano;
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(FinanzAsistApp(autenticacion: auth));
    await tester.pumpAndSettle();
    if (grande) {
      final context = tester.element(find.byType(Scaffold));
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(1.6)),
          child: FinanzAsistApp(autenticacion: auth),
        ),
      );
    }
    if (registro) {
      await tester.ensureVisible(find.byKey(const ValueKey('cambiar-acceso')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('cambiar-acceso')));
      await tester.pumpAndSettle();
    }
  }

  Future<void> enviar(WidgetTester tester) async {
    final boton = find.byKey(const ValueKey('enviar-acceso'));
    await tester.ensureVisible(boton);
    await tester.pumpAndSettle();
    await tester.tap(boton);
    await tester.pumpAndSettle();
  }

  testWidgets('HU01 CA02 campos obligatorios conservan el nombre ingresado', (
    tester,
  ) async {
    await abrir(tester, registro: true);
    await tester.enterText(
      find.byKey(const ValueKey('empresa-registro')),
      'Mi tienda',
    );
    await enviar(tester);
    expect(find.text('Escribe tu nombre.'), findsOneWidget);
    expect(find.text('Escribe tu correo electrónico.'), findsOneWidget);
    expect(find.text('Mi tienda'), findsOneWidget);
    expect(auth.llamadas, 0);
    expect(
      tester
          .widget<TextField>(
            find.descendant(
              of: find.byKey(const ValueKey('propietario-registro')),
              matching: find.byType(TextField),
            ),
          )
          .focusNode!
          .hasFocus,
      isTrue,
    );
    expect(find.byType(NavigationBar), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Registro comprueba confirmación, permite mostrar la clave y soporta teclado',
    (tester) async {
      await abrir(tester, registro: true);
      for (final campo in <String, String>{
        'empresa-registro': 'Mi tienda',
        'propietario-registro': 'Jose Torres',
        'correo-acceso': 'dueno@tienda.com',
        'clave-acceso': 'mi frase de acceso 2026',
        'confirmacion-registro': 'una clave diferente',
      }.entries) {
        await tester.ensureVisible(find.byKey(ValueKey(campo.key)));
        await tester.enterText(find.byKey(ValueKey(campo.key)), campo.value);
      }
      await enviar(tester);
      expect(find.text('Las contraseñas deben coincidir.'), findsOneWidget);
      expect(auth.llamadas, 0);
      final clave = find.byKey(const ValueKey('clave-acceso'));
      await tester.ensureVisible(clave);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Mostrar contraseña'));
      await tester.pump();
      expect(
        tester
            .widget<TextField>(
              find.descendant(of: clave, matching: find.byType(TextField)),
            )
            .obscureText,
        isFalse,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Registro exige 8 caracteres y permite enviar el mínimo', (
    tester,
  ) async {
    await abrir(tester, registro: true);
    expect(
      find.text('De 8 a 128 caracteres. Puedes usar una frase.'),
      findsOneWidget,
    );
    for (final campo in <String, String>{
      'empresa-registro': 'Mi tienda',
      'propietario-registro': 'Jose Torres',
      'correo-acceso': 'dueno@tienda.com',
      'clave-acceso': 'Acceso2',
      'confirmacion-registro': 'Acceso2',
    }.entries) {
      await tester.ensureVisible(find.byKey(ValueKey(campo.key)));
      await tester.enterText(find.byKey(ValueKey(campo.key)), campo.value);
    }
    await enviar(tester);
    expect(find.text('Usa entre 8 y 128 caracteres.'), findsOneWidget);
    expect(auth.llamadas, 0);

    for (final campo in ['clave-acceso', 'confirmacion-registro']) {
      final finder = find.byKey(ValueKey(campo));
      await tester.ensureVisible(finder);
      await tester.enterText(finder, 'Acceso26');
    }
    await enviar(tester);
    expect(find.text('Usa entre 8 y 128 caracteres.'), findsNothing);
    expect(auth.llamadas, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'HU02 CA02 error visible y datos protegidos ausentes; texto grande sin desbordes',
    (tester) async {
      await abrir(tester, grande: true);
      await tester.enterText(
        find.byKey(const ValueKey('correo-acceso')),
        'dueno@tienda.com',
      );
      await tester.enterText(
        find.byKey(const ValueKey('clave-acceso')),
        'clave incorrecta',
      );
      await enviar(tester);
      expect(find.text('Correo o contraseña incorrectos.'), findsOneWidget);
      expect(find.text('dueno@tienda.com'), findsOneWidget);
      expect(auth.llamadas, 1);
      expect(find.byType(NavigationBar), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'HU01 CA03 duplicado permite volver al acceso sin perder el correo',
    (tester) async {
      await abrir(tester, registro: true);
      for (final campo in <String, String>{
        'empresa-registro': 'Mi tienda',
        'propietario-registro': 'Jose Torres',
        'correo-acceso': 'dueno@tienda.com',
        'clave-acceso': 'mi frase de acceso 2026',
        'confirmacion-registro': 'mi frase de acceso 2026',
      }.entries) {
        await tester.ensureVisible(find.byKey(ValueKey(campo.key)));
        await tester.enterText(find.byKey(ValueKey(campo.key)), campo.value);
      }
      await enviar(tester);
      expect(
        find.text('Este correo ya tiene una cuenta. Inicia sesión.'),
        findsOneWidget,
      );
      await tester.ensureVisible(find.byKey(const ValueKey('cambiar-acceso')));
      await tester.tap(find.byKey(const ValueKey('cambiar-acceso')));
      await tester.pumpAndSettle();
      expect(find.text('Inicia sesión'), findsOneWidget);
      expect(find.text('dueno@tienda.com'), findsOneWidget);
      expect(
        tester
            .widget<TextFormField>(find.byKey(const ValueKey('clave-acceso')))
            .controller!
            .text,
        isEmpty,
      );
      expect(tester.takeException(), isNull);
    },
  );

  for (final tamano in [
    const Size(320, 640),
    const Size(390, 844),
    const Size(768, 1024),
  ]) {
    testWidgets('Acceso legible y controles alcanzables en $tamano', (
      tester,
    ) async {
      await abrir(tester, tamano: tamano);
      expect(find.text('FinanzAsist'), findsOneWidget);
      expect(find.text('Inicia sesión'), findsOneWidget);
      await tester.ensureVisible(find.byKey(const ValueKey('enviar-acceso')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('enviar-acceso')).hitTestable(),
        findsOneWidget,
      );
      expect(
        tester.getSize(find.byKey(const ValueKey('enviar-acceso'))).height,
        greaterThanOrEqualTo(48),
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Teclado y texto al doble conservan acceso al envío y al error', (
    tester,
  ) async {
    await abrir(tester, tamano: const Size(320, 640));
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    tester.view.viewInsets = const FakeViewPadding(bottom: 280);
    addTearDown(() {
      tester.platformDispatcher.clearTextScaleFactorTestValue();
      tester.view.resetViewInsets();
    });
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('correo-acceso')),
      'dueno@tienda.com',
    );
    await tester.enterText(
      find.byKey(const ValueKey('clave-acceso')),
      'clave incorrecta',
    );
    await enviar(tester);
    expect(find.text('Correo o contraseña incorrectos.'), findsOneWidget);
    await tester.ensureVisible(find.text('Correo o contraseña incorrectos.'));
    await tester.pumpAndSettle();
    expect(
      find.text('Correo o contraseña incorrectos.').hitTestable(),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Semántica, contraste y controles accesibles del acceso', (
    tester,
  ) async {
    await abrir(tester);
    final semantica = tester.ensureSemantics();
    try {
      expect(find.bySemanticsLabel(RegExp('Correo electrónico')), findsWidgets);
      expect(find.bySemanticsLabel(RegExp('Contraseña')), findsWidgets);
      expect(find.byTooltip('Mostrar contraseña'), findsOneWidget);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
    } finally {
      semantica.dispose();
    }
  });

  testWidgets('Durante el acceso se informa la espera y no hay doble envío', (
    tester,
  ) async {
    final lenta = AccesoLento();
    addTearDown(lenta.dispose);
    await abrir(tester);
    await tester.pumpWidget(
      FinanzAsistApp(key: const ValueKey('acceso-lento'), autenticacion: lenta),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('correo-acceso')),
      'dueno@tienda.com',
    );
    await tester.enterText(
      find.byKey(const ValueKey('clave-acceso')),
      'mi frase de acceso 2026',
    );
    final boton = find.byKey(const ValueKey('enviar-acceso'));
    await tester.ensureVisible(boton);
    await tester.pumpAndSettle();
    await tester.tap(boton);
    await tester.pump();
    expect(find.text('Verificando…'), findsOneWidget);
    expect(tester.widget<FilledButton>(boton).onPressed, isNull);
    expect(
      tester
          .widget<TextButton>(find.byKey(const ValueKey('cambiar-acceso')))
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<TextFormField>(find.byKey(const ValueKey('correo-acceso')))
          .enabled,
      isFalse,
    );
    expect(lenta.llamadas, 1);
    lenta.respuesta.completeError(
      const AccesoException('Correo o contraseña incorrectos.'),
    );
    await tester.pumpAndSettle();
    expect(find.text('Correo o contraseña incorrectos.'), findsOneWidget);
    expect(tester.widget<FilledButton>(boton).onPressed, isNotNull);
    expect(tester.takeException(), isNull);
  });
}
