# FinanzAsist

Aplicación móvil para la gestión financiera de pequeñas y medianas empresas que comercializan productos. Centraliza inventario, compras, ventas y gastos para consultar la utilidad y comprender el desempeño del negocio.

Proyecto académico del equipo **Los Juanchos**, del programa de Ingeniería Informática del Instituto Universitario de la Paz, UNIPAZ.

## 1. Visión del producto

FinanzAsist busca ser una aplicación móvil que facilite a las pequeñas y medianas empresas el control y la comprensión de sus finanzas, integrando la información de inventario, compras, ventas y gastos en un solo lugar. Su propósito es ofrecer una visión clara de la utilidad y del desempeño financiero del negocio, mediante reportes y herramientas de análisis que ayuden a sus propietarios y administradores a tomar decisiones informadas y planificar su crecimiento.

## 2. Objetivo del producto

Desarrollar una aplicación móvil que permita a pequeñas y medianas empresas centralizar la gestión de su inventario, compras, ventas y gastos, para calcular y visualizar la utilidad del negocio y apoyar la toma de decisiones mediante reportes, indicadores y herramientas de análisis financiero.

## 3. Público objetivo y plataforma

- **Usuarios:** propietarios, administradores y responsables financieros de pequeñas y medianas empresas que comercializan productos.
- **Plataforma inicial:** Android.
- **Tipo de aplicación:** móvil multiplataforma, con posibilidad de una versión posterior para iOS.
- **Etapa inicial:** exploración de requisitos, prototipado y validación con usuarios.
- **Tecnología de desarrollo y almacenamiento:** por definir y documentar antes de implementar la base técnica.

## 4. Equipo y responsabilidades

Las responsabilidades funcionales corresponden a la distribución consignada en el documento Sprint 0 del equipo.

| Integrante | Rol funcional | Responsabilidades |
| --- | --- | --- |
| Jose Manuel Torres Neira | Coordinador del proyecto y analista de requisitos | Coordinar el equipo, definir requisitos, priorizar el backlog y realizar seguimiento al tablero. |
| Victor Hugo Gomez Echeverri | Desarrollador y diseñador UI/UX | Diseñar interfaces y navegación, programar funcionalidades e integrar los componentes de la aplicación. |
| Juan David Ramos (Juancho) | Responsable de pruebas | Preparar escenarios, verificar funcionalidades, probar en dispositivos móviles y registrar errores y evidencias. |
| Juan Esteban Antolinez | Responsable de documentación | Documentar requisitos, decisiones y avances; mantener el README y elaborar el manual de usuario. |

### Correspondencia con los roles de la guía académica

Se utiliza Kanban para gestionar el flujo del trabajo y una planificación semanal por sprints para organizar las actividades solicitadas en el curso. Para la guía académica se establece esta propuesta de correspondencia:

| Responsabilidad de la guía | Integrante o equipo | Función |
| --- | --- | --- |
| Product Owner (PO) | Jose Manuel Torres Neira | Orientar el producto, coordinar la validación con usuarios y ordenar el backlog según valor, prioridad y dependencias. |
| Scrum Master o facilitador | Función rotativa; comienza con Juan Esteban Antolinez en Sprint 1 | Facilitar reuniones, dar seguimiento a bloqueos y ayudar a respetar las políticas y límites del tablero. |
| Equipo de trabajo | Los cuatro integrantes | Contribuir al objetivo semanal desde análisis, diseño, desarrollo, pruebas y documentación. |

**Plan propuesto de rotación de la facilitación:** Sprint 1, Juan Esteban Antolinez; Sprint 2, Juan David Ramos; Sprint 3, Victor Hugo Gomez Echeverri; Sprint 4, Jose Manuel Torres Neira. Después se repite el ciclo o se ajusta por disponibilidad. La rotación no cambia las responsabilidades funcionales ni la responsabilidad de Jose sobre la prioridad del producto.

## 5. Método de trabajo

Escogemos Kanban para el desarrollo de FinanzAsist porque permite visualizar las tareas, organizar las responsabilidades del equipo y controlar el avance de la aplicación móvil. Además, facilita priorizar actividades, identificar bloqueos y ajustar el trabajo cuando cambien los requisitos, manteniendo un flujo de desarrollo continuo.

El tablero muestra el estado de cada elemento y limita la cantidad de trabajo simultáneo. Los sprints de una semana sirven para establecer objetivos de seguimiento; el movimiento de tarjetas se realiza según la capacidad disponible y las dependencias.

