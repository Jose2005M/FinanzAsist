import 'dart:convert';

import 'package:flutter/material.dart';

import '../widgets/superficies_finanzasist.dart';
import '../widgets/contexto_negocio.dart';
import '../widgets/protector_formulario.dart';
import '../widgets/vista_previa_importe.dart';

import '../data/negocio_repository.dart';
import '../models/operacion.dart';
import '../models/reglas_inventario.dart';
import '../utils/formato_moneda.dart';
import '../utils/formato_operacion.dart';
import '../viewmodels/operacion_view_model.dart';

class OperacionScreen extends StatefulWidget {
  const OperacionScreen({
    super.key,
    required this.repositorio,
    required this.tipo,
    this.productoId,
  });
  final NegocioRepository repositorio;
  final TipoOperacion tipo;
  final String? productoId;
  @override
  State<OperacionScreen> createState() => _OperacionScreenState();
}

class _OperacionScreenState extends State<OperacionScreen> {
  late final OperacionViewModel _vm;
  final _form = GlobalKey<FormState>();
  final _salida = GlobalKey<ProtectorFormularioState>();
  ControlNavegacionNegocio? _control;
  String? _original;
  String get _firma => jsonEncode([
    for (final linea in _vm.lineas)
      [linea.productoId, linea.cantidad, linea.valor],
    _vm.descuento,
    _vm.motivo,
  ]);
  bool _tieneCambios() => _original != null && _firma != _original;
  bool _resumen = false;

  @override
  void initState() {
    super.initState();
    _vm = OperacionViewModel(
      widget.repositorio,
      widget.tipo,
      productoId: widget.productoId,
    );
    _vm.cargar().then((_) {
      if (mounted) setState(() => _original = _firma);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final alcance = ContextoNegocio.of(context);
    if (alcance?.control == _control) return;
    _control?.retirarVista(this);
    _control = alcance?.control;
    if (alcance != null) {
      _control!.registrarVista(this, alcance.modulo, () async {
        if (!mounted || _vm.cargando || _vm.guardando) return;
        await _vm.cargar(mostrarCarga: false);
      });
    }
  }

  @override
  void dispose() {
    _control?.retirarVista(this);
    _vm.dispose();
    super.dispose();
  }

  Future<void> _confirmar() async {
    final operacion = await _vm.confirmar();
    if (mounted && operacion != null) {
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
          title: Text(nombreOperacion(widget.tipo)),
          automaticallyImplyLeading: !_vm.guardando,
        ),
        body: SafeArea(child: _contenido()),
      ),
    ),
  );

