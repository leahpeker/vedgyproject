// Widget tests for ListingForm.
//
// ListingForm is a ConsumerStatefulWidget used in both create and edit mode.
// It uses listingActionsProvider, photoActionsProvider, and
// notificationQueueProvider for network calls.
//
// Strategy:
//   - apiClientProvider is overridden with a bare Dio instance.  This
//     prevents real network calls while still allowing the provider graph to
//     construct without errors.
//   - The auto-save debounce fires after 2 seconds; pumpAndSettle never
//     advances fake time past that, so no Dio call is made during rendering.
//   - Validation tests submit the form, which runs client-side _validate()
//     and shows an AlertDialog with errors — never touching the network.
//
// Overrides used in every test:
//   - secureStorageProvider   → FakeSecureStorage (no platform channels)
//   - authProvider            → AuthState.unauthenticated()
//   - apiClientProvider       → bare Dio() (no real calls)
//   - notificationQueueProvider → null (no SnackBars needed)
//
// Patterns follow Tasks 33-38:
//   - tester.view.physicalSize = const Size(1440, 900)
//   - ProviderScope wrapping MaterialApp.router with a GoRouter stub
//   - _configureView / _makeRouter / _buildApp helpers
//
// IMPORTANT: The ListingForm dropdown fields use DropdownButtonFormField with
// strict value matching. The edit-mode fixture (testEditListingJson) uses only
// values that exist in the dropdown item lists defined in listing_form.dart.

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:vedgy/models/listing.dart';
import 'package:vedgy/providers/auth_provider.dart';
import 'package:vedgy/providers/notification_provider.dart';
import 'package:vedgy/services/api_client.dart';
import 'package:vedgy/services/secure_storage.dart';
import 'package:vedgy/widgets/listing_form.dart';

import '../helpers/fake_secure_storage.dart';

// ---------------------------------------------------------------------------
// Edit-mode fixture — values must match the dropdown item lists in
// listing_form.dart (_furnishedOptions, _rentalTypes, _roomTypes, etc.)
// ---------------------------------------------------------------------------

/// A listing JSON where every string field matches a dropdown option so
/// DropdownButtonFormField does not throw an assertion error.
const _testEditListingJson = <String, dynamic>{
  'id': 'listing-uuid-edit',
  'title': 'Cozy Vegan Room',
  'description': 'Nice place.',
  'city': 'New York',
  'borough': 'Brooklyn',
  'neighborhood': null,
  'price': 1200,
  'start_date': null,
  'end_date': null,
  'rental_type': 'sublet',               // matches _rentalTypes
  'room_type': 'private_room',           // matches _roomTypes
  'vegan_household': 'fully_vegan',      // matches _veganHouseholds
  'furnished': 'fully_furnished',        // matches _furnishedOptions
  'lister_relationship': 'owner',        // matches _relationships
  'seeking_roommate': false,
  'about_lister': 'I love cooking.',
  'rental_requirements': 'Non-smoker preferred.',
  'pet_policy': 'No pets.',
  'include_phone': false,
  'phone_number': null,
  'status': 'draft',
  'user': {
    'id': 'user-uuid-001',
    'first_name': 'Test',
    'last_name': 'User',
  },
  'photos': <dynamic>[],
  'created_at': '2026-01-01T00:00:00Z',
  'expires_at': null,
};

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Minimal GoRouter placing ListingForm at /create with stubs for routes
/// the form may navigate to (/dashboard, /preview/:id).
GoRouter _makeRouter() => GoRouter(
      initialLocation: '/create',
      routes: [
        GoRoute(
          path: '/create',
          builder: (_, __) => const Scaffold(body: ListingForm()),
        ),
        GoRoute(
          path: '/dashboard',
          builder: (_, __) =>
              const Scaffold(body: Text('Dashboard page')),
        ),
        GoRoute(
          path: '/preview/:id',
          builder: (_, __) =>
              const Scaffold(body: Text('Preview page')),
        ),
      ],
    );

