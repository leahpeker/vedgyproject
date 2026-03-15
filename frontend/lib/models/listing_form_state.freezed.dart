// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'listing_form_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ListingFormState {

 String? get listingId; SaveStatus get saveStatus; List<ListingPhoto> get photos; bool get uploadingPhotos; bool get firstSaveInProgress;// Dropdown values
 String? get city; String? get borough; String? get rentalType; String? get roomType; String? get veganHousehold; String? get furnished; String? get listerRelationship;// Toggle values
 bool get seekingRoommate; bool get includePhone;
/// Create a copy of ListingFormState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ListingFormStateCopyWith<ListingFormState> get copyWith => _$ListingFormStateCopyWithImpl<ListingFormState>(this as ListingFormState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ListingFormState&&(identical(other.listingId, listingId) || other.listingId == listingId)&&(identical(other.saveStatus, saveStatus) || other.saveStatus == saveStatus)&&const DeepCollectionEquality().equals(other.photos, photos)&&(identical(other.uploadingPhotos, uploadingPhotos) || other.uploadingPhotos == uploadingPhotos)&&(identical(other.firstSaveInProgress, firstSaveInProgress) || other.firstSaveInProgress == firstSaveInProgress)&&(identical(other.city, city) || other.city == city)&&(identical(other.borough, borough) || other.borough == borough)&&(identical(other.rentalType, rentalType) || other.rentalType == rentalType)&&(identical(other.roomType, roomType) || other.roomType == roomType)&&(identical(other.veganHousehold, veganHousehold) || other.veganHousehold == veganHousehold)&&(identical(other.furnished, furnished) || other.furnished == furnished)&&(identical(other.listerRelationship, listerRelationship) || other.listerRelationship == listerRelationship)&&(identical(other.seekingRoommate, seekingRoommate) || other.seekingRoommate == seekingRoommate)&&(identical(other.includePhone, includePhone) || other.includePhone == includePhone));
}


@override
int get hashCode => Object.hash(runtimeType,listingId,saveStatus,const DeepCollectionEquality().hash(photos),uploadingPhotos,firstSaveInProgress,city,borough,rentalType,roomType,veganHousehold,furnished,listerRelationship,seekingRoommate,includePhone);

@override
String toString() {
  return 'ListingFormState(listingId: $listingId, saveStatus: $saveStatus, photos: $photos, uploadingPhotos: $uploadingPhotos, firstSaveInProgress: $firstSaveInProgress, city: $city, borough: $borough, rentalType: $rentalType, roomType: $roomType, veganHousehold: $veganHousehold, furnished: $furnished, listerRelationship: $listerRelationship, seekingRoommate: $seekingRoommate, includePhone: $includePhone)';
}


}

