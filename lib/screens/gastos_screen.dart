import 'package:flutter/material.dart';

import '../widgets/superficies_finanzasist.dart';
import '../widgets/guia_modulo.dart';
import '../widgets/contexto_negocio.dart';
import '../models/guia_modulo.dart';

import '../data/negocio_repository.dart';
import '../models/fecha_negocio.dart';
import '../models/operacion.dart';
import '../models/permisos.dart';
import '../widgets/permisos_sesion.dart';
import '../utils/formato_moneda.dart';
import '../viewmodels/gastos_view_model.dart';
import 'formulario_gasto_screen.dart';

class GastosScreen extends StatefulWidget {
  const GastosScreen({super.key, required this.repositorio});
  final NegocioRepository repositorio;
  @override
  State<GastosScreen> createState() => _GastosScreenState();
}

class _GastosScreenState extends State<GastosScreen>
    implements ModuloActualizable {
  late final GastosViewModel _vm;
  final _scroll = ScrollController();
  @override
  Future<void> actualizar() => actualizarConDesplazamiento(_scroll, _vm.cargar);
  @override
  void initState() {
    super.initState();
    _vm = GastosViewModel(widget.repositorio);
    _vm.cargar();
  }

  @override
  void dispose() {
    _scroll.dispose();
    _vm.dispose();
    super.dispose();
  }

  Future<void> _nuevo() async {
    final guardado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => FormularioGastoScreen(repositorio: widget.repositorio),
      ),
    );
    if (!mounted || guardado != true) return;
    _vm.cargar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Gasto registrado. Ya está disponible en los reportes.'),
      ),
    );
  }

  Widget? _estado() {
    if (_vm.cargando) return const Center(child: CircularProgressIndicator());
    if (_vm.error != null) {
      return EstadoModulo(
        titulo: _vm.error!,
        descripcion: 'Vuelve a consultar los gastos de tu empresa.',
        icono: Icons.error_outline,
        accion: FilledButton(
          onPressed: _vm.cargar,
          child: const Text('Reintentar'),
        ),
      );
    }
    if (_vm.gastos.isEmpty) {
      return const EstadoModulo(
        titulo: 'Aún no tienes gastos registrados',
        descripcion: 'Registra el primer gasto para incluirlo en los resultados del negocio.',
        icono: Icons.receipt_long_outlined,
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
        title: const Text('Gastos'),
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
                  const CabeceraModulo(
                    titulo: 'Gastos del negocio',
                    descripcion: 'Consulta y registra los gastos operativos de tu empresa.',
                    icono: Icons.receipt_long_outlined,
                  ),
                  const SizedBox(height: 20),
                  if (PermisosSesion.permite(context, Permiso.registrarGastos))
                    FilledButton.icon(
                      key: const ValueKey('nuevo-gasto'),
                      onPressed: _nuevo,
                      icon: const Icon(Icons.add),
                      label: const Text('Registrar gasto'),
                    ),
                  const SizedBox(height: 16),
                  const GuiaModulo(modulo: ModuloGuia.gastos),
                ],
              ),
            ),
            estado: _estado(),
            cantidad: _vm.gastos.length,
            onActualizar: _vm.cargar,
            itemBuilder: (context, i) {
              final gasto = _vm.gastos[i];
              return PanelFinanzas(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      gasto.concepto,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${FechaNegocio.mostrar(gasto.fecha)} · ${gasto.categoria}',
                    ),
                    const SizedBox(height: 8),
                    Text(
                      formatearPesos(pesos(gasto.valorCentavos)),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      'Responsable: ${_vm.responsables[gasto.usuarioId] ?? 'Usuario anterior'}',
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    ),
  );
}
