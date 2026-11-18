# Validación técnica de Sprint 1

Fecha: 10 de noviembre de 2026 (Colombia). Rama: `examen/sprint1-tecnico`.

Este informe conserva el corte de HU-04 a HU-08. La continuación con costos históricos, gastos, reportes y migración de SQLite se registra en [validacion-finanzas.md](validacion-finanzas.md); los pendientes de este informe se refieren al corte original.

## Alcance y decisiones

Los 19 escenarios de `criterios/HU-04.feature` a `HU-08.feature` son la referencia funcional. Los ejemplos de `FinanzAsist-sprint1.md` se conservan como escenarios complementarios. Las rutas reales son `lib/models`, `lib/screens` y `lib/viewmodels`; no se trasladó código a las carpetas previstas inicialmente para evitar romper avances del equipo.

El repositorio inicial ya implementaba HU-04 y la consulta simulada de HU-05. Esta entrega completa la integración con HU-06, HU-07 y HU-08, añade almacenamiento y mantiene el modo de demostración.

No había una tecnología de persistencia seleccionada. Se eligió SQLite mediante `sqflite`, con transacciones para guardar operación, detalle, movimientos y saldos juntos. La API del paquete y su implementación FFI para pruebas siguen la [documentación de sqflite](https://pub.dev/packages/sqflite) y la [guía de pruebas del mantenedor](https://github.com/tekartik/sqflite/blob/master/sqflite_common_ffi/doc/testing.md).

## Implementación

| Capa | Archivos principales | Responsabilidad |
| --- | --- | --- |
| Modelos | `producto.dart`, `operacion.dart`, `reglas_inventario.dart` | Productos por empresa, solicitudes inmutables, detalle histórico, movimientos y reglas compartidas. |
| Repositorios | `producto_repository.dart`, `negocio_repository.dart`, `repositorio_sqlite.dart`, `repositorio_simulado.dart` | Consultas, transacciones, idempotencia y separación de datos por empresa; simulación explícita en memoria. |
| ViewModels | `inventario_view_model.dart`, `detalle_producto_view_model.dart`, `operacion_view_model.dart`, `historial_view_model.dart` | Estados, validación, borradores, bloqueo del envío y coordinación de la actualización. |
| Views | `inventario_screen.dart`, `producto_detalle_screen.dart`, `formulario_producto_screen.dart`, `operacion_screen.dart`, `operaciones_screen.dart` | Formularios desplazables, errores por campo, resumen antes de confirmar, navegación e historiales. |

Cada confirmación recibe un identificador que se mantiene al reintentar. La misma solicitud devuelve la operación existente; si el identificador se reutiliza con otros datos, se rechaza. SQLite serializa la comprobación del saldo y la escritura dentro de una transacción. Un fallo intermedio revierte todos los cambios. Dos ventas de la última unidad no pueden confirmarse juntas contra la misma base local.

Los importes se almacenan en centavos enteros y se admiten hasta dos decimales. Las compras no modifican automáticamente el costo del catálogo; preservan su propio costo unitario. Las ventas conservan el precio cobrado, el descuento total y una copia del costo del catálogo. El método de asignación del costo y los reportes de HU-09 siguen pendientes.

La base `finanzasist.db` vive en el directorio privado de la aplicación Android. Las tablas son empresas, usuarios, productos, operaciones y movimientos. Todas las consultas incluyen la empresa y las relaciones usan claves compuestas. La sesión local se configura en el repositorio; no constituye autenticación ni autorización frente a un servidor. No se incluyen gastos ni sincronización en este sprint.

## Cobertura de aceptación

| Criterios | Evidencia automatizada |
| --- | --- |
| HU-04 CA01–CA03 | `hu04_catalogo_test.dart`, `hu04_widget_test.dart`: alta, edición conservando id y cantidad, validación por campo y doble envío. |
| HU-05 CA01–CA03 | `repositorio_simulado_test.dart`, `widget_test.dart`, `operaciones_repository_test.dart`, `operaciones_widget_test.dart`: 15 unidades, agotados y venta de 4 que deja 11 en lista y detalle. |
| HU-06 CA01–CA04 | `operaciones_repository_test.dart`, `operaciones_widget_test.dart`: apertura de 20, ajuste de −2 a 18, motivo obligatorio, fecha/responsable, rechazo de saldo negativo y de otra apertura. |
| HU-07 CA01–CA04 | Compra de 5 × 6000 = 30000 sobre 10 unidades deja 15; detalle inválido, cancelación y reintento idempotente; pruebas de repositorio y pantalla. |
| HU-08 CA01–CA05 | Venta de 2 × 10000 − 2000 = 18000 deja 8; cantidades/precios/descuentos inválidos; saldo insuficiente; competencia por la última unidad y cancelación. |
| Refinamiento móvil de HU-07 | Pausa y reanudación del ciclo de vida Flutter conservan 4 × 3500 = 14000, sin confirmar ni cambiar el inventario. No se simuló una llamada telefónica real. |
| TEC-02, alcance de Sprint 1 | Reapertura SQLite conserva productos, compras, ventas y movimientos; consultas y relaciones aisladas por empresa; un trigger que falla en la segunda línea comprueba rollback real. CA01 y CA04 no se declaran completos para gastos y autorización real. |
| Adaptación a 360 dp | Pruebas de widgets para inventario en sus cuatro estados, nombres largos, detalle, edición, apertura, ajustes, compras y ventas; compra con espacio de teclado simulado. |

## Comprobaciones ejecutadas

| Comando | Resultado observado |
| --- | --- |
| `dart format lib test integration_test test_driver` | Ejecutado satisfactoriamente. |
| `flutter analyze` | Sin observaciones. |
| `flutter test` | 59 pruebas aprobadas. |
| `flutter build apk --debug` | APK de depuración compilada correctamente. |
| `flutter build web --debug` | Compilación web completada; conserva la demostración en memoria. |
| `flutter devices` | Emulador Pixel 5, `emulator-5554`, Android 16/API 36 detectado. |
| `flutter test integration_test/sprint1_test.dart -d emulator-5554` | 1 prueba aprobada; recorrido completo y reapertura de SQLite, 25 segundos de ejecución de prueba (sin incluir compilación e instalación). |
| `flutter run -d emulator-5554 --no-resident` | Compilación, instalación, arranque de Flutter y sincronización completados. |
| `flutter drive --driver=test_driver/integration_test.dart --target=integration_test/sprint1_test.dart -d emulator-5554 --dart-define=CAPTURAS=true` | Recorrido Android aprobado nuevamente, con siete capturas de la superficie Flutter exportadas y revisadas. |
| `git diff --check` | Sin errores de espacios. |

Registros locales de esta sesión: `build/pruebas-sprint1.log`, `build/android-sprint1.log`, `build/capturas-android.log`, `build/ejecucion-final-android.log`, `build/compilacion-final-android.log` y `build/compilacion-web.log`. `build/` está ignorado por Git. Las compilaciones mostraron advertencias del entorno Java/SDK XML y una recomendación de Flutter sobre Wasm; terminaron correctamente. El detector mecánico de Impeccable se ejecutó sobre las pantallas modificadas y devolvió `[]`.

La captura del dispositivo encontró un aviso «System UI isn't responding», que persistió tras reiniciar en frío el emulador. Las pruebas y las siete capturas internas de Flutter sí completaron el recorrido. Estas imágenes permiten revisar la aplicación sin el aviso superpuesto; no prueban el funcionamiento del teclado nativo ni sustituyen la interacción manual. Esa revisión queda limitada por el estado de Android System UI. El espacio del teclado sí se comprobó por separado en pruebas de widgets.

Capturas conservadas en Git, con datos ficticios de QA y tamaño habitual del Pixel 5 (la comprobación a 360 dp se hizo en widgets): [resumen de compra](evidencias/sprint1/compra-resumen.png), [resumen de venta](evidencias/sprint1/venta-resumen.png) e [inventario final con 11 unidades](evidencias/sprint1/inventario-once.png). Las otras cuatro se pueden regenerar con el comando de capturas.

## Recorrido reproducible

1. `flutter pub get`; ejecutar `flutter devices`. Si es necesario, `flutter emulators --launch Pixel_5`.
2. `flutter run -d emulator-5554`: inicia el negocio local vacío si no existen datos previos.
3. Inventario → **+** → nombre, costo 6000 y precio 10000 → **Guardar producto**.
4. Detalle → **Registrar existencias iniciales** → 20 y motivo «Inventario de apertura» → revisar → confirmar.
5. **Ajustar existencias** → −10 y motivo «Diferencia de conteo» → revisar → confirmar. Quedan 10.
6. Volver a Inventario → Compras → Registrar compra → producto, 5 unidades, costo 6000 → revisar total 30000 → confirmar. Quedan 15.
7. Volver → Ventas → Registrar venta → producto, 4 unidades, precio 10000, descuento total 2000 → revisar total 38000 → confirmar. Quedan 11.
8. Revisar inventario, detalle y movimientos. Expandir los registros de compras/ventas para consultar sus valores históricos. Cerrar y abrir la aplicación para comprobar persistencia.

## Pendientes y límites

- Revisión y aprobación de otra persona del equipo, validación con dos usuarios reales y prueba en Android físico. La automatización no sustituye estas condiciones de la Definición de Terminado.
- RC-01: tres mediciones con 200 productos en el Android del equipo. No se infieren tiempos a partir de pruebas en el computador.
- Acceso autenticado, autorización remota, gastos, método de costeo, reportes y sincronización corresponden al backlog posterior. No se declara TEC-02 completo.
- El borrador permanece en el formulario durante una pausa; su recuperación tras finalizar el proceso no forma parte del refinamiento acordado.
- PR, revisión, publicación, fusión y cambios en GitHub Projects no se ejecutaron. Los cambios permanecen locales para revisión.
