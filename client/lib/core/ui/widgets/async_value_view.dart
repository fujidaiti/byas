import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:paperdoll/core/error/domain_error.dart';
import 'package:paperdoll/core/ui/widgets/error_placeholder.dart';
import 'package:paperdoll/core/ui/widgets/loading_indicator.dart';

/// Renders an [AsyncValue] uniformly: loading → spinner, error → inline
/// placeholder with retry, data → [data] builder.
class AsyncValueView<T> extends StatelessWidget {
  const AsyncValueView({
    required this.value,
    required this.data,
    this.onRetry,
    super.key,
  });

  final AsyncValue<T> value;

  // A builder that consumes T in a parameter position; the contravariance is
  // intentional and mirrors AsyncValue.when.
  // ignore: unsafe_variance
  final Widget Function(T value) data;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: data,
      loading: () => const LoadingIndicator(),
      error: (error, _) =>
          ErrorPlaceholder(message: describeError(error), onRetry: onRetry),
    );
  }
}
