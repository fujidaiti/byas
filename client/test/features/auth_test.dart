import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openapi/api.dart' as api;
import 'package:paperdoll/debug_keys.dart';
import 'package:patrol_finders/patrol_finders.dart';

import '../src/helpers.dart';

/// The device label the app derives from the stubbed device info.
const _expectedDevice = 'Pixel 8 Pro/android-14';

void main() {
  patrolWidgetTest('Sign up for a new account', (t) async {
    final adapter = await pumpApp(t);
    adapter.onPost(
      '/signup',
      (server) => server.reply(
        201,
        api.SignUp201Response(token: 'issued-token').toJson(),
      ),
      data: api.SignUpRequest(
        email: 'newuser@example.com',
        password: 'a-strong-password',
        device: _expectedDevice,
      ).toJson(),
    );

    await t(AppDebugKey.signInGoToSignUpButton).tap();
    await signUp(t, 'newuser@example.com', 'a-strong-password');
    expect(t(AppDebugKey.todayScreen), findsOneWidget);
  });

  patrolWidgetTest('Sign in to an existing account', (t) async {
    final adapter = await pumpApp(t);
    adapter.onPost(
      '/signin',
      (server) => server.reply(
        200,
        api.SignUp201Response(token: 'issued-token').toJson(),
      ),
      data: api.SignInRequest(
        email: 'alice@example.com',
        password: 'correct-password',
        device: _expectedDevice,
      ).toJson(),
    );

    expect(t(AppDebugKey.signInScreen), findsOneWidget);
    await signIn(t, 'alice@example.com', 'correct-password');
    expect(t(AppDebugKey.todayScreen), findsOneWidget);
  });

  patrolWidgetTest('Sign in with a padded email address', (t) async {
    final adapter = await pumpApp(t);
    adapter.onPost(
      '/signin',
      (server) => server.reply(
        200,
        api.SignUp201Response(token: 'issued-token').toJson(),
      ),
      // The registration only matches once the screen has trimmed the email;
      // an unmatched request fails the test.
      data: api.SignInRequest(
        email: 'user@example.com',
        password: 'a-password',
        device: _expectedDevice,
      ).toJson(),
    );

    await signIn(t, '  user@example.com  ', 'a-password');
    expect(t(AppDebugKey.todayScreen), findsOneWidget);
  });

  patrolWidgetTest('Signing up with a taken email keeps the form open', (
    t,
  ) async {
    final adapter = await pumpApp(t);
    adapter.onPost(
      '/signup',
      (server) => server.reply(
        400,
        api.Error(message: 'Email already exists').toJson(),
      ),
      data: api.SignUpRequest(
        email: 'alice@example.com',
        password: 'a-strong-password',
        device: _expectedDevice,
      ).toJson(),
    );

    await t(AppDebugKey.signInGoToSignUpButton).tap();
    await signUp(t, 'alice@example.com', 'a-strong-password');
    expect(t('Email already exists'), findsOneWidget);
    expect(t(AppDebugKey.signUpScreen), findsOneWidget);
  });

  patrolWidgetTest('Signing in with wrong credentials keeps the form open', (
    t,
  ) async {
    final adapter = await pumpApp(t);
    adapter.onPost(
      '/signin',
      (server) => server.reply(
        400,
        api.Error(message: 'Email or password is incorrect').toJson(),
      ),
      data: api.SignInRequest(
        email: 'alice@example.com',
        password: 'wrong-password',
        device: _expectedDevice,
      ).toJson(),
    );

    await signIn(t, 'alice@example.com', 'wrong-password');
    expect(t('Email or password is incorrect'), findsOneWidget);
    expect(t(AppDebugKey.signInScreen), findsOneWidget);
  });

  patrolWidgetTest('Submitting empty credentials does nothing', (t) async {
    await pumpApp(t);
    await t(AppDebugKey.signInSubmitButton).tap();
    // The screen guards on empty input, so it stays put without asking the
    // server — `/signin` is left unstubbed, and a request would surface an
    // error snackbar.
    expect(find.byType(SnackBar), findsNothing);
    expect(t(AppDebugKey.signInScreen), findsOneWidget);
  });

  patrolWidgetTest('Switch between sign-in and sign-up', (t) async {
    await pumpApp(t);
    await t(AppDebugKey.signInGoToSignUpButton).tap();
    expect(t(AppDebugKey.signUpScreen), findsOneWidget);
    await t(AppDebugKey.signUpGoToSignInButton).tap();
    expect(t(AppDebugKey.signInScreen), findsOneWidget);
  });

  patrolWidgetTest('Open the app with a stored token', (t) async {
    await pumpApp(t, token: 'stored-token');
    expect(t(AppDebugKey.todayScreen), findsOneWidget);
    expect(t(AppDebugKey.signInScreen), findsNothing);
    expect(t(AppDebugKey.signUpScreen), findsNothing);
  });
}

Future<void> signUp(PatrolTester t, String email, String password) async {
  await t(AppDebugKey.signUpEmailField).enterText(email);
  await t(AppDebugKey.signUpPasswordField).enterText(password);
  await t(AppDebugKey.signUpSubmitButton).tap();
}

Future<void> signIn(PatrolTester t, String email, String password) async {
  await t(AppDebugKey.signInEmailField).enterText(email);
  await t(AppDebugKey.signInPasswordField).enterText(password);
  await t(AppDebugKey.signInSubmitButton).tap();
}
