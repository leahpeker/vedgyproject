// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'listing.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ListingUser {

 String get id; String get firstName; String get lastName;
/// Create a copy of ListingUser
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ListingUserCopyWith<ListingUser> get copyWith => _$ListingUserCopyWithImpl<ListingUser>(this as ListingUser, _$identity);

  /// Serializes this ListingUser to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ListingUser&&(identical(other.id, id) || other.id == id)&&(identical(other.firstName, firstName) || other.firstName == firstName)&&(identical(other.lastName, lastName) || other.lastName == lastName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,firstName,lastName);

@override
String toString() {
  return 'ListingUser(id: $id, firstName: $firstName, lastName: $lastName)';
}


}

/// @nodoc
abstract mixin class $ListingUserCopyWith<$Res>  {
  factory $ListingUserCopyWith(ListingUser value, $Res Function(ListingUser) _then) = _$ListingUserCopyWithImpl;
@useResult
$Res call({
 String id, String firstName, String lastName
});




}
/// @nodoc
class _$ListingUserCopyWithImpl<$Res>
    implements $ListingUserCopyWith<$Res> {
  _$ListingUserCopyWithImpl(this._self, this._then);

  final ListingUser _self;
  final $Res Function(ListingUser) _then;

/// Create a copy of ListingUser
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? firstName = null,Object? lastName = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,firstName: null == firstName ? _self.firstName : firstName // ignore: cast_nullable_to_non_nullable
as String,lastName: null == lastName ? _self.lastName : lastName // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ListingUser].
extension ListingUserPatterns on ListingUser {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ListingUser value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ListingUser() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ListingUser value)  $default,){
final _that = this;
switch (_that) {
case _ListingUser():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ListingUser value)?  $default,){
final _that = this;
switch (_that) {
case _ListingUser() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String firstName,  String lastName)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ListingUser() when $default != null:
return $default(_that.id,_that.firstName,_that.lastName);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String firstName,  String lastName)  $default,) {final _that = this;
switch (_that) {
case _ListingUser():
return $default(_that.id,_that.firstName,_that.lastName);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String firstName,  String lastName)?  $default,) {final _that = this;
switch (_that) {
case _ListingUser() when $default != null:
return $default(_that.id,_that.firstName,_that.lastName);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ListingUser implements ListingUser {
  const _ListingUser({required this.id, required this.firstName, required this.lastName});
  factory _ListingUser.fromJson(Map<String, dynamic> json) => _$ListingUserFromJson(json);

@override final  String id;
@override final  String firstName;
@override final  String lastName;

/// Create a copy of ListingUser
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ListingUserCopyWith<_ListingUser> get copyWith => __$ListingUserCopyWithImpl<_ListingUser>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ListingUserToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ListingUser&&(identical(other.id, id) || other.id == id)&&(identical(other.firstName, firstName) || other.firstName == firstName)&&(identical(other.lastName, lastName) || other.lastName == lastName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,firstName,lastName);

@override
String toString() {
  return 'ListingUser(id: $id, firstName: $firstName, lastName: $lastName)';
}


}

/// @nodoc
abstract mixin class _$ListingUserCopyWith<$Res> implements $ListingUserCopyWith<$Res> {
  factory _$ListingUserCopyWith(_ListingUser value, $Res Function(_ListingUser) _then) = __$ListingUserCopyWithImpl;
@override @useResult
$Res call({
 String id, String firstName, String lastName
});




}
/// @nodoc
class __$ListingUserCopyWithImpl<$Res>
    implements _$ListingUserCopyWith<$Res> {
  __$ListingUserCopyWithImpl(this._self, this._then);

  final _ListingUser _self;
  final $Res Function(_ListingUser) _then;

/// Create a copy of ListingUser
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? firstName = null,Object? lastName = null,}) {
  return _then(_ListingUser(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,firstName: null == firstName ? _self.firstName : firstName // ignore: cast_nullable_to_non_nullable
as String,lastName: null == lastName ? _self.lastName : lastName // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$ListingPhoto {

 String get id; String get filename; String get url;
/// Create a copy of ListingPhoto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ListingPhotoCopyWith<ListingPhoto> get copyWith => _$ListingPhotoCopyWithImpl<ListingPhoto>(this as ListingPhoto, _$identity);

  /// Serializes this ListingPhoto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ListingPhoto&&(identical(other.id, id) || other.id == id)&&(identical(other.filename, filename) || other.filename == filename)&&(identical(other.url, url) || other.url == url));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,filename,url);

@override
String toString() {
  return 'ListingPhoto(id: $id, filename: $filename, url: $url)';
}


}

/// @nodoc
abstract mixin class $ListingPhotoCopyWith<$Res>  {
  factory $ListingPhotoCopyWith(ListingPhoto value, $Res Function(ListingPhoto) _then) = _$ListingPhotoCopyWithImpl;
@useResult
$Res call({
 String id, String filename, String url
});




}
/// @nodoc
class _$ListingPhotoCopyWithImpl<$Res>
    implements $ListingPhotoCopyWith<$Res> {
  _$ListingPhotoCopyWithImpl(this._self, this._then);

  final ListingPhoto _self;
  final $Res Function(ListingPhoto) _then;

/// Create a copy of ListingPhoto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? filename = null,Object? url = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,filename: null == filename ? _self.filename : filename // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ListingPhoto].
extension ListingPhotoPatterns on ListingPhoto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ListingPhoto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ListingPhoto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ListingPhoto value)  $default,){
final _that = this;
switch (_that) {
case _ListingPhoto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ListingPhoto value)?  $default,){
final _that = this;
switch (_that) {
case _ListingPhoto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String filename,  String url)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ListingPhoto() when $default != null:
return $default(_that.id,_that.filename,_that.url);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String filename,  String url)  $default,) {final _that = this;
switch (_that) {
case _ListingPhoto():
return $default(_that.id,_that.filename,_that.url);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String filename,  String url)?  $default,) {final _that = this;
switch (_that) {
case _ListingPhoto() when $default != null:
return $default(_that.id,_that.filename,_that.url);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ListingPhoto implements ListingPhoto {
  const _ListingPhoto({required this.id, required this.filename, required this.url});
  factory _ListingPhoto.fromJson(Map<String, dynamic> json) => _$ListingPhotoFromJson(json);

@override final  String id;
@override final  String filename;
@override final  String url;

/// Create a copy of ListingPhoto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ListingPhotoCopyWith<_ListingPhoto> get copyWith => __$ListingPhotoCopyWithImpl<_ListingPhoto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ListingPhotoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ListingPhoto&&(identical(other.id, id) || other.id == id)&&(identical(other.filename, filename) || other.filename == filename)&&(identical(other.url, url) || other.url == url));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,filename,url);

@override
String toString() {
  return 'ListingPhoto(id: $id, filename: $filename, url: $url)';
}


}

/// @nodoc
abstract mixin class _$ListingPhotoCopyWith<$Res> implements $ListingPhotoCopyWith<$Res> {
  factory _$ListingPhotoCopyWith(_ListingPhoto value, $Res Function(_ListingPhoto) _then) = __$ListingPhotoCopyWithImpl;
@override @useResult
$Res call({
 String id, String filename, String url
});




}
/// @nodoc
class __$ListingPhotoCopyWithImpl<$Res>
    implements _$ListingPhotoCopyWith<$Res> {
  __$ListingPhotoCopyWithImpl(this._self, this._then);

  final _ListingPhoto _self;
  final $Res Function(_ListingPhoto) _then;

/// Create a copy of ListingPhoto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? filename = null,Object? url = null,}) {
  return _then(_ListingPhoto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,filename: null == filename ? _self.filename : filename // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$Listing {

 String get id; String get title; String get description; String get city; String? get borough; String? get neighborhood; int? get price; DateTime? get startDate; DateTime? get endDate; String get rentalType; String get roomType; String get veganHousehold; String get furnished; String? get size; String? get transportation; String get listerRelationship; bool get seekingRoommate; String? get aboutLister; String? get rentalRequirements; String? get petPolicy; bool get includePhone; String? get phoneNumber; String get status; ListingUser get user; List<ListingPhoto> get photos; DateTime get createdAt; DateTime? get expiresAt;
/// Create a copy of Listing
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ListingCopyWith<Listing> get copyWith => _$ListingCopyWithImpl<Listing>(this as Listing, _$identity);

  /// Serializes this Listing to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Listing&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.city, city) || other.city == city)&&(identical(other.borough, borough) || other.borough == borough)&&(identical(other.neighborhood, neighborhood) || other.neighborhood == neighborhood)&&(identical(other.price, price) || other.price == price)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.rentalType, rentalType) || other.rentalType == rentalType)&&(identical(other.roomType, roomType) || other.roomType == roomType)&&(identical(other.veganHousehold, veganHousehold) || other.veganHousehold == veganHousehold)&&(identical(other.furnished, furnished) || other.furnished == furnished)&&(identical(other.size, size) || other.size == size)&&(identical(other.transportation, transportation) || other.transportation == transportation)&&(identical(other.listerRelationship, listerRelationship) || other.listerRelationship == listerRelationship)&&(identical(other.seekingRoommate, seekingRoommate) || other.seekingRoommate == seekingRoommate)&&(identical(other.aboutLister, aboutLister) || other.aboutLister == aboutLister)&&(identical(other.rentalRequirements, rentalRequirements) || other.rentalRequirements == rentalRequirements)&&(identical(other.petPolicy, petPolicy) || other.petPolicy == petPolicy)&&(identical(other.includePhone, includePhone) || other.includePhone == includePhone)&&(identical(other.phoneNumber, phoneNumber) || other.phoneNumber == phoneNumber)&&(identical(other.status, status) || other.status == status)&&(identical(other.user, user) || other.user == user)&&const DeepCollectionEquality().equals(other.photos, photos)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,title,description,city,borough,neighborhood,price,startDate,endDate,rentalType,roomType,veganHousehold,furnished,size,transportation,listerRelationship,seekingRoommate,aboutLister,rentalRequirements,petPolicy,includePhone,phoneNumber,status,user,const DeepCollectionEquality().hash(photos),createdAt,expiresAt]);

@override
String toString() {
  return 'Listing(id: $id, title: $title, description: $description, city: $city, borough: $borough, neighborhood: $neighborhood, price: $price, startDate: $startDate, endDate: $endDate, rentalType: $rentalType, roomType: $roomType, veganHousehold: $veganHousehold, furnished: $furnished, size: $size, transportation: $transportation, listerRelationship: $listerRelationship, seekingRoommate: $seekingRoommate, aboutLister: $aboutLister, rentalRequirements: $rentalRequirements, petPolicy: $petPolicy, includePhone: $includePhone, phoneNumber: $phoneNumber, status: $status, user: $user, photos: $photos, createdAt: $createdAt, expiresAt: $expiresAt)';
}


}

/// @nodoc
abstract mixin class $ListingCopyWith<$Res>  {
  factory $ListingCopyWith(Listing value, $Res Function(Listing) _then) = _$ListingCopyWithImpl;
@useResult
$Res call({
 String id, String title, String description, String city, String? borough, String? neighborhood, int? price, DateTime? startDate, DateTime? endDate, String rentalType, String roomType, String veganHousehold, String furnished, String? size, String? transportation, String listerRelationship, bool seekingRoommate, String? aboutLister, String? rentalRequirements, String? petPolicy, bool includePhone, String? phoneNumber, String status, ListingUser user, List<ListingPhoto> photos, DateTime createdAt, DateTime? expiresAt
});


$ListingUserCopyWith<$Res> get user;

}
/// @nodoc
class _$ListingCopyWithImpl<$Res>
    implements $ListingCopyWith<$Res> {
  _$ListingCopyWithImpl(this._self, this._then);

  final Listing _self;
  final $Res Function(Listing) _then;

/// Create a copy of Listing
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? description = null,Object? city = null,Object? borough = freezed,Object? neighborhood = freezed,Object? price = freezed,Object? startDate = freezed,Object? endDate = freezed,Object? rentalType = null,Object? roomType = null,Object? veganHousehold = null,Object? furnished = null,Object? size = freezed,Object? transportation = freezed,Object? listerRelationship = null,Object? seekingRoommate = null,Object? aboutLister = freezed,Object? rentalRequirements = freezed,Object? petPolicy = freezed,Object? includePhone = null,Object? phoneNumber = freezed,Object? status = null,Object? user = null,Object? photos = null,Object? createdAt = null,Object? expiresAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,borough: freezed == borough ? _self.borough : borough // ignore: cast_nullable_to_non_nullable
as String?,neighborhood: freezed == neighborhood ? _self.neighborhood : neighborhood // ignore: cast_nullable_to_non_nullable
as String?,price: freezed == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as int?,startDate: freezed == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime?,endDate: freezed == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime?,rentalType: null == rentalType ? _self.rentalType : rentalType // ignore: cast_nullable_to_non_nullable
as String,roomType: null == roomType ? _self.roomType : roomType // ignore: cast_nullable_to_non_nullable
as String,veganHousehold: null == veganHousehold ? _self.veganHousehold : veganHousehold // ignore: cast_nullable_to_non_nullable
as String,furnished: null == furnished ? _self.furnished : furnished // ignore: cast_nullable_to_non_nullable
as String,size: freezed == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as String?,transportation: freezed == transportation ? _self.transportation : transportation // ignore: cast_nullable_to_non_nullable
as String?,listerRelationship: null == listerRelationship ? _self.listerRelationship : listerRelationship // ignore: cast_nullable_to_non_nullable
as String,seekingRoommate: null == seekingRoommate ? _self.seekingRoommate : seekingRoommate // ignore: cast_nullable_to_non_nullable
as bool,aboutLister: freezed == aboutLister ? _self.aboutLister : aboutLister // ignore: cast_nullable_to_non_nullable
as String?,rentalRequirements: freezed == rentalRequirements ? _self.rentalRequirements : rentalRequirements // ignore: cast_nullable_to_non_nullable
as String?,petPolicy: freezed == petPolicy ? _self.petPolicy : petPolicy // ignore: cast_nullable_to_non_nullable
as String?,includePhone: null == includePhone ? _self.includePhone : includePhone // ignore: cast_nullable_to_non_nullable
as bool,phoneNumber: freezed == phoneNumber ? _self.phoneNumber : phoneNumber // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,user: null == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as ListingUser,photos: null == photos ? _self.photos : photos // ignore: cast_nullable_to_non_nullable
as List<ListingPhoto>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}
/// Create a copy of Listing
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ListingUserCopyWith<$Res> get user {
  
  return $ListingUserCopyWith<$Res>(_self.user, (value) {
    return _then(_self.copyWith(user: value));
  });
}
}


/// Adds pattern-matching-related methods to [Listing].
extension ListingPatterns on Listing {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Listing value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Listing() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Listing value)  $default,){
final _that = this;
switch (_that) {
case _Listing():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Listing value)?  $default,){
final _that = this;
switch (_that) {
case _Listing() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  String description,  String city,  String? borough,  String? neighborhood,  int? price,  DateTime? startDate,  DateTime? endDate,  String rentalType,  String roomType,  String veganHousehold,  String furnished,  String? size,  String? transportation,  String listerRelationship,  bool seekingRoommate,  String? aboutLister,  String? rentalRequirements,  String? petPolicy,  bool includePhone,  String? phoneNumber,  String status,  ListingUser user,  List<ListingPhoto> photos,  DateTime createdAt,  DateTime? expiresAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Listing() when $default != null:
return $default(_that.id,_that.title,_that.description,_that.city,_that.borough,_that.neighborhood,_that.price,_that.startDate,_that.endDate,_that.rentalType,_that.roomType,_that.veganHousehold,_that.furnished,_that.size,_that.transportation,_that.listerRelationship,_that.seekingRoommate,_that.aboutLister,_that.rentalRequirements,_that.petPolicy,_that.includePhone,_that.phoneNumber,_that.status,_that.user,_that.photos,_that.createdAt,_that.expiresAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  String description,  String city,  String? borough,  String? neighborhood,  int? price,  DateTime? startDate,  DateTime? endDate,  String rentalType,  String roomType,  String veganHousehold,  String furnished,  String? size,  String? transportation,  String listerRelationship,  bool seekingRoommate,  String? aboutLister,  String? rentalRequirements,  String? petPolicy,  bool includePhone,  String? phoneNumber,  String status,  ListingUser user,  List<ListingPhoto> photos,  DateTime createdAt,  DateTime? expiresAt)  $default,) {final _that = this;
switch (_that) {
case _Listing():
return $default(_that.id,_that.title,_that.description,_that.city,_that.borough,_that.neighborhood,_that.price,_that.startDate,_that.endDate,_that.rentalType,_that.roomType,_that.veganHousehold,_that.furnished,_that.size,_that.transportation,_that.listerRelationship,_that.seekingRoommate,_that.aboutLister,_that.rentalRequirements,_that.petPolicy,_that.includePhone,_that.phoneNumber,_that.status,_that.user,_that.photos,_that.createdAt,_that.expiresAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  String description,  String city,  String? borough,  String? neighborhood,  int? price,  DateTime? startDate,  DateTime? endDate,  String rentalType,  String roomType,  String veganHousehold,  String furnished,  String? size,  String? transportation,  String listerRelationship,  bool seekingRoommate,  String? aboutLister,  String? rentalRequirements,  String? petPolicy,  bool includePhone,  String? phoneNumber,  String status,  ListingUser user,  List<ListingPhoto> photos,  DateTime createdAt,  DateTime? expiresAt)?  $default,) {final _that = this;
switch (_that) {
case _Listing() when $default != null:
return $default(_that.id,_that.title,_that.description,_that.city,_that.borough,_that.neighborhood,_that.price,_that.startDate,_that.endDate,_that.rentalType,_that.roomType,_that.veganHousehold,_that.furnished,_that.size,_that.transportation,_that.listerRelationship,_that.seekingRoommate,_that.aboutLister,_that.rentalRequirements,_that.petPolicy,_that.includePhone,_that.phoneNumber,_that.status,_that.user,_that.photos,_that.createdAt,_that.expiresAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Listing implements Listing {
  const _Listing({required this.id, required this.title, required this.description, required this.city, this.borough, this.neighborhood, this.price, this.startDate, this.endDate, required this.rentalType, required this.roomType, required this.veganHousehold, required this.furnished, this.size, this.transportation, required this.listerRelationship, this.seekingRoommate = false, this.aboutLister, this.rentalRequirements, this.petPolicy, this.includePhone = false, this.phoneNumber, required this.status, required this.user, final  List<ListingPhoto> photos = const [], required this.createdAt, this.expiresAt}): _photos = photos;
  factory _Listing.fromJson(Map<String, dynamic> json) => _$ListingFromJson(json);

@override final  String id;
@override final  String title;
@override final  String description;
@override final  String city;
@override final  String? borough;
@override final  String? neighborhood;
@override final  int? price;
@override final  DateTime? startDate;
@override final  DateTime? endDate;
@override final  String rentalType;
@override final  String roomType;
@override final  String veganHousehold;
@override final  String furnished;
@override final  String? size;
@override final  String? transportation;
@override final  String listerRelationship;
@override@JsonKey() final  bool seekingRoommate;
@override final  String? aboutLister;
@override final  String? rentalRequirements;
@override final  String? petPolicy;
@override@JsonKey() final  bool includePhone;
@override final  String? phoneNumber;
@override final  String status;
@override final  ListingUser user;
 final  List<ListingPhoto> _photos;
@override@JsonKey() List<ListingPhoto> get photos {
  if (_photos is EqualUnmodifiableListView) return _photos;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_photos);
}

@override final  DateTime createdAt;
@override final  DateTime? expiresAt;

/// Create a copy of Listing
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ListingCopyWith<_Listing> get copyWith => __$ListingCopyWithImpl<_Listing>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ListingToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Listing&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.city, city) || other.city == city)&&(identical(other.borough, borough) || other.borough == borough)&&(identical(other.neighborhood, neighborhood) || other.neighborhood == neighborhood)&&(identical(other.price, price) || other.price == price)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.rentalType, rentalType) || other.rentalType == rentalType)&&(identical(other.roomType, roomType) || other.roomType == roomType)&&(identical(other.veganHousehold, veganHousehold) || other.veganHousehold == veganHousehold)&&(identical(other.furnished, furnished) || other.furnished == furnished)&&(identical(other.size, size) || other.size == size)&&(identical(other.transportation, transportation) || other.transportation == transportation)&&(identical(other.listerRelationship, listerRelationship) || other.listerRelationship == listerRelationship)&&(identical(other.seekingRoommate, seekingRoommate) || other.seekingRoommate == seekingRoommate)&&(identical(other.aboutLister, aboutLister) || other.aboutLister == aboutLister)&&(identical(other.rentalRequirements, rentalRequirements) || other.rentalRequirements == rentalRequirements)&&(identical(other.petPolicy, petPolicy) || other.petPolicy == petPolicy)&&(identical(other.includePhone, includePhone) || other.includePhone == includePhone)&&(identical(other.phoneNumber, phoneNumber) || other.phoneNumber == phoneNumber)&&(identical(other.status, status) || other.status == status)&&(identical(other.user, user) || other.user == user)&&const DeepCollectionEquality().equals(other._photos, _photos)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,title,description,city,borough,neighborhood,price,startDate,endDate,rentalType,roomType,veganHousehold,furnished,size,transportation,listerRelationship,seekingRoommate,aboutLister,rentalRequirements,petPolicy,includePhone,phoneNumber,status,user,const DeepCollectionEquality().hash(_photos),createdAt,expiresAt]);

@override
String toString() {
  return 'Listing(id: $id, title: $title, description: $description, city: $city, borough: $borough, neighborhood: $neighborhood, price: $price, startDate: $startDate, endDate: $endDate, rentalType: $rentalType, roomType: $roomType, veganHousehold: $veganHousehold, furnished: $furnished, size: $size, transportation: $transportation, listerRelationship: $listerRelationship, seekingRoommate: $seekingRoommate, aboutLister: $aboutLister, rentalRequirements: $rentalRequirements, petPolicy: $petPolicy, includePhone: $includePhone, phoneNumber: $phoneNumber, status: $status, user: $user, photos: $photos, createdAt: $createdAt, expiresAt: $expiresAt)';
}


}

