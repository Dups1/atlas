# Configuración de Firebase para Fixi

Esta guía configura una infraestructura propia para ejecutar Fixi. No reutilices el proyecto Firebase, las cuentas de servicio ni los archivos de configuración de otra instalación.

## Requisitos

- Una cuenta de Google con permiso para crear un proyecto Firebase.
- [Firebase CLI](https://firebase.google.com/docs/cli) instalada e iniciada con `firebase login`.
- Flutter y Dart instalados.
- FlutterFire CLI:

```bash
dart pub global activate flutterfire_cli
```

Si el comando `flutterfire` no está disponible después de instalarlo, agrega el directorio de ejecutables globales de Dart a tu `PATH` según tu sistema operativo.

## 1. Crear y registrar el proyecto

1. Crea un proyecto desde la [consola de Firebase](https://console.firebase.google.com/).
2. Desde la raíz del repositorio, inicia sesión y configura las plataformas que usarás:

   ```bash
   firebase login
   flutterfire configure --project=<tu-firebase-project-id>
   ```

3. Selecciona Android, iOS y/o web según tu entorno de desarrollo. FlutterFire generará o actualizará los archivos de configuración de cada plataforma y `lib/firebaseOptions.dart`.

Si cambias el identificador de paquete de Android o iOS, registra el nuevo identificador en Firebase y ejecuta de nuevo `flutterfire configure`.

## 2. Habilitar Authentication

1. Abre **Firebase Console → Authentication → Sign-in method**.
2. Habilita **Email/Password**.
3. Obtén la Web API Key del proyecto desde la configuración general y úsala como `FIREBASE_API_KEY` en `backend-atlas/.env`.

La aplicación autentica correo y contraseña mediante el backend y luego sincroniza Firebase Auth con un token personalizado. Por ello, tanto la Web API Key como la cuenta de servicio del backend deben pertenecer al mismo proyecto Firebase.

## 3. Crear Firestore y desplegar sus reglas

1. Abre **Firebase Console → Firestore Database** y crea la base de datos en la ubicación que prefieras.
2. Desde la raíz del repositorio, despliega las reglas incluidas:

   ```bash
   firebase deploy --only firestore:rules --project=<tu-firebase-project-id>
   ```

Las reglas de [`../firestore.rules`](../firestore.rules) permiten lecturas autenticadas y restringidas para conversaciones, mensajes y llamadas. El backend, mediante Firebase Admin SDK, realiza las operaciones sensibles de creación y actualización.

## 4. Crear la cuenta de servicio para el backend

1. Abre **Firebase Console → Configuración del proyecto → Cuentas de servicio**.
2. Genera una nueva clave privada para una cuenta de servicio.
3. Conserva el JSON en un lugar seguro y agrega su contenido en una sola línea a `backend-atlas/.env`:

   ```dotenv
   FIREBASE_SERVICE_ACCOUNT='<JSON completo de la cuenta de servicio>'
   ```

Nunca subas este JSON al repositorio, lo incluyas en capturas de pantalla ni lo envíes por mensajería sin un canal seguro. Si se filtra, revoca la clave desde Google Cloud o Firebase y crea una nueva.

## 5. Habilitar Vertex AI, si usarás el asistente

El backend usa la cuenta de servicio de Firebase para solicitar respuestas a Vertex AI.

1. Abre el proyecto de Google Cloud vinculado con Firebase.
2. Habilita la API de Vertex AI.
3. Otorga a la cuenta de servicio usada en `FIREBASE_SERVICE_ACCOUNT` un rol con acceso a Vertex AI, como **Vertex AI User**.
4. Define `VERTEX_MODEL` y, si es necesario, `VERTEX_PROJECT_ID` y `VERTEX_LOCATION` en `backend-atlas/.env`.

Sin esta configuración, el backend no completa su inicialización actual porque `VERTEX_MODEL` es obligatorio.

## 6. Configurar Firebase Cloud Messaging

Fixi usa Firebase Cloud Messaging (FCM) para apoyar el flujo de llamadas en Android e iOS.

- **Android:** conserva el archivo `android/app/google-services.json` generado por FlutterFire para tu proyecto.
- **iOS:** conserva `ios/Runner/GoogleService-Info.plist` y configura una clave o certificado APNs en **Firebase Console → Project settings → Cloud Messaging** antes de probar notificaciones en un dispositivo real.
- **Web:** FlutterFire generará la configuración web necesaria para inicializar Firebase. El flujo de llamadas de voz de Fixi se orienta a plataformas nativas.

En el dispositivo, acepta los permisos de notificaciones y micrófono cuando la aplicación los solicite.

## 7. Comprobación

1. Configura el backend con `FIREBASE_SERVICE_ACCOUNT` y `FIREBASE_API_KEY` del mismo proyecto.
2. Arranca el backend desde `backend-atlas`:

   ```bash
   npm ci
   npm start
   ```

3. Ajusta temporalmente `urlBase` en `lib/Servicios/configBackend.dart` para que apunte a tu backend local o desplegado.
4. Desde la raíz, ejecuta la aplicación:

   ```bash
   flutter pub get
   flutter run -d chrome
   ```

5. Registra una cuenta de prueba y confirma que se crea una sesión. Para validar mensajes, llamadas o perfiles, usa al menos dos cuentas de prueba.

## Solución de problemas

| Síntoma | Revisión recomendada |
| --- | --- |
| `Firebase.initializeApp` falla | Ejecuta nuevamente `flutterfire configure` y confirma que los archivos generados pertenecen a tu proyecto. |
| El backend no inicia al leer la cuenta de servicio | Revisa que `FIREBASE_SERVICE_ACCOUNT` contenga JSON válido en una sola línea. |
| Inicio de sesión devuelve error | Confirma que Email/Password esté habilitado y que `FIREBASE_API_KEY` corresponda al mismo proyecto. |
| Firestore responde `permission-denied` | Despliega `firestore.rules`, inicia sesión y verifica que los usuarios sean participantes de la conversación o llamada. |
| No llegan notificaciones de llamada | Revisa permisos del dispositivo, configuración FCM y APNs en iOS; prueba primero en Android o iOS nativo. |

Para las credenciales de Agora, Backblaze B2, Vertex AI, Groq y Facturapi, vuelve al [README principal](../README.md#ejecutar-el-proyecto-localmente).
