# language: es
# ID: HU-07
# Épica: Compras
# MoSCoW: Must
# Puntos: 5
# Propuesta: cantidades positivas, costos no negativos y confirmación sin duplicados.

@HU_07 @Must
Característica: HU-07 · Registrar compras
  Como administrador, quiero registrar compras con productos, cantidades y costos
  para aumentar las existencias y controlar las adquisiciones.

  @HU_07_CA01
  Escenario: Confirmar una compra
    Dado que un producto tiene 10 unidades disponibles
    Cuando registro y confirmo la compra de 5 unidades con costo unitario de 6000
    Entonces se guarda una compra por 30000
    Y el inventario del producto aumenta a 15 unidades
    Y se conserva el detalle de cantidad y costo

  @HU_07_CA02
  Escenario: Rechazar un detalle inválido
    Dado que estoy registrando una compra
    Cuando intento confirmar una línea sin producto, con cantidad no positiva o con costo negativo
    Entonces veo el dato que debo corregir
    Y no se confirma la compra
    Y el inventario no cambia

  @HU_07_CA03
  Escenario: Cancelar una compra sin confirmar
    Dado que agregué productos a una compra sin confirmarla
    Cuando cancelo el registro
    Entonces no se guarda una compra confirmada
    Y las existencias conservan sus valores anteriores

  @HU_07_CA04
  Escenario: Evitar duplicados al reintentar
    Dado que una compra ya fue confirmada con un identificador de operación
    Cuando reenvío la confirmación con el mismo identificador
    Entonces se reconoce la compra existente
    Y el inventario no vuelve a incrementarse
