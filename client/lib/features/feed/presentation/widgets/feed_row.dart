import 'package:material_ui/material_ui.dart';

import 'package:paperdoll/core/ui/widgets/body_text.dart';
import 'package:paperdoll/core/ui/widgets/heading_text.dart';
import 'package:paperdoll/features/feed/domain/feed.dart';
import 'package:paperdoll/features/feed/presentation/widgets/feed_icon.dart';

/// A subscribed feed in the Feeds list.
class const FeedRow({
  required final Feed feed,
  final VoidCallback? onTap,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final description = feed.description;
    return ListTile(
      onTap: onTap,
      leading: FeedIcon(url: feed.iconUrl),
      title: HeadingText(
        feed.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: description == null
          ? null
          : BodyText(description, maxLines: 2, overflow: TextOverflow.ellipsis),
    );
  }
}
