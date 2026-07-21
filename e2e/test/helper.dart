import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:paperdoll/app.dart';
import 'package:patrol/patrol.dart';

Future<void> pumpApp(PatrolIntegrationTester $) async {
  await $.pumpWidget(const ProviderScope(child: PaperdollApp()));
}

Future<void> setUpServer({
  required String debugLabel,
  required String scenarioId,
}) async {
  final response = await http
      .post(
        // TODO: make the host and port number configurable
        // This assumes that the test is running on an android emulator.
        Uri(scheme: 'http', host: '10.0.2.2', port: 9000, path: '/setup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'debug_label': debugLabel,
          'scenario_id': scenarioId,
        }),
      )
      .timeout(const Duration(seconds: 60));
  if (response.body != 'ready') {
    throw Exception(
      'setup request has finished with an error: ${response.body}',
    );
  }
}
