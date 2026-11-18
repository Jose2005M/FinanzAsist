import 'package:flutter/material.dart';

import '../widgets/superficies_finanzasist.dart';
import '../widgets/contexto_negocio.dart';

import '../data/producto_repository.dart';
import '../data/negocio_repository.dart';
import '../models/operacion.dart';
import '../models/producto.dart';
import '../utils/formato_moneda.dart';
import '../utils/formato_operacion.dart';
import '../viewmodels/detalle_producto_view_model.dart';
import '../viewmodels/inventario_view_model.dart';
import 'formulario_producto_screen.dart';
import 'operacion_screen.dart';

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
  final _scroll = ScrollController();
  ControlNavegacionNegocio? _control;

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
  void didChangeDependencies() {
    super.didChangeDependencies();
    final alcance = ContextoNegocio.of(context);
    if (alcance?.control == _control) return;
    _control?.retirarVista(this);
    _control = alcance?.control;
    if (alcance != null) {
      _control!.registrarVista(
        this,
        alcance.modulo,
        () => actualizarConDesplazamiento(
          _scroll,
          () => _viewModel.cargar(mostrarCarga: false),
        ),
      );
    }
  }

  @override
  void dispose() {
    _control?.retirarVista(this);
    _scroll.dispose();
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

  Future<void> _movimiento(TipoOperacion tipo) async {
    final repositorio = widget.repositorio;
    if (repositorio is! NegocioRepository) return;
    final confirmado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => OperacionScreen(
          repositorio: repositorio,
          tipo: tipo,
          productoId: widget.productoId,
        ),
      ),
    );
    if (!mounted || confirmado != true) return;
    await widget.inventarioViewModel.cargar();
    await _viewModel.cargar();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Movimiento registrado. Existencias actualizadas.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del producto')),
      body: AnchoContenido(
        child: SafeArea(
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
                controller: _scroll,
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
                  PanelFinanzas(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
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
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    key: const ValueKey('editar-producto'),
                    onPressed: () => _editarProducto(producto),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Editar producto'),
                  ),
                  if (widget.repositorio is NegocioRepository) ...[
                    const SizedBox(height: 12),
                    if (producto.cantidad == 0 &&
                        _viewModel.movimientos.isEmpty) ...[
                      OutlinedButton.icon(
                        key: const ValueKey('existencias-iniciales'),
                        onPressed: () => _movimiento(TipoOperacion.inicial),
                        icon: const Icon(Icons.inventory_2_outlined),
                        label: const Text('Registrar existencias iniciales'),
                      ),
                      const SizedBox(height: 12),
                    ],
                    OutlinedButton.icon(
                      key: const ValueKey('ajustar-inventario'),
                      onPressed: () => _movimiento(TipoOperacion.ajuste),
                      icon: const Icon(Icons.tune),
                      label: const Text('Ajustar existencias'),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Movimientos de inventario',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    if (_viewModel.movimientos.isEmpty)
                      const Text('Aún no hay movimientos registrados.'),
                    for (final movimiento in _viewModel.movimientos)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${nombreOperacion(movimiento.tipo)} · ${movimiento.cantidad > 0 ? '+' : ''}${movimiento.cantidad} unidades',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text('Saldo: ${movimiento.saldo} unidades'),
                            Text(movimiento.motivo),
                            Text(
                              '${fechaColombia(movimiento.fecha)} · ${movimiento.usuarioId}',
                            ),
                          ],
                        ),
                      ),
                  ],
                ],
              );
            },
          ),
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
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          etiqueta,
          style: Theme.of(context).textTheme.labelLarge
              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 6),
        Text(valor, style: Theme.of(context).textTheme.titleMedium),
      ],
    ),
  );
}
