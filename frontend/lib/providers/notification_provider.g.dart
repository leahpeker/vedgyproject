// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider that holds a pending notification to show.
/// AppScaffold listens to this and calls ScaffoldMessenger to show it,
/// then clears the state. Any screen can push a notification without
/// needing a BuildContext.

@ProviderFor(NotificationQueue)
final notificationQueueProvider = NotificationQueueProvider._();

/// Provider that holds a pending notification to show.
/// AppScaffold listens to this and calls ScaffoldMessenger to show it,
/// then clears the state. Any screen can push a notification without
/// needing a BuildContext.
final class NotificationQueueProvider
    extends $NotifierProvider<NotificationQueue, AppNotification?> {
  /// Provider that holds a pending notification to show.
  /// AppScaffold listens to this and calls ScaffoldMessenger to show it,
  /// then clears the state. Any screen can push a notification without
  /// needing a BuildContext.
  NotificationQueueProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notificationQueueProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notificationQueueHash();

  @$internal
  @override
  NotificationQueue create() => NotificationQueue();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppNotification? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppNotification?>(value),
    );
  }
}

String _$notificationQueueHash() => r'd0b9174cd2250c1c36da322edea49ff7b0f3457a';

/// Provider that holds a pending notification to show.
/// AppScaffold listens to this and calls ScaffoldMessenger to show it,
/// then clears the state. Any screen can push a notification without
/// needing a BuildContext.

abstract class _$NotificationQueue extends $Notifier<AppNotification?> {
  AppNotification? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AppNotification?, AppNotification?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AppNotification?, AppNotification?>,
              AppNotification?,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
