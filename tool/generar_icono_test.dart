// Genera las imágenes base del ícono a partir del símbolo de la marca.
// Ejecutar desde la raíz del proyecto:
//   flutter test tool/generar_icono_test.dart
//   dart run flutter_launcher_icons
// Las imágenes se escriben en assets/icono/ y la configuración del ícono está
// en pubspec.yaml (sección flutter_launcher_icons).
import 'dart:io';
import 'dart:ui' as ui;

import 'package:finanzasist/theme/tema_finanzasist.dart';
import 'package:finanzasist/widgets/marca_finanzasist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _lado = 1024.0;

/// Proporción del lienzo del símbolo (ver SimboloFinanzAsist).
const _altoPorAncho = 90 / 120;

/// Ícono clásico: símbolo grande sobre el fondo crema de la app.
const _escalaIcono = 0.72;

/// Capa frontal del ícono adaptable: Android recorta la imagen en círculos o
/// formas redondeadas y solo garantiza visible el 61 % central.
const _escalaAdaptable = 0.54;

Future<void> _guardar(
  String ruta, {
  required double escala,
  Color? fondo,
}) async {
  final grabadora = ui.PictureRecorder();
  final lienzo = Canvas(grabadora);
  if (fondo != null) {
    lienzo.drawRect(
      Offset.zero & const Size(_lado, _lado),
      Paint()..color = fondo,
    );
  }
  final ancho = _lado * escala;
  final alto = ancho * _altoPorAncho;
  lienzo.translate((_lado - ancho) / 2, (_lado - alto) / 2);
  const SimboloFinanzAsist().paint(lienzo, Size(ancho, alto));
  final imagen = await grabadora.endRecording().toImage(
    _lado.toInt(),
    _lado.toInt(),
  );
  final png = await imagen.toByteData(format: ui.ImageByteFormat.png);
  imagen.dispose();
  final archivo = File(ruta);
  await archivo.parent.create(recursive: true);
  await archivo.writeAsBytes(png!.buffer.asUint8List());
}

void main() {
  testWidgets('genera las imágenes base del ícono', (tester) async {
    await tester.runAsync(() async {
      await _guardar(
        'assets/icono/icono.png',
        escala: _escalaIcono,
        fondo: ColoresFinanzAsist.fondo,
      );
      await _guardar(
        'assets/icono/icono_adaptable.png',
        escala: _escalaAdaptable,
      );
    });
    expect(File('assets/icono/icono.png').existsSync(), isTrue);
    expect(File('assets/icono/icono_adaptable.png').existsSync(), isTrue);
  });
}
