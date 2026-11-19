# Funcionalidades de FinanzAsist

Informe de la versión actual

Versión de la aplicación 1.0.0+1 · Corte del informe 12 de noviembre de 2026
Equipo Los Juanchos · Ingeniería Informática · UNIPAZ

### Propósito y alcance

Este documento describe las funciones implementadas en la versión local de FinanzAsist para Android. Permite al equipo y a las personas interesadas conocer qué tareas puede realizar la aplicación, cómo se relacionan sus módulos y cuáles son sus límites actuales. Incluye el registro de empresas y las sesiones incorporados en esta entrega.

La aplicación permite registrar una empresa y su propietario, gestionar productos y existencias, confirmar compras y ventas, registrar gastos y consultar resultados por período. Los datos se conservan en el dispositivo. Las cuentas y los registros todavía no se comparten entre equipos.

### Funciones disponibles

| Módulo | Historia | Alcance implementado |
| --- | --- | --- |
| Cuentas y sesiones | HU-01 y 02 | Registro de empresa y propietario e inicio y cierre de sesión locales. |
| Productos | HU-04 y 05 | Registro, edición, catálogo y detalle de productos. |
| Existencias | HU-06 | Apertura de inventario, ajustes y consulta de movimientos. |
| Compras | HU-07 | Registro e historial con entrada de unidades al inventario. |
| Ventas | HU-08 | Registro, descuento, control de saldo e historial. |
| Costos históricos | HU-09 | Precio cobrado, costo asignado y utilidad de cada venta. |
| Gastos | HU-10 | Registro y consulta de gastos operativos. |
| Reportes | HU-14 | Resultados numéricos por período con ingresos, egresos y utilidades. |

Estas historias y HU-03 cuentan con implementación local, incluyendo usuarios por empresa y permisos comprobados en cada operación. La revisión humana, la validación con usuarios y el estado de las tarjetas de GitHub son pasos distintos de la existencia del código.

## Cuentas productos e inventario

### Registro de empresa e inicio y cierre de sesión

El acceso normal de Android comienza en Inicia sesión. Crear cuenta de empresa registra una empresa y una cuenta propietaria en una sola operación, y después abre su inventario.

- Se solicitan nombre de empresa, nombre del propietario, correo electrónico, contraseña y confirmación. La contraseña admite de 8 a 128 caracteres.

- El correo es único en este dispositivo; se ignoran las mayúsculas y los espacios exteriores. Los campos incompletos y los correos duplicados muestran una indicación y conservan los demás datos.

- Una contraseña incorrecta impide entrar. El menú Cuenta de empresa muestra la empresa y el correo y permite cerrar sesión.

- Al salir se retiran las pantallas privadas y se invalida la sesión anterior. Reiniciar la aplicación exige iniciar sesión de nuevo; las cuentas permanecen guardadas.

La primera cuenta vincula los datos anteriores de negocio-local, si existen. Sus responsables históricos se conservan. Las demás cuentas crean empresas vacías. Esta entrega permite un propietario por empresa y empleados con roles Encargado de inventario, Vendedor y Consulta. El propietario puede crearlos, activar o desactivar sus cuentas, cambiar su rol y restablecer sus contraseñas. No hay invitaciones ni recuperación por correo.

### Registro y edición de productos

- Crear productos con nombre, costo de compra y precio de venta en pesos colombianos. Cada producto recibe un identificador y comienza con cero unidades.

- Consultar el catálogo y el detalle con nombre, existencias, costo y precio; identificar productos agotados y actualizar la consulta.

- Editar nombre, costo y precio sin modificar las cantidades ni recalcular operaciones históricas. El nombre es obligatorio y los importes no pueden ser negativos.

### Existencias y movimientos

- Registrar existencias iniciales cuando el producto todavía no tiene movimientos. La apertura incorpora unidades y deja trazabilidad del responsable, la fecha y el motivo.

- Registrar ajustes positivos o negativos con motivo. La aplicación impide un resultado de existencias negativas.

- Consultar el historial de movimientos de cada producto con tipo, variación, saldo, fecha, motivo y responsable. Las compras suman unidades y las ventas las descuentan.

## Compras ventas y costos

### Registro y consulta de compras

El módulo Compras permite preparar una entrada de mercancía con varios productos y revisar su resumen antes de confirmarla.

- Seleccionar productos existentes y completar cantidades enteras positivas y valores unitarios. El formulario evita repetir un producto en varias líneas.

- Calcular subtotales y total de la compra y confirmar la operación junto con su actualización de inventario.

