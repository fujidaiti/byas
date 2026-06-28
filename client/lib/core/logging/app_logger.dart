import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

/// The single app-wide logger. Kept deliberately sparse; verbose levels are
/// opt-in via [configureLogging].
final appLogger = Logger('paperdoll');

/// Wires the logging package to console output. Call once at startup.
void configureLogging({Level level = Level.WARNING}) {
  Logger.root.level = level;
  Logger.root.onRecord.listen((record) {
    debugPrint('${record.level.name}: ${record.loggerName}: ${record.message}');
    final error = record.error;
    if (error != null) {
      debugPrint('  error: $error');
    }
    final stackTrace = record.stackTrace;
    if (stackTrace != null) {
      debugPrint('  stackTrace: $stackTrace');
    }
  });
}
