part of '../remote_rpc_catalog.dart';

/// The custom-provider definitions stored in [creds], when the store can
/// enumerate them (empty for stores that can't, e.g. an env-only store).
Future<List<ProviderCredential>> _customProviderDefs(
  ProviderCredentialStore creds,
) async {
  if (creds is! CustomProviderLister) {
    return const [];
  }
  return (creds as CustomProviderLister).customProviders();
}

/// The stored definition of the custom provider [providerId], or null when
/// [providerId] is a built-in or unknown provider.
Future<ProviderCredential?> _customProviderDef(
  ProviderCredentialStore creds,
  String providerId,
) async {
  if (harnessProviderMetas.containsKey(providerId)) {
    return null;
  }
  for (final def in await _customProviderDefs(creds)) {
    if (def.providerId == providerId) {
      return def;
    }
  }
  return null;
}

/// Throws unless [providerId] is a built-in or a stored custom provider — the
/// same existence gate `providers.saveGenerationDefaults` applies.
Future<void> _requireKnownProvider(
  ProviderCredentialStore creds,
  String providerId,
) async {
  if (harnessProviderMetas.containsKey(providerId)) {
    return;
  }
  final known = {
    for (final def in await _customProviderDefs(creds)) def.providerId,
  };
  if (!known.contains(providerId)) {
    throw ArgumentError('Unknown provider "$providerId".');
  }
}

/// Accepts a bare model id or the qualified `<providerId>/<modelId>` form and
/// returns the bare id. A qualified id naming a DIFFERENT provider is
/// rejected: silently filing the override under another provider's model is
/// worse than an error.
String _bareModelId(String providerId, String raw) {
  final id = raw.trim();
  if (id.isEmpty) {
    throw ArgumentError('model_id must not be empty.');
  }
  final slash = id.indexOf('/');
  if (slash < 0) {
    return id;
  }
  if (id.substring(0, slash) != providerId) {
    throw ArgumentError(
      'model_id "$id" does not belong to provider "$providerId".',
    );
  }
  final bare = id.substring(slash + 1);
  if (bare.isEmpty) {
    throw ArgumentError('model_id must not be empty.');
  }
  return bare;
}

/// Parses the `providers.saveModelOverride` / `providers.addCustom` model
/// fields into a [ProviderModelOverride], validating ranges and the modality
/// vocabulary. Absent fields stay null/empty ("inherit").
ProviderModelOverride _modelOverrideFromArgs(
  Map<String, dynamic> args, {
  bool manual = false,
}) {
  int? intArg(String key) {
    final raw = args[key];
    if (raw == null) {
      return null;
    }
    if (raw is! num) {
      throw ArgumentError('$key must be a number.');
    }
    final value = raw.toInt();
    if (value <= 0) {
      throw ArgumentError('$key must be positive.');
    }
    return value;
  }

  List<String> modalitiesArg(String key) {
    final raw = args[key];
    if (raw == null) {
      return const [];
    }
    if (raw is! List) {
      throw ArgumentError('$key must be a list of modality names.');
    }
    return [
      for (final v in raw)
        if (v is! String || !ProviderModelOverride.knownModalities.contains(v))
          throw ArgumentError(
            '$key entries must be one of '
            '${ProviderModelOverride.knownModalities.join(', ')}.',
          )
        else
          v,
    ];
  }

  return ProviderModelOverride(
    contextWindow: intArg('context_window'),
    maxOutputTokens: intArg('max_output_tokens'),
    inputModalities: modalitiesArg('input_modalities'),
    outputModalities: modalitiesArg('output_modalities'),
    manual: manual || (args['manual'] as bool? ?? false),
  );
}
