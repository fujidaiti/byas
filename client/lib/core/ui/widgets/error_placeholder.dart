import 'package:material_ui/material_ui.dart';

import 'package:paperdoll/core/ui/tokens/app_spacing.dart';
import 'package:paperdoll/core/ui/widgets/body_text.dart';
import 'package:paperdoll/core/ui/widgets/gap.dart';

/// Inline placeholder for load failures: a message plus an optional retry.
class const ErrorPlaceholder({
  required final String message,
  final VoidCallback? onRetry,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(spacingLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            BodyText(message),
            if (onRetry != null) ...[
              const Gap(spacingMd),
              FilledButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ],
        ),
      ),
    );
  }
}
