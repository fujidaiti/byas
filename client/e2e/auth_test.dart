import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paperdoll/debug_keys.dart';
import 'package:patrol/patrol.dart';

import 'helper.dart';

void main() {
  // Initialize the Flutter binding up front so the host-facing socket is ready
  // before the first request; without it the connection can abort transiently
  // right after a test's app relaunch ("Software caused connection abort").
  WidgetsFlutterBinding.ensureInitialized();

  const email = 'alice@example.com';
  const password = 'Police-Repurpose-Atypical-Gravel';

  patrolTest('Sign up for a new account', ($) async {
    await setUpServer(seederId: 'auth_no_users');
    await pumpApp($);

    await $(AppDebugKey.signInScreen).waitUntilVisible();
    await _signUp($, 'newuser@example.com', 'New-User-Account-Password');
    await $(AppDebugKey.todayScreen).waitUntilVisible();
  });

  patrolTest('Signing up with a taken email shows an error', ($) async {
    await setUpServer(seederId: 'auth_existing_user');
    await pumpApp($);

    await $(AppDebugKey.signInScreen).waitUntilVisible();
    await _signUp($, email, password);
    await $('Email already exists').waitUntilVisible();
    await $(AppDebugKey.signUpScreen).waitUntilVisible();
  });

  patrolTest('Sign in to an existing account', ($) async {
    await setUpServer(seederId: 'auth_existing_user');
    await pumpApp($);

    await $(AppDebugKey.signInScreen).waitUntilVisible();
    await _signIn($, email, password);
    await $(AppDebugKey.todayScreen).waitUntilVisible();
  });

  patrolTest('Signing in with wrong credentials shows an error', ($) async {
    await setUpServer(seederId: 'auth_existing_user');
    await pumpApp($);

    await $(AppDebugKey.signInScreen).waitUntilVisible();
    await _signIn($, email, 'wrong-password-value');
    await $('Email or password is incorrect').waitUntilVisible();
    await $(AppDebugKey.signInScreen).waitUntilVisible();
  });

  patrolTest('Navigate between sign-in and sign-up', ($) async {
    await setUpServer(seederId: 'auth_no_users');
    await pumpApp($);

    await $(AppDebugKey.signInScreen).waitUntilVisible();
    await $(AppDebugKey.signInGoToSignUpButton).tap();
    await $(AppDebugKey.signUpScreen).waitUntilVisible();
    await $(AppDebugKey.signUpGoToSignInButton).tap();
    await $(AppDebugKey.signInScreen).waitUntilVisible();
  });
}

Future<void> _signIn(
  PatrolIntegrationTester $,
  String email,
  String password,
) async {
  await $(AppDebugKey.signInEmailField).enterText(email);
  await $(AppDebugKey.signInPasswordField).enterText(password);
  await $(AppDebugKey.signInSubmitButton).tap();
}

Future<void> _signUp(
  PatrolIntegrationTester $,
  String email,
  String password,
) async {
  await $(AppDebugKey.signInGoToSignUpButton).tap();
  await $(AppDebugKey.signUpEmailField).enterText(email);
  await $(AppDebugKey.signUpPasswordField).enterText(password);
  await $(AppDebugKey.signUpSubmitButton).tap();
}
