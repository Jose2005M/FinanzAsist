# language: es
# ID: HU-04
# Épica: Inventario
# MoSCoW: Must
# Puntos: 3
# Propuesta: nombre obligatorio; costo y precio no negativos. La tabla no define otros campos ni reglas de duplicidad.

@HU_04 @Must
Característica: HU-04 · Registrar y actualizar productos
  Como administrador, quiero registrar y actualizar productos con costo de compra y precio de venta
  para mantener organizado el catálogo.

  @HU_04_CA01
  Escenario: Registrar un producto
    Dado que tengo permiso para administrar el catálogo
    Cuando registro un producto con nombre, costo de compra de 6000 y precio de venta de 10000
    Entonces el producto aparece en el catálogo de mi empresa
    Y muestra el costo de 6000 y el precio de 10000

  @HU_04_CA02
  Escenario: Actualizar un producto
    Dado que existe un producto en mi empresa
    Cuando modifico su costo de compra y su precio de venta con valores válidos
    Y guardo los cambios
    Entonces el catálogo muestra los nuevos valores
    Y el producto conserva su identificador

  @HU_04_CA03
  Escenario: Rechazar valores inválidos
    Dado que estoy registrando un producto
    Cuando intento guardarlo sin nombre o con un costo o precio negativo
    Entonces veo los campos que debo corregir
    Y no se guarda el producto
