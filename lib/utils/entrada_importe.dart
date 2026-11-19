/// Entrada de dinero sin agrupación de miles; punto o coma solo para decimales.
abstract final class EntradaImporte {
  static final _formato = RegExp(r'^[+-]?\d+(?:[.,]\d{1,2})?$');
  static final _separadores = RegExp(r'[.,\s]');

  static double? leer(String? texto) {
    final limpio = (texto ?? '').trim();
    if (!_formato.hasMatch(limpio)) return null;
    final valor = double.tryParse(limpio.replaceAll(',', '.'));
    return valor != null && valor.isFinite ? valor : null;
  }

  static String error(
    String? texto, {
    String invalido = 'Escribe un importe válido',
  }) {
    final limpio = (texto ?? '').trim();
    if (RegExp(r'^[-+\d.,\s]+$').hasMatch(limpio) &&
        _separadores.hasMatch(limpio)) {
      return 'Sin miles y máximo 2 decimales. Ej.: 6000,50';
    }
    return invalido;
  }

  static String paraFormulario(double valor) =>
      valor.toString().replaceFirst(RegExp(r'\.0$'), '').replaceAll('.', ',');
}
