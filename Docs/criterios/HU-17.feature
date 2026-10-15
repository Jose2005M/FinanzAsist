# language: es
# ID: HU-17
# Épica: Análisis financiero
# MoSCoW: Could
# Puntos: 8
# Pendiente de definición: método, datos mínimos, horizonte permitido e indicadores proyectados.
# Estos criterios describen el comportamiento esperado; las pruebas numéricas requieren concretar el método.

@HU_17 @Could
Característica: HU-17 · Consultar proyecciones financieras
  Como propietario, quiero consultar proyecciones basadas en los datos registrados
  para apoyar la planificación financiera del negocio.

  @HU_17_CA01
  Escenario: Generar una proyección
    Dado que existen datos suficientes según el método de proyección definido
    Cuando selecciono un horizonte permitido
    Y solicito una proyección
    Entonces veo los valores proyectados para ese horizonte
    Y se identifican el período histórico utilizado, el método y sus supuestos
    Y los valores están señalados como estimaciones

  @HU_17_CA02
  Escenario: Datos históricos insuficientes
    Dado que no se cumple el mínimo de datos exigido por el método
    Cuando solicito una proyección
    Entonces veo que no hay información suficiente
    Y se indica qué datos o períodos faltan
    Y no se muestran cifras como si fueran una proyección válida

  @HU_17_CA03
  Escenario: Separar proyecciones de registros reales
    Dado que generé una proyección
    Cuando consulto las ventas, compras y gastos registrados
    Entonces sus valores no han cambiado por generar la proyección

  @HU_17_CA04
  Escenario: Recalcular con nueva información
    Dado que ya consulté una proyección
    Y se registraron nuevas operaciones dentro del período de análisis
    Cuando solicito actualizar la proyección
    Entonces el cálculo incorpora las nuevas operaciones elegibles
    Y muestra la fecha de actualización