## 6. Alcance y priorización MoSCoW

La primera versión permitirá registrar productos, costos de compra, precios de venta y existencias; gestionar compras, ventas y gastos; y consultar reportes básicos sobre la utilidad y el desempeño del negocio.

### Tabla MoSCoW

| Categoría | Descripción | Funcionalidades |
| --- | --- | --- |
| **Must: debe tener** | Funcionalidades indispensables para cumplir el propósito de la primera versión. | Registro e inicio de sesión; protección y separación de información por empresa; gestión de productos, costos, precios y existencias; compras y ventas con actualización del inventario; ajustes de inventario; gastos; conservación de precios y costos históricos por venta; reportes básicos por período. |
| **Should: debería tener** | Funcionalidades importantes que complementan las indispensables. | Categorías y subcategorías; clientes y proveedores; gráficos e indicadores financieros; alertas sobre aumentos de gastos o disminuciones de utilidad. |
| **Could: podría tener** | Mejoras que se incorporarán según el tiempo y los recursos disponibles. | Proyecciones financieras; simulación de escenarios; asistente de consulta financiera; funcionamiento parcial sin conexión y sincronización posterior. |
| **Won't: no tendrá en esta versión** | Funcionalidades excluidas de la primera versión. | Versión para iOS; facturación electrónica; integración bancaria; procesamiento de pagos; nómina; liquidación de impuestos; contabilidad integral; gestión de producción y materias primas. |

### Dentro del alcance

- Aplicación móvil para Android.
- Acceso autenticado e información separada por empresa.
- Registro y actualización de productos, costos de compra y precios de venta.
- Control de existencias iniciales, compras, ventas y ajustes de inventario.
- Registro de ventas con cantidades, precios realmente cobrados y descuentos.
- Conservación del costo asignado y del precio cobrado en cada venta.
- Registro y clasificación básica de gastos operativos.
- Reportes por período de ventas, costos, gastos y utilidad.
- Categorías, clientes, proveedores, gráficos y alertas como funcionalidades deseables.
- Proyecciones, simulaciones, asistente y operación parcial sin conexión como mejoras opcionales.

### Fuera del alcance de la primera versión

- Implementación y publicación para iOS.
- Facturación electrónica e integración con la DIAN.
- Conexiones automáticas con bancos y plataformas contables.
- Procesamiento de pagos mediante pasarelas.
- Gestión de nómina, impuestos y contabilidad integral.
- Elaboración de estados financieros oficiales.
- Gestión de producción y transformación de materias primas.

### Reglas para calcular y consultar la utilidad

- La utilidad bruta del período se obtiene de las ventas netas menos el costo de los productos vendidos.
- La utilidad resultante considerada por el producto descuenta también los gastos operativos registrados del período.
- La compra de mercancía que todavía permanece en inventario no se descuenta íntegramente como costo vendido.
- Cambiar el precio o costo del catálogo no modifica los valores conservados en ventas anteriores.
- El método de costeo del inventario debe acordarse antes de implementar ventas y reportes.
- La base de los indicadores de ingresos y egresos debe definirse antes de presentarlos: una venta registrada y un cobro no siempre representan el mismo evento.

## 7. Product Backlog

El backlog contiene **22 elementos base: 20 historias de usuario (HU) y 2 tareas técnicas (TEC)**. Cada issue debe tener título, descripción, criterios de aceptación, tareas, Tipo, Prioridad, Épica y Puntos. Los campos personalizados del proyecto deben completarse además del contenido del issue.

### Backlog estimado y ordenado

