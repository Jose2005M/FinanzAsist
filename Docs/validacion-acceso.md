# Cuentas de empresas y sesiones locales

Fecha: 12 de noviembre de 2026. Rama: `examen/sprint1-tecnico`.

Actualización del 16 de noviembre de 2026: el registro acepta contraseñas de 8 a 128 caracteres a petición del usuario. El acceso conserva la compatibilidad con las contraseñas anteriores; no requiere migrar cuentas ni cambiar la derivación PBKDF2.

La comprobación de este ajuste aprobó las 23 pruebas de autenticación e interfaz, incluidos límites de longitud Unicode, rechazo de siete caracteres, registro y reingreso con ocho y cuentas con contraseñas largas. `flutter analyze --no-pub` terminó sin observaciones. El recorrido Android también aprobó registro con ocho caracteres, salida, intento incorrecto, reingreso y limpieza de rutas. Registros: `build/pruebas-clave-corta-directas.log`, `build/analisis-clave-corta-directo.log` y `build/android-clave-corta.log`. [Captura del registro actualizado](evidencias/acceso/registro-clave-8.png).

## Alcance y recorrido

HU-01 y HU-02 incorporan registro de empresa y propietario, acceso por correo y contraseña y cierre de sesión. Se implementan sobre SQLite en Android, sin un proveedor remoto configurado. La demostración y la versión web mantienen sus datos ficticios en memoria y no registran cuentas.

La pantalla **Inicia sesión** ofrece **Crear cuenta de empresa**. El registro válido abre Inventario con la empresa del propietario. El menú **Cuenta de empresa** muestra empresa y correo y permite **Cerrar sesión**. Al salir se elimina todo el navegador privado, incluso si había un detalle o formulario abierto. Volver no recupera pantallas de la cuenta anterior.

## Decisiones de cuenta y credenciales

- Campos obligatorios: nombre de empresa (2–120 caracteres), propietario (2–100), correo válido (hasta 254) y contraseña (8–128). La pantalla comprueba también la confirmación de contraseña.
- Correo único por dispositivo, normalizado con `trim` y minúsculas, con restricción única en SQLite. No se verifica por correo y no se promete recuperación.
- Una cuenta propietaria por empresa en esta entrega. No se implementan empleados, invitaciones ni roles de consulta.
- La contraseña se transforma con PBKDF2-HMAC-SHA256, 600000 iteraciones, resultado de 256 bits y sal aleatoria de 32 bytes por cuenta. Se guardan hash, sal y parámetros, sin la contraseña original. La derivación utiliza un isolate para mantener receptiva la interfaz. Referencias: [API de cryptography](https://pub.dev/documentation/cryptography/latest/cryptography/Pbkdf2-class.html) y [recomendaciones de almacenamiento de contraseñas de OWASP](https://cheatsheetseries.owasp.org/cheatsheets/Password_Storage_Cheat_Sheet.html).
- El acceso incorrecto y la cuenta inactiva devuelven el mismo mensaje. Para un correo inexistente se realiza también la derivación.
- La sesión existe en memoria. El registro inicia sesión y cerrar la aplicación requiere volver a entrar. Cerrar sesión invalida el objeto de sesión anterior; un acceso posterior emite otro objeto.

## Persistencia y conservación

`BaseDatosLocal` centraliza el esquema de SQLite en versión 3. La migración desde v2 añade `cuentas`; desde v1 crea también `gastos`. No borra las tablas existentes.

Empresa, usuario y cuenta se crean dentro de una sola transacción. Un error o correo duplicado no deja empresas ni usuarios huérfanos. La comprobación de duplicados se repite dentro de la transacción para cubrir registros simultáneos.

La primera cuenta asume la empresa anterior `negocio-local`, si existe. Esta decisión se informa antes de registrarse; los datos anteriores pertenecían a una instalación sin cuentas. No se cambia el responsable histórico. Las demás cuentas reciben identificadores de empresa nuevos. Las empresas QA con otros identificadores no se vinculan automáticamente.

Cada método del repositorio verifica la sesión y la cuenta activa dentro de su transacción y filtra por empresa. El constructor anterior permanece para datos heredados y QA; si la base tiene cuentas, deniega acceso sin sesión. Los repositorios conservados después de salir quedan bloqueados para lectura y escritura.

## Cobertura y comprobaciones

| Criterios | Evidencia |
| --- | --- |
| HU-01 CA01 | Creación asociada y hash comprobado con una derivación independiente. |
| HU-01 CA02 | Validación de datos, campos obligatorios y conservación de entradas en pantalla. |
| HU-01 CA03 | Correo normalizado único, mensaje de acceso y registro concurrente sin duplicados. |
| HU-01 CA04 | Fallo de escritura provocado con trigger; rollback de empresa, usuario y cuenta y posterior reintento. |
| HU-02 CA01 | Acceso correcto, persistencia y reapertura de cuenta con sus datos. |
| HU-02 CA02 | Contraseña incorrecta, correo inexistente y cuenta inactiva sin abrir funciones privadas. |
| HU-02 CA03 | Salida desde el menú, denegación en todos los métodos del repositorio anterior y retiro de rutas privadas. |
| Compatibilidad | Datos anteriores vinculados a la primera cuenta; empresas separadas y datos históricos conservados. |
| Interfaz | Formulario desplazable, confirmación, visibilidad de contraseña, mensajes de error y tamaños reducidos. |

Pruebas: `test/autenticacion_local_test.dart`, `test/acceso_widget_test.dart` e `integration_test/acceso_test.dart`. El recorrido Android usa una base QA independiente y la elimina al terminar; no registra cuentas en la base normal.

```powershell
flutter analyze
flutter test
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/acceso_test.dart -d emulator-5554 --dart-define=CAPTURAS=true
```

`dart format` y `flutter analyze` finalizaron sin observaciones. La suite completa `flutter test` aprobó **101 pruebas**: las 87 anteriores y 14 de acceso, formularios y migración. Registro local: `build/pruebas-acceso.log`.

El recorrido de integración pasó en el emulador Android 16, API 36: registro desde pantalla, producto de la empresa, salida desde el menú, contraseña incorrecta, corrección y reingreso, conservación del producto y salida con un detalle abierto sin recuperar la ruta privada. Registro: `build/android-acceso.log`. El foco del teclado simulado se restablece al editar de nuevo el mismo campo después de un envío; se comprueba que la nueva contraseña llegó al formulario antes de confirmar.

Las capturas se revisaron desde la superficie Flutter. El emulador presentó un diálogo de System UI sin respuesta; esta verificación no sustituye una revisión manual en un teléfono. Los recorridos anteriores ahora utilizan archivos QA separados para poder ejecutarse aunque la instalación normal tenga cuentas.

Evidencias: [acceso](evidencias/acceso/acceso-inicio.png), [registro](evidencias/acceso/acceso-registro.png), [empresa](evidencias/acceso/acceso-empresa.png) y [credenciales incorrectas](evidencias/acceso/acceso-error.png).

## Pendientes

HU-03 sigue parcial: existe aislamiento por empresa y comprobación de cuenta activa, pero no matriz de roles, usuarios adicionales ni administración de permisos. No hay servicio remoto, sincronización, verificación de correo, recuperación o cambio de contraseña. La base local no se cifra; la protección del almacenamiento depende del directorio privado de Android. La revisión humana y la validación con usuarios siguen pendientes. El tablero de GitHub no se modifica con esta implementación local.