/// @nodoc
abstract mixin class _$ListingCopyWith<$Res> implements $ListingCopyWith<$Res> {
  factory _$ListingCopyWith(_Listing value, $Res Function(_Listing) _then) = __$ListingCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, String description, String city, String? borough, String? neighborhood, int? price, DateTime? startDate, DateTime? endDate, String rentalType, String roomType, String veganHousehold, String furnished, String? size, String? transportation, String listerRelationship, bool seekingRoommate, String? aboutLister, String? rentalRequirements, String? petPolicy, bool includePhone, String? phoneNumber, String status, ListingUser user, List<ListingPhoto> photos, DateTime createdAt, DateTime? expiresAt
});


@override $ListingUserCopyWith<$Res> get user;

}
/// @nodoc
class __$ListingCopyWithImpl<$Res>
    implements _$ListingCopyWith<$Res> {
  __$ListingCopyWithImpl(this._self, this._then);

  final _Listing _self;
  final $Res Function(_Listing) _then;

/// Create a copy of Listing
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? description = null,Object? city = null,Object? borough = freezed,Object? neighborhood = freezed,Object? price = freezed,Object? startDate = freezed,Object? endDate = freezed,Object? rentalType = null,Object? roomType = null,Object? veganHousehold = null,Object? furnished = null,Object? size = freezed,Object? transportation = freezed,Object? listerRelationship = null,Object? seekingRoommate = null,Object? aboutLister = freezed,Object? rentalRequirements = freezed,Object? petPolicy = freezed,Object? includePhone = null,Object? phoneNumber = freezed,Object? status = null,Object? user = null,Object? photos = null,Object? createdAt = null,Object? expiresAt = freezed,}) {
  return _then(_Listing(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,borough: freezed == borough ? _self.borough : borough // ignore: cast_nullable_to_non_nullable
as String?,neighborhood: freezed == neighborhood ? _self.neighborhood : neighborhood // ignore: cast_nullable_to_non_nullable
as String?,price: freezed == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as int?,startDate: freezed == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime?,endDate: freezed == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime?,rentalType: null == rentalType ? _self.rentalType : rentalType // ignore: cast_nullable_to_non_nullable
as String,roomType: null == roomType ? _self.roomType : roomType // ignore: cast_nullable_to_non_nullable
as String,veganHousehold: null == veganHousehold ? _self.veganHousehold : veganHousehold // ignore: cast_nullable_to_non_nullable
as String,furnished: null == furnished ? _self.furnished : furnished // ignore: cast_nullable_to_non_nullable
as String,size: freezed == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as String?,transportation: freezed == transportation ? _self.transportation : transportation // ignore: cast_nullable_to_non_nullable
as String?,listerRelationship: null == listerRelationship ? _self.listerRelationship : listerRelationship // ignore: cast_nullable_to_non_nullable
as String,seekingRoommate: null == seekingRoommate ? _self.seekingRoommate : seekingRoommate // ignore: cast_nullable_to_non_nullable
as bool,aboutLister: freezed == aboutLister ? _self.aboutLister : aboutLister // ignore: cast_nullable_to_non_nullable
as String?,rentalRequirements: freezed == rentalRequirements ? _self.rentalRequirements : rentalRequirements // ignore: cast_nullable_to_non_nullable
as String?,petPolicy: freezed == petPolicy ? _self.petPolicy : petPolicy // ignore: cast_nullable_to_non_nullable
as String?,includePhone: null == includePhone ? _self.includePhone : includePhone // ignore: cast_nullable_to_non_nullable
as bool,phoneNumber: freezed == phoneNumber ? _self.phoneNumber : phoneNumber // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,user: null == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as ListingUser,photos: null == photos ? _self._photos : photos // ignore: cast_nullable_to_non_nullable
as List<ListingPhoto>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

/// Create a copy of Listing
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ListingUserCopyWith<$Res> get user {
  
  return $ListingUserCopyWith<$Res>(_self.user, (value) {
    return _then(_self.copyWith(user: value));
  });
}
}


/// @nodoc
mixin _$PaginatedListings {

 List<Listing> get items; int get count; int get page; int get pageSize;
/// Create a copy of PaginatedListings
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PaginatedListingsCopyWith<PaginatedListings> get copyWith => _$PaginatedListingsCopyWithImpl<PaginatedListings>(this as PaginatedListings, _$identity);

  /// Serializes this PaginatedListings to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PaginatedListings&&const DeepCollectionEquality().equals(other.items, items)&&(identical(other.count, count) || other.count == count)&&(identical(other.page, page) || other.page == page)&&(identical(other.pageSize, pageSize) || other.pageSize == pageSize));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(items),count,page,pageSize);

@override
String toString() {
  return 'PaginatedListings(items: $items, count: $count, page: $page, pageSize: $pageSize)';
}


}

/// @nodoc
abstract mixin class $PaginatedListingsCopyWith<$Res>  {
  factory $PaginatedListingsCopyWith(PaginatedListings value, $Res Function(PaginatedListings) _then) = _$PaginatedListingsCopyWithImpl;
@useResult
$Res call({
 List<Listing> items, int count, int page, int pageSize
});




}
/// @nodoc
class _$PaginatedListingsCopyWithImpl<$Res>
    implements $PaginatedListingsCopyWith<$Res> {
  _$PaginatedListingsCopyWithImpl(this._self, this._then);

  final PaginatedListings _self;
  final $Res Function(PaginatedListings) _then;

/// Create a copy of PaginatedListings
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,Object? count = null,Object? page = null,Object? pageSize = null,}) {
  return _then(_self.copyWith(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<Listing>,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,pageSize: null == pageSize ? _self.pageSize : pageSize // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [PaginatedListings].
extension PaginatedListingsPatterns on PaginatedListings {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PaginatedListings value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PaginatedListings() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PaginatedListings value)  $default,){
final _that = this;
switch (_that) {
case _PaginatedListings():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PaginatedListings value)?  $default,){
final _that = this;
switch (_that) {
case _PaginatedListings() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<Listing> items,  int count,  int page,  int pageSize)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PaginatedListings() when $default != null:
return $default(_that.items,_that.count,_that.page,_that.pageSize);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<Listing> items,  int count,  int page,  int pageSize)  $default,) {final _that = this;
switch (_that) {
case _PaginatedListings():
return $default(_that.items,_that.count,_that.page,_that.pageSize);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<Listing> items,  int count,  int page,  int pageSize)?  $default,) {final _that = this;
switch (_that) {
case _PaginatedListings() when $default != null:
return $default(_that.items,_that.count,_that.page,_that.pageSize);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PaginatedListings implements PaginatedListings {
  const _PaginatedListings({required final  List<Listing> items, required this.count, required this.page, required this.pageSize}): _items = items;
  factory _PaginatedListings.fromJson(Map<String, dynamic> json) => _$PaginatedListingsFromJson(json);

 final  List<Listing> _items;
@override List<Listing> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override final  int count;
@override final  int page;
@override final  int pageSize;

/// Create a copy of PaginatedListings
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PaginatedListingsCopyWith<_PaginatedListings> get copyWith => __$PaginatedListingsCopyWithImpl<_PaginatedListings>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PaginatedListingsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PaginatedListings&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.count, count) || other.count == count)&&(identical(other.page, page) || other.page == page)&&(identical(other.pageSize, pageSize) || other.pageSize == pageSize));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_items),count,page,pageSize);