/// Router pre-populated with an existing listing (edit mode).
GoRouter _makeEditRouter(Listing listing) => GoRouter(
      initialLocation: '/edit/${listing.id}',
      routes: [
        GoRoute(
          path: '/edit/:id',
          builder: (_, __) => Scaffold(body: ListingForm(initial: listing)),
        ),
        GoRoute(
          path: '/dashboard',
          builder: (_, __) =>
              const Scaffold(body: Text('Dashboard page')),
        ),
        GoRoute(
          path: '/preview/:id',
          builder: (_, __) =>
              const Scaffold(body: Text('Preview page')),
        ),
      ],
    );

/// Wraps the router inside a ProviderScope with all required overrides.
Widget _buildApp({GoRouter? router}) {
  return ProviderScope(
    overrides: [
      secureStorageProvider.overrideWithValue(FakeSecureStorage()),
      authProvider.overrideWithValue(const AuthState.unauthenticated()),
      // A bare Dio prevents real network calls without interfering with the
      // provider graph.  No requests are made during UI-only tests because
      // the 2-second auto-save debounce never fires in pumpAndSettle.
      apiClientProvider.overrideWithValue(Dio()),
      notificationQueueProvider.overrideWithValue(null),
    ],
    child: MaterialApp.router(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      routerConfig: router ?? _makeRouter(),
    ),
  );
}

/// Sets up a wide desktop viewport and suppresses RenderFlex overflow errors
/// (test fonts differ from real fonts in metrics).
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

