enum ModuloGuia {
  inventario,
  compras,
  ventas,
  gastos,
  reportes;

  String get nombre => switch (this) {
    inventario => 'Inventario',
    compras => 'Compras',
    ventas => 'Ventas',
    gastos => 'Gastos',
    reportes => 'Reportes',
  };

  String get proposito => switch (this) {
    inventario => 'Consulta tus productos y las unidades disponibles.',
    compras =>
      'Registra la mercancía que entra al negocio y consulta tus compras.',
    ventas =>
      'Anota lo que vendes para descontar existencias y conocer tus ingresos.',
    gastos => 'Registra pagos del negocio, como arriendo y servicios. La mercancía se registra en Compras.',
    reportes => 'Consulta ingresos, compras, gastos y utilidad de un período.',
  };

  String get inicio => switch (this) {
    inventario => 'Empieza registrando un producto. Abre su detalle para anotar las unidades que ya tienes.',
    compras => 'Primero crea el producto en Inventario. Después registra la cantidad y el costo de la compra.',
    ventas => 'Selecciona un producto con existencias, indica cuántas unidades vendes y revisa el total.',
    gastos => 'Elige la fecha, el concepto, la categoría y el valor del pago.',
    reportes =>
      'Elige un período rápido o indica las fechas que quieres consultar.',
  };

  List<String> get pasos => switch (this) {
    inventario => const [
      'Registra nombre, costo de compra y precio de venta. El producto empieza con cero unidades.',
      'Abre el producto y usa Registrar existencias iniciales para indicar las unidades que ya tienes.',
      'Las compras suman unidades y las ventas las descuentan. Usa Ajustar existencias para corregir un conteo, indicando el motivo.',
    ],
    compras => const [
      'Pulsa Registrar compra y selecciona uno o varios productos del inventario.',
      'Indica cuántas unidades entran y cuánto cuesta cada una. Revisa el resumen antes de confirmar.',
      'Al confirmar aumentan las existencias. La compra queda en este historial y en los egresos del reporte.',
    ],
    ventas => const [
      'Pulsa Registrar venta y selecciona productos con unidades disponibles.',
      'Indica cantidad y precio por unidad. Si aplica, escribe el descuento total en pesos y revisa el resumen.',
      'Al confirmar se descuentan las unidades. La venta queda en este historial y en los ingresos del reporte.',
    ],
    gastos => const [
      'Pulsa Registrar gasto para anotar un pago operativo, como un servicio o un arriendo.',
      'Selecciona el día del gasto, escribe el concepto, elige la categoría e indica el valor en pesos.',
      'Guarda el registro. El gasto se incluye en los reportes del día elegido y no cambia el inventario.',
    ],
    reportes => const [
      'Usa Hoy, Últimos 7 días o Este mes, o elige Desde y Hasta y pulsa Consultar reporte.',
      'Revisa ventas e ingresos, compras y gastos, y el resultado. Las dos fechas se incluyen completas.',
      'La utilidad descuenta el costo de los productos vendidos y los gastos. Las compras aparecen en egresos y no se restan otra vez de la utilidad.',
    ],
  };
}
