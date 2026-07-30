import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openapi/api.dart' as api;
import 'package:paperdoll/debug_keys.dart';
import 'package:patrol_finders/patrol_finders.dart';

import '../../helpers.dart';

/// The device label the app derives from the stubbed device info.
const _device = 'Pixel 8 Pro/android-14';

void main() {
  Future<void> signUp(PatrolTester $, String email, String password) async {
    await $(AppDebugKey.signUpEmailField).enterText(email);
    await $(AppDebugKey.signUpPasswordField).enterText(password);
    await $(AppDebugKey.signUpSubmitButton).tap();
  }

  Future<void> signIn(PatrolTester $, String email, String password) async {
    await $(AppDebugKey.signInEmailField).enterText(email);
    await $(AppDebugKey.signInPasswordField).enterText(password);
    await $(AppDebugKey.signInSubmitButton).tap();
  }

  patrolWidgetTest('Sign up for a new account', ($) async {
    final adapter = await pumpApp($);
    adapter.onPost(
      '/signup',
      (server) => server.reply(
        201,
        api.SignUp201Response(token: 'issued-token').toJson(),
      ),
      data: api.SignUpRequest(
        email: 'newuser@example.com',
        password: 'a-strong-password',
        device: _device,
      ).toJson(),
    );

    await $(AppDebugKey.signInGoToSignUpButton).tap();
    await signUp($, 'newuser@example.com', 'a-strong-password');

    expect($(AppDebugKey.todayScreen), findsOneWidget);
  });

  patrolWidgetTest('Sign in to an existing account', ($) async {
    final adapter = await pumpApp($);
    adapter.onPost(
      '/signin',
      (server) => server.reply(
        200,
        api.SignUp201Response(token: 'issued-token').toJson(),
      ),
      data: api.SignInRequest(
        email: 'alice@example.com',
        password: 'correct-password',
        device: _device,
      ).toJson(),
    );

    expect($(AppDebugKey.signInScreen), findsOneWidget);
    await signIn($, 'alice@example.com', 'correct-password');

    expect($(AppDebugKey.todayScreen), findsOneWidget);
  });

  patrolWidgetTest('Sign in with a padded email address', ($) async {
    final adapter = await pumpApp($);
    // The registration only matches once the screen has trimmed the email;
    // an unmatched request fails the test.
    adapter.onPost(
      '/signin',
      (server) => server.reply(
        200,
        api.SignUp201Response(token: 'issued-token').toJson(),
      ),
      data: api.SignInRequest(
        email: 'user@example.com',
        password: 'a-password',
        device: _device,
      ).toJson(),
    );

    await signIn($, '  user@example.com  ', 'a-password');

    expect($(AppDebugKey.todayScreen), findsOneWidget);
  });

  patrolWidgetTest('Signing up with a taken email keeps the form open', (
    $,
  ) async {
    final adapter = await pumpApp($);
    adapter.onPost(
      '/signup',
      (server) => server.reply(
        400,
        api.Error(message: 'Email already exists').toJson(),
      ),
      data: api.SignUpRequest(
        email: 'alice@example.com',
        password: 'a-strong-password',
        device: _device,
      ).toJson(),
    );

    await $(AppDebugKey.signInGoToSignUpButton).tap();
    await signUp($, 'alice@example.com', 'a-strong-password');

    expect($('Email already exists'), findsOneWidget);
    expect($(AppDebugKey.signUpScreen), findsOneWidget);
  });

  patrolWidgetTest('Signing in with wrong credentials keeps the form open', (
    $,
  ) async {
    final adapter = await pumpApp($);
    adapter.onPost(
      '/signin',
      (server) => server.reply(
        400,
        api.Error(message: 'Email or password is incorrect').toJson(),
      ),
      data: api.SignInRequest(
        email: 'alice@example.com',
        password: 'wrong-password',
        device: _device,
      ).toJson(),
    );

    await signIn($, 'alice@example.com', 'wrong-password');

    expect($('Email or password is incorrect'), findsOneWidget);
    expect($(AppDebugKey.signInScreen), findsOneWidget);
  });

  patrolWidgetTest('Submitting empty credentials does nothing', ($) async {
    await pumpApp($);

    await $(AppDebugKey.signInSubmitButton).tap();

    // The screen guards on empty input, so it stays put without asking the
    // server — `/signin` is left unstubbed, and a request would surface an
    // error snackbar.
    expect(find.byType(SnackBar), findsNothing);
    expect($(AppDebugKey.signInScreen), findsOneWidget);
  });

  patrolWidgetTest('Switch between sign-in and sign-up', ($) async {
    await pumpApp($);

    await $(AppDebugKey.signInGoToSignUpButton).tap();
    expect($(AppDebugKey.signUpScreen), findsOneWidget);

    await $(AppDebugKey.signUpGoToSignInButton).tap();
    expect($(AppDebugKey.signInScreen), findsOneWidget);
  });

  patrolWidgetTest('Open the app with a stored token', ($) async {
    await pumpApp($, token: 'stored-token');

    expect($(AppDebugKey.todayScreen), findsOneWidget);
    expect($(AppDebugKey.signInScreen), findsNothing);
    expect($(AppDebugKey.signUpScreen), findsNothing);
  });
}