@override
String toString() {
  return 'PaginatedListings(items: $items, count: $count, page: $page, pageSize: $pageSize)';
}


}

/// @nodoc
abstract mixin class _$PaginatedListingsCopyWith<$Res> implements $PaginatedListingsCopyWith<$Res> {
  factory _$PaginatedListingsCopyWith(_PaginatedListings value, $Res Function(_PaginatedListings) _then) = __$PaginatedListingsCopyWithImpl;
@override @useResult
$Res call({
 List<Listing> items, int count, int page, int pageSize
});




}
/// @nodoc
class __$PaginatedListingsCopyWithImpl<$Res>
    implements _$PaginatedListingsCopyWith<$Res> {
  __$PaginatedListingsCopyWithImpl(this._self, this._then);

  final _PaginatedListings _self;
  final $Res Function(_PaginatedListings) _then;

/// Create a copy of PaginatedListings
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? items = null,Object? count = null,Object? page = null,Object? pageSize = null,}) {
  return _then(_PaginatedListings(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<Listing>,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,pageSize: null == pageSize ? _self.pageSize : pageSize // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
mixin _$ListingFilters {

 String? get city; String? get borough; String? get rentalType; String? get roomType; String? get veganHousehold; String? get furnished; bool? get seekingRoommate; int? get priceMin; int? get priceMax; int get page;
/// Create a copy of ListingFilters
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ListingFiltersCopyWith<ListingFilters> get copyWith => _$ListingFiltersCopyWithImpl<ListingFilters>(this as ListingFilters, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ListingFilters&&(identical(other.city, city) || other.city == city)&&(identical(other.borough, borough) || other.borough == borough)&&(identical(other.rentalType, rentalType) || other.rentalType == rentalType)&&(identical(other.roomType, roomType) || other.roomType == roomType)&&(identical(other.veganHousehold, veganHousehold) || other.veganHousehold == veganHousehold)&&(identical(other.furnished, furnished) || other.furnished == furnished)&&(identical(other.seekingRoommate, seekingRoommate) || other.seekingRoommate == seekingRoommate)&&(identical(other.priceMin, priceMin) || other.priceMin == priceMin)&&(identical(other.priceMax, priceMax) || other.priceMax == priceMax)&&(identical(other.page, page) || other.page == page));
}


@override
int get hashCode => Object.hash(runtimeType,city,borough,rentalType,roomType,veganHousehold,furnished,seekingRoommate,priceMin,priceMax,page);

@override
String toString() {
  return 'ListingFilters(city: $city, borough: $borough, rentalType: $rentalType, roomType: $roomType, veganHousehold: $veganHousehold, furnished: $furnished, seekingRoommate: $seekingRoommate, priceMin: $priceMin, priceMax: $priceMax, page: $page)';
}


}

/// @nodoc
abstract mixin class $ListingFiltersCopyWith<$Res>  {
  factory $ListingFiltersCopyWith(ListingFilters value, $Res Function(ListingFilters) _then) = _$ListingFiltersCopyWithImpl;
@useResult
$Res call({
 String? city, String? borough, String? rentalType, String? roomType, String? veganHousehold, String? furnished, bool? seekingRoommate, int? priceMin, int? priceMax, int page
});




}
/// @nodoc
class _$ListingFiltersCopyWithImpl<$Res>
    implements $ListingFiltersCopyWith<$Res> {
  _$ListingFiltersCopyWithImpl(this._self, this._then);

  final ListingFilters _self;
  final $Res Function(ListingFilters) _then;

/// Create a copy of ListingFilters
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? city = freezed,Object? borough = freezed,Object? rentalType = freezed,Object? roomType = freezed,Object? veganHousehold = freezed,Object? furnished = freezed,Object? seekingRoommate = freezed,Object? priceMin = freezed,Object? priceMax = freezed,Object? page = null,}) {
  return _then(_self.copyWith(
city: freezed == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String?,borough: freezed == borough ? _self.borough : borough // ignore: cast_nullable_to_non_nullable
as String?,rentalType: freezed == rentalType ? _self.rentalType : rentalType // ignore: cast_nullable_to_non_nullable
as String?,roomType: freezed == roomType ? _self.roomType : roomType // ignore: cast_nullable_to_non_nullable
as String?,veganHousehold: freezed == veganHousehold ? _self.veganHousehold : veganHousehold // ignore: cast_nullable_to_non_nullable
as String?,furnished: freezed == furnished ? _self.furnished : furnished // ignore: cast_nullable_to_non_nullable
as String?,seekingRoommate: freezed == seekingRoommate ? _self.seekingRoommate : seekingRoommate // ignore: cast_nullable_to_non_nullable
as bool?,priceMin: freezed == priceMin ? _self.priceMin : priceMin // ignore: cast_nullable_to_non_nullable
as int?,priceMax: freezed == priceMax ? _self.priceMax : priceMax // ignore: cast_nullable_to_non_nullable
as int?,page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [ListingFilters].
extension ListingFiltersPatterns on ListingFilters {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ListingFilters value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ListingFilters() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ListingFilters value)  $default,){
final _that = this;
switch (_that) {
case _ListingFilters():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ListingFilters value)?  $default,){
final _that = this;
switch (_that) {
case _ListingFilters() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? city,  String? borough,  String? rentalType,  String? roomType,  String? veganHousehold,  String? furnished,  bool? seekingRoommate,  int? priceMin,  int? priceMax,  int page)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ListingFilters() when $default != null:
return $default(_that.city,_that.borough,_that.rentalType,_that.roomType,_that.veganHousehold,_that.furnished,_that.seekingRoommate,_that.priceMin,_that.priceMax,_that.page);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? city,  String? borough,  String? rentalType,  String? roomType,  String? veganHousehold,  String? furnished,  bool? seekingRoommate,  int? priceMin,  int? priceMax,  int page)  $default,) {final _that = this;
switch (_that) {
case _ListingFilters():
return $default(_that.city,_that.borough,_that.rentalType,_that.roomType,_that.veganHousehold,_that.furnished,_that.seekingRoommate,_that.priceMin,_that.priceMax,_that.page);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? city,  String? borough,  String? rentalType,  String? roomType,  String? veganHousehold,  String? furnished,  bool? seekingRoommate,  int? priceMin,  int? priceMax,  int page)?  $default,) {final _that = this;
switch (_that) {
case _ListingFilters() when $default != null:
return $default(_that.city,_that.borough,_that.rentalType,_that.roomType,_that.veganHousehold,_that.furnished,_that.seekingRoommate,_that.priceMin,_that.priceMax,_that.page);case _:
  return null;

}
}

}

/// @nodoc


class _ListingFilters implements ListingFilters {
  const _ListingFilters({this.city, this.borough, this.rentalType, this.roomType, this.veganHousehold, this.furnished, this.seekingRoommate, this.priceMin, this.priceMax, this.page = 1});
  

@override final  String? city;
@override final  String? borough;
@override final  String? rentalType;
@override final  String? roomType;
@override final  String? veganHousehold;
@override final  String? furnished;
@override final  bool? seekingRoommate;
@override final  int? priceMin;
@override final  int? priceMax;
@override@JsonKey() final  int page;

/// Create a copy of ListingFilters
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ListingFiltersCopyWith<_ListingFilters> get copyWith => __$ListingFiltersCopyWithImpl<_ListingFilters>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ListingFilters&&(identical(other.city, city) || other.city == city)&&(identical(other.borough, borough) || other.borough == borough)&&(identical(other.rentalType, rentalType) || other.rentalType == rentalType)&&(identical(other.roomType, roomType) || other.roomType == roomType)&&(identical(other.veganHousehold, veganHousehold) || other.veganHousehold == veganHousehold)&&(identical(other.furnished, furnished) || other.furnished == furnished)&&(identical(other.seekingRoommate, seekingRoommate) || other.seekingRoommate == seekingRoommate)&&(identical(other.priceMin, priceMin) || other.priceMin == priceMin)&&(identical(other.priceMax, priceMax) || other.priceMax == priceMax)&&(identical(other.page, page) || other.page == page));
}


