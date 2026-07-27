import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:paperdoll/core/error/domain_error.dart';
import 'package:paperdoll/core/router/routes.dart';
import 'package:paperdoll/debug_keys.dart';
import 'package:patrol_finders/patrol_finders.dart';

import '../../helpers.dart';

void main() {
  patrolWidgetTest('Submitting a new account authenticates', ($) async {
    final session = MockAuthSession();
    await pumpSignUpScreen($, session: session);

    await signUp($, email: 'newuser@example.com', password: 'a-strong-pass');

    verify(
      session.signUp(email: 'newuser@example.com', password: 'a-strong-pass'),
    ).called(1);
  });

  patrolWidgetTest('A taken email shows an error and stays put', ($) async {
    final session = MockAuthSession();
    when(
      session.signUp(email: 'alice@example.com', password: 'a-strong-pass'),
    ).thenThrow(const BadRequestError('Email already exists'));
    await pumpSignUpScreen($, session: session);

    await signUp($, email: 'alice@example.com', password: 'a-strong-pass');

    await $('Email already exists').waitUntilVisible();
    expect($(AppDebugKey.signUpScreen), findsOneWidget);
  });

  patrolWidgetTest('Tapping the sign-in link navigates to sign-in', ($) async {
    final router = MockGoRouter();
    await pumpSignUpScreen($, session: MockAuthSession(), router: router);

    await $(AppDebugKey.signUpGoToSignInButton).tap();

    verify(router.goNamed(routeSignInName)).called(1);
  });
}
