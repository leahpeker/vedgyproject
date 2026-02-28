import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/listings_provider.dart';
import '../widgets/photo_gallery.dart';

class PreviewScreen extends ConsumerWidget {
  const PreviewScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(listingDetailProvider(id));

    return Scaffold(
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load preview: $e')),
        data: (listing) => SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .secondaryContainer
                          .withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: Theme.of(context)
                              .colorScheme
                              .secondaryContainer),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.visibility_outlined,
                            color: Theme.of(context)
                                .colorScheme
                                .onSecondaryContainer),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'This is a preview. Your listing will look like this when active.',
                            style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSecondaryContainer),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Title & price
                  Text(
                    listing.title,
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (listing.price != null)
                    Text(
                      '\$${listing.price}/month',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(
                              color: Theme.of(context).colorScheme.primary),
                    ),
                  const SizedBox(height: 12),

                  // Location chips
                  Wrap(
                    spacing: 8,
                    children: [
                      if (listing.city.isNotEmpty) Chip(label: Text(listing.city)),
                      if (listing.borough != null)
                        Chip(label: Text(listing.borough!)),
                      if (listing.neighborhood != null)
                        Chip(label: Text(listing.neighborhood!)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Photos
                  if (listing.photos.isNotEmpty) ...[
                    SizedBox(
                      height: 320,
                      child: PhotoGallery(photos: listing.photos),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Description
                  Text('Description',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(listing.description),
                  const SizedBox(height: 24),

                  // Details
                  Text('Listing Details',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const Divider(),
                  const SizedBox(height: 8),
                  _DetailRow('Rental type', listing.rentalType),
                  _DetailRow('Room type', listing.roomType),
                  _DetailRow('Vegan household', listing.veganHousehold),
                  _DetailRow('Furnished', listing.furnished),
                  if (listing.seekingRoommate)
                    const _DetailRow('Seeking', 'Roommate'),
                  const SizedBox(height: 24),

                  // Actions
                  Row(
                    children: [
                      FilledButton(
                        onPressed: () => context.go('/pay/$id'),
                        child: const Text('Submit for Review'),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton(
                        onPressed: () => context.go('/edit/$id'),
                        child: const Text('Edit listing'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 160,
            child: Text(label,
                style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
