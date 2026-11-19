# Examen práctico · Sprint 1 · FinanzAsist · Flutter + Dart

Continuación de desarrollo: los costos históricos de HU-09, gastos de HU-10 y reportes de HU-14 se documentan en [validacion-finanzas.md](validacion-finanzas.md). Las cifras de pruebas de este documento conservan el corte original de Sprint 1.

**Equipo y proyecto:** Los Juanchos · FinanzAsist · Ingeniería Informática, UNIPAZ.

- **Product Owner:** Jose Manuel Torres Neira.
- **Scrum Master / facilitador propuesto para Sprint 1:** Juan Esteban Antolinez.
- **Líder de UX/UI y desarrollo:** Victor Hugo Gomez Echeverri.
- **Responsable de pruebas:** Juan David Ramos (Juancho).
- **Documentación:** Juan Esteban Antolinez.
- **Tecnología:** Flutter + Dart; Android como plataforma inicial.
- **Ruta de entrega:** `docs/examen-sprint1.md`.
- **Historia técnica:** HU-05 — Consultar las existencias disponibles de cada producto.
- **Historias seleccionadas:** HU-04, HU-05, HU-06, HU-07 y HU-08; todas con prioridad Must.

Este documento presenta los requisitos y la planificación de la prueba técnica de FinanzAsist, aplicación móvil para pequeñas y medianas empresas que comercializan productos. La funcionalidad se centra en productos, existencias, compras y ventas. Los resultados de validación se completarán con evidencias del desarrollo y de las pruebas.

| Código | Historia seleccionada | Puntos |
| --- | --- | ---: |
| HU-04 | Registrar y actualizar productos, costos de compra y precios de venta. | 3 |
| HU-05 | Consultar las existencias disponibles de cada producto. | 2 |
| HU-06 | Registrar existencias iniciales y ajustes con su motivo. | 5 |
| HU-07 | Registrar compras y aumentar las existencias. | 5 |
| HU-08 | Registrar ventas, calcular totales y descuentos, y disminuir las existencias. | 8 |
| **Total seleccionado** | **5 historias Must.** | **23** |

Las cinco historias cubren el recorrido de preparar el inventario, registrar la entrada de mercancía, realizar ventas y consultar las existencias. HU-05 conserva el papel de historia técnica para comenzar la lista y el detalle del inventario.

## 1. Persona y mapa de hoy

### Proto-persona

Martha Rodríguez representa a una propietaria de una pequeña tienda que comercializa productos. Su nombre, su situación y la frase presentada son supuestos de trabajo **por validar** con una persona real del público objetivo. No corresponden a una entrevista realizada.

| Campo | Descripción | Decisión que orienta en FinanzAsist |
| --- | --- | --- |
| **Contexto** | Martha atiende su tienda y se encarga de organizar productos, recibir mercancía, vender y revisar las cuentas. Alterna estas actividades durante la jornada y dispone de poco tiempo para anotar cada operación. **Por validar.** | Conectar el catálogo y las existencias con el registro de compras y ventas, usando formularios breves y un resumen de la operación antes de confirmarla. |
| **Teléfono y conexión** | Utiliza un teléfono Android con pantalla pequeña y conexión a internet que puede interrumpirse. También recibe llamadas mientras atiende el negocio. **Por validar.** | Adaptar la interfaz a 360 dp de ancho, presentar mensajes de error con una acción de recuperación y conservar los datos del formulario ante una interrupción mientras la aplicación permanezca abierta. |
| **Qué quiere lograr** | Registrar lo que compra y vende, conocer las unidades disponibles y consultar el costo de compra y el precio de venta de cada producto. **Por validar.** | Actualizar las existencias al registrar compras y ventas y mostrar nombre y cantidad en la lista, con costo y precio en el detalle. |
| **Qué la frena hoy** | Anota cantidades, compras y ventas en un cuaderno y conserva facturas por separado. Algunas operaciones quedan sin descontar o sin sumar y después no puede explicar las diferencias. **Por validar.** | Centralizar productos y operaciones, calcular totales y exigir un motivo para los ajustes manuales de inventario. |
| **Una frase suya** | «Compro y vendo durante el día, pero al cerrar no siempre coincide lo que anoté con lo que queda en la tienda». **Frase supuesta, por validar.** | Distinguir compras, ventas y ajustes; mostrar cómo queda la cantidad disponible después de registrar cada operación. |


