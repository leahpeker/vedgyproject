import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'secure_storage.g.dart';

const _refreshTokenKey = 'refresh_token';

@riverpod
SecureStorageService secureStorage(Ref ref) => const SecureStorageService();

class SecureStorageService {
  const SecureStorageService();

  static const _storage = FlutterSecureStorage(
    webOptions: WebOptions(dbName: 'vedgy_secure', publicKey: 'vedgy_pk'),
  );

  Future<void> saveRefreshToken(String token) =>
      _storage.write(key: _refreshTokenKey, value: token);

  Future<String?> getRefreshToken() =>
      _storage.read(key: _refreshTokenKey);

  Future<void> clearTokens() =>
      _storage.delete(key: _refreshTokenKey);
}
