import 'package:flutter/material.dart';

import '../data/producto_repository.dart';
import '../models/producto.dart';
import '../utils/formato_moneda.dart';
import '../viewmodels/detalle_producto_view_model.dart';
import '../viewmodels/inventario_view_model.dart';
import 'formulario_producto_screen.dart';

class ProductoDetalleScreen extends StatefulWidget {
  const ProductoDetalleScreen({
    super.key,
    required this.productoId,
    required this.repositorio,
    required this.inventarioViewModel,
  });

  final String productoId;
  final ProductoRepository repositorio;
  final InventarioViewModel inventarioViewModel;

  @override
  State<ProductoDetalleScreen> createState() => _ProductoDetalleScreenState();
}

class _ProductoDetalleScreenState extends State<ProductoDetalleScreen> {
  late final DetalleProductoViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = DetalleProductoViewModel(
      repositorio: widget.repositorio,
      productoId: widget.productoId,
    );
    _viewModel.cargar();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _editarProducto(Producto producto) async {
    final actualizado = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        settings: RouteSettings(
          name: '/productos/${Uri.encodeComponent(producto.id)}/editar',
        ),
        builder: (_) => FormularioProductoScreen(
          viewModel: widget.inventarioViewModel,
          productoInicial: producto,
        ),
      ),
    );
    if (!mounted || actualizado != true) return;
    await _viewModel.cargar();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Producto actualizado')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del producto')),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _viewModel,
          builder: (context, _) {
            if (_viewModel.estado == EstadoDetalle.cargando) {
              return const Center(child: CircularProgressIndicator());
            }
            if (_viewModel.estado == EstadoDetalle.error) {
              return Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.search_off, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        _viewModel.mensajeError,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _viewModel.cargar,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final producto = _viewModel.producto!;
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  producto.nombre,
                  style: Theme.of(context).textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (producto.cantidad == 0)
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Chip(label: Text('Agotado')),
                  ),
                const SizedBox(height: 16),
                _Dato(etiqueta: 'Identificador', valor: producto.id),
                _Dato(
                  etiqueta: 'Existencias disponibles',
                  valor: '${producto.cantidad} unidades',
                ),
                _Dato(
                  etiqueta: 'Costo de compra por unidad',
                  valor: formatearPesos(producto.costoCompra),
                ),
                _Dato(
                  etiqueta: 'Precio de venta por unidad',
                  valor: formatearPesos(producto.precioVenta),
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  key: const ValueKey('editar-producto'),
                  onPressed: () => _editarProducto(producto),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Editar producto'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato({required this.etiqueta, required this.valor});

  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(etiqueta, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 6),
            Text(valor, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}
