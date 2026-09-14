import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureIdentityStore {
  SecureIdentityStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _identityKey = 'themis.identity.secret';

  final FlutterSecureStorage _storage;

  Future<String?> read() => _storage.read(key: _identityKey);

  Future<void> write(String secret) =>
      _storage.write(key: _identityKey, value: secret);

  Future<void> clear() => _storage.delete(key: _identityKey);
}
