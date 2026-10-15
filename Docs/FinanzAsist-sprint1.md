# Examen práctico · Sprint 1 · FinanzAsist · Flutter + Dart

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

## 4. Prueba técnica · Flutter + Dart

### Estado actual del trabajo

- **Rama de trabajo:** `examen/sprint1-tecnico`, creada y activa según la salida de Git compartida.
- **Destino del pull request:** `main`.
- **Pull request:** pendiente de crear y registrar su enlace; se entregará abierto, sin fusionar.
- **Issue vinculado:** pendiente de registrar el enlace del issue correspondiente a HU-05.
- **Elemento INV «Prueba técnica del examen»:** pendiente de comprobar su creación y estado en el tablero.
- **Documento en `main`:** pendiente de comprobar que esta versión esté guardada en la ruta de entrega.

| Componente | Información comprobada |
| --- | --- |
| Flutter | Versión 3.47.1, canal estable. |
| Dart | Versión 3.13.1. |
| Sistema del computador | Windows 11, versión 25H2, arquitectura x64. |
| Proyecto | Creado con `flutter create --project-name finanzasist --platforms=android,web .`; dependencias descargadas. |
| Ejecución en Chrome | Confirmada por el equipo: abre la aplicación de ejemplo y funciona el contador. |
| Dispositivo Android de desarrollo | Emulador con perfil Pixel 5; Flutter lo identifica como `sdk gphone16k x86 64`, Android 16 (API 36). |
| Identificador del emulador | `emulator-5554`, detectado por `flutter devices`. |
| Ejecución en Android | Se inició con `flutter run -d emulator-5554`. La última evidencia muestra `Running Gradle task 'assembleDebug'...`; instalación y funcionamiento final pendientes de confirmar. |
| Prueba en teléfono Android físico | Pendiente de realizar y registrar el dispositivo utilizado. |

### Alcance técnico previsto

La primera implementación corresponde a la consulta de existencias de HU-05: una lista de productos y el detalle del producto solicitado por su identificador. La pantalla de lista tendrá los estados de **cargando, vacío, error y con datos**, con un selector de escenarios visible durante el desarrollo.

Las cinco historias seleccionadas conservan sus criterios de aceptación en la sección 2. Su cumplimiento se marcará conforme se implementen y comprueben sus funcionalidades.

**Modelo previsto `Producto`, con cinco campos:**

| Campo | Tipo previsto | Qué representa |
| --- | --- | --- |
| `id` | `String` | Identificador único del producto. |
| `nombre` | `String` | Nombre con el que se identifica el producto. |
| `existencias` | `int` | Cantidad de unidades disponibles. |
| `costoCompra` | `int` | Costo de compra unitario, expresado en pesos colombianos enteros para los datos de prueba. |
| `precioVenta` | `int` | Precio de venta unitario, expresado en pesos colombianos enteros para los datos de prueba. |

**Cinco registros simulados propuestos:** los valores son ficticios y se usarán para comprobar la interfaz; no corresponden a precios comerciales investigados ni a registros reales de una empresa.

| id | nombre | existencias | costoCompra (COP) | precioVenta (COP) |
| --- | --- | ---: | ---: | ---: |
| P001 | Arroz de 1 kg | 20 | 3500 | 4500 |
| P002 | Aceite de 1 litro | 12 | 7000 | 9000 |
| P003 | Azúcar de 1 kg | 15 | 3000 | 4000 |
| P004 | Leche de 1 litro | 18 | 3200 | 4000 |
| P005 | Jabón en barra | 8 | 2000 | 3000 |

Cada escenario de aceptación preparará los valores que indique su cláusula Dado. Las pruebas se ejecutarán con datos iniciales independientes para que una compra, una venta o un ajuste anterior no alteren el escenario siguiente. Para medir RC-01 se preparará un conjunto independiente de 200 productos; la lista de demostración conservará los cinco registros anteriores.

