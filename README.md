# Aplicación de alumnos y productos

Aplicación Flutter con las dos secciones de la actividad. Alumnos utiliza morado y productos utiliza azul. Cada sección incluye inicio de sesión, menú, listado, registro y perfil.

## Instalación en el proyecto creado

1. Copiar las carpetas `lib` y `test` de esta entrega dentro del proyecto Flutter, reemplazando los archivos originales. Copiar también este README.
2. En la terminal de Visual Studio Code, desde la carpeta que contiene `pubspec.yaml`, ejecutar:

```bash
flutter pub add image_picker shared_preferences
flutter analyze
flutter test
flutter run -d chrome --web-port 5200
```

El puerto fijo permite volver al mismo origen del navegador y recuperar los registros locales de las ejecuciones anteriores. Si 5200 está ocupado, elegir otro puerto y usarlo en las siguientes ejecuciones.

No se reemplaza `pubspec.yaml`: el comando `flutter pub add` agrega las dos dependencias al archivo del proyecto. Esta entrega requiere Flutter 3.35 o posterior, ya que utiliza `AppBarThemeData` e `InputDecorationThemeData`. La resolución de paquetes selecciona versiones compatibles de image_picker y shared_preferences; se utiliza `SharedPreferencesAsync` de shared_preferences 2.3 o posterior.

## Accesos iniciales

| Sección | Correo | Contraseña |
| --- | --- | --- |
| A alumnos | docente@demo.com | Demo1234 |
| B productos | admin@demo.com | Demo1234 |

Los accesos son una demostración local. No hay servidor de autenticación ni envío de correos. El enlace de contraseña muestra las credenciales locales actuales. Si se cambia el correo en el perfil, ese nuevo correo se utiliza en el siguiente inicio de sesión.

## Funciones

- Inicio de sesión con validación de campos y rechazo de credenciales incorrectas.
- Menú y menú lateral para navegar entre registro, listado y perfil.
- Registro y edición de alumnos con nombre, apellido y nota entre 0 y 20.
- Estado de aprobado desde 11; esta es una regla elegida para la implementación, ya que la referencia no especifica el umbral.
- Registro y edición de productos con imagen opcional, nombre, descripción, precio no negativo y stock entero no negativo.
- Selección de imágenes del dispositivo con image_picker. Los productos iniciales tienen iconos y cada uno puede editarse para incorporar su fotografía.
- Búsqueda por nombre, eliminación con confirmación y detalle del producto al tocarlo.
- Perfil con nombre, correo, teléfono, rol y foto. Edición de los datos y cambio de foto.
- Guardado local de registros, perfiles e imágenes mediante SharedPreferencesAsync y JSON.
- Ancho máximo de 440 píxeles para visualizar el diseño móvil desde Chrome.

Los cambios se conservan en el mismo navegador y origen. Se pierden si se borran los datos del sitio o de la aplicación. El almacenamiento es adecuado para los datos de demostración de esta práctica. La sesión se solicita de nuevo al abrir la aplicación.

## Evidencias para el informe

Las capturas deben mostrar la aplicación ejecutándose. Las pantallas de instalación de Flutter y del editor no sustituyen las evidencias del funcionamiento.

| N.º | Evidencia | Cómo obtenerla |
| --- | --- | --- |
| 1 | Inicio de sesión de alumnos | Seleccionar Alumnos y capturar antes de escribir la contraseña. |
| 2 | Menú de alumnos | Ingresar con docente@demo.com y capturar las cuatro opciones. |
| 3 | Listado de alumnos | Abrir Listar alumnos; incluir nombres, notas y estados visibles. |
| 4 | Registro de alumno | Abrir el botón + del listado, completar nombre, apellido y nota; capturar antes de guardar. |
| 5 | Perfil de alumnos | Regresar al menú y abrir Perfil. |
| 6 | Inicio de sesión de productos | Cerrar sesión, volver a la selección y elegir Productos. |
| 7 | Menú de productos | Ingresar con admin@demo.com y capturar las opciones. |
| 8 | Listado de productos | Abrir Listar productos; mostrar precios y stock. |
| 9 | Registro de producto | Abrir +, seleccionar una imagen y completar los campos; capturar antes de guardar. |
| 10 | Perfil de productos | Volver al menú y abrir Perfil. |

Evidencias adicionales útiles: alumno nuevo en la lista, producto nuevo con imagen, nota fuera de rango y credencial incorrecta. Al capturar un registro nuevo desde el menú, guardar y después entrar al listado para comprobarlo.

En Chrome, ajustar el zoom al 100 %. Si la pantalla no entra completa, aumentar la altura de la ventana o utilizar una vista de dispositivo de aproximadamente 390 × 844 píxeles. Las capturas se recortan para incluir el área de la aplicación, sin tapar campos ni botones.

## Código para comentar en el informe

| Archivo y bloque | Qué explicar al costado |
| --- | --- |
| lib/main.dart — LoginPage y _login | Lectura del correo y contraseña, validación y apertura del menú cuando la cuenta corresponde a la sección. |
| lib/main.dart — MenuOptions y openPage | Asociación de cada opción con su pantalla y navegación mediante Navigator. |
| lib/main.dart — DataListPage | Filtrado de registros por nombre y construcción de los elementos del listado. |
| lib/main.dart — RecordForm y _save | Validación de los campos, creación o edición del registro y actualización de la interfaz. |
| lib/main.dart — choosePhoto y PhotoBox | Selección de la imagen, lectura de sus bytes y visualización. |
| lib/main.dart — ProfilePage y EditProfilePage | Presentación y edición de los datos del perfil. |
| lib/app_store.dart — Student.approved | Cálculo del estado con una nota mínima aprobatoria de 11. |
| lib/app_store.dart — load y _commit | Conversión de los registros a JSON y recuperación del almacenamiento local. |
| lib/app_store.dart — _enqueue | Orden de las escrituras para evitar que dos guardados sobrescriban sus cambios. |

El informe debe comentar especialmente los bloques que no se hayan trabajado en clase. Es posible agregar el código como texto seleccionable o como una captura legible del fragmento, con la explicación en la columna derecha.

## Verificación

Se incluyen pruebas para credenciales de ambas secciones, notas inválidas y límite de aprobación, creación y edición sin duplicar alumnos, eliminación, productos con stock cero, actualización de correo y navegación de acceso y cierre de sesión. Ejecutar `flutter analyze` y `flutter test` en el equipo con Flutter para conocer sus resultados. Estas pruebas no verifican la persistencia real del navegador ni el selector de imágenes; ambos se revisan al ejecutar la aplicación.

Prueba manual de persistencia: registrar un alumno y un producto, recargar la página, iniciar sesión de nuevo y comprobar que continúan en sus listados. Probar también la selección de una imagen y su recuperación después de recargar.

## Otras plataformas

La primera ejecución de esta entrega está orientada a Chrome. Para compilar en Android se necesita la configuración de Android de Flutter. Para usar la galería en una compilación iOS se debe añadir `NSPhotoLibraryUsageDescription` con una descripción del uso de las fotos en `ios/Runner/Info.plist`, según la documentación del paquete.

## Documentación

- Formularios de Flutter: https://docs.flutter.dev/cookbook/forms/validation
- Selector de imágenes oficial: https://pub.dev/packages/image_picker
- Guardado local oficial: https://pub.dev/packages/shared_preferences
