import 'package:flutter/widgets.dart';

/// A fixed-size spacer built from spacing tokens. Works in both Row and
/// Column; the irrelevant axis is harmless.
class Gap extends StatelessWidget {
  const Gap(this.size, {super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: size, height: size);
  }
}
