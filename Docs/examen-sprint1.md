# Examen práctico · Sprint 1 · Flutter + Dart

> **Modelo resuelto** con el proyecto EcoReporte, sobre la plantilla del examen `24_Examen_Sprint1_Flutter_DAM.html`
> (versión de máximo 3 horas). Un equipo real escribe esto sobre **su propio** proyecto: copiar este contenido no
> puntúa.

- **Equipo y proyecto:** Equipo modelo · EcoReporte
- **Integrantes y rol:** Integrante 1 (PO) · Integrante 2 (Scrum Master) · Integrante 3 (líder de UX/UI) ·
  Integrante 4 (Developer). Los cuatro son Developers.
- **Historia técnica:** HU-04 · **Otra historia Must:** HU-05

## 1. Persona y mapa de hoy

•	Contexto: Sandra, propietaria de una pequeña tienda de productos para el hogar, atiende clientes y lleva los registros del negocio en un cuaderno (por validar). Necesita registrar las ventas durante la atención.
•	Teléfono y conexión: Android de gama de entrada; utiliza datos prepago y tiene conexión intermitente (por validar). Esto orienta una interfaz sencilla y mensajes claros cuando falla una consulta.
•	Quiere lograr: registrar lo que vende y saber cuánto le queda después de descontar el costo de los productos vendidos y los gastos del negocio (por validar).
•	La frena hoy: anota ventas y gastos en lugares distintos; al cerrar el negocio debe reunir los registros y repetir cálculos para estimar la utilidad (por validar).
•	Una frase suya: «Vendo todos los días, pero cuando cierro no sé cuánto fue ganancia y cuánto necesito para reponer mercancía» (frase supuesta, por validar).
•		1 · Atiende una venta	2 · Anota lo vendido	3 · Reúne las cuentas	4 · Intenta saber cuánto ganó
Hace	Consulta una lista de precios y calcula cantidades y descuentos con una calculadora.	Escribe la venta en un cuaderno y descuenta las unidades en otro registro.	Al terminar la semana, reúne las ventas, los costos y los comprobantes de gastos.	Suma las ventas y resta costos y gastos para estimar la utilidad.
Dolor	Puede equivocarse al calcular el total o aplicar un descuento.	Puede olvidar una anotación y dejar las existencias desactualizadas.	Los registros están dispersos y debe consolidarlos manualmente.	Puede omitir valores y confundir el total vendido con la ganancia.
Historia	HU-08 · Registrar ventas.	HU-08 · Registrar ventas.	HU-14 · Consultar reportes por período.	HU-14 · Consultar reportes por período.

## 2. Criterios de aceptación

Propuesta para el examen, pendiente de revisión cruzada. Los nombres, cantidades y valores son datos ficticios de prueba. La moneda COP, las cantidades enteras y la aceptación de costo o precio cero están **por validar**; se propone impedir valores negativos. Los criterios se ejecutan en el contexto de una empresa autorizada. La demostración con una empresa simulada no verifica HU-03.

### HU-05 · Consultar las existencias disponibles de cada producto

**Como** propietario o administrador, **quiero** consultar las existencias de mis productos, **para** saber qué unidades tengo disponibles.

```gherkin
# language: es
Escenario: Consultar una lista con existencias
  Dado que la empresa activa tiene los productos Arroz con 12 unidades, Aceite con 5 unidades y Azúcar con 0 unidades
  Cuando consulto el inventario
  Entonces veo los 3 productos con su nombre y sus existencias respectivas
  Y Azúcar aparece con 0 unidades

Escenario: Fallo al consultar el inventario
  Dado que la fuente de datos del inventario devuelve un error
  Cuando consulto el inventario
  Entonces veo el mensaje «No pudimos cargar el inventario»
  Y tengo disponible la opción de reintentar la consulta
  Y no se presenta el fallo como si la empresa no tuviera productos

Escenario: Inventario vacío en el móvil
  Dado que la empresa activa tiene 0 productos registrados
  Cuando consulto el inventario
  Entonces veo el mensaje «Todavía no tienes productos registrados»
  Y tengo disponible una acción para iniciar el registro del primer producto
```

**Autor propuesto:** Jose Manuel Torres Neira.

**Revisor propuesto:** Juan David Ramos. **Revisó:** por validar; completar después de la revisión efectiva.

### HU-04 · Registrar y actualizar productos, costos de compra y precios de venta

**Como** propietario o administrador, **quiero** registrar y actualizar los datos de mis productos, **para** mantener vigente mi catálogo.