/// Scrolls until [target] is visible within the first [SingleChildScrollView].
Future<void> _scrollToVisible(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('ListingForm', () {
    // -----------------------------------------------------------------------
    // 1. Renders in create mode — "Post a listing" heading
    // -----------------------------------------------------------------------
    testWidgets('renders Post a listing heading in create mode',
        (tester) async {
      _configureView(tester);

      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Post a listing'), findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // 2. Title label is present
    // -----------------------------------------------------------------------
    testWidgets('renders Title field label', (tester) async {
      _configureView(tester);

      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Title *'), findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // 3. City dropdown label is present
    // -----------------------------------------------------------------------
    testWidgets('renders City dropdown label', (tester) async {
      _configureView(tester);

      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      expect(find.text('City *'), findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // 4. Price field label is present
    // -----------------------------------------------------------------------
    testWidgets('renders Monthly Rent price field label', (tester) async {
      _configureView(tester);

      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Monthly Rent (\$) *'), findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // 5. Preview listing button is present
    // -----------------------------------------------------------------------
    testWidgets('renders Preview listing FilledButton', (tester) async {
      _configureView(tester);

      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      // The button is at the bottom of a long scrollable form.
      final previewButton = find.widgetWithText(FilledButton, 'Preview listing');
      await _scrollToVisible(tester, previewButton);

      expect(previewButton, findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // 6. Save & exit button is present
    // -----------------------------------------------------------------------
    testWidgets('renders Save and exit OutlinedButton', (tester) async {
      _configureView(tester);

      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      final saveButton = find.widgetWithText(OutlinedButton, 'Save & exit');
      await _scrollToVisible(tester, saveButton);

      expect(saveButton, findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // 7. Validation on submit — shows AlertDialog when required fields are empty
    // -----------------------------------------------------------------------
    testWidgets(
        'shows Please fix these issues dialog when required fields are empty',
        (tester) async {
      _configureView(tester);

      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      // Scroll to the "Preview listing" button before tapping.
      final previewButton =
          find.widgetWithText(FilledButton, 'Preview listing');
      await _scrollToVisible(tester, previewButton);

      await tester.tap(previewButton);
      await tester.pumpAndSettle();

      expect(find.text('Please fix these issues'), findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // 8. Empty title shows "Title is required." validation error
    // -----------------------------------------------------------------------
    testWidgets('shows Title is required error when title is empty',
        (tester) async {
      _configureView(tester);

      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      // Scroll to and tap the Preview listing button with an empty title.
      final previewButton =
          find.widgetWithText(FilledButton, 'Preview listing');
      await _scrollToVisible(tester, previewButton);

      await tester.tap(previewButton);
      await tester.pumpAndSettle();

      expect(find.text('Title is required.'), findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // 9. Missing city shows "City is required." validation error
    // -----------------------------------------------------------------------
    testWidgets('shows City is required error when city is not selected',
        (tester) async {
      _configureView(tester);

      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      // Fill in the title field (visible at the top of the form).
      final titleField = find.widgetWithText(
          TextField, 'Cozy room in vegan-friendly house');
      await tester.enterText(titleField, 'My nice vegan room');
      await tester.pumpAndSettle();

      // Scroll to the Preview button and tap — city is still null.
      final previewButton =
          find.widgetWithText(FilledButton, 'Preview listing');
      await _scrollToVisible(tester, previewButton);

      await tester.tap(previewButton);
      await tester.pumpAndSettle();

      expect(find.text('City is required.'), findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // 10. Validation dialog can be dismissed via OK button
    // -----------------------------------------------------------------------
    testWidgets('dismisses validation dialog when OK is tapped',
        (tester) async {
      _configureView(tester);

      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      // Scroll to the button and tap.
      final previewButton =
          find.widgetWithText(FilledButton, 'Preview listing');
      await _scrollToVisible(tester, previewButton);

      await tester.tap(previewButton);
      await tester.pumpAndSettle();

      // Dialog is shown.
      expect(find.text('Please fix these issues'), findsOneWidget);

      // Tap OK to dismiss.
      await tester.tap(find.widgetWithText(TextButton, 'OK'));
      await tester.pumpAndSettle();

      // Dialog is gone.
      expect(find.text('Please fix these issues'), findsNothing);
    });

    // -----------------------------------------------------------------------
    // 11. Renders in edit mode — "Edit listing" heading
    // -----------------------------------------------------------------------
    testWidgets('renders Edit listing heading when initial listing is supplied',
        (tester) async {
      _configureView(tester);

      // Use the edit fixture with valid dropdown values.
      final listing = Listing.fromJson(_testEditListingJson);
      await tester.pumpWidget(_buildApp(router: _makeEditRouter(listing)));
      await tester.pumpAndSettle();

      expect(find.text('Edit listing'), findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // 12. Edit mode — pre-populates the title field
    // -----------------------------------------------------------------------
    testWidgets('pre-populates title field from initial listing in edit mode',
        (tester) async {
      _configureView(tester);

      final listing = Listing.fromJson(_testEditListingJson);
      await tester.pumpWidget(_buildApp(router: _makeEditRouter(listing)));
      await tester.pumpAndSettle();

      // _testEditListingJson has title: 'Cozy Vegan Room'
      expect(find.text('Cozy Vegan Room'), findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // 13. Invalid price shows price error message
    // -----------------------------------------------------------------------
    testWidgets('shows price error when price is not a positive integer',
        (tester) async {
      _configureView(tester);

      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      // Find the price TextField by its hint text and enter an invalid value.
      final priceField = find.widgetWithText(TextField, '1200');
      await _scrollToVisible(tester, priceField);
      await tester.enterText(priceField, 'abc');
      await tester.pumpAndSettle();

      // Scroll to Preview button and tap.
      final previewButton =
          find.widgetWithText(FilledButton, 'Preview listing');
      await _scrollToVisible(tester, previewButton);

      await tester.tap(previewButton);
      await tester.pumpAndSettle();

      expect(
          find.text('Price must be a positive whole number.'), findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // 14. Section headers are present
    // -----------------------------------------------------------------------
    testWidgets('renders Basic Information and Location section headers',
        (tester) async {
      _configureView(tester);

      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Basic Information'), findsOneWidget);
      expect(find.text('Location'), findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // 15. Photos section is present with 0/10 counter
    // -----------------------------------------------------------------------
    testWidgets('renders Photos section with 0/10 photos counter',
        (tester) async {
      _configureView(tester);

      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      // Scroll down to the Photos section.
      final photosCounter = find.text('0/10 photos');
      await _scrollToVisible(tester, photosCounter);

      expect(find.text('0/10 photos'), findsOneWidget);
    });
  });
}
