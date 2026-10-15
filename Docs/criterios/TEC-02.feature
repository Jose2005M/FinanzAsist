# language: es
# ID: TEC-02
# Épica: Base
# MoSCoW: Must
# Puntos: 8

@TEC_02 @Must
Característica: TEC-02 · Almacenar los datos con separación por empresa
  Como equipo de desarrollo, queremos almacenar empresas, usuarios, productos, compras, ventas y gastos
  para conservar la información y mantener separados los datos de cada empresa.

  @TEC_02_CA01
  Escenario: Conservar los registros
    Dado que existe una empresa con un usuario autorizado
    Cuando guardo un producto, una compra, una venta y un gasto válidos de esa empresa
    Y inicio una nueva sesión de consulta
    Entonces recupero los registros con los valores guardados
    Y cada registro conserva su asociación con la empresa

  @TEC_02_CA02
  Escenario: Impedir relaciones entre empresas
    Dado que existe un producto de la empresa B
    Y estoy registrando una compra de la empresa A
    Cuando intento incluir el producto de la empresa B
    Entonces el sistema rechaza la relación
    Y no guarda la compra

  @TEC_02_CA03
  Escenario: Evitar registros parciales
    Dado que una compra válida debe guardar su detalle y actualizar las existencias
    Cuando ocurre un error antes de completar la transacción
    Entonces no queda una compra confirmada parcialmente
    Y las existencias conservan los valores anteriores

  @TEC_02_CA04
  Escenario: Aislar las consultas
    Dado que las empresas A y B tienen registros almacenados
    Cuando consulto los datos con un usuario autorizado únicamente para la empresa A
    Entonces recibo únicamente los registros de la empresa A
    Y no recibo datos de la empresa B
