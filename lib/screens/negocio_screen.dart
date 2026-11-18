import 'package:flutter/material.dart';

import '../data/negocio_repository.dart';
import '../models/operacion.dart';
import '../widgets/contexto_negocio.dart';
import 'gastos_screen.dart';
import 'inventario_screen.dart';
import 'operaciones_screen.dart';
import 'reportes_screen.dart';

/// Mantiene un navegador por módulo: consultas y borradores sobreviven al cambio.
class NegocioScreen extends StatefulWidget {
  const NegocioScreen({
    super.key,
    required this.repositorio,
    this.empresa,
    this.correo,
    this.cerrarSesion,
  });
  final NegocioRepository repositorio;
  final String? empresa;
  final String? correo;
  final VoidCallback? cerrarSesion;

  @override
  State<NegocioScreen> createState() => _NegocioScreenState();
}

class _NegocioScreenState extends State<NegocioScreen> {
  final _navegadores = List.generate(5, (_) => GlobalKey<NavigatorState>());
  final _pantallas = List.generate(5, (_) => GlobalKey());
  final _creados = [true, false, false, false, false];
  final _versiones = List.filled(5, 0);
  int _seleccion = 0;
  int _revision = 0;
  late final _control = ControlNavegacionNegocio(
    seleccionar: _seleccionar,
    notificarCambio: _notificarCambio,
  );
  static const _nombres = [
    'Inventario',
    'Compras',
    'Ventas',
    'Gastos',
    'Reportes',
  ];

  void _seleccionar(int modulo) {
    if (!mounted || modulo == _seleccion) return;
    if (_control.guardando) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Espera a que termine el guardado para cambiar de módulo.',
          ),
        ),
      );
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    final nuevo = !_creados[modulo];
    setState(() {
      _seleccion = modulo;
      _creados[modulo] = true;
      if (nuevo) _versiones[modulo] = _revision;
    });
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _actualizarSiPendiente(modulo),
    );
  }

  void _notificarCambio(int origen) {
    _revision++;
    // El módulo que guardó ya actualiza su propio historial al volver.
    _versiones[origen] = _revision;
    if (_seleccion != origen) _actualizarSiPendiente(_seleccion);
  }

  Future<void> _actualizarSiPendiente(int modulo) async {
    if (!mounted || _versiones[modulo] == _revision) return;
    final pantalla = _pantallas[modulo].currentState;
    if (pantalla is ModuloActualizable) {
      _versiones[modulo] = _revision;
      await (pantalla as ModuloActualizable).actualizar();
      await _control.actualizarVistas(modulo);
    }
  }

  Widget _pagina(int modulo) => switch (modulo) {
    0 => InventarioScreen(
      key: _pantallas[0],
      repositorio: widget.repositorio,
      empresa: widget.empresa,
      correo: widget.correo,
      cerrarSesion: widget.cerrarSesion,
    ),
    1 || 2 => OperacionesScreen(
      key: _pantallas[modulo],
      repositorio: widget.repositorio,
      tipo: modulo == 1 ? TipoOperacion.compra : TipoOperacion.venta,
    ),
    3 => GastosScreen(key: _pantallas[3], repositorio: widget.repositorio),
    _ => ReportesScreen(key: _pantallas[4], repositorio: widget.repositorio),
  };

  Widget _barra(BuildContext context) {
    final grande = MediaQuery.textScalerOf(context).scale(12) > 16;
    final barra = NavigationBar(
      selectedIndex: _seleccion,
      onDestinationSelected: _seleccionar,
      height: grande ? 72 : 80,
      labelBehavior: grande
          ? NavigationDestinationLabelBehavior.alwaysHide
          : NavigationDestinationLabelBehavior.alwaysShow,
      destinations: const [
        NavigationDestination(
          key: ValueKey('modulo-inventario'),
          icon: Icon(Icons.inventory_2_outlined),
          label: 'Inventario',
        ),
        NavigationDestination(
          key: ValueKey('modulo-compras'),
          icon: Icon(Icons.shopping_bag_outlined),
          label: 'Compras',
        ),
        NavigationDestination(
          key: ValueKey('modulo-ventas'),
          icon: Icon(Icons.point_of_sale),
          label: 'Ventas',
        ),
        NavigationDestination(
          key: ValueKey('modulo-gastos'),
          icon: Icon(Icons.receipt_long_outlined),
          label: 'Gastos',
        ),
        NavigationDestination(
          key: ValueKey('modulo-reportes'),
          icon: Icon(Icons.assessment_outlined),
          label: 'Reportes',
        ),
      ],
    );
    if (!grande) return barra;
    return Material(
      color: Theme.of(context).navigationBarTheme.backgroundColor,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: ExcludeSemantics(
              child: Text(
                _nombres[_seleccion],
                key: const ValueKey('modulo-actual-navegacion'),
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
          ),
          barra,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => PopScope<Object?>(
    canPop: _seleccion == 0,
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop &&
          !(_navegadores[_seleccion].currentState?.canPop() ?? false)) {
        _seleccionar(0);
      }
    },
    child: Scaffold(
      bottomNavigationBar: _barra(context),
      body: MediaQuery.removeViewInsets(
        context: context,
        removeBottom: true,
        child: IndexedStack(
          index: _seleccion,
          children: [
            for (var i = 0; i < 5; i++)
              if (!_creados[i])
                const SizedBox.shrink()
              else
                ContextoNegocio(
                  control: _control,
                  modulo: i,
                  child: NavigatorPopHandler<Object?>(
                    enabled: _seleccion == i,
                    onPopWithResult: (_) =>
                        _navegadores[i].currentState!.maybePop(),
                    child: Navigator(
                      key: _navegadores[i],
                      onGenerateRoute: (_) =>
                          MaterialPageRoute<void>(builder: (_) => _pagina(i)),
                    ),
                  ),
                ),
          ],
        ),
      ),
    ),
  );
}
