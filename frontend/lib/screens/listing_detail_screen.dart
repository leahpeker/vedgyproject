import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/listing.dart';
import '../providers/auth_provider.dart';
import '../providers/listings_provider.dart';
import '../widgets/photo_gallery.dart';

class ListingDetailScreen extends ConsumerWidget {
  const ListingDetailScreen({required this.id, super.key});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listingAsync = ref.watch(listingDetailProvider(id));

    return listingAsync.when(
      loading: () => const Scaffold(body: _SkeletonDetail()),
      error: (err, _) => _ErrorBody(err: err, onRetry: () => ref.invalidate(listingDetailProvider(id))),
      data: (listing) => _DetailBody(listing: listing),
    );
  }
}

// ---------------------------------------------------------------------------
// Error / not-available body
// ---------------------------------------------------------------------------

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.err, required this.onRetry});

  final Object err;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final isNotFound = err.toString().contains('404') ||
        err.toString().contains('not found') ||
        err.toString().contains('403');

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isNotFound ? Icons.search_off : Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                isNotFound ? 'Listing not available' : 'Failed to load listing',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                isNotFound
                    ? 'This listing may have expired or been removed.'
                    : 'Something went wrong. Please try again.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                children: [
                  OutlinedButton(
                    onPressed: () => context.go('/browse'),
                    child: const Text('Browse listings'),
                  ),
                  if (!isNotFound)
                    FilledButton(
                      onPressed: onRetry,
                      child: const Text('Try again'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Full detail body
// ---------------------------------------------------------------------------

class _DetailBody extends ConsumerWidget {
  const _DetailBody({required this.listing});

  final Listing listing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final isAuthenticated = authState.whenOrNull(authenticated: (user, token) => true) ?? false;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back link
                  TextButton.icon(
                    onPressed: () => context.go('/browse'),
                    icon: const Icon(Icons.arrow_back, size: 18),
                    label: const Text('Back to listings'),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Responsive two-column layout on wide screens
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 800;
                      if (isWide) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 2,
                              child: _MainColumn(listing: listing, isAuthenticated: isAuthenticated),
                            ),
                            const SizedBox(width: 24),
                            SizedBox(
                              width: 300,
                              child: _SidebarColumn(listing: listing, isAuthenticated: isAuthenticated),
                            ),
                          ],
                        );
                      }
                      return Column(
                        children: [
                          _MainColumn(listing: listing, isAuthenticated: isAuthenticated),
                          const SizedBox(height: 16),
                          _SidebarColumn(listing: listing, isAuthenticated: isAuthenticated),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Main column: photos, title, description, about lister, requirements, policy
// ---------------------------------------------------------------------------

class _MainColumn extends StatelessWidget {
  const _MainColumn({required this.listing, required this.isAuthenticated});

  final Listing listing;
  final bool isAuthenticated;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title + price
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                listing.title,
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            if (listing.price != null) ...[
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${listing.price}/mo',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text('Monthly rent', style: theme.textTheme.bodySmall),
                ],
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),

        // Location
        Row(
          children: [
            Icon(Icons.location_on_outlined, size: 16, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 4),
            Text(
              _locationText(),
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Status tags
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            _Chip(listing.rentalType, color: Colors.blue),
            _Chip(listing.roomType, color: Colors.purple),
            _Chip(listing.veganHousehold, color: Colors.teal),
            _Chip(listing.furnished),
            if (listing.seekingRoommate) _Chip('Seeking roommate', color: Colors.green),
          ],
        ),
        const SizedBox(height: 20),

        // Photos
        PhotoGallery(photos: listing.photos),
        const SizedBox(height: 20),

        // Description
        _Section(
          title: 'Description',
          child: Text(listing.description, style: theme.textTheme.bodyMedium),
        ),

        // About the lister
        if (listing.aboutLister != null && listing.aboutLister!.isNotEmpty)
          _Section(
            title: 'About the lister',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(listing.aboutLister!, style: theme.textTheme.bodyMedium),
                const SizedBox(height: 8),
                Text(
                  'Relationship to space: ${listing.listerRelationship}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

        // Requirements
        if (listing.rentalRequirements != null && listing.rentalRequirements!.isNotEmpty)
          _Section(
            title: 'Requirements & preferences',
            child: Text(listing.rentalRequirements!, style: theme.textTheme.bodyMedium),
          ),

        // Pet policy
        if (listing.petPolicy != null && listing.petPolicy!.isNotEmpty)
          _Section(
            title: 'Pet policy',
            child: Text(listing.petPolicy!, style: theme.textTheme.bodyMedium),
          ),
      ],
    );
  }

  String _locationText() {
    final parts = <String>[listing.city];
    if (listing.borough != null) parts.add(listing.borough!);
    if (listing.neighborhood != null) parts.add(listing.neighborhood!);
    return parts.join(', ');
  }
}

String _fmtDate(DateTime dt) {
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
}

// ---------------------------------------------------------------------------
// Sidebar: details, posted by, contact
// ---------------------------------------------------------------------------

class _SidebarColumn extends StatelessWidget {
  const _SidebarColumn({required this.listing, required this.isAuthenticated});

  final Listing listing;
  final bool isAuthenticated;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        // Details card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Details', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _DetailRow('Rental type', listing.rentalType),
                _DetailRow('Room type', listing.roomType),
                _DetailRow('Furnished', listing.furnished),
                _DetailRow('Vegan household', listing.veganHousehold),
                _DetailRow('Seeking roommate', listing.seekingRoommate ? 'Yes' : 'No'),
                if (listing.startDate != null)
                  _DetailRow('Available from', _fmtDate(listing.startDate!)),
                if (listing.endDate != null)
                  _DetailRow('Available until', _fmtDate(listing.endDate!)),
                _DetailRow('Posted', _fmtDate(listing.createdAt)),
                if (listing.expiresAt != null)
                  _DetailRow('Expires', _fmtDate(listing.expiresAt!)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Posted by
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Posted by', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Text(
                        listing.user.firstName.isNotEmpty
                            ? listing.user.firstName[0].toUpperCase()
                            : '?',
                        style: TextStyle(color: theme.colorScheme.onPrimaryContainer),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${listing.user.firstName} ${listing.user.lastName[0]}.',
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Contact section
        if (isAuthenticated)
          Card(
            color: theme.colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Contact ${listing.user.firstName}',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Send a message to enquire about this listing.',
                    style: theme.textTheme.bodySmall,
                  ),
                  if (listing.includePhone && listing.phoneNumber != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.phone_outlined, size: 16, color: theme.colorScheme.primary),
                        const SizedBox(width: 6),
                        Text(listing.phoneNumber!, style: theme.textTheme.bodyMedium),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          )
        else
          Card(
            color: theme.colorScheme.secondaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Contact listing owner',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text('Sign in to contact listing owners.'),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => context.go('/login?redirect=/listing/${listing.id}'),
                      child: const Text('Sign in to contact'),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Small shared widgets
// ---------------------------------------------------------------------------

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              child,
            ],
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
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          )),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.label, {this.color});

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final base = color ?? Theme.of(context).colorScheme.secondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: base.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: base.withValues(alpha: 0.9)),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Skeleton loading state
// ---------------------------------------------------------------------------

