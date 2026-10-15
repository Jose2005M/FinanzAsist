# language: es
# ID: HU-18
# Épica: Análisis financiero
# MoSCoW: Could
# Puntos: 8
# Propuesta: modificar los importes agregados de forma independiente; un aumento de ventas no modifica costos automáticamente.
# Utilidad bruta = ingresos netos - costo de ventas; utilidad resultante = utilidad bruta - gastos.

@HU_18 @Could
Característica: HU-18 · Simular cambios en ventas, costos y gastos
  Como propietario, quiero simular cambios en ventas, costos y gastos
  para explorar su posible efecto sobre la utilidad.

  @HU_18_CA01
  Escenario: Simular un aumento de ventas
    Dado que la base tiene ingresos netos de 1000000, costo de ventas de 600000 y gastos de 200000
    Cuando simulo un aumento del 10 por ciento en los ingresos por ventas
    Y mantengo sin cambios los costos y los gastos
    Entonces veo ingresos simulados de 1100000
    Y veo utilidad bruta simulada de 500000 y utilidad resultante simulada de 300000
    Y veo una mejora de 100000 frente a la utilidad base

  @HU_18_CA02
  Escenario: Simular cambios simultáneos
    Dado que la base tiene ingresos netos de 1000000, costo de ventas de 600000 y gastos de 200000
    Cuando simulo ingresos de 900000, costos de 650000 y gastos de 220000
    Entonces veo utilidad bruta simulada de 250000
    Y veo utilidad resultante simulada de 30000

  @HU_18_CA03
  Escenario: Proteger los datos reales
    Dado que modifiqué valores en una simulación
    Cuando consulto las operaciones reales de la empresa
    Entonces las ventas, costos y gastos registrados conservan sus valores originales

  @HU_18_CA04
  Escenario: Validar entradas
    Dado que estoy configurando una simulación
    Cuando ingreso un valor no numérico o un importe simulado negativo de ingresos, costos o gastos
    Entonces veo qué entrada debo corregir
    Y no se calcula un resultado con esa entrada
