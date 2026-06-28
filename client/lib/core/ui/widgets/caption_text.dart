import 'package:flutter/widgets.dart';

import 'package:paperdoll/core/ui/tokens/app_text_styles.dart';

/// Text pre-styled with the caption token. Avoids inline style values.
class CaptionText extends StatelessWidget {
  const CaptionText(this.data, {this.maxLines, this.overflow, super.key});

  final String data;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    return Text(
      data,
      style: textCaption,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}
