# Examen práctico · Sprint 1 · Flutter + Dart

> **Modelo resuelto** con el proyecto EcoReporte, sobre la plantilla del examen `24_Examen_Sprint1_Flutter_DAM.html`
> (versión de máximo 3 horas). Un equipo real escribe esto sobre **su propio** proyecto: copiar este contenido no
> puntúa.

- **Equipo y proyecto:** Los Juanchos · FinanzAsist · Ingeniería Informática, UNIPAZ.
- **Product Owner:** Jose Manuel Torres Neira.
- **Scrum Master / facilitador propuesto para Sprint 1:** Juan Esteban Antolinez.
- **Líder de UX/UI y desarrollo:** Victor Hugo Gomez Echeverri.
- **Responsable de pruebas:** Juan David Ramos (Juancho).
- **Documentación:** Juan Esteban Antolinez.
- **Historia técnica:** HU-05 — Consultar las existencias disponibles de cada producto.
- **Segunda historia Must:** HU-04 — Registrar y actualizar productos, costos de compra y precios de venta.

## 1.1. Persona y mapa de hoy

### Proto-persona

Martha Rodríguez representa a una propietaria de una pequeña tienda que comercializa productos. Su nombre, su situación y la frase presentada son supuestos de trabajo **por validar** con una persona real del público objetivo. No corresponden a una entrevista realizada.

| Campo | Descripción | Decisión que orienta en FinanzAsist |
| --- | --- | --- |
| **Contexto** | Martha atiende su tienda y se encarga de recibir mercancía, vender y revisar las cuentas. Durante la jornada alterna estas actividades y dispone de poco tiempo para consultar sus registros. **Por validar.** | Presentar una lista de productos que permita conocer las existencias y acceder al detalle desde el mismo recorrido. |
| **Teléfono y conexión** | Utiliza un teléfono Android con pantalla pequeña y conexión a internet que puede interrumpirse. **Por validar.** | Adaptar la consulta a 360 dp de ancho y mostrar un mensaje comprensible con opción de reintentar cuando falle la carga. |
| **Qué quiere lograr** | Saber cuántas unidades tiene de cada producto y consultar su costo de compra y precio de venta antes de atender una venta. **Por validar.** | Mostrar el nombre y las existencias en la lista; presentar costo y precio en el detalle del producto. |
| **Qué la frena hoy** | Anota cantidades y precios en un cuaderno y conserva facturas por separado. Para encontrar un dato debe revisar varias páginas o buscar un comprobante. **Por validar.** | Centralizar los datos de los productos y permitir su registro, actualización y consulta mediante HU-04 y HU-05. |
| **Una frase suya** | «A veces tengo que buscar en el cuaderno cuánto me costó un producto y contar lo que queda antes de responderle al cliente». **Frase supuesta, por validar.** | Usar etiquetas claras como «Existencias», «Costo de compra» y «Precio de venta», con valores completos y fáciles de leer. |

### Mapa de la situación actual, sin la aplicación

El siguiente mapa es una hipótesis de cómo la persona resuelve hoy estas actividades. Debe contrastarse con usuarios reales.

| Aspecto | 1. Recibe mercancía | 2. Anota los datos del producto | 3. Consulta las existencias | 4. Revisa el precio antes de vender |
| --- | --- | --- | --- | --- |
| **Qué hace** | Revisa los productos recibidos, cuenta las unidades y conserva la factura. | Escribe en un cuaderno el nombre, el costo de compra y el precio de venta; corrige los valores cuando cambian. | Busca las cantidades anotadas y cuenta los productos en los estantes cuando tiene dudas. | Revisa el cuaderno o una factura para recordar el costo y el precio del producto. |
| **Dolor** | Las cantidades recibidas pueden quedar separadas de los demás registros del inventario. | Puede dejar datos incompletos o encontrar varios precios anotados para el mismo producto. | Tarda en responder cuántas unidades tiene disponibles y debe interrumpir la atención para comprobarlo. | Pierde tiempo buscando los valores y puede utilizar un precio desactualizado. |
| **Historia que atiende el dolor** | HU-07: registrar compras y aumentar existencias; HU-06: registrar existencias iniciales y ajustes. | **HU-04:** registrar y actualizar productos, costos de compra y precios de venta. | **HU-05:** consultar las existencias disponibles de cada producto. | **HU-04 y HU-05:** mantener los datos del producto actualizados y consultar la información disponible en su detalle. |

## 1.2. Criterios de aceptación de las dos historias

Los siguientes criterios describen el comportamiento esperado. Su redacción queda pendiente de revisión cruzada por el equipo; todavía no constituyen resultados de pruebas.

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

## 1.3. Corte del MVP y dos requisitos de calidad

### Corte propuesto del MVP

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

### Porcentaje del MVP

Se utiliza la misma base de conteo en el numerador y el denominador: historias de usuario y tareas técnicas del backlog documentado en el README.

