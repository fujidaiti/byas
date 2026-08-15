import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:paperdoll/core/platform/app_version.dart';
import 'package:paperdoll/debug_keys.dart';
import 'package:paperdoll/features/auth/presentation/providers/auth_providers.dart';

/// Settings home: currently just sign-out. On success, the router reacts to
/// the cleared [authSessionProvider] state and navigates to Sign-in on its
/// own.
class const SettingsScreen({super.key}) extends ConsumerStatefulWidget {
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  var _submitting = false;

  Future<void> _signOut() async {
    setState(() => _submitting = true);
    await ref.read(authSessionProvider.notifier).signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: AppDebugKey.settingsScreen,
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            key: AppDebugKey.signOutButton,
            leading: const Icon(Icons.logout),
            title: const Text('Sign out'),
            enabled: !_submitting,
            onTap: () => unawaited(_signOut()),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(switch (ref.watch(appVersionProvider)) {
              AsyncData(:final value) => 'Version $value',
              _ => '',
            }),
          ),
        ],
      ),
    );
  }
}
