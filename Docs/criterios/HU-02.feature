# language: es
# ID: HU-02
# Épica: Acceso
# MoSCoW: Must
# Puntos: 3

@HU_02 @Must
Característica: HU-02 · Iniciar y cerrar sesión
  Como usuario registrado, quiero iniciar y cerrar sesión
  para acceder de manera controlada a la aplicación.

  @HU_02_CA01
  Escenario: Inicio de sesión correcto
    Dado que tengo una cuenta activa
    Cuando ingreso mis credenciales correctas
    Entonces accedo a la aplicación
    Y veo la información permitida para mi cuenta

  @HU_02_CA02
  Escenario: Credenciales incorrectas
    Dado que estoy en la pantalla de acceso
    Cuando ingreso credenciales incorrectas
    Entonces veo un mensaje de acceso no válido
    Y permanezco fuera de las funciones protegidas

  @HU_02_CA03
  Escenario: Cerrar sesión
    Dado que tengo una sesión iniciada
    Cuando cierro la sesión
    Y trato de abrir una pantalla protegida
    Entonces la aplicación solicita iniciar sesión nuevamente
    Y no muestra los datos de la sesión cerrada
