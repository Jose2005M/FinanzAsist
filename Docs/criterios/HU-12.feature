# language: es
# ID: HU-12
# Épica: Clientes y proveedores
# MoSCoW: Should
# Puntos: 3
# Pendiente de definición: campos obligatorios del cliente y reglas para identificar duplicados.

@HU_12 @Should
Característica: HU-12 · Registrar clientes y consultar sus compras
  Como administrador, quiero registrar clientes y asociarlos con las ventas
  para consultar su historial de compras.

  @HU_12_CA01
  Escenario: Registrar un cliente
    Dado que tengo permiso para administrar clientes
    Cuando ingreso los datos obligatorios válidos de un cliente
    Y guardo el registro
    Entonces el cliente aparece en el listado de mi empresa
    Y queda disponible para asociarlo con una venta

  @HU_12_CA02
  Escenario: Asociar una venta
    Dado que existe un cliente en mi empresa
    Cuando selecciono al cliente y confirmo una venta válida
    Entonces la venta queda asociada al cliente
    Y aparece en su historial con fecha, detalle y total

  @HU_12_CA03
  Escenario: Consultar un historial vacío
    Dado que un cliente no tiene ventas asociadas
    Cuando consulto su historial
    Entonces veo que todavía no tiene compras registradas

  @HU_12_CA04
  Escenario: Evitar asociaciones entre empresas
    Dado que estoy registrando una venta de mi empresa
    Cuando intento asociar un cliente de otra empresa
    Entonces el sistema rechaza la asociación
    Y no revela los datos del cliente ajeno