| Orden | ID | Tipo | Épica | Elemento | MoSCoW | Puntos |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | TEC-01 | Tarea técnica | Base | Crear el proyecto móvil y configurar el repositorio y las ramas de trabajo. | Must | 2 |
| 2 | TEC-02 | Tarea técnica | Base | Implementar el almacenamiento de datos y su separación por empresa. | Must | 8 |
| 3 | HU-01 | Historia | Acceso | Registrar la cuenta del propietario y los datos de su empresa. | Must | 3 |
| 4 | HU-02 | Historia | Acceso | Iniciar y cerrar sesión. | Must | 3 |
| 5 | HU-03 | Historia | Acceso | Restringir el acceso a la información de cada empresa a sus usuarios autorizados. | Must | 5 |
| 6 | HU-04 | Historia | Inventario | Registrar y actualizar productos, costos de compra y precios de venta. | Must | 3 |
| 7 | HU-06 | Historia | Inventario | Registrar existencias iniciales y ajustes con su motivo. | Must | 5 |
| 8 | HU-05 | Historia | Inventario | Consultar las existencias disponibles de cada producto. | Must | 2 |
| 9 | HU-07 | Historia | Compras | Registrar compras y aumentar las existencias. | Must | 5 |
| 10 | HU-08 | Historia | Ventas | Registrar ventas, calcular totales y descuentos, y disminuir las existencias. | Must | 8 |
| 11 | HU-09 | Historia | Ventas | Conservar el precio cobrado y el costo asignado a cada venta. | Must | 5 |
| 12 | HU-10 | Historia | Gastos | Registrar gastos con fecha, concepto, categoría y valor. | Must | 3 |
| 13 | HU-14 | Historia | Reportes | Consultar reportes por período de ventas, ingresos, egresos, costos, gastos y utilidad. | Must | 8 |
| 14 | HU-11 | Historia | Clasificación | Organizar productos y operaciones por categorías y subcategorías. | Should | 3 |
| 15 | HU-12 | Historia | Clientes y proveedores | Registrar clientes y relacionarlos con las ventas. | Should | 3 |
| 16 | HU-13 | Historia | Clientes y proveedores | Registrar proveedores y relacionarlos con las compras. | Should | 3 |
| 17 | HU-15 | Historia | Reportes | Visualizar gráficos e indicadores financieros. | Should | 5 |
| 18 | HU-16 | Historia | Reportes | Generar alertas sobre aumentos de gastos o disminuciones de utilidad. | Should | 5 |
| 19 | HU-17 | Historia | Análisis financiero | Consultar proyecciones basadas en los datos registrados. | Could | 8 |
| 20 | HU-18 | Historia | Análisis financiero | Simular cambios en ventas, costos y gastos. | Could | 8 |
| 21 | HU-19 | Historia | Asistente financiero | Consultar la información del negocio mediante un asistente financiero. | Could | 8 |
| 22 | HU-20 | Historia | Sincronización | Registrar operaciones sin conexión y sincronizarlas al recuperar internet. | Could | 8 |

La base técnica se atiende primero, seguida del acceso y la protección de datos. El catálogo y el inventario permiten implementar compras y ventas. Los reportes requieren operaciones registradas y costos históricos consistentes. Las categorías básicas necesarias para registrar gastos se incluyen en HU-10; HU-11 amplía su administración.

### Estimación mediante Planning Poker

Se usa la escala **1, 2, 3, 5, 8 y 13**. La historia de referencia es **HU-05, consultar existencias**, con **2 puntos**. Los puntos consideran diseño, desarrollo, pruebas, documentación, complejidad e incertidumbre; no representan horas.

El PO presenta cada historia, el equipo vota simultáneamente, quienes eligen los extremos explican su razonamiento y se realiza una segunda votación. En la versión exprés de la guía, si no hay acuerdo se toma el valor más alto. Un elemento que alcance 13 puntos debe dividirse y estimarse de nuevo antes de incorporarlo al trabajo.

Los valores de la tabla son estimaciones iniciales para validar con el equipo. Ningún elemento del backlog base tiene 13 puntos o más.

## 8. Tablero Kanban en GitHub Projects

### Campos del proyecto

| Campo | Uso |
| --- | --- |
| Status | Estado del elemento dentro del flujo. |
| Tipo | Historia, tarea técnica, defecto o investigación. |
| Prioridad | Must, Should o Could. |
| Épica | Grupo funcional al que pertenece el elemento. |
| Puntos | Estimación de esfuerzo relativo. |
| Sprint | Campo de tipo iteración, con períodos de una semana. |
| Assignees | Responsable o responsables de la tarjeta. |

### Vistas requeridas

- **Backlog:** permite consultar los elementos en el orden priorizado por el PO, con Tipo, Prioridad, Épica y Puntos visibles.
- **Sprint actual:** muestra los elementos de la iteración vigente y su avance por Status.
- **Por épica:** agrupa los elementos por módulo o área funcional.

Las columnas del campo Status se mantienen en este orden:

**Backlog → Listo → En desarrollo → En revisión → En dispositivo → Hecho.**

### Políticas de entrada y límites WIP

