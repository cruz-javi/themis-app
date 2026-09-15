import 'dart:convert';

class MockSsoAssertionPayload {
  const MockSsoAssertionPayload({
    required this.sub,
    required this.facultad,
    required this.tipoUsuario,
    required this.habilitado,
    required this.iat,
    required this.exp,
  });

  final String sub;
  final String facultad;
  final String tipoUsuario;
  final bool habilitado;
  final int iat;
  final int exp;

  /// Decodifica el payload de una assertion de mock-sso (`base64url(json).hmacHex`)
  /// sin verificar la firma HMAC. Es solo para mostrar informacion en la UI; la
  /// verificacion real ocurre en el backend cuando la assertion se use en el registro.
  factory MockSsoAssertionPayload.decode(String assertion) {
    final separatorIndex = assertion.indexOf('.');
    if (separatorIndex == -1) {
      throw const FormatException('Assertion con formato invalido');
    }

    final payloadB64 = assertion.substring(0, separatorIndex);
    final payloadJson =
        jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(payloadB64))))
            as Map<String, dynamic>;

    return MockSsoAssertionPayload(
      sub: payloadJson['sub'] as String,
      facultad: payloadJson['facultad'] as String,
      tipoUsuario: payloadJson['tipoUsuario'] as String,
      habilitado: payloadJson['habilitado'] as bool,
      iat: payloadJson['iat'] as int,
      exp: payloadJson['exp'] as int,
    );
  }
}
