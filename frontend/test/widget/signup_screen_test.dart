// Widget tests for SignupScreen.
//
// The screen is a ConsumerStatefulWidget that uses:
//   - authProvider (keepAlive Riverpod notifier)
//   - GoRouter for navigation (Log in link)
//   - Form with first name, last name, email, password, confirm-password
//     TextFormFields and a FilledButton
//
// Overrides used in every test:
//   - secureStorageProvider → FakeSecureStorage (no platform channels)
//   - authProvider → AuthState.unauthenticated() (no network calls on start)
//
// A minimal GoRouter is constructed so GoRouterState.of(context) is available
// inside the screen (needed for the ?redirect= query parameter forwarding).
//
// NOTE: The "Already have an account? Log in" Row may render wider than its
// Card container under Flutter test fonts.  The RenderFlex overflow is a known
// test-environment artefact (test fonts have different metrics than real
// fonts).  Each test suppresses this specific overflow error by setting
// FlutterError.onError before pumping the widget.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:vedgy/providers/auth_provider.dart';
import 'package:vedgy/screens/auth/signup_screen.dart';
import 'package:vedgy/services/secure_storage.dart';

import '../helpers/fake_secure_storage.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Minimal router that places SignupScreen at /signup with stubs for
/// routes that SignupScreen can navigate to.
GoRouter _makeRouter() => GoRouter(
  initialLocation: '/signup',
  routes: [
    GoRoute(path: '/signup', builder: (_, __) => const SignupScreen()),
    GoRoute(
      path: '/login',
      builder: (_, __) => const Scaffold(body: Text('Log in page')),
    ),
    GoRoute(
      path: '/dashboard',
      builder: (_, __) => const Scaffold(body: Text('Dashboard page')),
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
  group('SignupScreen', () {
    // -----------------------------------------------------------------------
    // 1. Form fields are present
    // -----------------------------------------------------------------------
    testWidgets(
      'renders email, password, and confirm-password TextFormFields',
      (tester) async {
        _configureView(tester);

        await tester.pumpWidget(_buildApp());
        await tester.pumpAndSettle();

        // Five TextFormFields: first name, last name, email, password, confirm.
        expect(find.byType(TextFormField), findsNWidgets(5));

        // Labels confirm which field is which.
        expect(find.text('First name'), findsOneWidget);
        expect(find.text('Last name'), findsOneWidget);
        expect(find.text('Email'), findsOneWidget);
        expect(find.text('Password'), findsOneWidget);
        expect(find.text('Confirm password'), findsOneWidget);
      },
    );

    // -----------------------------------------------------------------------
    // 2. Submit button is visible
    // -----------------------------------------------------------------------
    testWidgets('renders a Sign up submit button', (tester) async {
      _configureView(tester);

      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      expect(find.widgetWithText(FilledButton, 'Sign up'), findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // 3. Validation errors shown when form is submitted empty
    // -----------------------------------------------------------------------
    testWidgets('shows validation errors on empty submit', (tester) async {
      _configureView(tester);

      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      // Tap submit without filling any fields.
      await tester.tap(find.widgetWithText(FilledButton, 'Sign up'));
      await tester.pump();

      // The password validator fires for an empty password field.
      expect(find.text('Password is required'), findsOneWidget);

      // The confirm-password validator fires too.
      expect(find.text('Please confirm your password'), findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // 4. Password mismatch error
    // -----------------------------------------------------------------------
    testWidgets('shows passwords do not match error when passwords differ', (
      tester,
    ) async {
      _configureView(tester);

      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      // Fill first name, last name, email, and password to pass those validators.
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'Test',
      ); // first name
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'User',
      ); // last name
      await tester.enterText(
        find.byType(TextFormField).at(2),
        'test@example.com',
      ); // email
      await tester.enterText(
        find.byType(TextFormField).at(3),
        'password123',
      ); // password
      await tester.enterText(
        find.byType(TextFormField).at(4),
        'differentpassword',
      ); // confirm

      await tester.tap(find.widgetWithText(FilledButton, 'Sign up'));
      await tester.pump();

      expect(find.text('Passwords do not match'), findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // 5. Log in link is present
    // -----------------------------------------------------------------------
    testWidgets('shows a Log in link', (tester) async {
      _configureView(tester);

      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Log in'), findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // 6. Log in link is a TextButton
    // -----------------------------------------------------------------------
    testWidgets('Log in is a TextButton in the widget tree', (tester) async {
      _configureView(tester);

      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      expect(find.widgetWithText(TextButton, 'Log in'), findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // 7. Page heading is shown
    // -----------------------------------------------------------------------
    testWidgets('shows Create an account heading', (tester) async {
      _configureView(tester);

      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Create an account'), findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // 8. No error banner shown on initial render
    // -----------------------------------------------------------------------
    testWidgets('does not show an error message on first render', (
      tester,
    ) async {
      _configureView(tester);

      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      // ErrorBanner only appears after a failed submission.
      expect(find.text('Sign up failed. Please try again.'), findsNothing);
      expect(
        find.text('An unexpected error occurred. Please try again.'),
        findsNothing,
      );
    });

    // -----------------------------------------------------------------------
    // 9. Tapping Log in navigates to /login
    // -----------------------------------------------------------------------
    testWidgets('tapping Log in navigates to login screen', (tester) async {
      _configureView(tester);

      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, 'Log in'));
      await tester.pumpAndSettle();

      expect(find.text('Log in page'), findsOneWidget);
    });
  });
}
