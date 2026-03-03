// Integration tests for app initialization.
//
// These tests exercise the full auth init flow using:
//   - Real GoRouter (via AppHarness)
//   - Real Riverpod providers
//   - FakeSecureStorage (no platform channels)
//   - MockDio (no network calls)
//
// Test cases:
//   1. Cold start, no refresh token → unauthenticated state, home screen
//   2. Cold start, valid refresh token → authenticated state, home/dashboard
//   3. Cold start, expired/invalid refresh token → unauthenticated state, home
//
// Because Auth._authDio is a private late final field, Dio is injected via
// a _DioOverrideAuth subclass that re-implements init() using the provided
// MockDio, matching Auth._doRefresh / _storeTokens / _fetchMe logic exactly.

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
/// an injected [Dio] instance instead of the private _authDio field.
/// This allows Dio calls to be intercepted in tests without modifying
/// production code.
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

      await ref.read(secureStorageProvider).saveRefreshToken(tokens.refreshToken);

      final meResponse = await _dio.get<Map<String, dynamic>>(
        '/api/auth/me/',
        options: Options(headers: {'Authorization': 'Bearer ${tokens.accessToken}'}),
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
  // Register the fallback value for RequestOptions so mocktail can match
  // any() matchers on Dio calls.
  setUpAll(() {
    registerFallbackValue(RequestOptions(path: ''));
    registerFallbackValue(Options());
  });

  group('App initialization', () {
    // -----------------------------------------------------------------------
    // 1. Cold start — no refresh token stored
    //    Expected: AuthState.unauthenticated(), app shows the home screen
    //    (router stays at "/" because "/" is not a protected route).
    // -----------------------------------------------------------------------
    testWidgets('cold start with no token → unauthenticated, shows home screen',
        (tester) async {
      _configureView(tester);

      // Empty storage: no refresh token present.
      final storage = FakeSecureStorage();
      final harness = AppHarness(fakeStorage: storage);

      await harness.pump(tester);
      await harness.init(tester);

      // Auth state must be unauthenticated.
      final authState = harness.read(authProvider);
      expect(
        authState,
        equals(const AuthState.unauthenticated()),
      );

      // The initial route "/" shows HomeScreen.
      // No Dio call is needed — AuthState.initial triggers a loading spinner
      // on HomeScreen, which resolves once init() completes.
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // 2. Cold start — refresh token present, Dio responds successfully
    //    Expected: AuthState.authenticated(...), app stays on home screen
    //    (not redirected to login).  Authenticated users on "/" are not
    //    forced anywhere; router only redirects /login → /dashboard.
    // -----------------------------------------------------------------------
    testWidgets(
        'cold start with valid token → authenticated, stays on home screen',
        (tester) async {
      _configureView(tester);

      // Storage pre-loaded with a refresh token.
      final storage = FakeSecureStorage(
        initialRefreshToken: validTokensJson['refresh'] as String,
      );

      final mockDio = MockDio();

      // Stub /api/auth/refresh/ → returns valid access + refresh tokens.
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
        (_) async => okResponse(validTokensJson, '/api/auth/refresh/'),
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
      ).thenAnswer(
        (_) async => okResponse(userJson, '/api/auth/me/'),
      );

      final harness = AppHarness(
        fakeStorage: storage,
        extraOverrides: [
          authProvider.overrideWith(() => _DioOverrideAuth(mockDio)),
        ],
      );

      await harness.pump(tester);
      await harness.init(tester);

      // Auth state must be authenticated.
      final authState = harness.read(authProvider);
      expect(
        authState.whenOrNull(authenticated: (user, token) => true),
        isTrue,
      );

      // The "/" route is still rendered — authenticated users are not
      // redirected away from home (only away from /login and /signup).
      expect(find.byType(HomeScreen), findsOneWidget);

      // LoginScreen must not be present.
      expect(find.byType(LoginScreen), findsNothing);
    });

    // -----------------------------------------------------------------------
    // 3. Cold start — refresh token present but Dio responds with 401
    //    Expected: AuthState.unauthenticated(), token cleared from storage,
    //    app shows home screen (not /login; "/" is a public route).
    // -----------------------------------------------------------------------
    testWidgets(
        'cold start with expired token → unauthenticated after 401',
        (tester) async {
      _configureView(tester);

      // Storage pre-loaded with a stale refresh token.
      final storage = FakeSecureStorage(
        initialRefreshToken: 'expired-refresh-token',
      );

      final mockDio = MockDio();

      // Stub /api/auth/refresh/ → 401 error simulating an expired token.
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
      ).thenThrow(dioError('/api/auth/refresh/'));

      final harness = AppHarness(
        fakeStorage: storage,
        extraOverrides: [
          authProvider.overrideWith(() => _DioOverrideAuth(mockDio)),
        ],
      );

      await harness.pump(tester);
      await harness.init(tester);

      // Auth state must be unauthenticated after a failed refresh.
      final authState = harness.read(authProvider);
      expect(
        authState,
        equals(const AuthState.unauthenticated()),
      );

      // The refresh token must have been cleared from storage.
      expect(await storage.getRefreshToken(), isNull);

      // The app stays on the home route; "/" is public so no redirect.
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);
    });
  });
}
