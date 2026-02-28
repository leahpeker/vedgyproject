import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../providers/auth_provider.dart';
import '../screens/about_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/browse_screen.dart';
import '../screens/create_listing_screen.dart';
import '../screens/edit_listing_screen.dart';
import '../screens/pay_screen.dart';
import '../screens/preview_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/home_screen.dart';
import '../screens/listing_detail_screen.dart';
import '../screens/static/contact_screen.dart';
import '../screens/static/privacy_screen.dart';
import '../screens/static/terms_screen.dart';
import '../widgets/app_scaffold.dart';

part 'app_router.g.dart';

// ---------------------------------------------------------------------------
// Routes that require an authenticated session.
// ---------------------------------------------------------------------------

bool _requiresAuth(String location) =>
    location.startsWith('/dashboard') ||
    location.startsWith('/create') ||
    location.startsWith('/edit') ||
    location.startsWith('/preview') ||
    location.startsWith('/pay');

// Routes that an authenticated user should not visit (auth-only pages).
bool _isAuthOnlyRoute(String location) =>
    location == '/login' || location == '/signup';

// ---------------------------------------------------------------------------
// Router provider
// ---------------------------------------------------------------------------

@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  // Bridge Riverpod state changes to GoRouter's ChangeNotifier refresh system.
  // This triggers GoRouter to re-run the redirect callback on every auth change.
  final notifier = ValueNotifier<int>(0);
  ref.listen<AuthState>(authProvider, (prev, next) => notifier.value++);
  ref.onDispose(notifier.dispose);

  return GoRouter(
    refreshListenable: notifier,
    initialLocation: '/',
    redirect: (BuildContext context, GoRouterState state) {
      final authState = ref.read(authProvider);
      final location = state.matchedLocation;

      return authState.when(
        // Still reading stored refresh token — hold protected routes on home
        // (which shows a loading spinner) but don't redirect public routes.
        // Navigation guards re-fire when state leaves initial.
        initial: () => _requiresAuth(location) ? '/' : null,

        authenticated: (user, token) {
          if (!_isAuthOnlyRoute(location)) return null;
          // Respect the ?redirect= param so users land where they intended.
          final redirect = state.uri.queryParameters['redirect'];
          return (redirect != null && redirect.startsWith('/'))
              ? redirect
              : '/dashboard';
        },

        unauthenticated: () => _requiresAuth(location)
            ? '/login?redirect=${Uri.encodeComponent(location)}'
            : null,
      );
    },
    routes: [
      ShellRoute(
        builder: (context, state, child) => AppScaffold(child: child),
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/login',
            builder: (context, state) => const LoginScreen(),
          ),
          GoRoute(
            path: '/signup',
            builder: (context, state) => const SignupScreen(),
          ),
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/browse',
            builder: (context, state) => const BrowseScreen(),
          ),
          GoRoute(
            path: '/create',
            builder: (context, state) => const CreateListingScreen(),
          ),
          GoRoute(
            path: '/edit/:id',
            builder: (context, state) =>
                EditListingScreen(id: state.pathParameters['id']!),
          ),
          GoRoute(
            path: '/preview/:id',
            builder: (context, state) =>
                PreviewScreen(id: state.pathParameters['id']!),
          ),
          GoRoute(
            path: '/pay/:id',
            builder: (context, state) =>
                PayScreen(id: state.pathParameters['id']!),
          ),
          GoRoute(
            path: '/listing/:id',
            builder: (context, state) =>
                ListingDetailScreen(id: state.pathParameters['id']!),
          ),
          GoRoute(
            path: '/about',
            builder: (context, state) => const AboutScreen(),
          ),
          GoRoute(
            path: '/privacy',
            builder: (context, state) => const PrivacyScreen(),
          ),
          GoRoute(
            path: '/contact',
            builder: (context, state) => const ContactScreen(),
          ),
          GoRoute(
            path: '/terms',
            builder: (context, state) => const TermsScreen(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => AppScaffold(
      child: Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '404',
                style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('Page not found'),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => context.go('/'),
                child: const Text('Go home'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
