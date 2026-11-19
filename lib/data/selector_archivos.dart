import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import 'respaldo_local.dart';

/// Diálogos del sistema para guardar y elegir archivos de respaldo.
abstract interface class SelectorArchivos {
  /// Devuelve `false` si la persona cancela el diálogo.
  Future<bool> guardar({required String nombre, required Uint8List bytes});

  /// Devuelve `null` si la persona cancela el diálogo.
  Future<Uint8List?> elegir({required int tamanoMaximo});
}

class SelectorArchivosSistema implements SelectorArchivos {
  const SelectorArchivosSistema();

  @override
  Future<bool> guardar({
    required String nombre,
    required Uint8List bytes,
  }) async =>
      await FilePicker.saveFile(
        fileName: nombre,
        bytes: bytes,
        dialogTitle: 'Guardar respaldo de FinanzAsist',
      ) !=
      null;

  @override
  Future<Uint8List?> elegir({required int tamanoMaximo}) async {
    final archivos = await FilePicker.pickFiles(
      dialogTitle: 'Elegir respaldo de FinanzAsist',
    );
    if (archivos.isEmpty) return null;
    final archivo = archivos.first;
    // Comprueba el tamaño antes de cargar el archivo en memoria.
    final tamano = archivo.lengthSync() ?? await archivo.length();
    if (tamano != null && tamano > tamanoMaximo) {
      throw const RespaldoException(
        'El archivo es demasiado grande para ser un respaldo de FinanzAsist.',
      );
    }
    return archivo.readAsBytes();
  }
}
