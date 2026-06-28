import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:paperdoll/core/logging/app_logger.dart';
import 'package:paperdoll/core/router/app_router.dart';

void main() {
  configureLogging();
  runApp(const ProviderScope(child: PaperdollApp()));
}

class PaperdollApp extends ConsumerWidget {
  const PaperdollApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Paperdoll',
      routerConfig: ref.watch(goRouterProvider),
    );
  }
}
