import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vedgy/providers/auth_provider.dart';
import 'package:vedgy/router/app_router.dart';
import 'package:vedgy/services/secure_storage.dart';
import 'fake_secure_storage.dart';

class AppHarness {
  AppHarness({this.fakeStorage, this.extraOverrides = const []});

  final FakeSecureStorage? fakeStorage;
  final List<Override> extraOverrides;

  late ProviderContainer _container;

  Future<void> pump(WidgetTester tester) async {
    final storage = fakeStorage ?? FakeSecureStorage();
    _container = ProviderContainer(
      overrides: [
        secureStorageProvider.overrideWithValue(storage),
        ...extraOverrides,
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: _container,
        child: Consumer(
          builder: (ctx, ref, _) {
            final router = ref.watch(appRouterProvider);
            return MaterialApp.router(
              theme: ThemeData(
                colorScheme: ColorScheme.fromSeed(
                  seedColor: const Color(0xFF2D6A4F),
                ),
                useMaterial3: true,
              ),
              routerConfig: router,
            );
          },
        ),
      ),
    );
  }

  Future<void> init(WidgetTester tester) async {
    await _container.read(authProvider.notifier).init();
    await tester.pumpAndSettle();
  }

  T read<T>(ProviderListenable<T> provider) => _container.read(provider);
}