| Concepto | Puntos |
| --- | ---: |
| Historias de usuario del MVP | 50 |
| Tareas técnicas del MVP: TEC-01 y TEC-02 | 10 |
| **Total del MVP propuesto** | **60** |
| **Total del backlog: 20 HU y 2 TEC** | **111** |

**Porcentaje del MVP = (60 / 111) × 100 = 54,05 %.**

El corte propuesto se mantiene por debajo del máximo del 60 %. Las cifras corresponden a las estimaciones iniciales del backlog y deben actualizarse si el equipo modifica sus puntos o su alcance.

Este MVP corresponde al alcance propuesto de la primera versión del producto. Para la prueba técnica del parcial, el desarrollo se concentra en la lista del inventario, sus estados de cargando, vacío, error y con datos, y el detalle de un producto, utilizando datos simulados. Las demás funcionalidades conservan pendiente su implementación y validación.

### Requisitos de calidad medibles

| ID | Requisito | Cómo se comprobará | Historia vinculada |
| --- | --- | --- | --- |
| RC-01 — Tiempo de respuesta | La lista del inventario debe quedar disponible en un máximo de 2 segundos desde la solicitud de consulta, con 200 productos y un retardo de 1,5 segundos en el repositorio simulado, ejecutándose en el Android de prueba del equipo. | Medir 3 consultas consecutivas en el escenario con datos. Cada consulta debe mostrar las primeras filas dentro de los 2 segundos y permitir recorrer los 200 productos. Registrar el modelo del teléfono, la versión de Android y los tiempos obtenidos en la validación técnica. | HU-05. |
| RC-02 — Adaptación a pantalla | La lista, sus cuatro estados y el detalle del producto deben presentar 0 desbordamientos horizontales en una pantalla de 360 dp de ancho. Los nombres de los productos, las existencias, el costo y el precio deben poder leerse completos. | Recorrer los cuatro estados y abrir el detalle en una pantalla configurada a 360 dp de ancho. Los textos pueden ocupar varias líneas y se permite desplazamiento vertical; no debe ser necesario desplazarse horizontalmente para leerlos. | HU-05; el detalle muestra los datos definidos por HU-04. |

**Estado de validación:** los requisitos de calidad son metas verificables. Sus resultados se registrarán después de ejecutar la aplicación y realizar las mediciones.

## 4. Prueba técnica · Flutter + Dart
- **Pull request:** `examen/sprint1-tecnico` → `main` (en este repositorio modelo ya está revisado y fusionado; ver
  `git log --graph`).
- **Dispositivo:** *(el equipo anota aquí su Android y versión)*
- **Analizador** (`flutter analyze`): *(el equipo pega aquí el resultado)*

Lo que construyó la pareja técnica, en `lib/`:

| Archivo | Qué hace |
|---|---|
| `domain/reporte.dart` | El modelo, con los campos de HU-04 y HU-05 |
| `data/reporte_repository.dart` | El contrato de datos que conocen los ViewModel |
| `data/repositorio_simulado.dart` | Seis reportes del barrio y los cuatro escenarios, con 1,5 s de retardo |
| `ui/reportes/reportes_viewmodel.dart` | `ChangeNotifier` con `EstadoUi { cargando, vacio, error, listo }` |
| `ui/reportes/pantalla_reportes.dart` | Los cuatro estados con un `switch` sobre el enum |
| `ui/reportes/selector_escenario.dart` | Menú de escenarios, solo en modo de desarrollo |
| `ui/detalle/pantalla_detalle.dart` | HU-05, por id con `go_router` |
| `test/` | Los escenarios de HU-04 y HU-05 como pruebas automáticas |

| Escenario | ¿Cumple? (sí / no / aún no aplica) | Por qué |
|---|---|---|
| HU-04 · Lista con datos | **No del todo** | Ordena del más reciente al más antiguo, con fecha y lugar; la miniatura es un hueco porque la foto llega con HU-01 |
| HU-04 · No se pueden leer | Sí | Mensaje en lenguaje llano y «Reintentar» que vuelve a cargar |
| HU-04 · Lista vacía | Sí, a medias | Invita a crear el primero; la acción avisa que crear llega con HU-01 |
| HU-05 · Abrir el detalle | No del todo | Fecha, hora y lugar sí; la foto en grande es un hueco (HU-01) |
| HU-05 · Volver a la lista | Sí | La ruta del detalle es hija de `/`: la lista sigue en la pila con su posición |
| HU-05 · Pantalla pequeña | Sí | Lo cubre una prueba de widgets a 360 dp; en el teléfono se comprueba con `adb shell wm size 720x1600` y `wm density 320` |

> En este modelo la tabla muestra el resultado **esperado** según el código. El equipo la rellena con lo que ve en su
> teléfono: si algo no coincide, eso es lo que se anota.

**Pendiente para el Sprint 2:**
- TEC-02: cambiar el repositorio simulado por el de SQLite (solo cambia `main.dart`).
- HU-01 y HU-03: miniatura y foto reales; la acción «Crear el primero» deja de ser un aviso.
- Escenario de error de HU-05, si la revisión lo pide.
