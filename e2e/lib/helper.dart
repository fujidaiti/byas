import 'dart:async';
import 'dart:convert';
import 'dart:io';

const _delimiter = '\n';

Future<void> setUpServer({
  required String debugLabel,
  required String scenarioId,
}) async {
  final socket = await Socket.connect(
    // TODO: Make the server host address configurable
    // Currently, we assume that the testing is running on an android emulator.
    '10.0.2.2',
    9000,
    timeout: const Duration(seconds: 60),
  );
  final msg = jsonEncode({
    'debug_label': debugLabel,
    'scenario_id': scenarioId,
  });

  try {
    socket.write('$msg$_delimiter');
    await socket.flush();
    final response = await socket
        .cast<List<int>>()
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .first
        .timeout(const Duration(seconds: 60));

    if (response != 'ready') {
      throw Exception('setup request has finished with an error: $response');
    }
  } on TimeoutException catch (err) {
    throw Exception('timeout: no response from test server. $err');
  } finally {
    socket.destroy();
  }
}
