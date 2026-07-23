import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paperdoll/app.dart';
import 'package:paperdoll/core/logging/app_logger.dart';
import 'package:paperdoll/core/logging/logging_provider_observer.dart';

void main() {
  configureLogging();
  runApp(
    const ProviderScope(
      observers: [LoggingProviderObserver()],
      child: PaperdollApp(),
    ),
  );
}
