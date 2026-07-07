import 'package:flutter/foundation.dart';

/// One page of a cursor-paginated list: the fetched [items] plus the opaque
/// [nextCursor] to fetch the following page ([hasMore] is false on the last
/// page, where the server omits the cursor).
@immutable
class PageResult<T> {
  const PageResult({required this.items, this.nextCursor});

  final List<T> items;
  final String? nextCursor;

  bool get hasMore => nextCursor != null;
}
