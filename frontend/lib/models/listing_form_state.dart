import 'package:freezed_annotation/freezed_annotation.dart';

import 'listing.dart';

part 'listing_form_state.freezed.dart';

/// Save status for the listing form auto-save indicator.
enum SaveStatus { idle, saving, saved, error }

/// Immutable state for the listing form's dropdown, toggle, and status fields.
///
/// TextEditingControllers, pendingChanges (Map), and debounce (Timer)
/// remain as widget-level state since they are mutable/non-serializable.
@freezed
abstract class ListingFormState with _$ListingFormState {
  const factory ListingFormState({
    String? listingId,
    @Default(SaveStatus.idle) SaveStatus saveStatus,
    @Default([]) List<ListingPhoto> photos,
    @Default(false) bool uploadingPhotos,
    @Default(false) bool firstSaveInProgress,

    // Dropdown values
    String? city,
    String? borough,
    String? rentalType,
    String? roomType,
    String? veganHousehold,
    String? furnished,
    String? listerRelationship,

    // Toggle values
    @Default(false) bool seekingRoommate,
    @Default(false) bool includePhone,
  }) = _ListingFormState;
}
