import 'package:cc_domain/features/model_routing/domain/entities/model_info.dart';
import 'package:collection/collection.dart';

/// Why a provider is (or is not) usable — the `enabled` discriminated
/// union. The UI uses this to say *"Claude disabled — set ANTHROPIC_API_KEY or
/// log in"* instead of silently hiding the provider.
sealed class ProviderEnablement {
  /// Const base constructor.
  const ProviderEnablement();

  /// Whether the provider is usable.
  bool get isEnabled => this is! ProviderDisabled;
}

/// The provider has no usable credential.
class ProviderDisabled extends ProviderEnablement {
  /// Creates a [ProviderDisabled].
  const ProviderDisabled({this.missingEnv = const []});

  /// Env var names that, if set, would enable the provider (for the hint).
  final List<String> missingEnv;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProviderDisabled &&
          const ListEquality<String>().equals(missingEnv, other.missingEnv);

  @override
  int get hashCode => const ListEquality<String>().hash(missingEnv);
}

/// Enabled because an environment variable is set.
class ProviderEnabledViaEnv extends ProviderEnablement {
  /// Creates a [ProviderEnabledViaEnv].
  const ProviderEnabledViaEnv(this.name);

  /// The env var name that satisfied it (e.g. `ANTHROPIC_API_KEY`).
  final String name;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProviderEnabledViaEnv && name == other.name;

  @override
  int get hashCode => name.hashCode;
}

/// Enabled because an account / login session exists.
class ProviderEnabledViaAccount extends ProviderEnablement {
  /// Creates a [ProviderEnabledViaAccount].
  const ProviderEnabledViaAccount(this.service);

  /// The auth service that provided the account (e.g. `anthropic-oauth`).
  final String service;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProviderEnabledViaAccount && service == other.service;

  @override
  int get hashCode => service.hashCode;
}

/// Enabled through a custom, app-specific mechanism.
class ProviderEnabledViaCustom extends ProviderEnablement {
  /// Creates a [ProviderEnabledViaCustom].
  const ProviderEnabledViaCustom(this.data);

  /// Opaque custom payload.
  final Map<String, dynamic> data;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProviderEnabledViaCustom &&
          const DeepCollectionEquality().equals(data, other.data);

  @override
  int get hashCode => const DeepCollectionEquality().hash(data);
}

/// A model provider (e.g. Anthropic, OpenAI, Google) and its enablement state.
class ModelProvider {
  /// Creates a [ModelProvider].
  const ModelProvider({
    required this.id,
    required this.name,
    this.description,
    this.envKeys = const [],
    this.docUrl,
    this.npm,
    this.enablement = const ProviderDisabled(),
  });

  /// Stable provider id (e.g. `anthropic`).
  final String id;

  /// Human-readable name.
  final String name;

  /// Optional description.
  final String? description;

  /// Env var names that authenticate this provider, in priority order.
  final List<String> envKeys;

  /// Documentation URL, if any.
  final String? docUrl;

  /// The provider's SDK npm package name, if documented (informational).
  final String? npm;

  /// Why the provider is / isn't usable.
  final ProviderEnablement enablement;

  /// Whether the provider is usable.
  bool get isEnabled => enablement.isEnabled;

  /// Returns a copy with a new enablement state.
  ModelProvider withEnablement(ProviderEnablement enablement) => ModelProvider(
    id: id,
    name: name,
    description: description,
    envKeys: envKeys,
    docUrl: docUrl,
    npm: npm,
    enablement: enablement,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ModelProvider &&
          id == other.id &&
          name == other.name &&
          enablement == other.enablement;

  @override
  int get hashCode => Object.hash(id, name, enablement);

  @override
  String toString() => 'ModelProvider($id, enabled=$isEnabled)';
}

/// A provider together with its models, the catalog's per-provider record.
class ProviderEntry {
  /// Creates a [ProviderEntry].
  const ProviderEntry({required this.provider, required this.models});

  /// The provider.
  final ModelProvider provider;

  /// Models keyed by [ModelInfo.id].
  final Map<String, ModelInfo> models;
}
