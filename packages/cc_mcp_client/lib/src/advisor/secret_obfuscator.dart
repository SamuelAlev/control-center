/// Redacts known secrets from text before it is shown to the advisor model.
///
/// The advisor is a *second* LLM; the primary transcript may carry tokens,
/// keys, and passwords (in tool args, env dumps, command output). This walks
/// text and replaces any registered secret literal — plus values that match
/// common high-entropy credential patterns — with `‹redacted›`, without
/// mutating the live primary transcript.
class SecretObfuscator {
  /// Creates a [SecretObfuscator] seeded with known secret [literals].
  SecretObfuscator({Set<String> literals = const {}})
    : _literals = {...literals.where((s) => s.trim().length >= 6)};

  final Set<String> _literals;

  /// Patterns for common credential shapes (bearer tokens, GitHub PATs, AWS
  /// keys, generic `key=value` secrets) redacted even when not registered.
  static final List<RegExp> _patterns = [
    RegExp(r'gh[pousr]_[A-Za-z0-9]{16,}'), // GitHub tokens
    RegExp(r'github_pat_[A-Za-z0-9_]{20,}'),
    RegExp(r'sk-[A-Za-z0-9]{20,}'), // OpenAI-style
    RegExp('AKIA[0-9A-Z]{16}'), // AWS access key id
    RegExp(r'xox[baprs]-[A-Za-z0-9-]{10,}'), // Slack
    RegExp('eyJ[A-Za-z0-9_-]{10,}\\.[A-Za-z0-9_-]{10,}\\.[A-Za-z0-9_-]{10,}'),
    RegExp(
      r'''(?<=(?:token|secret|password|api[_-]?key|authorization|bearer)["'\s:=]{1,4})[A-Za-z0-9._\-]{12,}''',
      caseSensitive: false,
    ),
  ];

  /// Placeholder substituted for any redacted value.
  static const String placeholder = '‹redacted›';

  /// Registers an additional secret to redact (e.g. a freshly minted token).
  void register(String secret) {
    if (secret.trim().length >= 6) {
      _literals.add(secret);
    }
  }

  /// Returns [input] with every known secret + pattern match redacted.
  String obfuscate(String input) {
    if (input.isEmpty) {
      return input;
    }
    var result = input;
    // Longest literals first so a token isn't partially masked by a substring.
    final literals = _literals.toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    for (final literal in literals) {
      if (literal.isEmpty) {
        continue;
      }
      result = result.replaceAll(literal, placeholder);
    }
    for (final pattern in _patterns) {
      result = result.replaceAll(pattern, placeholder);
    }
    return result;
  }
}
