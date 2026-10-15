# language: es
# ID: HU-15
# Épica: Reportes
# MoSCoW: Should
# Puntos: 5
# Los indicadores usan las definiciones propuestas en HU-14.

@HU_15 @Should
Característica: HU-15 · Visualizar gráficos e indicadores
  Como propietario, quiero visualizar gráficos e indicadores
  para identificar tendencias en ventas, costos, gastos y utilidad.

  @HU_15_CA01
  Escenario: Mostrar indicadores consistentes
    Dado que existen operaciones confirmadas para un período
    Cuando abro el panel de gráficos de ese período
    Entonces veo indicadores de ventas, costos, gastos y utilidad
    Y sus totales coinciden con el reporte financiero del mismo período

  @HU_15_CA02
  Escenario: Cambiar el período
    Dado que estoy visualizando los gráficos de un período
    Cuando selecciono otro período válido
    Entonces se actualizan los gráficos y los indicadores con los datos del nuevo período
    Y se muestra el intervalo consultado

  @HU_15_CA03
  Escenario: Presentar períodos sin datos
    Dado que el período seleccionado no tiene operaciones
    Cuando consulto el panel
    Entonces veo un mensaje de ausencia de datos
    Y no se muestran tendencias inventadas

  @HU_15_CA04
  Escenario: Representar pérdidas
    Dado que en un período los costos y gastos superan los ingresos netos
    Cuando consulto el indicador de utilidad
    Entonces veo el valor negativo correspondiente
    Y la representación permite distinguir la pérdida de una ganancia
