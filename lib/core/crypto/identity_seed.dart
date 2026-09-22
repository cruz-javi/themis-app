import 'dart:convert';

import 'package:bip39/bip39.dart' as bip39;
import 'package:crypto/crypto.dart';

/// Derivacion de la identidad Semaphore a partir de una frase mnemonica
/// BIP-39 que custodia el votante.
///
/// **Por que existe este archivo:** antes la identidad se derivaba del `sub`
/// del SSO (`themis:voter:<sub>`). Como el backend conoce todos los `sub`
/// (tabla `mock_sso_users`), podia recalcular privateKey -> commitment ->
/// nullifier de cada persona y cruzarlo con el nullifier que queda registrado
/// al votar: asociacion exacta entre votante y voto, justo lo que la regla 2
/// del CLAUDE.md raiz prohibe. La frase mnemonica corta ese vinculo porque el
/// servidor nunca la ve, y a la vez permite recuperar la identidad si el
/// votante pierde el dispositivo.
///
/// Funciones puras a proposito (sin WebView, sin storage): son las unicas
/// piezas de la cadena de anonimato que se pueden testear con `flutter test`
/// sin platform channels.

/// Prefijo de dominio: evita que la misma frase usada en otra app derive la
/// misma clave privada (separacion de dominio criptografico).
const _seedDomain = 'themis:semaphore:v1';

/// Frase nueva de 12 palabras (128 bits de entropia).
String generateMnemonic() => bip39.generateMnemonic(strength: 128);

/// Valida palabras y checksum BIP-39. Tolera espacios extra y mayusculas,
/// porque el votante la va a tipear a mano desde un papel.
bool isValidMnemonic(String mnemonic) {
  final normalized = normalizeMnemonic(mnemonic);
  if (normalized.isEmpty) return false;
  return bip39.validateMnemonic(normalized);
}

/// Normaliza lo que el votante tipea: minusculas y un solo espacio entre
/// palabras. BIP-39 es sensible a ambas cosas.
String normalizeMnemonic(String mnemonic) =>
    mnemonic.trim().toLowerCase().split(RegExp(r'\s+')).join(' ');

/// Etiqueta local de la cuenta que es dueña de la identidad guardada.
///
/// **No interviene en la derivacion de la identidad**: solo permite detectar
/// que el dispositivo cambio de votante (otra persona inicio sesion) para no
/// reusar la identidad de la cuenta anterior. La mnemonica sigue siendo
/// aleatoria, asi que el servidor no puede reproducirla aunque conozca el
/// `sub`; si esta etiqueta se usara como seed volveria la vulnerabilidad que
/// describe el comentario de arriba.
String accountTagFromSub(String sub) {
  final digest = sha256.convert(utf8.encode('themis:account:$sub'));
  return digest.toString().substring(0, 16);
}

/// Clave privada Semaphore (hex) derivada de la frase. Determinista respecto
/// de la frase y de nada mas: la misma frase da siempre la misma identidad, y
/// dos frases distintas dan identidades sin relacion entre si.
///
/// El resultado se pasa como `seed` a `CryptoBridge.generateIdentity`, que es
/// quien construye la `Identity` de Semaphore dentro del WebView.
String seedFromMnemonic(String mnemonic) {
  final normalized = normalizeMnemonic(mnemonic);
  if (!bip39.validateMnemonic(normalized)) {
    throw ArgumentError('La frase de recuperacion no es valida');
  }
  final bip39Seed = bip39.mnemonicToSeedHex(normalized);
  final digest = sha256.convert(utf8.encode('$_seedDomain:$bip39Seed'));
  return digest.toString();
}
