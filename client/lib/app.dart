import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paperdoll/core/router/app_router.dart';

class PaperdollApp extends ConsumerWidget {
  const PaperdollApp({super.key});

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
