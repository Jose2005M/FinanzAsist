# language: es
# ID: HU-05
# Épica: Inventario
# MoSCoW: Must
# Puntos: 2

@HU_05 @Must
Característica: HU-05 · Consultar las existencias
  Como administrador, quiero consultar las existencias de cada producto
  para conocer las cantidades disponibles para vender.

  @HU_05_CA01
  Escenario: Consultar un producto con existencias
    Dado que un producto tiene 15 unidades disponibles
    Cuando consulto su inventario
    Entonces veo 15 unidades disponibles asociadas al producto correcto

  @HU_05_CA02
  Escenario: Consultar un producto agotado
    Dado que un producto tiene 0 unidades disponibles
    Cuando consulto su inventario
    Entonces veo una cantidad de 0
    Y el producto se identifica como agotado

  @HU_05_CA03
  Escenario: Reflejar una operación confirmada
    Dado que un producto tiene 15 unidades disponibles
    Y se confirma una venta de 4 unidades
    Cuando actualizo la consulta de existencias
    Entonces veo 11 unidades disponibles
