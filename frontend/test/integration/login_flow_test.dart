// Integration tests for the login flow.
//
// These tests exercise the full login interaction using:
//   - Real GoRouter (via AppHarness)
//   - Real Riverpod providers
//   - FakeSecureStorage (no platform channels)
//   - _DioOverrideAuth subclass to inject MockDio for auth calls
//   - MockDio on apiClientProvider for dashboard API calls
//
// Test cases:
//   1. Successful login → authenticated state, navigates to /dashboard
//   2. Failed login (401) → error message displayed on LoginScreen
//   3. Network error on login → stays on LoginScreen with error message
//
// Because Auth._authDio is a private late final field, Dio is injected via
// a _DioOverrideAuth subclass that re-implements login() (and init()) using
// the provided MockDio, matching Auth._storeTokens / _fetchMe logic exactly.

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
import 'package:vedgy/services/api_client.dart';
import 'package:vedgy/services/secure_storage.dart';

import 'helpers/app_harness.dart';
import 'helpers/fake_secure_storage.dart';
import 'helpers/fixtures.dart';
import 'helpers/mock_dio.dart';

// ---------------------------------------------------------------------------
// Fake Auth notifier that accepts an injected Dio for testing
// ---------------------------------------------------------------------------

/// A subclass of [Auth] that replaces login() (and init()) with
/// implementations using an injected [Dio] instance instead of the private
/// _authDio field. This allows Dio calls to be intercepted in tests without
/// modifying production code.
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
    // No stored refresh token in login flow tests; just go unauthenticated.
    state = const AuthState.unauthenticated();
  }

  @override
  Future<void> login(String email, String password) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/auth/login/',
      data: LoginRequest(email: email, password: password).toJson(),
    );
    final tokens = AuthTokens.fromJson(response.data!);
    await _storeTokensWithDio(tokens);
  }

  Future<void> _storeTokensWithDio(AuthTokens tokens) async {
    await ref.read(secureStorageProvider).saveRefreshToken(tokens.refreshToken);
    final me = await _fetchMeWithDio(tokens.accessToken);
    state = AuthState.authenticated(me, tokens.accessToken);
  }

  Future<User> _fetchMeWithDio(String accessToken) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/auth/me/',
      options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
    );
    return User.fromJson(response.data!);
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
// Shared stub helpers
// ---------------------------------------------------------------------------

void _stubLoginSuccess(MockDio mockDio) {
  when(
    () => mockDio.post<Map<String, dynamic>>(
      '/api/auth/login/',
      data: any(named: 'data'),
      options: any(named: 'options'),
      queryParameters: any(named: 'queryParameters'),
      cancelToken: any(named: 'cancelToken'),
      onSendProgress: any(named: 'onSendProgress'),
      onReceiveProgress: any(named: 'onReceiveProgress'),
    ),
  ).thenAnswer(
    (_) async => okResponse(validTokensJson, '/api/auth/login/'),
  );
}

void _stubMeSuccess(MockDio mockDio) {
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
}

