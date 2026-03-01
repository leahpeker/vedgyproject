import 'package:vedgy/services/secure_storage.dart';

/// In-memory SecureStorageService for tests — no platform channels.
class FakeSecureStorage extends SecureStorageService {
  FakeSecureStorage({String? initialRefreshToken})
      : _refreshToken = initialRefreshToken;

  String? _refreshToken;

  @override
  Future<void> saveRefreshToken(String token) async => _refreshToken = token;

  @override
  Future<String?> getRefreshToken() async => _refreshToken;

  @override
  Future<void> clearTokens() async => _refreshToken = null;
}
