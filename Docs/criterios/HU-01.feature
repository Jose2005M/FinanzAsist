# language: es
# ID: HU-01
# Épica: Acceso
# MoSCoW: Must
# Puntos: 3
# Implementación local: empresa, nombre del propietario, correo y contraseña obligatorios.
# El correo es único en este dispositivo y se compara sin espacios exteriores ni mayúsculas.
# Contraseña de 8 a 128 caracteres, sin reglas de composición y con confirmación en pantalla.
# El registro inicia sesión; la primera cuenta vincula el negocio local anterior, si existe.
# Pendiente: validación del equipo para servicio remoto y recuperación de cuentas.

@HU_01 @Must
Característica: HU-01 · Registrar la cuenta y la empresa
  Como propietario, quiero registrar mi cuenta y mi empresa
  para comenzar a gestionar la información del negocio.

  @HU_01_CA01
  Escenario: Registro correcto
    Dado que no tengo una cuenta registrada
    Cuando ingreso los datos obligatorios válidos de mi cuenta y de mi empresa
    Y confirmo el registro
    Entonces se crean mi cuenta y mi empresa
    Y mi cuenta queda asociada como propietaria de la empresa

  @HU_01_CA02
  Escenario: Datos obligatorios incompletos
    Dado que estoy completando el registro
    Cuando intento continuar sin completar un dato obligatorio
    Entonces veo cuál dato falta
    Y no se completa el registro
    Y se conservan los demás datos ingresados

  @HU_01_CA03
  Escenario: Cuenta existente
    Dado que ya existe una cuenta con el identificador de acceso ingresado
    Cuando intento registrar otra cuenta con ese identificador
    Entonces el sistema impide crear la cuenta duplicada
    Y muestra una indicación para acceder con una cuenta existente

  @HU_01_CA04
  Escenario: Fallo durante el registro
    Dado que ingresé los datos válidos de mi cuenta y mi empresa
    Cuando ocurre un error al confirmar el registro
    Entonces veo que el registro no se completó
    Y no queda una empresa creada sin su propietario asociado
