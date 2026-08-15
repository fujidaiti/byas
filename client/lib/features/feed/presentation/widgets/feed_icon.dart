import 'package:material_ui/material_ui.dart';

import 'package:paperdoll/core/ui/tokens/app_radii.dart';
import 'package:paperdoll/core/ui/tokens/app_spacing.dart';

/// A feed's icon, falling back to a generic glyph when missing or unloadable.
class const FeedIcon({
  required final String? url,
  final double size = iconMd,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final url = this.url;
    if (url == null) {
      return Icon(Icons.rss_feed, size: size);
    }
    return ClipRRect(
      borderRadius: borderRadiusCard,
      child: Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            Icon(Icons.rss_feed, size: size),
      ),
    );
  }
}