### Mapa de la situación actual, sin la aplicación

El siguiente mapa es una hipótesis de cómo la persona resuelve hoy estas actividades. Debe contrastarse con usuarios reales.

| Aspecto | 1. Organiza el inventario inicial | 2. Recibe una compra | 3. Atiende una venta | 4. Verifica las existencias |
| --- | --- | --- | --- | --- |
| **Qué hace** | Identifica los productos, cuenta las unidades y anota nombre, costo y precio en un cuaderno. | Revisa la mercancía recibida, guarda la factura y suma manualmente las unidades compradas. | Busca el precio, calcula cantidades y descuentos y anota la venta; después intenta descontar lo vendido. | Compara las anotaciones con los productos de los estantes y corrige las cantidades cuando encuentra diferencias. |
| **Dolor** | Puede dejar datos incompletos o confundir cantidades y precios al transcribirlos. | La compra puede quedar en la factura sin actualizar las cantidades del cuaderno. | Puede equivocarse al calcular el total o dejar una venta sin descontar del inventario. | Tarda en conocer la cantidad disponible y puede corregirla sin conservar la razón de la diferencia. |
| **Historia que atiende el dolor** | **HU-04:** registrar productos, costos y precios; **HU-06:** registrar existencias iniciales. | **HU-07:** registrar compras y aumentar las existencias. | **HU-08:** registrar ventas, calcular totales y descuentos y disminuir las existencias. | **HU-05:** consultar existencias; **HU-06:** registrar ajustes con su motivo. |

## 2. Criterios de aceptación

Cada historia contiene tres escenarios: uno de camino feliz, uno de error y uno propio del móvil. Se presentan 15 escenarios en total, con datos ficticios para realizar pruebas. Los criterios describen el comportamiento esperado y quedan pendientes de revisión cruzada y comprobación; todavía no constituyen resultados de pruebas.

### HU-05 — Consultar las existencias disponibles de cada producto

**Prioridad:** Must.  
**Estimación del backlog:** 2 puntos.

**Historia:** Como administrador de una pequeña empresa, quiero consultar las existencias disponibles de cada producto para saber qué mercancía puedo ofrecer y reconocer qué productos necesitan reposición.

```gherkin
# language: es

Escenario: Consultar el inventario con productos disponibles
  Dado que la empresa tiene 5 productos registrados con sus existencias
  Cuando consulto el inventario
  Entonces veo los 5 productos con su nombre y cantidad disponible
  Y puedo acceder al detalle de cada producto

Escenario: Falla la consulta del inventario
  Dado que ocurre una falla al obtener los productos de la empresa
  Cuando consulto el inventario
  Entonces veo el mensaje "No pudimos cargar el inventario"
  Y tengo disponible la opción "Reintentar"

Escenario: Consultar un inventario vacío desde el teléfono
  Dado que la empresa tiene 0 productos registrados
  Cuando consulto el inventario desde mi teléfono Android
  Entonces veo el mensaje "Aún no tienes productos"
  Y tengo disponible la opción "Registrar producto"
```

**Responsable propuesto de la historia:** Jose Manuel Torres Neira.  
**Revisor propuesto:** Juan David Ramos.  
**Revisó:** pendiente. El integrante que realice la revisión debe registrar su nombre y las observaciones correspondientes.

La opción «Registrar producto» se vincula con HU-04. Si durante la prueba técnica solo muestra un aviso porque el registro está pendiente, el criterio debe anotarse como no cumplido por completo en la validación técnica.

### HU-04 — Registrar y actualizar productos, costos de compra y precios de venta