/// @nodoc
abstract mixin class $ListingFormStateCopyWith<$Res>  {
  factory $ListingFormStateCopyWith(ListingFormState value, $Res Function(ListingFormState) _then) = _$ListingFormStateCopyWithImpl;
@useResult
$Res call({
 String? listingId, SaveStatus saveStatus, List<ListingPhoto> photos, bool uploadingPhotos, bool firstSaveInProgress, String? city, String? borough, String? rentalType, String? roomType, String? veganHousehold, String? furnished, String? listerRelationship, bool seekingRoommate, bool includePhone
});




}
/// @nodoc
class _$ListingFormStateCopyWithImpl<$Res>
    implements $ListingFormStateCopyWith<$Res> {
  _$ListingFormStateCopyWithImpl(this._self, this._then);

  final ListingFormState _self;
  final $Res Function(ListingFormState) _then;

/// Create a copy of ListingFormState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? listingId = freezed,Object? saveStatus = null,Object? photos = null,Object? uploadingPhotos = null,Object? firstSaveInProgress = null,Object? city = freezed,Object? borough = freezed,Object? rentalType = freezed,Object? roomType = freezed,Object? veganHousehold = freezed,Object? furnished = freezed,Object? listerRelationship = freezed,Object? seekingRoommate = null,Object? includePhone = null,}) {
  return _then(_self.copyWith(
listingId: freezed == listingId ? _self.listingId : listingId // ignore: cast_nullable_to_non_nullable
as String?,saveStatus: null == saveStatus ? _self.saveStatus : saveStatus // ignore: cast_nullable_to_non_nullable
as SaveStatus,photos: null == photos ? _self.photos : photos // ignore: cast_nullable_to_non_nullable
as List<ListingPhoto>,uploadingPhotos: null == uploadingPhotos ? _self.uploadingPhotos : uploadingPhotos // ignore: cast_nullable_to_non_nullable
as bool,firstSaveInProgress: null == firstSaveInProgress ? _self.firstSaveInProgress : firstSaveInProgress // ignore: cast_nullable_to_non_nullable
as bool,city: freezed == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String?,borough: freezed == borough ? _self.borough : borough // ignore: cast_nullable_to_non_nullable
as String?,rentalType: freezed == rentalType ? _self.rentalType : rentalType // ignore: cast_nullable_to_non_nullable
as String?,roomType: freezed == roomType ? _self.roomType : roomType // ignore: cast_nullable_to_non_nullable
as String?,veganHousehold: freezed == veganHousehold ? _self.veganHousehold : veganHousehold // ignore: cast_nullable_to_non_nullable
as String?,furnished: freezed == furnished ? _self.furnished : furnished // ignore: cast_nullable_to_non_nullable
as String?,listerRelationship: freezed == listerRelationship ? _self.listerRelationship : listerRelationship // ignore: cast_nullable_to_non_nullable
as String?,seekingRoommate: null == seekingRoommate ? _self.seekingRoommate : seekingRoommate // ignore: cast_nullable_to_non_nullable
as bool,includePhone: null == includePhone ? _self.includePhone : includePhone // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [ListingFormState].
extension ListingFormStatePatterns on ListingFormState {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ListingFormState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ListingFormState() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ListingFormState value)  $default,){
final _that = this;
switch (_that) {
case _ListingFormState():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ListingFormState value)?  $default,){
final _that = this;
switch (_that) {
case _ListingFormState() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? listingId,  SaveStatus saveStatus,  List<ListingPhoto> photos,  bool uploadingPhotos,  bool firstSaveInProgress,  String? city,  String? borough,  String? rentalType,  String? roomType,  String? veganHousehold,  String? furnished,  String? listerRelationship,  bool seekingRoommate,  bool includePhone)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ListingFormState() when $default != null:
return $default(_that.listingId,_that.saveStatus,_that.photos,_that.uploadingPhotos,_that.firstSaveInProgress,_that.city,_that.borough,_that.rentalType,_that.roomType,_that.veganHousehold,_that.furnished,_that.listerRelationship,_that.seekingRoommate,_that.includePhone);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? listingId,  SaveStatus saveStatus,  List<ListingPhoto> photos,  bool uploadingPhotos,  bool firstSaveInProgress,  String? city,  String? borough,  String? rentalType,  String? roomType,  String? veganHousehold,  String? furnished,  String? listerRelationship,  bool seekingRoommate,  bool includePhone)  $default,) {final _that = this;
switch (_that) {
case _ListingFormState():
return $default(_that.listingId,_that.saveStatus,_that.photos,_that.uploadingPhotos,_that.firstSaveInProgress,_that.city,_that.borough,_that.rentalType,_that.roomType,_that.veganHousehold,_that.furnished,_that.listerRelationship,_that.seekingRoommate,_that.includePhone);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? listingId,  SaveStatus saveStatus,  List<ListingPhoto> photos,  bool uploadingPhotos,  bool firstSaveInProgress,  String? city,  String? borough,  String? rentalType,  String? roomType,  String? veganHousehold,  String? furnished,  String? listerRelationship,  bool seekingRoommate,  bool includePhone)?  $default,) {final _that = this;
switch (_that) {
case _ListingFormState() when $default != null:
return $default(_that.listingId,_that.saveStatus,_that.photos,_that.uploadingPhotos,_that.firstSaveInProgress,_that.city,_that.borough,_that.rentalType,_that.roomType,_that.veganHousehold,_that.furnished,_that.listerRelationship,_that.seekingRoommate,_that.includePhone);case _:
  return null;

}
}

}

/// @nodoc


class _ListingFormState implements ListingFormState {
  const _ListingFormState({this.listingId, this.saveStatus = SaveStatus.idle, final  List<ListingPhoto> photos = const [], this.uploadingPhotos = false, this.firstSaveInProgress = false, this.city, this.borough, this.rentalType, this.roomType, this.veganHousehold, this.furnished, this.listerRelationship, this.seekingRoommate = false, this.includePhone = false}): _photos = photos;
  

@override final  String? listingId;
@override@JsonKey() final  SaveStatus saveStatus;
 final  List<ListingPhoto> _photos;
@override@JsonKey() List<ListingPhoto> get photos {
  if (_photos is EqualUnmodifiableListView) return _photos;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_photos);
}

@override@JsonKey() final  bool uploadingPhotos;
@override@JsonKey() final  bool firstSaveInProgress;
// Dropdown values
@override final  String? city;
@override final  String? borough;
@override final  String? rentalType;
@override final  String? roomType;
@override final  String? veganHousehold;
@override final  String? furnished;
@override final  String? listerRelationship;
// Toggle values
@override@JsonKey() final  bool seekingRoommate;
@override@JsonKey() final  bool includePhone;

