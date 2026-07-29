import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:paperdoll/core/error/domain_error.dart';
import 'package:paperdoll/core/router/routes.dart';
import 'package:paperdoll/debug_keys.dart';
import 'package:paperdoll/features/auth/data/token_storage.dart';
import 'package:paperdoll/features/auth/domain/auth_repository.dart';
import 'package:paperdoll/features/auth/presentation/providers/auth_providers.dart';
import 'package:paperdoll/features/auth/presentation/sign_in_screen.dart';
import 'package:paperdoll/features/auth/presentation/sign_up_screen.dart';
import 'package:patrol_finders/patrol_finders.dart';

import '../../helpers.dart';
@GenerateMocks([TokenStorage, AuthRepository, DeviceInfoPlugin])
import 'auth_screens_test.mocks.dart';

void main() {
  late MockTokenStorage tokenStorage;
  late MockAuthRepository authRepository;
  late MockDeviceInfoPlugin deviceInfoPlugin;
  late MockGoRouter router;

  setUp(() {
    tokenStorage = MockTokenStorage();
    authRepository = MockAuthRepository();
    deviceInfoPlugin = MockDeviceInfoPlugin();
    router = MockGoRouter();

    when(tokenStorage.read()).thenAnswer((_) async => null);
    when(tokenStorage.write(any)).thenAnswer((_) async {});
    when(
      deviceInfoPlugin.androidInfo,
    ).thenAnswer((_) async => _fakeAndroidDeviceInfo);
    when(
      authRepository.signUp(
        email: anyNamed('email'),
        password: anyNamed('password'),
        device: anyNamed('device'),
      ),
    ).thenAnswer((_) async => 'a-token');
    when(
      authRepository.signIn(
        email: anyNamed('email'),
        password: anyNamed('password'),
        device: anyNamed('device'),
      ),
    ).thenAnswer((_) async => 'a-token');
  });

  group('SignUpScreen', () {
    late Widget testWidget;

    setUp(() {
      testWidget = ProviderScope(
        overrides: [
          tokenStorageProvider.overrideWithValue(tokenStorage),
          authRepositoryProvider.overrideWithValue(authRepository),
          deviceInfoPluginProvider.overrideWithValue(deviceInfoPlugin),
        ],
        // Mirrors the real app's router, which watches authSessionProvider
        // to react to sign-in/sign-up (see app_router.dart's redirect). This
        // keeps the autoDispose provider alive across the async gap in
        // signIn/signUp, matching production behavior.
        child: Consumer(
          builder: (context, ref, child) {
            ref.watch(authSessionProvider);
            return child!;
          },
          child: MaterialApp(
            home: InheritedGoRouter(
              goRouter: router,
              child: const SignUpScreen(),
            ),
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
      await signUp($, 'newuser@example.com', 'a-strong-password');
      verify(
        authRepository.signUp(
          email: 'newuser@example.com',
          password: 'a-strong-password',
          device: 'Pixel 8 Pro/android-14',
        ),
      );
    });

    patrolWidgetTest('A taken email shows an error and stays put', ($) async {
      when(
        authRepository.signUp(
          email: anyNamed('email'),
          password: anyNamed('password'),
          device: anyNamed('device'),
        ),
      ).thenThrow(const BadRequestError('Email already exists'));
      await $.pumpWidget(testWidget);

      await signUp($, 'alice@example.com', 'a-strong-password');

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
    late Widget testWidget;

    setUp(() {
      testWidget = ProviderScope(
        overrides: [
          tokenStorageProvider.overrideWithValue(tokenStorage),
          authRepositoryProvider.overrideWithValue(authRepository),
          deviceInfoPluginProvider.overrideWithValue(deviceInfoPlugin),
        ],
        child: Consumer(
          builder: (context, ref, child) {
            ref.watch(authSessionProvider);
            return child!;
          },
          child: MaterialApp(
            home: InheritedGoRouter(
              goRouter: router,
              child: const SignInScreen(),
            ),
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
        authRepository.signIn(
          email: 'alice@example.com',
          password: 'correct-password',
          device: anyNamed('device'),
        ),
      );
    });

    patrolWidgetTest('Wrong credentials show an error and stay put', ($) async {
      when(
        authRepository.signIn(
          email: 'alice@example.com',
          password: 'wrong-password',
          device: anyNamed('device'),
        ),
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
      verifyNever(
        authRepository.signIn(
          email: anyNamed('email'),
          password: anyNamed('password'),
          device: anyNamed('device'),
        ),
      );
      expect(find.byType(SnackBar), findsNothing);
      expect($(AppDebugKey.signInScreen), findsOneWidget);
    });

    patrolWidgetTest('Submitting trims the email before authenticating', (
      $,
    ) async {
      await $.pumpWidget(testWidget);

      await signIn($, '  user@example.com  ', 'a-password');
      verify(
        authRepository.signIn(
          email: 'user@example.com',
          password: 'a-password',
          device: anyNamed('device'),
        ),
      );
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

final AndroidDeviceInfo _fakeAndroidDeviceInfo =
    AndroidDeviceInfo.setMockInitialValues(
      version: AndroidBuildVersion.setMockInitialValues(
        codename: 'REL',
        incremental: '1',
        previewSdkInt: 0,
        release: '14',
        sdkInt: 34,
      ),
      board: 'test-board',
      bootloader: 'test-bootloader',
      brand: 'google',
      device: 'test-device',
      display: 'test-display',
      fingerprint: 'test-fingerprint',
      hardware: 'test-hardware',
      host: 'test-host',
      id: 'test-id',
      manufacturer: 'Google',
      model: 'Pixel 8 Pro',
      product: 'test-product',
      name: 'test-name',
      supported32BitAbis: const [],
      supported64BitAbis: const ['arm64-v8a'],
      supportedAbis: const ['arm64-v8a'],
      tags: 'release-keys',
      type: 'user',
      isPhysicalDevice: true,
      freeDiskSize: 0,
      totalDiskSize: 0,
      systemFeatures: const [],
      isLowRamDevice: false,
      physicalRamSize: 0,
      availableRamSize: 0,
    );
