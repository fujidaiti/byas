import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mockito/mockito.dart';
import 'package:paperdoll/core/error/domain_error.dart';
import 'package:paperdoll/core/router/routes.dart';
import 'package:paperdoll/debug_keys.dart';
import 'package:paperdoll/features/auth/presentation/providers/auth_providers.dart';
import 'package:paperdoll/features/auth/presentation/sign_in_screen.dart';
import 'package:paperdoll/features/auth/presentation/sign_up_screen.dart';
import 'package:patrol_finders/patrol_finders.dart';

import '../../helpers.dart';

void main() {
  group('SignUpScreen', () {
    late MockAuthSession session;
    late MockGoRouter router;
    late Widget testWidget;

    setUp(() {
      session = MockAuthSession();
      router = MockGoRouter();
      testWidget = ProviderScope(
        overrides: [authSessionProvider.overrideWith(() => session)],
        child: MaterialApp(
          home: InheritedGoRouter(
            goRouter: router,
            child: const SignUpScreen(),
          ),
        ),
      );
    });

    Future<void> signUp(PatrolTester $, String email, String password) async {
      await $(AppDebugKey.signUpEmailField).enterText(email);
      await $(AppDebugKey.signUpPasswordField).enterText(password);
      await $(AppDebugKey.signUpSubmitButton).tap();
    }

    patrolWidgetTest('Submitting a new account authenticates', ($) async {
      await $.pumpWidget(testWidget);
      await signUp($, 'newuser@example.com', 'a-strong-pass');
      verify(
        session.signUp(email: 'newuser@example.com', password: 'a-strong-pass'),
      );
    });

    patrolWidgetTest('A taken email shows an error and stays put', ($) async {
      when(
        session.signUp(
          email: anyNamed('email'),
          password: anyNamed('password'),
        ),
      ).thenThrow(const BadRequestError('Email already exists'));
      await $.pumpWidget(testWidget);

      await signUp($, 'alice@example.com', 'a-strong-pass');

      await $('Email already exists').waitUntilVisible();
      expect($(AppDebugKey.signUpScreen), findsOneWidget);
    });

    patrolWidgetTest('Tapping the sign-in link navigates to sign-in', (
      $,
    ) async {
      await $.pumpWidget(testWidget);

      await $(AppDebugKey.signUpGoToSignInButton).tap();

      verify(router.goNamed(routeSignInName));
    });
  });

  group('SignInScreen', () {
    late MockAuthSession session;
    late MockGoRouter router;
    late Widget testWidget;

    setUp(() {
      session = MockAuthSession();
      router = MockGoRouter();
      testWidget = ProviderScope(
        overrides: [authSessionProvider.overrideWith(() => session)],
        child: MaterialApp(
          home: InheritedGoRouter(
            goRouter: router,
            child: const SignInScreen(),
          ),
        ),
      );
    });

    Future<void> signIn(PatrolTester $, String email, String password) async {
      await $(AppDebugKey.signInEmailField).enterText(email);
      await $(AppDebugKey.signInPasswordField).enterText(password);
      await $(AppDebugKey.signInSubmitButton).tap();
    }

    patrolWidgetTest('Submitting valid credentials authenticates', ($) async {
      await $.pumpWidget(testWidget);

      await signIn($, 'alice@example.com', 'correct-password');

      verify(
        session.signIn(
          email: 'alice@example.com',
          password: 'correct-password',
        ),
      );
    });

    patrolWidgetTest('Wrong credentials show an error and stay put', ($) async {
      when(
        session.signIn(email: 'alice@example.com', password: 'wrong-password'),
      ).thenThrow(const BadRequestError('Email or password is incorrect'));
      await $.pumpWidget(testWidget);

      await signIn($, 'alice@example.com', 'wrong-password');

      await $('Email or password is incorrect').waitUntilVisible();
      expect($(AppDebugKey.signInScreen), findsOneWidget);
    });

    patrolWidgetTest('Submitting empty fields does nothing', ($) async {
      await $.pumpWidget(testWidget);

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
      await $.pumpWidget(testWidget);

      await signIn($, '  user@example.com  ', 'a-password');
      verify(session.signIn(email: 'user@example.com', password: 'a-password'));
    });

    patrolWidgetTest('Tapping the sign-up link navigates to sign-up', (
      $,
    ) async {
      await $.pumpWidget(testWidget);

      await $(AppDebugKey.signInGoToSignUpButton).tap();
      verify(router.goNamed(routeSignUpName));
    });
  });
}

class MockAuthSession extends AsyncNotifier<String?>
    with Mock
    implements AuthSession {
  @override
  Future<String?> build() async => null;

  @override
  Future<void> signIn({required String? email, required String? password}) {
    return super.noSuchMethod(
          Invocation.method(#signIn, const [], {
            #email: email,
            #password: password,
          }),
          returnValue: Future<void>.value(),
          returnValueForMissingStub: Future<void>.value(),
        )
        as Future<void>;
  }

  @override
  Future<void> signUp({required String? email, required String? password}) {
    return super.noSuchMethod(
          Invocation.method(#signUp, const [], {
            #email: email,
            #password: password,
          }),
          returnValue: Future<void>.value(),
          returnValueForMissingStub: Future<void>.value(),
        )
        as Future<void>;
  }
}
