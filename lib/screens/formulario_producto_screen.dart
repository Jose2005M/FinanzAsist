import 'package:flutter/material.dart';

import '../data/producto_repository.dart';
import '../models/producto.dart';
import '../viewmodels/inventario_view_model.dart';

class FormularioProductoScreen extends StatefulWidget {
  const FormularioProductoScreen({
    super.key,
    required this.viewModel,
    this.productoInicial,
  });

  final InventarioViewModel viewModel;
  final Producto? productoInicial;

  @override
  State<FormularioProductoScreen> createState() =>
      _FormularioProductoScreenState();
}

class _FormularioProductoScreenState extends State<FormularioProductoScreen> {
  final _formulario = GlobalKey<FormState>();
  late final TextEditingController _nombre;
  late final TextEditingController _costo;
  late final TextEditingController _precio;

  bool get _editando => widget.productoInicial != null;

  String _importeParaFormulario(double importe) {
    return importe
        .toString()
        .replaceFirst(RegExp(r'\.0$'), '')
        .replaceAll('.', ',');
  }

  @override
  void initState() {
    super.initState();
    final producto = widget.productoInicial;
    _nombre = TextEditingController(text: producto?.nombre ?? '');
    _costo = TextEditingController(
      text: producto == null
          ? ''
          : _importeParaFormulario(producto.costoCompra),
    );
    _precio = TextEditingController(
      text: producto == null
          ? ''
          : _importeParaFormulario(producto.precioVenta),
    );
  }

  @override
  void dispose() {
    _nombre.dispose();
    _costo.dispose();
    _precio.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (widget.viewModel.guardando) return;
    FocusScope.of(context).unfocus();
    if (!_formulario.currentState!.validate()) return;

    try {
      final producto = widget.productoInicial;
      if (producto == null) {
        await widget.viewModel.registrarProducto(
          nombre: _nombre.text,
          costoCompra: _costo.text,
          precioVenta: _precio.text,
        );
      } else {
        await widget.viewModel.actualizarProducto(
          id: producto.id,
          nombre: _nombre.text,
          costoCompra: _costo.text,
          precioVenta: _precio.text,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ProductoNoEncontradoException {
      _mostrarError(
        'El producto ya no está disponible. Regresa al inventario.',
      );
    } catch (_) {
      _mostrarError('No pudimos guardar el producto. Intenta de nuevo.');
    }
  }

  void _mostrarError(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(mensaje)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_editando ? 'Editar producto' : 'Registrar producto'),
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: widget.viewModel,
          builder: (context, _) => SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Form(
                  key: _formulario,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_editando) ...[
                        Text('Identificador: ${widget.productoInicial!.id}'),
                        const SizedBox(height: 8),
                        Text(
                          'Existencias: ${widget.productoInicial!.cantidad} unidades. '
                          'Se conservan al editar el producto.',
                        ),
                      ] else
                        const Text(
                          'El producto se crea con 0 unidades. Las existencias '
                          'iniciales se registrarán en el módulo de inventario.',
                        ),
                      const SizedBox(height: 24),
                      TextFormField(
                        key: const ValueKey('nombre-producto'),
                        controller: _nombre,
                        enabled: !widget.viewModel.guardando,
                        textCapitalization: TextCapitalization.sentences,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Nombre del producto',
                          errorMaxLines: 3,
                          border: OutlineInputBorder(),
                        ),
                        validator: widget.viewModel.validarNombre,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        key: const ValueKey('costo-producto'),
                        controller: _costo,
                        enabled: !widget.viewModel.guardando,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Costo de compra (COP)',
                          hintText: 'Ej. 6000',
                          helperText:
                              'Escribe el valor sin separadores de miles.',
                          helperMaxLines: 2,
                          errorMaxLines: 3,
                          border: OutlineInputBorder(),
                        ),
                        validator: widget.viewModel.validarCosto,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        key: const ValueKey('precio-producto'),
                        controller: _precio,
                        enabled: !widget.viewModel.guardando,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _guardar(),
                        decoration: const InputDecoration(
                          labelText: 'Precio de venta (COP)',
                          hintText: 'Ej. 10000',
                          errorMaxLines: 3,
                          border: OutlineInputBorder(),
                        ),
                        validator: widget.viewModel.validarPrecio,
                      ),
                      const SizedBox(height: 24),
                      FilledButton(
                        key: const ValueKey('guardar-producto'),
                        onPressed: widget.viewModel.guardando ? null : _guardar,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: widget.viewModel.guardando
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  _editando
                                      ? 'Guardar cambios'
                                      : 'Guardar producto',
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
