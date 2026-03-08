import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/listing.dart';
import '../providers/dashboard_provider.dart';
import '../providers/listings_provider.dart';
import '../services/api_client.dart';

part 'listing_actions_provider.g.dart';

// ---------------------------------------------------------------------------
// Wraps all mutating listing API calls and handles cache invalidation.
// ---------------------------------------------------------------------------

@Riverpod(keepAlive: true)
ListingActions listingActions(Ref ref) => ListingActions(ref);

class ListingActions {
  ListingActions(this._ref);

  final Ref _ref;

  /// Create a new draft listing. Returns the created [Listing].
  Future<Listing> createListing(Map<String, dynamic> fields) async {
    final dio = _ref.read(apiClientProvider);
    final response = await dio.post<Map<String, dynamic>>(
      '/api/listings/',
      data: fields,
    );
    _ref.invalidate(dashboardProvider);
    return Listing.fromJson(response.data!);
  }

  /// Partially update a listing. Returns the updated [Listing].
  Future<Listing> updateListing(String listingId, Map<String, dynamic> fields) async {
    final dio = _ref.read(apiClientProvider);
    final response = await dio.patch<Map<String, dynamic>>(
      '/api/listings/$listingId/',
      data: fields,
    );
    _ref.invalidate(listingDetailProvider(listingId));
    _ref.invalidate(dashboardProvider);
    return Listing.fromJson(response.data!);
  }

  /// Delete a listing and all its photos.
  Future<void> deleteListing(String listingId) async {
    final dio = _ref.read(apiClientProvider);
    await dio.delete<void>('/api/listings/$listingId/');
    _ref.invalidate(dashboardProvider);
    _ref.invalidate(browseListingsProvider);
  }

  /// Deactivate an active listing.
  Future<Listing> deactivateListing(String listingId) async {
    final dio = _ref.read(apiClientProvider);
    final response = await dio.post<Map<String, dynamic>>(
      '/api/listings/$listingId/deactivate/',
    );
    _ref.invalidate(listingDetailProvider(listingId));
    _ref.invalidate(dashboardProvider);
    _ref.invalidate(browseListingsProvider);
    return Listing.fromJson(response.data!);
  }

  /// Submit a draft listing for review (sets payment_submitted status).
  Future<Listing> submitForReview(String listingId) async {
    final dio = _ref.read(apiClientProvider);
    final response = await dio.post<Map<String, dynamic>>(
      '/api/listings/$listingId/submit/',
    );
    _ref.invalidate(listingDetailProvider(listingId));
    _ref.invalidate(dashboardProvider);
    return Listing.fromJson(response.data!);
  }
}
