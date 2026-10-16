String formatearPesos(double valor) {
  final partes = valor.toStringAsFixed(2).split('.');
  final entero = partes[0].replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => '.',
  );
  final decimales = partes[1] == '00' ? '' : ',${partes[1]}';
  return '\$ $entero$decimales COP';
}
