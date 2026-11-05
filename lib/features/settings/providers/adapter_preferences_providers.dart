import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/features/settings/data/repositories/adapter_env_overrides_repository.dart';
import 'package:control_center/features/settings/data/services/adapter_preferences.dart';
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
