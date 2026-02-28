import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/listing.dart';
import '../services/api_client.dart';

part 'listings_provider.g.dart';

// ---------------------------------------------------------------------------
// Browse provider — holds filter state and fetches paginated listings
// ---------------------------------------------------------------------------

@riverpod
class BrowseFilters extends _$BrowseFilters {
  @override
  ListingFilters build() => const ListingFilters();

  void update(ListingFilters filters) => state = filters;

  void reset() => state = const ListingFilters();
}

@riverpod
Future<PaginatedListings> browseListings(Ref ref) async {
  final filters = ref.watch(browseFiltersProvider);
  final dio = ref.watch(apiClientProvider);

  final queryParams = <String, dynamic>{
    'page': filters.page,
  };
  if (filters.city != null) queryParams['city'] = filters.city;
  if (filters.borough != null) queryParams['borough'] = filters.borough;
  if (filters.rentalType != null) queryParams['rental_type'] = filters.rentalType;
  if (filters.roomType != null) queryParams['room_type'] = filters.roomType;
  if (filters.veganHousehold != null) queryParams['vegan_household'] = filters.veganHousehold;
  if (filters.furnished != null) queryParams['furnished'] = filters.furnished;
  if (filters.seekingRoommate != null) queryParams['seeking_roommate'] = filters.seekingRoommate;
  if (filters.priceMin != null) queryParams['price_min'] = filters.priceMin;
  if (filters.priceMax != null) queryParams['price_max'] = filters.priceMax;

  final response = await dio.get<Map<String, dynamic>>(
    '/api/listings/',
    queryParameters: queryParams,
  );
  return PaginatedListings.fromJson(response.data!);
}

// ---------------------------------------------------------------------------
// Detail provider — keyed by listing ID
// ---------------------------------------------------------------------------

@riverpod
Future<Listing> listingDetail(Ref ref, String id) async {
  final dio = ref.watch(apiClientProvider);
  final response = await dio.get<Map<String, dynamic>>('/api/listings/$id/');
  return Listing.fromJson(response.data!);
}
