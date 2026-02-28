import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';

// Width at which the nav switches from hamburger menu to full horizontal nav.
const _kNavBreakpoint = 768.0;

class AppScaffold extends ConsumerWidget {
  const AppScaffold({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: _VedgyNavBar(onMenuPressed: _openDrawer),
      drawer: const _VedgyDrawer(),
      body: Column(
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
        child: const Text(
          'Vedgy',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
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
            child: const Text(
              'Vedgy',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
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

  @override
  Widget build(BuildContext context) {
    final textStyle = TextStyle(
      color: Colors.white.withValues(alpha: 0.8),
      fontSize: 13,
    );

    return ColoredBox(
      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.9),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Wrap(
              spacing: 24,
              runSpacing: 8,
              children: [
                _FooterLink('Home', '/'),
                _FooterLink('Browse', '/browse'),
                _FooterLink('Post a listing', '/create'),
                _FooterLink('About', '/about'),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '© ${DateTime.now().year} Vedgy. Open-source vegan housing.',
              style: textStyle,
            ),
          ],
        ),
      ),
    );
  }
}

class _FooterLink extends StatelessWidget {
  const _FooterLink(this.label, this.route);

  final String label;
  final String route;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go(route),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.85),
          fontSize: 13,
          decoration: TextDecoration.underline,
          decorationColor: Colors.white54,
        ),
      ),
    );
  }
}
