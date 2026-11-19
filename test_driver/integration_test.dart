import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  await integrationDriver(
    onScreenshot: (nombre, bytes, [argumentos]) async {
      final directorio = Directory('build/qa');
      await directorio.create(recursive: true);
      final seguro = nombre.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      await File('${directorio.path}/$seguro.png').writeAsBytes(bytes);
      return true;
    },
  );
}
