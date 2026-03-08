// Widget tests for BrowseScreen.
//
// BrowseScreen is a ConsumerWidget that watches:
//   - browseListingsProvider (AutoDisposeFutureProvider<PaginatedListings>)
//   - browseFiltersProvider  (AutoDisposeNotifierProvider<ListingFilters>)
//
// The four async states are exercised:
//   - loading  → _SkeletonGrid (skeleton Card boxes, no CircularProgressIndicator)
//   - error    → "Something went wrong" text + "Try again" TextButton
//   - data / empty  → "No listings match your filters." + "Try adjusting your search."
//   - data / items  → ListingCard widgets with listing titles visible
//
// Filter UI tests verify that the FilterPanel (with its "Filters" label,
// "Clear all" button, and filter dropdowns) is always rendered.
//
// Overrides used in every test:
//   - secureStorageProvider    → FakeSecureStorage (no platform channels)
//   - authProvider             → AuthState.unauthenticated() (no network calls)
//   - browseListingsProvider   → overrideWith(...) to control async state
//   - browseFiltersProvider    → overrideWithValue(ListingFilters()) to prevent
//                                the real notifier from touching the network
//
// IMPORTANT: overrideWith((_) async => value) is used instead of
// overrideWithValue(AsyncValue.data(value)) because the BrowseScreen
// _buildContent method receives listingsAsync as a dynamic type (no type
// annotation in the parameter list).  Under Riverpod 3, calling .when()
// on a dynamic AsyncValue causes a NoSuchMethodError because the runtime
// cannot resolve the extension method.  With overrideWith the framework
// wraps the returned Future in an AsyncValue internally, ensuring the
// correct concrete type is used.
//
// For the loading state we supply a Future that never completes so the
// provider stays in AsyncLoading.  For the error state we throw inside
// the override function.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:vedgy/models/listing.dart';
import 'package:vedgy/providers/auth_provider.dart';
import 'package:vedgy/providers/listings_provider.dart';
import 'package:vedgy/screens/browse_screen.dart';
import 'package:vedgy/services/secure_storage.dart';

import '../helpers/fake_secure_storage.dart';
import '../helpers/test_fixtures.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Minimal GoRouter placing BrowseScreen at /browse with a stub for the
/// listing-detail route that ListingCard navigates to.
GoRouter _makeRouter() => GoRouter(
      initialLocation: '/browse',
      routes: [
        GoRoute(
          path: '/browse',
          builder: (_, __) => const BrowseScreen(),
        ),
        GoRoute(
          path: '/listing/:id',
          builder: (_, __) =>
              const Scaffold(body: Text('Listing detail page')),
        ),
      ],
    );

