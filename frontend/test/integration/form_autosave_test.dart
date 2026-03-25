// Integration tests for ListingForm auto-save debounce behavior.
//
// Uses tester.pump(Duration(seconds: 2)) to advance the debounce timer
// (NOT fakeAsync — it cannot be nested inside testWidgets).
//
// MockDio intercepts POST/PATCH calls to verify auto-save triggers.

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:vedgy/providers/auth_provider.dart';
import 'package:vedgy/services/api_client.dart';
import 'package:vedgy/services/secure_storage.dart';
import 'package:vedgy/widgets/listing_form.dart';

import '../helpers/fake_secure_storage.dart';
import '../helpers/test_fixtures.dart';
import 'helpers/mock_dio.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

GoRouter _makeRouter() => GoRouter(
  initialLocation: '/create',
  routes: [
    GoRoute(
      path: '/create',
      builder: (_, __) => const Scaffold(body: ListingForm()),
    ),
    GoRoute(
      path: '/dashboard',
      builder: (_, __) => const Scaffold(body: Text('Dashboard')),
    ),
    GoRoute(
      path: '/preview/:id',
      builder: (_, __) => const Scaffold(body: Text('Preview')),
    ),
  ],
);

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

void _stubCreateListing(MockDio mockDio) {
  when(
    () => mockDio.post<Map<String, dynamic>>(
      '/api/listings/',
      data: any(named: 'data'),
    ),
  ).thenAnswer((_) async => okResponse(testListingJson, '/api/listings/'));
}

void _stubUpdateListing(MockDio mockDio) {
  when(
    () => mockDio.patch<Map<String, dynamic>>(
      '/api/listings/listing-uuid-001/',
      data: any(named: 'data'),
    ),
  ).thenAnswer(
    (_) async => okResponse(testListingJson, '/api/listings/listing-uuid-001/'),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
  });

  group('Form auto-save', () {
    testWidgets('entering text and pumping 2s triggers POST (creates draft)', (
      tester,
    ) async {
      _configureView(tester);
      final mockDio = MockDio();
      _stubCreateListing(mockDio);

      await tester.pumpWidget(_buildApp(mockDio));
      await tester.pumpAndSettle();

      // Enter text in the title field.
      final titleField = find.widgetWithText(
        TextField,
        'Cozy room in vegan-friendly house',
      );
      await tester.enterText(titleField, 'My vegan room');

      // Advance past the 2-second debounce.
      await tester.pump(const Duration(seconds: 3));

      // POST should have been called to create a draft.
      verify(
        () => mockDio.post<Map<String, dynamic>>(
          '/api/listings/',
          data: any(named: 'data'),
        ),
      ).called(1);
    });

    testWidgets('rapid edits within 2s only trigger one API call', (
      tester,
    ) async {
      _configureView(tester);
      final mockDio = MockDio();
      _stubCreateListing(mockDio);

      await tester.pumpWidget(_buildApp(mockDio));
      await tester.pumpAndSettle();

      final titleField = find.widgetWithText(
        TextField,
        'Cozy room in vegan-friendly house',
      );

      // Type once, wait 1 second (not enough to trigger).
      await tester.enterText(titleField, 'First');
      await tester.pump(const Duration(seconds: 1));

      // Type again — resets the debounce.
      await tester.enterText(titleField, 'Second');
      await tester.pump(const Duration(seconds: 3));

      // Only one POST should have been made (not two).
      verify(
        () => mockDio.post<Map<String, dynamic>>(
          '/api/listings/',
          data: any(named: 'data'),
        ),
      ).called(1);
    });

    testWidgets('subsequent edit after draft created triggers PATCH', (
      tester,
    ) async {
      _configureView(tester);
      final mockDio = MockDio();
      _stubCreateListing(mockDio);
      _stubUpdateListing(mockDio);

      await tester.pumpWidget(_buildApp(mockDio));
      await tester.pumpAndSettle();

      // First edit — creates draft.
      final titleField = find.widgetWithText(
        TextField,
        'Cozy room in vegan-friendly house',
      );
      await tester.enterText(titleField, 'My vegan room');
      await tester.pump(const Duration(seconds: 3));

      // POST was called.
      verify(
        () => mockDio.post<Map<String, dynamic>>(
          '/api/listings/',
          data: any(named: 'data'),
        ),
      ).called(1);

      // Second edit — should PATCH the existing listing.
      await tester.enterText(titleField, 'Updated title');
      await tester.pump(const Duration(seconds: 3));

      verify(
        () => mockDio.patch<Map<String, dynamic>>(
          '/api/listings/listing-uuid-001/',
          data: any(named: 'data'),
        ),
      ).called(1);
    });

    testWidgets('no API call before debounce fires', (tester) async {
      _configureView(tester);
      final mockDio = MockDio();
      _stubCreateListing(mockDio);

      await tester.pumpWidget(_buildApp(mockDio));
      await tester.pumpAndSettle();

      // Enter text but only pump 1 second — debounce is 2 seconds.
      final titleField = find.widgetWithText(
        TextField,
        'Cozy room in vegan-friendly house',
      );
      await tester.enterText(titleField, 'Pending text');
      await tester.pump(const Duration(seconds: 1));

      // No POST yet — debounce hasn't fired.
      verifyNever(
        () => mockDio.post<Map<String, dynamic>>(
          '/api/listings/',
          data: any(named: 'data'),
        ),
      );

      // Now pump past the debounce.
      await tester.pump(const Duration(seconds: 2));

      // POST fires after the full debounce.
      verify(
        () => mockDio.post<Map<String, dynamic>>(
          '/api/listings/',
          data: any(named: 'data'),
        ),
      ).called(1);
    });
  });
}
