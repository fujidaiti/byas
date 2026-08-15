import 'package:material_ui/material_ui.dart';

/// Centered progress indicator for loading states.
class const LoadingIndicator({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator.adaptive());
  }
}
