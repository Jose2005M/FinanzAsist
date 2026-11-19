import 'package:flutter/material.dart';

import '../models/reglas_inventario.dart';
import '../utils/entrada_importe.dart';
import '../utils/formato_moneda.dart';

class VistaPreviaImporte extends StatelessWidget {
  const VistaPreviaImporte({super.key, required this.texto});
  final String texto;

  @override
  Widget build(BuildContext context) {
    final valor = EntradaImporte.leer(texto);
    if (valor == null || ReglasInventario.importe(texto) != null) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        'Se registrará: ${formatearPesos(valor)}',
        style: Theme.of(context).textTheme.bodySmall
            ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    );
  }
}
