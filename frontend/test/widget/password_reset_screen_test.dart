// Widget tests for PasswordResetScreen.
//
// The screen is a ConsumerStatefulWidget that uses:
//   - apiClientProvider (keepAlive Riverpod Dio instance)
//   - Form with a single email TextFormField and a FilledButton
//   - A success state (_SuccessView) shown after a successful API response
//   - A "Back to log in" TextButton that calls Navigator.of(context).pop()
//
// Overrides used in every test:
//   - secureStorageProvider → FakeSecureStorage (no platform channels)
//   - authProvider → AuthState.unauthenticated() (no network calls on start)
//   - apiClientProvider → MockDio (no real network calls; configurable per test)
//
// A minimal GoRouter is constructed so GoRouterState.of(context) is available.
// The /password-reset route is nested under a /login stub so Navigator.pop()
// has a route to pop back to.
//
// NOTE: RenderFlex overflow is suppressed in each test because test-font
// metrics differ from real fonts (known test-environment artefact).

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:vedgy/providers/auth_provider.dart';
import 'package:vedgy/screens/auth/password_reset_screen.dart';
import 'package:vedgy/services/api_client.dart';
import 'package:vedgy/services/secure_storage.dart';

import '../helpers/fake_secure_storage.dart';

// ---------------------------------------------------------------------------
// Mock
// ---------------------------------------------------------------------------

class MockDio extends Mock implements Dio {}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Minimal router that places PasswordResetScreen at /password-reset with a
/// /login stub so that Navigator.pop() has somewhere to return to.
GoRouter _makeRouter() => GoRouter(
  initialLocation: '/password-reset',
  routes: [
    GoRoute(
      path: '/login',
      builder: (_, __) => const Scaffold(body: Text('Log in page')),
    ),
    GoRoute(
      path: '/password-reset',
      builder: (_, __) => const PasswordResetScreen(),
    ),
  ],
);

/// Wraps the router inside a ProviderScope with the required overrides.
/// [mockDio] is used to control what the apiClientProvider returns.
Widget _buildApp(MockDio mockDio) {
  return ProviderScope(
    overrides: [
      secureStorageProvider.overrideWithValue(FakeSecureStorage()),
      authProvider.overrideWithValue(const AuthState.unauthenticated()),
      apiClientProvider.overrideWithValue(mockDio),
    ],
    child: MaterialApp.router(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      routerConfig: _makeRouter(),
    ),
  );
}

/// Sets up a wide viewport and suppresses RenderFlex overflow errors that
/// occur in the test environment because test-font metrics differ from real
/// fonts. Call once at the start of each [testWidgets] callback.
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
  // Register fallback values required by mocktail for Dio type arguments.
  setUpAll(() {
    registerFallbackValue(RequestOptions(path: ''));
  });

  group('PasswordResetScreen', () {
    // -----------------------------------------------------------------------
    // 1. Email field is present
    // -----------------------------------------------------------------------
    testWidgets('renders an email TextFormField', (tester) async {
      _configureView(tester);

      final mockDio = MockDio();
      await tester.pumpWidget(_buildApp(mockDio));
      await tester.pumpAndSettle();

      expect(find.byType(TextFormField), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // 2. Submit button is visible
    // -----------------------------------------------------------------------
    testWidgets('renders a Send reset link submit button', (tester) async {
      _configureView(tester);

      final mockDio = MockDio();
      await tester.pumpWidget(_buildApp(mockDio));
      await tester.pumpAndSettle();

      expect(
        find.widgetWithText(FilledButton, 'Send reset link'),
        findsOneWidget,
      );
    });

    // -----------------------------------------------------------------------
    // 3. Validation on empty submit
    // -----------------------------------------------------------------------
    testWidgets('shows email validation error on empty submit', (tester) async {
      _configureView(tester);

      final mockDio = MockDio();
      await tester.pumpWidget(_buildApp(mockDio));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Send reset link'));
      await tester.pump();

      expect(find.text('Email is required'), findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // 4. Validation rejects malformed email
    // -----------------------------------------------------------------------
    testWidgets('shows invalid email error for malformed email', (
      tester,
    ) async {
      _configureView(tester);

      final mockDio = MockDio();
      await tester.pumpWidget(_buildApp(mockDio));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), 'notanemail');
      await tester.tap(find.widgetWithText(FilledButton, 'Send reset link'));
      await tester.pump();

      expect(find.text('Enter a valid email address'), findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // 5. Success state shown after valid submission
    // -----------------------------------------------------------------------
    testWidgets('shows Check your inbox success state after valid submission', (
      tester,
    ) async {
      _configureView(tester);

      final mockDio = MockDio();
      when(
        () => mockDio.post<void>(any(), data: any(named: 'data')),
      ).thenAnswer(
        (_) async => Response<void>(
          requestOptions: RequestOptions(path: '/api/auth/password-reset/'),
          statusCode: 200,
        ),
      );

      await tester.pumpWidget(_buildApp(mockDio));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), 'user@example.com');
      await tester.tap(find.widgetWithText(FilledButton, 'Send reset link'));
      await tester.pumpAndSettle();

      expect(find.text('Check your inbox'), findsOneWidget);
      expect(find.byType(TextFormField), findsNothing);
    });

    // -----------------------------------------------------------------------
    // 6. Back to log in link is present as a TextButton
    // -----------------------------------------------------------------------
    testWidgets('shows a Back to log in TextButton', (tester) async {
      _configureView(tester);

      final mockDio = MockDio();
      await tester.pumpWidget(_buildApp(mockDio));
      await tester.pumpAndSettle();

      expect(find.text('Back to log in'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Back to log in'), findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // 7. Page heading is shown
    // -----------------------------------------------------------------------
    testWidgets('shows Reset your password heading', (tester) async {
      _configureView(tester);

      final mockDio = MockDio();
      await tester.pumpWidget(_buildApp(mockDio));
      await tester.pumpAndSettle();

      expect(find.text('Reset your password'), findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // 8. No error banner shown on initial render
    // -----------------------------------------------------------------------
    testWidgets('does not show an error banner on first render', (
      tester,
    ) async {
      _configureView(tester);

      final mockDio = MockDio();
      await tester.pumpWidget(_buildApp(mockDio));
      await tester.pumpAndSettle();

      expect(
        find.text('Something went wrong. Please try again.'),
        findsNothing,
      );
      expect(
        find.text('An unexpected error occurred. Please try again.'),
        findsNothing,
      );
    });

    // -----------------------------------------------------------------------
    // 9. Success view shows Back to log in button (OutlinedButton)
    // -----------------------------------------------------------------------
    testWidgets('success view shows a Back to log in OutlinedButton', (
      tester,
    ) async {
      _configureView(tester);

      final mockDio = MockDio();
      when(
        () => mockDio.post<void>(any(), data: any(named: 'data')),
      ).thenAnswer(
        (_) async => Response<void>(
          requestOptions: RequestOptions(path: '/api/auth/password-reset/'),
          statusCode: 200,
        ),
      );

      await tester.pumpWidget(_buildApp(mockDio));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), 'user@example.com');
      await tester.tap(find.widgetWithText(FilledButton, 'Send reset link'));
      await tester.pumpAndSettle();

      expect(
        find.widgetWithText(OutlinedButton, 'Back to log in'),
        findsOneWidget,
      );
    });
  });
}
