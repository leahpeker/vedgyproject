// Integration tests for the logout flow.
//
// These tests exercise the logout interaction using:
//   - Real GoRouter (via AppHarness)
//   - Real Riverpod providers
//   - FakeSecureStorage (no platform channels)
//   - _DioOverrideAuth subclass to inject MockDio for auth calls
//
// Test cases:
//   1. Logout clears state → auth state becomes unauthenticated, token cleared
//   2. Logout redirects → after logout, app navigates away from protected routes

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vedgy/models/auth_tokens.dart';
import 'package:vedgy/models/user.dart';
import 'package:vedgy/providers/auth_provider.dart';
import 'package:vedgy/router/app_router.dart';
import 'package:vedgy/screens/auth/login_screen.dart';
import 'package:vedgy/screens/dashboard_screen.dart';
import 'package:vedgy/screens/home_screen.dart';
import 'package:vedgy/services/api_client.dart';
import 'package:vedgy/services/secure_storage.dart';

import 'helpers/app_harness.dart';
import 'helpers/fake_secure_storage.dart';
import 'helpers/fixtures.dart';
import 'helpers/mock_dio.dart';

// ---------------------------------------------------------------------------
// Fake Auth notifier that accepts an injected Dio for testing
// ---------------------------------------------------------------------------

/// A subclass of [Auth] that replaces init() with an implementation using
/// an injected [Dio] instance. This allows us to start in an authenticated state
/// for testing the logout flow.
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
    // We have a refresh token — simulate successful refresh for testing.
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

  group('Logout flow', () {
    // -----------------------------------------------------------------------
    // 1. Logout clears state
    //    Start authenticated → call logout → auth state becomes unauthenticated,
    //    refresh token cleared from storage.
    // -----------------------------------------------------------------------
    testWidgets('logout clears auth state and token from storage', (
      tester,
    ) async {
      _configureView(tester);

      // Pre-populate storage with a valid refresh token.
      final storage = FakeSecureStorage(
        initialRefreshToken: validTokensJson['refresh'] as String,
      );

      final mockDio = MockDio();

      // Stub /api/auth/refresh/ → returns valid tokens.
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
      ).thenAnswer((_) async => okResponse(userJson, '/api/auth/me/'));

      final harness = AppHarness(
        fakeStorage: storage,
        extraOverrides: [
          authProvider.overrideWith(() => _DioOverrideAuth(mockDio)),
        ],
      );

      await harness.pump(tester);
      await harness.init(tester);

      // Verify we start authenticated.
      var authState = harness.read(authProvider);
      expect(
        authState.whenOrNull(authenticated: (user, token) => true),
        isTrue,
        reason: 'User should start authenticated',
      );

      // Verify refresh token is still in storage before logout.
      var token = await storage.getRefreshToken();
      expect(
        token,
        isNotNull,
        reason: 'Token should be in storage before logout',
      );

      // Call logout.
      await harness.read(authProvider.notifier).logout();
      await tester.pumpAndSettle();

      // Auth state must be unauthenticated after logout.
      authState = harness.read(authProvider);
      expect(
        authState,
        equals(const AuthState.unauthenticated()),
        reason: 'Auth state should be unauthenticated after logout',
      );

      // Refresh token must be cleared from storage.
      token = await storage.getRefreshToken();
      expect(
        token,
        isNull,
        reason: 'Token should be cleared from storage after logout',
      );
    });

    // -----------------------------------------------------------------------
    // 2. Logout redirects to home or login
    //    After logout, app navigates away from protected routes.
    //    Unauthenticated users on "/" (home) are not redirected.
    // -----------------------------------------------------------------------
    testWidgets('logout navigation behavior', (tester) async {
      _configureView(tester);

      // Pre-populate storage with a valid refresh token.
      final storage = FakeSecureStorage(
        initialRefreshToken: validTokensJson['refresh'] as String,
      );

      final mockDio = MockDio();

      // Stub /api/auth/refresh/ → returns valid tokens.
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
      ).thenAnswer((_) async => okResponse(userJson, '/api/auth/me/'));

      // Stub dashboard API call so authenticated user can navigate to dashboard.
      when(
        () => mockDio.get<Map<String, dynamic>>(
          '/api/listings/dashboard/',
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
          cancelToken: any(named: 'cancelToken'),
          onReceiveProgress: any(named: 'onReceiveProgress'),
        ),
      ).thenAnswer(
        (_) async => okResponse(emptyDashboardJson, '/api/listings/dashboard/'),
      );

      final harness = AppHarness(
        fakeStorage: storage,
        extraOverrides: [
          authProvider.overrideWith(() => _DioOverrideAuth(mockDio)),
          apiClientProvider.overrideWithValue(mockDio),
        ],
      );

      await harness.pump(tester);
      await harness.init(tester);

      // Navigate to /dashboard (authenticated route).
      harness.read(appRouterProvider).go('/dashboard');
      await tester.pumpAndSettle();
      expect(find.byType(DashboardScreen), findsOneWidget);

      // Call logout.
      await harness.read(authProvider.notifier).logout();
      await tester.pumpAndSettle();

      // After logout, user should not be on DashboardScreen anymore.
      // The router should redirect unauthenticated users away from /dashboard
      // to the home screen "/" which is a public route.
      expect(
        find.byType(DashboardScreen),
        findsNothing,
        reason:
            'DashboardScreen should not be visible after logout (protected route)',
      );

      // HomeScreen or LoginScreen should be visible depending on the router config.
      // At minimum, we should not be on the protected dashboard.
      final isOnPublicRoute =
          find.byType(HomeScreen).evaluate().isNotEmpty ||
          find.byType(LoginScreen).evaluate().isNotEmpty;
      expect(
        isOnPublicRoute,
        isTrue,
        reason:
            'Should be on a public route (home or login) after logout from dashboard',
      );
    });
  });
}
