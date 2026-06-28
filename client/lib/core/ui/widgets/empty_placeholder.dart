import 'package:flutter/material.dart';

import 'package:paperdoll/core/ui/tokens/app_spacing.dart';
import 'package:paperdoll/core/ui/widgets/body_text.dart';
import 'package:paperdoll/core/ui/widgets/gap.dart';

/// Inline placeholder for empty results, with an optional call to action.
class EmptyPlaceholder extends StatelessWidget {
  const EmptyPlaceholder({
    required this.message,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

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
