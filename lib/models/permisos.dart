/// Acciones protegidas dentro de una empresa (HU-03). Consultar el inventario
/// y los precios de venta está permitido a todos los roles.
enum Permiso {
  verCostos,
  gestionarProductos,
  gestionarExistencias,
  registrarCompras,
  verCompras,
  registrarVentas,
  verVentasPropias,
  verTodasLasVentas,
  registrarGastos,
  verGastos,
  verReportes,
  gestionarUsuarios,
  gestionarRespaldos,
}

/// Rol de una cuenta dentro de su empresa. Cada empresa tiene un propietario.
enum RolCuenta {
  propietario('Propietario'),
  encargado('Encargado de inventario'),
  vendedor('Vendedor'),
  consulta('Consulta');

  const RolCuenta(this.etiqueta);
  final String etiqueta;

  /// Roles que el propietario puede asignar a sus empleados.
  static const empleados = [encargado, vendedor, consulta];

  static const _lectura = {
    Permiso.verCostos,
    Permiso.verCompras,
    Permiso.verTodasLasVentas,
    Permiso.verVentasPropias,
    Permiso.verGastos,
    Permiso.verReportes,
  };

  Set<Permiso> get permisos => switch (this) {
    propietario => Permiso.values.toSet(),
    encargado => {
      ..._lectura,
      Permiso.gestionarProductos,
      Permiso.gestionarExistencias,
      Permiso.registrarCompras,
    },
    vendedor => {Permiso.registrarVentas, Permiso.verVentasPropias},
    consulta => _lectura,
  };

  bool permite(Permiso permiso) => permisos.contains(permiso);

  /// Breve descripción para elegir el rol al crear un usuario.
  String get descripcion => switch (this) {
    propietario => 'Puede todo: usuarios, gastos y respaldos.',
    encargado =>
      'Ve todo; registra productos, existencias y compras. No vende ni '
          'registra gastos.',
    vendedor =>
      'Ve el inventario y los precios de venta; registra ventas y ve solo '
          'las suyas.',
    consulta =>
      'Ve inventario, historiales, gastos y reportes. No registra nada.',
  };
}
