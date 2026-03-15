// Widget tests for browse screen pagination behavior.
//
// Uses browseAccumulatorProvider overrides to control accumulated state
// and verify pagination UX: Load more button, result count, and all-loaded state.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:vedgy/models/listing.dart';
import 'package:vedgy/providers/auth_provider.dart';
import 'package:vedgy/providers/browse_accumulator_provider.dart';
import 'package:vedgy/providers/listings_provider.dart';
import 'package:vedgy/screens/browse_screen.dart';
import 'package:vedgy/services/secure_storage.dart';

import '../helpers/fake_secure_storage.dart';
import '../helpers/test_fixtures.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

GoRouter _makeRouter() => GoRouter(
      initialLocation: '/browse',
      routes: [
        GoRoute(
          path: '/browse',
          builder: (_, __) => const BrowseScreen(),
        ),
        GoRoute(
          path: '/listing/:id',
          builder: (_, __) => const Scaffold(body: Text('Detail')),
        ),
      ],
    );

Widget _buildApp({required Override accOverride}) {
  return ProviderScope(
    overrides: [
      secureStorageProvider.overrideWithValue(FakeSecureStorage()),
      authProvider.overrideWithValue(const AuthState.unauthenticated()),
      accOverride,
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

class _StubAccumulator extends BrowseAccumulator {
  _StubAccumulator(this._state);
  final BrowseAccumulatorState _state;

  @override
  Future<BrowseAccumulatorState> build() async => _state;
}

final _listing1 = Listing.fromJson(testListingJson);
final _listing2 = Listing.fromJson({
  ...testListingJson,
  'id': 'listing-uuid-002',
  'title': 'Another Vegan Flat',
});
final _listing3 = Listing.fromJson({
  ...testListingJson,
  'id': 'listing-uuid-003',
  'title': 'Third Listing',
});

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('Browse pagination', () {
    testWidgets('shows first page of results with result count',
        (tester) async {
      _configureView(tester);

      final override = browseAccumulatorProvider.overrideWith(
        () => _StubAccumulator(BrowseAccumulatorState(
          items: [_listing1],
          totalCount: 3,
        )),
      );

      await tester.pumpWidget(_buildApp(accOverride: override));
      await tester.pumpAndSettle();

      expect(find.text('Cozy Vegan Room'), findsOneWidget);
      expect(find.text('Showing 1 of 3 listings'), findsOneWidget);
      expect(find.text('Load more'), findsOneWidget);
    });

    testWidgets('shows both pages when accumulated results include page 2',
        (tester) async {
      _configureView(tester);

      // Simulate having loaded 2 pages of results.
      final override = browseAccumulatorProvider.overrideWith(
        () => _StubAccumulator(BrowseAccumulatorState(
          items: [_listing1, _listing2],
          totalCount: 3,
        )),
      );

      await tester.pumpWidget(_buildApp(accOverride: override));
      await tester.pumpAndSettle();

      expect(find.text('Cozy Vegan Room'), findsOneWidget);
      expect(find.text('Another Vegan Flat'), findsOneWidget);
      expect(find.text('Showing 2 of 3 listings'), findsOneWidget);
      expect(find.text('Load more'), findsOneWidget);
    });

    testWidgets('hides Load more when all results loaded', (tester) async {
      _configureView(tester);

      final override = browseAccumulatorProvider.overrideWith(
        () => _StubAccumulator(BrowseAccumulatorState(
          items: [_listing1, _listing2, _listing3],
          totalCount: 3,
        )),
      );

      await tester.pumpWidget(_buildApp(accOverride: override));
      await tester.pumpAndSettle();

      expect(find.text('Cozy Vegan Room'), findsOneWidget);
      expect(find.text('Another Vegan Flat'), findsOneWidget);
      expect(find.text('Third Listing'), findsOneWidget);
      expect(find.text('Showing 3 of 3 listings'), findsOneWidget);
      expect(find.text('Load more'), findsNothing);
    });

    testWidgets('shows inline retry on load more error', (tester) async {
      _configureView(tester);

      final overrideWithItems = browseAccumulatorProvider.overrideWith(
        () => _StubAccumulator(BrowseAccumulatorState(
          items: [_listing1],
          totalCount: 3,
          loadMoreError: true,
        )),
      );

      await tester.pumpWidget(_buildApp(accOverride: overrideWithItems));
      await tester.pumpAndSettle();

      // Existing results preserved.
      expect(find.text('Cozy Vegan Room'), findsOneWidget);
      // Inline retry shown instead of Load more.
      expect(find.text('Failed to load more listings.'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Retry'), findsOneWidget);
      expect(find.text('Load more'), findsNothing);
    });
  });
}
