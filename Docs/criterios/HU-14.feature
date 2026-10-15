# language: es
# ID: HU-14
# Épica: Reportes
# MoSCoW: Must
# Puntos: 8
# Propuesta para estos escenarios: operaciones al contado, sin impuestos, devoluciones ni otros movimientos.
# Ingresos netos = ventas antes de descuentos - descuentos.
# Egresos = compras + gastos operativos; costo de ventas = costo histórico de las unidades vendidas.
# Utilidad bruta = ingresos netos - costo de ventas.
# Utilidad resultante = utilidad bruta - gastos operativos. Las compras no se restan otra vez de la utilidad.
# Definir tratamiento de crédito, impuestos, devoluciones, zona horaria y redondeo antes de implementar.

@HU_14 @Must
Característica: HU-14 · Consultar el desempeño financiero por período
  Como propietario, quiero consultar ventas, ingresos, egresos, costos, utilidad bruta, gastos y utilidad resultante por período
  para evaluar el desempeño financiero.

  @HU_14_CA01
  Escenario: Calcular los indicadores del período
    Dado que en el período hay ventas confirmadas por 1000000 antes de descuentos
    Y los descuentos suman 100000
    Y el costo histórico de los productos vendidos suma 500000
    Y las compras confirmadas suman 600000
    Y los gastos operativos suman 150000
    Cuando consulto el reporte del período
    Entonces veo ventas antes de descuentos por 1000000 e ingresos netos por 900000
    Y veo egresos por 750000 y costo de ventas por 500000
    Y veo utilidad bruta por 400000 y gastos por 150000
    Y veo utilidad resultante por 250000

  @HU_14_CA02
  Escenario: Aplicar los límites del período
    Dado que existen operaciones anteriores, interiores y posteriores al período solicitado
    Cuando consulto un período con fecha inicial y final válidas
    Entonces el reporte incluye las operaciones desde el inicio del primer día hasta el final del último día según la zona horaria de la empresa
    Y excluye las operaciones fuera de ese intervalo

  @HU_14_CA03
  Escenario: Período sin operaciones
    Dado que no existen operaciones confirmadas en el período seleccionado
    Cuando consulto el reporte
    Entonces los totales aparecen en cero
    Y veo que no hay operaciones para ese período

  @HU_14_CA04
  Escenario: Rechazar un intervalo inválido
    Dado que estoy seleccionando el período
    Cuando ingreso una fecha inicial posterior a la fecha final
    Entonces veo que debo corregir el intervalo
    Y no se genera un reporte con esas fechas
