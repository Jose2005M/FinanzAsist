# language: es
# ID: HU-10
# Épica: Gastos
# MoSCoW: Must
# Puntos: 3
# Propuesta: valor mayor que cero; fecha, concepto y categoría obligatorios.

@HU_10 @Must
Característica: HU-10 · Registrar gastos operativos
  Como administrador, quiero registrar gastos con fecha, concepto, categoría y valor
  para controlar los gastos operativos del negocio.

  @HU_10_CA01
  Escenario: Guardar un gasto
    Dado que tengo permiso para registrar gastos
    Cuando ingreso una fecha válida, el concepto Servicio de energía, una categoría y el valor 80000
    Y confirmo el registro
    Entonces el gasto queda asociado a mi empresa
    Y puedo consultar la fecha, el concepto, la categoría y el valor registrados

  @HU_10_CA02
  Escenario: Validar campos obligatorios
    Dado que estoy registrando un gasto
    Cuando intento guardarlo sin fecha, concepto o categoría
    Entonces veo los campos obligatorios pendientes
    Y el gasto no se guarda

  @HU_10_CA03
  Escenario: Rechazar un valor inválido
    Dado que completé los demás datos de un gasto
    Cuando intento guardarlo con un valor igual o menor que cero
    Entonces veo que el valor debe ser mayor que cero
    Y el gasto no se guarda
