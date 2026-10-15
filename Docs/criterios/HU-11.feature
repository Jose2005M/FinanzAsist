# language: es
# ID: HU-11
# Épica: Clasificación
# MoSCoW: Should
# Puntos: 3
# Propuesta: una subcategoría pertenece a una categoría. Definir qué operaciones admiten cada clasificación.

@HU_11 @Should
Característica: HU-11 · Organizar productos y operaciones por categorías
  Como administrador, quiero organizar productos y operaciones por categorías y subcategorías
  para consultar la información con mayor detalle.

  @HU_11_CA01
  Escenario: Crear una jerarquía
    Dado que tengo permiso para administrar clasificaciones
    Cuando creo una categoría Bebidas
    Y creo una subcategoría Jugos dentro de Bebidas
    Entonces la subcategoría Jugos queda asociada a Bebidas
    Y ambas quedan disponibles en mi empresa

  @HU_11_CA02
  Escenario: Clasificar un registro
    Dado que existen la categoría Bebidas y su subcategoría Jugos
    Cuando asigno esa categoría y subcategoría a un producto o una operación compatible
    Entonces el registro conserva ambas clasificaciones
    Y aparece al filtrar por ellas

  @HU_11_CA03
  Escenario: Impedir una combinación incoherente
    Dado que la subcategoría Jugos pertenece a Bebidas
    Cuando intento guardar un registro con Jugos y una categoría diferente
    Entonces el sistema solicita una combinación válida
    Y no guarda la clasificación incoherente

  @HU_11_CA04
  Escenario: Consultar por categoría
    Dado que existen registros en distintas categorías
    Cuando filtro una consulta por Bebidas
    Entonces veo únicamente registros asociados a Bebidas y sus subcategorías
