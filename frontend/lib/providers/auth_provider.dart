import 'package:dio/dio.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../config/api_config.dart';
import '../models/auth_tokens.dart';
import '../models/user.dart';
import '../services/secure_storage.dart';

part 'auth_provider.freezed.dart';
part 'auth_provider.g.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

@freezed
abstract class AuthState with _$AuthState {
  const factory AuthState.initial() = _Initial;
  const factory AuthState.authenticated(User user, String accessToken) =
      _Authenticated;
  const factory AuthState.unauthenticated() = _Unauthenticated;
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

@Riverpod(keepAlive: true)
class Auth extends _$Auth {
  // Plain Dio with no interceptors — used only for auth calls to avoid
  // circular dependency with the interceptor-equipped apiClient.
  // Lazily created and cached for the notifier's lifetime.
  late final Dio _authDio = Dio(BaseOptions(baseUrl: apiBaseUrl));

  @override
  AuthState build() => const AuthState.initial();

  /// Called on app startup. Tries to restore session from stored refresh token.
  Future<void> init() async {
    final storage = ref.read(secureStorageProvider);
    final refreshToken = await storage.getRefreshToken();
    if (refreshToken == null) {
      state = const AuthState.unauthenticated();
      return;
    }
    await _doRefresh(refreshToken);
  }

  /// Log in with email + password. Stores refresh token, keeps access in memory.
  Future<void> login(String email, String password) async {
    final response = await _authDio.post<Map<String, dynamic>>(
      '/api/auth/login/',
      data: LoginRequest(email: email, password: password).toJson(),
    );
    final tokens = AuthTokens.fromJson(response.data!);
    await _storeTokens(tokens);
  }

  /// Sign up a new account.
  Future<void> signup(SignupRequest request) async {
    final response = await _authDio.post<Map<String, dynamic>>(
      '/api/auth/signup/',
      data: request.toJson(),
    );
    final tokens = AuthTokens.fromJson(response.data!);
    await _storeTokens(tokens);
  }

  /// Clear all tokens and set unauthenticated.
  Future<void> logout() async {
    await ref.read(secureStorageProvider).clearTokens();
    state = const AuthState.unauthenticated();
  }

  /// Called by the Dio interceptor on 401. Returns new access token or null.
  Future<String?> refreshToken() async {
    final storage = ref.read(secureStorageProvider);
    final stored = await storage.getRefreshToken();
    if (stored == null) {
      state = const AuthState.unauthenticated();
      return null;
    }
    return _doRefresh(stored);
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  Future<String?> _doRefresh(String refreshToken) async {
    try {
      final response = await _authDio.post<Map<String, dynamic>>(
        '/api/auth/refresh/',
        data: {'refresh': refreshToken},
      );
      final tokens = AuthTokens.fromJson(response.data!);
      await _storeTokens(tokens);
      return tokens.accessToken;
    } on DioException {
      await ref.read(secureStorageProvider).clearTokens();
      state = const AuthState.unauthenticated();
      return null;
    }
  }

  Future<void> _storeTokens(AuthTokens tokens) async {
    await ref.read(secureStorageProvider).saveRefreshToken(tokens.refreshToken);
    final me = await _fetchMe(tokens.accessToken);
    state = AuthState.authenticated(me, tokens.accessToken);
  }

  Future<User> _fetchMe(String accessToken) async {
    final response = await _authDio.get<Map<String, dynamic>>(
      '/api/auth/me/',
      options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
    );
    return User.fromJson(response.data!);
  }
}
