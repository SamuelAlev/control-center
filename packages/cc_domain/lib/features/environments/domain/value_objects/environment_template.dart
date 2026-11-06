import 'package:collection/collection.dart';

/// Thrown when a template or condition names a value that does not exist.
class EnvironmentTemplateException implements Exception {
  /// Creates an [EnvironmentTemplateException].
  const EnvironmentTemplateException(this.message);

  /// Client-safe explanation.
  final String message;

  @override
  String toString() => message;

  @override
  bool operator ==(Object other) =>
      other is EnvironmentTemplateException && other.message == message;

  @override
  int get hashCode => message.hashCode;
}

/// The flat value table placeholders and conditions resolve against.
///
/// Keys are dotted paths exactly as written in a definition: `name`,
/// `repo.web_app`, `port.postgres.5432`, `opt.seed`. A missing key is a hard
/// error for a placeholder (a silently empty argument is how a command ends up
/// operating on the wrong thing) and simply false for a condition.
class EnvironmentValues {
  /// Creates [EnvironmentValues] from [values].
  const EnvironmentValues(this.values);

  /// No values at all.
  static const EnvironmentValues empty = EnvironmentValues({});

  /// The table.
  final Map<String, String> values;

  @override
  bool operator ==(Object other) =>
      other is EnvironmentValues &&
      const MapEquality<String, String>().equals(other.values, values);

  @override
  int get hashCode => const MapEquality<String, String>().hash(values);

  /// This table with [extra] layered on top.
  EnvironmentValues withAll(Map<String, String> extra) =>
      EnvironmentValues({...values, ...extra});

  static final RegExp _placeholder = RegExp(
    r'(?<!\{)\{([a-zA-Z_][a-zA-Z0-9_.\-]*)\}(?!\})',
  );

  /// Every placeholder named in [template].
  ///
  /// `{{…}}` is left alone: that is Docker's Go-template syntax, and a check
  /// command is entitled to use it.
  static Iterable<String> placeholdersIn(String template) =>
      _placeholder.allMatches(template).map((m) => m.group(1)!);

  /// Expands every placeholder in [template].
  ///
  /// Throws [EnvironmentTemplateException] on an unknown placeholder.
  String expand(String template) =>
      template.replaceAllMapped(_placeholder, (match) {
        final key = match.group(1)!;
        final value = values[key];
        if (value == null) {
          throw EnvironmentTemplateException('Unknown placeholder {$key}');
        }
        return value;
      });

  /// Evaluates a condition such as `opt.seed`, `!repo.web_app` or
  /// `opt.mode == desktop`.
  bool evaluate(String condition) {
    final text = condition.trim();
    final notEqual = text.indexOf('!=');
    if (notEqual > 0) {
      return (values[text.substring(0, notEqual).trim()] ?? '') !=
          text.substring(notEqual + 2).trim();
    }
    final equal = text.indexOf('==');
    if (equal > 0) {
      return (values[text.substring(0, equal).trim()] ?? '') ==
          text.substring(equal + 2).trim();
    }
    if (text.startsWith('!')) {
      return !_truthy(text.substring(1).trim());
    }
    return _truthy(text);
  }

  bool _truthy(String key) {
    final value = values[key];
    return value != null && value.isNotEmpty && value != 'false';
  }
}

/// The key a condition reads, with any negation or comparison removed.
String environmentConditionKey(String condition) {
  final text = condition.trim();
  for (final operator in const ['!=', '==']) {
    final index = text.indexOf(operator);
    if (index > 0) {
      return text.substring(0, index).trim();
    }
  }
  return text.startsWith('!') ? text.substring(1).trim() : text;
}
