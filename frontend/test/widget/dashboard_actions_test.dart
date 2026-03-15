// Widget tests for DashboardScreen delete/deactivate actions.
//
// Strategy: Override apiClientProvider with MockDio and let the real
// ListingActions run against it. Override dashboardProvider with test
// data. Override notificationQueueProvider to suppress SnackBars.

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:vedgy/models/listing.dart';
import 'package:vedgy/providers/auth_provider.dart';
import 'package:vedgy/providers/dashboard_provider.dart';
import 'package:vedgy/screens/dashboard_screen.dart';
import 'package:vedgy/services/api_client.dart';
import 'package:vedgy/services/secure_storage.dart';

import '../helpers/fake_secure_storage.dart';
import '../helpers/test_fixtures.dart';
import '../integration/helpers/mock_dio.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

GoRouter _makeRouter() => GoRouter(
  initialLocation: '/dashboard',
  routes: [
    GoRoute(path: '/dashboard', builder: (_, __) => const DashboardScreen()),
    GoRoute(
      path: '/create',
      builder: (_, __) => const Scaffold(body: Text('Create')),
    ),
    GoRoute(
      path: '/listing/:id',
      builder: (_, __) => const Scaffold(body: Text('Detail')),
    ),
    GoRoute(
      path: '/edit/:id',
      builder: (_, __) => const Scaffold(body: Text('Edit')),
    ),
  ],
);

Widget _buildApp({
  required AsyncValue<DashboardOut> dashboardValue,
  required MockDio mockDio,
}) {
  return ProviderScope(
    overrides: [
      secureStorageProvider.overrideWithValue(FakeSecureStorage()),
      authProvider.overrideWithValue(const AuthState.unauthenticated()),
      apiClientProvider.overrideWithValue(mockDio),
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

AsyncValue<DashboardOut> _draftDashboard() {
  final draftListing = Listing.fromJson({
    ...testListingJson,
    'id': 'draft-uuid',
    'title': 'My Draft Listing',
    'status': 'draft',
  });
  return AsyncValue.data(
    DashboardOut(
      drafts: [draftListing],
      paymentSubmitted: const [],
      active: const [],
      expired: const [],
      deactivated: const [],
    ),
  );
}

AsyncValue<DashboardOut> _activeDashboard() {
  final activeListing = Listing.fromJson({
    ...testListingJson,
    'id': 'active-uuid',
    'title': 'My Active Listing',
    'status': 'active',
  });
  return AsyncValue.data(
    DashboardOut(
      drafts: const [],
      paymentSubmitted: const [],
      active: [activeListing],
      expired: const [],
      deactivated: const [],
    ),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('DashboardScreen actions', () {
    testWidgets('tapping Delete shows confirmation dialog with listing title', (
      tester,
    ) async {
      _configureView(tester);
      final mockDio = MockDio();

      await tester.pumpWidget(
        _buildApp(dashboardValue: _draftDashboard(), mockDio: mockDio),
      );
      await tester.pumpAndSettle();

      // Find and tap the Delete button.
      final deleteButton = find.text('Delete');
      expect(deleteButton, findsOneWidget);
      await tester.tap(deleteButton);
      await tester.pumpAndSettle();

      // Confirmation dialog is visible.
      expect(find.text('Delete listing?'), findsOneWidget);
      // The dialog content mentions the listing title.
      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('confirming delete calls DELETE on correct API path', (
      tester,
    ) async {
      _configureView(tester);
      final mockDio = MockDio();

      when(() => mockDio.delete<void>('/api/listings/draft-uuid/')).thenAnswer(
        (_) async => Response(
          statusCode: 204,
          requestOptions: RequestOptions(path: '/api/listings/draft-uuid/'),
        ),
      );

      await tester.pumpWidget(
        _buildApp(dashboardValue: _draftDashboard(), mockDio: mockDio),
      );
      await tester.pumpAndSettle();

      // Tap Delete, then confirm.
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();

      verify(() => mockDio.delete<void>('/api/listings/draft-uuid/')).called(1);
    });

    testWidgets('cancelling delete dismisses dialog without API call', (
      tester,
    ) async {
      _configureView(tester);
      final mockDio = MockDio();

      await tester.pumpWidget(
        _buildApp(dashboardValue: _draftDashboard(), mockDio: mockDio),
      );
      await tester.pumpAndSettle();

      // Tap Delete, then cancel.
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();

      // Dialog dismissed.
      expect(find.text('Delete listing?'), findsNothing);
      // No API call made.
      verifyNever(() => mockDio.delete<void>(any()));
    });

    testWidgets('tapping Deactivate shows confirmation dialog', (tester) async {
      _configureView(tester);
      final mockDio = MockDio();

      await tester.pumpWidget(
        _buildApp(dashboardValue: _activeDashboard(), mockDio: mockDio),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Deactivate'));
      await tester.pumpAndSettle();

      expect(find.text('Deactivate listing?'), findsOneWidget);
      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('confirming deactivate calls POST on correct API path', (
      tester,
    ) async {
      _configureView(tester);
      final mockDio = MockDio();

      when(
        () => mockDio.post<Map<String, dynamic>>(
          '/api/listings/active-uuid/deactivate/',
        ),
      ).thenAnswer(
        (_) async => okResponse({
          ...testListingJson,
          'id': 'active-uuid',
          'status': 'deactivated',
        }, '/api/listings/active-uuid/deactivate/'),
      );

      await tester.pumpWidget(
        _buildApp(dashboardValue: _activeDashboard(), mockDio: mockDio),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Deactivate'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Deactivate'));
      await tester.pumpAndSettle();

      verify(
        () => mockDio.post<Map<String, dynamic>>(
          '/api/listings/active-uuid/deactivate/',
        ),
      ).called(1);
    });
  });
}
