// Router guard tests — verifies that the GoRouter redirect logic correctly
// guards protected routes and auth-only routes for all AuthState variants.
//
// Approach: widget-based tests using the real appRouterProvider wired to a
// fake authProvider override.  Each test pumps a full MaterialApp.router,
// navigates to the target path, and asserts on the rendered screen type or
// visible text — the observable consequence of the redirect firing.
//
// The redirect function is defined inline inside the GoRouter constructor
// (app_router.dart), so it cannot be called directly without a widget tree.
// We therefore use testWidgets throughout.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:vedgy/models/listing.dart';
import 'package:vedgy/models/user.dart';
import 'package:vedgy/providers/auth_provider.dart';
import 'package:vedgy/providers/dashboard_provider.dart';
import 'package:vedgy/providers/listings_provider.dart';
import 'package:vedgy/router/app_router.dart';
import 'package:vedgy/screens/auth/login_screen.dart';
import 'package:vedgy/screens/dashboard_screen.dart';
import 'package:vedgy/screens/home_screen.dart';
import 'package:vedgy/services/secure_storage.dart';

// ---------------------------------------------------------------------------
// Minimal User for the authenticated state.
// ---------------------------------------------------------------------------

const _kTestUser = User(
  id: 'test-uuid-001',
  email: 'test@example.com',
  firstName: 'Test',
  lastName: 'User',
);

// ---------------------------------------------------------------------------
// Fake auth notifiers — each returns a fixed AuthState with no I/O.
// ---------------------------------------------------------------------------

/// Returns unauthenticated immediately; never touches secure storage.
class _UnauthenticatedAuth extends Auth {
  @override
  AuthState build() => const AuthState.unauthenticated();
}

/// Returns authenticated immediately with a hard-coded user + token.
class _AuthenticatedAuth extends Auth {
  @override
  AuthState build() =>
      const AuthState.authenticated(_kTestUser, 'fake-access-token');
}

/// Stays in initial/loading state forever (simulates app startup before the
/// token restore completes).
class _InitialAuth extends Auth {
  @override
  AuthState build() => const AuthState.initial();
}

// ---------------------------------------------------------------------------
// Fake secure storage — prevents flutter_secure_storage from opening a
// platform channel (which would crash in a headless test environment).
// ---------------------------------------------------------------------------

class _FakeStorage extends SecureStorageService {
  @override
  Future<void> saveRefreshToken(String token) async {}
  @override
  Future<String?> getRefreshToken() async => null;
  @override
  Future<void> clearTokens() async {}
}

// ---------------------------------------------------------------------------
// Fake data for providers that make HTTP calls.
// ---------------------------------------------------------------------------

final _emptyDashboard = DashboardOut(
  drafts: const [],
  paymentSubmitted: const [],
  active: const [],
  expired: const [],
  deactivated: const [],
);

final _emptyListings = PaginatedListings(
  items: const [],
  count: 0,
  page: 1,
  pageSize: 20,
);

// ---------------------------------------------------------------------------
// Helper: temporarily suppress FlutterError layout-overflow assertions.
//
// LoginScreen contains a Row (line 156) that overflows at the fixed card
// width when test fonts are used.  This is a pre-existing cosmetic issue in
// the LoginScreen widget that is unrelated to the routing logic we are
// testing here.  We suppress overflow errors so they don't surface as test
// failures in router-guard tests.
// ---------------------------------------------------------------------------

T _withOverflowSuppressed<T>(T Function() body) {
  final original = FlutterError.onError;
  FlutterError.onError = (details) {
    if (details.exceptionAsString().contains('overflowed')) return;
    original?.call(details);
  };
  try {
    return body();
  } finally {
    FlutterError.onError = original;
  }
}

// ---------------------------------------------------------------------------
// Helper: pump a full app with the real appRouterProvider and a fake auth.
//
// Notes:
//  • dashboardProvider and browseListingsProvider are overridden so that
//    DashboardScreen and BrowseScreen never make real HTTP requests.
//  • For routes with persistent animations (CircularProgressIndicator) use
//    pump() rather than pumpAndSettle() to avoid timing out.
// ---------------------------------------------------------------------------

Future<GoRouter> _pumpApp(
  WidgetTester tester, {
  required Override authOverride,
}) async {
  late GoRouter router;

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        secureStorageProvider.overrideWithValue(_FakeStorage()),
        authOverride,
        dashboardProvider.overrideWith((_) async => _emptyDashboard),
        browseListingsProvider.overrideWith((_) async => _emptyListings),
      ],
      child: Consumer(
        builder: (ctx, ref, _) {
          router = ref.watch(appRouterProvider);
          return MaterialApp.router(
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF2D6A4F),
              ),
              useMaterial3: true,
            ),
            routerConfig: router,
          );
        },
      ),
    ),
  );

  // One frame so the initial route renders; subsequent navigation is triggered
  // by calling router.go(...) in each test.
  await tester.pump();
  return router;
}

// ---------------------------------------------------------------------------
// Helper: navigate and pump, suppressing overflow errors.
// ---------------------------------------------------------------------------

