import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/listing.dart';
import '../providers/listings_provider.dart';
import '../widgets/filter_panel.dart';
import '../widgets/listing_card.dart';

class BrowseScreen extends ConsumerWidget {
  const BrowseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listingsAsync = ref.watch(browseListingsProvider);
    final filters = ref.watch(browseFiltersProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Browse listings',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const FilterPanel(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          listingsAsync.when(
            loading: () => const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: _SkeletonGrid(),
              ),
            ),
            error: (err, _) => SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 12),
                      Text('Failed to load listings',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => ref.invalidate(browseListingsProvider),
                        child: const Text('Try again'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            data: (paginated) => paginated.items.isEmpty
                ? SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(48),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.search_off,
                                size: 64,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant
                                    .withValues(alpha: 0.4)),
                            const SizedBox(height: 16),
                            Text(
                              'No listings found',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            const Text('Try adjusting your filters'),
                          ],
                        ),
                      ),
                    ),
                  )
                : _ListingGrid(
                    listings: paginated.items,
                    hasMore: paginated.items.length < paginated.count,
                    currentPage: filters.page,
                    onLoadMore: () {
                      final current = ref.read(browseFiltersProvider);
                      ref.read(browseFiltersProvider.notifier).update(
                            current.copyWith(page: current.page + 1),
                          );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Responsive grid of listing cards
// ---------------------------------------------------------------------------

class _ListingGrid extends StatelessWidget {
  const _ListingGrid({
    required this.listings,
    required this.hasMore,
    required this.currentPage,
    required this.onLoadMore,
  });

  final List<Listing> listings;
  final bool hasMore;
  final int currentPage;
  final VoidCallback onLoadMore;

  int _columnCount(double width) {
    if (width >= 1024) return 3;
    if (width >= 600) return 2;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final cols = _columnCount(width);

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cols,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.75,
            ),
            itemCount: listings.length,
            itemBuilder: (context, index) => ListingCard(listing: listings[index]),
          ),
          if (hasMore) ...[
            const SizedBox(height: 24),
            Center(
              child: OutlinedButton(
                onPressed: onLoadMore,
                child: const Text('Load more'),
              ),
            ),
          ],
          const SizedBox(height: 24),
        ]),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Skeleton loading cards
// ---------------------------------------------------------------------------

class _SkeletonGrid extends StatelessWidget {
  const _SkeletonGrid();

  int _columnCount(double width) {
    if (width >= 1024) return 3;
    if (width >= 600) return 2;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final cols = _columnCount(width);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: 6,
      itemBuilder: (context, index) => const _SkeletonCard(),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 160, color: color),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 16, width: double.infinity, color: color),
                const SizedBox(height: 8),
                Container(height: 14, width: 80, color: color),
                const SizedBox(height: 8),
                Container(height: 12, width: double.infinity, color: color),
                const SizedBox(height: 4),
                Container(height: 12, width: 200, color: color),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
