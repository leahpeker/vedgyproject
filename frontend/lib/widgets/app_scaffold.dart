import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';

// Width at which the nav switches from hamburger menu to full horizontal nav.
const _kNavBreakpoint = 768.0;

class AppScaffold extends ConsumerWidget {
  const AppScaffold({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen for snackbar notifications and display them.
    ref.listen<AppNotification?>(notificationQueueProvider, (_, notification) {
      if (notification == null) return;
      final messenger = ScaffoldMessenger.maybeOf(context);
      if (messenger == null) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(notification.message),
          backgroundColor: notification.isError
              ? Theme.of(context).colorScheme.error
              : Colors.green.shade700,
        ),
      );
      // Clear so the same notification isn't re-shown on rebuild.
      ref.read(notificationQueueProvider.notifier).clear();
    });

    return Scaffold(
      appBar: _VedgyNavBar(onMenuPressed: _openDrawer),
      drawer: const _VedgyDrawer(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: child),
          const _VedgyFooter(),
        ],
      ),
    );
  }

  void _openDrawer(BuildContext context) {
    Scaffold.of(context).openDrawer();
  }
}

// ---------------------------------------------------------------------------
// Nav bar
// ---------------------------------------------------------------------------

class _VedgyNavBar extends ConsumerWidget implements PreferredSizeWidget {
  const _VedgyNavBar({required this.onMenuPressed});

  final void Function(BuildContext) onMenuPressed;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final isWide = MediaQuery.sizeOf(context).width >= _kNavBreakpoint;

    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Colors.white,
      title: GestureDetector(
        onTap: () => context.go('/'),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🏡 ', style: TextStyle(fontSize: 18)),
            Text(
              'VedgyProject',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ],
        ),
      ),
      actions: isWide
          ? [
              ..._navLinks(context),
              const SizedBox(width: 8),
              ..._authActions(context, ref, authState),
              const SizedBox(width: 16),
            ]
          : [
              Builder(
                builder: (ctx) => IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => onMenuPressed(ctx),
                ),
              ),
            ],
      automaticallyImplyLeading: false,
    );
  }

  List<Widget> _navLinks(BuildContext context) => [
    _NavLink('Browse', () => context.go('/browse')),
    _NavLink('Post a listing', () => context.go('/create')),
  ];

  List<Widget> _authActions(
    BuildContext context,
    WidgetRef ref,
    AuthState authState,
  ) {
    return authState.when(
      initial: () => [],
      authenticated: (user, _) => [
        _NavLink('My listings', () => context.go('/dashboard')),
        const SizedBox(width: 4),
        _NavLink(
          'Log out',
          () => ref.read(authProvider.notifier).logout(),
          style: _NavLinkStyle.outlined,
        ),
      ],
      unauthenticated: () => [
        _NavLink('Log in', () => context.go('/login')),
        const SizedBox(width: 4),
        _NavLink(
          'Sign up',
          () => context.go('/signup'),
          style: _NavLinkStyle.filled,
        ),
      ],
    );
  }
}

enum _NavLinkStyle { plain, outlined, filled }

class _NavLink extends StatelessWidget {
  const _NavLink(this.label, this.onTap, {this.style = _NavLinkStyle.plain});

  final String label;
  final VoidCallback onTap;
  final _NavLinkStyle style;

  @override
  Widget build(BuildContext context) {
    switch (style) {
      case _NavLinkStyle.plain:
        return TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(foregroundColor: Colors.white),
          child: Text(label),
        );
      case _NavLinkStyle.outlined:
        return OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(color: Colors.white70),
          ),
          child: Text(label),
        );
      case _NavLinkStyle.filled:
        return FilledButton(
          onPressed: onTap,
          style: FilledButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Theme.of(context).colorScheme.primary,
          ),
          child: Text(label),
        );
    }
  }
}

// ---------------------------------------------------------------------------
// Mobile drawer
// ---------------------------------------------------------------------------