Future<void> _navigate(
  WidgetTester tester,
  GoRouter router,
  String location,
) async {
  _withOverflowSuppressed(() => router.go(location));
  await tester.pump();
  // Suppress overflow in the settle phase too.
  final original = FlutterError.onError;
  FlutterError.onError = (details) {
    if (details.exceptionAsString().contains('overflowed')) return;
    original?.call(details);
  };
  await tester.pump(const Duration(milliseconds: 300));
  FlutterError.onError = original;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('Router guard — unauthenticated user', () {
    testWidgets('accessing /dashboard redirects to /login', (tester) async {
      final router = await _pumpApp(
        tester,
        authOverride: authProvider.overrideWith(_UnauthenticatedAuth.new),
      );

      await _navigate(tester, router, '/dashboard');

      // The guard produces /login?redirect=%2Fdashboard → LoginScreen renders.
      expect(find.byType(LoginScreen), findsOneWidget);
      // The 'Email' label on the login form confirms we are on LoginScreen.
      expect(find.text('Email'), findsOneWidget);
    });

    testWidgets('accessing /create redirects to /login', (tester) async {
      final router = await _pumpApp(
        tester,
        authOverride: authProvider.overrideWith(_UnauthenticatedAuth.new),
      );

      await _navigate(tester, router, '/create');

      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('accessing /login is allowed — no redirect occurs', (
      tester,
    ) async {
      final router = await _pumpApp(
        tester,
        authOverride: authProvider.overrideWith(_UnauthenticatedAuth.new),
      );

      await _navigate(tester, router, '/login');

      // /login is not a protected route; unauthenticated users may access it.
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('accessing / (home) is allowed — no redirect occurs', (
      tester,
    ) async {
      await _pumpApp(
        tester,
        authOverride: authProvider.overrideWith(_UnauthenticatedAuth.new),
      );

      await tester.pump(const Duration(milliseconds: 300));

      // The app starts at initialLocation '/'; HomeScreen should render.
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text('Find vegan-friendly housing.'), findsOneWidget);
    });
  });

  group('Router guard — authenticated user', () {
    testWidgets('accessing /login redirects to /dashboard', (tester) async {
      final router = await _pumpApp(
        tester,
        authOverride: authProvider.overrideWith(_AuthenticatedAuth.new),
      );

      await _navigate(tester, router, '/login');

      // Authenticated users are redirected away from /login → /dashboard.
      expect(find.byType(DashboardScreen), findsOneWidget);
      // LoginScreen must NOT be present.
      expect(find.byType(LoginScreen), findsNothing);
    });

    testWidgets('accessing /signup redirects to /dashboard', (tester) async {
      final router = await _pumpApp(
        tester,
        authOverride: authProvider.overrideWith(_AuthenticatedAuth.new),
      );

      await _navigate(tester, router, '/signup');

      expect(find.byType(DashboardScreen), findsOneWidget);
    });

    testWidgets('accessing /dashboard is allowed — no redirect', (
      tester,
    ) async {
      final router = await _pumpApp(
        tester,
        authOverride: authProvider.overrideWith(_AuthenticatedAuth.new),
      );

      await _navigate(tester, router, '/dashboard');

      expect(find.byType(DashboardScreen), findsOneWidget);
    });

    testWidgets(
      'accessing /login?redirect=%2Fabout follows the redirect param',
      (tester) async {
        final router = await _pumpApp(
          tester,
          authOverride: authProvider.overrideWith(_AuthenticatedAuth.new),
        );

        // Authenticated redirect reads ?redirect= and follows it instead of
        // /dashboard when the redirect value starts with '/'.
        await _navigate(tester, router, '/login?redirect=%2Fabout');

        // We should NOT remain on the login page.
        expect(find.byType(LoginScreen), findsNothing);
        // We should NOT land on the dashboard (redirect param was /about).
        expect(find.byType(DashboardScreen), findsNothing);
        // We should be on the About page.
        expect(find.text('About Vedgy'), findsOneWidget);
      },
    );
  });

  group('Router guard — initial/loading state', () {
    testWidgets('accessing /dashboard redirects to / (shows loading spinner)', (
      tester,
    ) async {
      final router = await _pumpApp(
        tester,
        authOverride: authProvider.overrideWith(_InitialAuth.new),
      );

      router.go('/dashboard');
      // Use pump() rather than pumpAndSettle(): CircularProgressIndicator
      // animates forever and would cause pumpAndSettle to time out.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // The initial state redirect sends protected routes to '/'.
      // HomeScreen renders a CircularProgressIndicator while auth is initial.
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('accessing /create redirects to / (shows loading spinner)', (
      tester,
    ) async {
      final router = await _pumpApp(
        tester,
        authOverride: authProvider.overrideWith(_InitialAuth.new),
      );

      router.go('/create');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets(
      'accessing / is allowed during initial state (shows loading spinner)',
      (tester) async {
        await _pumpApp(
          tester,
          authOverride: authProvider.overrideWith(_InitialAuth.new),
        );

        await tester.pump(const Duration(milliseconds: 50));

        // Not a protected route — no redirect.  HomeScreen shows spinner.
        expect(find.byType(HomeScreen), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      },
    );

    testWidgets('accessing /login is allowed during initial state', (
      tester,
    ) async {
      final router = await _pumpApp(
        tester,
        authOverride: authProvider.overrideWith(_InitialAuth.new),
      );

      await _navigate(tester, router, '/login');

      // /login is not a protected route — initial state does not redirect it.
      expect(find.byType(LoginScreen), findsOneWidget);
    });
  });
}
