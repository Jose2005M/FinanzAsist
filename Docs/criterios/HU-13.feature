# language: es
# ID: HU-13
# Épica: Clientes y proveedores
# MoSCoW: Should
# Puntos: 3
# Pendiente de definición: campos obligatorios del proveedor y reglas para identificar duplicados.

@HU_13 @Should
Característica: HU-13 · Registrar proveedores y asociar compras
  Como administrador, quiero registrar proveedores y asociarlos con las compras
  para consultar el origen de las adquisiciones.

  @HU_13_CA01
  Escenario: Registrar un proveedor
    Dado que tengo permiso para administrar proveedores
    Cuando ingreso los datos obligatorios válidos de un proveedor
    Y guardo el registro
    Entonces el proveedor aparece en el listado de mi empresa
    Y queda disponible para asociarlo con una compra

  @HU_13_CA02
  Escenario: Asociar una compra
    Dado que existe un proveedor en mi empresa
    Cuando selecciono al proveedor y confirmo una compra válida
    Entonces la compra queda asociada al proveedor
    Y puedo consultar su fecha, productos, cantidades y costos

  @HU_13_CA03
  Escenario: Consultar las compras de un proveedor
    Dado que hay compras asociadas a diferentes proveedores
    Cuando consulto las compras de un proveedor específico
    Entonces veo únicamente las compras asociadas a ese proveedor

  @HU_13_CA04
  Escenario: Evitar asociaciones entre empresas
    Dado que estoy registrando una compra de mi empresa
    Cuando intento asociar un proveedor de otra empresa
    Entonces el sistema rechaza la asociación
    Y no revela los datos del proveedor ajeno
