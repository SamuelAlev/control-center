import 'package:control_center/core/providers/storage_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _keepAwakeKey = 'keep_computer_awake_while_agents_run';

/// Whether to keep the computer awake while any agent is working. Defaults to
/// true; backed by [AppPreferences] (non-sensitive preference).
final keepComputerAwakeProvider =
    NotifierProvider<KeepComputerAwakeNotifier, bool>(
      KeepComputerAwakeNotifier.new,
    );

/// Notifier for [keepComputerAwakeProvider].
class KeepComputerAwakeNotifier extends Notifier<bool> {
  @override
  bool build() =>
      ref.watch(appPreferencesProvider).getBool(_keepAwakeKey) ?? true;

  /// Persists the preference and updates the live value.
  Future<void> setEnabled({required bool value}) async {
    await ref.read(appPreferencesProvider).setBool(_keepAwakeKey, value: value);
    state = value;
  }
}

