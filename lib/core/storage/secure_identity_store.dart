import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../domain/entities/vote_receipt.dart';

class SecureIdentityStore {
  SecureIdentityStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _identityKey = 'themis.identity.secret';
  static const _accountTagKey = 'themis.identity.account_tag';
  static const _mnemonicKey = 'themis.identity.mnemonic';
  static const _mnemonicBackedUpKey = 'themis.identity.mnemonic_backed_up';
  static const _credentialPreparedMessageKey = 'themis.credential.prepared_message';
  static const _credentialSignatureKey = 'themis.credential.signature';
  static const _presentationElectionIdKey = 'themis.presentation.election_id';
  static const _presentationPresentAtKey = 'themis.presentation.present_at';
  static const _presentationDoneKey = 'themis.presentation.done';

  final FlutterSecureStorage _storage;

  Future<String?> read() => _storage.read(key: _identityKey);

  Future<void> write(String secret) =>
      _storage.write(key: _identityKey, value: secret);

  /// Etiqueta de la cuenta dueña de la identidad guardada (ver
  /// core/crypto/identity_seed.dart). Sirve para detectar que el dispositivo
  /// cambio de votante: un celular guarda la identidad de un solo votante a la
  /// vez, y volver a la anterior exige restaurarla con su frase.
  Future<String?> readAccountTag() => _storage.read(key: _accountTagKey);

  Future<void> writeAccountTag(String tag) =>
      _storage.write(key: _accountTagKey, value: tag);

  /// La frase mnemonica BIP-39 desde la que se deriva la identidad Semaphore
  /// (ver core/crypto/identity_seed.dart). Se guarda para poder mostrarsela al
  /// votante mas de una vez hasta que confirme que la anoto; el respaldo real
  /// es el papel, no este storage - si el dispositivo se pierde, esto se
  /// pierde con el.
  Future<void> writeMnemonic(String mnemonic) =>
      _storage.write(key: _mnemonicKey, value: mnemonic);

  Future<String?> readMnemonic() => _storage.read(key: _mnemonicKey);

  /// El votante confirmo que anoto la frase fuera del dispositivo.
  Future<bool> isMnemonicBackedUp() async {
    return (await _storage.read(key: _mnemonicBackedUpKey)) == 'true';
  }

  Future<void> markMnemonicBackedUp() =>
      _storage.write(key: _mnemonicBackedUpKey, value: 'true');

  /// La "credencial certificada" (ver diagrama de secuencia): el mensaje
  /// preparado que realmente se firmo, mas la firma ya descegada. Ambos
  /// hacen falta juntos para usar la credencial mas adelante.
  Future<void> writeCredential({
    required String preparedMessage,
    required String signature,
  }) async {
    await _storage.write(key: _credentialPreparedMessageKey, value: preparedMessage);
    await _storage.write(key: _credentialSignatureKey, value: signature);
  }

  Future<({String preparedMessage, String signature})?> readCredential() async {
    final preparedMessage = await _storage.read(key: _credentialPreparedMessageKey);
    final signature = await _storage.read(key: _credentialSignatureKey);
    if (preparedMessage == null || signature == null) return null;
    return (preparedMessage: preparedMessage, signature: signature);
  }

  /// Programa la presentacion anonima de la credencial (segundo paso de
  /// CU-05, ver registration/README.md en themis-core): se llama recien
  /// despues de [presentAt], para no delatar el registro por timing.
  Future<void> writePresentationSchedule({
    required String electionId,
    required DateTime presentAt,
  }) async {
    await _storage.write(key: _presentationElectionIdKey, value: electionId);
    await _storage.write(
      key: _presentationPresentAtKey,
      value: presentAt.toUtc().toIso8601String(),
    );
    await _storage.delete(key: _presentationDoneKey);
  }

  Future<({String electionId, DateTime presentAt})?> readPresentationSchedule() async {
    final electionId = await _storage.read(key: _presentationElectionIdKey);
    final presentAtRaw = await _storage.read(key: _presentationPresentAtKey);
    if (electionId == null || presentAtRaw == null) return null;
    return (electionId: electionId, presentAt: DateTime.parse(presentAtRaw));
  }

  Future<bool> isPresentationDone() async {
    return (await _storage.read(key: _presentationDoneKey)) == 'true';
  }

  Future<void> markPresentationDone() =>
      _storage.write(key: _presentationDoneKey, value: 'true');

  static String _voteReceiptKey(String electionId) => 'themis.vote_receipt.$electionId';

  Future<void> saveVoteReceipt({
    required String electionId,
    required VoteReceipt receipt,
  }) async {
    final jsonStr = jsonEncode({
      'id': receipt.id,
      'electionId': receipt.electionId,
      'optionId': receipt.optionId,
      'nullifier': receipt.nullifier,
      'txHash': receipt.txHash,
      'createdAt': receipt.createdAt.toUtc().toIso8601String(),
    });
    await _storage.write(key: _voteReceiptKey(electionId), value: jsonStr);
  }

  Future<VoteReceipt?> getVoteReceipt(String electionId) async {
    final str = await _storage.read(key: _voteReceiptKey(electionId));
    if (str == null) return null;
    try {
      final json = jsonDecode(str) as Map<String, dynamic>;
      return VoteReceipt.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  Future<bool> hasVoted(String electionId) async {
    final str = await _storage.read(key: _voteReceiptKey(electionId));
    return str != null && str.isNotEmpty;
  }

  static String _electionRegisteredKey(String electionId) =>
      'themis.election.$electionId.registered';

  Future<void> markElectionRegistered(String electionId) async {
    await _storage.write(key: _electionRegisteredKey(electionId), value: 'true');
  }

  Future<bool> isElectionRegistered(String electionId) async {
    final val = await _storage.read(key: _electionRegisteredKey(electionId));
    if (val == 'true') return true;
    final hasReceipt = await hasVoted(electionId);
    if (hasReceipt) return true;
    final legacyElectionId = await _storage.read(key: _presentationElectionIdKey);
    return legacyElectionId == electionId;
  }

  Future<void> clear() async {
    await _storage.deleteAll();
  }
}
