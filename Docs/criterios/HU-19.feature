# language: es
# ID: HU-19
# Épica: Asistente financiero
# MoSCoW: Could
# Puntos: 8
# Propuesta: respuestas respaldadas por datos y limitadas a los permisos del usuario; sin modificaciones mediante el asistente.

@HU_19 @Could
Característica: HU-19 · Consultar los datos mediante un asistente financiero
  Como usuario, quiero consultar los datos mediante un asistente financiero
  para obtener respuestas sobre el desempeño de mi empresa.

  @HU_19_CA01
  Escenario: Responder con datos verificables
    Dado que tengo permiso para consultar reportes
    Y el reporte de un período muestra ingresos netos de 900000
    Cuando pregunto por los ingresos netos de ese período
    Entonces el asistente responde 900000
    Y identifica el período y el indicador utilizado
    Y permite reconocer los registros o el reporte que respaldan la respuesta

  @HU_19_CA02
  Escenario: Aclarar una consulta ambigua
    Dado que no hay un período seleccionado ni establecido en la conversación
    Cuando pregunto cómo estuvo la utilidad
    Entonces el asistente solicita precisar el período
    Y no inventa un intervalo ni una cifra

  @HU_19_CA03
  Escenario: Respetar los permisos
    Dado que mi usuario no tiene acceso a información financiera de otra empresa
    Cuando solicito los ingresos de esa otra empresa
    Entonces el asistente deniega la consulta
    Y no revela sus datos

  @HU_19_CA04
  Escenario: Responder cuando faltan datos
    Dado que no hay operaciones registradas para el período consultado
    Cuando pregunto por el desempeño de ese período
    Entonces el asistente indica la ausencia de datos registrados
    Y no inventa operaciones ni conclusiones sobre el desempeño
