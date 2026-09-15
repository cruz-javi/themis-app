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

### Dispositivo fisico por USB (recomendado en Windows)

Probar contra un celular real conectado por USB tiene dos caminos:

**Opcion A - IP de la LAN (`http://<IP-de-tu-PC>:3000/api/v1`)**

El celular sale por WiFi/Ethernet hasta la IP de tu PC en la red local. En Windows esto casi siempre falla la primera vez con "no se pudo conectar con el servidor" aunque el backend este corriendo: el adaptador de red suele estar clasificado como perfil **"Publico"**, y el Firewall de Windows bloquea por defecto las conexiones entrantes no solicitadas en ese perfil (no es un problema de NestJS ni de la app, le pasaria a cualquier servidor). Se nota porque un `ping`/`curl` desde el celular a la IP de la PC se queda en timeout en vez de fallar rapido.

Arreglos (uno de los dos, requieren PowerShell **como Administrador**):

```powershell
# Opcion 1: marcar la red como privada (mas simple, si confias en esa red)
Set-NetConnectionProfile -InterfaceAlias 'Ethernet' -NetworkCategory Private

# Opcion 2: abrir solo el puerto del backend
New-NetFirewallRule -DisplayName 'Themis Core Dev' -Direction Inbound -Protocol TCP -LocalPort 3000 -Action Allow
```

**Opcion B - `adb reverse` (evita el firewall por completo)**

Redirige el puerto por el cable USB en vez de salir por la red. No requiere permisos de administrador ni tocar el firewall.

```bash
adb reverse tcp:3000 tcp:3000
```

Con esto, `assets/.env` puede usar `API_BASE_URL=http://localhost:3000/api/v1` (el `localhost` del celular queda mapeado al `localhost` de la PC via USB). Hay que volver a correr el comando cada vez que se reconecta el cable o se reinicia `adb` — no es persistente. Si la app ya estaba instalada con el `.env` viejo, hace falta un `flutter run` de nuevo (no alcanza con hot reload) para que tome el cambio, porque `assets/.env` se empaqueta en el build.

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
| `flutter devices` | Lista dispositivos/emuladores detectados |
| `adb reverse tcp:3000 tcp:3000` | Tunel USB para que el celular vea `localhost:3000` como el de la PC (ver seccion "Dispositivo fisico por USB") |

## Sin Docker

No hay `docker-compose.yml` aqui. Flutter en contenedor no da recarga en caliente ni acceso a emuladores. El unico uso razonable de Docker seria compilar el APK en CI, y para eso conviene mas la action oficial de Flutter.
