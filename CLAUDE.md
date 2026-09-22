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

**Frase mnemónica BIP-39 (implementado).** La identidad Semaphore se deriva de 12 palabras que custodia el votante: `lib/core/crypto/identity_seed.dart` (`generateMnemonic`, `isValidMnemonic`, `seedFromMnemonic`), con respaldo en `lib/features/registration/pages/mnemonic_backup_page.dart` y restauración en `lib/features/recovery/pages/restore_identity_page.dart`.

**Nunca derivar la identidad de datos que el servidor conozca.** Antes se usaba `seed = 'themis:voter:<sub>'`: como `themis-core` tiene todos los `sub` en `mock_sso_users`, podía recalcular `commitment` y `nullifier` de cada persona y cruzarlos con el voto, lo que anulaba la firma ciega y rompía la regla 2 del CLAUDE.md raíz. Cualquier cambio en la derivación tiene que mantener la propiedad de que el servidor no pueda reproducir la identidad de un votante.

**Un dispositivo guarda la identidad de un solo votante a la vez.** `SecureIdentityStore` marca de quién es la identidad guardada con `accountTag` (hash local del `sub`, `accountTagFromSub`). Si inicia sesión otra cuenta y se registra, los datos del votante anterior se borran y se genera una identidad nueva: reusar la frase daría el mismo commitment, y aunque el registro pasaría (su `scoped_token_hash` es distinto), la credencial choca con `409 CREDENTIAL_ALREADY_PRESENTED` y esa cuenta nunca entraría al padrón. El `accountTag` **solo indexa el storage**, nunca interviene en derivar la identidad — si se usara como seed volvería la vulnerabilidad de arriba. Para volver a la cuenta anterior hay que restaurarla con sus 12 palabras.

**Límite conocido:** la frase recupera la *identidad*, no la *credencial* (`preparedMessage`/`signature` no se pueden re-derivar: el factor de cegado es aleatorio y la firma la emitió el servidor). Si el commitment ya entró en un lote `INSERTED`, restaurar alcanza para votar; si la credencial nunca se presentó, el votante queda trabado porque re-registrarse da `409 REGISTRATION_ALREADY_REGISTERED`.

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

## CU-05 (registro): generación de identidad, cegado y presentación anónima

Implementado de punta a punta contra el backend real. `lib/core/crypto/crypto_bridge.dart` corre
`@semaphore-protocol/identity` + `@cloudflare/blindrsa-ts` (RFC 9474) dentro de un WebView local
sin red (`assets/semaphore/`, bundle generado desde `tool/semaphore-identity-bundle/` — no
reimplementado en Dart, ver justificación en `docs/modelo-bd-registro.md`). `RegistrationPage`
llega hasta "Credencial certificada lista" mostrando la analogía del "sobre carbón"
(`lib/features/registration/widgets/registration_steps.dart`).

**Segundo paso, separado en el tiempo — limitación documentada, no resuelta del todo:** después de
certificar la credencial, la app programa un delay aleatorio
(`lib/core/config/credential_presentation_config.dart`) y la presenta de forma anónima
(`POST /elections/:id/credentials/present`, sin ninguna sesión ni dato que la conecte con el
registro original) recién cuando pasa ese tiempo. El chequeo es **oportunista**
(`lib/core/scheduling/credential_presentation_checker.dart`, invocado al abrir la app y al volver a
primer plano vía `WidgetsBindingObserver` en `main.dart`), **no un job en background real** — si el
votante no vuelve a abrir la app después del delay, la credencial queda sin presentar hasta que la
abra. No se agregó `WorkManager`/`BGTaskScheduler` a propósito (dependencias nuevas, configuración
por plataforma) para esta iteración. El delay en sí es una mitigación parcial de correlación por
timing (IP/momento del request), no una garantía criptográfica — el reemplazo real es el Relayer
que se construya para CU-10, pendiente. Detalle completo del protocolo en
`themis-core/src/modules/registration/README.md`.

## CU-10 (voto): implementado

`lib/core/crypto/vote_proof_bridge.dart` (`VoteProofBridge`, interfaz `VoteProofGenerator` para poder
inyectar un fake en tests) carga `$webBaseUrl/prove` de `themis-web` en un WebView remoto (a diferencia
de `CryptoBridge`, que carga un asset local) y genera la prueba zk-SNARK real ahí — mismo patrón
`JavaScriptChannel`+`Completer`, canal separado (`ThemisVoteChannel`), y con un timeout explícito de 45s
que `CryptoBridge` todavía no tiene. `lib/features/voting/election_select_page.dart` (genérico, también
resuelve el placeholder que tenía `login_result_page.dart` para CU-05) y `ballot_page.dart` completan el
flujo: leer la identidad ya guardada por CU-05 (`SecureIdentityStore.read()`), generar la prueba, y
`POST /elections/:id/votes` vía `VoteRepository`. Verificado end-to-end (incluida la generación real de
la prueba y el rechazo real de doble voto) desde `themis-core/scripts/manual-test-full-flow.ts` —
correr `flutter run` manualmente en dispositivo/Chrome sigue siendo necesario para validar el WebView
real, ver `test/voting/ballot_page_test.dart` para lo que sí cubre `flutter test` (todo excepto la
generación real de la prueba).

## Auth — todavía sin implementar

`ApiClient` (`lib/core/network/api_client.dart`) es un wrapper de Dio genérico sin ningún interceptor de auth todavía. El login de plataforma de themis-core (`/auth/login`) usa **cookies httpOnly**, lo cual no es el patrón natural para un cliente móvil nativo (requeriría `cookie_jar`/`dio_cookie_manager` y persistencia manual) — pero ese login es para Admin/Autoridad/Auditor, probablemente **no** para el flujo del votante en esta app. El flujo del votante pasa por `/mock-sso/login` (sin cookies, devuelve una assertion de elegibilidad) seguido de la generación local de identidad Semaphore. Antes de escribir el cliente de auth de esta app, confirmar contra `themis-core/src/modules/mock-sso/README.md` el contrato exacto de esa respuesta.

## Comandos

`flutter analyze`, `flutter test`, `flutter build apk --release`.
