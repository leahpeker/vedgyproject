import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/listing.dart';
import '../providers/listings_provider.dart';
import '../services/api_client.dart';

part 'photo_provider.g.dart';

// ---------------------------------------------------------------------------
// Photo operations — upload and delete, with cache invalidation
// ---------------------------------------------------------------------------

@Riverpod(keepAlive: true)
PhotoActions photoActions(Ref ref) => PhotoActions(ref);

class PhotoActions {
  PhotoActions(this._ref);

  final Ref _ref;

  Dio get _dio => _ref.read(apiClientProvider);

  /// Upload one or more images for a listing.
  /// Returns the list of newly created [ListingPhoto]s.
  /// [onProgress] is called with (bytesUploaded, totalBytes) per file.
  Future<List<ListingPhoto>> uploadPhotos(
    String listingId,
    List<XFile> files, {
    void Function(int sent, int total)? onProgress,
  }) async {
    final results = <ListingPhoto>[];

    for (final file in files) {
      final bytes = await file.readAsBytes();
      final formData = FormData.fromMap({
        'photo': MultipartFile.fromBytes(
          bytes,
          filename: file.name,
        ),
      });

      final response = await _dio.post<Map<String, dynamic>>(
        '/api/listings/$listingId/photos/',
        data: formData,
        onSendProgress: onProgress,
      );
      results.add(ListingPhoto.fromJson(response.data!));
    }

    // Invalidate the detail cache so the listing refreshes with new photos.
    _ref.invalidate(listingDetailProvider(listingId));

    return results;
  }

  /// Delete a single photo by ID.
  Future<void> deletePhoto(String listingId, String photoId) async {
    await _dio.delete<void>('/api/listings/photos/$photoId/');
    _ref.invalidate(listingDetailProvider(listingId));
  }
}
