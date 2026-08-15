import 'package:flutter/widgets.dart';
import 'package:paperdoll/debug_keys.dart';
import 'package:patrol/patrol.dart';

import 'helper.dart';

void main() {
  // Initialize the Flutter binding up front so the host-facing socket is ready
  // before the first request; without it the connection can abort transiently
  // right after a test's app relaunch ("Software caused connection abort").
  WidgetsFlutterBinding.ensureInitialized();

  patrolTest('Sign up for a new account', tags: 'signup', (t) async {
    await setUpServer(seederId: 'auth_no_users');
    await pumpApp(t);

    await t(AppDebugKey.signInGoToSignUpButton).tap();
    await t(AppDebugKey.signUpEmailField).enterText('newuser@example.com');
    await t(AppDebugKey.signUpPasswordField)
        .enterText('New-User-Account-Password');
    await t(AppDebugKey.signUpSubmitButton).tap();
    await t(AppDebugKey.todayScreen).waitUntilVisible();
  });

  patrolTest('Sign in to an existing account', tags: 'signin', (t) async {
    await setUpServer(seederId: 'auth_existing_user');
    await pumpApp(t);

    await t(AppDebugKey.signInScreen).waitUntilVisible();
    await t(AppDebugKey.signInEmailField).enterText('alice@example.com');
    await t(AppDebugKey.signInPasswordField)
        .enterText('Police-Repurpose-Atypical-Gravel');
    await t(AppDebugKey.signInSubmitButton).tap();
    await t(AppDebugKey.todayScreen).waitUntilVisible();
  });

  patrolTest('Sign out ends the session', tags: 'signout', (t) async {
    await setUpServer(seederId: 'auth_signed_in');
    await pumpAppWithAuth(t);

    await t(AppDebugKey.todayScreen).waitUntilVisible();
    await t(AppDebugKey.settingsButton).tap();
    await t(AppDebugKey.settingsScreen).waitUntilVisible();
    await t(AppDebugKey.signOutButton).tap();
    await t(AppDebugKey.signInScreen).waitUntilVisible();
  });
}
