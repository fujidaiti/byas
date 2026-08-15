import 'package:material_ui/material_ui.dart';

import 'package:paperdoll/core/ui/tokens/app_spacing.dart';
import 'package:paperdoll/core/ui/widgets/body_text.dart';
import 'package:paperdoll/core/ui/widgets/heading_text.dart';
import 'package:paperdoll/features/feed/domain/feed_candidate.dart';

/// A search result with a subscribe action.
class const FeedCandidateTile({
  required final FeedCandidate candidate,
  required final VoidCallback onSubscribe,
  final bool isSubscribing = false,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final description = candidate.description;
    return ListTile(
      onTap: isSubscribing ? null : onSubscribe,
      title: HeadingText(
        candidate.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: description == null
          ? null
          : BodyText(description, maxLines: 2, overflow: TextOverflow.ellipsis),
      trailing: isSubscribing
          ? const SizedBox(
              width: iconMd,
              height: iconMd,
              child: Padding(
                padding: EdgeInsets.all(spacingSm),
                child: CircularProgressIndicator.adaptive(),
              ),
            )
          : FilledButton(
              onPressed: onSubscribe,
              child: const Text('Subscribe'),
            ),
    );
  }
}
