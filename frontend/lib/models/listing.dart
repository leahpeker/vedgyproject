// Models matching the Django Ninja ListingOut schema (listings/schemas.py).
// PaginatedListings and DashboardOut match the paginated browse and dashboard responses.
import 'package:freezed_annotation/freezed_annotation.dart';

part 'listing.freezed.dart';
part 'listing.g.dart';

@freezed
abstract class ListingUser with _$ListingUser {
  const factory ListingUser({
    required String id,
    required String firstName,
    required String lastName,
  }) = _ListingUser;

  factory ListingUser.fromJson(Map<String, dynamic> json) =>
      _$ListingUserFromJson(json);
}

@freezed
abstract class ListingPhoto with _$ListingPhoto {
  const factory ListingPhoto({
    required String id,
    required String filename,
    required String url,
  }) = _ListingPhoto;

  factory ListingPhoto.fromJson(Map<String, dynamic> json) =>
      _$ListingPhotoFromJson(json);
}

@freezed
abstract class Listing with _$Listing {
  const factory Listing({
    required String id,
    required String title,
    required String description,
    required String city,
    String? borough,
    String? neighborhood,
    int? price,
    DateTime? startDate,
    DateTime? endDate,
    required String rentalType,
    required String roomType,
    required String veganHousehold,
    required String furnished,
    String? size,
    String? transportation,
    required String listerRelationship,
    @Default(false) bool seekingRoommate,
    String? aboutLister,
    String? rentalRequirements,
    String? petPolicy,
    @Default(false) bool includePhone,
    String? phoneNumber,
    required String status,
    required ListingUser user,
    @Default([]) List<ListingPhoto> photos,
    required DateTime createdAt,
    DateTime? expiresAt,
  }) = _Listing;

  factory Listing.fromJson(Map<String, dynamic> json) =>
      _$ListingFromJson(json);
}

@freezed
abstract class PaginatedListings with _$PaginatedListings {
  const factory PaginatedListings({
    required List<Listing> items,
    required int count,
    required int page,
    required int pageSize,
  }) = _PaginatedListings;

  factory PaginatedListings.fromJson(Map<String, dynamic> json) =>
      _$PaginatedListingsFromJson(json);
}

@freezed
abstract class ListingFilters with _$ListingFilters {
  const factory ListingFilters({
    String? city,
    String? borough,
    String? rentalType,
    String? roomType,
    String? veganHousehold,
    String? furnished,
    bool? seekingRoommate,
    int? priceMin,
    int? priceMax,
    @Default(1) int page,
  }) = _ListingFilters;
}

@freezed
abstract class DashboardOut with _$DashboardOut {
  const factory DashboardOut({
    required List<Listing> drafts,
    @JsonKey(name: 'payment_submitted') required List<Listing> paymentSubmitted,
    required List<Listing> active,
    required List<Listing> expired,
    required List<Listing> deactivated,
  }) = _DashboardOut;

  factory DashboardOut.fromJson(Map<String, dynamic> json) =>
      _$DashboardOutFromJson(json);
}
