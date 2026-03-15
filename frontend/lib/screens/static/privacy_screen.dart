import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

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
                    'Privacy Policy',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
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
                    title: '1. Information We Collect',
                    body:
                        'We collect information you provide directly to us, such as:\n'
                        '• Account information (name, email, phone number)\n'
                        '• Listing information (property details, descriptions, photos)\n'
                        '• Payment information (processed securely by Paddle)\n'
                        '• Communications with us',
                  ),
                  const _Section(
                    title: '2. How We Use Your Information',
                    body:
                        'We use the information we collect to:\n'
                        '• Provide and maintain our service\n'
                        '• Process payments and transactions\n'
                        '• Communicate with you about your account and listings\n'
                        '• Improve our platform and user experience\n'
                        '• Comply with legal obligations',
                  ),
                  const _Section(
                    title: '3. Information Sharing',
                    body:
                        'We do not sell or rent your personal information. We may share information:\n'
                        '• In listing displays (as you choose to make public)\n'
                        '• With payment processors (Paddle) for transaction processing\n'
                        '• When required by law or to protect our rights\n'
                        '• With your consent',
                  ),
                  const _Section(
                    title: '4. Data Security',
                    body:
                        'We implement appropriate security measures to protect your personal information '
                        'against unauthorized access, alteration, disclosure, or destruction.',
                  ),
                  const _Section(
                    title: '5. Cookies',
                    body:
                        'We use only strictly necessary cookies:\n'
                        '• Session cookies: Required for login (expire when you close your browser or after 7 days)\n'
                        '• CSRF protection cookies: Security cookies that protect your account\n\n'
                        'We do not use analytics, advertising, or third-party tracking cookies.',
                  ),
                  const _Section(
                    title: '6. Your Rights',
                    body:
                        'You have the right to:\n'
                        '• Access and update your personal information\n'
                        '• Delete your account and associated data\n'
                        '• Opt out of marketing communications\n'
                        '• Request a copy of your data',
                  ),
                  const _Section(
                    title: '7. Data Retention',
                    body:
                        'We retain your information for as long as necessary to provide our services '
                        'and comply with legal obligations. Listing data may be retained for record-keeping purposes.',
                  ),
                  const _Section(
                    title: '8. Third-Party Services',
                    body:
                        'Our service integrates with third-party services (like Paddle for payments) '
                        'that have their own privacy policies. We encourage you to review their policies.',
                  ),
                  const _Section(
                    title: '9. Changes to This Policy',
                    body:
                        'We may update this privacy policy periodically. We will notify you of any '
                        'material changes by posting the new policy on this page.',
                  ),
                  const _Section(
                    title: '10. Contact Us',
                    body:
                        'If you have questions about this Privacy Policy, please contact us via '
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
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(body, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
