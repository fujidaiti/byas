import 'package:material_ui/material_ui.dart';
import 'package:paperdoll/core/error/domain_error.dart';
import 'package:paperdoll/core/ui/tokens/app_spacing.dart';

/// Trailing footer for a paginated list: a spinner while the next page loads,
/// an inline message with a retry when the last next-page fetch failed, and
/// nothing otherwise.
class const LoadMoreFooter({
  required final bool isLoading,
  final Object? error,
  final VoidCallback? onRetry,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final error = this.error;
    if (error != null) {
      return Padding(
        padding: const EdgeInsets.all(spacingMd),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(describeError(error), textAlign: TextAlign.center),
            const SizedBox(height: spacingSm),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.all(spacingMd),
        child: Center(child: CircularProgressIndicator.adaptive()),
      );
    }
    return const SizedBox.shrink();
  }
}
