# language: es
# ID: HU-06
# Épica: Inventario
# MoSCoW: Must
# Puntos: 5
# Propuesta: impedir inventario negativo y conservar fecha, usuario y motivo de cada movimiento.

@HU_06 @Must
Característica: HU-06 · Registrar existencias iniciales y ajustes
  Como administrador, quiero registrar existencias iniciales y ajustes con su motivo
  para mantener el inventario acorde con las cantidades reales.

  @HU_06_CA01
  Escenario: Registrar las existencias iniciales
    Dado que un producto no tiene movimientos de inventario
    Cuando registro 20 unidades iniciales con el motivo Inventario de apertura
    Entonces el producto tiene 20 unidades disponibles
    Y queda registrado el movimiento con su motivo, fecha y usuario responsable

  @HU_06_CA02
  Escenario: Ajustar una diferencia física
    Dado que el sistema registra 20 unidades de un producto
    Y el conteo físico encuentra 18 unidades
    Cuando registro un ajuste de menos 2 unidades con el motivo Diferencia de conteo
    Entonces las existencias quedan en 18 unidades
    Y se conserva el motivo del ajuste

  @HU_06_CA03
  Escenario: Exigir un motivo
    Dado que estoy registrando un ajuste de inventario
    Cuando intento guardarlo sin motivo
    Entonces veo que debo indicar el motivo
    Y las existencias no cambian

  @HU_06_CA04
  Escenario: Evitar existencias negativas
    Dado que un producto tiene 3 unidades
    Cuando intento registrar un ajuste de menos 4 unidades
    Entonces el sistema rechaza el ajuste
    Y mantiene las 3 unidades disponibles
