import 'package:material_ui/material_ui.dart';

import 'package:paperdoll/core/ui/tokens/app_spacing.dart';
import 'package:paperdoll/core/ui/widgets/body_text.dart';
import 'package:paperdoll/core/ui/widgets/gap.dart';

/// Inline placeholder for empty results, with an optional call to action.
class const EmptyPlaceholder({
  required final String message,
  final String? actionLabel,
  final VoidCallback? onAction,
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
            if (actionLabel != null && onAction != null) ...[
              const Gap(spacingMd),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
