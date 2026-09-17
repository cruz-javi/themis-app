import 'mock_sso_assertion.dart';

class LoginResult {
  const LoginResult({required this.assertion, required this.payload});

  /// Assertion cruda de mock-sso (`base64url(payload).hmacHex`), necesaria
  /// para el endpoint de registro (CU-05) - el backend la vuelve a verificar,
  /// no confia en el payload ya decodificado del lado del cliente.
  final String assertion;
  final MockSsoAssertionPayload payload;
}
