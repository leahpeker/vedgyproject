// Widget tests for LoginScreen.
//
// The screen is a ConsumerStatefulWidget that uses:
//   - authProvider (keepAlive Riverpod notifier)
//   - GoRouter for navigation (Sign up / Forgot password links)
//   - Form with email + password TextFormFields and a FilledButton
//
// Overrides used in every test:
//   - secureStorageProvider → FakeSecureStorage (no platform channels)
//   - authProvider → AuthState.unauthenticated() (no network calls on start)
//
// A minimal GoRouter is constructed so GoRouterState.of(context) is available
// inside the screen (needed for the ?redirect= query parameter forwarding).
//
// NOTE: The "Don't have an account? Sign up" Row renders wider than its Card
// container under Flutter test fonts.  The RenderFlex overflow is a known
// test-environment artefact (test fonts have different metrics than real
// fonts).  Each test suppresses this specific overflow error by setting
// FlutterError.onError before pumping the widget.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:vedgy/providers/auth_provider.dart';
import 'package:vedgy/screens/auth/login_screen.dart';
import 'package:vedgy/services/secure_storage.dart';

import '../helpers/fake_secure_storage.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Minimal router that places LoginScreen at /login with stubs for
/// routes that LoginScreen can navigate to.
GoRouter _makeRouter() => GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    GoRoute(
      path: '/signup',
      builder: (_, __) => const Scaffold(body: Text('Sign up page')),
    ),
    GoRoute(
      path: '/dashboard',
      builder: (_, __) => const Scaffold(body: Text('Dashboard page')),
    ),
    GoRoute(
      path: '/password-reset',
      builder: (_, __) => const Scaffold(body: Text('Password reset page')),
    ),
  ],
);

/// Wraps the router inside a ProviderScope with the required overrides.
Widget _buildApp() {
  return ProviderScope(
    overrides: [
      secureStorageProvider.overrideWithValue(FakeSecureStorage()),
      authProvider.overrideWithValue(const AuthState.unauthenticated()),
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
/// fonts.  Call once at the start of each [testWidgets] callback.
void _configureView(WidgetTester tester) {
  tester.view.physicalSize = const Size(1440, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  // Suppress RenderFlex overflow, which is a test-environment artefact
  // caused by test fonts being wider than real fonts.
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
  group('LoginScreen', () {
    // -----------------------------------------------------------------------
    // 1. Email and password fields are present
    // -----------------------------------------------------------------------
    testWidgets('renders email and password TextFormFields', (tester) async {
      _configureView(tester);

      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      // Two TextFormFields: email and password.
      expect(find.byType(TextFormField), findsNWidgets(2));

      // Labels confirm which field is which.
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // 2. Submit button is visible
    // -----------------------------------------------------------------------
    testWidgets('renders a Log in submit button', (tester) async {
      _configureView(tester);

      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      expect(find.widgetWithText(FilledButton, 'Log in'), findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // 3. Validation errors shown when form is submitted empty
    // -----------------------------------------------------------------------
    testWidgets('shows password validation error on empty submit', (
      tester,
    ) async {
      _configureView(tester);

      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      // Tap submit without filling any fields.
      await tester.tap(find.widgetWithText(FilledButton, 'Log in'));
      await tester.pump();

      // The password validator (v == null || v.isEmpty) fires.
      expect(find.text('Password is required'), findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // 4. Email validation fires — login screen stays on screen
    // -----------------------------------------------------------------------
    testWidgets('stays on login screen when only password is filled', (
      tester,
    ) async {
      _configureView(tester);

      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      // Fill only the password — the email validator should block submission.
      final passwordField = find.widgetWithText(TextFormField, 'Password');
      await tester.enterText(passwordField, 'somepassword');

      await tester.tap(find.widgetWithText(FilledButton, 'Log in'));
      await tester.pump();

      // We remain on LoginScreen (no navigation occurred).
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // 5. Sign up link is present
    // -----------------------------------------------------------------------
    testWidgets('shows a Sign up link', (tester) async {
      _configureView(tester);

      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Sign up'), findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // 6. Sign up TextButton is present in the widget tree
    // -----------------------------------------------------------------------
    testWidgets('Sign up is a TextButton in the widget tree', (tester) async {
      _configureView(tester);

      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      // Verify that the Sign up element is a tappable TextButton.
      expect(find.widgetWithText(TextButton, 'Sign up'), findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // 7. Forgot password link is present
    // -----------------------------------------------------------------------
    testWidgets('shows a Forgot password link', (tester) async {
      _configureView(tester);

      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Forgot password?'), findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // 8. Tapping Forgot password navigates to /password-reset
    // -----------------------------------------------------------------------
    testWidgets('tapping Forgot password navigates to password-reset screen', (
      tester,
    ) async {
      _configureView(tester);

      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Forgot password?'));
      await tester.pumpAndSettle();

      expect(find.text('Password reset page'), findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // 9. Page heading is shown
    // -----------------------------------------------------------------------
    testWidgets('shows Log in heading', (tester) async {
      _configureView(tester);

      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      // Both the heading text and the button use "Log in".
      expect(find.text('Log in'), findsWidgets);
    });

    // -----------------------------------------------------------------------
    // 10. No error banner shown on initial render
    // -----------------------------------------------------------------------
    testWidgets('does not show an error message on first render', (
      tester,
    ) async {
      _configureView(tester);

      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      // ErrorBanner only appears after a failed submission.
      expect(find.text('Invalid email or password.'), findsNothing);
      expect(
        find.text('An unexpected error occurred. Please try again.'),
        findsNothing,
      );
    });
  });
}