El repositorio simulado incorporará un retardo de **1,5 segundos** en los escenarios con datos, vacío y error. El escenario de cargando permitirá mantener el indicador visible para su comprobación y captura. Los datos del repositorio simulado se utilizarán para esta prueba; el almacenamiento definitivo se atenderá mediante TEC-02.

### Organización prevista del código

La arquitectura separará pantalla, ViewModel y repositorio. La pantalla representará el estado y recibirá las acciones del usuario; el ViewModel gestionará ese estado y solicitará los datos al repositorio.

| Archivo o carpeta | Función prevista | Estado al preparar este documento |
| --- | --- | --- |
| `lib/main.dart` | Iniciar FinanzAsist y configurar sus dependencias y navegación. | Generado; contiene la aplicación de ejemplo. Adaptación pendiente. |
| `lib/domain/producto.dart` | Definir el modelo `Producto` y sus cinco campos. | Pendiente de crear. |
| `lib/data/producto_repository.dart` | Definir el contrato para consultar productos y obtener uno por su identificador. | Pendiente de crear. |
| `lib/data/repositorio_simulado.dart` | Entregar cinco productos y simular cargando, vacío, error y con datos. | Pendiente de crear. |
| `lib/ui/inventario/inventario_viewmodel.dart` | Gestionar los cuatro estados de la lista, la carga y el reintento. | Pendiente de crear. |
| `lib/ui/inventario/pantalla_inventario.dart` | Mostrar la lista con nombre, existencias y precio de venta y representar los cuatro estados. | Pendiente de crear. |
| `lib/ui/inventario/selector_escenario.dart` | Permitir cambiar de escenario durante el desarrollo. | Pendiente de crear. |
| `lib/ui/detalle/detalle_viewmodel.dart` | Consultar el producto por su id y gestionar el resultado o el error del detalle. | Pendiente de crear. |
| `lib/ui/detalle/pantalla_detalle.dart` | Mostrar los datos del producto solicitado y permitir regresar a la lista. | Pendiente de crear. |
| `test/` | Comprobar los escenarios y la adaptación de las pantallas implementadas. | Se generó `widget_test.dart` de ejemplo; pruebas del negocio pendientes de preparar y ejecutar. |

Los archivos para registrar y actualizar productos, existencias iniciales, ajustes, compras y ventas se añadirán al implementar HU-04, HU-06, HU-07 y HU-08. Los nombres definitivos y su estado se actualizarán en esta tabla según el código realmente creado.

### Analizador y pruebas automáticas

- **Analizador (`flutter analyze`):** pendiente de ejecutar y registrar la salida.
- **Pruebas (`flutter test`):** pendiente de preparar las pruebas del negocio, ejecutarlas y registrar la salida.
- **RC-01, tiempo con 200 productos:** pendiente de realizar las tres mediciones y registrar las condiciones del equipo.
- **RC-02, adaptación a 360 dp:** pendiente de comprobar en las pantallas implementadas y guardar la evidencia.

El resultado satisfactorio de los comandos se anotará después de ejecutarlos. La prueba del contador confirma el arranque del proyecto en Chrome; la validación de las funciones de FinanzAsist requiere sus propias pruebas.

### Evidencias por incorporar

| Evidencia | Estado |
| --- | --- |
| Captura del estado cargando de la lista | Pendiente. |
| Captura del estado vacío de la lista | Pendiente. |
| Captura del estado de error con la opción Reintentar | Pendiente. |
| Captura de la lista con los cinco productos | Pendiente. |
| Verificación del detalle del producto y regreso a la lista | Pendiente. |
| Verificación de los contenidos con un ancho de 360 dp | Pendiente. |
| Enlace del PR con las cuatro capturas de los estados | Pendiente. |
| Registro de quién manejó el dispositivo durante la comprobación | Pendiente; debe ser una persona distinta de quien programó la parte comprobada. |

### Cumplimiento de los escenarios

Esta tabla refleja la situación previa al desarrollo de las funciones del negocio. Se utiliza **No** para señalar funcionalidades pendientes de implementación y comprobación. Todavía no hay resultados de ejecución de estos escenarios. Se actualizará cada fila con **sí, no o aún no aplica**, su justificación y su evidencia después de probarla.

