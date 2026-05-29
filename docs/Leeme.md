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
flutter run -d web-server --web-hostname localhost --web-port 8090
```

#Abre la URL que muestre Flutter, por ejemplo `http://localhost:8080`.