| Columna | Política de entrada | Límite WIP |
| --- | --- | --- |
| Backlog | La tarjeta tiene título claro, identificador y descripción. El PO organiza su prioridad según valor, MoSCoW y dependencias. | Sin límite |
| Listo | El equipo entiende el elemento. Tiene criterios verificables, puntos y dependencias resueltas para el trabajo previsto. | 5 |
| En desarrollo | Un responsable dispone de capacidad y se asigna la tarjeta. Para cambios de código se crea una rama, por ejemplo, `hu-04-productos`. | 4; máximo una tarjeta activa por integrante en esta columna |
| En revisión | El trabajo cuenta con evidencias y se solicita revisión a otra persona. Para código, existe un Pull Request vinculado al issue y pasan las comprobaciones de calidad. | 2 |
| En dispositivo | El código fue aprobado por otra persona y existe una APK de la versión aprobada instalada en un Android físico, con criterios disponibles para probarla. | 2 |
| Hecho | Cumple la Definición de Terminado correspondiente. Para código, el Pull Request está fusionado y se verificó la versión integrada. | Sin límite |

El límite de cuatro en En desarrollo contempla trabajo de análisis, diseño, programación y documentación. Victor mantiene como máximo una tarjeta de programación o diseño activa en esa columna. El equipo debe ayudar a finalizar trabajo cuando una columna llega a su límite.

## 9. Definición del Flujo de Trabajo

- **Elemento de trabajo:** un issue que representa una historia, tarea técnica, defecto o investigación.
- **Inicio del trabajo:** entrada en En desarrollo.
- **Finalización del trabajo:** entrada en Hecho.
- **Tiempo de ciclo:** tiempo transcurrido entre ambos momentos, incluyendo espera y bloqueos.
- **Selección de trabajo:** se toma el siguiente elemento de mayor prioridad que tenga sus dependencias resueltas y pueda atenderse sin superar el WIP.
- **Bloqueos:** la tarjeta permanece en su columna y cuenta dentro del WIP. Se añade la etiqueta `bloqueada`, se registra el motivo y se identifica la acción necesaria. Si el bloqueo dura dos días, el facilitador y Jose coordinan su resolución.
- **Correcciones:** si una revisión o prueba detecta un incumplimiento, la tarjeta vuelve a En desarrollo respetando el WIP y conservando el registro del error.
- **Trabajo no ejecutable:** requisitos, prototipos, documentación e investigación pueden pasar de En revisión a Hecho con aprobación y evidencias, sin recorrer En dispositivo.
- **Cambios de alcance:** el PO revisa su valor y efecto sobre las dependencias antes de incorporarlos al backlog o al objetivo semanal.

### Expectativa de nivel de servicio

Como meta provisional, la mayoría de los elementos pequeños debería terminar en **cuatro días o menos** desde su entrada en En desarrollo. La expectativa se revisará con los tiempos de ciclo reales obtenidos durante las primeras semanas.

## 10. Definición de Terminado de Exploración

Una historia o tarea de exploración pasa a Hecho cuando cumple los criterios que correspondan a su alcance:

- [ ] Tiene una descripción clara de la necesidad y del resultado esperado.
- [ ] Sus criterios de aceptación son verificables y están redactados en formato Dado / Cuando / Entonces.
- [ ] Sus reglas, supuestos y decisiones pendientes están documentados.
- [ ] Cuando incluye interfaz, las pantallas y la navegación están representadas en un prototipo de baja fidelidad, como mínimo.
- [ ] Cuando requiere validación de usuario, Jose registra los comentarios y las observaciones obtenidos con al menos un usuario real del público objetivo.
- [ ] Los ajustes necesarios se incorporaron o quedaron registrados como trabajo pendiente.
- [ ] Otra persona del equipo revisó el resultado y sus evidencias.
- [ ] Juan Esteban actualizó la documentación relacionada.

El Sprint 1 contempla dos usuarios para validar el flujo conjunto. Finalizar una tarea de exploración no significa que su funcionalidad ya esté implementada. La historia de implementación conserva pendientes sus criterios técnicos y funcionales hasta la etapa correspondiente.

## 11. Definición de Terminado de Implementación

Una funcionalidad implementada pasa a Hecho cuando:

- [ ] Cumple todos sus criterios de aceptación.
- [ ] El código fue revisado y aprobado por otra persona.
- [ ] Las comprobaciones de calidad y las pruebas correspondientes pasan.
- [ ] Juan David verificó el funcionamiento en un Android físico y registró evidencias.
- [ ] Los errores que impiden cumplir los criterios de aceptación están corregidos.
- [ ] La documentación está actualizada.
- [ ] El Pull Request está fusionado y la versión integrada mantiene el comportamiento validado.

