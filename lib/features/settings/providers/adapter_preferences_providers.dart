import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/features/settings/data/services/adapter_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart' show SharedPreferences;

/// Provides the [AdapterPreferences] instance backed by [SharedPreferences].
final adapterPreferencesProvider = Provider<AdapterPreferences>((ref) {
  return AdapterPreferences(ref.watch(sharedPreferencesProvider));
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