```gherkin
# language: es
Escenario: Registrar un producto con datos válidos
  Dado que preparo un producto llamado Arroz de 1 kg con costo de compra de 3000 COP y precio de venta de 4200 COP
  Cuando confirmo su registro
  Entonces veo la confirmación de que el producto fue guardado
  Y el producto aparece en el catálogo con ese nombre, costo y precio
  Y sus existencias iniciales son 0 unidades

Escenario: Rechazar un precio de venta negativo
  Dado que preparo un producto con nombre válido, costo de compra de 3000 COP y precio de venta de -100 COP
  Cuando confirmo su registro
  Entonces veo el mensaje «El precio de venta no puede ser negativo»
  Y el producto no se incorpora al catálogo
  Y los datos introducidos permanecen disponibles para corregirlos

Escenario: Actualizar un producto en una pantalla de 360 dp
  Dado que edito un producto existente en un teléfono de 360 dp de ancho
  Y he cambiado su precio de venta de 4200 COP a 4500 COP
  Cuando confirmo la actualización
  Entonces veo la confirmación de que los cambios fueron guardados sin texto cortado ni desplazamiento horizontal
  Y el catálogo muestra el precio de venta de 4500 COP para ese mismo producto
  Y no se crea un producto adicional ni se modifican sus existencias
```

**Autor propuesto:** Jose Manuel Torres Neira, con apoyo de Victor Hugo Gomez Echeverri.

**Revisor propuesto:** Juan Esteban Antolinez. **Revisó:** por validar; completar después de la revisión efectiva.

**Límites y dependencias:**
- Se propone que registrar un producto cree su catálogo con 0 unidades; validar esta regla con el PO. Las existencias iniciales y ajustes con motivo corresponden a HU-06.
- Comprar y vender modifica las existencias mediante HU-07 y HU-08, no mediante la edición del catálogo.
- Cambiar el costo o precio del catálogo no debe modificar los valores históricos conservados en ventas anteriores (HU-09). Verificarlo en la integración correspondiente.
- Estos seis escenarios son el mínimo del examen; no agotan las validaciones de HU-04 ni la seguridad por empresa.

## 3. MVP y calidad

### Corte del MVP propuesto

| Actividad del usuario | Historias mínimas del MVP | Puntos |
|---|---|---:|
| Acceder a la información de su empresa | HU-01 · HU-02 · HU-03 | 11 |
| Preparar y consultar productos y existencias | HU-04 · HU-05 · HU-06 | 10 |
| Registrar compras de mercancía | HU-07 | 5 |
| Registrar ventas conservando sus valores históricos | HU-08 · HU-09 | 13 |
| Registrar gastos operativos | HU-10 | 3 |
| Consultar resultados por período | HU-14 | 8 |
| **Subtotal de historias** | **12 historias Must** | **50** |

- **Soporte técnico:** TEC-01 (2 puntos) y TEC-02 (8 puntos): 10 puntos.
- **Puntos del MVP:** 50 + 10 = **60 puntos**.
- **Total del backlog base:** **111 puntos** en 20 HU y 2 TEC.
- **Porcentaje:** 60 / 111 × 100 = **54,05 %**, inferior al límite del 60 %.
- **Fuera del corte inicial:** HU-11, HU-12, HU-13, HU-15, HU-16, HU-17, HU-18, HU-19 y HU-20: 51 puntos.
- El cálculo usa las estimaciones iniciales del documento del proyecto; su vigencia y el denominador exigido por el docente están **por validar**. Las tareas S1 de exploración no se suman al backlog base de implementación.

El MVP completo no se implementa en las tres horas del examen. HU-05 y HU-04 son el foco de esta prueba técnica. Antes de implementar ventas y reportes deben acordarse el método de costeo y la base de los indicadores de ingresos y egresos.

### Dos requisitos de calidad propuestos

1. **Rendimiento:** la pantalla de inventario debe mostrar los nombres y existencias de la primera vista de la lista en un máximo de **1 segundo**, medido desde la solicitud de apertura hasta la aparición de los datos, con **200 productos en un repositorio local de prueba**, en **5 aperturas consecutivas** sobre el Android identificado en la sección 4, sin retardo artificial. Umbral y dispositivo: **por validar**. Se relaciona con HU-05; no acredita el rendimiento de un servicio remoto.
2. **Adaptación a pantalla móvil:** las pantallas de inventario y registro/edición deben permitir leer sus etiquetas, mensajes y valores completos con **0 desplazamientos horizontales y 0 solapamientos**, en orientación vertical de **360 dp de ancho**, escala de texto del sistema de **100 %** y nombres de producto de hasta **60 caracteres**; se permite ajuste de línea y desplazamiento vertical. Condiciones: **por validar**. Se relaciona con HU-04 y HU-05.

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
