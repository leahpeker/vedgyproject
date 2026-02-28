// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'listing.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ListingUser _$ListingUserFromJson(Map<String, dynamic> json) => _ListingUser(
  id: json['id'] as String,
  firstName: json['first_name'] as String,
  lastName: json['last_name'] as String,
);

Map<String, dynamic> _$ListingUserToJson(_ListingUser instance) =>
    <String, dynamic>{
      'id': instance.id,
      'first_name': instance.firstName,
      'last_name': instance.lastName,
    };

_ListingPhoto _$ListingPhotoFromJson(Map<String, dynamic> json) =>
    _ListingPhoto(
      id: json['id'] as String,
      filename: json['filename'] as String,
      url: json['url'] as String,
    );

Map<String, dynamic> _$ListingPhotoToJson(_ListingPhoto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'filename': instance.filename,
      'url': instance.url,
    };

_Listing _$ListingFromJson(Map<String, dynamic> json) => _Listing(
  id: json['id'] as String,
  title: json['title'] as String,
  description: json['description'] as String,
  city: json['city'] as String,
  borough: json['borough'] as String?,
  neighborhood: json['neighborhood'] as String?,
  price: (json['price'] as num?)?.toInt(),
  startDate: json['start_date'] == null
      ? null
      : DateTime.parse(json['start_date'] as String),
  endDate: json['end_date'] == null
      ? null
      : DateTime.parse(json['end_date'] as String),
  rentalType: json['rental_type'] as String,
  roomType: json['room_type'] as String,
  veganHousehold: json['vegan_household'] as String,
  furnished: json['furnished'] as String,
  listerRelationship: json['lister_relationship'] as String,
  seekingRoommate: json['seeking_roommate'] as bool? ?? false,
  aboutLister: json['about_lister'] as String?,
  rentalRequirements: json['rental_requirements'] as String?,
  petPolicy: json['pet_policy'] as String?,
  includePhone: json['include_phone'] as bool? ?? false,
  phoneNumber: json['phone_number'] as String?,
  status: json['status'] as String,
  user: ListingUser.fromJson(json['user'] as Map<String, dynamic>),
  photos:
      (json['photos'] as List<dynamic>?)
          ?.map((e) => ListingPhoto.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  createdAt: DateTime.parse(json['created_at'] as String),
  expiresAt: json['expires_at'] == null
      ? null
      : DateTime.parse(json['expires_at'] as String),
);

Map<String, dynamic> _$ListingToJson(_Listing instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'description': instance.description,
  'city': instance.city,
  'borough': instance.borough,
  'neighborhood': instance.neighborhood,
  'price': instance.price,
  'start_date': instance.startDate?.toIso8601String(),
  'end_date': instance.endDate?.toIso8601String(),
  'rental_type': instance.rentalType,
  'room_type': instance.roomType,
  'vegan_household': instance.veganHousehold,
  'furnished': instance.furnished,
  'lister_relationship': instance.listerRelationship,
  'seeking_roommate': instance.seekingRoommate,
  'about_lister': instance.aboutLister,
  'rental_requirements': instance.rentalRequirements,
  'pet_policy': instance.petPolicy,
  'include_phone': instance.includePhone,
  'phone_number': instance.phoneNumber,
  'status': instance.status,
  'user': instance.user.toJson(),
  'photos': instance.photos.map((e) => e.toJson()).toList(),
  'created_at': instance.createdAt.toIso8601String(),
  'expires_at': instance.expiresAt?.toIso8601String(),
};

_PaginatedListings _$PaginatedListingsFromJson(Map<String, dynamic> json) =>
    _PaginatedListings(
      items: (json['items'] as List<dynamic>)
          .map((e) => Listing.fromJson(e as Map<String, dynamic>))
          .toList(),
      count: (json['count'] as num).toInt(),
      page: (json['page'] as num).toInt(),
      pageSize: (json['page_size'] as num).toInt(),
    );

Map<String, dynamic> _$PaginatedListingsToJson(_PaginatedListings instance) =>
    <String, dynamic>{
      'items': instance.items.map((e) => e.toJson()).toList(),
      'count': instance.count,
      'page': instance.page,
      'page_size': instance.pageSize,
    };

_DashboardOut _$DashboardOutFromJson(Map<String, dynamic> json) =>
    _DashboardOut(
      drafts: (json['drafts'] as List<dynamic>)
          .map((e) => Listing.fromJson(e as Map<String, dynamic>))
          .toList(),
      paymentSubmitted: (json['payment_submitted'] as List<dynamic>)
          .map((e) => Listing.fromJson(e as Map<String, dynamic>))
          .toList(),
      active: (json['active'] as List<dynamic>)
          .map((e) => Listing.fromJson(e as Map<String, dynamic>))
          .toList(),
      expired: (json['expired'] as List<dynamic>)
          .map((e) => Listing.fromJson(e as Map<String, dynamic>))
          .toList(),
      deactivated: (json['deactivated'] as List<dynamic>)
          .map((e) => Listing.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$DashboardOutToJson(_DashboardOut instance) =>
    <String, dynamic>{
      'drafts': instance.drafts.map((e) => e.toJson()).toList(),
      'payment_submitted': instance.paymentSubmitted
          .map((e) => e.toJson())
          .toList(),
      'active': instance.active.map((e) => e.toJson()).toList(),
      'expired': instance.expired.map((e) => e.toJson()).toList(),
      'deactivated': instance.deactivated.map((e) => e.toJson()).toList(),
    };
