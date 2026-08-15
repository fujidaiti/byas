import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:paperdoll/core/error/domain_error.dart';
import 'package:paperdoll/core/router/routes.dart';
import 'package:paperdoll/core/ui/tokens/app_spacing.dart';
import 'package:paperdoll/core/ui/widgets/gap.dart';
import 'package:paperdoll/debug_keys.dart';
import 'package:paperdoll/features/auth/presentation/providers/auth_providers.dart';

/// Sign in with email + password. On success, the router reacts to the
/// updated [authSessionProvider] state and navigates to Today on its own.
class const SignInScreen({super.key}) extends ConsumerStatefulWidget {
  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  var _submitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _submitting = true);
    try {
      await ref
          .read(authSessionProvider.notifier)
          .signIn(email: email, password: password);
    } on DomainError catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(describeError(error))));
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: AppDebugKey.signInScreen,
      appBar: AppBar(title: const Text('Sign in')),
      body: Padding(
        padding: const EdgeInsets.all(spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              key: AppDebugKey.signInEmailField,
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const Gap(spacingSm),
            TextField(
              key: AppDebugKey.signInPasswordField,
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => unawaited(_submit()),
            ),
            const Gap(spacingMd),
            FilledButton(
              key: AppDebugKey.signInSubmitButton,
              onPressed: _submitting ? null : () => unawaited(_submit()),
              child: const Text('Sign in'),
            ),
            const Gap(spacingSm),
            TextButton(
              key: AppDebugKey.signInGoToSignUpButton,
              onPressed: () => context.goNamed(routeSignUpName),
              child: const Text("Don't have an account? Sign up"),
            ),
          ],
        ),
      ),
    );
  }
}
