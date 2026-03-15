// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'listings_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(BrowseFilters)
final browseFiltersProvider = BrowseFiltersProvider._();

final class BrowseFiltersProvider
    extends $NotifierProvider<BrowseFilters, ListingFilters> {
  BrowseFiltersProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'browseFiltersProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$browseFiltersHash();

  @$internal
  @override
  BrowseFilters create() => BrowseFilters();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ListingFilters value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ListingFilters>(value),
    );
  }
}

String _$browseFiltersHash() => r'308c63f6f7fd810efd6e273f53ea1db21bd9f4ce';

abstract class _$BrowseFilters extends $Notifier<ListingFilters> {
  ListingFilters build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<ListingFilters, ListingFilters>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ListingFilters, ListingFilters>,
              ListingFilters,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// @Deprecated('Browse screen now uses browseAccumulatorProvider')

@ProviderFor(browseListings)
final browseListingsProvider = BrowseListingsProvider._();

/// @Deprecated('Browse screen now uses browseAccumulatorProvider')

final class BrowseListingsProvider
    extends
        $FunctionalProvider<
          AsyncValue<PaginatedListings>,
          PaginatedListings,
          FutureOr<PaginatedListings>
        >
    with
        $FutureModifier<PaginatedListings>,
        $FutureProvider<PaginatedListings> {
  /// @Deprecated('Browse screen now uses browseAccumulatorProvider')
  BrowseListingsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'browseListingsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$browseListingsHash();

  @$internal
  @override
  $FutureProviderElement<PaginatedListings> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<PaginatedListings> create(Ref ref) {
    return browseListings(ref);
  }
}

String _$browseListingsHash() => r'a6c0d6d0dfbc8db00cb6d8f3f4c5bc169ad47736';

@ProviderFor(listingDetail)
final listingDetailProvider = ListingDetailFamily._();

final class ListingDetailProvider
    extends $FunctionalProvider<AsyncValue<Listing>, Listing, FutureOr<Listing>>
    with $FutureModifier<Listing>, $FutureProvider<Listing> {
  ListingDetailProvider._({
    required ListingDetailFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'listingDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$listingDetailHash();

  @override
  String toString() {
    return r'listingDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Listing> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Listing> create(Ref ref) {
    final argument = this.argument as String;
    return listingDetail(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ListingDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$listingDetailHash() => r'57c547a221d3c9fdce8560a403babbd664392955';

final class ListingDetailFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Listing>, String> {
  ListingDetailFamily._()
    : super(
        retry: null,
        name: r'listingDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ListingDetailProvider call(String id) =>
      ListingDetailProvider._(argument: id, from: this);

  @override
  String toString() => r'listingDetailProvider';
}