| Historia y escenario | ¿Cumple? | Motivo o evidencia |
| --- | --- | --- |
| HU-05 · Consultar el inventario con productos disponibles | No | Pendiente de implementar la lista y comprobar los cinco productos. |
| HU-05 · Falla la consulta del inventario | No | Pendiente de implementar el error simulado y la opción Reintentar. |
| HU-05 · Consultar un inventario vacío desde el teléfono | No | Pendiente de implementar el estado vacío y verificar la acción Registrar producto. |
| HU-04 · Actualizar el costo y el precio de un producto | No | Pendiente de implementar la actualización y comprobar los valores 3500 y 4500 pesos. |
| HU-04 · Intentar registrar un producto con costo negativo | No | Pendiente de implementar la validación y comprobar que se conserven cinco productos. |
| HU-04 · Evitar un registro duplicado por doble envío en el teléfono | No | Pendiente de implementar el registro y comprobar que se cree una sola entrada. |
| HU-06 · Ajustar las existencias e indicar el motivo | No | Pendiente de implementar el ajuste de -2 unidades y verificar el resultado de 18 unidades. |
| HU-06 · Intentar ajustar existencias sin indicar el motivo | No | Pendiente de implementar la validación del motivo y comprobar que se conserven 20 unidades. |
| HU-06 · Evitar duplicar existencias iniciales por doble envío | No | Pendiente de implementar el registro inicial y verificar una sola operación por 20 unidades. |
| HU-07 · Registrar una compra y aumentar las existencias | No | Pendiente de implementar la compra y verificar 15 unidades y un total de 17500 pesos. |
| HU-07 · Intentar registrar una compra con cantidad cero | No | Pendiente de implementar la validación y verificar que la compra inválida no se registre. |
| HU-07 · Retomar una compra después de una llamada | No | Pendiente de implementar el formulario y comprobar que conserve los datos al regresar de la llamada. |
| HU-08 · Registrar una venta con descuento y actualizar las existencias | No | Pendiente de implementar la venta y verificar el total de 12000 pesos y las 7 unidades restantes. |
| HU-08 · Intentar vender más unidades de las disponibles | No | Pendiente de implementar la validación de existencias y comprobar el rechazo de la venta. |
| HU-08 · Revisar el resumen de una venta en una pantalla pequeña | No | Pendiente de implementar el resumen y comprobar su lectura a 360 dp con total de 22500 pesos. |

### Pendientes de cierre del parcial

- Confirmar que la aplicación base se instala y funciona en el emulador Android.
- Implementar la lista, el detalle, el repositorio simulado, el ViewModel y el selector de escenarios.
- Implementar y comprobar las funciones de las cinco historias conforme al alcance acordado para la entrega; documentar cualquier criterio que permanezca pendiente.
- Realizar la revisión cruzada de las cinco historias y registrar los nombres de quienes revisaron.
- Ejecutar el analizador, las pruebas automáticas y los escenarios en Android.
- Incorporar las cuatro capturas al pull request y registrar los enlaces del PR y del issue.
- Guardar esta versión del documento en `main` y actualizar la tarjeta INV según el trabajo realizado.

### Propuesta de continuidad para Sprint 2

Los siguientes elementos corresponden al backlog del producto y se confirmarán en la planificación del Sprint 2:

- **TEC-02:** sustituir los datos simulados por almacenamiento real y separar la información por empresa. La tecnología de almacenamiento está por definir.
- **HU-01, HU-02 y HU-03:** implementar el acceso, la cuenta de empresa y la autorización necesarios para utilizar información real.
- **HU-09:** conservar los precios y costos históricos de cada venta antes de construir reportes de utilidad.
- **Historias o criterios que queden abiertos al cerrar Sprint 1:** registrarlos con su motivo y volver a planificarlos; no se consideran terminados por haber creado su documentación.
