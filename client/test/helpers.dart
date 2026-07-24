import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:paperdoll/core/error/domain_error.dart';
import 'package:paperdoll/core/router/routes.dart';
import 'package:paperdoll/debug_keys.dart';
import 'package:paperdoll/features/auth/presentation/providers/auth_providers.dart';
import 'package:paperdoll/features/auth/presentation/sign_in_screen.dart';
import 'package:paperdoll/features/auth/presentation/sign_up_screen.dart';
import 'package:patrol_finders/patrol_finders.dart';

/// Pumps [SignInScreen] in isolation for a pure widget test.
///
/// See [_pumpAuthScreen] for how the screen is wired.
Future<void> pumpSignInScreen(
  PatrolTester $, {
  required FakeAuthSession session,
}) async {
  await _pumpAuthScreen($, initialLocation: routeSignInPath, session: session);
}

/// Pumps [SignUpScreen] in isolation for a pure widget test.
///
/// See [_pumpAuthScreen] for how the screen is wired.
Future<void> pumpSignUpScreen(
  PatrolTester $, {
  required FakeAuthSession session,
}) async {
  await _pumpAuthScreen($, initialLocation: routeSignUpPath, session: session);
}

/// Pumps a single auth screen with just the collaborators it directly needs:
///
///  - a minimal [GoRouter] wiring only the sign-in and sign-up routes, so
///    `context.goNamed(...)` resolves and the two screens can navigate to each
///    other (but nothing else of the app router is involved);
///  - a [ProviderScope] overriding only [authSessionProvider] with [session],
///    the seam these screens depend on. The real notifier hits the network and
///    a `device_info_plus` platform channel, neither of which works under
///    `flutter_test`, so the fake stands in for it.
Future<void> _pumpAuthScreen(
  PatrolTester $, {
  required String initialLocation,
  required FakeAuthSession session,
}) async {
  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        name: routeSignInName,
        path: routeSignInPath,
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        name: routeSignUpName,
        path: routeSignUpPath,
        builder: (context, state) => const SignUpScreen(),
      ),
    ],
  );
  await $.pumpWidget(
    ProviderScope(
      overrides: [authSessionProvider.overrideWith(() => session)],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
}

/// A fake [AuthSession] notifier that replaces the real one in widget tests.
///
/// The real `_authenticate` calls `buildDeviceLabel()` (a `device_info_plus`
/// platform channel) and hits the network, neither of which works in a pure
/// `flutter_test`. This fake records the calls the screens make and lets each
/// test choose the outcome: throw [signInError] / [signUpError] to exercise the
/// error SnackBar path, or otherwise complete successfully.
class FakeAuthSession extends AuthSession {
  FakeAuthSession({this.signInError, this.signUpError});

  final DomainError? signInError;
  final DomainError? signUpError;

  final List<({String email, String password})> signInCalls = [];
  final List<({String email, String password})> signUpCalls = [];

  @override
  Future<String?> build() async => null;

  @override
  Future<void> signIn({required String email, required String password}) async {
    signInCalls.add((email: email, password: password));
    if (signInError != null) {
      throw signInError!;
    }
    state = const AsyncData('token');
  }

  @override
  Future<void> signUp({required String email, required String password}) async {
    signUpCalls.add((email: email, password: password));
    if (signUpError != null) {
      throw signUpError!;
    }
    state = const AsyncData('token');
  }
}

/// Fills the sign-in form and taps submit, driving the real UI.
Future<void> signIn(
  PatrolTester $, {
  required String email,
  required String password,
}) async {
  await $(AppDebugKey.signInEmailField).enterText(email);
  await $(AppDebugKey.signInPasswordField).enterText(password);
  await $(AppDebugKey.signInSubmitButton).tap();
}

/// Fills the sign-up form and taps submit, driving the real UI.
Future<void> signUp(
  PatrolTester $, {
  required String email,
  required String password,
}) async {
  await $(AppDebugKey.signUpEmailField).enterText(email);
  await $(AppDebugKey.signUpPasswordField).enterText(password);
  await $(AppDebugKey.signUpSubmitButton).tap();
}