**Prioridad:** Must.  
**Estimación del backlog:** 3 puntos.

**Historia:** Como administrador de una pequeña empresa, quiero registrar y actualizar los productos, sus costos de compra y sus precios de venta para mantener disponible la información que necesito al gestionar el negocio.

```gherkin
# language: es

Escenario: Actualizar el costo y el precio de un producto
  Dado que existe el producto "Arroz de 1 kg" con costo de 3000 pesos
  Y su precio de venta es de 4000 pesos
  Cuando actualizo su costo a 3500 pesos y su precio de venta a 4500 pesos
  Entonces el detalle de "Arroz de 1 kg" muestra el costo de 3500 pesos
  Y muestra el precio de venta de 4500 pesos
  Y la lista muestra una sola entrada para ese producto

Escenario: Intentar registrar un producto con costo negativo
  Dado que la empresa tiene 5 productos registrados
  Y los datos del nuevo producto incluyen un costo de -3500 pesos
  Cuando solicito registrar ese producto
  Entonces veo el mensaje "El costo de compra no puede ser negativo"
  Y el inventario conserva sus 5 productos sin agregar el registro inválido

Escenario: Evitar un registro duplicado por doble envío en el teléfono
  Dado que la empresa tiene 5 productos registrados
  Y preparé un nuevo producto "Aceite de 1 litro" con costo de 7000 pesos
  Y su precio de venta es de 9000 pesos
  Cuando envío dos veces la misma solicitud de registro en menos de 1 segundo
  Entonces el inventario contiene 6 productos
  Y "Aceite de 1 litro" aparece una sola vez con los valores registrados
```

**Responsable propuesto de la historia:** Victor Hugo Gomez Echeverri.  
**Revisor propuesto:** Juan Esteban Antolinez.  
**Revisó:** pendiente. El integrante que realice la revisión debe registrar su nombre y las observaciones correspondientes.

### HU-06 — Registrar existencias iniciales y ajustes con su motivo

**Prioridad:** Must.  
**Estimación del backlog:** 5 puntos.

**Historia:** Como administrador de una pequeña empresa, quiero registrar las existencias iniciales y los ajustes de inventario con su motivo para mantener las cantidades disponibles y explicar sus cambios.

```gherkin
# language: es

Escenario: Ajustar las existencias e indicar el motivo
  Dado que el producto "Arroz de 1 kg" tiene 20 unidades disponibles
  Cuando registro un ajuste de -2 unidades con el motivo "Dos unidades dañadas"
  Entonces veo 18 unidades disponibles para "Arroz de 1 kg"
  Y puedo consultar el ajuste de -2 unidades con su motivo

Escenario: Intentar ajustar existencias sin indicar el motivo
  Dado que el producto "Arroz de 1 kg" tiene 20 unidades disponibles
  Y preparé un ajuste de -2 unidades sin motivo
  Cuando solicito registrar el ajuste
  Entonces veo el mensaje "Debes indicar el motivo del ajuste"
  Y el producto conserva sus 20 unidades disponibles

Escenario: Evitar duplicar existencias iniciales por doble envío
  Dado que "Arroz de 1 kg" tiene 0 unidades y no tiene existencias iniciales registradas
  Y preparé el registro inicial de 20 unidades
  Cuando envío dos veces la misma solicitud desde el teléfono en menos de 1 segundo
  Entonces veo 20 unidades disponibles para "Arroz de 1 kg"
  Y puedo consultar un solo registro de existencias iniciales por 20 unidades
```

**Responsable propuesto de la historia:** Juan David Ramos.  
**Revisor propuesto:** Victor Hugo Gomez Echeverri.  
**Revisó:** pendiente. El integrante que realice la revisión debe registrar su nombre y las observaciones correspondientes.

### HU-07 — Registrar compras y aumentar las existencias

**Prioridad:** Must.  
**Estimación del backlog:** 5 puntos.

**Historia:** Como administrador de una pequeña empresa, quiero registrar las compras de productos para aumentar sus existencias y conservar la información de la mercancía adquirida.