- Consultar las compras confirmadas y sus detalles. Cada operación conserva su identificador, fecha, empresa y usuario.

Cancelar o volver antes de confirmar no guarda la compra. El borrador puede mantenerse durante una pausa mientras el formulario y el proceso sigan abiertos; no se garantiza su recuperación si Android termina la aplicación.

### Registro y consulta de ventas

- Agregar varios productos, cantidades y precios unitarios y aplicar un descuento como importe total en pesos, entre cero y el subtotal.

- Revisar el resumen y confirmar. La venta y la salida de unidades se registran juntas; se rechaza una venta sin existencias suficientes.

- Consultar el historial y el detalle de ventas, incluidos precios cobrados, descuento, ingreso neto, costo de ventas y utilidad bruta.

El botón se bloquea mientras se confirma. Cada solicitud tiene un identificador que permite reintentar la misma confirmación sin duplicar el registro ni volver a modificar las existencias.

### Conservación de precios y costos

Cada venta guarda una copia del nombre y precio de los productos y del costo unitario asignado al confirmarla. Editar después el catálogo no cambia sus importes históricos ni los reportes que se calculan a partir de ellos.

El método actual toma el costo del catálogo al confirmar la venta. No implementa FIFO ni promedio ponderado. Las operaciones consideradas son al contado, sin impuestos, devoluciones ni gestión de cuentas por cobrar o pagar.

### Ejemplo de actualización del inventario

Si un producto comienza con 10 unidades, se compran 5 y se venden 4, la existencia final es de 11 unidades. El movimiento de compra, el de venta y sus saldos quedan disponibles para consulta.

## Gastos y reportes financieros

### Registro y consulta de gastos

- Registrar fecha, concepto, categoría y valor positivo del gasto. El usuario y la empresa se asocian a partir de la sesión.

- Elegir categorías básicas de Servicios, Arriendo, Transporte, Insumos, Personal y Otros y consultar los gastos guardados.

- Validar los campos obligatorios y los importes. Cancelar no guarda; la confirmación protege frente a doble envío y reintentos.

Los gastos no cambian las existencias. Esta versión no ofrece edición ni eliminación de gastos desde sus pantallas y las categorías todavía no son administrables.

### Consulta de resultados por período

En Reportes se seleccionan las fechas Desde y Hasta y se consulta el resultado de la empresa. Los dos días se incluyen completos, con referencia de Colombia, UTC-5. La aplicación rechaza un intervalo invertido y retira el resultado anterior al cambiar las fechas.

| Indicador | Regla utilizada |
| --- | --- |
| Ingresos netos | Ventas antes de descuentos menos descuentos. |
| Egresos | Compras más gastos operativos. |
| Costo de ventas | Unidades vendidas por costo unitario histórico asignado. |
| Utilidad bruta | Ingresos netos menos costo de ventas. |
| Utilidad resultante | Utilidad bruta menos gastos operativos. |

El reporte también presenta ventas antes de descuentos, descuentos, compras y gastos. Sin operaciones muestra valores en cero; un período con gastos y sin ingresos puede presentar pérdida. Los estados de carga, error y reintento permiten recuperar la consulta.

### Ejemplo de cálculo

Con ventas de 1.000.000 COP y descuentos de 100.000 COP, los ingresos netos son 900.000 COP. Si el costo de ventas es 500.000 COP y los gastos son 150.000 COP, la utilidad bruta es 400.000 COP y la resultante, 250.000 COP. Con compras de 600.000 COP, los egresos son 750.000 COP.

Las compras no se descuentan otra vez de la utilidad, porque el costo de los productos vendidos ya se reconoce mediante su costo histórico. Estos resultados describen las reglas implementadas; no incluyen una contabilidad tributaria completa.

## Datos plataforma y validación

### Conservación y separación de información

Android conserva cuentas, productos, operaciones, movimientos y gastos en SQLite. Los registros sobreviven al cierre de sesión y al reinicio de la aplicación. La base migra a la versión 6 sin borrar los datos anteriores.

Las consultas y escrituras del repositorio comprueban la sesión y la cuenta activa y filtran por empresa. Las contraseñas no se guardan en texto plano: se conserva una derivación PBKDF2 con sal aleatoria. La base local no está cifrada; utiliza el almacenamiento privado de Android.

Cerrar sesión impide reutilizar el repositorio anterior para leer o escribir. La sesión comprueba cuenta activa, empresa, usuario y rol vigente. Cada operación exige su permiso; desactivar un empleado o cambiar su rol invalida la sesión abierta en su siguiente operación.

### Validación de datos y uso de la interfaz

