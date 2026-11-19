import 'package:flutter/material.dart';

import '../widgets/superficies_finanzasist.dart';
import '../widgets/contexto_negocio.dart';
import '../widgets/protector_formulario.dart';
import '../widgets/vista_previa_importe.dart';

import '../data/negocio_repository.dart';
import '../models/gasto.dart';
import '../viewmodels/gastos_view_model.dart';
import '../widgets/campo_fecha.dart';

class FormularioGastoScreen extends StatefulWidget {
  const FormularioGastoScreen({super.key, required this.repositorio});
  final NegocioRepository repositorio;
  @override
  State<FormularioGastoScreen> createState() => _FormularioGastoScreenState();
}

class _FormularioGastoScreenState extends State<FormularioGastoScreen> {
  late final FormularioGastoViewModel _vm;
  final _form = GlobalKey<FormState>();
  final _salida = GlobalKey<ProtectorFormularioState>();
  bool _tieneCambios() =>
      _vm.fecha != null ||
      _vm.concepto.trim().isNotEmpty ||
      _vm.categoria != null ||
      _vm.valor.trim().isNotEmpty;
  @override
  void initState() {
    super.initState();
    _vm = FormularioGastoViewModel(widget.repositorio);
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (_vm.guardando) return;
    FocusScope.of(context).unfocus();
    if (!_form.currentState!.validate()) return;
    final gasto = await _vm.guardar();
    if (mounted && gasto != null) {
      ContextoNegocio.avisarCambio(context);
      await _salida.currentState!.finalizar(true);
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _vm,
    builder: (context, _) => ProtectorFormulario(
      key: _salida,
      tieneCambios: _tieneCambios,
      estaGuardando: () => _vm.guardando,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Registrar gasto'),
          automaticallyImplyLeading: !_vm.guardando,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.all(20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: PanelFinanzas(
                  child: Form(
                    onChanged: () => setState(() {}),
                    key: _form,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Registra un gasto operativo del negocio. El gasto se incluye en el reporte de la fecha que selecciones.',
                        ),
                        const SizedBox(height: 24),
                        CampoFecha(
                          identificador: 'fecha-gasto',
                          etiqueta: 'Fecha del gasto',
                          valor: _vm.fecha,
                          habilitado: !_vm.guardando,
                          validator: ValidacionGasto.fecha,
                          onChanged: (fecha) =>
                              setState(() => _vm.fecha = fecha),
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          key: const ValueKey('concepto-gasto'),
                          enabled: !_vm.guardando,
                          initialValue: _vm.concepto,
                          textCapitalization: TextCapitalization.sentences,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Concepto',
                            prefixIcon: Icon(Icons.receipt_long_outlined),
                            hintText: 'Ej. Servicio de energía',
                            errorMaxLines: 4,
                          ),
                          onChanged: (v) => _vm.concepto = v,
                          validator: ValidacionGasto.concepto,
                        ),
                        const SizedBox(height: 20),
                        DropdownButtonFormField<String>(
                          key: const ValueKey('categoria-gasto'),
                          initialValue: _vm.categoria,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Categoría',
                            prefixIcon: Icon(Icons.category_outlined),
                            errorMaxLines: 4,
                          ),
                          items:
                              const [
                                    'Servicios',
                                    'Arriendo',
                                    'Transporte',
                                    'Insumos',
                                    'Personal',
                                    'Otros',
                                  ]
                                  .map(
                                    (c) => DropdownMenuItem(
                                      value: c,
                                      child: Text(c),
                                    ),
                                  )
                                  .toList(),
                          onChanged: _vm.guardando
                              ? null
                              : (v) => _vm.categoria = v,
                          validator: ValidacionGasto.categoria,
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          key: const ValueKey('valor-gasto'),
                          enabled: !_vm.guardando,
                          initialValue: _vm.valor,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                            signed: true,
                          ),
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _guardar(),
                          decoration: const InputDecoration(
                            labelText: 'Valor (COP)',
                            prefixIcon: Icon(Icons.payments_outlined),
                            hintText: 'Ej. 80000',
                            helperText: 'Sin miles. Ej.: 6000,50',
                            helperMaxLines: 2,
                            errorMaxLines: 4,
                          ),
                          onChanged: (v) => _vm.valor = v,
                          validator: ValidacionGasto.valor,
                        ),
                        VistaPreviaImporte(texto: _vm.valor),
                        if (_vm.error != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 20),
                            child: Semantics(
                              liveRegion: true,
                              child: Text(
                                _vm.error!,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 24),
                        FilledButton(
                          key: const ValueKey('guardar-gasto'),
                          onPressed: _vm.guardando ? null : _guardar,
                          child: _vm.guardando
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Guardar gasto'),
                        ),
                        TextButton(
                          onPressed: _vm.guardando
                              ? null
                              : () => _salida.currentState!.salir(),
                          child: const Text('Cancelar'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
