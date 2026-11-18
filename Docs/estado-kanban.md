# Estado del Kanban y funciones de FinanzAsist

**Fecha de consulta:** 11 de noviembre de 2026, Colombia. Esta es una fotografía del estado consultado; el tablero puede cambiar después.

**Ampliación local posterior · 12 de noviembre:** se añadieron registro de empresa y propietario e inicio/cierre de sesión locales (HU-01/HU-02). Véase [validación de acceso](validacion-acceso.md). El análisis de abajo conserva el corte del día 11; esta ampliación no cambia las columnas observadas en GitHub.

Fuentes: [tablero público del proyecto 1](https://github.com/users/Jose2005M/projects/1), [issues del repositorio](https://github.com/Jose2005M/FinanzAsist/issues), [código publicado en main](https://github.com/Jose2005M/FinanzAsist/tree/main/lib), archivos locales de `lib/` y [validación técnica local](validacion-finanzas.md).

Se leyeron las 20 tarjetas visibles del tablero, sus columnas y campos, los issues públicos, el PR #30 y el árbol de archivos publicado. No se modificaron tarjetas, issues, ramas ni permisos en GitHub. Esta consulta no ejecutó otra vez las pruebas de la aplicación.

## Resultado principal

La aplicación local tiene implementación de **ocho historias: HU-04 a HU-10 y HU-14**. El código publicado en GitHub contiene el catálogo de productos y el inventario con datos simulados. Los cambios posteriores siguen modificados o sin seguimiento en la carpeta local de la rama `examen/sprint1-tecnico`; no forman parte de los commits publicados.

El [PR #30](https://github.com/Jose2005M/FinanzAsist/pull/30) sí fue fusionado en `main`: no está pendiente. Su commit de integración es `d349fc36e53540ce2611d34b6b3b6e7eedf79647`. Esa integración corresponde al catálogo e inventario simulados, no a los nuevos módulos locales.

Que una función esté implementada localmente no significa que su tarjeta cumpla la Definición de Terminado del equipo. Siguen pendientes la revisión y las evidencias humanas indicadas en los informes.

## Distribución real del tablero

| Columna | Tarjetas | Historias |
| --- | ---: | --- |
| BackLog | 15 | HU-01, HU-02, HU-03, HU-09, HU-10, HU-11, HU-12, HU-13, HU-14, HU-15, HU-16, HU-17, HU-18, HU-19 y HU-20. |
| Listo | 1 | HU-08. |
| En desarrollo | 2 | HU-06 y HU-07. |
| En revision | 2 | HU-04 y HU-05. |
| En Dispositivo | 0 | Ninguna. |
| Hecho | 0 | Ninguna. |

Los 20 issues representados siguen abiertos. El repositorio tiene 29 issues abiertos en total; las otras entradas incluyen hitos, «Tipo», «historias» y otro issue titulado HU-01, que no forman parte de estas 20 tarjetas.

## Funciones implementadas en la copia local

| Historia y tarjeta | Estado del Kanban | Qué existe localmente | Qué está publicado en GitHub |
| --- | --- | --- | --- |
| [HU-04 · #12](https://github.com/Jose2005M/FinanzAsist/issues/12) | En revision | Registro y edición de nombre, costo y precio; validación por campo; conservación de id y unidades. | Catálogo funcional sobre un repositorio en memoria. La persistencia posterior no está publicada. |
| [HU-05 · #13](https://github.com/Jose2005M/FinanzAsist/issues/13) | En revision | Consulta de existencias, agotados, detalle y actualización tras movimientos, compras y ventas. | Lista y detalle con estados de carga, vacío y error; datos simulados. No integra compras ni ventas publicadas. |
| [HU-06 · #14](https://github.com/Jose2005M/FinanzAsist/issues/14) | En desarrollo | Apertura y ajustes con motivo, fecha y responsable; movimientos e impedimento de saldo negativo. | No está implementada en el código publicado. |
| [HU-07 · #15](https://github.com/Jose2005M/FinanzAsist/issues/15) | En desarrollo | Compras con varios productos, resumen, confirmación y aumento de inventario sin duplicados. | No está implementada en el código publicado. |
| [HU-08 · #16](https://github.com/Jose2005M/FinanzAsist/issues/16) | Listo | Ventas con varios productos, descuento total, comprobación de existencias y reducción del inventario. | No está implementada en el código publicado. |
| [HU-09 · #17](https://github.com/Jose2005M/FinanzAsist/issues/17) | BackLog | Conservación de precios y costos históricos; costo de ventas y utilidad bruta. Usa el costo del catálogo al confirmar. | No está implementada en el código publicado. |
| [HU-10 · #18](https://github.com/Jose2005M/FinanzAsist/issues/18) | BackLog | Gastos con fecha, concepto, categoría y valor; validación, historial y persistencia. | No está implementada en el código publicado. |
| [HU-14 · #22](https://github.com/Jose2005M/FinanzAsist/issues/22) | BackLog | Reportes por período con ingresos, egresos, compras, gastos, costo histórico y utilidades; límites de fecha de Colombia. | No está implementada en el código publicado. |

La validación local documenta **87 pruebas aprobadas**, compilación Android y web y un recorrido Android de gastos/reportes. Es evidencia del avance local registrado el 10 de noviembre; no equivale a pruebas ejecutadas sobre la rama remota actual.

## Historias que todavía no están completas en la aplicación local

Todas estas tarjetas están en BackLog:

| Historia y tarjeta | Qué falta |
| --- | --- |
| [HU-01 · #29](https://github.com/Jose2005M/FinanzAsist/issues/29) | Registro de cuenta y empresa desde la aplicación. La sesión actual se crea localmente; no hay pantalla de registro. |
| [HU-02 · #10](https://github.com/Jose2005M/FinanzAsist/issues/10) | Inicio y cierre de sesión con credenciales y protección de pantallas. |
| [HU-03 · #11](https://github.com/Jose2005M/FinanzAsist/issues/11) | Roles, permisos y autorización real. Filtrar los datos por empresa en el repositorio no sustituye estas funciones. |
| [HU-11 · #19](https://github.com/Jose2005M/FinanzAsist/issues/19) | Crear categorías/subcategorías, clasificarlas y filtrar por ellas. Hay categorías fijas para gastos, pero no la administración requerida por HU-11. |
| [HU-12 · #20](https://github.com/Jose2005M/FinanzAsist/issues/20) | Registro de clientes, asociación con ventas e historial por cliente. |
| [HU-13 · #21](https://github.com/Jose2005M/FinanzAsist/issues/21) | Registro de proveedores, asociación con compras y consultas por proveedor. |
| [HU-15 · #23](https://github.com/Jose2005M/FinanzAsist/issues/23) | Panel de gráficos y tendencias. Los indicadores numéricos ya existen en Reportes, pero no hay gráficos. |
| [HU-16 · #24](https://github.com/Jose2005M/FinanzAsist/issues/24) | Alertas por aumentos de gastos o disminución de utilidad, comparación de períodos y umbrales. |
| [HU-17 · #25](https://github.com/Jose2005M/FinanzAsist/issues/25) | Proyecciones financieras con un método y supuestos definidos. |
| [HU-18 · #26](https://github.com/Jose2005M/FinanzAsist/issues/26) | Simulador de cambios en ventas, costos y gastos separado de los registros reales. |
| [HU-19 · #27](https://github.com/Jose2005M/FinanzAsist/issues/27) | Asistente financiero de consultas respaldadas por datos y permisos. |
| [HU-20 · #28](https://github.com/Jose2005M/FinanzAsist/issues/28) | Sincronización con servidor, estados pendientes/sincronizados/conflictos y resolución de conflictos. El almacenamiento local actual no completa HU-20. |

Son doce historias pendientes de completar. Esta cuenta no debe convertirse directamente en un porcentaje de avance: tienen esfuerzos distintos y la revisión del equipo sigue pendiente.

## Base técnica

Los 22 elementos base del README incluyen TEC-01 y TEC-02, pero estas dos tareas técnicas no aparecen entre las 20 tarjetas visibles del tablero consultado.

- **TEC-01, parcial:** existen proyecto Flutter, ramas, pruebas y una integración mediante PR. La API de GitHub devuelve `protected: false` para las ramas `main` y `examen/sprint1-tecnico`; falta la protección requerida para `main` por TEC-01.
- **TEC-02, parcial en local:** SQLite conserva productos, compras, ventas, gastos y movimientos; hay transacciones y separación por empresa. La autorización real de usuarios sigue pendiente. GitHub todavía publica el repositorio simulado en memoria.

## Aspectos del tablero por completar

1. **Publicación y trazabilidad del avance local.** Preparar commits y PR con las pruebas y capturas existentes. Vincular las tarjetas correspondientes: ninguna de las 20 tiene un PR enlazado en el campo de relaciones del tablero consultado.
2. **Criterios de aceptación en los issues.** En #12, #13, #14, #16 y #17 están sin responder; en #15, #18 y #22 solo aparece la plantilla «Dado ... cuando ... entonces ...». Los archivos `.feature` sí contienen criterios: deben vincularse o incorporarse a las tarjetas.
3. **Responsables y planificación.** Las 20 tarjetas carecen de responsables asignados. El proyecto consultado no tiene campos personalizados de Tipo, Prioridad, Épica, Puntos o Sprint; la prioridad escrita en el cuerpo de un issue no es un campo de Projects.
4. **Vistas y tareas técnicas.** Existen «View 1» en formato tablero y «Vista 2» en formato tabla. Falta configurar y nombrar las vistas Backlog, Sprint actual y Por épica descritas en el README, y representar TEC-01/TEC-02.
5. **Identificación de tarjetas.** Corregir los títulos con el prefijo de plantilla «HU-XX» y revisar el solapamiento entre [#9](https://github.com/Jose2005M/FinanzAsist/issues/9) y [#29](https://github.com/Jose2005M/FinanzAsist/issues/29), ambos referidos a HU-01, antes de decidir cuál conservar.

Los límites WIP configurados son Listo 5, En desarrollo 4, En revision 2 y En Dispositivo 2. No están superados, pero En revision ya está en su límite. La actualización del avance debe hacerse por lotes, terminando revisiones antes de introducir más tarjetas en esa columna.

No se recomienda mover de forma automática todas las historias implementadas a Hecho: el equipo exige revisión, evidencia en Android físico e integración verificada. El tablero debe reflejar esos pasos además de la existencia del código.