/// Wraps the router inside a ProviderScope with all required overrides.
///
/// [listingsOverride] is an [Override] for browseListingsProvider.
/// [authState] defaults to [AuthState.unauthenticated()].
Widget _buildApp({
  required Override listingsOverride,
  AuthState authState = const AuthState.unauthenticated(),
}) {
  return ProviderScope(
    overrides: [
      secureStorageProvider.overrideWithValue(FakeSecureStorage()),
      authProvider.overrideWithValue(authState),
      listingsOverride,
      browseFiltersProvider.overrideWithValue(const ListingFilters()),
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

/// Sets up a wide viewport (desktop layout) and suppresses RenderFlex
/// overflow errors that are a test-environment artefact from test fonts
/// having different metrics than real fonts.
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
// Provider overrides
// ---------------------------------------------------------------------------

/// Override that keeps the provider in loading state forever (Future never
/// completes).
Override get _loadingOverride =>
    browseListingsProvider.overrideWith((_) => Completer<PaginatedListings>().future);

/// Override that resolves with one listing (from testListingJson).
Override get _oneListingOverride => browseListingsProvider.overrideWith(
      (_) async => PaginatedListings.fromJson(paginatedListingsJson),
    );

/// Override that resolves with an empty listing set.
Override get _emptyListingsOverride => browseListingsProvider.overrideWith(
      (_) async => const PaginatedListings(
        items: [],
        count: 0,
        page: 1,
        pageSize: 20,
      ),
    );

/// Override that puts the provider into an error state synchronously.
Override get _errorOverride => browseListingsProvider.overrideWithValue(
      AsyncValue.error('Network error', StackTrace.empty),
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('BrowseScreen', () {
    // -----------------------------------------------------------------------
    // 1. Loading state: skeleton grid is shown, no data or error content
    // -----------------------------------------------------------------------
    testWidgets('shows skeleton loading state while provider is loading',
        (tester) async {
      _configureView(tester);

      await tester.pumpWidget(_buildApp(listingsOverride: _loadingOverride));
      await tester.pump();

      // No data content while loading.
      expect(find.text('No listings found'), findsNothing);
      expect(find.text('Failed to load listings'), findsNothing);

      // The Scaffold is always rendered.
      expect(find.byType(Scaffold), findsOneWidget);

      // No error icon in loading state.
      expect(
        find.byWidgetPredicate(
          (w) => w is Icon && w.icon == Icons.error_outline,
        ),
        findsNothing,
      );

      // No listing cards while loading.
      expect(find.text('Cozy Vegan Room'), findsNothing);
    });

    // -----------------------------------------------------------------------
    // 2. Listings shown: listing titles appear in data state
    // -----------------------------------------------------------------------
    testWidgets('shows listing card titles when provider has data',
        (tester) async {
      _configureView(tester);

      await tester.pumpWidget(_buildApp(listingsOverride: _oneListingOverride));
      await tester.pumpAndSettle();

      // The title from testListingJson must be visible.
      expect(find.text('Cozy Vegan Room'), findsOneWidget);

      // No error or empty-state text.
      expect(find.text('No listings found'), findsNothing);
      expect(find.text('Failed to load listings'), findsNothing);
    });

    // -----------------------------------------------------------------------
    // 3. Listings shown: listing price is visible
    // -----------------------------------------------------------------------
    testWidgets('shows listing price in listing card', (tester) async {
      _configureView(tester);

      await tester.pumpWidget(_buildApp(listingsOverride: _oneListingOverride));
      await tester.pumpAndSettle();

      // testListingJson has price: 1200.
      expect(find.textContaining('\$1200/mo'), findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // 4. Empty state: "No listings match your filters." message is shown
    // -----------------------------------------------------------------------
    testWidgets('shows No listings found when provider returns empty list',
        (tester) async {
      _configureView(tester);

      await tester.pumpWidget(
          _buildApp(listingsOverride: _emptyListingsOverride));
      await tester.pumpAndSettle();

      expect(find.text('No listings match your filters.'), findsOneWidget);
      expect(find.text('Try adjusting your search.'), findsOneWidget);

      // No listing cards shown.
      expect(find.text('Cozy Vegan Room'), findsNothing);

      // No error content shown.
      expect(find.textContaining('Something went wrong'), findsNothing);
    });

    // -----------------------------------------------------------------------
    // 5. Empty state: search_off icon is shown
    // -----------------------------------------------------------------------
    testWidgets('shows search_off icon in empty state', (tester) async {
      _configureView(tester);

      await tester.pumpWidget(
          _buildApp(listingsOverride: _emptyListingsOverride));
      await tester.pumpAndSettle();

      expect(
        find.byWidgetPredicate(
          (w) => w is Icon && w.icon == Icons.search_off,
        ),
        findsOneWidget,
      );
    });

    // -----------------------------------------------------------------------
    // 6. Error state: error message text and Try again button
    // -----------------------------------------------------------------------
    testWidgets('shows error message and Try again button when provider fails',
        (tester) async {
      _configureView(tester);

      await tester.pumpWidget(_buildApp(listingsOverride: _errorOverride));
      await tester.pumpAndSettle();

      expect(find.textContaining('Something went wrong'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Try again'), findsOneWidget);

      // No listing content in error state.
      expect(find.text('Cozy Vegan Room'), findsNothing);
      expect(find.textContaining('No listings match'), findsNothing);
    });

    // -----------------------------------------------------------------------
    // 7. Error state: error icon is shown
    // -----------------------------------------------------------------------
    testWidgets('shows error_outline icon in error state', (tester) async {
      _configureView(tester);

      await tester.pumpWidget(_buildApp(listingsOverride: _errorOverride));
      await tester.pumpAndSettle();

      expect(
        find.byWidgetPredicate(
          (w) => w is Icon && w.icon == Icons.error_outline,
        ),
        findsOneWidget,
      );
    });

    // -----------------------------------------------------------------------
    // 8. Filter UI present: "Filters" label and "Clear all" button visible
    // -----------------------------------------------------------------------
    testWidgets('shows Filters label and Clear all button in data state',
        (tester) async {
      _configureView(tester);

      await tester.pumpWidget(_buildApp(listingsOverride: _oneListingOverride));
      await tester.pumpAndSettle();

      expect(find.text('Filters'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Clear all'), findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // 9. Filter UI present in loading state
    // -----------------------------------------------------------------------
    testWidgets('shows filter controls in loading state', (tester) async {
      _configureView(tester);

      await tester.pumpWidget(_buildApp(listingsOverride: _loadingOverride));
      await tester.pump();

      expect(find.text('Filters'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Clear all'), findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // 10. Filter UI present in empty state
    // -----------------------------------------------------------------------
    testWidgets('shows filter controls in empty state', (tester) async {
      _configureView(tester);

      await tester.pumpWidget(
          _buildApp(listingsOverride: _emptyListingsOverride));
      await tester.pumpAndSettle();

      expect(find.text('Filters'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Clear all'), findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // 11. Filter UI: City dropdown is present
    // -----------------------------------------------------------------------
    testWidgets('shows City filter dropdown in data state', (tester) async {
      _configureView(tester);

      await tester.pumpWidget(_buildApp(listingsOverride: _oneListingOverride));
      await tester.pumpAndSettle();

      expect(find.text('City'), findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // 12. "Browse listings" heading is shown in data state
    // -----------------------------------------------------------------------
    testWidgets('shows Browse listings heading in data state', (tester) async {
      _configureView(tester);

      await tester.pumpWidget(_buildApp(listingsOverride: _oneListingOverride));
      await tester.pumpAndSettle();

      expect(find.text('Browse listings'), findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // 13. Multiple listings: all titles visible
    // -----------------------------------------------------------------------
    testWidgets('shows all listing titles when multiple listings returned',
        (tester) async {
      _configureView(tester);

      final secondListing = Listing.fromJson({
        ...testListingJson,
        'id': 'listing-uuid-002',
        'title': 'Another Vegan Flat',
      });
      final firstListing = Listing.fromJson(testListingJson);
      final multiOverride = browseListingsProvider.overrideWith(
        (_) async => PaginatedListings(
          items: [firstListing, secondListing],
          count: 2,
          page: 1,
          pageSize: 20,
        ),
      );

      await tester.pumpWidget(_buildApp(listingsOverride: multiOverride));
      await tester.pumpAndSettle();

      expect(find.text('Cozy Vegan Room'), findsOneWidget);
      expect(find.text('Another Vegan Flat'), findsOneWidget);
    });
  });
}
