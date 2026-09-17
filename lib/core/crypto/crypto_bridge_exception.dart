class CryptoBridgeException implements Exception {
  const CryptoBridgeException(this.message);

  final String message;

  @override
  String toString() => 'CryptoBridgeException: $message';
}
