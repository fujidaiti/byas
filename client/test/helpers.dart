import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mockito/mockito.dart';
import 'package:paperdoll/debug_keys.dart';
import 'package:paperdoll/features/auth/presentation/providers/auth_providers.dart';
import 'package:paperdoll/features/auth/presentation/sign_in_screen.dart';
import 'package:paperdoll/features/auth/presentation/sign_up_screen.dart';
import 'package:patrol_finders/patrol_finders.dart';

/// A mockito mock of the [AuthSession] notifier, used to stub/verify the
/// `signIn`/`signUp` calls the auth screens make.
///
/// It extends the real [AsyncNotifier] base (rather than only `implements
/// AuthSession`) so Riverpod's `runBuild` machinery stays intact; [build] is
/// overridden to return synchronously so the mock never touches the network or
/// the `device_info_plus` platform channel the real notifier uses.
///
/// `signIn`/`signUp` forward to mockito's [noSuchMethod] — so `when(...)` /
/// `verify(...)` see them — while supplying a real `Future<void>` return value.
/// This mirrors what mockito's code generator emits; hand-written mocks need it
/// because `Mock`'s default `noSuchMethod` would return `null` for these
/// non-nullable `Future<void>` methods and the cast would throw.
class MockAuthSession extends AsyncNotifier<String?>
    with Mock
    implements AuthSession {
  @override
  Future<String?> build() async => null;

  @override
  Future<void> signIn({required String email, required String password}) =>
      super.noSuchMethod(
            Invocation.method(#signIn, const [], {
              #email: email,
              #password: password,
            }),
            returnValue: Future<void>.value(),
            returnValueForMissingStub: Future<void>.value(),
          )
          as Future<void>;

  @override
  Future<void> signUp({required String email, required String password}) =>
      super.noSuchMethod(
            Invocation.method(#signUp, const [], {
              #email: email,
              #password: password,
            }),
            returnValue: Future<void>.value(),
            returnValueForMissingStub: Future<void>.value(),
          )
          as Future<void>;
}

/// A mockito mock of [GoRouter], injected via [InheritedGoRouter] so the
/// screens' `context.goNamed(...)` calls resolve to it and can be verified.
class MockGoRouter extends Mock implements GoRouter {}

/// Pumps [SignInScreen] in isolation for a pure widget test.
///
/// See [_pumpAuthScreen] for how the screen is wired.
Future<void> pumpSignInScreen(
  PatrolTester $, {
  required MockAuthSession session,
  MockGoRouter? router,
}) async {
  await _pumpAuthScreen(
    $,
    screen: const SignInScreen(),
    session: session,
    router: router,
  );
}

/// Pumps [SignUpScreen] in isolation for a pure widget test.
///
/// See [_pumpAuthScreen] for how the screen is wired.
Future<void> pumpSignUpScreen(
  PatrolTester $, {
  required MockAuthSession session,
  MockGoRouter? router,
}) async {
  await _pumpAuthScreen(
    $,
    screen: const SignUpScreen(),
    session: session,
    router: router,
  );
}

/// Pumps a single auth [screen] with just the collaborators it directly needs:
///
///  - a [MockGoRouter] provided through [InheritedGoRouter], so
///    `context.goNamed(...)` resolves to the mock and navigation can be
///    verified (no real router or destination screen is involved);
///  - a [ProviderScope] overriding only [authSessionProvider] with [session],
///    the seam these screens depend on. The real notifier hits the network and
///    a `device_info_plus` platform channel, neither of which works under
///    `flutter_test`, so the mock stands in for it.
///
/// The plain [MaterialApp] (not `.router`) still supplies the `Directionality`,
/// theme, and root `ScaffoldMessenger` the screens render against.
Future<void> _pumpAuthScreen(
  PatrolTester $, {
  required Widget screen,
  required MockAuthSession session,
  MockGoRouter? router,
}) async {
  await $.pumpWidget(
    ProviderScope(
      overrides: [authSessionProvider.overrideWith(() => session)],
      child: MaterialApp(
        home: InheritedGoRouter(
          goRouter: router ?? MockGoRouter(),
          child: screen,
        ),
      ),
    ),
  );
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
