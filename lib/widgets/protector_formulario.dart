import 'package:flutter/material.dart';

import 'contexto_negocio.dart';

/// Protege el borrador al volver/cancelar y evita salir durante una escritura.
class ProtectorFormulario extends StatefulWidget {
  const ProtectorFormulario({
    super.key,
    required this.tieneCambios,
    required this.estaGuardando,
    required this.child,
  });
  final bool Function() tieneCambios;
  final bool Function() estaGuardando;
  final Widget child;

  @override
  State<ProtectorFormulario> createState() => ProtectorFormularioState();
}

class ProtectorFormularioState extends State<ProtectorFormulario> {
  bool _permitir = false;
  bool _preguntando = false;
  ControlNavegacionNegocio? _control;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final nuevo = ContextoNegocio.of(context)?.control;
    if (nuevo == _control) return;
    _control?.retirarTarea(this);
    _control = nuevo;
    _control?.registrarTarea(this, () => widget.estaGuardando());
  }

  @override
  void dispose() {
    _control?.retirarTarea(this);
    super.dispose();
  }

  Future<void> finalizar([Object? resultado]) async {
    if (!mounted) return;
    setState(() => _permitir = true);
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) Navigator.of(context).pop(resultado);
  }

  Future<void> salir() async {
    if (_preguntando || widget.estaGuardando()) return;
    if (!widget.tieneCambios()) {
      await finalizar();
      return;
    }
    _preguntando = true;
    FocusScope.of(context).unfocus();
    final descartar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        title: const Text('¿Descartar los cambios?'),
        content: const Text(
          'Hay datos sin guardar. Puedes seguir editando o descartar este formulario.',
        ),
        actions: [
          TextButton(
            key: const ValueKey('descartar-cambios'),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Descartar cambios'),
          ),
          FilledButton(
            key: const ValueKey('seguir-editando'),
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Seguir editando'),
          ),
        ],
      ),
    );
    _preguntando = false;
    if (mounted && descartar == true) await finalizar();
  }

  @override
  Widget build(BuildContext context) => PopScope<Object?>(
    canPop: _permitir || (!widget.estaGuardando() && !widget.tieneCambios()),
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop && !_permitir) salir();
    },
    child: widget.child,
  );
}
