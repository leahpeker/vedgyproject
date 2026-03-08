import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'notification_provider.g.dart';

/// Payload for a single snackbar notification.
class AppNotification {
  const AppNotification({
    required this.message,
    this.isError = false,
  });

  final String message;
  final bool isError;
}

/// Provider that holds a pending notification to show.
/// AppScaffold listens to this and calls ScaffoldMessenger to show it,
/// then clears the state. Any screen can push a notification without
/// needing a BuildContext.
@riverpod
class NotificationQueue extends _$NotificationQueue {
  @override
  AppNotification? build() => null;

  void show(String message, {bool isError = false}) {
    state = AppNotification(message: message, isError: isError);
  }

  void showError(String message) => show(message, isError: true);

  void clear() => state = null;
}
