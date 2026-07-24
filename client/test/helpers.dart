import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paperdoll/app.dart';
import 'package:paperdoll/core/config/app_config.dart';
import 'package:paperdoll/core/config/app_config_provider.dart';
import 'package:paperdoll/core/error/domain_error.dart';
import 'package:paperdoll/debug_keys.dart';
import 'package:paperdoll/features/auth/data/token_storage.dart';
import 'package:paperdoll/features/auth/presentation/providers/auth_providers.dart';
import 'package:patrol_finders/patrol_finders.dart';

/// Boots the app for a pure widget test. Overrides the provider layer so
/// nothing touches the real network, secure storage, or platform channels:
///
///  - [authSessionProvider] is replaced by [session] (defaults to a
///    success-on-submit fake), which starts signed out so the router lands on
///    the sign-in screen. This is the mock seam for the sign-in/sign-up UI.
///  - [appConfigProvider] and [tokenStorageProvider] are stubbed so a
///    happy-path redirect to Today builds its Dio setup cleanly (the off-screen
///    request just resolves to an error; the Today Scaffold still renders).
Future<void> pumpApp(PatrolTester $, {FakeAuthSession? session}) async {
  await $.pumpWidget(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(const AppConfig('http://mock')),
        tokenStorageProvider.overrideWithValue(FakeTokenStorage()),
        authSessionProvider.overrideWith(() => session ?? FakeAuthSession()),
      ],
      child: const PaperdollApp(),
    ),
  );
}

/// In-memory [TokenStorage] fake, so tests don't touch the secure storage
/// plugin. Mirrors the one in `integration_test/helpers.dart`.
class FakeTokenStorage implements TokenStorage {
  FakeTokenStorage([this._token]);

  String? _token;

  @override
  Future<String?> read() async => _token;

  @override
  Future<void> write(String token) async => _token = token;

  @override
  Future<void> delete() async => _token = null;
}

/// A fake [AuthSession] notifier that replaces the real one in widget tests.
///
/// The real `_authenticate` calls `buildDeviceLabel()` (a `device_info_plus`
/// platform channel) and hits the network, neither of which works in a pure
/// `flutter_test`. This fake records the calls the screens make and lets each
/// test choose the outcome:
///
///  - throw [signInError] / [signUpError] to exercise the error SnackBar path;
///  - otherwise, when [recordOnly] is false, set the session token so the real
///    router redirects to Today (happy path); when [recordOnly] is true, leave
///    the state unchanged so the screen stays put (call-inspection tests).
class FakeAuthSession extends AuthSession {
  FakeAuthSession({
    this.signInError,
    this.signUpError,
    this.recordOnly = false,
  });

  final DomainError? signInError;
  final DomainError? signUpError;
  final bool recordOnly;

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
    if (!recordOnly) {
      state = const AsyncData('token');
    }
  }

  @override
  Future<void> signUp({required String email, required String password}) async {
    signUpCalls.add((email: email, password: password));
    if (signUpError != null) {
      throw signUpError!;
    }
    if (!recordOnly) {
      state = const AsyncData('token');
    }
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

/// Navigates to sign-up, fills the form, and taps submit, driving the real UI.
Future<void> signUp(
  PatrolTester $, {
  required String email,
  required String password,
}) async {
  await $(AppDebugKey.signInGoToSignUpButton).tap();
  await $(AppDebugKey.signUpEmailField).enterText(email);
  await $(AppDebugKey.signUpPasswordField).enterText(password);
  await $(AppDebugKey.signUpSubmitButton).tap();
}
