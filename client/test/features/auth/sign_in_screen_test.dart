import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paperdoll/core/error/domain_error.dart';
import 'package:paperdoll/debug_keys.dart';
import 'package:patrol_finders/patrol_finders.dart';

import '../../helpers.dart';

void main() {
  patrolWidgetTest('Submitting valid credentials authenticates', ($) async {
    final session = FakeAuthSession();
    await pumpSignInScreen($, session: session);

    await signIn($, email: 'alice@example.com', password: 'correct-password');

    expect(session.signInCalls.single, (
      email: 'alice@example.com',
      password: 'correct-password',
    ));
  });

  patrolWidgetTest('Wrong credentials show an error and stay put', ($) async {
    final session = FakeAuthSession(
      signInError: const BadRequestError('Email or password is incorrect'),
    );
    await pumpSignInScreen($, session: session);

    await signIn($, email: 'alice@example.com', password: 'wrong-password');

    await $('Email or password is incorrect').waitUntilVisible();
    expect($(AppDebugKey.signInScreen), findsOneWidget);
  });

  patrolWidgetTest('Submitting empty fields does nothing', ($) async {
    final session = FakeAuthSession();
    await pumpSignInScreen($, session: session);

    await $(AppDebugKey.signInSubmitButton).tap();

    // No request is made and no error surfaces; the screen stays put.
    expect(session.signInCalls, isEmpty);
    expect(find.byType(SnackBar), findsNothing);
    expect($(AppDebugKey.signInScreen), findsOneWidget);
  });

  patrolWidgetTest('Submitting trims the email before authenticating', (
    $,
  ) async {
    final session = FakeAuthSession();
    await pumpSignInScreen($, session: session);

    await signIn($, email: '  user@example.com  ', password: 'a-password');

    expect(session.signInCalls.single.email, 'user@example.com');
  });

  patrolWidgetTest('Tapping the sign-up link navigates to sign-up', ($) async {
    await pumpSignInScreen($, session: FakeAuthSession());

    await $(AppDebugKey.signInGoToSignUpButton).tap();

    await $(AppDebugKey.signUpScreen).waitUntilVisible();
  });
}