Las historias de inventario, ventas y reportes deben comprobar la actualización de existencias, la conservación de precios y costos históricos y la consistencia de los cálculos, según corresponda.

## 12. Sprint 1 - Exploración y validación

**Duración:** una semana, definida en el campo Sprint del proyecto.

**Objetivo:** validar los requisitos y el flujo principal de inventario, compras, ventas, gastos y consulta de utilidad de FinanzAsist mediante criterios de aceptación y un prototipo de baja fidelidad.

### Elementos del Sprint 1

Los elementos S1 son tareas de exploración vinculadas al backlog base. Conservan su propio alcance y se estiman antes de pasar a Listo; no heredan automáticamente los puntos de las historias de implementación.

| ID | Elemento | Relación con el backlog | Responsable | Entregable |
| --- | --- | --- | --- | --- |
| S1-01 | Definir datos, costos, precios, existencias iniciales y ajustes de inventario; redactar sus criterios. | HU-04, HU-05, HU-06 | Jose, con apoyo de Juan David | Requisitos y criterios verificables de productos e inventario. |
| S1-02 | Definir compras, ventas, descuentos, tratamiento de costos y conservación de valores históricos. | HU-07, HU-08, HU-09 | Jose y Victor | Flujos, reglas y criterios de compras y ventas. |
| S1-03 | Definir gastos y reportes; preparar un ejemplo con resultados de utilidad conocidos. | HU-10, HU-14 | Jose, con apoyo de Juan David | Criterios y ejemplo verificable para consultar la utilidad. |
| S1-04 | Diseñar pantallas y conectar la navegación del flujo principal. | HU-04, HU-05, HU-07, HU-08, HU-10, HU-14 | Victor | Prototipo de baja fidelidad. |
| S1-05 | Validar requisitos y prototipo con dos usuarios reales de pymes y registrar comentarios. | Historias seleccionadas del flujo principal | Jose y Juan David | Evidencias de validación y lista de ajustes. |
| S1-06 | Preparar escenarios Dado / Cuando / Entonces, incluyendo errores de cantidad, stock y cálculos. | Historias seleccionadas del flujo principal | Juan David | Escenarios para las pruebas de implementación. |
| S1-07 | Consolidar requisitos, reglas, prototipo, comentarios y decisiones; actualizar este README. | Documentación del Sprint 1 | Juan Esteban | Documentación del sprint y backlog actualizado. |

### Plan de trabajo y capacidad

S1-01, S1-02 y S1-03 permiten preparar el prototipo S1-04 y los escenarios S1-06. La validación S1-05 se realiza cuando el prototipo está disponible. S1-07 consolida los resultados al cierre.

Todas las tareas seleccionadas llevan **Sprint = Sprint 1**. Las que cumplen las condiciones de entrada avanzan a Listo hasta su límite de cinco. Las demás permanecen en Backlog hasta completar sus dependencias y disponer de capacidad. Tener un sprint asignado no exime de las políticas de entrada ni de los límites WIP.

### Entregables del Sprint 1

- Requisitos y criterios de aceptación de las funcionalidades seleccionadas.
- Prototipo de baja fidelidad del flujo principal.
- Evidencias de validación con dos usuarios reales del público objetivo.
- Escenarios de prueba.
- Registro de decisiones, comentarios y ajustes al backlog.

### Registro de cierre

Al finalizar la semana se registran las tareas terminadas, las evidencias, los pendientes, los bloqueos y los ajustes para la siguiente iteración. Los resultados se documentan después de ejecutar las actividades; este apartado describe el plan del Sprint 1.

## 13. Plantillas, evidencias y acceso académico

- **Plantilla de historias:** `.github/ISSUE_TEMPLATE/historia.yml`.
- **Contenido mínimo de un issue:** historia u objetivo técnico, criterios, lista de tareas, prioridad, épica, puntos, dependencias y notas.
- **Evidencias:** se vinculan desde el issue correspondiente: prototipos, capturas, registros de validación, pruebas y Pull Requests.
- **Acceso del docente:** debe configurarse con permiso de lectura sobre el GitHub Project. Si el repositorio es privado, también debe poder consultar el repositorio y sus issues.
- **Verificación de entrega:** comprobar en GitHub las vistas, los campos, las columnas, los límites WIP, la iteración semanal, las tarjetas y los permisos. Documentar la configuración en este README no la aplica automáticamente al proyecto.
