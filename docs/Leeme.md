# Comandos Flutter y area Laboratorio

## Comandos utiles (desde la raiz del repo)

|                 Accion                               |    Comando                       |
|                 ------                               |   ---------                      |
|           Dependencias                               | `flutter pub get`                |
| Analisis estatico                                    | `dart analyze lib`               |
| Tests                                                | `flutter test`                   |
| Ejecutar en Chrome                                   | `flutter run -d chrome`          |
| Ejecutar en Android (dispositivo/emulador)           | `flutter run -d android`         |
| Ejecutar en iOS (simulador/dispositivo)              | `flutter run -d ios`             |
| Web con servidor propio (cualquier host por defecto) | `flutter run -d web-server`      |

### Web + ubicacion (localhost seguro)

Para que la geolocalizacion en navegador funcione con origen seguro, arranca el servidor web ligado a `localhost`:

```bash
flutter run -d web-server --web-hostname localhost --web-port 8080
```

Abre la URL que muestre Flutter, por ejemplo `http://localhost:8080`.

### Script equivalente

Desde la raiz del proyecto:

```bash
./scripts/runWebLocalhost.sh
```

Hace lo mismo que el comando anterior (cambia al directorio del repo y ejecuta Flutter con hostname y puerto fijados).

### Depuracion en VS Code / Cursor

Existe la configuracion **atlas web (localhost)** en `.vscode/launch.json` para lanzar web con esos flags sin escribirlos a mano.

---

## `lib/Pantallas/pantLaboratorio.dart`

Pantalla **Laboratorio**: un `Scaffold` sencillo con titulo y un texto centrado. Sirve como **placeholder de UI** para experimentar nuevas ideas en la app sin mezclarlas aun con el flujo principal. Se abre desde el icono de laboratorio en las pantallas de cliente y trabajador.

---

## `lib/Servicios/servicioLaboratorio.dart`

Archivo **reservado** para futuras pruebas ligadas a la pantalla Laboratorio. Hoy **no contiene clases ni funciones**: solo comentarios que aclaran que la logica de red y HTTP vive en otros servicios (`servicioAlmacenamiento.dart`, `servicioAuth.dart`, etc.). Evita que el nombre “laboratorio” se confunda con un servicio HTTP real.
