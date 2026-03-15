// Integration tests for token refresh flow.
//
// These tests exercise token refresh during app initialization using:
//   - Real GoRouter (via AppHarness)
//   - Real Riverpod providers
//   - FakeSecureStorage (no platform channels)
//   - _DioOverrideAuth subclass to inject MockDio for auth calls
//
// Test cases:
//   1. Successful refresh → valid refresh token in storage → auth.init()
//      refreshes → authenticated state
//   2. Failed refresh → stale token → auth.init() gets 401 →
//      unauthenticated state, token cleared

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vedgy/models/auth_tokens.dart';
import 'package:vedgy/models/user.dart';
import 'package:vedgy/providers/auth_provider.dart';
import 'package:vedgy/screens/auth/login_screen.dart';
import 'package:vedgy/screens/home_screen.dart';
import 'package:vedgy/services/secure_storage.dart';

import 'helpers/app_harness.dart';
import 'helpers/fake_secure_storage.dart';
import 'helpers/fixtures.dart';
import 'helpers/mock_dio.dart';

// ---------------------------------------------------------------------------
// Fake Auth notifier that accepts an injected Dio for testing
// ---------------------------------------------------------------------------

/// A subclass of [Auth] that replaces init() with an implementation using
/// an injected [Dio] instance. This allows us to test the refresh flow
/// with mocked Dio responses.
class _DioOverrideAuth extends Auth {
  _DioOverrideAuth(this._dio);

  final Dio _dio;

  @override
  Future<void> init() async {
    final storage = ref.read(secureStorageProvider);
    final refreshToken = await storage.getRefreshToken();
    if (refreshToken == null) {
      state = const AuthState.unauthenticated();
      return;
    }
    await _doRefreshWithDio(refreshToken);
  }

  Future<void> _doRefreshWithDio(String refreshToken) async {
    try {
      final refreshResponse = await _dio.post<Map<String, dynamic>>(
        '/api/auth/refresh/',
        data: {'refresh': refreshToken},
      );
      final tokens = AuthTokens.fromJson(refreshResponse.data!);

      await ref
          .read(secureStorageProvider)
          .saveRefreshToken(tokens.refreshToken);

      final meResponse = await _dio.get<Map<String, dynamic>>(
        '/api/auth/me/',
        options: Options(
          headers: {'Authorization': 'Bearer ${tokens.accessToken}'},
        ),
      );
      final user = User.fromJson(meResponse.data!);
      state = AuthState.authenticated(user, tokens.accessToken);
    } on DioException {
      await ref.read(secureStorageProvider).clearTokens();
      state = const AuthState.unauthenticated();
    }
  }
}

// ---------------------------------------------------------------------------
// View configuration helper
// ---------------------------------------------------------------------------

