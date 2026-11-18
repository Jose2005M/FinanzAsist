import 'package:flutter/material.dart';

abstract interface class ModuloActualizable {
  Future<void> actualizar();
}

class ControlNavegacionNegocio {
  ControlNavegacionNegocio({
    required this.seleccionar,
    required this.notificarCambio,
  });
  final ValueChanged<int> seleccionar;
  final ValueChanged<int> notificarCambio;
  final Map<Object, bool Function()> _tareas = {};
  final Map<Object, ({int modulo, Future<void> Function() actualizar})>
  _vistas = {};

  bool get guardando => _tareas.values.any((consultar) => consultar());
  void registrarTarea(Object id, bool Function() guardando) =>
      _tareas[id] = guardando;
  void retirarTarea(Object id) => _tareas.remove(id);
  void registrarVista(
    Object id,
    int modulo,
    Future<void> Function() actualizar,
  ) => _vistas[id] = (modulo: modulo, actualizar: actualizar);
  void retirarVista(Object id) => _vistas.remove(id);

  Future<void> actualizarVistas(int modulo) async {
    final pendientes = _vistas.values
        .where((vista) => vista.modulo == modulo)
        .toList();
    for (final vista in pendientes) {
      await vista.actualizar();
    }
  }
}

class ContextoNegocio extends InheritedWidget {
  const ContextoNegocio({
    super.key,
    required this.control,
    required this.modulo,
    required super.child,
  });
  final ControlNavegacionNegocio control;
  final int modulo;

  static ContextoNegocio? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ContextoNegocio>();

  static void avisarCambio(BuildContext context) {
    final alcance = of(context);
    alcance?.control.notificarCambio(alcance.modulo);
  }

  static Widget? volverAInventario(BuildContext context) {
    final alcance = of(context);
    return alcance == null
        ? null
        : BackButton(onPressed: () => alcance.control.seleccionar(0));
  }

  @override
  bool updateShouldNotify(ContextoNegocio oldWidget) =>
      control != oldWidget.control || modulo != oldWidget.modulo;
}

Future<void> actualizarConDesplazamiento(
  ScrollController scroll,
  Future<void> Function() accion,
) async {
  final anterior = scroll.hasClients ? scroll.offset : null;
  await accion();
  if (anterior == null) return;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (scroll.hasClients) {
      scroll.jumpTo(anterior.clamp(0, scroll.position.maxScrollExtent));
    }
  });
}
