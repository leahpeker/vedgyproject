// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(dashboard)
final dashboardProvider = DashboardProvider._();

final class DashboardProvider
    extends
        $FunctionalProvider<
          AsyncValue<DashboardOut>,
          DashboardOut,
          FutureOr<DashboardOut>
        >
    with $FutureModifier<DashboardOut>, $FutureProvider<DashboardOut> {
  DashboardProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dashboardProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dashboardHash();

  @$internal
  @override
  $FutureProviderElement<DashboardOut> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<DashboardOut> create(Ref ref) {
    return dashboard(ref);
  }
}

String _$dashboardHash() => r'd3b33a4c79fff66b18f5a4cee8dcc427b93ab797';
