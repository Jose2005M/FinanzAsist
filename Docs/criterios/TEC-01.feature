# language: es
# ID: TEC-01
# Épica: Base
# MoSCoW: Must
# Puntos: 2
# Pendiente de definición: plataformas móviles objetivo, convención de ramas y reglas de integración.

@TEC_01 @Must
Característica: TEC-01 · Preparar el proyecto móvil y el repositorio
  Como equipo de desarrollo, queremos disponer de un proyecto móvil multiplataforma y un repositorio organizado
  para desarrollar la aplicación con control de versiones.

  @TEC_01_CA01
  Escenario: Ejecutar el proyecto en las plataformas objetivo
    Dado que el entorno cumple los requisitos documentados
    Y el repositorio contiene el proyecto móvil
    Cuando obtengo el proyecto e instalo sus dependencias
    Y ejecuto la aplicación en cada plataforma móvil objetivo
    Entonces la aplicación inicia sin errores en cada plataforma
    Y se muestra la pantalla inicial

  @TEC_01_CA02
  Escenario: Trabajar mediante ramas
    Dado que el repositorio tiene una rama principal
    Y existe una convención documentada para las ramas de trabajo
    Cuando creo una rama siguiendo esa convención
    Y publico un cambio en ella
    Entonces el cambio queda disponible en la rama de trabajo
    Y la rama principal permanece sin modificaciones

  @TEC_01_CA03
  Escenario: Proteger la rama principal
    Dado que la rama principal tiene activadas las reglas de protección
    Y mi usuario no tiene permisos de excepción
    Cuando intento enviar cambios directamente a la rama principal
    Entonces el repositorio rechaza el envío
    Y indica que debo utilizar el proceso de integración configurado