```gherkin
# language: es

Escenario: Registrar una compra y aumentar las existencias
  Dado que el producto "Arroz de 1 kg" tiene 10 unidades disponibles
  Cuando registro una compra de 5 unidades a 3500 pesos por unidad
  Entonces veo 15 unidades disponibles para "Arroz de 1 kg"
  Y el detalle de la compra muestra 5 unidades y un total de 17500 pesos

Escenario: Intentar registrar una compra con cantidad cero
  Dado que el producto "Arroz de 1 kg" tiene 10 unidades disponibles
  Y preparé una compra de 0 unidades a 3500 pesos por unidad
  Cuando solicito registrar la compra
  Entonces veo el mensaje "La cantidad debe ser mayor que 0"
  Y el producto conserva sus 10 unidades disponibles
  Y la compra inválida no aparece entre las compras registradas

Escenario: Retomar una compra después de una llamada
  Dado que preparé una compra de 4 unidades de "Arroz de 1 kg" a 3500 pesos por unidad
  Y una llamada interrumpió el formulario sin cerrar la aplicación
  Cuando regreso al formulario después de la llamada
  Entonces veo el producto, la cantidad de 4 unidades y el costo unitario de 3500 pesos
  Y la compra sigue pendiente de confirmación sin modificar las existencias
```

**Responsable propuesto de la historia:** Victor Hugo Gomez Echeverri.  
**Revisor propuesto:** Juan Esteban Antolinez.  
**Revisó:** pendiente. El integrante que realice la revisión debe registrar su nombre y las observaciones correspondientes.

### HU-08 — Registrar ventas, calcular totales y descuentos, y disminuir las existencias

**Prioridad:** Must.  
**Estimación del backlog:** 8 puntos.

**Historia:** Como administrador de una pequeña empresa, quiero registrar las ventas con sus cantidades, precios y descuentos para conocer el total cobrado y actualizar las existencias de los productos vendidos.

```gherkin
# language: es

Escenario: Registrar una venta con descuento y actualizar las existencias
  Dado que "Arroz de 1 kg" tiene 10 unidades disponibles
  Y su precio de venta es de 4500 pesos por unidad
  Cuando registro una venta de 3 unidades con un descuento total de 1500 pesos
  Entonces el detalle de la venta muestra un subtotal de 13500 pesos
  Y muestra un descuento de 1500 pesos y un total de 12000 pesos
  Y veo 7 unidades disponibles para "Arroz de 1 kg"

Escenario: Intentar vender más unidades de las disponibles
  Dado que el producto "Arroz de 1 kg" tiene 2 unidades disponibles
  Cuando solicito registrar una venta de 3 unidades
  Entonces veo el mensaje "No hay existencias suficientes"
  Y el producto conserva sus 2 unidades disponibles
  Y la venta rechazada no aparece entre las ventas registradas

Escenario: Revisar el resumen de una venta en una pantalla pequeña
  Dado que utilizo un teléfono con pantalla de 360 dp de ancho
  Y preparé una venta de 3 unidades de "Arroz de 1 kg" a 4500 pesos por unidad
  Y agregué 1 unidad de "Aceite de 1 litro" a 9000 pesos sin aplicar descuentos
  Cuando consulto el resumen de la venta
  Entonces puedo leer los 2 nombres, sus cantidades y sus precios completos
  Y veo el total de 22500 pesos y el descuento de 0 pesos
  Y no necesito desplazarme horizontalmente
```

**Responsable propuesto de la historia:** Juan Esteban Antolinez.  
**Revisor propuesto:** Jose Manuel Torres Neira.  
**Revisó:** pendiente. El integrante que realice la revisión debe registrar su nombre y las observaciones correspondientes.

## 3. MVP y calidad

### Historias seleccionadas para el parcial

El ajuste del parcial contempla cinco historias Must: HU-04 (3 puntos), HU-05 (2 puntos), HU-06 (5 puntos), HU-07 (5 puntos) y HU-08 (8 puntos). La suma es **23 puntos**. Este valor identifica las historias seleccionadas para documentar y comprobar durante el parcial.

