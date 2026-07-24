import 'package:flutter_test/flutter_test.dart';
import 'package:paperdoll/core/error/domain_error.dart';
import 'package:paperdoll/debug_keys.dart';
import 'package:patrol_finders/patrol_finders.dart';

import '../../helpers.dart';

void main() {
  patrolWidgetTest('Submitting a new account authenticates', ($) async {
    final session = FakeAuthSession();
    await pumpSignUpScreen($, session: session);

    await signUp($, email: 'newuser@example.com', password: 'a-strong-pass');

    expect(session.signUpCalls.single, (
      email: 'newuser@example.com',
      password: 'a-strong-pass',
    ));
  });

  patrolWidgetTest('A taken email shows an error and stays put', ($) async {
    final session = FakeAuthSession(
      signUpError: const BadRequestError('Email already exists'),
    );
    await pumpSignUpScreen($, session: session);

    await signUp($, email: 'alice@example.com', password: 'a-strong-pass');

    await $('Email already exists').waitUntilVisible();
    expect($(AppDebugKey.signUpScreen), findsOneWidget);
  });

  patrolWidgetTest('Tapping the sign-in link navigates to sign-in', ($) async {
    await pumpSignUpScreen($, session: FakeAuthSession());

    await $(AppDebugKey.signUpGoToSignInButton).tap();

    await $(AppDebugKey.signInScreen).waitUntilVisible();
  });
}
