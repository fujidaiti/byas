import 'package:paperdoll/debug_keys.dart';
import 'package:patrol/patrol.dart';

import 'helper.dart';

void main() {
  patrolTest('Sign up for a new account', config: e2eConfig, ($) async {
    await setUpServer(seederId: 'auth_no_users');
    await pumpApp($);

    await $(AppDebugKey.signInScreen).waitUntilVisible();
    await signUp(
      $,
      email: 'newuser@example.com',
      password: existingUserPassword,
    );

    await $(AppDebugKey.todayScreen).waitUntilVisible();
  });

  patrolTest(
    'Signing up with a taken email shows an error',
    config: e2eConfig,
    ($) async {
      await setUpServer(seederId: 'auth_existing_user');
      await pumpApp($);

      await $(AppDebugKey.signInScreen).waitUntilVisible();
      await signUp($, email: existingUserEmail, password: existingUserPassword);

      await $('Email already exists').waitUntilVisible();
      await $(AppDebugKey.signUpScreen).waitUntilVisible();
    },
  );

  patrolTest('Sign in to an existing account', config: e2eConfig, ($) async {
    await setUpServer(seederId: 'auth_existing_user');
    await pumpApp($);

    await $(AppDebugKey.signInScreen).waitUntilVisible();
    await signIn($, email: existingUserEmail, password: existingUserPassword);

    await $(AppDebugKey.todayScreen).waitUntilVisible();
  });

  patrolTest(
    'Signing in with wrong credentials shows an error',
    config: e2eConfig,
    ($) async {
      await setUpServer(seederId: 'auth_existing_user');
      await pumpApp($);

      await $(AppDebugKey.signInScreen).waitUntilVisible();
      await signIn(
        $,
        email: existingUserEmail,
        password: 'wrong-password-value',
      );

      await $('Email or password is incorrect').waitUntilVisible();
      await $(AppDebugKey.signInScreen).waitUntilVisible();
    },
  );

  patrolTest('Navigate between sign-in and sign-up', config: e2eConfig, (
    $,
  ) async {
    await setUpServer(seederId: 'auth_no_users');
    await pumpApp($);

    await $(AppDebugKey.signInScreen).waitUntilVisible();
    await $(AppDebugKey.signInGoToSignUpButton).tap();
    await $(AppDebugKey.signUpScreen).waitUntilVisible();
    await $(AppDebugKey.signUpGoToSignInButton).tap();
    await $(AppDebugKey.signInScreen).waitUntilVisible();
  });
}
