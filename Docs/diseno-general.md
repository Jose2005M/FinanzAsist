# Diseño uniforme de la aplicación

Fecha: 13 de noviembre de 2026. La referencia crema y dorada del inicio de sesión se aplica a todos los módulos de FinanzAsist. La [guía de diseño](../DESIGN.md) recoge colores, tamaños, componentes y reglas para futuras pantallas.

## Alcance

Se unificaron el acceso y registro de empresa, inventario, detalle y edición del producto, existencias iniciales, ajustes, compras, ventas, historiales, gastos y reportes. También comparten el tema los calendarios, desplegables, menú de cuenta, botones, campos, barras de navegación, indicadores, errores y mensajes de confirmación.

El tema se centralizó en `lib/theme/tema_finanzasist.dart`. Los paneles, encabezados, estados y listados reutilizables se encuentran en `lib/widgets/superficies_finanzasist.dart`. Los formularios agrupan los campos de una tarea; los reportes separan el período y los resultados. Los encabezados de listas se desplazan junto con los registros para permitir pantallas pequeñas y texto ampliado.

## Verificación

- `flutter analyze`: sin observaciones.
- `flutter test --reporter expanded`: **113 pruebas aprobadas**. Registro: `build/pruebas-diseno-general-final.log`.
- Se añadieron seis pruebas en `test/diseno_general_widget_test.dart`: cinco recorridos a 320 × 640 con texto al 200 %, incluido formulario con teclado; y comprobación de contraste, nombres accesibles y área táctil Android en los cinco módulos principales.
- La revisión visual de 16 vistas a 390 × 844 utilizó las fuentes Roboto y los iconos Material de Android. Sus datos son simulados. La captura auxiliar se ejecutó aparte de la suite del proyecto; registro: `build/capturas-diseno-general.log`.
- El detector de diseño terminó sin hallazgos en el tema, las pantallas y los componentes compartidos.
- El recorrido Android de producto, apertura, ajuste, compra, venta y reapertura SQLite aprobó. Comprobó 11 unidades finales y venta de 38.000 COP. Registro: `build/android-diseno-inventario.log`.
- El recorrido Android de gastos y reportes aprobó: dos gastos conservados al reabrir la base, costo histórico de ventas de 500.000 COP y utilidad resultante de 250.000 COP. Registro: `build/android-diseno-finanzas.log`.
- El recorrido Android de acceso aprobó registro de empresa, salida, intento inválido, reingreso y limpieza de las rutas privadas. Registro: `build/android-diseno-general-acceso.log`.

Las pruebas de integración usan bases QA independientes. La revisión en teléfono físico y la validación con usuarios siguen pendientes.

Después de las pruebas se compiló, instaló y ejecutó la aplicación normal en el emulador Android. La [captura final](evidencias/diseno-general/android-app-normal.png) muestra el registro inicial con las barras del sistema. La APK de depuración está en `build/app/outputs/flutter-apk/app-debug.apk`; el registro de ejecución es `build/ejecucion-diseno-general.log`.

## Capturas

Las siguientes vistas pertenecen a la revisión de widgets con datos simulados; las capturas Android se identifican por separado.

| Módulo | Vistas |
| --- | --- |
| Inventario | [Catálogo](evidencias/diseno-general/01-inventario.png), [detalle](evidencias/diseno-general/02-detalle.png) |
| Productos | [Edición](evidencias/diseno-general/03-editar-producto.png), [registro](evidencias/diseno-general/04-registrar-producto.png) |
| Existencias | [Ajuste](evidencias/diseno-general/05-ajuste.png) |
| Compras | [Historial](evidencias/diseno-general/06-historial-compras.png), [formulario](evidencias/diseno-general/07-compra.png), [confirmación](evidencias/diseno-general/08-resumen-compra.png) |
| Ventas | [Historial](evidencias/diseno-general/09-historial-ventas.png), [formulario](evidencias/diseno-general/10-venta.png), [confirmación](evidencias/diseno-general/11-resumen-venta.png) |
| Gastos | [Historial](evidencias/diseno-general/12-gastos.png), [registro](evidencias/diseno-general/13-registrar-gasto.png), [calendario](evidencias/diseno-general/14-calendario.png) |
| Reportes | [Período e ingresos](evidencias/diseno-general/15-reporte-periodo.png), [resultado](evidencias/diseno-general/16-reporte-resultado.png) |
| Android con SQLite QA | [Inventario final](evidencias/diseno-general/android-inventario.png), [confirmación de venta](evidencias/diseno-general/android-resumen-venta.png), [gastos](evidencias/diseno-general/android-gastos.png), [reporte](evidencias/diseno-general/android-reporte.png) |
| Android con cuenta QA | [Acceso](evidencias/diseno-general/android-acceso.png), [inventario de empresa](evidencias/diseno-general/android-empresa.png) |

El [documento del acceso](diseno-acceso.md) conserva el detalle de la composición de marca y del comportamiento de sus formularios.
