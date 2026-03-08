// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'listing_actions_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(listingActions)
final listingActionsProvider = ListingActionsProvider._();

final class ListingActionsProvider
    extends $FunctionalProvider<ListingActions, ListingActions, ListingActions>
    with $Provider<ListingActions> {
  ListingActionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'listingActionsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$listingActionsHash();

  @$internal
  @override
  $ProviderElement<ListingActions> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ListingActions create(Ref ref) {
    return listingActions(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ListingActions value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ListingActions>(value),
    );
  }
}

String _$listingActionsHash() => r'3b1cffcb25cfb49ff1ae3344024311a9f8055ccc';
