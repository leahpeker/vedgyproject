import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/listing_actions_provider.dart';
import '../providers/listings_provider.dart';

class PayScreen extends ConsumerStatefulWidget {
  const PayScreen({super.key, required this.id});

  final String id;

  @override
  ConsumerState<PayScreen> createState() => _PayScreenState();
}

class _PayScreenState extends ConsumerState<PayScreen> {
  bool _submitting = false;

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      await ref.read(listingActionsProvider).submitForReview(widget.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Listing submitted! We\'ll review it shortly.'),
            backgroundColor: Colors.green,
          ),
        );
        context.go('/dashboard');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Submission failed: $e')),
        );
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final listingAsync = ref.watch(listingDetailProvider(widget.id));

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Submit Your Listing',
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                listingAsync.whenData((l) => Text(
                      l.title,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant),
                    )).value ?? const SizedBox.shrink(),
                const SizedBox(height: 32),

                // Why we charge card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('About listing fees',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        const _BulletPoint(
                          icon: Icons.shield_outlined,
                          text:
                              'A small fee helps prevent scam and spam listings, keeping the platform trustworthy.',
                        ),
                        const _BulletPoint(
                          icon: Icons.eco_outlined,
                          text:
                              'Your contribution supports the mission of connecting the vegan community.',
                        ),
                        const _BulletPoint(
                          icon: Icons.build_outlined,
                          text:
                              'Funds cover server costs and new features — no ads, ever.',
                        ),
                        const _BulletPoint(
                          icon: Icons.schedule_outlined,
                          text:
                              'Listings are active for 30 days and can be renewed.',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Payment placeholder
                Card(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Payment',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        Text(
                          'Sliding scale — pay what works for your budget. Payment integration coming soon.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                Row(
                  children: [
                    FilledButton(
                      onPressed: _submitting ? null : _submit,
                      child: _submitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Submit for Review'),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: () => context.go('/preview/${widget.id}'),
                      child: const Text('Back to preview'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BulletPoint extends StatelessWidget {
  const _BulletPoint({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18,
              color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
