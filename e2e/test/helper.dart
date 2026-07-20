import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

Future<void> setUpServer({
  required String debugLabel,
  required String scenarioId,
}) async {
  try {
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
        .timeout(const Duration(seconds: 120));
    if (response.body != 'ready') {
      throw Exception(
        'setup request has finished with an error: ${response.body}',
      );
    }
  } on TimeoutException catch (err) {
    throw Exception('timeout: no response from test server. $err');
  }
}
