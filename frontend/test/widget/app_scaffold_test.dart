// Widget tests for AppScaffold's notification (snackbar) behaviour.
//
// AppScaffold uses ref.listen(notificationQueueProvider, ...) to display
// snackbars via ScaffoldMessenger.  These tests drive the provider state
// directly and verify that the correct SnackBar widget appears (or does not
// appear) in the widget tree.
//
// We override:
//   - secureStorageProvider → FakeSecureStorage (no platform channel)
//   - authProvider          → AuthState.unauthenticated() (no network calls)
//   - notificationQueueProvider → static value under test

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:vedgy/providers/auth_provider.dart';
import 'package:vedgy/providers/notification_provider.dart';
import 'package:vedgy/services/secure_storage.dart';
import 'package:vedgy/widgets/app_scaffold.dart';

import '../helpers/fake_secure_storage.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Minimal GoRouter used in tests — single route renders AppScaffold.
GoRouter _makeRouter(Widget body) => GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (_, __) => AppScaffold(child: body),
    ),
  ],
);

/// Wraps [child] inside a full [ProviderScope] + [MaterialApp.router].
///
/// [overrides] lets individual tests inject provider state.  The auth and
/// secure-storage providers are always stubbed out so no platform channels or
/// network calls are made.
Widget wrap(List<Override> overrides, Widget child) {
  final baseOverrides = <Override>[
    secureStorageProvider.overrideWithValue(FakeSecureStorage()),
    authProvider.overrideWithValue(const AuthState.unauthenticated()),
    ...overrides,
  ];

  return ProviderScope(
    overrides: baseOverrides,
    child: MaterialApp.router(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      routerConfig: _makeRouter(child),
    ),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('AppScaffold — notification behaviour', () {
    // -----------------------------------------------------------------------
    // 1. No snackbar when provider state is null
    // -----------------------------------------------------------------------
    testWidgets('no snackbar is shown when notificationQueueProvider is null', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap([
          notificationQueueProvider.overrideWithValue(null),
        ], const Text('body')),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsNothing);
    });

    // -----------------------------------------------------------------------
    // 2. Snackbar appears when provider emits a notification
    // -----------------------------------------------------------------------
    testWidgets('snackbar is shown with the notification message', (
      tester,
    ) async {
      // Start with null so the listener fires on the *transition* from
      // null → notification.  We achieve this by pumping the widget, then
      // mutating the provider state through the notifier.
      await tester.pumpWidget(wrap([], const Text('body')));
      await tester.pumpAndSettle();

      // No snackbar yet.
      expect(find.byType(SnackBar), findsNothing);

      // Push a notification through the real notifier.
      final container = ProviderScope.containerOf(
        tester.element(find.byType(AppScaffold)),
      );
      container
          .read(notificationQueueProvider.notifier)
          .show('Item saved successfully');

      await tester.pump(); // let the listener fire
      await tester.pump(
        const Duration(milliseconds: 300),
      ); // snackbar animation

      expect(find.text('Item saved successfully'), findsOneWidget);
      expect(find.byType(SnackBar), findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // 3. Error notification uses error colour
    // -----------------------------------------------------------------------
    testWidgets('error notification snackbar uses error background colour', (
      tester,
    ) async {
      await tester.pumpWidget(wrap([], const Text('body')));
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(AppScaffold)),
      );
      container
          .read(notificationQueueProvider.notifier)
          .show('Something went wrong', isError: true);

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(SnackBar), findsOneWidget);

      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      // The error colour comes from Theme.of(context).colorScheme.error.
      final colorScheme = Theme.of(
        tester.element(find.byType(AppScaffold)),
      ).colorScheme;
      expect(snackBar.backgroundColor, colorScheme.error);
    });

    // -----------------------------------------------------------------------
    // 4. Normal (non-error) notification uses green/success colour
    // -----------------------------------------------------------------------
    testWidgets('normal notification snackbar uses green background colour', (
      tester,
    ) async {
      await tester.pumpWidget(wrap([], const Text('body')));
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(AppScaffold)),
      );
      container
          .read(notificationQueueProvider.notifier)
          .show('Profile updated', isError: false);

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(SnackBar), findsOneWidget);

      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.backgroundColor, Colors.green.shade700);
    });

    // -----------------------------------------------------------------------
    // 5. AppScaffold renders its body child
    // -----------------------------------------------------------------------
    testWidgets('AppScaffold renders the provided body widget', (tester) async {
      const bodyKey = Key('test_body');
      await tester.pumpWidget(
        wrap([
          notificationQueueProvider.overrideWithValue(null),
        ], const Text('Hello Vedgy', key: bodyKey)),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(bodyKey), findsOneWidget);
      expect(find.text('Hello Vedgy'), findsOneWidget);
    });
  });
}