  Widget _contenido() {
    if (_vm.cargando) return const Center(child: CircularProgressIndicator());
    if (_vm.errorCarga != null || _vm.productos.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _vm.errorCarga ??
                    'Registra un producto en Inventario para comenzar.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              if (_vm.errorCarga != null)
                FilledButton(
                  onPressed: _vm.cargar,
                  child: const Text('Reintentar'),
                ),
            ],
          ),
        ),
      );
    }
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: _resumen
              ? PanelFinanzas(child: _vistaResumen())
              : PanelFinanzas(
                  child: Form(
                    onChanged: () => setState(() {}),
                    key: _form,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          _vm.manual
                              ? (widget.tipo == TipoOperacion.ajuste
                                    ? 'Escribe las unidades que entran o salen: por ejemplo, -2 para retirar dos unidades.'
                                    : 'Registra el conteo de apertura. Solo se permite si el producto no tiene movimientos.')
                              : 'Agrega los productos y revisa el resumen antes de confirmar.',
                        ),
                        const SizedBox(height: 24),
                        for (var i = 0; i < _vm.lineas.length; i++)
                          _linea(_vm.lineas[i], i),
                        if (!_vm.manual)
                          OutlinedButton.icon(
                            onPressed: () {
                              _vm.lineas.add(BorradorLinea());
                              _vm.actualizar();
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Agregar producto'),
                          ),
                        if (_vm.manual)
                          TextFormField(
                            key: const ValueKey('motivo-movimiento'),
                            initialValue: _vm.motivo,
                            decoration: const InputDecoration(
                              labelText: 'Motivo',
                              prefixIcon: Icon(Icons.edit_note_outlined),

                              errorMaxLines: 4,
                            ),
                            maxLines: 3,
                            onChanged: (v) => _vm.motivo = v,
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Indica el motivo del movimiento'
                                : null,
                          ),
                        if (widget.tipo == TipoOperacion.venta) ...[
                          const SizedBox(height: 20),
                          TextFormField(
                            key: const ValueKey('descuento-venta'),
                            initialValue: _vm.descuento,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Descuento total (COP)',
                              prefixIcon: Icon(Icons.discount_outlined),
                              helperText: 'Sin miles. Ej.: 6000,50',
                              helperMaxLines: 2,
                              errorMaxLines: 4,
                            ),
                            validator: _vm.validarDescuento,
                            onChanged: (v) {
                              _vm.descuento = v;
                              _vm.actualizar();
                            },
                          ),
                          VistaPreviaImporte(texto: _vm.descuento),
                        ],
                        if (!_vm.manual) ...[
                          const SizedBox(height: 24),
                          _totales(),
                        ],
                        const SizedBox(height: 24),
                        FilledButton(
                          key: const ValueKey('revisar-operacion'),
                          onPressed: () {
                            FocusScope.of(context).unfocus();
                            if (_form.currentState!.validate()) {
                              setState(() => _resumen = true);
                            }
                          },
                          child: Text('Revisar operación'),
                        ),
                        TextButton(
                          onPressed: () => _salida.currentState!.salir(),
                          child: const Text('Cancelar'),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _linea(BorradorLinea linea, int indice) {
    final producto = _vm.productoDe(linea);
    return Column(
      key: ObjectKey(linea),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!_vm.manual)
          Row(
            children: [
              Expanded(
                child: Text(
                  'Producto ${indice + 1}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (_vm.lineas.length > 1)
                IconButton(
                  tooltip: 'Quitar producto ${indice + 1}',
                  onPressed: () {
                    _vm.lineas.remove(linea);
                    _vm.actualizar();
                  },
                  icon: const Icon(Icons.close),
                ),
            ],
          ),
        DropdownButtonFormField<String>(
          key: ValueKey('producto-linea-$indice-${linea.productoId}'),
          initialValue: linea.productoId,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Producto',
            prefixIcon: Icon(Icons.inventory_2_outlined),

            errorMaxLines: 4,
          ),
          selectedItemBuilder: (context) => _vm.productos
              .map(
                (p) => Text(
                  p.nombre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              )
              .toList(),
          items: _vm.productos
              .map((p) => DropdownMenuItem(value: p.id, child: Text(p.nombre)))
              .toList(),
          onChanged: (id) {
            if (id != null) _vm.seleccionar(linea, id);
          },
          validator: (_) => _vm.validarProducto(linea),
        ),
        if (producto != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '${producto.nombre}\n${producto.cantidad} unidades disponibles',
            ),
          ),
        const SizedBox(height: 16),
        TextFormField(
          key: ValueKey('cantidad-linea-$indice'),
          initialValue: linea.cantidad,
          keyboardType: TextInputType.numberWithOptions(
            signed: widget.tipo == TipoOperacion.ajuste,
          ),
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.numbers),
            labelText: widget.tipo == TipoOperacion.ajuste
                ? 'Variación de unidades (+ / −)'
                : 'Cantidad de unidades',

            errorMaxLines: 4,
          ),
          onChanged: (v) {
            linea.cantidad = v;
            _vm.actualizar();
          },
          validator: (_) => _vm.validarCantidad(linea),
        ),
        if (!_vm.manual) ...[
          const SizedBox(height: 16),
          TextFormField(
            key: ValueKey('valor-linea-$indice-${linea.productoId}'),
            initialValue: linea.valor,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.payments_outlined),
              labelText: widget.tipo == TipoOperacion.compra
                  ? 'Costo unitario (COP)'
                  : 'Precio cobrado por unidad (COP)',
              helperText: 'Sin miles. Ej.: 6000,50',
              helperMaxLines: 2,

              errorMaxLines: 4,
            ),
            onChanged: (v) {
              linea.valor = v;
              _vm.actualizar();
            },
            validator: ReglasInventario.importe,
          ),
          VistaPreviaImporte(texto: linea.valor),
        ],
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _totales() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text('Subtotal: ${formatearPesos(pesos(_vm.subtotalCentavos))}'),
      if (widget.tipo == TipoOperacion.venta)
        Text('Descuento: ${formatearPesos(pesos(_vm.descuentoCentavos))}'),
      const SizedBox(height: 8),
      Text(
        'Total: ${formatearPesos(pesos(_vm.subtotalCentavos - (widget.tipo == TipoOperacion.venta ? _vm.descuentoCentavos : 0)))}',
        style: Theme.of(context).textTheme.titleLarge,
      ),
    ],
  );

  Widget _vistaResumen() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        'Revisa y confirma',
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      const SizedBox(height: 8),
      const Text('Las existencias se actualizan al confirmar.'),
      const SizedBox(height: 24),
      for (final linea in _vm.lineas) ...[
        Text(
          _vm.productoDe(linea)!.nombre,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Text(
          '${linea.cantidad} unidades${_vm.manual ? '' : ' × ${formatearPesos(double.parse(linea.valor.replaceAll(',', '.')))}'}',
        ),
        Text(
          'Existencias después: ${_vm.productoDe(linea)!.cantidad + (widget.tipo == TipoOperacion.venta ? -1 : 1) * int.parse(linea.cantidad)} unidades',
        ),
        const Divider(height: 32),
      ],
      if (_vm.manual) Text('Motivo: ${_vm.motivo}') else _totales(),
      if (_vm.error != null)
        Padding(
          padding: const EdgeInsets.only(top: 20),
          child: Semantics(
            liveRegion: true,
            child: Text(
              _vm.error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ),
      const SizedBox(height: 24),
      FilledButton(
        key: const ValueKey('confirmar-operacion'),
        onPressed: _vm.guardando ? null : _confirmar,
        child: _vm.guardando
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text('Confirmar ${nombreOperacion(widget.tipo).toLowerCase()}'),
      ),
      TextButton(
        onPressed: _vm.guardando
            ? null
            : () => setState(() => _resumen = false),
        child: const Text('Volver a editar'),
      ),
      TextButton(
        onPressed: _vm.guardando ? null : () => _salida.currentState!.salir(),
        child: const Text('Cancelar'),
      ),
    ],
  );
}
