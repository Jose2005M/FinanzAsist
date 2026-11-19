import 'package:flutter/material.dart';

import '../models/fecha_negocio.dart';

class CampoFecha extends StatelessWidget {
  const CampoFecha({
    super.key,
    required this.identificador,
    required this.etiqueta,
    required this.valor,
    required this.onChanged,
    this.validator,
    this.habilitado = true,
  });
  final String identificador;
  final String etiqueta;
  final DateTime? valor;
  final ValueChanged<DateTime> onChanged;
  final FormFieldValidator<DateTime>? validator;
  final bool habilitado;

  @override
  Widget build(BuildContext context) => FormField<DateTime>(
    key: ValueKey(
      '$identificador-${valor == null ? 'sin-fecha' : FechaNegocio.clave(valor!)}',
    ),
    initialValue: valor,
    validator: validator,
    autovalidateMode: AutovalidateMode.onUserInteraction,
    builder: (campo) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          key: ValueKey(identificador),
          onPressed: !habilitado
              ? null
              : () async {
                  FocusScope.of(context).unfocus();
                  final inicial = valor ?? FechaNegocio.hoy();
                  final seleccionada = await showDatePicker(
                    context: context,
                    initialDate: DateTime(
                      inicial.year,
                      inicial.month,
                      inicial.day,
                    ),
                    firstDate: DateTime(1),
                    lastDate: DateTime(9999, 12, 31),
                    helpText: etiqueta,
                    confirmText: 'Usar fecha',
                    cancelText: 'Cancelar',
                  );
                  if (seleccionada == null || !context.mounted) return;
                  campo.didChange(FechaNegocio.dia(seleccionada));
                  onChanged(FechaNegocio.dia(seleccionada));
                },
          icon: const Icon(Icons.calendar_today_outlined),
          label: Text(
            '$etiqueta: ${valor == null ? 'Seleccionar fecha' : FechaNegocio.mostrar(valor!)}',
            textAlign: TextAlign.center,
          ),
        ),
        if (campo.errorText != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
            child: Semantics(
              liveRegion: true,
              child: Text(
                campo.errorText!,
                style: Theme.of(context).inputDecorationTheme.errorStyle,
              ),
            ),
          ),
      ],
    ),
  );
}
