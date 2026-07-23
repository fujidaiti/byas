import 'package:flutter/material.dart';
import 'package:paperdoll/core/ui/widgets/loading_indicator.dart';

/// Shown only briefly, while the router waits to learn whether a token is
/// already persisted locally (see `goRouter`'s `redirect`).
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: LoadingIndicator());
  }
}
