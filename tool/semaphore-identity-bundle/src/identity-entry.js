import { Identity } from "@semaphore-protocol/identity";
import { RSABSSA } from "@cloudflare/blindrsa-ts";

const suite = RSABSSA.SHA384.PSS.Randomized();
const channel = () => window.ThemisIdentityChannel;

function post(type, payload) {
  channel().postMessage(JSON.stringify({ type, ...payload }));
}

function postError(type, error) {
  post(type, { ok: false, error: String(error && error.message ? error.message : error) });
}

function bytesToBase64(bytes) {
  let binary = "";
  for (let i = 0; i < bytes.length; i += 1) binary += String.fromCharCode(bytes[i]);
  return btoa(binary);
}

function base64ToBytes(b64) {
  const binary = atob(b64);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i += 1) bytes[i] = binary.charCodeAt(i);
  return bytes;
}

async function importPublicKey(publicKeyJwk) {
  return crypto.subtle.importKey(
    "jwk",
    JSON.parse(publicKeyJwk),
    { name: "RSA-PSS", hash: "SHA-384" },
    true,
    ["verify"],
  );
}

/**
 * Genera una identidad Semaphore y la entrega por el JavaScriptChannel
 * "ThemisIdentityChannel" que registra semaphore_identity_bridge.dart.
 * seed (opcional): string usada como private key determinística, solo
 * para pruebas de reproducibilidad (ver plan, seccion Verificacion).
 */
window.generateIdentity = function (seed) {
  try {
    const identity = seed ? new Identity(seed) : new Identity();
    post("identity", {
      ok: true,
      privateKey: identity.export(),
      commitment: identity.commitment.toString(),
    });
  } catch (error) {
    postError("identity", error);
  }
};

/**
 * Cegado RSA (RFC 9474) del commitment antes de mandarlo al backend - "el
 * sobre carbon" de la analogia del diseno consolidado. Devuelve el mensaje
 * cegado a enviar por red, mas preparedMsg/inv que hay que guardar en el
 * cliente para poder finalizar mas tarde (no viajan al servidor).
 */
window.blindCommitment = async function (publicKeyJwk, commitment) {
  try {
    const publicKey = await importPublicKey(publicKeyJwk);
    const message = new TextEncoder().encode(commitment);
    const preparedMsg = suite.prepare(message);
    const { blindedMsg, inv } = await suite.blind(publicKey, preparedMsg);
    post("blind", {
      ok: true,
      blindedMessage: bytesToBase64(blindedMsg),
      preparedMsg: bytesToBase64(preparedMsg),
      inv: bytesToBase64(inv),
    });
  } catch (error) {
    postError("blind", error);
  }
};

/**
 * Descegado local: produce la firma final sobre el commitment real a partir
 * de la firma ciega que devolvio el backend. El backend nunca vio el
 * commitment ni esta firma final ("Credencial certificada lista").
 */
window.finalizeCredential = async function (publicKeyJwk, preparedMsgB64, blindSignatureB64, invB64) {
  try {
    const publicKey = await importPublicKey(publicKeyJwk);
    const preparedMsg = base64ToBytes(preparedMsgB64);
    const blindSignature = base64ToBytes(blindSignatureB64);
    const inv = base64ToBytes(invB64);
    const signature = await suite.finalize(publicKey, preparedMsg, blindSignature, inv);
    const isValid = await suite.verify(publicKey, signature, preparedMsg);
    if (!isValid) {
      postError("finalize", "La firma finalizada no verifica contra la clave publica");
      return;
    }
    post("finalize", { ok: true, signature: bytesToBase64(signature) });
  } catch (error) {
    postError("finalize", error);
  }
};
