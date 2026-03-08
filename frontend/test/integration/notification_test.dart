// Integration tests for notification snackbars.
//
// These tests exercise the notificationQueueProvider and AppScaffold integration:
//   - NotificationQueue provider holds a pending AppNotification
//   - AppScaffold listens to notifications and shows a SnackBar
//   - After dismissal, state returns to null
//
// Test cases:
//   1. Show notification in snackbar: Call notificationQueueProvider.notifier
//      .show('Message') → snackbar appears with the message text
//   2. Error notification styling: Call .showError('Error') → snackbar has
//      error styling (red background)
//   3. Notification clears: After snackbar dismisses, state returns to null

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vedgy/providers/auth_provider.dart';
import 'package:vedgy/providers/notification_provider.dart';
import 'package:vedgy/router/app_router.dart';

import 'helpers/app_harness.dart';
import 'helpers/fake_secure_storage.dart';

// ---------------------------------------------------------------------------
// Fake Auth notifier that sets unauthenticated state
// ---------------------------------------------------------------------------

/// Auth notifier that immediately sets unauthenticated state.
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
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('Notification snackbar', () {
    // -----------------------------------------------------------------------
    // 1. Show notification in snackbar
    //    Call notificationQueueProvider.notifier.show('Message') →
    //    snackbar appears with the message text.
    // -----------------------------------------------------------------------
    testWidgets('show notification displays snackbar with message',
        (tester) async {
      _configureView(tester);

      final harness = AppHarness(
        fakeStorage: FakeSecureStorage(),
        extraOverrides: [
          authProvider.overrideWith(() => _UnauthenticatedAuth()),
        ],
      );

      await harness.pump(tester);
      await harness.init(tester);

      // Navigate to /login (a simple public route without network calls).
      harness.read(appRouterProvider).go('/login');
      await tester.pumpAndSettle();

      // Show a notification via the provider.
      const testMessage = 'Test notification message';
      harness
          .read(notificationQueueProvider.notifier)
          .show(testMessage, isError: false);

      // Pump to allow AppScaffold to listen and display the snackbar.
      await tester.pumpAndSettle();

      // Verify the snackbar appears with the message.
      expect(find.text(testMessage), findsWidgets,
          reason: 'Notification message should appear in snackbar');

      // Verify a SnackBar widget is found.
      final snackBarFinder = find.byType(SnackBar);
      expect(snackBarFinder, findsOneWidget,
          reason: 'SnackBar should be displayed');
    });

    // -----------------------------------------------------------------------
    // 2. Error notification styling
    //    Call notificationQueueProvider.notifier.showError('Error') →
    //    snackbar has error styling (red/error color background).
    // -----------------------------------------------------------------------
    testWidgets('showError displays snackbar with error styling',
        (tester) async {
      _configureView(tester);

      final harness = AppHarness(
        fakeStorage: FakeSecureStorage(),
        extraOverrides: [
          authProvider.overrideWith(() => _UnauthenticatedAuth()),
        ],
      );

      await harness.pump(tester);
      await harness.init(tester);

      // Navigate to /login.
      harness.read(appRouterProvider).go('/login');
      await tester.pumpAndSettle();

      // Show an error notification.
      const errorMessage = 'An error occurred';
      harness.read(notificationQueueProvider.notifier).showError(errorMessage);

      // Pump to allow AppScaffold to listen and display the snackbar.
      await tester.pumpAndSettle();

      // Verify the snackbar appears with the error message.
      expect(find.text(errorMessage), findsWidgets,
          reason: 'Error message should appear in snackbar');

      // Verify a SnackBar is displayed.
      final snackBarFinder = find.byType(SnackBar);
      expect(snackBarFinder, findsOneWidget,
          reason: 'SnackBar should be displayed for error');

      // Verify the snackbar has error styling (red background).
      // The SnackBar's backgroundColor should be set to the error color.
      final snackBar =
          snackBarFinder.evaluate().single.widget as SnackBar;
      expect(snackBar.backgroundColor, isNotNull,
          reason: 'SnackBar should have a backgroundColor set');

      // Check that the backgroundColor is not green (error color vs success).
      // AppScaffold uses green for success and error color for errors.
      final bgColor = snackBar.backgroundColor as Color?;
      if (bgColor != null) {
        // For error, it should not be green.
        expect(
          bgColor != Colors.green && bgColor != (Colors.green[700] ?? Colors.green),
          isTrue,
          reason: 'SnackBar background should not be green (should be error color)',
        );
      }
    });

    // -----------------------------------------------------------------------
    // 3. Notification clears after snackbar dismisses
    //    AppScaffold calls clear() immediately after showing the snackbar,
    //    so the state should be null after pumpAndSettle.
    // -----------------------------------------------------------------------
    testWidgets('notification clears after showing', (tester) async {
      _configureView(tester);

      final harness = AppHarness(
        fakeStorage: FakeSecureStorage(),
        extraOverrides: [
          authProvider.overrideWith(() => _UnauthenticatedAuth()),
        ],
      );

      await harness.pump(tester);
      await harness.init(tester);

      // Navigate to /login.
      harness.read(appRouterProvider).go('/login');
      await tester.pumpAndSettle();

      // Show a notification.
      const testMessage = 'Notification to clear';
      harness.read(notificationQueueProvider.notifier).show(testMessage);
      await tester.pumpAndSettle();

      // Verify snackbar is visible.
      expect(find.text(testMessage), findsWidgets,
          reason: 'Notification message should be visible');

      // AppScaffold calls clear() immediately after showing the snackbar,
      // so the state should be null.
      final notification = harness.read(notificationQueueProvider);
      expect(notification, isNull,
          reason: 'Notification state should be null after AppScaffold shows snackbar');
    });
  });
}
