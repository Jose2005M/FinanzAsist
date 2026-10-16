# Requisitos de FinanzAsist — Persona y mapa de experiencia

**Proyecto:** FinanzAsist  
**Equipo:** Los Juanchos — Ingeniería Informática, UNIPAZ  
**Etapa:** Sprint 1 — Parcial II  
**Fecha:** 15 de octubre de 2026  
**Ruta en el repositorio:** `docs/requisitos.md`

## 1. Propósito

Describir a una persona representativa de los usuarios de FinanzAsist y comprender cómo organiza hoy sus productos, compras, ventas y existencias sin la aplicación. A partir de esta descripción se documenta un cambio en una historia seleccionada para el parcial.

Las historias seleccionadas son HU-04, HU-05, HU-06, HU-07 y HU-08, todas con prioridad Must y un total de 23 puntos. La prueba técnica comienza con HU-05: lista y detalle del inventario con datos simulados.

## 2. Persona: Martha Rodríguez

Martha representa a una propietaria y administradora de una pequeña tienda en Barrancabermeja que comercializa productos.

**Estado de la información:** es una proto-persona ficticia construida como hipótesis de trabajo. Los datos, pensamientos, emociones y la frase de este documento están **por validar** con usuarios reales. No corresponden a una entrevista realizada.

| Campo | Descripción de la persona | Decisión que orienta en FinanzAsist |
| --- | --- | --- |
| **Contexto** | Martha atiende clientes, recibe mercancía y lleva las cuentas de su tienda. Alterna estas actividades durante el día y dispone de poco tiempo para anotar cada operación. **Por validar.** | Utilizar formularios breves y mostrar un resumen antes de confirmar compras, ventas y ajustes. |
| **Teléfono y conexión** | Utiliza un teléfono Android con pantalla pequeña. La conexión puede interrumpirse y recibe llamadas mientras trabaja. **Por validar.** | Comprobar la interfaz a 360 dp, informar los errores y conservar el borrador de una compra al volver de una llamada, siempre que la aplicación permanezca abierta. |
| **Qué quiere lograr** | Saber cuántas unidades tiene, registrar la mercancía que compra y vende y consultar los costos y precios de sus productos. **Por validar.** | Relacionar productos y movimientos de inventario, mostrar existencias y permitir consultar el detalle de cada producto. |
| **Qué la frena hoy** | Lleva registros en un cuaderno y conserva facturas por separado. Algunas operaciones quedan sin anotar y aparecen diferencias entre el registro y los productos disponibles. **Por validar.** | Actualizar las existencias al confirmar compras y ventas y conservar el motivo de los ajustes manuales. |
| **Una frase que representa su necesidad** | «Quiero saber cuánto me queda de cada producto sin tener que contar todo cada vez que me preguntan». **Frase supuesta, por validar.** | Mostrar el nombre y la cantidad disponible de cada producto e identificar los agotados. |

## 3. Mapa de experiencia actual, sin la aplicación

El siguiente mapa es una hipótesis del proceso actual mediante cuaderno, facturas, calculadora y conteos físicos. Las cuatro fases se contrastarán con usuarios reales.

| Aspecto | 1. Organiza sus productos | 2. Recibe mercancía | 3. Atiende una venta | 4. Revisa las existencias |
| --- | --- | --- | --- | --- |
| **Qué hace** | Cuenta los productos y anota cantidades, costos y precios en un cuaderno. | Compara la mercancía con la factura y suma las unidades recibidas a sus anotaciones. Si recibe una llamada, deja temporalmente el registro. | Busca el precio, calcula el total y el descuento y anota la venta cuando dispone de tiempo. | Revisa el cuaderno y cuenta los productos de los estantes para comprobar cuánto queda. |
| **Qué piensa** | «Necesito dejar estos datos organizados para encontrarlos después». | «¿En qué producto y cantidad iba antes de la llamada?». | «Tengo que cobrar bien y recordar descontar lo vendido». | «¿Por qué lo anotado no coincide con lo que tengo?». |
| **Qué siente** | Cansancio por el conteo y preocupación por equivocarse. | Presión por recibir mercancía mientras atiende otras actividades. | Afán por atender y temor a cometer errores en el cobro. | Incertidumbre y frustración ante las diferencias. |
| **Dolor o frustración** | Puede dejar datos incompletos o desactualizados. | Puede olvidar actualizar cantidades, perder el punto del registro o sumar una entrada dos veces. | Puede calcular mal el descuento o dejar una venta sin descontar del inventario. | Debe repetir el conteo y no siempre puede explicar las diferencias. |
| **Historia que atiende el dolor** | **HU-04:** registrar y actualizar productos, costos y precios. **HU-06:** registrar existencias iniciales. | **HU-07:** registrar compras y aumentar las existencias. | **HU-08:** registrar ventas, calcular descuentos y disminuir las existencias. | **HU-05:** consultar existencias. **HU-06:** realizar ajustes con motivo. |

