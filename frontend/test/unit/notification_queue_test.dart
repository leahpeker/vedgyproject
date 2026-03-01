// NotificationQueue unit tests — verifies the NotificationQueueNotifier
// state machine using a plain ProviderContainer (no widget tree needed).
//
// The provider is auto-dispose, so each test creates a fresh container and
// registers an addTearDown to dispose it.  All assertions use
// container.read(notificationQueueProvider) to inspect the current state.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vedgy/providers/notification_provider.dart';

void main() {
  // -------------------------------------------------------------------------
  // Helper: creates a ProviderContainer and registers disposal.
  // -------------------------------------------------------------------------

  ProviderContainer makeContainer() {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    return container;
  }

  // -------------------------------------------------------------------------
  // Initial state
  // -------------------------------------------------------------------------

  group('NotificationQueue — initial state', () {
    test('state is null before any notification is pushed', () {
      final container = makeContainer();

      expect(container.read(notificationQueueProvider), isNull);
    });
  });

  // -------------------------------------------------------------------------
  // show()
  // -------------------------------------------------------------------------

  group('NotificationQueue — show()', () {
    test('sets state to an AppNotification with the given message', () {
      final container = makeContainer();

      container.read(notificationQueueProvider.notifier).show('Hello');

      final notification = container.read(notificationQueueProvider);
      expect(notification, isNotNull);
      expect(notification!.message, 'Hello');
    });

    test('isError defaults to false when show() is called without isError', () {
      final container = makeContainer();

      container.read(notificationQueueProvider.notifier).show('Info message');

      final notification = container.read(notificationQueueProvider);
      expect(notification!.isError, isFalse);
    });

    test('show() with isError: true sets isError to true', () {
      final container = makeContainer();

      container
          .read(notificationQueueProvider.notifier)
          .show('Something failed', isError: true);

      final notification = container.read(notificationQueueProvider);
      expect(notification!.isError, isTrue);
    });

    test('show() with isError: false explicitly keeps isError false', () {
      final container = makeContainer();

      container
          .read(notificationQueueProvider.notifier)
          .show('All good', isError: false);

      final notification = container.read(notificationQueueProvider);
      expect(notification!.isError, isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // showError()
  // -------------------------------------------------------------------------

  group('NotificationQueue — showError()', () {
    test('sets state to an AppNotification with isError: true', () {
      final container = makeContainer();

      container.read(notificationQueueProvider.notifier).showError('Bad input');

      final notification = container.read(notificationQueueProvider);
      expect(notification, isNotNull);
      expect(notification!.isError, isTrue);
    });

    test('stores the correct message via showError()', () {
      final container = makeContainer();

      container
          .read(notificationQueueProvider.notifier)
          .showError('Network error');

      final notification = container.read(notificationQueueProvider);
      expect(notification!.message, 'Network error');
    });
  });

  // -------------------------------------------------------------------------
  // clear()
  // -------------------------------------------------------------------------

  group('NotificationQueue — clear()', () {
    test('resets state back to null after show()', () {
      final container = makeContainer();

      container.read(notificationQueueProvider.notifier).show('Temporary');
      expect(container.read(notificationQueueProvider), isNotNull);

      container.read(notificationQueueProvider.notifier).clear();

      expect(container.read(notificationQueueProvider), isNull);
    });

    test('resets state back to null after showError()', () {
      final container = makeContainer();

      container
          .read(notificationQueueProvider.notifier)
          .showError('Error msg');
      expect(container.read(notificationQueueProvider), isNotNull);

      container.read(notificationQueueProvider.notifier).clear();

      expect(container.read(notificationQueueProvider), isNull);
    });

    test('calling clear() on already-null state leaves state null', () {
      final container = makeContainer();

      // State is already null — clear() should be a no-op.
      container.read(notificationQueueProvider.notifier).clear();

      expect(container.read(notificationQueueProvider), isNull);
    });
  });

  // -------------------------------------------------------------------------
  // Replacement behaviour
  // -------------------------------------------------------------------------

  group('NotificationQueue — replacement', () {
    test('second show() replaces the first notification', () {
      final container = makeContainer();

      container.read(notificationQueueProvider.notifier).show('First');
      container.read(notificationQueueProvider.notifier).show('Second');

      final notification = container.read(notificationQueueProvider);
      expect(notification!.message, 'Second');
    });

    test('second show() keeps isError: false even if first was an error', () {
      final container = makeContainer();

      container
          .read(notificationQueueProvider.notifier)
          .showError('Error first');
      container.read(notificationQueueProvider.notifier).show('Success now');

      final notification = container.read(notificationQueueProvider);
      expect(notification!.isError, isFalse);
      expect(notification.message, 'Success now');
    });

    test('showError() replaces a previous regular notification', () {
      final container = makeContainer();

      container.read(notificationQueueProvider.notifier).show('Regular');
      container
          .read(notificationQueueProvider.notifier)
          .showError('Now an error');

      final notification = container.read(notificationQueueProvider);
      expect(notification!.isError, isTrue);
      expect(notification.message, 'Now an error');
    });
  });

  // -------------------------------------------------------------------------
  // Edge cases
  // -------------------------------------------------------------------------

  group('NotificationQueue — edge cases', () {
    test('empty string message is stored as-is', () {
      final container = makeContainer();

      container.read(notificationQueueProvider.notifier).show('');

      final notification = container.read(notificationQueueProvider);
      expect(notification, isNotNull);
      expect(notification!.message, '');
    });

    test('very long message is stored without truncation', () {
      final container = makeContainer();
      final longMessage = 'A' * 10000;

      container.read(notificationQueueProvider.notifier).show(longMessage);

      final notification = container.read(notificationQueueProvider);
      expect(notification!.message, longMessage);
      expect(notification.message.length, 10000);
    });

    test('empty string error message is stored as-is via showError()', () {
      final container = makeContainer();

      container.read(notificationQueueProvider.notifier).showError('');

      final notification = container.read(notificationQueueProvider);
      expect(notification, isNotNull);
      expect(notification!.message, '');
      expect(notification.isError, isTrue);
    });

    test('show → clear → show produces fresh notification', () {
      final container = makeContainer();

      container.read(notificationQueueProvider.notifier).show('First round');
      container.read(notificationQueueProvider.notifier).clear();
      container.read(notificationQueueProvider.notifier).show('Second round');

      final notification = container.read(notificationQueueProvider);
      expect(notification!.message, 'Second round');
      expect(notification.isError, isFalse);
    });
  });
}
