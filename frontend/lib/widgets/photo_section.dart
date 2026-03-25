import 'package:flutter/material.dart';

import '../models/listing.dart';
import 'vedgy_image.dart';

/// Photo grid with upload button, used in the listing form.
class PhotoSection extends StatelessWidget {
  const PhotoSection({
    required this.photos,
    required this.uploading,
    required this.onAdd,
    required this.onDelete,
    super.key,
  });

  final List<ListingPhoto> photos;
  final bool uploading;
  final VoidCallback onAdd;
  final void Function(ListingPhoto) onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (photos.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: photos
                .map((p) => _PhotoThumb(photo: p, onDelete: onDelete))
                .toList(),
          ),
          const SizedBox(height: 12),
        ],
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: uploading || photos.length >= 10 ? null : onAdd,
              icon: uploading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add_photo_alternate_outlined),
              label: Text(uploading ? 'Uploading...' : 'Add photos'),
            ),
            const SizedBox(width: 12),
            Text(
              '${photos.length}/10 photos',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PhotoThumb extends StatelessWidget {
  const _PhotoThumb({required this.photo, required this.onDelete});

  final ListingPhoto photo;
  final void Function(ListingPhoto) onDelete;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: VedgyImage(url: photo.url, width: 80, height: 80),
        ),
        Positioned(
          top: -14,
          right: -14,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onDelete(photo),
            child: SizedBox(
              width: 48,
              height: 48,
              child: Center(
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.error,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, size: 13, color: Colors.white),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
