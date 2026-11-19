import 'fecha_negocio.dart';
import 'operacion.dart';
import 'reglas_inventario.dart';
import '../utils/entrada_importe.dart';

class SolicitudGasto {
  const SolicitudGasto({
    required this.id,
    required this.fecha,
    required this.concepto,
    required this.categoria,
    required this.valor,
  });
  final String id;
  final DateTime? fecha;
  final String concepto;
  final String categoria;
  final double valor;

  Gasto confirmar({
    required String empresaId,
    required String usuarioId,
    required DateTime registradoEn,
  }) {
    final error =
        ValidacionGasto.fecha(fecha) ??
        ValidacionGasto.concepto(concepto) ??
        ValidacionGasto.categoria(categoria) ??
        ValidacionGasto.valor(valor.toString());
    if (error != null) throw ReglaNegocioException(error);
    if (id.trim().isEmpty ||
        empresaId.trim().isEmpty ||
        usuarioId.trim().isEmpty) {
      throw const ReglaNegocioException(
        'Falta la identificación del gasto o de la sesión',
      );
    }
    return Gasto(
      id: id,
      empresaId: empresaId,
      usuarioId: usuarioId,
      fecha: FechaNegocio.dia(fecha!),
      concepto: concepto.trim(),
      categoria: categoria.trim(),
      valorCentavos: centavos(valor),
      registradoEn: registradoEn.toUtc(),
    );
  }
}

class Gasto {
  const Gasto({
    required this.id,
    required this.empresaId,
    required this.usuarioId,
    required this.fecha,
    required this.concepto,
    required this.categoria,
    required this.valorCentavos,
    required this.registradoEn,
  });
  final String id;
  final String empresaId;
  final String usuarioId;
  final DateTime fecha;
  final String concepto;
  final String categoria;
  final int valorCentavos;
  final DateTime registradoEn;

  bool mismosDatos(Gasto otro) =>
      empresaId == otro.empresaId &&
      FechaNegocio.clave(fecha) == FechaNegocio.clave(otro.fecha) &&
      concepto == otro.concepto &&
      categoria == otro.categoria &&
      valorCentavos == otro.valorCentavos;
}

class ValidacionGasto {
  static String? fecha(DateTime? valor) =>
      FechaNegocio.valida(valor) ? null : 'Selecciona una fecha válida';
  static String? concepto(String? valor) =>
      valor == null || valor.trim().isEmpty
      ? 'Escribe el concepto del gasto'
      : null;
  static String? categoria(String? valor) =>
      valor == null || valor.trim().isEmpty ? 'Selecciona una categoría' : null;
  static String? valor(String? texto) {
    final numero = EntradaImporte.leer(texto);
    if (numero != null && numero.isFinite && numero <= 0) {
      return 'El valor debe ser mayor que cero';
    }
    final error = ReglasInventario.importe(texto);
    if (error != null) return error;
    return centavos(numero!) <= 0 ? 'El valor debe ser mayor que cero' : null;
  }
}
