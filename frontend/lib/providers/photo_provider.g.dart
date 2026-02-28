// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'photo_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(photoActions)
final photoActionsProvider = PhotoActionsProvider._();

final class PhotoActionsProvider
    extends $FunctionalProvider<PhotoActions, PhotoActions, PhotoActions>
    with $Provider<PhotoActions> {
  PhotoActionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'photoActionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$photoActionsHash();

  @$internal
  @override
  $ProviderElement<PhotoActions> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PhotoActions create(Ref ref) {
    return photoActions(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PhotoActions value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PhotoActions>(value),
    );
  }
}

String _$photoActionsHash() => r'a9c71ade7c4064c95fc4d1acb2b262b5a6460eeb';
