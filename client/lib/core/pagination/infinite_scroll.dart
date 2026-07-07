import 'package:flutter/widgets.dart';

/// Fires [onEndReached] when the wrapped scroll view is scrolled within
/// [threshold] pixels of its bottom. Works for any vertical scrollable
/// ([ListView], [CustomScrollView], …) via a scroll-notification listener.
///
/// [onEndReached] may fire repeatedly while scrolling near the edge; callers
/// are expected to guard against redundant loads (a paginating notifier's
/// `loadMore()` no-ops when a fetch is in flight or there is nothing more).
class InfiniteScrollList extends StatelessWidget {
  const InfiniteScrollList({
    required this.onEndReached,
    required this.child,
    this.threshold = 300,
    super.key,
  });

  final VoidCallback onEndReached;
  final double threshold;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        final metrics = notification.metrics;
        if (metrics.axis == Axis.vertical &&
            metrics.hasContentDimensions &&
            metrics.pixels >= metrics.maxScrollExtent - threshold) {
          onEndReached();
        }
        return false;
      },
      child: child,
    );
  }
}