@override
int get hashCode => Object.hash(runtimeType,city,borough,rentalType,roomType,veganHousehold,furnished,seekingRoommate,priceMin,priceMax,page);

@override
String toString() {
  return 'ListingFilters(city: $city, borough: $borough, rentalType: $rentalType, roomType: $roomType, veganHousehold: $veganHousehold, furnished: $furnished, seekingRoommate: $seekingRoommate, priceMin: $priceMin, priceMax: $priceMax, page: $page)';
}


}

/// @nodoc
abstract mixin class _$ListingFiltersCopyWith<$Res> implements $ListingFiltersCopyWith<$Res> {
  factory _$ListingFiltersCopyWith(_ListingFilters value, $Res Function(_ListingFilters) _then) = __$ListingFiltersCopyWithImpl;
@override @useResult
$Res call({
 String? city, String? borough, String? rentalType, String? roomType, String? veganHousehold, String? furnished, bool? seekingRoommate, int? priceMin, int? priceMax, int page
});




}
/// @nodoc
class __$ListingFiltersCopyWithImpl<$Res>
    implements _$ListingFiltersCopyWith<$Res> {
  __$ListingFiltersCopyWithImpl(this._self, this._then);

  final _ListingFilters _self;
  final $Res Function(_ListingFilters) _then;

/// Create a copy of ListingFilters
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? city = freezed,Object? borough = freezed,Object? rentalType = freezed,Object? roomType = freezed,Object? veganHousehold = freezed,Object? furnished = freezed,Object? seekingRoommate = freezed,Object? priceMin = freezed,Object? priceMax = freezed,Object? page = null,}) {
  return _then(_ListingFilters(
city: freezed == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String?,borough: freezed == borough ? _self.borough : borough // ignore: cast_nullable_to_non_nullable
as String?,rentalType: freezed == rentalType ? _self.rentalType : rentalType // ignore: cast_nullable_to_non_nullable
as String?,roomType: freezed == roomType ? _self.roomType : roomType // ignore: cast_nullable_to_non_nullable
as String?,veganHousehold: freezed == veganHousehold ? _self.veganHousehold : veganHousehold // ignore: cast_nullable_to_non_nullable
as String?,furnished: freezed == furnished ? _self.furnished : furnished // ignore: cast_nullable_to_non_nullable
as String?,seekingRoommate: freezed == seekingRoommate ? _self.seekingRoommate : seekingRoommate // ignore: cast_nullable_to_non_nullable
as bool?,priceMin: freezed == priceMin ? _self.priceMin : priceMin // ignore: cast_nullable_to_non_nullable
as int?,priceMax: freezed == priceMax ? _self.priceMax : priceMax // ignore: cast_nullable_to_non_nullable
as int?,page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$DashboardOut {

 List<Listing> get drafts;@JsonKey(name: 'payment_submitted') List<Listing> get paymentSubmitted; List<Listing> get active; List<Listing> get expired; List<Listing> get deactivated;
/// Create a copy of DashboardOut
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DashboardOutCopyWith<DashboardOut> get copyWith => _$DashboardOutCopyWithImpl<DashboardOut>(this as DashboardOut, _$identity);

  /// Serializes this DashboardOut to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DashboardOut&&const DeepCollectionEquality().equals(other.drafts, drafts)&&const DeepCollectionEquality().equals(other.paymentSubmitted, paymentSubmitted)&&const DeepCollectionEquality().equals(other.active, active)&&const DeepCollectionEquality().equals(other.expired, expired)&&const DeepCollectionEquality().equals(other.deactivated, deactivated));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(drafts),const DeepCollectionEquality().hash(paymentSubmitted),const DeepCollectionEquality().hash(active),const DeepCollectionEquality().hash(expired),const DeepCollectionEquality().hash(deactivated));

@override
String toString() {
  return 'DashboardOut(drafts: $drafts, paymentSubmitted: $paymentSubmitted, active: $active, expired: $expired, deactivated: $deactivated)';
}


}

/// @nodoc
abstract mixin class $DashboardOutCopyWith<$Res>  {
  factory $DashboardOutCopyWith(DashboardOut value, $Res Function(DashboardOut) _then) = _$DashboardOutCopyWithImpl;
@useResult
$Res call({
 List<Listing> drafts,@JsonKey(name: 'payment_submitted') List<Listing> paymentSubmitted, List<Listing> active, List<Listing> expired, List<Listing> deactivated
});




}
/// @nodoc
class _$DashboardOutCopyWithImpl<$Res>
    implements $DashboardOutCopyWith<$Res> {
  _$DashboardOutCopyWithImpl(this._self, this._then);

  final DashboardOut _self;
  final $Res Function(DashboardOut) _then;

/// Create a copy of DashboardOut
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? drafts = null,Object? paymentSubmitted = null,Object? active = null,Object? expired = null,Object? deactivated = null,}) {
  return _then(_self.copyWith(
drafts: null == drafts ? _self.drafts : drafts // ignore: cast_nullable_to_non_nullable
as List<Listing>,paymentSubmitted: null == paymentSubmitted ? _self.paymentSubmitted : paymentSubmitted // ignore: cast_nullable_to_non_nullable
as List<Listing>,active: null == active ? _self.active : active // ignore: cast_nullable_to_non_nullable
as List<Listing>,expired: null == expired ? _self.expired : expired // ignore: cast_nullable_to_non_nullable
as List<Listing>,deactivated: null == deactivated ? _self.deactivated : deactivated // ignore: cast_nullable_to_non_nullable
as List<Listing>,
  ));
}

}


/// Adds pattern-matching-related methods to [DashboardOut].
extension DashboardOutPatterns on DashboardOut {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DashboardOut value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DashboardOut() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DashboardOut value)  $default,){
final _that = this;
switch (_that) {
case _DashboardOut():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DashboardOut value)?  $default,){
final _that = this;
switch (_that) {
case _DashboardOut() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<Listing> drafts, @JsonKey(name: 'payment_submitted')  List<Listing> paymentSubmitted,  List<Listing> active,  List<Listing> expired,  List<Listing> deactivated)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DashboardOut() when $default != null:
return $default(_that.drafts,_that.paymentSubmitted,_that.active,_that.expired,_that.deactivated);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<Listing> drafts, @JsonKey(name: 'payment_submitted')  List<Listing> paymentSubmitted,  List<Listing> active,  List<Listing> expired,  List<Listing> deactivated)  $default,) {final _that = this;
switch (_that) {
case _DashboardOut():
return $default(_that.drafts,_that.paymentSubmitted,_that.active,_that.expired,_that.deactivated);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<Listing> drafts, @JsonKey(name: 'payment_submitted')  List<Listing> paymentSubmitted,  List<Listing> active,  List<Listing> expired,  List<Listing> deactivated)?  $default,) {final _that = this;
switch (_that) {
case _DashboardOut() when $default != null:
return $default(_that.drafts,_that.paymentSubmitted,_that.active,_that.expired,_that.deactivated);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DashboardOut implements DashboardOut {
  const _DashboardOut({required final  List<Listing> drafts, @JsonKey(name: 'payment_submitted') required final  List<Listing> paymentSubmitted, required final  List<Listing> active, required final  List<Listing> expired, required final  List<Listing> deactivated}): _drafts = drafts,_paymentSubmitted = paymentSubmitted,_active = active,_expired = expired,_deactivated = deactivated;
  factory _DashboardOut.fromJson(Map<String, dynamic> json) => _$DashboardOutFromJson(json);

 final  List<Listing> _drafts;
@override List<Listing> get drafts {
  if (_drafts is EqualUnmodifiableListView) return _drafts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_drafts);
}

 final  List<Listing> _paymentSubmitted;
@override@JsonKey(name: 'payment_submitted') List<Listing> get paymentSubmitted {
  if (_paymentSubmitted is EqualUnmodifiableListView) return _paymentSubmitted;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_paymentSubmitted);
}

 final  List<Listing> _active;
@override List<Listing> get active {
  if (_active is EqualUnmodifiableListView) return _active;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_active);
}

 final  List<Listing> _expired;