class _SkeletonDetail extends StatelessWidget {
  const _SkeletonDetail();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;

    Widget box({double? w, double h = 16, double? radius}) => Container(
          width: w ?? double.infinity,
          height: h,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(radius ?? 4),
          ),
        );

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 800;
                final content = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Back link placeholder
                    box(w: 120, h: 14),
                    const SizedBox(height: 20),
                    // Title
                    box(h: 28),
                    const SizedBox(height: 10),
                    box(w: 180, h: 28),
                    const SizedBox(height: 12),
                    // Location
                    box(w: 140, h: 14),
                    const SizedBox(height: 16),
                    // Chips row
                    Row(children: [
                      box(w: 80, h: 24, radius: 12),
                      const SizedBox(width: 8),
                      box(w: 80, h: 24, radius: 12),
                      const SizedBox(width: 8),
                      box(w: 100, h: 24, radius: 12),
                    ]),
                    const SizedBox(height: 20),
                    // Photo area
                    box(h: 260, radius: 8),
                    const SizedBox(height: 20),
                    // Description card
                    box(h: 100, radius: 8),
                    const SizedBox(height: 16),
                    // Details card
                    box(h: 120, radius: 8),
                  ],
                );

                if (isWide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 2, child: content),
                      const SizedBox(width: 24),
                      SizedBox(
                        width: 300,
                        child: Column(
                          children: [
                            box(h: 180, radius: 8),
                            const SizedBox(height: 16),
                            box(h: 80, radius: 8),
                            const SizedBox(height: 16),
                            box(h: 100, radius: 8),
                          ],
                        ),
                      ),
                    ],
                  );
                }
                return content;
              },
            ),
          ),
        ),
      ],
    );
  }
}
