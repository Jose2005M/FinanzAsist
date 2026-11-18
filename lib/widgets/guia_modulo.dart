import 'package:flutter/material.dart';

import '../data/almacen_guias.dart';
import '../models/guia_modulo.dart';
import '../theme/tema_finanzasist.dart';
import '../viewmodels/guias_view_model.dart';
import 'superficies_finanzasist.dart';

class AreaGuias extends StatefulWidget {
  const AreaGuias({super.key, required this.almacen, required this.child});
  final AlmacenGuias almacen;
  final Widget child;

  @override
  State<AreaGuias> createState() => _AreaGuiasState();
}

class _AreaGuiasState extends State<AreaGuias> {
  late final _modelo = GuiasViewModel(widget.almacen)..cargar();

  @override
  void dispose() {
    _modelo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _ContextoGuias(notifier: _modelo, child: widget.child);
}

class _ContextoGuias extends InheritedNotifier<GuiasViewModel> {
  const _ContextoGuias({required super.notifier, required super.child});

  static GuiasViewModel? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_ContextoGuias>()?.notifier;
}

/// Introducción opcional en el contenido: no bloquea las acciones del módulo.
class GuiaModulo extends StatefulWidget {
  const GuiaModulo({super.key, required this.modulo});
  final ModuloGuia modulo;

  @override
  State<GuiaModulo> createState() => _GuiaModuloState();
}

class _GuiaModuloState extends State<GuiaModulo> {
  bool? _abierta;
  bool _pasos = false;

  Future<void> _entendido(GuiasViewModel modelo) async {
    setState(() => _abierta = false);
    final guardada = await modelo.marcarVista(widget.modulo);
    if (!mounted || guardada) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'La guía se ocultó por ahora. Puede volver a aparecer al abrir la aplicación.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final modelo = _ContextoGuias.of(context);
    if (modelo == null || modelo.cargando) return const SizedBox.shrink();
    final modulo = widget.modulo;
    final abierta = _abierta ?? !modelo.vista(modulo);
    if (!abierta) {
      return Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          key: ValueKey('guia-abrir-${modulo.name}'),
          onPressed: () => setState(() {
            _abierta = true;
            _pasos = true;
          }),
          icon: const Icon(Icons.help_outline),
          label: Text('Guía de ${modulo.nombre}'),
        ),
      );
    }
    return PanelFinanzas(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const ExcludeSemantics(
                child: Icon(
                  Icons.lightbulb_outline,
                  color: ColoresFinanzAsist.foco,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    'Guía de ${modulo.nombre}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
              IconButton(
                key: ValueKey('guia-omitir-${modulo.name}'),
                tooltip: 'Omitir guía de ${modulo.nombre}',
                onPressed: () => _entendido(modelo),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(modulo.proposito),
          const SizedBox(height: 12),
          if (_pasos)
            for (var i = 0; i < modulo.pasos.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text('${i + 1}. ${modulo.pasos[i]}'),
              ),
          if (!_pasos) Text(modulo.inicio),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
            runSpacing: 4,
            children: [
              TextButton(
                key: ValueKey('guia-pasos-${modulo.name}'),
                onPressed: () => setState(() => _pasos = !_pasos),
                child: Text(_pasos ? 'Ver menos' : 'Ver pasos'),
              ),
              TextButton(
                key: ValueKey('guia-entendido-${modulo.name}'),
                onPressed: () => _entendido(modelo),
                child: const Text('Entendido'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
