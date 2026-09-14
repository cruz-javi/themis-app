# themis-app

Aplicacion movil del votante de Themis.

## Requisitos

| Herramienta | Version |
|---|---|
| Flutter | 3.35.x estable |
| Dart | 3.9.x (viene con Flutter) |

## Arranque

```bash
flutter pub get
cp .env.example assets/.env
flutter run
```

## Variables de entorno

`assets/.env` se empaqueta como asset de Flutter y se lee con `flutter_dotenv`.

| Variable | Para que sirve |
|---|---|
| `API_BASE_URL` | URL base de la API de themis-core |

La URL del core depende de donde corras la app:

| Objetivo | URL |
|---|---|
| Emulador Android | `http://10.0.2.2:3000/api/v1` |
| Simulador iOS | `http://localhost:3000/api/v1` |
| Dispositivo fisico | `http://<IP-de-tu-PC>:3000/api/v1` |
| Chrome | `http://localhost:3000/api/v1` |

`10.0.2.2` es como el emulador de Android ve el `localhost` de la maquina anfitriona. Usar `localhost` ahi apunta al propio emulador y falla.

Para Chrome hay que anadir el origen a `CORS_ORIGINS` en el `.env` de themis-core.

## Estructura

```
lib/core/config/      Lectura del entorno
lib/core/network/     Cliente HTTP con dio
lib/core/storage/     Almacenamiento seguro del secreto de identidad
lib/core/router/      Rutas con go_router
lib/data/api/         Cliente Dart generado desde el OpenAPI de themis-core
lib/data/repositories/  Implementaciones HTTP
lib/domain/entities/  Modelos
lib/domain/usecases/  Casos de uso
lib/features/         Una carpeta por feature
```

Los repositorios se declaran como clase abstracta en `data/repositories/` y se inyectan por constructor. Eso permite testear las pantallas con dobles, sin red. Ver `test/demo_page_test.dart`.

## Almacenamiento de la identidad

`lib/core/storage/secure_identity_store.dart` usa `flutter_secure_storage`, que respalda en Keychain (iOS) y Keystore (Android). El secreto de identidad Semaphore nunca debe salir del dispositivo ni enviarse al backend.

## Criptografia ZK

Decision tomada: la app **no** genera la prueba en Dart. Abre un WebView contra la ruta `/prove` de `themis-web` y recibe la prueba por `postMessage`.

Motivo: snarkjs es JavaScript y no corre en Dart. Las alternativas eran `flutter_js` (lento, dificil de depurar) o `mopro` (prover nativo en Rust, semanas de trabajo). El WebView reutiliza la implementacion web, asi que la criptografia existe una sola vez.

El secreto sigue guardado en el Keystore del telefono y se pasa al WebView por `postMessage`. Las garantias de anonimato no cambian; solo cambia el motor que ejecuta las matematicas.

## Pantalla de verificacion

`lib/features/demo/` es andamiaje temporal. Comprueba que la app alcanza el core y puede escribir en Neon. Borrala al empezar las features reales.

## Comandos

| Comando | Que hace |
|---|---|
| `flutter run` | Ejecuta en el dispositivo conectado |
| `flutter analyze` | Analisis estatico |
| `flutter test` | Tests de widgets |
| `flutter build apk --release` | APK de produccion |

## Sin Docker

No hay `docker-compose.yml` aqui. Flutter en contenedor no da recarga en caliente ni acceso a emuladores. El unico uso razonable de Docker seria compilar el APK en CI, y para eso conviene mas la action oficial de Flutter.
