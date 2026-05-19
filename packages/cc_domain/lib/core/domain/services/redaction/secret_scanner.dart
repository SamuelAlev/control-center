/// A single secret detected while scanning a value, naming where it was found
/// and why it was flagged.
class SecretFinding {
  /// Creates a [SecretFinding].
  const SecretFinding({required this.path, required this.reason});

  /// JSON-ish path to the offending string (e.g. `headers.authorization`,
  /// `interactions[0].response.body`).
  final String path;

  /// Human-readable reason (e.g. `bearer token`, `GitHub token`,
  /// `environment secret OPENAI_API_KEY`).
  final String reason;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SecretFinding && path == other.path && reason == other.reason;

  @override
  int get hashCode => Object.hash(path, reason);

  @override
  String toString() => '$path ($reason)';
}

/// A named credential pattern matched against string values.
class _SecretPattern {
  const _SecretPattern(this.label, this.pattern);
  final String label;
  final RegExp pattern;
}

/// Scans arbitrary JSON-ish values for credentials, returning a [SecretFinding]
/// for each match. Pure: it never reads the process environment itself — pass
/// in [environment] (e.g. `Platform.environment`) so the same scanner works in
/// both pure-Dart and platform contexts.
///
/// Detects Bearer tokens, OpenAI/Anthropic `sk-…` keys, Google `AIza…` keys,
/// AWS access keys, GitHub `gh[pousr]_…` tokens, PEM private-key blocks and —
/// crucially — values that match a secret-named environment variable, so a leak
/// of e.g. `$OPENAI_API_KEY` is caught even if the literal does not match a
/// known shape.
class SecretScanner {
  /// Creates a [SecretScanner].
  const SecretScanner({
    this.environment = const {},
    this.safeEnvValues = _defaultSafeEnvValues,
    this.minEnvValueLength = 12,
  });

  /// Environment variables to cross-check string values against. Empty disables
  /// env-secret detection.
  final Map<String, String> environment;

  /// Env values that are known-safe placeholders and must not trip the scanner
  /// (case-insensitive).
  final Set<String> safeEnvValues;

  /// Env values shorter than this are ignored (too short to be a real secret).
  final int minEnvValueLength;

  static const Set<String> _defaultSafeEnvValues = {
    'fixture',
    'test',
    'test-key',
  };

  static final RegExp _envSecretNames = RegExp(
    r'(?:API|AUTH|BEARER|CREDENTIAL|KEY|PASSWORD|SECRET|TOKEN)',
    caseSensitive: false,
  );

  static final List<_SecretPattern> _patterns = [
    _SecretPattern(
      'bearer token',
      RegExp(r'\bBearer\s+[A-Za-z0-9._~+/=-]{16,}', caseSensitive: false),
    ),
    _SecretPattern('Anthropic API key', RegExp(r'\bsk-ant-[A-Za-z0-9_-]{20,}')),
    _SecretPattern('API key', RegExp(r'\bsk-[A-Za-z0-9][A-Za-z0-9_-]{20,}')),
    _SecretPattern('Google API key', RegExp(r'\bAIza[0-9A-Za-z_-]{20,}')),
    _SecretPattern('AWS access key', RegExp(r'\b(?:AKIA|ASIA)[0-9A-Z]{16}\b')),
    _SecretPattern('GitHub token', RegExp(r'\bgh[pousr]_[A-Za-z0-9_]{20,}')),
    _SecretPattern(
      'private key',
      RegExp(r'-----BEGIN [A-Z ]*PRIVATE KEY-----'),
    ),
  ];

  /// Returns every [SecretFinding] in [value], walking maps, lists and strings.
  List<SecretFinding> scan(Object? value) {
    final findings = <SecretFinding>[];
    final envSecrets = _envSecrets();
    for (final entry in _stringEntries(value)) {
      for (final pattern in _patterns) {
        if (pattern.pattern.hasMatch(entry.value)) {
          findings.add(SecretFinding(path: entry.path, reason: pattern.label));
        }
      }
      for (final secret in envSecrets) {
        if (entry.value.contains(secret.value)) {
          findings.add(
            SecretFinding(
              path: entry.path,
              reason: 'environment secret ${secret.name}',
            ),
          );
        }
      }
    }
    return findings;
  }

  /// Whether [value] contains any secret.
  bool hasSecrets(Object? value) => scan(value).isNotEmpty;

  List<({String name, String value})> _envSecrets() {
    final result = <({String name, String value})>[];
    environment.forEach((name, value) {
      if (value.isEmpty) {
        return;
      }
      if (!_envSecretNames.hasMatch(name)) {
        return;
      }
      if (value.length < minEnvValueLength) {
        return;
      }
      if (safeEnvValues.contains(value.toLowerCase())) {
        return;
      }
      result.add((name: name, value: value));
    });
    return result;
  }

  Iterable<({String path, String value})> _stringEntries(
    Object? value, [
    String base = r'$',
  ]) sync* {
    if (value is String) {
      yield (path: base, value: value);
    } else if (value is List) {
      for (var i = 0; i < value.length; i++) {
        yield* _stringEntries(value[i], '$base[$i]');
      }
    } else if (value is Map) {
      for (final entry in value.entries) {
        yield* _stringEntries(entry.value, '$base.${entry.key}');
      }
    }
  }
}
