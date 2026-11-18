import 'package:flutter/material.dart';

import '../widgets/superficies_finanzasist.dart';
import '../widgets/guia_modulo.dart';
import '../widgets/contexto_negocio.dart';
import '../models/guia_modulo.dart';

import '../data/negocio_repository.dart';
import '../models/fecha_negocio.dart';
import '../models/operacion.dart';
import '../models/reporte_financiero.dart';
import '../utils/formato_moneda.dart';
import '../viewmodels/reportes_view_model.dart';
import '../widgets/campo_fecha.dart';

class ReportesScreen extends StatefulWidget {
  const ReportesScreen({super.key, required this.repositorio});
  final NegocioRepository repositorio;
  @override
  State<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends State<ReportesScreen>
    implements ModuloActualizable {
  late final ReportesViewModel _vm;
  final _scroll = ScrollController();
  @override
  Future<void> actualizar() =>
      actualizarConDesplazamiento(_scroll, _vm.consultar);
  final _form = GlobalKey<FormState>();
  @override
  void initState() {
    super.initState();
    _vm = ReportesViewModel(widget.repositorio);
    _vm.consultar();
  }

  @override
  void dispose() {
    _scroll.dispose();
    _vm.dispose();
    super.dispose();
  }

  void _consultar() {
    if (_form.currentState!.validate()) _vm.consultar();
  }

  void _periodoRapido(DateTime inicio, DateTime fin) {
    FocusScope.of(context).unfocus();
    _vm.cambiarFechas(inicio: inicio, fin: fin);
    _form.currentState?.reset();
    _vm.consultar();
  }

  Widget _periodosRapidos() {
    final hoy = FechaNegocio.hoy();
    final opciones = [
      ('Hoy', hoy),
      ('Últimos 7 días', hoy.subtract(const Duration(days: 6))),
      ('Este mes', DateTime.utc(hoy.year, hoy.month)),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var i = 0; i < opciones.length; i++)
          ChoiceChip(
            key: ValueKey('periodo-rapido-$i'),
            label: Text(opciones[i].$1),
            selected: _vm.desde == opciones[i].$2 && _vm.hasta == hoy,
            onSelected: _vm.cargando
                ? null
                : (_) => _periodoRapido(opciones[i].$2, hoy),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: ContextoNegocio.volverAInventario(context),
      title: const Text('Reportes'),
    ),
    body: SafeArea(
      child: ListenableBuilder(
        listenable: _vm,
        builder: (context, _) => ListView(
          controller: _scroll,
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const CabeceraModulo(
                      titulo: 'Resultados del negocio',
                      descripcion: 'Selecciona el período. Se incluyen ambos días completos, con fechas de Colombia (UTC-5).',
                      icono: Icons.assessment_outlined,
                    ),
                    const SizedBox(height: 20),
                    PanelFinanzas(
                      child: Form(
                        key: _form,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _periodosRapidos(),
                            const SizedBox(height: 16),
                            CampoFecha(
                              identificador: 'desde-reporte',
                              etiqueta: 'Desde',
                              valor: _vm.desde,
                              habilitado: !_vm.cargando,
                              onChanged: (v) => _vm.cambiarFechas(inicio: v),
                            ),
                            const SizedBox(height: 12),
                            CampoFecha(
                              identificador: 'hasta-reporte',
                              etiqueta: 'Hasta',
                              valor: _vm.hasta,
                              habilitado: !_vm.cargando,
                              validator: (_) =>
                                  PeriodoReporte.validar(_vm.desde, _vm.hasta),
                              onChanged: (v) => _vm.cambiarFechas(fin: v),
                            ),
                            const SizedBox(height: 16),
                            FilledButton.icon(
                              key: const ValueKey('consultar-reporte'),
                              onPressed: _vm.cargando ? null : _consultar,
                              icon: const Icon(Icons.assessment_outlined),
                              label: const Text('Consultar reporte'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const GuiaModulo(modulo: ModuloGuia.reportes),
                    const SizedBox(height: 28),
                    if (_vm.cargando)
                      const Center(
                        child: Column(
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 12),
                            Text('Calculando resultados…'),
                          ],
                        ),
                      )
                    else if (_vm.error != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Semantics(
                            liveRegion: true,
                            child: Text(
                              _vm.error!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton(
                            onPressed: _consultar,
                            child: const Text('Reintentar'),
                          ),
                        ],
                      )
                    else if (_vm.reporte != null)
                      PanelFinanzas(child: _resultado(_vm.reporte!))
                    else
                      const Text(
                        'Consulta el reporte para ver el período seleccionado.',
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _resultado(ReporteFinanciero reporte) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        '${FechaNegocio.mostrar(reporte.periodo.desde)} al ${FechaNegocio.mostrar(reporte.periodo.hasta)}',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      if (reporte.sinOperaciones)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Text('No hay operaciones para este período'),
        ),
      const SizedBox(height: 24),
      _seccion('Ventas e ingresos'),
      _dato(
        'Ventas antes de descuentos',
        reporte.ventasCentavos,
        'ventas-brutas',
      ),
      _dato('Descuentos', reporte.descuentosCentavos, 'descuentos'),
      _dato('Ingresos netos', reporte.ingresosNetosCentavos, 'ingresos-netos'),
      const Divider(height: 32),
      _seccion('Compras y gastos'),
      _dato('Compras', reporte.comprasCentavos, 'compras'),
      _dato('Gastos operativos', reporte.gastosCentavos, 'gastos'),
      _dato('Egresos', reporte.egresosCentavos, 'egresos'),
      const Divider(height: 32),
      _seccion('Resultado'),
      _dato('Costo de ventas', reporte.costoVentasCentavos, 'costo-ventas'),
      _dato('Utilidad bruta', reporte.utilidadBrutaCentavos, 'utilidad-bruta'),
      _dato(
        'Utilidad resultante',
        reporte.utilidadResultanteCentavos,
        'utilidad-resultante',
        destacado: true,
      ),
      const SizedBox(height: 20),
      Text(
        '${reporte.numeroVentas} ${reporte.numeroVentas == 1 ? 'venta' : 'ventas'} · ${reporte.numeroCompras} ${reporte.numeroCompras == 1 ? 'compra' : 'compras'} · ${reporte.numeroGastos} ${reporte.numeroGastos == 1 ? 'gasto' : 'gastos'}',
      ),
      const SizedBox(height: 20),
      const Text(
        'La utilidad descuenta el costo histórico de lo vendido y los gastos. Las compras se incluyen en egresos y no se restan de nuevo de la utilidad.',
      ),
      const SizedBox(height: 12),
      const Text(
        'Costo asignado: costo del catálogo al confirmar cada venta. Operaciones al contado, sin impuestos ni devoluciones.',
      ),
    ],
  );

  Widget _seccion(String titulo) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(titulo, style: Theme.of(context).textTheme.titleLarge),
  );
  Widget _dato(
    String etiqueta,
    int valor,
    String id, {
    bool destacado = false,
  }) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            etiqueta,
            style: destacado ? Theme.of(context).textTheme.titleMedium : null,
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            formatearPesos(pesos(valor)),
            key: ValueKey('reporte-$id'),
            textAlign: TextAlign.right,
            style: destacado
                ? Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: valor < 0
                        ? Theme.of(context).colorScheme.error
                        : Theme.of(context).colorScheme.primary,
                  )
                : Theme.of(context).textTheme.titleMedium,
          ),
        ),
      ],
    ),
  );
}
