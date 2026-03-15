import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/listing.dart';
import '../providers/dashboard_provider.dart';
import '../providers/listing_actions_provider.dart';
import '../providers/notification_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(dashboardProvider);

    return Scaffold(
      body: async.when(
        loading: () => const _SkeletonDashboard(),
        error: (e, _) {
          String errorMessage = 'Something went wrong. Please try again.';
          if (e is DioException) {
            if (e.type == DioExceptionType.connectionTimeout ||
                e.type == DioExceptionType.receiveTimeout ||
                e.type == DioExceptionType.sendTimeout ||
                e.type == DioExceptionType.connectionError) {
              errorMessage =
                  'Unable to connect. Check your connection and try again.';
            } else if (e.response?.statusCode == 404) {
              errorMessage = 'Dashboard not found';
            } else if (e.response?.statusCode == 403) {
              errorMessage =
                  'You don\'t have permission to view your dashboard';
            }
          }
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    errorMessage,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => ref.invalidate(dashboardProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        },
        data: (dashboard) => SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'My Listings',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: () => context.go('/create'),
                    icon: const Icon(Icons.add),
                    label: const Text('Post a listing'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _Section(
                title: 'Active',
                icon: Icons.check_circle_outline,
                color: Colors.green,
                listings: dashboard.active,
                emptyText: 'No active listings.',
                actions: (listing) => [
                  _ActionButton(
                    label: 'View',
                    icon: Icons.open_in_new,
                    onPressed: () => context.go('/listing/${listing.id}'),
                  ),
                  _ActionButton(
                    label: 'Deactivate',
                    icon: Icons.pause_circle_outline,
                    destructive: true,
                    onPressed: () => _confirmDeactivate(context, ref, listing),
                  ),
                ],
              ),
              _Section(
                title: 'Drafts',
                icon: Icons.edit_outlined,
                color: Colors.grey,
                listings: dashboard.drafts,
                emptyText: 'No drafts.',
                actions: (listing) => [
                  _ActionButton(
                    label: 'Edit',
                    icon: Icons.edit,
                    onPressed: () => context.go('/edit/${listing.id}'),
                  ),
                  _ActionButton(
                    label: 'Delete',
                    icon: Icons.delete_outline,
                    destructive: true,
                    onPressed: () => _confirmDelete(context, ref, listing),
                  ),
                ],
              ),
              _Section(
                title: 'Under Review',
                icon: Icons.hourglass_empty,
                color: Colors.orange,
                listings: dashboard.paymentSubmitted,
                emptyText: 'No listings pending review.',
                actions: (listing) => [
                  _ActionButton(
                    label: 'View',
                    icon: Icons.open_in_new,
                    onPressed: () => context.go('/listing/${listing.id}'),
                  ),
                ],
              ),
              _Section(
                title: 'Expired',
                icon: Icons.schedule,
                color: Colors.red,
                listings: dashboard.expired,
                emptyText: 'No expired listings.',
                actions: (listing) => [
                  _ActionButton(
                    label: 'Edit & Resubmit',
                    icon: Icons.refresh,
                    onPressed: () => context.go('/edit/${listing.id}'),
                  ),
                ],
              ),
              _Section(
                title: 'Deactivated',
                icon: Icons.block,
                color: Colors.grey,
                listings: dashboard.deactivated,
                emptyText: 'No deactivated listings.',
                actions: (listing) => [
                  _ActionButton(
                    label: 'Edit',
                    icon: Icons.edit,
                    onPressed: () => context.go('/edit/${listing.id}'),
                  ),
                  _ActionButton(
                    label: 'Delete',
                    icon: Icons.delete_outline,
                    destructive: true,
                    onPressed: () => _confirmDelete(context, ref, listing),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDeactivate(
    BuildContext context,
    WidgetRef ref,
    Listing listing,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Deactivate listing?'),
        content: Text(
          'This will hide "${listing.title}" from the browse page. You can edit and resubmit later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      try {
        await ref.read(listingActionsProvider).deactivateListing(listing.id);
        ref
            .read(notificationQueueProvider.notifier)
            .show('Listing deactivated.');
      } catch (e) {
        ref
            .read(notificationQueueProvider.notifier)
            .showError('Failed to deactivate: $e');
      }
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Listing listing,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete listing?'),
        content: Text(
          '"${listing.title}" and all its photos will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      try {
        await ref.read(listingActionsProvider).deleteListing(listing.id);
        ref.read(notificationQueueProvider.notifier).show('Listing deleted.');
      } catch (e) {
        ref
            .read(notificationQueueProvider.notifier)
            .showError('Failed to delete: $e');
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Section widget
// ---------------------------------------------------------------------------

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.icon,
    required this.color,
    required this.listings,
    required this.emptyText,
    required this.actions,
  });

  final String title;
  final IconData icon;
  final Color color;
  final List<Listing> listings;
  final String emptyText;
  final List<_ActionButton> Function(Listing) actions;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Text(
              '$title (${listings.length})',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (listings.isEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 24, bottom: 24),
            child: Text(
              emptyText,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          )
        else
          ...listings.map((l) => _ListingRow(listing: l, actions: actions(l))),
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 16),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Row for a single listing
// ---------------------------------------------------------------------------

class _ListingRow extends StatelessWidget {
  const _ListingRow({required this.listing, required this.actions});

  final Listing listing;
  final List<_ActionButton> actions;

  @override
  Widget build(BuildContext context) {
    final price = listing.price != null ? '\$${listing.price}/mo' : 'Price TBD';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listing.title.isEmpty ? '(Untitled draft)' : listing.title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      if (listing.city.isNotEmpty) listing.city,
                      price,
                    ].join(' · '),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Wrap(spacing: 4, children: actions),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Small icon+label action button
// ---------------------------------------------------------------------------

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.destructive = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.primary;

    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16, color: color),
      label: Text(label, style: TextStyle(color: color, fontSize: 12)),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Skeleton loading state
// ---------------------------------------------------------------------------

class _SkeletonDashboard extends StatelessWidget {
  const _SkeletonDashboard();

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

    Widget skeletonRow() => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    box(w: 200, h: 14),
                    const SizedBox(height: 6),
                    box(w: 120, h: 12),
                  ],
                ),
              ),
              box(w: 60, h: 12),
            ],
          ),
        ),
      ),
    );

    Widget skeletonSection() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        box(w: 120, h: 16),
        const SizedBox(height: 10),
        skeletonRow(),
        skeletonRow(),
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 16),
      ],
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              box(w: 160, h: 24),
              const Spacer(),
              box(w: 140, h: 36, radius: 20),
            ],
          ),
          const SizedBox(height: 24),
          skeletonSection(),
          skeletonSection(),
          skeletonSection(),
        ],
      ),
    );
  }
}
