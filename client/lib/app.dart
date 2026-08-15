import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:paperdoll/core/router/app_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart' show Override;

class const PaperdollApp({super.key}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.grey),
      ),
      title: 'Paperdoll',
      routerConfig: ref.watch(goRouterProvider),
    );
  }
}

/// Builds the root [ProviderContainer] for [PaperdollApp]. Every environment
/// that runs this app — production (`main.dart`), the widget test harness
/// (`test/src/boilerplate.dart`), and the e2e harness (`e2e/helper.dart`) —
/// builds its own container (tests need one to inject overrides and seed
/// state before the first pump), so policies that must hold everywhere live
/// here once rather than being repeated at each call site.
ProviderContainer createPaperdollContainer({
  List<Override> overrides = const [],
  List<ProviderObserver>? observers,
}) {
  return ProviderContainer(
    overrides: overrides,
    observers: observers,
    // Riverpod retries a failed provider automatically by default; this app
    // surfaces failures via explicit retry buttons instead.
    retry: (_, _) => null,
  );
}
