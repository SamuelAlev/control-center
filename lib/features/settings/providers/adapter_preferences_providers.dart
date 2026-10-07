import 'package:cc_domain/features/settings/domain/services/short_task_runner.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/features/settings/data/repositories/adapter_env_overrides_repository.dart';
import 'package:control_center/features/settings/data/services/adapter_preferences.dart';
import 'package:control_center/features/settings/providers/workspace_settings_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provides the [AdapterPreferences] instance backed by `AppPreferences`.
final adapterPreferencesProvider = Provider<AdapterPreferences>((ref) {
  return AdapterPreferences(ref.watch(appPreferencesProvider));
});

/// Provides the [AdapterEnvOverridesRepository] over the platform secure store.
final adapterEnvOverridesRepositoryProvider =
    Provider<AdapterEnvOverridesRepository>((ref) {
      return AdapterEnvOverridesRepository(ref.watch(secureStoreProvider));
    });

/// The per-adapter env-override map for the given adapter id, read from the secure
/// store. Mutations go through [AdapterEnvOverridesRepository]; call
/// `ref.invalidate(adapterEnvOverridesProvider(adapterId))` to refresh.
final adapterEnvOverridesProvider =
    FutureProvider.family<Map<String, String>, String>((ref, adapterId) {
      return ref.watch(adapterEnvOverridesRepositoryProvider).getFor(adapterId);
    });

/// The per-adapter argv override for the given adapter id (YOLO/skip-perms), from prefs.
/// Mutations go through [AdapterPreferences]; call
/// `ref.invalidate(adapterArgsProvider(adapterId))` to refresh.
final adapterArgsProvider = FutureProvider.family<String?, String>((
  ref,
  adapterId,
) {
  return ref.read(adapterPreferencesProvider).getAdapterArgs(adapterId);
});

// Default Chat Adapter + Model

/// Manages the persisted default chat adapter id.
class DefaultChatAdapterNotifier extends Notifier<String?> {
  @override
  String? build() {
    return ref.read(adapterPreferencesProvider).getDefaultChatAdapterId();
  }

  /// Persists a new default chat adapter id.
  Future<void> set(String? value) async {
    await ref.read(adapterPreferencesProvider).setDefaultChatAdapterId(value);
    state = value;
  }
}

/// Read/write provider for the default chat adapter id.
final defaultChatAdapterProvider =
    NotifierProvider<DefaultChatAdapterNotifier, String?>(
      DefaultChatAdapterNotifier.new,
    );

/// Manages the persisted default chat model id.
class DefaultChatModelNotifier extends Notifier<String?> {
  @override
  String? build() {
    return ref.read(adapterPreferencesProvider).getDefaultChatModelId();
  }

  /// Persists a new default chat model id.
  Future<void> set(String? value) async {
    await ref.read(adapterPreferencesProvider).setDefaultChatModelId(value);
    state = value;
  }
}

/// Read/write provider for the default chat model id.
final defaultChatModelProvider =
    NotifierProvider<DefaultChatModelNotifier, String?>(
      DefaultChatModelNotifier.new,
    );

// Short Task Adapter + Model

/// One `workspace_settings` key as a read/write string, for the short-task
/// runner pair.
///
/// Unlike the default chat runner the short-task runner is NOT a device
/// preference: it names conversations every member reads and the server runs
/// it, so it is admin-gated workspace state the server reads at run time.
abstract class _WorkspaceSettingNotifier extends Notifier<String?> {
  String get _key;

  @override
  String? build() => _nonEmpty(ref.watch(workspaceSettingProvider(_key)));

  /// Persists [value] to the active workspace. Null (rather than an empty
  /// string) deletes the row, so "unset" is the absence of a setting.
  /// Admin-gated server-side by `workspace_settings.set`.
  Future<void> set(String? value) async {
    final workspaceId = ref.read(activeWorkspaceIdProvider);
    if (workspaceId == null) {
      return;
    }
    final normalized = _nonEmpty(value);
    await ref
        .read(workspaceSettingsRepositoryProvider)
        .set(workspaceId, _key, normalized);
    state = normalized;
  }
}

/// The workspace's short-task adapter — the one-shot runner behind
/// conversation titles, side questions and the `/goal` interview. Null means
/// short tasks are off.
class ShortTaskAdapterNotifier extends _WorkspaceSettingNotifier {
  @override
  String get _key => kShortTaskAdapterSettingKey;
}

/// Read/write provider for the workspace's short-task adapter id.
final shortTaskAdapterProvider =
    NotifierProvider<ShortTaskAdapterNotifier, String?>(
      ShortTaskAdapterNotifier.new,
    );

/// The model [shortTaskAdapterProvider]'s adapter runs short tasks on — a
/// qualified `provider/model` id for `cc-harness`, whatever the CLI advertises
/// otherwise. Null lets the adapter pick its own default.
class ShortTaskModelNotifier extends _WorkspaceSettingNotifier {
  @override
  String get _key => kShortTaskModelSettingKey;
}

/// Read/write provider for the workspace's short-task model id.
final shortTaskModelProvider =
    NotifierProvider<ShortTaskModelNotifier, String?>(
      ShortTaskModelNotifier.new,
    );

String? _nonEmpty(String? raw) {
  final trimmed = raw?.trim();
  return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
}
