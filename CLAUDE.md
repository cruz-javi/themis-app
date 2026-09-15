# themis-app

Aplicación móvil del votante (Flutter). Contexto de producto completo en [`../docs/diseno-consolidado.md`](../docs/diseno-consolidado.md).

**Dato de arquitectura clave:** registro (CU-05) y voto (CU-10) ocurren **exclusivamente aquí**, nunca en el navegador. La prueba ZK no se reimplementa en Dart (snarkjs es JS) — esta app abre un **WebView interno** contra la ruta `/prove` de `themis-web` (todavía no implementada del lado web) y recibe la prueba por `postMessage`. Esa ruta no es un link público; solo la carga este WebView.

## Stack

Flutter 3.35.x / Dart 3.9.x, `dio` (HTTP), `go_router`, `flutter_secure_storage` (Keychain/Keystore — custodia del secreto de identidad Semaphore), `flutter_dotenv`.

## Arranque local

```bash
flutter pub get
cp .env.example assets/.env   # el .env se empaqueta como asset, no va en la raiz del repo
flutter run
```

`assets/.env` solo tiene `API_BASE_URL`, y **depende de dónde corras la app** (ver tabla en `README.md`): `10.0.2.2` para emulador Android, `localhost` para simulador iOS/Chrome, la IP LAN de la PC para dispositivo físico. Si cambias de red (WiFi distinta), la IP de dispositivo físico hay que actualizarla a mano.

## Custodia de identidad

`lib/core/storage/secure_identity_store.dart` guarda el secreto Semaphore en `flutter_secure_storage`. **Nunca debe salir del dispositivo ni enviarse al backend.** Importante para cualquier feature nueva: mobile-only **no es lo mismo** que "llave no exportable del chip" — `flutter_secure_storage` cifra el valor pero sigue siendo legible/copiable si el dispositivo está desbloqueado o comprometido (no vive en el Secure Enclave/Keystore de forma no-exportable). Ver sección 5.1 del documento de diseño consolidado para el detalle completo de esta limitación reconocida.

**Riesgo abierto sin resolver todavía:** si el votante pierde el celular o hace reset de fábrica entre registro y voto, el secreto se pierde sin recuperación (no hay copia en servidor). Propuesta pendiente de decisión en equipo: frase mnemónica BIP-39 (paquete `bip39` + derivación determinística vía `@semaphore-protocol/*`) — ver sección 6 del documento consolidado antes de tocar `secure_identity_store.dart` para esto.

## Estructura

```
lib/core/config/      Lectura del entorno (Env.apiBaseUrl desde assets/.env)
lib/core/network/     ApiClient (wrapper de dio) - hoy sin auth wired
lib/core/storage/     SecureIdentityStore
lib/core/router/      go_router
lib/data/api/         Cliente Dart generado desde el OpenAPI de themis-core - VACIO, sin generar todavia
lib/data/repositories/  Implementaciones HTTP (interfaz abstracta + implementacion, para poder testear con dobles)
lib/domain/entities/  Modelos
lib/domain/usecases/  Casos de uso
lib/features/          Una carpeta por feature; lib/features/demo/ es andamiaje temporal, borrar al empezar features reales
```

## Auth — todavía sin implementar

`ApiClient` (`lib/core/network/api_client.dart`) es un wrapper de Dio genérico sin ningún interceptor de auth todavía. El login de plataforma de themis-core (`/auth/login`) usa **cookies httpOnly**, lo cual no es el patrón natural para un cliente móvil nativo (requeriría `cookie_jar`/`dio_cookie_manager` y persistencia manual) — pero ese login es para Admin/Autoridad/Auditor, probablemente **no** para el flujo del votante en esta app. El flujo del votante pasa por `/mock-sso/login` (sin cookies, devuelve una assertion de elegibilidad) seguido de la generación local de identidad Semaphore. Antes de escribir el cliente de auth de esta app, confirmar contra `themis-core/src/modules/mock-sso/README.md` el contrato exacto de esa respuesta.

## Comandos

`flutter analyze`, `flutter test`, `flutter build apk --release`.
