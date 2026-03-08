// Integration tests for browse-to-detail navigation.
//
// These tests exercise the browse and detail screens using:
//   - Real GoRouter (via AppHarness)
//   - Real Riverpod providers
//   - FakeSecureStorage (no platform channels)
//   - MockDio to stub API responses for listings endpoints
//
// Test cases:
//   1. Browse → tap listing → detail screen: From BrowseScreen, tap a listing
//      tile → navigates to /listing/{id} → ListingDetailScreen is shown with
//      the listing data

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vedgy/providers/auth_provider.dart';
import 'package:vedgy/router/app_router.dart';
import 'package:vedgy/screens/browse_screen.dart';
import 'package:vedgy/screens/listing_detail_screen.dart';
import 'package:vedgy/services/api_client.dart';

import 'helpers/app_harness.dart';
import 'helpers/fake_secure_storage.dart';
import 'helpers/fixtures.dart';
import 'helpers/mock_dio.dart';

// ---------------------------------------------------------------------------
// Fake Auth notifier that sets unauthenticated state
// ---------------------------------------------------------------------------

/// Auth notifier that immediately sets unauthenticated state.
/// Allows browsing without authentication.
class _UnauthenticatedAuth extends Auth {
  @override
  AuthState build() => const AuthState.unauthenticated();

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
// Shared stub helpers
// ---------------------------------------------------------------------------

void _stubBrowseSuccess(MockDio mockDio) {
  when(
    () => mockDio.get<Map<String, dynamic>>(
      '/api/listings/',
      data: any(named: 'data'),
      queryParameters: any(named: 'queryParameters'),
      options: any(named: 'options'),
      cancelToken: any(named: 'cancelToken'),
      onReceiveProgress: any(named: 'onReceiveProgress'),
    ),
  ).thenAnswer(
    (_) async => okResponse(paginatedListingsJson, '/api/listings/'),
  );
}

void _stubDetailSuccess(MockDio mockDio, String id) {
  when(
    () => mockDio.get<Map<String, dynamic>>(
      '/api/listings/$id/',
      data: any(named: 'data'),
      queryParameters: any(named: 'queryParameters'),
      options: any(named: 'options'),
      cancelToken: any(named: 'cancelToken'),
      onReceiveProgress: any(named: 'onReceiveProgress'),
    ),
  ).thenAnswer(
    (_) async => okResponse(testListingJson, '/api/listings/$id/'),
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

  group('Browse to detail navigation', () {
    // -----------------------------------------------------------------------
    // 1. Browse → tap listing → detail screen
    //    User navigates to /browse → sees paginated listings →
    //    taps the "Cozy Vegan Room" listing card →
    //    navigates to /listing/{id} →
    //    ListingDetailScreen is shown with listing data.
    // -----------------------------------------------------------------------
    testWidgets(
        'tapping a listing from browse navigates to detail screen',
        (tester) async {
      _configureView(tester);

      final apiMockDio = MockDio();

      // Stub the browse listings endpoint to return a paginated response.
      _stubBrowseSuccess(apiMockDio);

      // Stub the detail endpoint for the listing we'll tap.
      _stubDetailSuccess(apiMockDio, 'listing-uuid-001');

      final harness = AppHarness(
        fakeStorage: FakeSecureStorage(),
        extraOverrides: [
          authProvider.overrideWith(() => _UnauthenticatedAuth()),
          apiClientProvider.overrideWithValue(apiMockDio),
        ],
      );

      await harness.pump(tester);
      await harness.init(tester);

      // Navigate to /browse.
      harness.read(appRouterProvider).go('/browse');
      await tester.pumpAndSettle();

      // Verify BrowseScreen is visible.
      expect(find.byType(BrowseScreen), findsOneWidget);

      // Find the listing tile with "Cozy Vegan Room" title.
      final listingTileFinder = find.text('Cozy Vegan Room');
      expect(listingTileFinder, findsOneWidget,
          reason: 'Listing tile "Cozy Vegan Room" should be visible');

      // Tap the listing.
      await tester.tap(listingTileFinder);
      await tester.pumpAndSettle();

      // Verify ListingDetailScreen is now visible.
      expect(find.byType(ListingDetailScreen), findsOneWidget,
          reason: 'ListingDetailScreen should be shown after tapping');

      // Verify we're on the correct route.
      final route = harness.read(appRouterProvider).routeInformationProvider
          .value
          .location;
      expect(route, contains('/listing/listing-uuid-001'),
          reason: 'Route should contain the listing ID');

      // Verify the detail screen is showing the listing data by checking
      // for key text from the listing.
      expect(find.text('Cozy Vegan Room'), findsOneWidget,
          reason: 'Listing title should be visible in detail screen');
    });
  });
}
