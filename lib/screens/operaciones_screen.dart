import 'package:flutter/material.dart';

import '../widgets/superficies_finanzasist.dart';
import '../widgets/guia_modulo.dart';
import '../widgets/contexto_negocio.dart';
import '../models/guia_modulo.dart';

import '../data/negocio_repository.dart';
import '../models/operacion.dart';
import '../models/permisos.dart';
import '../widgets/permisos_sesion.dart';
import '../utils/formato_moneda.dart';
import '../utils/formato_operacion.dart';
import '../viewmodels/historial_view_model.dart';
import 'operacion_screen.dart';

class OperacionesScreen extends StatefulWidget {
  const OperacionesScreen({
    super.key,
    required this.repositorio,
    required this.tipo,
  });
  final NegocioRepository repositorio;
  final TipoOperacion tipo;
  @override
  State<OperacionesScreen> createState() => _OperacionesScreenState();
}

class _OperacionesScreenState extends State<OperacionesScreen>
    implements ModuloActualizable {
  late final HistorialViewModel _vm;
  final _scroll = ScrollController();
  @override
  Future<void> actualizar() => actualizarConDesplazamiento(_scroll, _vm.cargar);
  bool get compra => widget.tipo == TipoOperacion.compra;
  @override
  void initState() {
    super.initState();
    _vm = HistorialViewModel(widget.repositorio, widget.tipo);
    _vm.cargar();
  }

  @override
  void dispose() {
    _scroll.dispose();
    _vm.dispose();
    super.dispose();
  }

  Future<void> _nueva() async {
    final confirmada = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            OperacionScreen(repositorio: widget.repositorio, tipo: widget.tipo),
      ),
    );
    if (!mounted || confirmada != true) return;
    _vm.cargar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${compra ? 'Compra' : 'Venta'} confirmada. Inventario actualizado.',
        ),
      ),
    );
  }

  Widget? _estado() {
    if (_vm.cargando) return const Center(child: CircularProgressIndicator());
    if (_vm.error != null) {
      return EstadoModulo(
        titulo: _vm.error!,
        descripcion: 'Vuelve a consultar el historial de tu empresa.',
        icono: Icons.error_outline,
        accion: FilledButton(
          onPressed: _vm.cargar,
          child: const Text('Reintentar'),
        ),
      );
    }
    if (_vm.operaciones.isEmpty) {
      return EstadoModulo(
        titulo: compra
            ? 'Aún no tienes compras confirmadas'
            : 'Aún no tienes ventas confirmadas',
        descripcion: compra
            ? 'Registra una compra para incorporar mercancía al inventario.'
            : 'Registra una venta para comenzar tu historial de ingresos.',
        icono: compra ? Icons.shopping_bag_outlined : Icons.point_of_sale,
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _vm,
    builder: (context, _) => Scaffold(
      appBar: AppBar(
        leading: ContextoNegocio.volverAInventario(context),
        title: Text(
          compra
              ? 'Compras'
              : PermisosSesion.rolDe(context) == RolCuenta.vendedor
              ? 'Tus ventas'
              : 'Ventas',
        ),
      ),
      body: AnchoContenido(
        child: SafeArea(
          child: ListadoModulo(
            controller: _scroll,
            cabecera: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CabeceraModulo(
                    titulo: compra
                        ? 'Historial de compras'
                        : PermisosSesion.rolDe(context) == RolCuenta.vendedor
                        ? 'Tus ventas'
                        : 'Historial de ventas',
                    descripcion:
                        'Consulta las operaciones confirmadas de tu empresa.',
                    icono: compra
                        ? Icons.shopping_bag_outlined
                        : Icons.point_of_sale,
                  ),
                  const SizedBox(height: 20),
                  if (PermisosSesion.permite(
                    context,
                    compra ? Permiso.registrarCompras : Permiso.registrarVentas,
                  ))
                    FilledButton.icon(
                      key: ValueKey(compra ? 'nueva-compra' : 'nueva-venta'),
                      onPressed: _nueva,
                      icon: const Icon(Icons.add),
                      label: Text(
                        compra ? 'Registrar compra' : 'Registrar venta',
                      ),
                    ),
                  const SizedBox(height: 16),
                  GuiaModulo(
                    modulo: compra ? ModuloGuia.compras : ModuloGuia.ventas,
                  ),
                ],
              ),
            ),
            estado: _estado(),
            cantidad: _vm.operaciones.length,
            onActualizar: _vm.cargar,
            itemBuilder: (context, i) {
              final o = _vm.operaciones[i];
              return ExpansionTile(
                title: Text(
                  formatearPesos(pesos(o.totalCentavos)),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                subtitle: Text(
                  '${fechaColombia(o.fecha)} · ${o.detalles.length} ${o.detalles.length == 1 ? 'producto' : 'productos'}',
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final d in o.detalles)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              '${d['nombre']}\n${d['cantidad']} unidades × ${formatearPesos(pesos(d['valorCentavos'] as int))}',
                            ),
                          ),
                        if (!compra &&
                            PermisosSesion.permite(
                              context,
                              Permiso.verCostos,
                            )) ...[
                          for (final d in o.detalles)
                            Text(
                              'Costo asignado por unidad de ${d['nombre']}: ${formatearPesos(pesos((d['costoAsignadoCentavos'] ?? d['costoCatalogoCentavos']) as int))}',
                            ),
                          const SizedBox(height: 12),
                        ],
                        Text(
                          'Subtotal: ${formatearPesos(pesos(o.subtotalCentavos))}',
                        ),
                        if (!compra)
                          Text(
                            'Descuento: ${formatearPesos(pesos(o.descuentoCentavos))}',
                          ),
                        Text(
                          'Total: ${formatearPesos(pesos(o.totalCentavos))}',
                        ),
                        if (!compra &&
                            PermisosSesion.permite(
                              context,
                              Permiso.verCostos,
                            )) ...[
                          Text(
                            'Costo de ventas: ${formatearPesos(pesos(o.costoVentasCentavos))}',
                          ),
                          Text(
                            'Utilidad bruta: ${formatearPesos(pesos(o.utilidadBrutaCentavos))}',
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Costo asignado: costo del catálogo al confirmar la venta.',
                          ),
                        ],
                        const SizedBox(height: 12),
                        Text(
                          'Responsable: ${_vm.responsables[o.usuarioId] ?? 'Usuario anterior'}',
                        ),
                        SelectableText('Operación: ${o.id}'),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    ),
  );
}
