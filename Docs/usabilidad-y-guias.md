# Usabilidad y guías por módulo

Revisión del 16 de noviembre de 2026 sobre la aplicación Flutter local. Las observaciones provienen del código, los recorridos de prueba y la revisión de pantallas. Todavía deben contrastarse con propietarios de pequeñas empresas; no representan resultados de pruebas con usuarios reales.

## Mejoras incorporadas

| Dificultad encontrada | Cambio disponible |
| --- | --- |
| No siempre queda claro para qué sirve un módulo o qué registrar primero. | Introducción en Inventario, Compras, Ventas, Gastos y Reportes con propósito, primer paso y tres instrucciones opcionales. |
| Compras y gastos pueden confundirse; crear un producto no añade unidades. | Las guías distinguen mercancía y pagos operativos, explican las existencias iniciales y cómo compras y ventas cambian el inventario. |
| Repetir instrucciones en cada visita interrumpe el trabajo habitual. | “Entendido” y el cierre ocultan la guía; “Guía de…” permite consultarla otra vez. La decisión se recuerda por cuenta. |
| Localizar un producto exige recorrer la lista. | Buscar producto, sin distinguir mayúsculas ni tildes; limpieza y mensaje recuperable cuando no hay coincidencias. |
| Consultar períodos habituales exige abrir calendarios. | Hoy, Últimos 7 días y Este mes seleccionan las fechas y consultan automáticamente. Desde y Hasta permiten otros períodos. |
| Con texto al doble, el nombre del módulo se parte dentro de la barra inferior. | El nombre se muestra en una línea de ancho completo sobre los iconos; cada destino conserva su nombre accesible. |

## Cómo funcionan las guías

Las guías aparecen dentro del contenido, conservando las acciones del módulo. No es obligatorio leerlas ni completar un recorrido para usar la aplicación.

| Módulo | Qué explica |
| --- | --- |
| Inventario | Crear el producto, registrar unidades iniciales y distinguir compras, ventas y ajustes. |
| Compras | Seleccionar productos, indicar cantidad y costo unitario, revisar y confirmar la entrada. |
| Ventas | Elegir productos con existencias, introducir cantidades y precios, aplicar descuentos y confirmar la salida. |
| Gastos | Registrar pagos operativos con fecha, concepto, categoría y valor; distinguirlos de la mercancía. |
| Reportes | Elegir el período e interpretar ingresos, egresos y utilidad, sin descontar dos veces las compras. |

Al principio se muestra una explicación breve. **Ver pasos** amplía las instrucciones y **Ver menos** vuelve al resumen. **Entendido** y el icono de cierre recuerdan la decisión. **Guía de [módulo]** permite reabrirla con los pasos visibles.

En Android con una cuenta, las preferencias se guardan en SQLite y se conservan al volver a entrar o reabrir la base. Una cuenta nueva tiene sus propias guías. En la demostración se recuerdan durante la ejecución; sus datos continúan en memoria. Si falla guardar la preferencia, se oculta durante la sesión y se informa que podría aparecer de nuevo.

La migración v3 → v4 añade únicamente la tabla `guias_vistas`. La lectura y escritura verifican la sesión y filtran por cuenta. La guía no crea productos ni movimientos de ejemplo en el negocio.

## Siguientes mejoras recomendadas

Seguimiento de la iteración siguiente: navegación compartida, equivalencias de importes y aviso de descarte ya están implementados en la [versión 1.0.2](mejoras-prioridad-alta.md). Las demás propuestas siguen pendientes. La prioridad refleja el efecto esperado y debe confirmarse con usuarios.

| Prioridad | Propuesta | Motivo y criterio de aceptación sugerido |
| --- | --- | --- |
| Alta · realizada | Mantener la navegación entre los cinco módulos. | Barra compartida, consultas conservadas, borradores en memoria y datos actualizados al regresar. |
| Alta · realizada | Mostrar equivalencias de importes durante la escritura. | Vista previa en COP y rechazo de separadores ambiguos, como `6.000`. |
| Alta | Respaldo, exportación y restauración. | El negocio vive en un dispositivo. Guardar una copia, verificarla y restaurarla con una confirmación clara del alcance. |
| Media | Buscar productos dentro de compras y ventas. | El selector actual es desplegable. Encontrar un producto por nombre en catálogos largos sin recorrerlos completos. |
| Media · realizada | Avisar antes de descartar formularios modificados. | Seguir editando o descartar solo cuando hay cambios; se bloquea la salida durante el guardado. |
| Media | Alertas de existencias mínimas configurables. | Actualmente se identifica el producto agotado. Permitir definir cuándo se necesita reponerlo. |
| Media | Mostrar nombres de responsables en los historiales. | Se muestran identificadores técnicos. Priorizar el nombre legible y conservar el identificador para auditoría. |

Para validar la siguiente iteración, pedir a una persona nueva que registre un producto con unidades iniciales, confirme una venta, anote un gasto y consulte su resultado. Observar dónde solicita ayuda, qué guía abre y si identifica correctamente el efecto de cada registro.

## Evidencias

Capturas Android con una cuenta QA independiente: [Inventario](evidencias/guias/inventario.png), [Compras](evidencias/guias/compras.png), [Ventas](evidencias/guias/ventas.png), [Gastos](evidencias/guias/gastos.png) y [Reportes](evidencias/guias/reportes.png).

El recorrido de `integration_test/acceso_test.dart` comprobó apertura, cierre y reapertura de las cinco guías, cinco preferencias guardadas y su conservación tras cerrar e iniciar sesión. Registro: `build/android-guias.log`.

Las pruebas específicas están en `test/guias_test.dart` y `test/guias_widget_test.dart`. Comprueban aislamiento por cuenta, migración, persistencia, fallos de almacenamiento, ayuda opcional, accesibilidad, texto ampliado, búsqueda y períodos rápidos.

La suite completa aprobó **126 pruebas**, incluidas diez nuevas. Registros: `build/pruebas-guias-final.log` y `build/analisis-guias-final.log`. Los tres recorridos Android aprobaron: guías y acceso, inventario/compras/ventas con búsqueda y gastos/reportes con períodos rápidos. Registros: `build/android-guias.log`, `build/android-guias-inventario.log` y `build/android-guias-finanzas.log`.

La revisión visual comprobó las cinco guías en Android y los [pasos ampliados](evidencias/guias/pasos.png), el [texto al 200 % a 320 × 640](evidencias/guias/texto-ampliado.png), la [búsqueda](evidencias/guias/busqueda.png) y el [período rápido](evidencias/guias/periodo-rapido.png). Tras ajustar la navegación para texto grande, se repitieron las doce pruebas de interfaz relacionadas y la captura auxiliar: `build/revision-guias-final.log`. El detector de diseño terminó sin hallazgos.

El análisis final terminó sin observaciones: `build/analisis-guias-cierre.log`. La aplicación normal se compiló, instaló y ejecutó en el emulador después de las pruebas; registro: `build/ejecucion-guias.log`. La APK de depuración queda en `build/app/outputs/flutter-apk/app-debug.apk`.