### Corte propuesto del MVP del producto

La primera versión de FinanzAsist permitirá recorrer las actividades esenciales de una pequeña empresa: acceder a su información, organizar el inventario, registrar compras, ventas y gastos, y consultar los resultados del negocio.

| Actividad del usuario | Historias mínimas que la cubren | Puntos |
| --- | --- | ---: |
| Acceder a la información de su empresa | HU-01: registrar cuenta y empresa; HU-02: iniciar y cerrar sesión; HU-03: restringir el acceso a usuarios autorizados. | 11 |
| Organizar y consultar el inventario | HU-04: registrar y actualizar productos, costos y precios; HU-05: consultar existencias; HU-06: registrar existencias iniciales y ajustes. | 10 |
| Registrar la mercancía comprada | HU-07: registrar compras y aumentar las existencias. | 5 |
| Registrar las ventas del negocio | HU-08: registrar ventas y actualizar existencias; HU-09: conservar el precio cobrado y el costo asignado a cada venta. | 13 |
| Registrar los gastos del negocio | HU-10: registrar gastos con fecha, concepto, categoría y valor. | 3 |
| Consultar los resultados de un período | HU-14: consultar reportes de ventas, ingresos, egresos, costos, gastos y utilidad. | 8 |
| **Subtotal de historias del MVP** | **11 historias de usuario Must.** | **50** |

Para soportar estas actividades se incluyen las tareas técnicas TEC-01, crear y configurar el proyecto y el repositorio, con 2 puntos, y TEC-02, implementar el almacenamiento y la separación de datos por empresa, con 8 puntos.

### Porcentaje del MVP del producto

Se utiliza la misma base de conteo en el numerador y el denominador: historias de usuario y tareas técnicas del backlog documentado en el README.

| Concepto | Puntos |
| --- | ---: |
| Historias de usuario del MVP | 50 |
| Tareas técnicas del MVP: TEC-01 y TEC-02 | 10 |
| **Total del MVP propuesto** | **60** |
| **Total del backlog: 20 HU y 2 TEC** | **111** |

**Porcentaje del MVP = (60 / 111) × 100 = 54,05 %.**

El corte propuesto se mantiene por debajo del máximo del 60 %. Las cifras corresponden a las estimaciones iniciales del backlog y deben actualizarse si el equipo modifica sus puntos o su alcance.

Los **23 puntos de las cinco historias seleccionadas** y los **60 puntos del MVP del producto** representan alcances distintos. El 54,05 % se calcula sobre el MVP completo de la primera versión. Elegir cinco historias para el parcial no modifica por sí solo ese corte del producto.

La implementación del parcial comienza con HU-05: lista del inventario, estados de cargando, vacío, error y con datos, y detalle de un producto mediante datos simulados. El cumplimiento de las cinco historias se registrará según las funciones y escenarios que realmente se ejecuten. La creación del proyecto y la ejecución del contador de Flutter son comprobaciones del entorno; las funcionalidades del negocio continúan pendientes hasta implementarlas y probarlas.

### Requisitos de calidad medibles

| ID | Requisito | Cómo se comprobará | Historia vinculada |
| --- | --- | --- | --- |
| RC-01 — Tiempo de respuesta | La lista del inventario debe quedar disponible en un máximo de 2 segundos desde la solicitud de consulta, con 200 productos y un retardo de 1,5 segundos en el repositorio simulado, ejecutándose en el Android de prueba del equipo. | Medir 3 consultas consecutivas en el escenario con datos. Cada consulta debe mostrar las primeras filas dentro de los 2 segundos y permitir recorrer los 200 productos. Registrar el modelo del teléfono, la versión de Android y los tiempos obtenidos en la validación técnica. | HU-05. |
| RC-02 — Adaptación a pantalla | Las pantallas de productos, consulta de inventario, ajustes, compras y ventas deben presentar 0 desbordamientos horizontales en una pantalla de 360 dp de ancho. Los nombres, las cantidades, los costos, los precios, los descuentos y los totales deben poder leerse completos. | Recorrer cada pantalla implementada, incluidos los cuatro estados de la lista y el detalle del producto, con un ancho de 360 dp. Se permiten varias líneas y desplazamiento vertical. Registrar como pendientes las pantallas todavía no implementadas. | HU-04, HU-05, HU-06, HU-07 y HU-08. |

