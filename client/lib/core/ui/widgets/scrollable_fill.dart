import 'package:flutter/widgets.dart';

/// Hosts [child] in an always-scrollable viewport sized to fill the available
/// space.
///
/// Use this for placeholder content (e.g. an empty or error state) inside a
/// [RefreshIndicator]: without a scrollable descendant that accepts overscroll,
/// a pull gesture never reaches the indicator and pull-to-refresh silently does
/// nothing. Filling the viewport also keeps a centered child vertically
/// centered instead of collapsing to the top.
///
/// ```dart
/// RefreshIndicator(
///   onRefresh: _refresh,
///   child: switch (items.isEmpty) {
///     true => const ScrollableFill(
///       child: EmptyPlaceholder(message: 'Nothing here yet.'),
///     ),
///     false => ListView(children: [...]),
///   },
/// )
/// ```
class const ScrollableFill({required final Widget child, super.key})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: child,
        ),
      ),
    );
  }
}
