import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Terms of Service',
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Last updated: January 1, 2025',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 32),
                  const _Section(
                    title: '1. Acceptance of Terms',
                    body: 'By accessing and using Vedgy, you accept and agree to be bound by '
                        'the terms and provisions of this agreement.',
                  ),
                  const _Section(
                    title: '2. Description of Service',
                    body: 'Vedgy is a platform that connects vegan-friendly renters and property owners. '
                        'We facilitate housing listings with a focus on vegan and plant-based living arrangements.',
                  ),
                  const _Section(
                    title: '3. User Responsibilities',
                    body: '• Provide accurate and truthful information in listings\n'
                        '• Comply with all applicable local, state, and federal laws\n'
                        '• Respect the rights and property of others\n'
                        '• Use the service only for lawful purposes',
                  ),
                  const _Section(
                    title: '4. Listing Payments',
                    body: 'Listings require payment to become active. Payments are processed securely '
                        'through Paddle. Listings expire after 30 days and can be renewed. '
                        'Payments are non-refundable except as required by law.',
                  ),
                  const _Section(
                    title: '5. Prohibited Content',
                    body: 'Users may not post content that is illegal, discriminatory, harassing, '
                        'or violates the rights of others. We reserve the right to remove any '
                        'content that violates these terms.',
                  ),
                  const _Section(
                    title: '6. Privacy',
                    body: 'Your privacy is important to us. Please review our Privacy Policy to '
                        'understand how we collect, use, and protect your information.',
                  ),
                  const _Section(
                    title: '7. Disclaimer of Warranties',
                    body: 'Vedgy is provided "as is" without warranties of any kind. We do not '
                        'guarantee the accuracy of listings or the conduct of users.',
                  ),
                  const _Section(
                    title: '8. Limitation of Liability',
                    body: 'We shall not be liable for any direct, indirect, incidental, special, '
                        'or consequential damages resulting from your use of the service.',
                  ),
                  const _Section(
                    title: '9. Changes to Terms',
                    body: 'We reserve the right to modify these terms at any time. '
                        'Users will be notified of significant changes.',
                  ),
                  const _Section(
                    title: '10. Contact Information',
                    body: 'For questions about these Terms of Service, please contact us via '
                        'the contact page.',
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () => context.go('/'),
                    child: const Text('Back to home'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(body, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
