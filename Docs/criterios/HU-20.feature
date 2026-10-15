# language: es
# ID: HU-20
# Épica: Sincronización
# MoSCoW: Could
# Puntos: 8
# Pendiente de definición: operaciones habilitadas sin conexión y mecanismo de resolución de conflictos.
# Propuesta: mantener estados pendiente, sincronizada y conflicto; validar permisos y existencias en el servidor.

@HU_20 @Could
Característica: HU-20 · Registrar operaciones sin conexión y sincronizarlas
  Como usuario, quiero registrar determinadas operaciones sin conexión y sincronizarlas al recuperar internet
  para continuar trabajando durante interrupciones de conectividad.

  @HU_20_CA01
  Escenario: Guardar una operación admitida sin conexión
    Dado que inicié sesión previamente
    Y la operación que voy a registrar está habilitada para uso sin conexión
    Y no tengo acceso a internet
    Cuando completo los datos válidos y guardo la operación
    Entonces la operación queda almacenada localmente
    Y aparece como pendiente de sincronización
    Y no se presenta como confirmada en el servidor

  @HU_20_CA02
  Escenario: Sincronizar al recuperar internet
    Dado que tengo una operación pendiente sin conflictos
    Y mi sesión y permisos siguen siendo válidos
    Cuando se recupera la conexión
    Y se ejecuta la sincronización
    Entonces la operación se registra una sola vez en el servidor
    Y su estado cambia a sincronizada

  @HU_20_CA03
  Escenario: Reintentar sin duplicar
    Dado que el servidor recibió una operación
    Y la conexión se interrumpió antes de recibir la confirmación
    Cuando la aplicación reintenta el envío con el mismo identificador
    Entonces el servidor reconoce la operación ya registrada
    Y no duplica sus importes ni sus movimientos de inventario

  @HU_20_CA04
  Escenario: Resolver un conflicto de existencias
    Dado que tengo pendiente una venta registrada sin conexión
    Y al sincronizar el servidor no tiene existencias suficientes
    Cuando se intenta sincronizar la venta
    Entonces la venta queda marcada con un conflicto que requiere revisión
    Y no se confirma ni produce existencias negativas en el servidor
    Y se conservan sus datos locales

  @HU_20_CA05
  Escenario: Impedir una operación no habilitada
    Dado que no tengo conexión
    Y la operación solicitada requiere conexión
    Cuando intento realizarla
    Entonces veo que necesito conectarme para continuar
    Y no se muestra como una operación completada

  @HU_20_CA06
  Escenario: Conservar pendientes al cerrar la aplicación
    Dado que guardé una operación pendiente de sincronización
    Cuando cierro y vuelvo a abrir la aplicación sin conexión
    Entonces la operación continúa disponible con sus datos
    Y mantiene su estado pendiente
