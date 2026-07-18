import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:openapi/api.dart' as api;
import 'package:paperdoll/debug_keys.dart';
import 'package:patrol/patrol.dart';

import 'helpers.dart';

void main() {
  patrolTest('Sign up for a new account', ($) async {
    await pumpApp($, token: null);
    final adapter = httpMockAdapter($);

    adapter.onPost(
      '/signup',
      (s) => s.reply(201, api.SignUp201Response(token: 'new-token').toJson()),
      data: Matchers.any,
    );

    expect($(AppDebugKey.signInScreen), findsOneWidget);
    await $(AppDebugKey.signInGoToSignUpButton).tap();
    expect($(AppDebugKey.signUpScreen), findsOneWidget);

    await $(AppDebugKey.signUpEmailField).enterText('alice@example.com');
    await $(
      AppDebugKey.signUpPasswordField,
    ).enterText('Police-Repurpose-Atypical-Gravel');
    await $(AppDebugKey.signUpSubmitButton).tap();

    expect($(AppDebugKey.todayScreen), findsOneWidget);
  });

  patrolTest('Signing up with a taken email shows an error', ($) async {
    await pumpApp($, token: null);
    final adapter = httpMockAdapter($);

    adapter.onPost(
      '/signup',
      (s) => s.reply(409, {'message': 'Email already exists'}),
      data: Matchers.any,
    );

    await $(AppDebugKey.signInGoToSignUpButton).tap();
    await $(AppDebugKey.signUpEmailField).enterText('alice@example.com');
    await $(
      AppDebugKey.signUpPasswordField,
    ).enterText('Police-Repurpose-Atypical-Gravel');
    await $(AppDebugKey.signUpSubmitButton).tap();

    expect($('Email already exists'), findsOneWidget);
    expect($(AppDebugKey.signUpScreen), findsOneWidget);
  });

  patrolTest('Sign in to an existing account', ($) async {
    await pumpApp($, token: null);
    final adapter = httpMockAdapter($);

    adapter.onPost(
      '/signin',
      (s) => s.reply(200, api.SignUp201Response(token: 'new-token').toJson()),
      data: Matchers.any,
    );

    expect($(AppDebugKey.signInScreen), findsOneWidget);
    await $(AppDebugKey.signInEmailField).enterText('alice@example.com');
    await $(
      AppDebugKey.signInPasswordField,
    ).enterText('Police-Repurpose-Atypical-Gravel');
    await $(AppDebugKey.signInSubmitButton).tap();

    expect($(AppDebugKey.todayScreen), findsOneWidget);
  });

  patrolTest('Signing in with wrong credentials shows an error', ($) async {
    await pumpApp($, token: null);
    final adapter = httpMockAdapter($);

    adapter.onPost(
      '/signin',
      (s) => s.reply(401, {'message': 'Email or password is incorrect'}),
      data: Matchers.any,
    );

    await $(AppDebugKey.signInEmailField).enterText('alice@example.com');
    await $(AppDebugKey.signInPasswordField).enterText('wrong-password');
    await $(AppDebugKey.signInSubmitButton).tap();

    expect($('Email or password is incorrect'), findsOneWidget);
    expect($(AppDebugKey.signInScreen), findsOneWidget);
  });

  patrolTest('Navigate between sign-in and sign-up', ($) async {
    await pumpApp($, token: null);

    expect($(AppDebugKey.signInScreen), findsOneWidget);
    await $(AppDebugKey.signInGoToSignUpButton).tap();
    expect($(AppDebugKey.signUpScreen), findsOneWidget);
    await $(AppDebugKey.signUpGoToSignInButton).tap();
    expect($(AppDebugKey.signInScreen), findsOneWidget);
  });
}
