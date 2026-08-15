import 'package:material_ui/material_ui.dart';
import 'package:paperdoll/core/ui/widgets/loading_indicator.dart';

/// Shown only briefly, while the router waits to learn whether a token is
/// already persisted locally (see `goRouter`'s `redirect`).
class const SplashScreen({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: LoadingIndicator());
  }
}