@override List<Listing> get expired {
  if (_expired is EqualUnmodifiableListView) return _expired;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_expired);
}

 final  List<Listing> _deactivated;
@override List<Listing> get deactivated {
  if (_deactivated is EqualUnmodifiableListView) return _deactivated;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_deactivated);
}


/// Create a copy of DashboardOut
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DashboardOutCopyWith<_DashboardOut> get copyWith => __$DashboardOutCopyWithImpl<_DashboardOut>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DashboardOutToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DashboardOut&&const DeepCollectionEquality().equals(other._drafts, _drafts)&&const DeepCollectionEquality().equals(other._paymentSubmitted, _paymentSubmitted)&&const DeepCollectionEquality().equals(other._active, _active)&&const DeepCollectionEquality().equals(other._expired, _expired)&&const DeepCollectionEquality().equals(other._deactivated, _deactivated));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_drafts),const DeepCollectionEquality().hash(_paymentSubmitted),const DeepCollectionEquality().hash(_active),const DeepCollectionEquality().hash(_expired),const DeepCollectionEquality().hash(_deactivated));

@override
String toString() {
  return 'DashboardOut(drafts: $drafts, paymentSubmitted: $paymentSubmitted, active: $active, expired: $expired, deactivated: $deactivated)';
}


}

