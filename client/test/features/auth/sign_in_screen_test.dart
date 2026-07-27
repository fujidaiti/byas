import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:paperdoll/core/error/domain_error.dart';
import 'package:paperdoll/core/router/routes.dart';
import 'package:paperdoll/debug_keys.dart';
import 'package:patrol_finders/patrol_finders.dart';

import '../../helpers.dart';

void main() {
  patrolWidgetTest('Submitting valid credentials authenticates', ($) async {
    final session = MockAuthSession();
    await pumpSignInScreen($, session: session);

    await signIn($, email: 'alice@example.com', password: 'correct-password');

    verify(
      session.signIn(email: 'alice@example.com', password: 'correct-password'),
    ).called(1);
  });

  patrolWidgetTest('Wrong credentials show an error and stay put', ($) async {
    final session = MockAuthSession();
    when(
      session.signIn(email: 'alice@example.com', password: 'wrong-password'),
    ).thenThrow(const BadRequestError('Email or password is incorrect'));
    await pumpSignInScreen($, session: session);

    await signIn($, email: 'alice@example.com', password: 'wrong-password');

    await $('Email or password is incorrect').waitUntilVisible();
    expect($(AppDebugKey.signInScreen), findsOneWidget);
  });

  patrolWidgetTest('Submitting empty fields does nothing', ($) async {
    final session = MockAuthSession();
    await pumpSignInScreen($, session: session);

    await $(AppDebugKey.signInSubmitButton).tap();

    // The screen guards on empty input, so no request is made (with empty
    // fields the only call it could make is with empty strings), no error
    // surfaces, and it stays put.
    verifyNever(session.signIn(email: '', password: ''));
    expect(find.byType(SnackBar), findsNothing);
    expect($(AppDebugKey.signInScreen), findsOneWidget);
  });

  patrolWidgetTest('Submitting trims the email before authenticating', (
    $,
  ) async {
    final session = MockAuthSession();
    await pumpSignInScreen($, session: session);

    await signIn($, email: '  user@example.com  ', password: 'a-password');

    verify(
      session.signIn(email: 'user@example.com', password: 'a-password'),
    ).called(1);
  });

  patrolWidgetTest('Tapping the sign-up link navigates to sign-up', ($) async {
    final router = MockGoRouter();
    await pumpSignInScreen($, session: MockAuthSession(), router: router);

    await $(AppDebugKey.signInGoToSignUpButton).tap();

    verify(router.goNamed(routeSignUpName)).called(1);
  });
}
