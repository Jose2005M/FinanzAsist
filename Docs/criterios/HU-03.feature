# language: es
# ID: HU-03
# Épica: Acceso
# MoSCoW: Must
# Puntos: 5
# Propuesta: comprobar permisos también en solicitudes directas y después de su revocación. Definir la matriz de roles.

@HU_03 @Must
Característica: HU-03 · Restringir el acceso a los datos de la empresa
  Como propietario, quiero que únicamente los usuarios autorizados de mi empresa accedan a sus datos
  para proteger la información del negocio.

  @HU_03_CA01
  Escenario: Acceso autorizado
    Dado que mi usuario está autorizado para consultar los datos de mi empresa
    Cuando abro una consulta de productos
    Entonces veo los productos de mi empresa
    Y no veo productos de otras empresas

  @HU_03_CA02
  Escenario: Acceso directo a otra empresa
    Dado que mi usuario pertenece únicamente a la empresa A
    Y conozco el identificador de una venta de la empresa B
    Cuando intento consultar esa venta directamente
    Entonces el sistema deniega el acceso
    Y no revela el contenido de la venta

  @HU_03_CA03
  Escenario: Operación sin permiso
    Dado que mi usuario puede consultar productos pero no modificarlos
    Cuando intento actualizar un producto mediante una solicitud directa
    Entonces el sistema rechaza la operación
    Y el producto conserva sus valores anteriores

  @HU_03_CA04
  Escenario: Autorización revocada
    Dado que tengo una sesión iniciada
    Y se revoca mi autorización para la empresa
    Cuando intento realizar una nueva consulta de sus datos
    Entonces el sistema deniega la consulta
    Y no entrega información de la empresa
