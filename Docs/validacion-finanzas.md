# Continuación de FinanzAsist: costos, gastos y reportes

Fecha: 10 de noviembre de 2026. Rama: `examen/sprint1-tecnico`.

Este informe conserva el corte de costos, gastos y reportes. La [ampliación de cuentas y sesiones del 12 de noviembre](validacion-acceso.md) sustituye la sesión de desarrollo por cuentas locales y añade la migración SQLite v3.

## Funciones disponibles

- **HU-09:** cada venta conserva precio cobrado, descuento total y costo asignado por unidad. El historial muestra costo de ventas y utilidad bruta. Editar el catálogo no cambia los resultados anteriores.
- **HU-10:** registro y consulta de gastos con fecha, concepto, categoría, valor y responsable; campos obligatorios, importe positivo de hasta dos decimales, protección durante el envío y reintentos idempotentes. Las categorías básicas son Servicios, Arriendo, Transporte, Insumos, Personal y Otros.
- **HU-14:** reporte por período con ventas antes de descuentos, descuentos, ingresos netos, compras, gastos, egresos, costo de ventas y utilidades. Incluye estados de carga, vacío, error y reintento. Cambiar las fechas retira el resultado anterior hasta consultar de nuevo.

La barra de navegación tiene cinco destinos: Inventario, Compras, Ventas, Gastos y Reportes. Los formularios se desplazan con el teclado y los calendarios se muestran en español. Se conserva MVVM y el modo de demostración en memoria.

## Reglas y decisiones de cálculo

La referencia funcional son `criterios/HU-09.feature`, `HU-10.feature` y `HU-14.feature`: diez escenarios adicionales. Se utiliza como costo asignado **el costo registrado en el catálogo al confirmar la venta**, que ya se guardaba en el corte anterior. La interfaz identifica esta decisión; no implementa FIFO ni promedio ponderado. Cambiar de método requiere una decisión posterior y no debe recalcular ventas históricas.

Los importes se calculan en centavos enteros. Se rechazan fracciones menores al centavo y se comprueba el límite de cálculo exacto para evitar resultados numéricos desbordados. Las operaciones consideradas son al contado, sin impuestos ni devoluciones, conforme a los ejemplos de HU-14.

| Indicador | Regla |
| --- | --- |
| Ingresos netos | Ventas antes de descuentos − descuentos. |
| Egresos | Compras + gastos operativos. |
| Costo de ventas | Cantidades vendidas × costos unitarios históricos asignados. |
| Utilidad bruta | Ingresos netos − costo de ventas. |
| Utilidad resultante | Utilidad bruta − gastos operativos. |

Las compras no se descuentan de nuevo de la utilidad. Un período con gastos y sin ventas puede mostrar una pérdida; los resultados negativos conservan su signo.

La zona del negocio local es Colombia, UTC-5. Los límites se convierten al inicio UTC del primer día y al inicio del día siguiente al último, usando un intervalo cerrado al inicio y abierto al final. Se prueban registros a un microsegundo de los límites. El gasto usa una fecha civil, independiente de la zona horaria del computador.

## Persistencia y compatibilidad

SQLite pasa de versión 1 a 2 mediante una migración que añade `gastos`. No elimina ni vuelve a crear tablas anteriores. Los gastos conservan empresa y usuario y no alteran existencias. Los reportes consultan compras, ventas y gastos dentro de una misma transacción de lectura para evitar combinar estados parciales.

Las ventas nuevas guardan `costoAsignadoCentavos` y el método `catalogo_al_confirmar`. Las ventas de la versión anterior conservan `costoCatalogoCentavos`: se lee ese campo como costo histórico sin modificar los registros. Una prueba abre una base v1, conserva un producto y una venta existentes, aplica la migración y registra un gasto.

La sesión sigue siendo local. La separación por empresa no sustituye autenticación ni autorización remota. TEC-02 queda ampliado para gastos, pero no se declara completo respecto a usuarios autorizados.

## Pruebas y criterios

