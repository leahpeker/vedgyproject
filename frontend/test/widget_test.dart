import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:vedgy/models/listing.dart';
import 'package:vedgy/providers/auth_provider.dart';
import 'package:vedgy/screens/home_screen.dart';
import 'package:vedgy/widgets/listing_card.dart';

// ---------------------------------------------------------------------------
// Fake auth notifier — returns unauthenticated without touching secure storage
// ---------------------------------------------------------------------------

class _FakeAuth extends Auth {
  @override
  AuthState build() => const AuthState.unauthenticated();
}

// ---------------------------------------------------------------------------
// Test helper — wraps a widget in a ProviderScope + MaterialApp.router with
// enough routes so that go_router navigations inside widgets don't throw.
// ---------------------------------------------------------------------------

Widget _wrap(Widget screen) {
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (ctx, st) => screen),
      GoRoute(
        path: '/browse',
        builder: (ctx, st) => const Scaffold(body: Text('browse')),
      ),
      GoRoute(
        path: '/create',
        builder: (ctx, st) => const Scaffold(body: Text('create')),
      ),
      GoRoute(
        path: '/login',
        builder: (ctx, st) => const Scaffold(body: Text('login')),
      ),
      GoRoute(
        path: '/listing/:id',
        builder: (ctx, st) => const Scaffold(body: Text('detail')),
      ),
    ],
  );

  return ProviderScope(
    overrides: [authProvider.overrideWith(_FakeAuth.new)],
    child: MaterialApp.router(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2D6A4F)),
        useMaterial3: true,
      ),
      routerConfig: router,
    ),
  );
}

// ---------------------------------------------------------------------------
// Test data
// ---------------------------------------------------------------------------

final _testListing = Listing(
  id: 'test-id-123',
  title: 'Cozy vegan flat in Brooklyn',
  description: 'A beautiful plant-based home with lots of natural light.',
  city: 'New York',
  neighborhood: 'Williamsburg',
  price: 1800,
  rentalType: 'Long-term',
  roomType: 'Entire place',
  veganHousehold: 'Fully vegan',
  furnished: 'Furnished',
  listerRelationship: 'Owner',
  seekingRoommate: false,
  includePhone: false,
  status: 'active',
  user: const ListingUser(id: 'u1', firstName: 'Alice', lastName: 'Green'),
  photos: const [],
  createdAt: DateTime(2025, 1, 1),
);

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('HomeScreen', () {
    testWidgets('renders headline and CTAs', (tester) async {
      await tester.pumpWidget(_wrap(const HomeScreen()));
      await tester.pump();

      expect(find.text('Find vegan-friendly housing.'), findsOneWidget);
      expect(find.text('Browse listings'), findsOneWidget);
      expect(find.text('Post a listing'), findsOneWidget);
    });

    testWidgets('Browse listings button navigates to /browse', (tester) async {
      await tester.pumpWidget(_wrap(const HomeScreen()));
      await tester.pump();

      await tester.tap(find.text('Browse listings'));
      await tester.pumpAndSettle();

      expect(find.text('browse'), findsOneWidget);
    });
  });

  group('ListingCard', () {
    testWidgets('renders title, price, location, and lister name', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(ListingCard(listing: _testListing)));
      await tester.pump();

      expect(find.text('Cozy vegan flat in Brooklyn'), findsOneWidget);
      expect(find.text('\$1800/mo'), findsOneWidget);
      expect(find.text('New York, Williamsburg'), findsOneWidget);
      expect(find.text('Posted by Alice Green'), findsOneWidget);
    });

    testWidgets('shows placeholder icon when no photos', (tester) async {
      await tester.pumpWidget(_wrap(ListingCard(listing: _testListing)));
      await tester.pump();

      expect(find.byIcon(Icons.home_outlined), findsOneWidget);
    });

    testWidgets('tapping card navigates to listing detail', (tester) async {
      await tester.pumpWidget(_wrap(ListingCard(listing: _testListing)));
      await tester.pump();

      await tester.tap(find.byType(Card));
      await tester.pumpAndSettle();

      expect(find.text('detail'), findsOneWidget);
    });
  });
}
