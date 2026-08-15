import 'package:flutter/widgets.dart';

/// A fixed-size spacer built from spacing tokens. Works in both Row and
/// Column; the irrelevant axis is harmless.
class const Gap(final double size, {super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(width: size, height: size);
  }
}
