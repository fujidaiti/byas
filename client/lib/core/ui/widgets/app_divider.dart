import 'package:material_ui/material_ui.dart';

import 'package:paperdoll/core/ui/tokens/app_colors.dart';
import 'package:paperdoll/core/ui/tokens/app_spacing.dart';

/// A thin divider styled from tokens. Avoids inline dimension values.
class const AppDivider({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: dividerHeight,
      thickness: dividerHeight,
      color: colorDivider,
    );
  }
}
