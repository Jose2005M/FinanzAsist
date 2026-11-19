import 'package:flutter/widgets.dart';

import '../models/permisos.dart';

/// Permisos de la cuenta para todos los navegadores privados.
/// La demostración y los árboles sin sesión conservan todas las acciones.
class PermisosSesion extends InheritedWidget {
  const PermisosSesion({super.key, required this.rol, required super.child});
  final RolCuenta rol;

  static RolCuenta? rolDe(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PermisosSesion>()?.rol;

  static bool permite(BuildContext context, Permiso permiso) =>
      rolDe(context)?.permite(permiso) ?? true;

  @override
  bool updateShouldNotify(PermisosSesion oldWidget) => rol != oldWidget.rol;
}
