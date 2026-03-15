// Integration tests for the GoRouter auth guard.
//
// These tests exercise the redirect callback in app_router.dart using:
//   - Real GoRouter (via AppHarness)
//   - Real Riverpod providers
//   - FakeSecureStorage (no platform channels)
//   - Auth state injected directly via overrideWith to avoid Dio calls
//
// Test cases:
//   1. Unauthenticated user navigating to /dashboard → redirected to /login
//   2. Authenticated user navigating to /dashboard → sees DashboardScreen
//   3. Authenticated user navigating to /login → redirected to /dashboard

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dio/dio.dart';
import 'package:vedgy/models/user.dart';
import 'package:vedgy/providers/auth_provider.dart';
import 'package:vedgy/router/app_router.dart';
import 'package:vedgy/screens/auth/login_screen.dart';
import 'package:vedgy/screens/dashboard_screen.dart';
import 'package:vedgy/services/api_client.dart';

import 'helpers/app_harness.dart';
import 'helpers/fake_secure_storage.dart';
import 'helpers/fixtures.dart';
import 'helpers/mock_dio.dart';

// ---------------------------------------------------------------------------
// Fake Auth notifiers that set a fixed state and ignore init()
// ---------------------------------------------------------------------------

/// Auth notifier that immediately sets unauthenticated state.
class _UnauthenticatedAuth extends Auth {
  @override
  AuthState build() => const AuthState.unauthenticated();

  @override
  Future<void> init() async {
    // State is already set by build(); nothing to do.
  }
}

/// Auth notifier that immediately sets authenticated state using the
/// test fixture user and a dummy access token.
class _AuthenticatedAuth extends Auth {
  @override
  AuthState build() => AuthState.authenticated(
    User.fromJson(userJson),
    validTokensJson['access'] as String,
  );

  @override
  Future<void> init() async {
    // State is already set by build(); nothing to do.
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

  group('Auth guard', () {
    // -----------------------------------------------------------------------
    // 1. Unauthenticated user navigates to /dashboard
    //    Expected: router redirects to /login
    // -----------------------------------------------------------------------
    testWidgets(
      'unauthenticated user navigating to /dashboard redirects to /login',
      (tester) async {
        _configureView(tester);

        final harness = AppHarness(
          fakeStorage: FakeSecureStorage(),
          extraOverrides: [
            authProvider.overrideWith(() => _UnauthenticatedAuth()),
          ],
        );

        await harness.pump(tester);
        // init() is a no-op in _UnauthenticatedAuth; pumpAndSettle lets the
        // router process the initial redirect.
        await harness.init(tester);

        // Navigate to the protected route.
        harness.read(appRouterProvider).go('/dashboard');
        await tester.pumpAndSettle();

        // Guard should have redirected to /login.
        expect(find.byType(LoginScreen), findsOneWidget);
        expect(find.byType(DashboardScreen), findsNothing);
      },
    );

    // -----------------------------------------------------------------------
    // 2. Authenticated user navigates to /dashboard
    //    Expected: DashboardScreen is shown (no redirect).
    //    The dashboard makes an API call to /api/listings/dashboard/ which we
    //    stub with a MockDio override on apiClientProvider.
    // -----------------------------------------------------------------------
    testWidgets(
      'authenticated user navigating to /dashboard shows DashboardScreen',
      (tester) async {
        _configureView(tester);

        final mockDio = MockDio();

        // Stub the dashboard API call so DashboardScreen can render its data.
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
          (_) async =>
              okResponse(emptyDashboardJson, '/api/listings/dashboard/'),
        );

        final harness = AppHarness(
          fakeStorage: FakeSecureStorage(),
          extraOverrides: [
            authProvider.overrideWith(() => _AuthenticatedAuth()),
            apiClientProvider.overrideWithValue(mockDio),
          ],
        );

        await harness.pump(tester);
        await harness.init(tester);

        // Navigate to the protected route.
        harness.read(appRouterProvider).go('/dashboard');
        await tester.pumpAndSettle();

        // Auth state must be authenticated.
        final authState = harness.read(authProvider);
        expect(
          authState.whenOrNull(authenticated: (user, token) => true),
          isTrue,
        );

        // DashboardScreen must be visible; login screen must not be.
        expect(find.byType(DashboardScreen), findsOneWidget);
        expect(find.byType(LoginScreen), findsNothing);
      },
    );

    // -----------------------------------------------------------------------
    // 3. Authenticated user navigates to /login
    //    Expected: router redirects to /dashboard (auth-only route guard).
    // -----------------------------------------------------------------------
    testWidgets(
      'authenticated user navigating to /login redirects to /dashboard',
      (tester) async {
        _configureView(tester);

        final mockDio = MockDio();

        // Stub the dashboard API call for the redirect destination.
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
          (_) async =>
              okResponse(emptyDashboardJson, '/api/listings/dashboard/'),
        );

        final harness = AppHarness(
          fakeStorage: FakeSecureStorage(),
          extraOverrides: [
            authProvider.overrideWith(() => _AuthenticatedAuth()),
            apiClientProvider.overrideWithValue(mockDio),
          ],
        );

        await harness.pump(tester);
        await harness.init(tester);

        // Navigate to the auth-only route.
        harness.read(appRouterProvider).go('/login');
        await tester.pumpAndSettle();

        // Guard should have redirected to /dashboard.
        expect(find.byType(DashboardScreen), findsOneWidget);
        expect(find.byType(LoginScreen), findsNothing);
      },
    );
  });
}
