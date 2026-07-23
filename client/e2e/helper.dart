import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:paperdoll/app.dart';
import 'package:paperdoll/debug_keys.dart';
import 'package:patrol/patrol.dart';

/// Credentials of the user inserted by the `auth_existing_user` seeder
/// (see `e2e/auth_seed.go`); keep these in sync with the Go constants.
const existingUserEmail = 'alice@example.com';
const existingUserPassword = 'Police-Repurpose-Atypical-Gravel';

/// Generous finder timeouts: these hit a real backend, and the first test after
/// a cold install pays extra startup cost (e.g. first `flutter_secure_storage`
/// keystore access) before the sign-in screen settles.
const e2eConfig = PatrolTesterConfig(
  existsTimeout: Duration(seconds: 30),
  visibleTimeout: Duration(seconds: 30),
  settleTimeout: Duration(seconds: 30),
);

Future<void> pumpApp(PatrolIntegrationTester $) async {
  await $.pumpWidget(const ProviderScope(child: PaperdollApp()));
}

/// Signs in from the sign-in screen by driving the real UI + backend.
Future<void> signIn(
  PatrolIntegrationTester $, {
  required String email,
  required String password,
}) async {
  await $(AppDebugKey.signInEmailField).enterText(email);
  await $(AppDebugKey.signInPasswordField).enterText(password);
  await $(AppDebugKey.signInSubmitButton).tap();
}

/// Signs up from the sign-in screen: navigates to sign-up, fills the form, and
/// submits, driving the real UI + backend.
Future<void> signUp(
  PatrolIntegrationTester $, {
  required String email,
  required String password,
}) async {
  await $(AppDebugKey.signInGoToSignUpButton).tap();
  await $(AppDebugKey.signUpEmailField).enterText(email);
  await $(AppDebugKey.signUpPasswordField).enterText(password);
  await $(AppDebugKey.signUpSubmitButton).tap();
}

Future<void> setUpServer({required String seederId}) async {
  // The connection to the runner can abort transiently right after a test's
  // app relaunch (e.g. "Software caused connection abort"), so retry on
  // connection/timeout errors. A received-but-not-"ready" body is a real
  // seeding error and is not retried.
  const maxAttempts = 5;
  for (var attempt = 1; ; attempt++) {
    try {
      final response = await http
          .post(
            // TODO: make the host and port number configurable
            // This assumes that the test is running on an android emulator.
            Uri(scheme: 'http', host: '10.0.2.2', port: 9000, path: '/setup'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'seeder_id': seederId}),
          )
          .timeout(const Duration(seconds: 60));
      if (response.body != 'ready') {
        throw Exception(
          'setup request has finished with an error: ${response.body}',
        );
      }
      return;
    } on http.ClientException {
      if (attempt >= maxAttempts) {
        rethrow;
      }
    } on TimeoutException {
      if (attempt >= maxAttempts) {
        rethrow;
      }
    }
    await Future<void>.delayed(const Duration(seconds: 1));
  }
}