## 4. Cambio en la lista de historias derivado de la persona y el mapa

### 4.1. Origen del cambio

El dato «recibe llamadas mientras trabaja» y la interrupción descrita en la fase **Recibe mercancía** muestran la necesidad de retomar una compra sin perder lo digitado ni modificar las existencias antes de confirmarla. Esta necesidad se incorpora como refinamiento de HU-07.

La relación es: **interrupción durante el registro → riesgo de perder o repetir datos → conservar el borrador y separar su preparación de la confirmación**.

### 4.2. Lista de historias: antes y después

| ID | Historia original | Historia ajustada a partir de la persona y el mapa | Prioridad | Puntos del backlog |
| --- | --- | --- | --- | ---: |
| **HU-07** | Como administrador, quiero registrar compras con productos, cantidades y costos para aumentar las existencias y controlar las adquisiciones. | Como administrador, quiero registrar compras con productos, cantidades y costos y retomar su borrador después de una llamada, para completar el registro sin perder los datos y aumentar las existencias únicamente al confirmar la compra. | Must | 5 |

Los 5 puntos se conservan como estimación de referencia. El equipo deberá revisar si el refinamiento cambia el esfuerzo antes de comprometer su implementación. HU-04, HU-05, HU-06 y HU-08 mantienen su redacción y sus puntos en esta actualización.

### 4.3. Nuevo criterio de aceptación de HU-07

Este escenario complementa los cuatro criterios existentes en el archivo HU-07.feature compartido por el equipo. Su identificador propuesto es **HU_07_CA05**.

```gherkin
# language: es

@HU_07_CA05 @Movil
Escenario: Retomar una compra después de una llamada
  Dado que preparé una compra de 4 unidades de "Arroz de 1 kg" con costo unitario de 3500 pesos
  Y el producto tiene 10 unidades disponibles
  Y una llamada interrumpió el formulario sin cerrar la aplicación
  Cuando regreso al formulario después de la llamada
  Entonces veo el producto "Arroz de 1 kg", la cantidad de 4 unidades y el costo unitario de 3500 pesos
  Y el resumen muestra un total de 14000 pesos
  Y la compra permanece pendiente de confirmación
  Y las existencias conservan sus 10 unidades
```

**Límite del criterio:** conservar el borrador durante una interrupción que no cierre la aplicación. Recuperarlo después de cerrar la aplicación o de que el sistema finalice su proceso requiere una decisión adicional. Este ajuste no incorpora sincronización ni registro de compras sin conexión; esas capacidades siguen en HU-20, con prioridad Could.

### 4.4. Estado del cambio y trazabilidad

| Elemento | Estado |
| --- | --- |
| Cambio de HU-07 y nuevo criterio en este documento | Documentados como refinamiento propuesto. |
| Contraste de la necesidad con usuarios reales | Pendiente. |
| Incorporación al issue de HU-07 y a HU-07.feature del repositorio | Pendiente; este documento no modifica esos elementos. |
| Revisión cruzada por una persona distinta del autor | Pendiente; registrar nombre y observaciones al realizarla. |
| Implementación y prueba del nuevo escenario | Pendientes. |

Si el criterio se incorpora a los archivos de aceptación, el conjunto pasará de 19 a 20 escenarios. Documentarlo no significa que ya haya sido implementado o probado.

## 5. Validación pendiente con usuarios reales

Se contrastarán la persona, el mapa y el cambio con dos propietarios o administradores de pequeñas empresas que comercialicen productos. Las conversaciones se centrarán en hechos de su trabajo, por ejemplo:

- ¿Cómo registró la última compra de mercancía que recibió?
- ¿Qué ocurrió la última vez que interrumpieron ese registro?
- ¿Cómo sabe qué cantidades ya sumó y cuáles siguen pendientes?
- ¿Cómo comprueba las unidades disponibles antes de vender?
- Si vuelve al registro después de una llamada, ¿qué información espera encontrar?

Se registrarán la fecha, el contexto del negocio, las observaciones y los cambios resultantes, sin recopilar datos personales innecesarios. Después se actualizarán los supuestos que se confirmen o se descarten.

## 6. Responsables y revisión

| Actividad | Responsable propuesto | Estado |
| --- | --- | --- |
| Coordinar el contraste con usuarios y revisar el alcance de HU-07 | Jose Manuel Torres Neira | Pendiente. |
| Revisar las decisiones de interfaz y la conservación del formulario | Victor Hugo Gomez Echeverri | Pendiente. |
| Revisar el escenario móvil y preparar su comprobación | Juan David Ramos | Pendiente. |
| Consolidar el documento y registrar los cambios y evidencias | Juan Esteban Antolinez | Documento preparado; revisión del equipo pendiente. |

**Revisado por:** pendiente.  
**Fecha de revisión:** pendiente.  
**Observaciones de la revisión:** pendientes.
