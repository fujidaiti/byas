import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:paperdoll/app.dart';
import 'package:paperdoll/features/auth/data/token_storage.dart';
import 'package:paperdoll/features/auth/presentation/providers/auth_providers.dart';
import 'package:patrol/patrol.dart';

Future<void> pumpApp(PatrolIntegrationTester $) async {
  await $.pumpWidget(const ProviderScope(child: PaperdollApp()));
}

/// Boots the app already authenticated, skipping the sign-in/up UI: fetches a
/// real token from the runner's `/signin` endpoint, persists it to secure
/// storage, and pumps the app so the real `AuthSession.build()` reads it and
/// the router lands straight on Today. Use this for tests behind the auth gate
/// that aren't about the auth flow itself (e.g. the newspaper suite).
Future<void> pumpAppWithAuth(PatrolIntegrationTester $) async {
  final token = await signInViaRunner();
  const storage = SecureTokenStorage();
  await storage.write(token);
  await $.pumpWidget(
    ProviderScope(
      overrides: [tokenStorageProvider.overrideWithValue(storage)],
      child: const PaperdollApp(),
    ),
  );
}

/// Builds a URL to the runner's message server. It listens on the host, reached
/// from the Android emulator via 10.0.2.2.
// TODO: make the host and port number configurable (assumes an Android
// emulator).
Uri _runnerUri(String path) =>
    Uri(scheme: 'http', host: '10.0.2.2', port: 9000, path: path);

const _runnerTimeout = Duration(seconds: 60);

/// Provisions the pre-defined test account via the runner's `/signin` endpoint
/// and returns its bearer token.
Future<String> signInViaRunner() async {
  final response = await http
      .post(_runnerUri('/signin'))
      .timeout(_runnerTimeout);
  if (response.statusCode != 200) {
    throw Exception(
      'signin request failed (${response.statusCode}): ${response.body}',
    );
  }
  final body = jsonDecode(response.body) as Map<String, dynamic>;
  return body['token'] as String;
}

Future<void> setUpServer({required String seederId}) async {
  // Initialize the Flutter binding up front so the host-facing socket is ready
  // before the first request; without it the connection can abort transiently
  // right after a test's app relaunch ("Software caused connection abort").
  WidgetsFlutterBinding.ensureInitialized();
  final response = await http
      .post(
        _runnerUri('/setup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'seeder_id': seederId}),
      )
      .timeout(_runnerTimeout);
  if (response.body != 'ready') {
    throw Exception(
      'setup request has finished with an error: ${response.body}',
    );
  }
}
