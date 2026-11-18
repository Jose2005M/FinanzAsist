# Diseño del acceso de FinanzAsist

Actualización del 12 de noviembre de 2026. La referencia visual es la imagen de inicio de sesión facilitada por el usuario. El alcance comprende el inicio de sesión y su formulario de registro asociado.

## Identidad y composición

El acceso utiliza fondo crema, acentos dorados y texto oscuro. La marca combina tres barras ascendentes, una flecha y el nombre FinanzAsist. El símbolo se dibuja con `CustomPainter`, de modo que conserva su nitidez sin una imagen de fondo ni dependencias adicionales.

El título y la explicación preceden un panel con etiquetas visibles, campos con iconos, acción principal dorada y acceso al registro. Un aviso separado explica que los datos permanecen en el dispositivo y que no hay sincronización ni recuperación por correo. El registro conserva la misma identidad y utiliza una cabecera más compacta para dar espacio a los campos.

| Elemento | Decisión |
| --- | --- |
| Fondo | `#FFF3D6`. |
| Panel y campos | `#FFFAEC`, panel con radio de 24 y sombra suave desplazada hacia abajo. |
| Texto principal | `#20211D`. |
| Texto secundario | `#5D594F`. |
| Acción principal | `#F0B400` con texto oscuro; altura mínima de 54. |
| Foco | `#89620B`, borde de 2 y selección de texto dorada. |
| Error | `#AA3026`, acompañado de icono y mensaje. |
| Tipografía | Familia de la aplicación, campos de 16, título de acceso de 32 y ayudas de 13. Se respeta el tamaño de texto del sistema. |

El 13 de noviembre de 2026 esta identidad se extendió a toda la aplicación. El acceso hereda ahora el tema global de `TemaFinanzAsist`; la [guía compartida](../DESIGN.md) y la [validación general](diseno-general.md) documentan la ampliación.

## Ajustes de uso y accesibilidad

- Los campos tienen etiquetas persistentes y nombres para lectores de pantalla. Los iconos decorativos no se anuncian por separado.
- La contraseña permite mostrar u ocultar su contenido mediante un control con indicación accesible.
- El teclado ofrece correo, siguiente y finalizar según el campo, y se conserva el autocompletado de credenciales.
- Si hay datos inválidos, el foco y el desplazamiento se llevan al primer campo que requiere corrección. Se conservan las otras entradas.
- El contenido se desplaza y reduce la cabecera cuando aparece el teclado. La composición permite texto al doble y pantallas pequeñas sin fijar la altura del formulario.
- El botón informa que se está verificando o creando la cuenta. Durante la espera se bloquean los campos, el cambio de formulario y el envío repetido.
- El aviso de almacenamiento utiliza lenguaje directo y no incorpora acciones de recuperación que la aplicación todavía no ofrece.
- El correo se conserva al cambiar entre registro y acceso. Las contraseñas se limpian al cambiar de formulario y la vista vuelve al inicio del contenido.

## Verificación

La suite general aprobó 107 pruebas, incluidas seis comprobaciones nuevas de la interfaz. Se verificaron tamaños de 320 × 640, 360 × 800, 390 × 844 y 768 × 1024, teclado con texto al doble, foco del primer error, estados de espera, contraste, nombres accesibles y tamaño de los controles Android.

El recorrido Android de `integration_test/acceso_test.dart` aprobó registro, salida desde el menú, acceso inválido, corrección de contraseña, reingreso y retiro del historial de pantallas privadas. La prueba centra los controles y estabiliza el foco antes de pulsar para adaptarse al teclado nativo. Se utiliza una base QA independiente.

Registros locales: `build/pruebas-diseno-acceso-final.log`, `build/pruebas-interfaz-acceso-final.log` y `build/android-diseno-acceso.log`. Las capturas de revisión se guardan en `build/qa/acceso-diseno-*.png`. El análisis de Flutter y el detector de diseño finalizaron sin observaciones. Tras el último ajuste tipográfico también se repitieron las diez pruebas de interfaz.

La revisión visual incluye la referencia, la vista normal, una pantalla pequeña, el registro y el error de acceso. La validación con usuarios y la revisión en un teléfono físico quedan pendientes.

La aplicación normal se compiló, instaló y ejecutó en el emulador tras la última revisión. La [captura final de Android](evidencias/acceso/inicio-redisenado.png) muestra el resultado con los controles del sistema. La APK de depuración está en `build/app/outputs/flutter-apk/app-debug.apk`; el registro de ejecución es `build/ejecucion-diseno-acceso.log`.