- Navegación entre Inventario, Compras, Ventas, Gastos y Reportes, con formularios desplazables, mensajes de validación, indicadores de carga y opciones de reintento.

- Calendarios en español y valores monetarios presentados en COP. Los cálculos se realizan en centavos enteros; los formularios aceptan hasta dos decimales, sin separadores de miles.

- Confirmaciones atómicas de operaciones y existencias, control de saldos y protección frente a registros duplicados al reintentar.

### Demostración y plataformas

La plataforma funcional con persistencia y cuentas es Android. La demostración de Android y la versión web utilizan datos ficticios en memoria y los identifican en pantalla. Sus cambios se pierden al reiniciar y no registran cuentas. En depuración hay escenarios de contenido, vacío, error y carga; cambiarlos reinicia la simulación.

### Base técnica y comprobaciones

El proyecto utiliza Flutter y Dart, separación de responsabilidades mediante vistas, modelos y modelos de vista, y repositorios para el acceso a datos. El entorno comprobado utiliza Flutter 3.47.1, Dart 3.13.1 y un emulador Android 16, API 36.

La suite general aprobó 101 pruebas y el analizador de Flutter no reportó problemas. El recorrido de integración de cuentas verificó registro, acceso inválido, corrección, reingreso, conservación de datos y retiro de rutas privadas. Las capturas revisadas corresponden a la superficie Flutter. La revisión humana y la validación con usuarios siguen pendientes.

## Cobertura y funciones pendientes

Esta versión cuenta con implementación local de HU-01, HU-02, HU-04, HU-05, HU-06, HU-07, HU-08, HU-09, HU-10 y HU-14. El registro e inicio de sesión de este corte no incluyen un servicio remoto. La siguiente relación identifica el trabajo que todavía falta.

| Historia | Estado | Funcionalidad por completar |
| --- | --- | --- |
| HU-03 | Implementada localmente | Usuarios por empresa con propietario, encargado de inventario, vendedor y consulta. El propietario gestiona empleados, gastos y respaldos; el encargado registra productos, existencias y compras; el vendedor registra y consulta solo sus ventas, sin costos; consulta solo lee. Administrador único del dispositivo: lo crea el primero en un teléfono sin cuentas y, si ya hay empresas, con la autorización de un propietario activo; panel por empresa para activar/desactivar y restablecer claves de propietarios y trabajadores, sin acceso a datos de negocio ni respaldos. Permisos verificados en SQLite y reflejados en la interfaz; esquema v7 conserva cuentas y guías de v6. |
| HU-11 | Pendiente | Crear categorías y subcategorías y filtrar por ellas. |
| HU-12 | Pendiente | Clientes, asociación con ventas e historial por cliente. |
| HU-13 | Pendiente | Proveedores, asociación con compras y consultas por proveedor. |
| HU-15 | Pendiente | Gráficos financieros y tendencias visuales. |
| HU-16 | Pendiente | Alertas por variaciones de gastos o utilidad y umbrales. |
| HU-17 | Pendiente | Proyecciones financieras con método y supuestos definidos. |
| HU-18 | Pendiente | Simulación de cambios separada de los registros reales. |
| HU-19 | Pendiente | Asistente financiero de consultas respaldadas por los datos. |
| HU-20 | Pendiente | Sincronización con servidor y resolución de conflictos. |

### Otros límites de esta entrega

No hay verificación ni recuperación por correo, cambio de contraseña del propietario ni edición de cuentas y empresas. El propietario sí puede restablecer contraseñas de empleados. Sí existe la exportación y restauración manual por empresa: el propietario respalda solo sus datos y cuentas, restaura su misma empresa sin alterar otras ni al administrador, y desde el acceso se puede agregar una empresa ausente si sus correos no chocan con cuentas existentes. Tampoco hay anulación o edición de compras y ventas confirmadas, devoluciones ni edición o eliminación de gastos. Eliminar los datos de Android o desinstalar la aplicación puede eliminar los registros locales.

### Documentación de referencia

El informe se basa en el código local de lib/, la versión declarada en pubspec.yaml y la documentación del repositorio: README.md, Docs/manual-usuario.md, Docs/validacion-acceso.md, Docs/validacion-finanzas.md y los criterios de Docs/criterios/. Para instrucciones de uso y ejemplos por pantalla, consultar el manual de usuario.

El corte describe la rama local examen/sprint1-tecnico. No certifica que estas funciones estén publicadas en GitHub ni que las tarjetas del Kanban estén terminadas. El informe de estado del tablero del 11 de noviembre es una consulta histórica; el acceso local se añadió después.
