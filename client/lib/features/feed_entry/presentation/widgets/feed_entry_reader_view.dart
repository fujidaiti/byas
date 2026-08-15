import 'package:material_ui/material_ui.dart';
import 'package:paperdoll/core/ui/tokens/app_spacing.dart';
import 'package:paperdoll/core/ui/widgets/body_text.dart';
import 'package:paperdoll/features/feed_entry/domain/feed_entry.dart';
import 'package:paperdoll/features/feed_entry/presentation/widgets/feed_entry_content_webview.dart';

/// Shared reading layout for both the Story Reader and the Feed Entry Reader: a
/// header (title) above the rendered HTML content.
class const FeedEntryReaderView({required final FeedEntry entry, super.key})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final content = entry.content;
    if (content != null && content.trim().isNotEmpty) {
      return FeedEntryContentWebView(html: content);
    }
    return Padding(
      padding: const EdgeInsets.all(spacingMd),
      child: BodyText(entry.description ?? 'No content available.'),
    );
  }
}
