import '../../core/network/api_client.dart';

abstract class MockSsoRepository {
  Future<String> login({
    required String codigoInstitucional,
    required String password,
  });
}

class HttpMockSsoRepository implements MockSsoRepository {
  HttpMockSsoRepository(this._client);

  final ApiClient _client;

  @override
  Future<String> login({
    required String codigoInstitucional,
    required String password,
  }) async {
    final json = await _client.postJson(
      '/mock-sso/login',
      body: {
        'codigoInstitucional': codigoInstitucional,
        'password': password,
      },
    );
    return json['assertion'] as String;
  }
}