/// @nodoc
abstract mixin class _$DashboardOutCopyWith<$Res> implements $DashboardOutCopyWith<$Res> {
  factory _$DashboardOutCopyWith(_DashboardOut value, $Res Function(_DashboardOut) _then) = __$DashboardOutCopyWithImpl;
@override @useResult
$Res call({
 List<Listing> drafts,@JsonKey(name: 'payment_submitted') List<Listing> paymentSubmitted, List<Listing> active, List<Listing> expired, List<Listing> deactivated
});




}
/// @nodoc
class __$DashboardOutCopyWithImpl<$Res>
    implements _$DashboardOutCopyWith<$Res> {
  __$DashboardOutCopyWithImpl(this._self, this._then);

  final _DashboardOut _self;
  final $Res Function(_DashboardOut) _then;

/// Create a copy of DashboardOut
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? drafts = null,Object? paymentSubmitted = null,Object? active = null,Object? expired = null,Object? deactivated = null,}) {
  return _then(_DashboardOut(
drafts: null == drafts ? _self._drafts : drafts // ignore: cast_nullable_to_non_nullable
as List<Listing>,paymentSubmitted: null == paymentSubmitted ? _self._paymentSubmitted : paymentSubmitted // ignore: cast_nullable_to_non_nullable
as List<Listing>,active: null == active ? _self._active : active // ignore: cast_nullable_to_non_nullable
as List<Listing>,expired: null == expired ? _self._expired : expired // ignore: cast_nullable_to_non_nullable
as List<Listing>,deactivated: null == deactivated ? _self._deactivated : deactivated // ignore: cast_nullable_to_non_nullable
as List<Listing>,
  ));
}


}

// dart format on
