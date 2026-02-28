import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/auth_provider.dart';
import 'router/app_router.dart';

void main() {
  runApp(const ProviderScope(child: VedgyApp()));
}

class VedgyApp extends ConsumerStatefulWidget {
  const VedgyApp({super.key});

  @override
  ConsumerState<VedgyApp> createState() => _VedgyAppState();
}

class _VedgyAppState extends ConsumerState<VedgyApp> {
  @override
  void initState() {
    super.initState();
    // Restore session from stored refresh token. GoRouter's refreshListenable
    // will re-run the redirect when state leaves AuthState.initial.
    ref.read(authProvider.notifier).init();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'Vedgy',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2D6A4F)),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}
