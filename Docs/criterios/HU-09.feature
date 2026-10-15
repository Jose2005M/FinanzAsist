# language: es
# ID: HU-09
# Épica: Ventas
# MoSCoW: Must
# Puntos: 5
# Pendiente de definición: método de asignación del costo (por ejemplo, promedio ponderado o FIFO). Los escenarios parten de un costo ya asignado.

@HU_09 @Must
Característica: HU-09 · Conservar el precio y costo históricos de las ventas
  Como propietario, quiero conservar el precio cobrado y el costo asignado en cada venta
  para mantener consistentes los reportes históricos.

  @HU_09_CA01
  Escenario: Guardar los valores históricos
    Dado que el costo asignado por unidad para una venta es 6000
    Cuando confirmo la venta de 2 unidades a 10000 cada una con descuento total de 2000
    Entonces el detalle conserva el precio unitario de 10000 y el descuento de 2000
    Y conserva el costo unitario asignado de 6000
    Y la venta tiene ingreso neto de 18000 y costo total de 12000

  @HU_09_CA02
  Escenario: Cambiar el catálogo después de vender
    Dado que una venta confirmada conserva precio unitario de 10000 y costo unitario de 6000
    Cuando actualizo el precio del catálogo a 12000 y el costo a 7000
    Entonces la venta anterior conserva el precio de 10000 y el costo de 6000
    Y sus totales históricos no se recalculan con los valores nuevos

  @HU_09_CA03
  Escenario: Calcular reportes con valores históricos
    Dado que una venta tiene ingreso neto de 18000 y costo histórico total de 12000
    Y el costo actual del catálogo es diferente
    Cuando consulto la utilidad bruta de esa venta
    Entonces veo una utilidad bruta de 6000
