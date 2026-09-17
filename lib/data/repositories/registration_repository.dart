import '../../core/network/api_client.dart';

abstract class RegistrationRepository {
  Future<String> fetchPublicKey();

  /// [blindedMessage] es el mensaje ya cegado (RFC 9474) - el backend nunca
  /// ve el commitment real. Devuelve la firma ciega (base64) para descegar
  /// localmente con CryptoBridge.finalizeCredential.
  Future<String> submit({
    required String electionId,
    required String assertion,
    required String blindedMessage,
  });

  /// Segundo paso de CU-05, sin assertion ni sesion - ver
  /// registration/README.md (themis-core) "Presentacion anonima de la
  /// credencial". [preparedMessage]/[signature] son los mismos valores que
  /// ya se guardaron con SecureIdentityStore.writeCredential.
  Future<void> presentCredential({
    required String electionId,
    required String preparedMessage,
    required String signature,
  });
}

class HttpRegistrationRepository implements RegistrationRepository {
  HttpRegistrationRepository(this._client);

  final ApiClient _client;

  @override
  Future<String> fetchPublicKey() async {
    final json = await _client.getJson('/registration/public-key');
    return json['publicKeyJwk'] as String;
  }

  @override
  Future<String> submit({
    required String electionId,
    required String assertion,
    required String blindedMessage,
  }) async {
    final json = await _client.postJson(
      '/elections/$electionId/registration-requests',
      body: {'assertion': assertion, 'blindedMessage': blindedMessage},
    );
    return json['blindSignature'] as String;
  }

  @override
  Future<void> presentCredential({
    required String electionId,
    required String preparedMessage,
    required String signature,
  }) async {
    await _client.postJson(
      '/elections/$electionId/credentials/present',
      body: {'preparedMessage': preparedMessage, 'signature': signature},
    );
  }
}