**Estado de validación:** los requisitos de calidad son metas verificables. Sus resultados se registrarán después de ejecutar la aplicación y realizar las mediciones.

## 4. Implementación y validación técnica · 10 de noviembre de 2026

El alcance implementado comprende HU-04, HU-05, HU-06, HU-07 y HU-08. La referencia principal son los 19 escenarios vigentes en `Docs/criterios/`. Los 15 ejemplos de la sección 2 conservan su valor como escenarios complementarios de exploración; no reemplazan esos archivos. El diagnóstico inicial encontró catálogo e inventario simulados funcionales y ausencia de ajustes, compras, ventas y persistencia.

### Entorno comprobado

| Componente | Resultado |
| --- | --- |
| Rama | `examen/sprint1-tecnico`, sin cambios ajenos al iniciar. |
| SDK | Flutter 3.47.1, Dart 3.13.1. |
| Dispositivo | Pixel 5, `emulator-5554`, `sdk gphone16k x86 64`, Android 16, API 36. |
| Compilación | `flutter build apk --debug` completado; APK en `build/app/outputs/flutter-apk/app-debug.apk`. |
| Ejecución | Prueba de integración Android completa aprobada; instalación y arranque normal con `flutter run -d emulator-5554 --no-resident` completados. |
| Android físico | Pendiente de validación por el equipo. |

### Arquitectura implementada

Se conserva MVVM: las pantallas representan el estado y reciben la interacción, los ViewModels coordinan las operaciones, los modelos contienen datos y reglas compartidas y los repositorios consultan y modifican información.

| Ruta real | Responsabilidad |
| --- | --- |
| `lib/main.dart` | Tema y configuración del repositorio persistente o de demostración. |
| `lib/models/` | Producto por empresa, operación, detalle histórico, movimiento y validaciones compartidas. |
| `lib/data/producto_repository.dart` | Contrato del catálogo existente. |
| `lib/data/negocio_repository.dart` | Contrato común de compras, ventas y movimientos. |
| `lib/data/repositorio_sqlite.dart` | Persistencia transaccional, comprobación de saldos e idempotencia por empresa. |
| `lib/data/repositorio_simulado.dart` | Cinco productos ficticios, retardo de 1,5 segundos y selector de estados para desarrollo. |
| `lib/viewmodels/` | Inventario, detalle, operación y historial. |
| `lib/screens/` | Inventario, catálogo, detalle, apertura, ajuste, compra, venta e historial. |
| `test/` | Pruebas de catálogo, reglas, SQLite e interfaz a 360 dp. |
| `integration_test/sprint1_test.dart` | Recorrido completo Android con SQLite y empresa de prueba independiente. |

`Producto` conserva `id`, `nombre`, `cantidad`, `costoCompra` y `precioVenta`, y añade `empresaId`. Se preserva la API monetaria del catálogo con `double`; los cálculos de operaciones y el almacenamiento usan centavos enteros. El formulario acepta máximo dos decimales.

La lista de demostración conserva los datos implementados por el equipo: P001 Arroz (20), P002 Aceite (12), P003 Azúcar (15), P004 Leche (18) y P005 Jabón (0, agotado). Estos valores son ficticios. Android inicia vacío en modo persistente; no copia automáticamente los ejemplos a una base real.

### Almacenamiento y reglas

SQLite almacena empresas, usuarios locales, productos, operaciones, detalles y movimientos. Cada escritura de operación y sus cambios de existencias se confirman en una sola transacción; un error revierte todo. El mismo identificador de confirmación no aplica de nuevo el movimiento, incluso después de reabrir la base. El detalle y la lista se actualizan al regresar de cada operación.