| Criterios | Evidencia automatizada |
| --- | --- |
| HU-09 CA01–CA03 | Precio/costo históricos, ingreso 18000, costo 12000, utilidad 6000 y conservación tras editar catálogo. |
| HU-10 CA01–CA03 | Gasto de energía por 80000, datos obligatorios, rechazo de cero/negativos y valores no finitos; cancelación y doble envío. |
| HU-14 CA01 | Ventas 1000000 − descuentos 100000 = ingreso 900000; costo 500000; compras 600000; gastos 150000; egresos 750000; utilidad bruta 400000 y resultante 250000. |
| HU-14 CA02 | Límites inclusivos de fechas de Colombia, incluidos microsegundos y exclusión de operaciones fuera del período. |
| HU-14 CA03–CA04 | Ceros sin operaciones, pérdida con gastos, rechazo del intervalo invertido y retiro de resultados desactualizados. |
| Persistencia | Reapertura con gastos, reintentos sin duplicados, aislamiento entre empresas y migración de base v1 sin perder productos/ventas. |
| Estado e interfaz | Error y reintento, respuestas fuera de orden, cierre durante consulta, calendario español, formularios y reporte a 360 dp, espacio de teclado simulado. |

`dart format` y `flutter analyze` se ejecutaron sin observaciones. `flutter test` aprobó **87 pruebas**, incluidas las 59 del corte anterior y 28 nuevas. Registro local: `build/pruebas-finanzas-final.log`.

`flutter build apk --debug` compiló correctamente. `flutter devices` detectó el Pixel 5, `emulator-5554`, Android 16/API 36. El recorrido `flutter drive --driver=test_driver/integration_test.dart --target=integration_test/finanzas_test.dart -d emulator-5554 --dart-define=CAPTURAS=true` terminó aprobado: registró gastos de 80000 y 70000, comprobó ingresos de 900000, costo histórico de 500000 y utilidad resultante de 250000, y recuperó los resultados después de reabrir SQLite. Se exportaron y revisaron tres capturas internas de Flutter. Registros: `build/android-finanzas.log` y `build/compilacion-finanzas-android.log`.

El detector de Impeccable se ejecutó sobre las pantallas y el campo de fecha modificados y devolvió `[]`. La interacción a 360 dp y el espacio del teclado se comprobaron con widgets; las capturas Android usan el tamaño habitual del Pixel 5. No se declara revisión humana ni prueba en teléfono físico.

La verificación final del formato revisó 43 archivos Dart sin cambios pendientes y `flutter analyze` terminó sin observaciones. Se dejó instalada la aplicación normal mediante `flutter run -d emulator-5554 --no-resident`; las compilaciones finales `flutter build apk --debug` y `flutter build web --debug` completaron correctamente. La compilación web corresponde a la demostración en memoria. Registros adicionales: `build/ejecucion-finanzas.log` y `build/compilacion-finanzas-web.log`. `git diff --check` no encontró errores de espacios.

Capturas con datos ficticios: [gastos registrados](evidencias/finanzas/gastos.png), [selección de período e ingresos](evidencias/finanzas/reporte-periodo.png) y [utilidad resultante](evidencias/finanzas/reporte-utilidad.png).

## Recorrido

1. Ejecutar `flutter run -d emulator-5554`.
2. Abrir Gastos → Registrar gasto → seleccionar fecha → concepto «Servicio de energía» → categoría Servicios → valor 80000 → Guardar gasto.
3. Comprobar el gasto en el listado. Cancelar otro formulario no crea registros.
4. Abrir Reportes → seleccionar Desde y Hasta → Consultar reporte. Las fechas incluyen ambos días completos en Colombia.
5. Consultar los importes y desplazarse hasta el resultado. Abrir Ventas y expandir una venta para revisar su costo asignado y utilidad bruta.

Para repetir las pruebas:

```powershell
dart format lib test integration_test test_driver
flutter analyze
flutter test
flutter test integration_test/finanzas_test.dart -d emulator-5554
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/finanzas_test.dart -d emulator-5554 --dart-define=CAPTURAS=true
flutter build apk --debug
```

## Pendientes

Autenticación y autorización remotas, administración de categorías de HU-11, clientes, proveedores, gráficos y sincronización permanecen en el backlog. La elección de FIFO o promedio ponderado, el crédito, los impuestos y las devoluciones requieren reglas adicionales del equipo. La revisión humana, la validación con usuarios y Android físico siguen pendientes.
