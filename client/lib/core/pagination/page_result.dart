import 'package:flutter/foundation.dart';

/// One page of a cursor-paginated list: the fetched [items] plus the opaque
/// [nextCursor] to fetch the following page ([hasMore] is false on the last
/// page, where the server omits the cursor).
@immutable
class const PageResult<T>({
  required final List<T> items,
  final String? nextCursor,
}) {
  bool get hasMore => nextCursor != null;
}
