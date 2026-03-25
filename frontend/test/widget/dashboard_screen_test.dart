// Widget tests for DashboardScreen.
//
// DashboardScreen is a ConsumerWidget that watches dashboardProvider
// (an AutoDisposeFutureProvider returning AsyncValue<DashboardOut>).
//
// The three async states are exercised:
//   - loading  → _SkeletonDashboard (no CircularProgressIndicator;
//                a custom skeleton using Container boxes)
//   - error    → "Something went wrong. Please try again." + Retry button
//   - data     → sections for Active, Drafts, Under Review, Expired,
//                Deactivated with empty-state text when lists are empty,
//                and listing titles/cards when lists are populated.
//
// Overrides used in every test:
//   - secureStorageProvider → FakeSecureStorage (no platform channels)
//   - authProvider          → AuthState.unauthenticated() (no network calls)
//   - dashboardProvider     → overrideWithValue(...) to control async state
//
// NOTE: We use overrideWithValue(AsyncValue.error/loading/data) rather than
// overrideWith((ref) async { throw ... }) because the async-throw approach
// leaves the provider in loading state in the test environment — the async
// exception is not guaranteed to land before pumpAndSettle returns.  Using
// overrideWithValue allows synchronous control of the provider state.
//
// A minimal GoRouter is used so context.go('/create') etc. are available.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:vedgy/models/listing.dart';
import 'package:vedgy/models/user.dart';
import 'package:vedgy/providers/auth_provider.dart';
import 'package:vedgy/providers/dashboard_provider.dart';
import 'package:vedgy/screens/dashboard_screen.dart';
import 'package:vedgy/services/secure_storage.dart';

import '../helpers/fake_secure_storage.dart';
import '../helpers/test_fixtures.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Minimal GoRouter placing DashboardScreen at /dashboard with stub routes
/// for other paths the screen may navigate to.
GoRouter _makeRouter() => GoRouter(
  initialLocation: '/dashboard',
  routes: [
    GoRoute(path: '/dashboard', builder: (_, __) => const DashboardScreen()),
    GoRoute(
      path: '/create',
      builder: (_, __) => const Scaffold(body: Text('Create listing page')),
    ),
    GoRoute(
      path: '/listing/:id',
      builder: (_, __) => const Scaffold(body: Text('Listing detail page')),
    ),
    GoRoute(
      path: '/edit/:id',
      builder: (_, __) => const Scaffold(body: Text('Edit listing page')),
    ),
  ],
);