void _configureView(WidgetTester tester) {
  tester.view.physicalSize = const Size(1440, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final originalOnError = FlutterError.onError;
  FlutterError.onError = (FlutterErrorDetails details) {
    if (details.exceptionAsString().contains('RenderFlex overflowed')) return;
    originalOnError?.call(details);
  };
  addTearDown(() => FlutterError.onError = originalOnError);
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() {
    registerFallbackValue(RequestOptions(path: ''));
    registerFallbackValue(Options());
  });

  group('Token refresh flow', () {
    // -----------------------------------------------------------------------
    // 1. Successful refresh
    //    Valid refresh token in storage → auth.init() calls /api/auth/refresh/ →
    //    returns new tokens → calls /api/auth/me/ → sets authenticated state.
    // -----------------------------------------------------------------------
    testWidgets('successful refresh with valid token → authenticated state', (
      tester,
    ) async {
      _configureView(tester);

      // Pre-populate storage with a valid refresh token.
      final storage = FakeSecureStorage(
        initialRefreshToken: validTokensJson['refresh'] as String,
      );

      final mockDio = MockDio();

      // Stub /api/auth/refresh/ → returns new access + refresh tokens.
      when(
        () => mockDio.post<Map<String, dynamic>>(
          '/api/auth/refresh/',
          data: any(named: 'data'),
          options: any(named: 'options'),
          queryParameters: any(named: 'queryParameters'),
          cancelToken: any(named: 'cancelToken'),
          onSendProgress: any(named: 'onSendProgress'),
          onReceiveProgress: any(named: 'onReceiveProgress'),
        ),
      ).thenAnswer(
        (_) async => okResponse(<String, dynamic>{
          'access': 'new-access-token-refreshed',
          'refresh': 'new-refresh-token-refreshed',
        }, '/api/auth/refresh/'),
      );

      // Stub /api/auth/me/ → returns user details.
      when(
        () => mockDio.get<Map<String, dynamic>>(
          '/api/auth/me/',
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
          cancelToken: any(named: 'cancelToken'),
          onReceiveProgress: any(named: 'onReceiveProgress'),
        ),
      ).thenAnswer((_) async => okResponse(userJson, '/api/auth/me/'));

      final harness = AppHarness(
        fakeStorage: storage,
        extraOverrides: [
          authProvider.overrideWith(() => _DioOverrideAuth(mockDio)),
        ],
      );

      await harness.pump(tester);
      await harness.init(tester);

      // Auth state must be authenticated after successful refresh.
      final authState = harness.read(authProvider);
      expect(
        authState.whenOrNull(authenticated: (user, token) => true),
        isTrue,
        reason:
            'Auth state should be authenticated after successful token refresh',
      );

      // The refreshed token should have been saved to storage.
      final refreshedToken = await storage.getRefreshToken();
      expect(
        refreshedToken,
        equals('new-refresh-token-refreshed'),
        reason: 'Refreshed token should be saved to storage',
      );

      // HomeScreen should be visible (not redirected away).
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);
    });

    // -----------------------------------------------------------------------
    // 2. Failed refresh
    //    Stale refresh token in storage → auth.init() calls /api/auth/refresh/ →
    //    gets 401 error → clears token from storage → sets unauthenticated state.
    // -----------------------------------------------------------------------
    testWidgets(
      'failed refresh with expired token → unauthenticated state, token cleared',
      (tester) async {
        _configureView(tester);

        // Pre-populate storage with a stale refresh token.
        final storage = FakeSecureStorage(
          initialRefreshToken: 'stale-expired-refresh-token',
        );

        final mockDio = MockDio();

        // Stub /api/auth/refresh/ → returns 401 error.
        when(
          () => mockDio.post<Map<String, dynamic>>(
            '/api/auth/refresh/',
            data: any(named: 'data'),
            options: any(named: 'options'),
            queryParameters: any(named: 'queryParameters'),
            cancelToken: any(named: 'cancelToken'),
            onSendProgress: any(named: 'onSendProgress'),
            onReceiveProgress: any(named: 'onReceiveProgress'),
          ),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/api/auth/refresh/'),
            response: Response(
              data: {'detail': 'Token refresh failed.'},
              statusCode: 401,
              requestOptions: RequestOptions(path: '/api/auth/refresh/'),
            ),
            type: DioExceptionType.badResponse,
          ),
        );

        final harness = AppHarness(
          fakeStorage: storage,
          extraOverrides: [
            authProvider.overrideWith(() => _DioOverrideAuth(mockDio)),
          ],
        );

        await harness.pump(tester);
        await harness.init(tester);

        // Auth state must be unauthenticated after failed refresh.
        final authState = harness.read(authProvider);
        expect(
          authState,
          equals(const AuthState.unauthenticated()),
          reason:
              'Auth state should be unauthenticated after failed token refresh',
        );

        // The stale token must be cleared from storage.
        final storedToken = await storage.getRefreshToken();
        expect(
          storedToken,
          isNull,
          reason:
              'Stale token should be cleared from storage after failed refresh',
        );

        // HomeScreen should be visible (not redirected to login).
        // "/" is a public route, so unauthenticated users are not redirected.
        expect(find.byType(HomeScreen), findsOneWidget);
      },
    );

    // -----------------------------------------------------------------------
    // 3. Network error on refresh
    //    Refresh token in storage → auth.init() calls /api/auth/refresh/ →
    //    network error (not a server response) → clears token, sets unauthenticated.
    // -----------------------------------------------------------------------
    testWidgets('network error on refresh → unauthenticated state, token cleared', (
      tester,
    ) async {
      _configureView(tester);

      // Pre-populate storage with a refresh token.
      final storage = FakeSecureStorage(
        initialRefreshToken: validTokensJson['refresh'] as String,
      );

      final mockDio = MockDio();

      // Stub /api/auth/refresh/ → throws a network-level DioException.
      when(
        () => mockDio.post<Map<String, dynamic>>(
          '/api/auth/refresh/',
          data: any(named: 'data'),
          options: any(named: 'options'),
          queryParameters: any(named: 'queryParameters'),
          cancelToken: any(named: 'cancelToken'),
          onSendProgress: any(named: 'onSendProgress'),
          onReceiveProgress: any(named: 'onReceiveProgress'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/api/auth/refresh/'),
          type: DioExceptionType.connectionError,
          message: 'Failed to connect to server.',
        ),
      );

      final harness = AppHarness(
        fakeStorage: storage,
        extraOverrides: [
          authProvider.overrideWith(() => _DioOverrideAuth(mockDio)),
        ],
      );

      await harness.pump(tester);
      await harness.init(tester);

      // Auth state must be unauthenticated after network error.
      final authState = harness.read(authProvider);
      expect(
        authState,
        equals(const AuthState.unauthenticated()),
        reason:
            'Auth state should be unauthenticated after network error on refresh',
      );

      // The token must be cleared from storage.
      final storedToken = await storage.getRefreshToken();
      expect(
        storedToken,
        isNull,
        reason:
            'Token should be cleared from storage after network error on refresh',
      );

      // HomeScreen should be visible.
      expect(find.byType(HomeScreen), findsOneWidget);
    });
  });
}