Una apertura se permite una sola vez, cuando el producto no tiene movimientos. Los ajustes exigen motivo y no permiten saldos negativos. Compras y ventas admiten varios productos; una línea inválida impide confirmar todo el documento. El descuento de venta es un importe entre cero y el subtotal. Los precios cobrados y los costos de compra se conservan en el detalle histórico.

La empresa y el usuario iniciales son `negocio-local` y `administrador-local`. Las consultas y las relaciones están separadas por empresa, pero esta sesión de desarrollo no implementa autorización real. TEC-02 queda parcialmente atendido: faltan gastos y la integración con HU-01 a HU-03. No se implementó sincronización ni un método FIFO/promedio ponderado de HU-09.

### Pruebas y criterios cubiertos

- `dart format lib test integration_test test_driver`: ejecutado.
- `flutter analyze`: sin observaciones.
- `flutter test`: 59 pruebas aprobadas.
- `flutter build apk --debug`: compilación completada.
- `flutter build web --debug`: compilación completada del modo de demostración.
- `flutter test integration_test/sprint1_test.dart -d emulator-5554`: 1 prueba aprobada; crea producto, registra 20 iniciales, ajusta a 10, compra 5, vende 4 y recupera 11 al reabrir SQLite.
- El recorrido se repitió con `flutter drive` y siete capturas internas de Flutter revisadas; tres están en `Docs/evidencias/sprint1/`. Android System UI mostró un aviso de bloqueo persistente, por lo que la revisión manual del emulador y el teclado nativo siguen limitados. Véase el informe de validación.
- RC-02: las pruebas de widgets cubren los cuatro estados, nombres largos, detalle, formularios y resumen a 360 dp; incluyen espacio de teclado simulado.
- RC-01: siguen pendientes las tres mediciones de 200 productos en el Android del equipo.

| Historia | Criterios vigentes | Evidencia |
| --- | --- | --- |
| HU-04 | CA01–CA03 | Alta, edición con id y cantidad conservados, errores junto a campos, protección frente a doble envío. |
| HU-05 | CA01–CA03 | Producto y cantidad correctos, agotado y venta confirmada que reduce 15 a 11 en lista y detalle. |
| HU-06 | CA01–CA04 | Apertura, ajuste de 20 a 18, motivo/fecha/responsable y rechazo de existencias negativas. |
| HU-07 | CA01–CA04 | Compra de 5 × 6000 sobre 10 deja 15; líneas válidas, cancelación y reintento idempotente. |
| HU-08 | CA01–CA05 | Descuento y total, saldo insuficiente, cantidades/precios/descuentos inválidos, competencia por última unidad y cancelación. |

El refinamiento de HU-07 se comprueba con pausa y reanudación del ciclo de vida Flutter: el borrador de 4 × 3500 conserva sus valores y total 14000 sin alterar existencias. Una llamada real y la recuperación tras finalizar el proceso no se declaran verificadas.

Los casos de SQLite también comprueban aislamiento entre empresas y rollback con un fallo inyectado en la segunda línea de una compra. El informe ampliado y el recorrido manual están en [validacion-sprint1.md](validacion-sprint1.md).

### Pendientes de cierre académico

- Revisión cruzada y aprobación de otra persona, con sus nombres y evidencias.
- Validación con dos usuarios reales y prueba en Android físico.
- Medición de RC-01 y capturas finales de los cuatro estados para adjuntar al PR.
- Crear y vincular PR e issue, revisar, fusionar y actualizar GitHub Projects. No se realizaron publicaciones ni cambios en el tablero.
- Completar autenticación/autorización, gastos, método de costeo, reportes y sincronización en sus historias correspondientes.

La implementación y sus pruebas no equivalen a marcar las historias como Hecho según la Definición de Terminado del equipo. Los cambios están locales, preparados para revisión en la rama técnica.