void _stubDashboardSuccess(MockDio mockDio) {
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
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() {
    registerFallbackValue(RequestOptions(path: ''));
    registerFallbackValue(Options());
  });

  group('Login flow', () {
    // -----------------------------------------------------------------------
    // 1. Successful login
    //    User enters valid credentials → Dio returns tokens + user →
    //    authProvider transitions to authenticated → router redirects to
    //    /dashboard.
    // -----------------------------------------------------------------------
    testWidgets('successful login navigates to /dashboard', (tester) async {
      _configureView(tester);

      // auth MockDio: handles login + me calls.
      final authMockDio = MockDio();
      _stubLoginSuccess(authMockDio);
      _stubMeSuccess(authMockDio);

      // API client MockDio: handles dashboard call after redirect.
      final apiMockDio = MockDio();
      _stubDashboardSuccess(apiMockDio);

      final harness = AppHarness(
        fakeStorage: FakeSecureStorage(),
        extraOverrides: [
          authProvider.overrideWith(() => _DioOverrideAuth(authMockDio)),
          apiClientProvider.overrideWithValue(apiMockDio),
        ],
      );

      await harness.pump(tester);
      await harness.init(tester);

      // Start on /login.
      harness.read(appRouterProvider).go('/login');
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);

      // Fill in credentials.
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'test@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'secret123',
      );

      // Submit the form.
      await tester.tap(find.widgetWithText(FilledButton, 'Log in'));
      await tester.pumpAndSettle();

      // Auth state must be authenticated.
      final authState = harness.read(authProvider);
      expect(
        authState.whenOrNull(authenticated: (user, token) => true),
        isTrue,
      );

      // Router should have redirected from /login to /dashboard.
      expect(find.byType(DashboardScreen), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);
    });

    // -----------------------------------------------------------------------
    // 2. Failed login (401)
    //    User enters credentials → Dio returns 401 → error message shown on
    //    LoginScreen; auth state remains unauthenticated.
    // -----------------------------------------------------------------------
    testWidgets('failed login (401) shows error on LoginScreen', (tester) async {
      _configureView(tester);

      final authMockDio = MockDio();

      // Stub login to return a 401 DioException.
      when(
        () => authMockDio.post<Map<String, dynamic>>(
          '/api/auth/login/',
          data: any(named: 'data'),
          options: any(named: 'options'),
          queryParameters: any(named: 'queryParameters'),
          cancelToken: any(named: 'cancelToken'),
          onSendProgress: any(named: 'onSendProgress'),
          onReceiveProgress: any(named: 'onReceiveProgress'),
        ),
      ).thenThrow(dioError('/api/auth/login/'));

      final harness = AppHarness(
        fakeStorage: FakeSecureStorage(),
        extraOverrides: [
          authProvider.overrideWith(() => _DioOverrideAuth(authMockDio)),
        ],
      );

      await harness.pump(tester);
      await harness.init(tester);

      // Start on /login.
      harness.read(appRouterProvider).go('/login');
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);

      // Fill in credentials.
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'bad@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'wrongpassword',
      );

      // Submit the form.
      await tester.tap(find.widgetWithText(FilledButton, 'Log in'));
      await tester.pumpAndSettle();

      // Auth state must remain unauthenticated.
      final authState = harness.read(authProvider);
      expect(authState, equals(const AuthState.unauthenticated()));

      // Still on LoginScreen — no navigation occurred.
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(DashboardScreen), findsNothing);

      // An error message must be visible. The dioError helper uses
      // {'detail': 'Authentication failed.'} which the screen renders
      // via parseAuthError. Also accept the fallback text.
      final errorText = find.textContaining('Authentication failed.');
      final fallbackText =
          find.textContaining('Invalid email or password.');
      expect(
        errorText.evaluate().isNotEmpty || fallbackText.evaluate().isNotEmpty,
        isTrue,
        reason: 'Expected an error message on LoginScreen after 401',
      );
    });

    // -----------------------------------------------------------------------
    // 3. Network error on login
    //    Dio throws a connection error (not a DioException with a response) →
    //    LoginScreen shows generic error; auth state remains unauthenticated.
    // -----------------------------------------------------------------------
    testWidgets(
        'network error on login stays on LoginScreen with error message',
        (tester) async {
      _configureView(tester);

      final authMockDio = MockDio();

      // Stub login to throw a network-level DioException (no response).
      when(
        () => authMockDio.post<Map<String, dynamic>>(
          '/api/auth/login/',
          data: any(named: 'data'),
          options: any(named: 'options'),
          queryParameters: any(named: 'queryParameters'),
          cancelToken: any(named: 'cancelToken'),
          onSendProgress: any(named: 'onSendProgress'),
          onReceiveProgress: any(named: 'onReceiveProgress'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/api/auth/login/'),
          type: DioExceptionType.connectionError,
          message: 'Failed to connect to server.',
        ),
      );

      final harness = AppHarness(
        fakeStorage: FakeSecureStorage(),
        extraOverrides: [
          authProvider.overrideWith(() => _DioOverrideAuth(authMockDio)),
        ],
      );

      await harness.pump(tester);
      await harness.init(tester);

      // Start on /login.
      harness.read(appRouterProvider).go('/login');
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);

      // Fill in credentials.
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'user@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'mypassword',
      );

      // Submit the form.
      await tester.tap(find.widgetWithText(FilledButton, 'Log in'));
      await tester.pumpAndSettle();

      // Auth state must remain unauthenticated.
      final authState = harness.read(authProvider);
      expect(authState, equals(const AuthState.unauthenticated()));

      // Still on LoginScreen.
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(DashboardScreen), findsNothing);

      // A generic error message must be visible.
      // The screen catches DioException with no response and shows the
      // parseAuthError fallback or the generic catch-all message.
      final dioFallback = find.textContaining('Invalid email or password.');
      final genericError =
          find.textContaining('An unexpected error occurred.');
      expect(
        dioFallback.evaluate().isNotEmpty || genericError.evaluate().isNotEmpty,
        isTrue,
        reason: 'Expected an error message on LoginScreen after network error',
      );
    });
  });
}
