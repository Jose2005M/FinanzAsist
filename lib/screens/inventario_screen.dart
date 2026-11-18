import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../widgets/superficies_finanzasist.dart';
import '../widgets/guia_modulo.dart';
import '../widgets/contexto_negocio.dart';
import '../models/guia_modulo.dart';

import '../data/producto_repository.dart';
import '../data/repositorio_simulado.dart';
import '../utils/formato_moneda.dart';
import '../viewmodels/inventario_view_model.dart';
import 'producto_detalle_screen.dart';
import 'registrar_producto_screen.dart';

class InventarioScreen extends StatefulWidget {
  const InventarioScreen({
    super.key,
    required this.repositorio,
    this.empresa,
    this.correo,
    this.cerrarSesion,
  });

  final ProductoRepository repositorio;
  final String? empresa;
  final String? correo;
  final VoidCallback? cerrarSesion;

  @override
  State<InventarioScreen> createState() => _InventarioScreenState();
}

class _InventarioScreenState extends State<InventarioScreen>
    implements ModuloActualizable {
  late final InventarioViewModel _viewModel;
  final _busqueda = TextEditingController();
  final _scroll = ScrollController();

  @override
  Future<void> actualizar() =>
      actualizarConDesplazamiento(_scroll, _viewModel.cargar);

  String _normalizar(String valor) {
    var texto = valor.toLowerCase().trim();
    for (final par in [
      ('á', 'a'),
      ('é', 'e'),
      ('í', 'i'),
      ('ó', 'o'),
      ('ú', 'u'),
      ('ü', 'u'),
    ]) {
      texto = texto.replaceAll(par.$1, par.$2);
    }
    return texto;
  }

  @override
  void initState() {
    super.initState();
    _viewModel = InventarioViewModel(widget.repositorio);
    _viewModel.cargar();
  }

  @override
  void dispose() {
    _busqueda.dispose();
    _scroll.dispose();
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
    setState(_busqueda.clear);
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
          actions: [
            if (widget.cerrarSesion != null)
              PopupMenuButton<String>(
                tooltip: 'Cuenta de empresa',
                icon: const Icon(Icons.account_circle_outlined),
                onSelected: (_) => widget.cerrarSesion!(),
                itemBuilder: (_) => [
                  PopupMenuItem<String>(
                    enabled: false,
                    child: Text(
                      '${widget.empresa}\n${widget.correo}',
                      style: TextStyle(color: colores.onSurface),
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'salir',
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.logout),
                      title: Text('Cerrar sesión'),
                    ),
                  ),
                ],
              ),
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
        body: AnchoContenido(
          child: SafeArea(
            child: CustomScrollView(
              controller: _scroll,
              key: const PageStorageKey('lista-inventario'),
              slivers: [
                SliverToBoxAdapter(
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
                            if (widget.empresa != null) ...[
                              Text(
                                widget.empresa!,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 4),
                            ],
                            const Text(
                              'Consulta los productos y sus existencias.',
                            ),
                          ],
                        ),
                      ),
                      if (widget.repositorio is RepositorioSimulado)
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            'Demostración · datos ficticios, sin guardar en disco.',
                          ),
                        ),
                      if (kDebugMode &&
                          widget.repositorio is RepositorioSimulado)
                        _selectorEscenario(),
                      if (_viewModel.estado == EstadoInventario.conDatos)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                          child: TextField(
                            key: const ValueKey('buscar-producto'),
                            controller: _busqueda,
                            textInputAction: TextInputAction.search,
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              labelText: 'Buscar producto',
                              hintText: 'Nombre del producto',
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: _busqueda.text.isEmpty
                                  ? null
                                  : IconButton(
                                      key: const ValueKey(
                                        'limpiar-busqueda-producto',
                                      ),
                                      tooltip: 'Limpiar búsqueda',
                                      onPressed: () =>
                                          setState(_busqueda.clear),
                                      icon: const Icon(Icons.close),
                                    ),
                            ),
                          ),
                        ),
                      const Padding(
                        padding: EdgeInsets.fromLTRB(20, 8, 20, 16),
                        child: GuiaModulo(modulo: ModuloGuia.inventario),
                      ),
                    ],
                  ),
                ),
                _contenido(),
              ],
            ),
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
        return const SliverFillRemaining(
          hasScrollBody: false,
          child: _MensajeEstado(
            indicador: CircularProgressIndicator(),
            titulo: 'Consultando inventario...',
          ),
        );
      case EstadoInventario.error:
        return SliverFillRemaining(
          hasScrollBody: false,
          child: _MensajeEstado(
            indicador: const Icon(Icons.cloud_off_outlined, size: 48),
            titulo: 'No pudimos cargar el inventario',
            descripcion: 'Intenta consultar tus productos otra vez.',
            accion: FilledButton.icon(
              onPressed: _viewModel.cargar,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ),
        );
      case EstadoInventario.vacio:
        return SliverFillRemaining(
          hasScrollBody: false,
          child: _MensajeEstado(
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
          ),
        );
      case EstadoInventario.conDatos:
        final consulta = _normalizar(_busqueda.text);
        final productos = _viewModel.productos
            .where((p) => _normalizar(p.nombre).contains(consulta))
            .toList();
        if (productos.isEmpty) {
          return SliverFillRemaining(
            hasScrollBody: false,
            child: _MensajeEstado(
              indicador: const Icon(Icons.search_off, size: 48),
              titulo: 'No encontramos ese producto',
              descripcion: 'Prueba con otro nombre o limpia la búsqueda para ver todo el inventario.',
              accion: TextButton(
                onPressed: () => setState(_busqueda.clear),
                child: const Text('Ver todos los productos'),
              ),
            ),
          );
        }
        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          sliver: SliverList.separated(
            itemCount: productos.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final producto = productos[index];
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
          ),
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
      child: Padding(
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
