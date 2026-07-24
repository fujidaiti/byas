import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paperdoll/core/error/domain_error.dart';
import 'package:paperdoll/debug_keys.dart';
import 'package:patrol_finders/patrol_finders.dart';

import '../../helpers.dart';

void main() {
  patrolWidgetTest('Sign in to an existing account', ($) async {
    final session = FakeAuthSession();
    await pumpApp($, session: session);

    await $(AppDebugKey.signInScreen).waitUntilVisible();
    await signIn($, email: 'alice@example.com', password: 'correct-password');

    await $(AppDebugKey.todayScreen).waitUntilVisible();
  });

  patrolWidgetTest('Signing in with wrong credentials shows an error', (
    $,
  ) async {
    final session = FakeAuthSession(
      signInError: const BadRequestError('Email or password is incorrect'),
    );
    await pumpApp($, session: session);

    await $(AppDebugKey.signInScreen).waitUntilVisible();
    await signIn($, email: 'alice@example.com', password: 'wrong-password');

    await $('Email or password is incorrect').waitUntilVisible();
    expect($(AppDebugKey.signInScreen), findsOneWidget);
  });

  patrolWidgetTest('Sign up for a new account', ($) async {
    final session = FakeAuthSession();
    await pumpApp($, session: session);

    await $(AppDebugKey.signInScreen).waitUntilVisible();
    await signUp(
      $,
      email: 'newuser@example.com',
      password: 'a-strong-password',
    );

    await $(AppDebugKey.todayScreen).waitUntilVisible();
  });

  patrolWidgetTest('Signing up with a taken email shows an error', ($) async {
    final session = FakeAuthSession(
      signUpError: const BadRequestError('Email already exists'),
    );
    await pumpApp($, session: session);

    await $(AppDebugKey.signInScreen).waitUntilVisible();
    await signUp($, email: 'alice@example.com', password: 'a-strong-password');

    await $('Email already exists').waitUntilVisible();
    expect($(AppDebugKey.signUpScreen), findsOneWidget);
  });

  patrolWidgetTest('Navigate between sign-in and sign-up', ($) async {
    await pumpApp($);

    await $(AppDebugKey.signInScreen).waitUntilVisible();
    await $(AppDebugKey.signInGoToSignUpButton).tap();
    await $(AppDebugKey.signUpScreen).waitUntilVisible();
    await $(AppDebugKey.signUpGoToSignInButton).tap();
    await $(AppDebugKey.signInScreen).waitUntilVisible();
  });

  patrolWidgetTest('Submitting empty fields does nothing', ($) async {
    final session = FakeAuthSession();
    await pumpApp($, session: session);

    await $(AppDebugKey.signInScreen).waitUntilVisible();
    await $(AppDebugKey.signInSubmitButton).tap();

    // No request is made and no error surfaces; the screen stays put.
    expect(session.signInCalls, isEmpty);
    expect(find.byType(SnackBar), findsNothing);
    expect($(AppDebugKey.signInScreen), findsOneWidget);
  });

  patrolWidgetTest('Submitting trims the email before authenticating', (
    $,
  ) async {
    final session = FakeAuthSession(recordOnly: true);
    await pumpApp($, session: session);

    await $(AppDebugKey.signInScreen).waitUntilVisible();
    await signIn($, email: '  user@example.com  ', password: 'a-password');

    expect(session.signInCalls.single.email, 'user@example.com');
  });
}
