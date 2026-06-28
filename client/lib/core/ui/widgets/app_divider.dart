import 'package:flutter/material.dart';

import 'package:paperdoll/core/ui/tokens/app_colors.dart';
import 'package:paperdoll/core/ui/tokens/app_spacing.dart';

/// A thin divider styled from tokens. Avoids inline dimension values.
class AppDivider extends StatelessWidget {
  const AppDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: dividerHeight,
      thickness: dividerHeight,
      color: colorDivider,
    );
  }
}
