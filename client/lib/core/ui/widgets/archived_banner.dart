import 'package:flutter/material.dart';
import 'package:paperdoll/core/ui/tokens/app_colors.dart';
import 'package:paperdoll/core/ui/tokens/app_spacing.dart';
import 'package:paperdoll/core/ui/tokens/app_text_styles.dart';

/// A thin banner shown just below a reader's app bar to signal that the item
/// is archived (hidden from the reading list). Accent background, white label,
/// with a slight elevation so it floats over the content.
class ArchivedBanner extends StatelessWidget {
  const ArchivedBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: colorAccent,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: spacingXs),
        child: Center(
          child: Text(
            'ARCHIVED',
            style: textCaption.copyWith(color: colorBackground),
          ),
        ),
      ),
    );
  }
}
