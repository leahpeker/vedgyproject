// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'browse_accumulator_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(BrowseAccumulator)
final browseAccumulatorProvider = BrowseAccumulatorProvider._();

final class BrowseAccumulatorProvider
    extends $AsyncNotifierProvider<BrowseAccumulator, BrowseAccumulatorState> {
  BrowseAccumulatorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'browseAccumulatorProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$browseAccumulatorHash();

  @$internal
  @override
  BrowseAccumulator create() => BrowseAccumulator();
}

String _$browseAccumulatorHash() => r'25c3520c370fa397d1fb8ed9629cd8e82df01da0';

abstract class _$BrowseAccumulator
    extends $AsyncNotifier<BrowseAccumulatorState> {
  FutureOr<BrowseAccumulatorState> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<BrowseAccumulatorState>, BrowseAccumulatorState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<BrowseAccumulatorState>,
                BrowseAccumulatorState
              >,
              AsyncValue<BrowseAccumulatorState>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
