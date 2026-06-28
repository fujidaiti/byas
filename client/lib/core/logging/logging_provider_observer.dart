import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:paperdoll/core/logging/app_logger.dart';

/// Logs every provider failure so errors that never reach a widget (e.g. a
/// provider that throws while nothing is listening, or a background refresh)
/// are still recorded rather than silently swallowed.
final class LoggingProviderObserver extends ProviderObserver {
  const LoggingProviderObserver();

  @override
  void providerDidFail(
    ProviderObserverContext context,
    Object error,
    StackTrace stackTrace,
  ) {
    final name = context.provider.name ?? context.provider.runtimeType;
    appLogger.severe('Provider $name failed', error, stackTrace);
  }
}
