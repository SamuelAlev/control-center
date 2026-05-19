import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/features/settings/data/repositories/adapter_env_overrides_repository.dart';
import 'package:control_center/features/settings/data/services/adapter_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provides the [AdapterPreferences] instance backed by [AppPreferences].
final adapterPreferencesProvider = Provider<AdapterPreferences>((ref) {
  return AdapterPreferences(ref.watch(appPreferencesProvider));
});

/// Provides the [AdapterEnvOverridesRepository] over the platform secure store.
final adapterEnvOverridesRepositoryProvider =
    Provider<AdapterEnvOverridesRepository>((ref) {
  return AdapterEnvOverridesRepository(ref.watch(secureStoreProvider));
});

/// The per-adapter env-override map for [adapterId], read from the secure
/// store. Mutations go through [AdapterEnvOverridesRepository]; call
/// `ref.invalidate(adapterEnvOverridesProvider(adapterId))` to refresh.
final adapterEnvOverridesProvider =
    FutureProvider.family<Map<String, String>, String>((ref, adapterId) {
  return ref.watch(adapterEnvOverridesRepositoryProvider).getFor(adapterId);
});

/// The per-adapter argv override for [adapterId] (YOLO/skip-perms), from prefs.
/// Mutations go through [AdapterPreferences]; call
/// `ref.invalidate(adapterArgsProvider(adapterId))` to refresh.
final adapterArgsProvider = FutureProvider.family<String?, String>((
  ref,
  adapterId,
) {
  return ref.read(adapterPreferencesProvider).getAdapterArgs(adapterId);
});

// ---------------------------------------------------------------------------
// Default Chat Adapter + Model
// ---------------------------------------------------------------------------

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

// ---------------------------------------------------------------------------
// Short Task Adapter + Model
// ---------------------------------------------------------------------------

/// Manages the persisted short-task adapter id.
class ShortTaskAdapterNotifier extends Notifier<String?> {
  @override
  String? build() {
    return ref.read(adapterPreferencesProvider).getShortTaskAdapterId();
  }

  /// Persists a new short-task adapter id.
  Future<void> set(String? value) async {
    await ref.read(adapterPreferencesProvider).setShortTaskAdapterId(value);
    state = value;
  }
}

/// Read/write provider for the short-task adapter id.
final shortTaskAdapterProvider =
    NotifierProvider<ShortTaskAdapterNotifier, String?>(
      ShortTaskAdapterNotifier.new,
    );

/// Manages the persisted short-task model id.
class ShortTaskModelNotifier extends Notifier<String?> {
  @override
  String? build() {
    return ref.read(adapterPreferencesProvider).getShortTaskModelId();
  }

  /// Persists a new short-task model id.
  Future<void> set(String? value) async {
    await ref.read(adapterPreferencesProvider).setShortTaskModelId(value);
    state = value;
  }
}

/// Read/write provider for the short-task model id.
final shortTaskModelProvider =
    NotifierProvider<ShortTaskModelNotifier, String?>(
      ShortTaskModelNotifier.new,
    );
