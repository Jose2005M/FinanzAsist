# language: es
# ID: HU-08
# Épica: Ventas
# MoSCoW: Must
# Puntos: 8
# Propuesta: descuento como importe total entre cero y el subtotal; impedir ventas sin existencias. Los ejemplos no incluyen impuestos.

@HU_08 @Must
Característica: HU-08 · Registrar ventas y actualizar el inventario
  Como responsable de ventas, quiero registrar productos, cantidades, precios cobrados y descuentos
  para calcular el total y actualizar el inventario.

  @HU_08_CA01
  Escenario: Calcular una venta con descuento
    Dado que un producto tiene 10 unidades disponibles
    Cuando registro 2 unidades a 10000 cada una
    Y aplico un descuento total de 2000
    Y confirmo la venta
    Entonces se guarda un subtotal de 20000, un descuento de 2000 y un total de 18000
    Y quedan 8 unidades disponibles
    Y se conservan los precios cobrados

  @HU_08_CA02
  Escenario: Impedir una venta sin existencias suficientes
    Dado que un producto tiene 3 unidades disponibles
    Cuando intento confirmar una venta de 4 unidades
    Entonces veo que no hay existencias suficientes
    Y no se confirma la venta
    Y se mantienen las 3 unidades

  @HU_08_CA03
  Escenario: Validar cantidades, precios y descuentos
    Dado que estoy registrando una venta
    Cuando intento confirmarla con cantidad no positiva, precio negativo o descuento fuera del intervalo entre cero y el subtotal
    Entonces veo los valores que debo corregir
    Y la venta no se confirma
    Y el inventario no cambia

  @HU_08_CA04
  Escenario: Comprobar existencias al confirmar
    Dado que dos usuarios preparan una venta de la última unidad del mismo producto
    Cuando ambos intentan confirmar sus ventas
    Entonces solo una venta se confirma
    Y el otro usuario recibe un aviso de existencias insuficientes
    Y las existencias quedan en 0

  @HU_08_CA05
  Escenario: Cancelar antes de confirmar
    Dado que preparé una venta con productos y descuentos
    Cuando cancelo la venta antes de confirmarla
    Entonces no queda una venta confirmada
    Y no se descuentan unidades del inventario
