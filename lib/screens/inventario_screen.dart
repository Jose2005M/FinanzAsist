import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../data/producto_repository.dart';
import '../utils/formato_moneda.dart';
import '../viewmodels/inventario_view_model.dart';
import 'producto_detalle_screen.dart';
import 'registrar_producto_screen.dart';

class InventarioScreen extends StatefulWidget {
  const InventarioScreen({super.key, required this.repositorio});

  final ProductoRepository repositorio;

  @override
  State<InventarioScreen> createState() => _InventarioScreenState();
}

class _InventarioScreenState extends State<InventarioScreen> {
  late final InventarioViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = InventarioViewModel(widget.repositorio);
    _viewModel.cargar();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _registrarProducto() async {
    final creado = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        settings: const RouteSettings(name: '/productos/nuevo'),
        builder: (_) => RegistrarProductoScreen(viewModel: _viewModel),
      ),
    );
    if (!mounted || creado != true) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Producto registrado')));
  }

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) => Scaffold(
        appBar: AppBar(
          title: const Text('FinanzAsist'),
          backgroundColor: colores.primary,
          foregroundColor: colores.onPrimary,
          actions: [
            IconButton(
              tooltip: 'Actualizar inventario',
              onPressed:
                  _viewModel.estado == EstadoInventario.cargando ||
                      _viewModel.guardando
                  ? null
                  : _viewModel.cargar,
              icon: const Icon(Icons.refresh),
            ),
            IconButton(
              tooltip: 'Registrar producto',
              onPressed: _viewModel.guardando ? null : _registrarProducto,
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Inventario',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    const Text('Consulta los productos y sus existencias.'),
                  ],
                ),
              ),
              if (kDebugMode) _selectorEscenario(),
              Expanded(child: _contenido()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _selectorEscenario() {
    const etiquetas = {
      EscenarioInventario.conDatos: 'Con datos',
      EscenarioInventario.vacio: 'Vacío',
      EscenarioInventario.error: 'Error',
      EscenarioInventario.cargando: 'Cargando',
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Escenarios de prueba',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final escenario in EscenarioInventario.values)
                ChoiceChip(
                  key: ValueKey('escenario-${escenario.name}'),
                  label: Text(etiquetas[escenario]!),
                  selected: _viewModel.escenario == escenario,
                  onSelected: _viewModel.guardando
                      ? null
                      : (_) => _viewModel.cambiarEscenario(escenario),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _contenido() {
    switch (_viewModel.estado) {
      case EstadoInventario.cargando:
        return const _MensajeEstado(
          indicador: CircularProgressIndicator(),
          titulo: 'Consultando inventario...',
        );
      case EstadoInventario.error:
        return _MensajeEstado(
          indicador: const Icon(Icons.cloud_off_outlined, size: 48),
          titulo: 'No pudimos cargar el inventario',
          descripcion: 'Intenta consultar tus productos otra vez.',
          accion: FilledButton.icon(
            onPressed: _viewModel.cargar,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        );
      case EstadoInventario.vacio:
        return _MensajeEstado(
          indicador: const Icon(Icons.inventory_2_outlined, size: 48),
          titulo: 'Aún no tienes productos',
          descripcion:
              'Registra tu primer producto para comenzar el inventario.',
          accion: FilledButton.icon(
            key: const ValueKey('registrar-desde-vacio'),
            onPressed: _registrarProducto,
            icon: const Icon(Icons.add),
            label: const Text('Registrar producto'),
          ),
        );
      case EstadoInventario.conDatos:
        return ListView.separated(
          key: const PageStorageKey('lista-inventario'),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          itemCount: _viewModel.productos.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final producto = _viewModel.productos[index];
            return Card(
              margin: EdgeInsets.zero,
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                key: ValueKey('producto-${producto.id}'),
                onTap: () => Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    settings: RouteSettings(
                      name: '/productos/${Uri.encodeComponent(producto.id)}',
                    ),
                    builder: (_) => ProductoDetalleScreen(
                      productoId: producto.id,
                      repositorio: widget.repositorio,
                      inventarioViewModel: _viewModel,
                    ),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              producto.nombre,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 12,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text('${producto.cantidad} unidades disponibles'),
                          if (producto.cantidad == 0)
                            const Chip(label: Text('Agotado')),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('Venta: ${formatearPesos(producto.precioVenta)}'),
                    ],
                  ),
                ),
              ),
            );
          },
        );
    }
  }
}

class _MensajeEstado extends StatelessWidget {
  const _MensajeEstado({
    required this.indicador,
    required this.titulo,
    this.descripcion,
    this.accion,
  });

  final Widget indicador;
  final String titulo;
  final String? descripcion;
  final Widget? accion;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            indicador,
            const SizedBox(height: 20),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (descripcion != null) ...[
              const SizedBox(height: 8),
              Text(descripcion!, textAlign: TextAlign.center),
            ],
            if (accion != null) ...[const SizedBox(height: 20), accion!],
          ],
        ),
      ),
    );
  }
}
