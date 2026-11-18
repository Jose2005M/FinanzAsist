# Diseño de FinanzAsist

Ampliación del 16 de noviembre de 2026: guías iniciales, búsqueda en Inventario y períodos rápidos en Reportes. Las reglas visuales descritas a continuación se mantienen.

La misma iteración incorpora navegación compartida entre módulos, protección de formularios y equivalencias de dinero en COP. Consulta [las mejoras prioritarias](Docs/mejoras-prioridad-alta.md).

Actualizado el 13 de noviembre de 2026. Interfaz Flutter para registrar y consultar el inventario y las finanzas de pequeñas empresas. El objetivo de las pantallas es completar tareas con claridad. La identidad deriva de la referencia de inicio de sesión proporcionada por el usuario: fondo crema, acciones doradas y texto oscuro.

## Tema y componentes

El tema único se declara en `lib/theme/tema_finanzasist.dart` y se aplica desde `MaterialApp`. Acceso, registro, inventario, detalle y edición de productos, existencias iniciales, ajustes, compras, ventas, gastos y reportes lo comparten. Calendarios, menús de cuenta, desplegables, mensajes y navegación heredan la misma paleta.

| Uso | Color |
| --- | --- |
| Fondo | `#FFF3D6` |
| Superficie del panel y campo | `#FFFAEC` |
| Texto principal | `#20211D` |
| Texto secundario | `#5D594F` |
| Acción principal e indicador seleccionado | `#F0B400`, con texto oscuro |
| Foco y acciones de texto | `#89620B` |
| Borde de campo | `#706A5C` |
| Separador | `#DBCFAD` |
| Selección suave | `#FFE49A` |
| Error y resultado negativo | `#AA3026` |

El dorado brillante se reserva para superficies e indicadores. El texto de acento usa el dorado oscuro para conservar contraste sobre crema. Los errores incluyen una explicación; los resultados negativos también muestran el signo.

Los componentes reutilizables están en `lib/widgets/superficies_finanzasist.dart`:

- `PanelFinanzas`: agrupa los campos de una tarea o datos relacionados, radio 24, relleno habitual 20 y sombra suave desplazada hacia abajo.
- `AnchoContenido`: limita el ancho de las listas a 760; los formularios usan hasta 560 y el acceso hasta 460.
- `CabeceraModulo`: título de sección, icono decorativo y descripción.
- `EstadoModulo`: explicación de un estado vacío o de error, con acción de recuperación cuando corresponde.
- `ListadoModulo`: encabezado y registros dentro del mismo desplazamiento, con actualización al arrastrar y construcción de registros a demanda.

## Tipografía y espacio

Se conserva la tipografía nativa de Flutter y se respeta la ampliación del sistema. Los títulos principales usan 24 y peso 700; las barras superiores 21; los campos y botones 16; las ayudas 13. El acceso mantiene su composición de marca y título de 32.

Los márgenes habituales de pantalla son 20. Los campos relacionados se separan entre 16 y 20; las secciones entre 24 y 28. Los campos tienen radio 12 y borde de foco de 2. Las acciones principales y secundarias tienen radio 18 y altura mínima 52; el acceso conserva mínimo 54. Los controles de icono tienen área mínima de 48.

Los formularios agrupan sus entradas en un panel. Los reportes separan filtros y resultados. El detalle reúne la información del producto en un panel y presenta sus acciones y movimientos después. Los historiales usan superficies desplegables y los gastos muestran concepto, fecha, categoría e importe.

## Comportamiento

- Las pantallas respetan las áreas seguras de Android y utilizan iconos oscuros en las barras del sistema.
- El contenido puede desplazarse con pantallas pequeñas, teclado y texto ampliado. Los encabezados del inventario y de los historiales también se desplazan.
- La navegación muestra todas las etiquetas normalmente. Con texto grande muestra el nombre del módulo en una línea de ancho completo sobre los iconos, para evitar partir palabras; todos los destinos conservan sus nombres accesibles.
- `NegocioScreen` mantiene cinco navegadores y una barra inferior compartida, también en detalles y formularios. Cada destino conserva rutas, búsqueda, fechas y desplazamiento. Se cargan los módulos al visitarlos y se renuevan sus datos después de cambios en otros módulos.
- `ProtectorFormulario` ofrece seguir editando o descartar solo cuando hay cambios; el diálogo puede desplazarse con texto ampliado. Durante una escritura se impiden el regreso y el cambio de módulo. Los borradores entre destinos viven en memoria durante la sesión.
- `VistaPreviaImporte` muestra la equivalencia en COP debajo de cada campo monetario válido. Una regla común permite coma o punto decimal con hasta dos cifras y rechaza miles ambiguos; la ayuda y el error explican cómo escribir el importe.
- Se mantienen las transiciones y los controles de Flutter, el formato COP y las fechas de Colombia.
- Los campos conservan validación, ayudas y teclado apropiado. La espera deshabilita el envío repetido. Los mensajes de error y los indicadores utilizan el tema compartido.
- Los datos de demostración están identificados y los selectores de escenarios solo aparecen en depuración con repositorio simulado.

Para nuevos módulos, reutilizar el tema y estas superficies; evitar definir paletas o botones locales independientes. La marca del acceso se dibuja en `lib/widgets/marca_finanzasist.dart`.

Consulta las [evidencias y la validación del diseño](Docs/diseno-general.md).

## Ayuda y primeras tareas

`GuiaModulo` reutiliza el panel y la paleta existentes. Muestra propósito y primer paso; los tres pasos detallados se despliegan a petición. Se puede omitir y reabrir sin bloquear acciones. `AreaGuias` comparte el estado entre las rutas y lo separa por sesión. Las preferencias se guardan por cuenta en SQLite v4; la demostración utiliza memoria.

La búsqueda de Inventario conserva el campo y permite limpiar una consulta sin resultados. Los períodos rápidos de Reportes usan chips y consultan automáticamente; los calendarios siguen disponibles para otras fechas. Consulta la [revisión de usabilidad y las guías](Docs/usabilidad-y-guias.md).