/// Create a copy of ListingFormState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ListingFormStateCopyWith<_ListingFormState> get copyWith => __$ListingFormStateCopyWithImpl<_ListingFormState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ListingFormState&&(identical(other.listingId, listingId) || other.listingId == listingId)&&(identical(other.saveStatus, saveStatus) || other.saveStatus == saveStatus)&&const DeepCollectionEquality().equals(other._photos, _photos)&&(identical(other.uploadingPhotos, uploadingPhotos) || other.uploadingPhotos == uploadingPhotos)&&(identical(other.firstSaveInProgress, firstSaveInProgress) || other.firstSaveInProgress == firstSaveInProgress)&&(identical(other.city, city) || other.city == city)&&(identical(other.borough, borough) || other.borough == borough)&&(identical(other.rentalType, rentalType) || other.rentalType == rentalType)&&(identical(other.roomType, roomType) || other.roomType == roomType)&&(identical(other.veganHousehold, veganHousehold) || other.veganHousehold == veganHousehold)&&(identical(other.furnished, furnished) || other.furnished == furnished)&&(identical(other.listerRelationship, listerRelationship) || other.listerRelationship == listerRelationship)&&(identical(other.seekingRoommate, seekingRoommate) || other.seekingRoommate == seekingRoommate)&&(identical(other.includePhone, includePhone) || other.includePhone == includePhone));
}


@override
int get hashCode => Object.hash(runtimeType,listingId,saveStatus,const DeepCollectionEquality().hash(_photos),uploadingPhotos,firstSaveInProgress,city,borough,rentalType,roomType,veganHousehold,furnished,listerRelationship,seekingRoommate,includePhone);

@override
String toString() {
  return 'ListingFormState(listingId: $listingId, saveStatus: $saveStatus, photos: $photos, uploadingPhotos: $uploadingPhotos, firstSaveInProgress: $firstSaveInProgress, city: $city, borough: $borough, rentalType: $rentalType, roomType: $roomType, veganHousehold: $veganHousehold, furnished: $furnished, listerRelationship: $listerRelationship, seekingRoommate: $seekingRoommate, includePhone: $includePhone)';
}


}

/// @nodoc
abstract mixin class _$ListingFormStateCopyWith<$Res> implements $ListingFormStateCopyWith<$Res> {
  factory _$ListingFormStateCopyWith(_ListingFormState value, $Res Function(_ListingFormState) _then) = __$ListingFormStateCopyWithImpl;
@override @useResult
$Res call({
 String? listingId, SaveStatus saveStatus, List<ListingPhoto> photos, bool uploadingPhotos, bool firstSaveInProgress, String? city, String? borough, String? rentalType, String? roomType, String? veganHousehold, String? furnished, String? listerRelationship, bool seekingRoommate, bool includePhone
});




}
/// @nodoc
class __$ListingFormStateCopyWithImpl<$Res>
    implements _$ListingFormStateCopyWith<$Res> {
  __$ListingFormStateCopyWithImpl(this._self, this._then);

  final _ListingFormState _self;
  final $Res Function(_ListingFormState) _then;

/// Create a copy of ListingFormState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? listingId = freezed,Object? saveStatus = null,Object? photos = null,Object? uploadingPhotos = null,Object? firstSaveInProgress = null,Object? city = freezed,Object? borough = freezed,Object? rentalType = freezed,Object? roomType = freezed,Object? veganHousehold = freezed,Object? furnished = freezed,Object? listerRelationship = freezed,Object? seekingRoommate = null,Object? includePhone = null,}) {
  return _then(_ListingFormState(
listingId: freezed == listingId ? _self.listingId : listingId // ignore: cast_nullable_to_non_nullable
as String?,saveStatus: null == saveStatus ? _self.saveStatus : saveStatus // ignore: cast_nullable_to_non_nullable
as SaveStatus,photos: null == photos ? _self._photos : photos // ignore: cast_nullable_to_non_nullable
as List<ListingPhoto>,uploadingPhotos: null == uploadingPhotos ? _self.uploadingPhotos : uploadingPhotos // ignore: cast_nullable_to_non_nullable
as bool,firstSaveInProgress: null == firstSaveInProgress ? _self.firstSaveInProgress : firstSaveInProgress // ignore: cast_nullable_to_non_nullable
as bool,city: freezed == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String?,borough: freezed == borough ? _self.borough : borough // ignore: cast_nullable_to_non_nullable
as String?,rentalType: freezed == rentalType ? _self.rentalType : rentalType // ignore: cast_nullable_to_non_nullable
as String?,roomType: freezed == roomType ? _self.roomType : roomType // ignore: cast_nullable_to_non_nullable
as String?,veganHousehold: freezed == veganHousehold ? _self.veganHousehold : veganHousehold // ignore: cast_nullable_to_non_nullable
as String?,furnished: freezed == furnished ? _self.furnished : furnished // ignore: cast_nullable_to_non_nullable
as String?,listerRelationship: freezed == listerRelationship ? _self.listerRelationship : listerRelationship // ignore: cast_nullable_to_non_nullable
as String?,seekingRoommate: null == seekingRoommate ? _self.seekingRoommate : seekingRoommate // ignore: cast_nullable_to_non_nullable
as bool,includePhone: null == includePhone ? _self.includePhone : includePhone // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
