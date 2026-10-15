# language: es
# ID: HU-16
# Épica: Reportes
# MoSCoW: Should
# Puntos: 5
# Propuesta: comparación entre períodos equivalentes; 20 por ciento es un umbral de prueba, no un valor obligatorio del producto.
# Definir umbrales, frecuencia, canal, tratamiento de utilidades negativas y prevención de alertas repetidas.

@HU_16 @Should
Característica: HU-16 · Alertar sobre gastos y utilidad
  Como propietario, quiero recibir alertas sobre aumentos de gastos o disminuciones de utilidad
  para identificar situaciones que requieren revisión.

  @HU_16_CA01
  Escenario: Detectar un aumento de gastos
    Dado que la regla de alerta establece un aumento de gastos de al menos 20 por ciento
    Y el período comparable anterior tiene gastos de 100000
    Y el período evaluado tiene gastos de 125000
    Cuando se evalúan las alertas
    Entonces recibo una alerta de aumento de gastos del 25 por ciento
    Y veo los períodos y valores comparados

  @HU_16_CA02
  Escenario: Detectar una disminución de utilidad
    Dado que la regla de alerta establece una disminución de utilidad de al menos 20 por ciento
    Y la utilidad del período comparable anterior es 200000
    Y la utilidad del período evaluado es 150000
    Cuando se evalúan las alertas
    Entonces recibo una alerta de disminución de utilidad del 25 por ciento
    Y puedo identificar los períodos comparados

  @HU_16_CA03
  Escenario: No alertar por debajo del umbral
    Dado que el umbral de aumento de gastos es 20 por ciento
    Y el aumento calculado es 10 por ciento
    Cuando se evalúan las alertas
    Entonces no se genera una alerta de aumento de gastos

  @HU_16_CA04
  Escenario: Comparación porcentual sin base válida
    Dado que el valor del período anterior es cero o no existen datos comparables
    Cuando se intenta evaluar una variación porcentual
    Entonces se indica que no es posible calcular esa variación
    Y no se presenta un porcentaje inventado
