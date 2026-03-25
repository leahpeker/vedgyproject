// Integration tests for the signup flow.
//
// These tests exercise the full signup interaction using:
//   - Real GoRouter (via AppHarness)
//   - Real Riverpod providers
//   - FakeSecureStorage (no platform channels)
//   - _DioOverrideAuth subclass to inject MockDio for auth calls
//   - MockDio on apiClientProvider for dashboard API calls
//
// Test cases:
//   1. Successful signup → authenticated state, navigates to /dashboard
//   2. Failed signup (email taken) → 400 error, stays on SignupScreen
//   3. Password mismatch → client-side validation, no Dio call

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vedgy/models/auth_tokens.dart';
import 'package:vedgy/models/user.dart';
import 'package:vedgy/providers/auth_provider.dart';
import 'package:vedgy/router/app_router.dart';
import 'package:vedgy/screens/auth/signup_screen.dart';
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

/// A subclass of [Auth] that replaces signup() (and init()) with
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
    // No stored refresh token in signup flow tests; just go unauthenticated.
    state = const AuthState.unauthenticated();
  }

  @override
  Future<void> signup(SignupRequest request) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/auth/signup/',
      data: request.toJson(),
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

void _stubSignupSuccess(MockDio mockDio) {
  when(
    () => mockDio.post<Map<String, dynamic>>(
      '/api/auth/signup/',
      data: any(named: 'data'),
      options: any(named: 'options'),
      queryParameters: any(named: 'queryParameters'),
      cancelToken: any(named: 'cancelToken'),
      onSendProgress: any(named: 'onSendProgress'),
      onReceiveProgress: any(named: 'onReceiveProgress'),
    ),
  ).thenAnswer((_) async => okResponse(validTokensJson, '/api/auth/signup/'));
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
  ).thenAnswer((_) async => okResponse(userJson, '/api/auth/me/'));
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

  group('Signup flow', () {
    // -----------------------------------------------------------------------
    // 1. Successful signup
    //    User enters valid credentials (including matching passwords) →
    //    Dio returns tokens + user → authProvider transitions to authenticated →
    //    router redirects to /dashboard.
    // -----------------------------------------------------------------------
    testWidgets('successful signup navigates to /dashboard', (tester) async {
      _configureView(tester);

      // auth MockDio: handles signup + me calls.
      final authMockDio = MockDio();
      _stubSignupSuccess(authMockDio);
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

      // Start on /signup.
      harness.read(appRouterProvider).go('/signup');
      await tester.pumpAndSettle();
      expect(find.byType(SignupScreen), findsOneWidget);

      // Fill in the form.
      await tester.enterText(
        find.widgetWithText(TextFormField, 'First name'),
        'John',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Last name'),
        'Doe',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'john@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'SecurePass123',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirm password'),
        'SecurePass123',
      );

      // Submit the form.
      await tester.tap(find.byType(FilledButton).first);
      await tester.pumpAndSettle();

      // Auth state must be authenticated.
      final authState = harness.read(authProvider);
      expect(
        authState.whenOrNull(authenticated: (user, token) => true),
        isTrue,
      );

      // Router should have redirected from /signup to /dashboard.
      expect(find.byType(DashboardScreen), findsOneWidget);
      expect(find.byType(SignupScreen), findsNothing);
    });

    // -----------------------------------------------------------------------
    // 2. Failed signup (email taken)
    //    User enters credentials → Dio returns 400 with email error →
    //    error message shown on SignupScreen; auth state remains unauthenticated.
    // -----------------------------------------------------------------------
    testWidgets('failed signup (email taken) shows error on SignupScreen', (
      tester,
    ) async {
      _configureView(tester);

      final authMockDio = MockDio();

      // Stub signup to return a 400 DioException with email error.
      when(
        () => authMockDio.post<Map<String, dynamic>>(
          '/api/auth/signup/',
          data: any(named: 'data'),
          options: any(named: 'options'),
          queryParameters: any(named: 'queryParameters'),
          cancelToken: any(named: 'cancelToken'),
          onSendProgress: any(named: 'onSendProgress'),
          onReceiveProgress: any(named: 'onReceiveProgress'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/api/auth/signup/'),
          response: Response(
            data: {'email': 'Email is already in use.'},
            statusCode: 400,
            requestOptions: RequestOptions(path: '/api/auth/signup/'),
          ),
          type: DioExceptionType.badResponse,
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

      // Start on /signup.
      harness.read(appRouterProvider).go('/signup');
      await tester.pumpAndSettle();
      expect(find.byType(SignupScreen), findsOneWidget);

      // Fill in the form.
      await tester.enterText(
        find.widgetWithText(TextFormField, 'First name'),
        'Jane',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Last name'),
        'Smith',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'existing@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'SecurePass123',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirm password'),
        'SecurePass123',
      );

      // Submit the form.
      await tester.tap(find.byType(FilledButton).first);
      await tester.pumpAndSettle();

      // Auth state must remain unauthenticated.
      final authState = harness.read(authProvider);
      expect(authState, equals(const AuthState.unauthenticated()));

      // Still on SignupScreen — no navigation occurred.
      expect(find.byType(SignupScreen), findsOneWidget);
      expect(find.byType(DashboardScreen), findsNothing);

      // An error message must be visible. The parseAuthError function looks for
      // a 'detail' key in the response, so when we return {'email': '...'}, it
      // falls back to the fallback message defined in signup_screen.dart.
      final fallbackError = find.textContaining(
        'Sign up failed. Please try again.',
      );
      expect(
        fallbackError.evaluate().isNotEmpty,
        isTrue,
        reason: 'Expected error message on SignupScreen after 400',
      );
    });

    // -----------------------------------------------------------------------
    // 3. Password mismatch
    //    User enters mismatched passwords → client-side form validation
    //    catches the error → stays on SignupScreen, no Dio call is made.
    // -----------------------------------------------------------------------
    testWidgets('password mismatch shows validation error, no Dio call', (
      tester,
    ) async {
      _configureView(tester);

      final authMockDio = MockDio();

      final harness = AppHarness(
        fakeStorage: FakeSecureStorage(),
        extraOverrides: [
          authProvider.overrideWith(() => _DioOverrideAuth(authMockDio)),
        ],
      );

      await harness.pump(tester);
      await harness.init(tester);

      // Start on /signup.
      harness.read(appRouterProvider).go('/signup');
      await tester.pumpAndSettle();
      expect(find.byType(SignupScreen), findsOneWidget);

      // Fill in the form with mismatched passwords.
      await tester.enterText(
        find.widgetWithText(TextFormField, 'First name'),
        'Bob',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Last name'),
        'Johnson',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'bob@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'SecurePass123',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirm password'),
        'DifferentPass456',
      );

      // Submit the form.
      await tester.tap(find.byType(FilledButton).first);
      await tester.pumpAndSettle();

      // Auth state must remain unauthenticated (no Dio call was made).
      final authState = harness.read(authProvider);
      expect(authState, equals(const AuthState.unauthenticated()));

      // Still on SignupScreen.
      expect(find.byType(SignupScreen), findsOneWidget);
      expect(find.byType(DashboardScreen), findsNothing);

      // A validation error message must be visible.
      // The SignupScreen validates that password2 matches password1.
      final validationError = find.textContaining('Passwords do not match');
      expect(
        validationError.evaluate().isNotEmpty,
        isTrue,
        reason: 'Expected password mismatch validation error on SignupScreen',
      );

      // Verify that the signup Dio method was never called.
      verifyNever(
        () => authMockDio.post<Map<String, dynamic>>(
          '/api/auth/signup/',
          data: any(named: 'data'),
          options: any(named: 'options'),
          queryParameters: any(named: 'queryParameters'),
          cancelToken: any(named: 'cancelToken'),
          onSendProgress: any(named: 'onSendProgress'),
          onReceiveProgress: any(named: 'onReceiveProgress'),
        ),
      );
    });
  });
}
