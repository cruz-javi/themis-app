# themis-app: estado del registro y pendientes para la Fase 2

Resume qué hace hoy la app, cómo probarla contra el backend local y qué le falta para el voto (CU-10).
El flujo completo del backend está en `themis-core/docs/` (empieza por `README.md` y
`guia-prueba-end-to-end.md`).

## Qué hace hoy (CU-05, registro)

1. **Login** con el mock SSO (`POST /mock-sso/login`), que devuelve una *assertion* de elegibilidad.
2. **Identidad Semaphore + cegado**, todo dentro de un WebView local sin red
   (`lib/core/crypto/crypto_bridge.dart`, bundle en `assets/semaphore/`): genera la identidad, calcula el
   commitment y lo ciega con RSA blind signature (RFC 9474). El secreto queda en
   `flutter_secure_storage` y nunca sale del dispositivo.
3. **Solicitud de registro** (`POST /elections/:id/registration-requests`) con la assertion y el valor
   cegado. El backend responde con la firma ciega sin ver nunca el commitment real. La app la descega
   localmente y muestra **"Credencial certificada lista"**. Esa es la última pantalla del flujo.
4. **Presentación anónima**, tiempo después: tras un **delay aleatorio de 30 a 120 s**
   (`lib/core/config/credential_presentation_config.dart`) la app llama a
   `POST /elections/:id/credentials/present`, sin token ni sesión. Ese endpoint es lo que mete el commitment
   en la cola que luego se agrupa en un lote.

**El chequeo del delay es oportunista, no un job en segundo plano**
(`lib/core/scheduling/credential_presentation_checker.dart`): solo corre al abrir la app o al volver a
primer plano. Si el votante no la reabre después del delay, la credencial no se presenta. Es una limitación
documentada; el reemplazo real es el Relayer de la Fase 2.

## Cómo apuntarla al backend

`assets/.env` (se copia de `.env.example`; no se comitea) solo tiene `API_BASE_URL`, y depende de dónde corra
la app. **Reinicia la app después de cambiarlo.**

| Dónde corre | `API_BASE_URL` |
|---|---|
| Emulador Android | `http://10.0.2.2:3000/api/v1` |
| Celular físico en tu Wi-Fi | `http://<IP-de-tu-PC>:3000/api/v1` (el backend escucha en `0.0.0.0`; revisa el firewall del puerto 3000) |
| Simulador iOS / Chrome | `http://localhost:3000/api/v1` |

**El id de la elección está fijo en el código**: `_placeholderElectionId` en
`lib/features/auth/login_result_page.dart`. Aún no existe una pantalla para elegir elección; para probar con
otra hay que cambiar esa constante por el id de la elección (visible en la URL del portal,
`/admin/elections/<id>`). Esa elección debe estar en `Registro abierto`, con padrón y 5 autoridades (ver
`themis-core/docs/ciclo-de-vida-elecciones.md`).

## Qué NO hace la app todavía

- **No muestra si el lote fue aprobado ni si su commitment ya está en la blockchain.** Después de "Credencial
  certificada lista" no hay más pantallas, y el backend no expone ningún endpoint para consultarlo. La app
  tampoco tiene dirección de contrato ni RPC para leer la cadena.
- **No hay selección de elección** ni lista de elecciones para el votante: `GET /elections` es solo `ADMIN`
  y no existe un endpoint público de elección (estado, opciones, fechas).
- **No hay voto**: ninguna pantalla ni ruta (las rutas son `/login`, `/login/resultado`, `/registro`,
  `/demo`).
- El **cliente OpenAPI** de `lib/data/api/` sigue vacío; los repositorios HTTP están escritos a mano.

## Qué necesita la Fase 2 de esta app

Nada de esto está hecho; es el trabajo de CU-10 del lado móvil:

- **Bundle de JavaScript ampliado**: hoy `tool/semaphore-identity-bundle/` solo incluye
  `@semaphore-protocol/identity` y `@cloudflare/blindrsa-ts`. Para votar hacen falta
  `@semaphore-protocol/group` y `@semaphore-protocol/proof` (y snarkjs), más los **artefactos del circuito**
  (`.zkey` y `.wasm`) en `assets/`. El diseño prevé generar la prueba abriendo un WebView contra la ruta
  `/prove` de `themis-web` (que tampoco existe todavía) y recibirla por `postMessage`.
- **Datos que la app no tiene**: el id del grupo Semaphore, la raíz vigente y la **prueba de Merkle** de su
  commitment. Requiere un endpoint nuevo en `themis-core` (ver "Pendiente para la Fase 2" en
  `themis-core/docs/checkpoint-lote-multisig.md`); el mismo endpoint puede responder "¿ya estoy insertado?" y
  alimentar la pantalla "Estás registrado".
- **Pantallas y rutas**: elegir elección, ver opciones, votar, confirmación.
- **Envío por relayer**, no directo al contrato, para que la dirección del votante no quede ligada al voto.
- **Recuperación de la identidad**: si el votante pierde el celular entre el registro y el voto, el secreto
  se pierde (no hay copia en el servidor). La propuesta de frase mnemónica BIP-39 está pendiente de decisión
  del equipo (sección 6 de `diseno-consolidado.md`).