/// Wraps the router inside a ProviderScope with the required overrides.
///
/// [authState] defaults to [AuthState.unauthenticated()].  Pass an
/// authenticated state for tests that need it.  The dashboard async value
/// is supplied via [dashboardValue].
Widget _buildApp({
  required AsyncValue<DashboardOut> dashboardValue,
  AuthState authState = const AuthState.unauthenticated(),
}) {
  return ProviderScope(
    overrides: [
      secureStorageProvider.overrideWithValue(FakeSecureStorage()),
      authProvider.overrideWithValue(authState),
      dashboardProvider.overrideWithValue(dashboardValue),
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

/// Constructs an [AsyncValue.data] wrapping an empty [DashboardOut].
AsyncValue<DashboardOut> _emptyDashboardValue() =>
    AsyncValue.data(DashboardOut.fromJson(emptyDashboardJson));

/// Constructs an [AsyncValue.data] with one active listing.
AsyncValue<DashboardOut> _activeDashboardValue() {
  final listing = Listing.fromJson(testListingJson);
  return AsyncValue.data(
    DashboardOut(
      drafts: const [],
      paymentSubmitted: const [],
      active: [listing],
      expired: const [],
      deactivated: const [],
    ),
  );
}

/// Constructs an [AsyncValue.data] with one listing in each section.
AsyncValue<DashboardOut> _allSectionsDashboardValue() {
  final activeListing = Listing.fromJson(testListingJson);
  final draftListing = Listing.fromJson({
    ...testListingJson,
    'id': 'listing-uuid-002',
    'title': 'Draft Room',
    'status': 'draft',
  });
  final submittedListing = Listing.fromJson({
    ...testListingJson,
    'id': 'listing-uuid-003',
    'title': 'Under Review Room',
    'status': 'payment_submitted',
  });
  final expiredListing = Listing.fromJson({
    ...testListingJson,
    'id': 'listing-uuid-004',
    'title': 'Expired Room',
    'status': 'expired',
  });
  final deactivatedListing = Listing.fromJson({
    ...testListingJson,
    'id': 'listing-uuid-005',
    'title': 'Deactivated Room',
    'status': 'deactivated',
  });
  return AsyncValue.data(
    DashboardOut(
      drafts: [draftListing],
      paymentSubmitted: [submittedListing],
      active: [activeListing],
      expired: [expiredListing],
      deactivated: [deactivatedListing],
    ),
  );
}

/// An [AsyncValue.error] to exercise the error branch.
final _errorDashboardValue = AsyncValue<DashboardOut>.error(
  'Network error',
  StackTrace.empty,
);

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('DashboardScreen', () {
    // -----------------------------------------------------------------------
    // 1. Loading state: skeleton dashboard is shown
    // -----------------------------------------------------------------------
    testWidgets('shows skeleton loading state while provider is loading', (
      tester,
    ) async {
      _configureView(tester);

      await tester.pumpWidget(
        _buildApp(dashboardValue: const AsyncValue.loading()),
      );

      await tester.pump();

      // No data content visible while loading.
      expect(find.text('My Listings'), findsNothing);
      expect(find.textContaining('Something went wrong'), findsNothing);

      // The Scaffold is always rendered.
      expect(find.byType(Scaffold), findsOneWidget);

      // No error icon in loading state.
      expect(
        find.byWidgetPredicate(
          (w) => w is Icon && w.icon == Icons.error_outline,
        ),
        findsNothing,
      );
    });

    // -----------------------------------------------------------------------
    // 2. Empty state: all sections show empty-text messages
    // -----------------------------------------------------------------------
    testWidgets('shows empty state messages when dashboard has no listings', (
      tester,
    ) async {
      _configureView(tester);

      await tester.pumpWidget(
        _buildApp(dashboardValue: _emptyDashboardValue()),
      );

      await tester.pumpAndSettle();

      // Header is visible.
      expect(find.text('My Listings'), findsOneWidget);

      // Each section shows its empty-state copy.
      expect(find.text('No active listings.'), findsOneWidget);
      expect(find.text('No drafts.'), findsOneWidget);
      expect(find.text('No listings pending review.'), findsOneWidget);
      expect(find.text('No expired listings.'), findsOneWidget);
      expect(find.text('No deactivated listings.'), findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // 3. Section headings include counts
    // -----------------------------------------------------------------------
    testWidgets('shows section headings with zero counts when empty', (
      tester,
    ) async {
      _configureView(tester);

      await tester.pumpWidget(
        _buildApp(dashboardValue: _emptyDashboardValue()),
      );

      await tester.pumpAndSettle();

      // Each section heading has the format "Title (count)".
      expect(find.text('Active (0)'), findsOneWidget);
      expect(find.text('Drafts (0)'), findsOneWidget);
      expect(find.text('Under Review (0)'), findsOneWidget);
      expect(find.text('Expired (0)'), findsOneWidget);
      expect(find.text('Deactivated (0)'), findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // 4. Listings shown: cards appear for each listing
    // -----------------------------------------------------------------------
    testWidgets('shows listing card when active listing is present', (
      tester,
    ) async {
      _configureView(tester);

      await tester.pumpWidget(
        _buildApp(dashboardValue: _activeDashboardValue()),
      );

      await tester.pumpAndSettle();

      // The listing title from testListingJson should be visible.
      expect(find.text('Cozy Vegan Room'), findsOneWidget);

      // The active section shows count 1.
      expect(find.text('Active (1)'), findsOneWidget);

      // The empty-text for active section should not appear.
      expect(find.text('No active listings.'), findsNothing);
    });

    // -----------------------------------------------------------------------
    // 5. Listings in all sections are shown
    // -----------------------------------------------------------------------
    testWidgets('shows listing titles across all sections', (tester) async {
      _configureView(tester);

      await tester.pumpWidget(
        _buildApp(dashboardValue: _allSectionsDashboardValue()),
      );

      await tester.pumpAndSettle();

      expect(find.text('Cozy Vegan Room'), findsOneWidget);
      expect(find.text('Draft Room'), findsOneWidget);
      expect(find.text('Under Review Room'), findsOneWidget);
      expect(find.text('Expired Room'), findsOneWidget);
      expect(find.text('Deactivated Room'), findsOneWidget);

      // Counts all show 1.
      expect(find.text('Active (1)'), findsOneWidget);
      expect(find.text('Drafts (1)'), findsOneWidget);
      expect(find.text('Under Review (1)'), findsOneWidget);
      expect(find.text('Expired (1)'), findsOneWidget);
      expect(find.text('Deactivated (1)'), findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // 6. Error state: shows error icon and Retry button
    // -----------------------------------------------------------------------
    testWidgets('shows error icon and Retry button when provider fails', (
      tester,
    ) async {
      _configureView(tester);

      await tester.pumpWidget(_buildApp(dashboardValue: _errorDashboardValue));

      await tester.pumpAndSettle();

      // Error icon is shown (use byWidgetPredicate per established pattern).
      expect(
        find.byWidgetPredicate(
          (w) => w is Icon && w.icon == Icons.error_outline,
        ),
        findsOneWidget,
      );

      // Retry button is present.
      expect(find.widgetWithText(FilledButton, 'Retry'), findsOneWidget);

      // No listing content is shown.
      expect(find.text('My Listings'), findsNothing);
    });

    // -----------------------------------------------------------------------
    // 7. Error state: error message text contains the provider error
    // -----------------------------------------------------------------------
    testWidgets('shows error message text when provider fails', (tester) async {
      _configureView(tester);

      await tester.pumpWidget(_buildApp(dashboardValue: _errorDashboardValue));

      await tester.pumpAndSettle();

      // The error state now shows a user-friendly message (not the raw exception).
      expect(find.textContaining('Something went wrong'), findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // 8. "Post a listing" button is visible on data state
    // -----------------------------------------------------------------------
    testWidgets('shows Post a listing button in data state', (tester) async {
      _configureView(tester);

      await tester.pumpWidget(
        _buildApp(dashboardValue: _emptyDashboardValue()),
      );

      await tester.pumpAndSettle();

      expect(find.text('Post a listing'), findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // 9. Authenticated required: dashboard shows user's listings with
    //    authenticated auth state override
    // -----------------------------------------------------------------------
    testWidgets(
      'shows dashboard data when authenticated with an active listing',
      (tester) async {
        _configureView(tester);

        const testUser = User(
          id: 'user-uuid-001',
          email: 'test@example.com',
          firstName: 'Test',
          lastName: 'User',
        );

        await tester.pumpWidget(
          _buildApp(
            authState: const AuthState.authenticated(
              testUser,
              'test-access-token',
            ),
            dashboardValue: _activeDashboardValue(),
          ),
        );

        await tester.pumpAndSettle();

        // Dashboard content is rendered for the authenticated user.
        expect(find.text('My Listings'), findsOneWidget);
        expect(find.text('Cozy Vegan Room'), findsOneWidget);
        expect(find.text('Active (1)'), findsOneWidget);
      },
    );

    // -----------------------------------------------------------------------
    // 10. Listing card shows city and price
    // -----------------------------------------------------------------------
    testWidgets('listing card shows city and price', (tester) async {
      _configureView(tester);

      await tester.pumpWidget(
        _buildApp(dashboardValue: _activeDashboardValue()),
      );

      await tester.pumpAndSettle();

      // testListingJson has city: "New York" and price: 1200.
      expect(find.textContaining('New York'), findsOneWidget);
      expect(find.textContaining('\$1200/mo'), findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // 11. Error state: no section headings shown
    // -----------------------------------------------------------------------
    testWidgets('does not show section headings in error state', (
      tester,
    ) async {
      _configureView(tester);

      await tester.pumpWidget(_buildApp(dashboardValue: _errorDashboardValue));

      await tester.pumpAndSettle();

      // Section headings must not appear in the error state.
      expect(find.text('Active (0)'), findsNothing);
      expect(find.text('Drafts (0)'), findsNothing);
    });
  });
}