class _VedgyDrawer extends ConsumerWidget {
  const _VedgyDrawer();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    void nav(String route) {
      Navigator.of(context).pop(); // close drawer
      context.go(route);
    }

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: const Row(
              children: [
                Text('🏡 ', style: TextStyle(fontSize: 22)),
                Text(
                  'VedgyProject',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home_outlined),
            title: const Text('Home'),
            onTap: () => nav('/'),
          ),
          ListTile(
            leading: const Icon(Icons.search),
            title: const Text('Browse listings'),
            onTap: () => nav('/browse'),
          ),
          ...authState.when(
            initial: () => <Widget>[],
            authenticated: (user, _) => [
              ListTile(
                leading: const Icon(Icons.add_home_outlined),
                title: const Text('Post a listing'),
                onTap: () => nav('/create'),
              ),
              ListTile(
                leading: const Icon(Icons.list_alt),
                title: const Text('My listings'),
                onTap: () => nav('/dashboard'),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Log out'),
                onTap: () {
                  Navigator.of(context).pop();
                  ref.read(authProvider.notifier).logout();
                },
              ),
            ],
            unauthenticated: () => [
              ListTile(
                leading: const Icon(Icons.add_home_outlined),
                title: const Text('Post a listing'),
                // Router guard redirects to /login?redirect=%2Fcreate for
                // unauthenticated users, preserving the intended destination.
                onTap: () => nav('/create'),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.login),
                title: const Text('Log in'),
                onTap: () => nav('/login'),
              ),
              ListTile(
                leading: const Icon(Icons.person_add_outlined),
                title: const Text('Sign up'),
                onTap: () => nav('/signup'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Footer
// ---------------------------------------------------------------------------

class _VedgyFooter extends StatelessWidget {
  const _VedgyFooter();

  static const _githubIssues =
      'https://github.com/leahpeker/veglistings/issues';
  static const _githubRepo = 'https://github.com/leahpeker/veglistings';

  @override
  Widget build(BuildContext context) {
    final headingStyle = TextStyle(
      color: Colors.white.withValues(alpha: 0.95),
      fontSize: 14,
      fontWeight: FontWeight.w600,
    );
    final linkStyle = TextStyle(
      color: Colors.white.withValues(alpha: 0.7),
      fontSize: 13,
    );
    final mutedStyle = TextStyle(
      color: Colors.white.withValues(alpha: 0.5),
      fontSize: 12,
    );

    return ColoredBox(
      color: const Color(0xFF1F2937),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Wrap(
                  spacing: 48,
                  runSpacing: 24,
                  children: [
                    // Brand column
                    SizedBox(
                      width: 200,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('🏡 ', style: TextStyle(fontSize: 14)),
                              Text(
                                'VedgyProject',
                                style: headingStyle.copyWith(fontSize: 16),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Connecting vegan-friendly renters and property owners.',
                            style: linkStyle,
                          ),
                        ],
                      ),
                    ),
                    // Quick Links
                    _FooterColumn(
                      title: 'Quick Links',
                      headingStyle: headingStyle,
                      children: [
                        _FooterLink(
                          'Browse Listings',
                          '/browse',
                          style: linkStyle,
                        ),
                        _FooterLink(
                          'Post a Listing',
                          '/create',
                          style: linkStyle,
                        ),
                      ],
                    ),
                    // Feedback & Support
                    _FooterColumn(
                      title: 'Feedback & Support',
                      headingStyle: headingStyle,
                      children: [
                        _FooterExternalLink(
                          'Report Issues',
                          _githubIssues,
                          style: linkStyle,
                        ),
                        _FooterLink('Contact Us', '/contact', style: linkStyle),
                        _FooterExternalLink(
                          'Source Code',
                          _githubRepo,
                          style: linkStyle,
                        ),
                      ],
                    ),
                    // Legal
                    _FooterColumn(
                      title: 'Legal',
                      headingStyle: headingStyle,
                      children: [
                        _FooterLink(
                          'Privacy Policy',
                          '/privacy',
                          style: linkStyle,
                        ),
                        _FooterLink('About', '/about', style: linkStyle),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Divider(color: Colors.white.withValues(alpha: 0.2), height: 1),
                const SizedBox(height: 16),
                Text(
                  '© ${DateTime.now().year} VedgyProject. All rights reserved.',
                  style: mutedStyle,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FooterColumn extends StatelessWidget {
  const _FooterColumn({
    required this.title,
    required this.headingStyle,
    required this.children,
  });

  final String title;
  final TextStyle headingStyle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: headingStyle),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _FooterLink extends StatelessWidget {
  const _FooterLink(this.label, this.route, {required this.style});

  final String label;
  final String route;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () => context.go(route),
        child: Text(label, style: style),
      ),
    );
  }
}

class _FooterExternalLink extends StatelessWidget {
  const _FooterExternalLink(this.label, this.url, {required this.style});

  final String label;
  final String url;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () =>
            launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
        child: Text(label, style: style),
      ),
    );
  }
}
