import 'package:cc_domain/features/environments/domain/services/environment_definition_reader.dart';
import 'package:cc_domain/features/environments/domain/value_objects/environment_definition.dart';
import 'package:cc_domain/features/environments/domain/value_objects/environment_template.dart';
import 'package:collection/collection.dart';

/// What a definition asks CC to run.
///
/// [ArgvEnvironmentCommand] is the default: values never pass through a shell,
/// which removes a whole class of injection and works on Windows without bash.
/// [ShellEnvironmentCommand] is the escape hatch. Placeholders are NOT expanded
/// inside shell bodies: `${VAR}` would collide with `{VAR}`, and an option value
/// spliced into shell text is an injection. Shell reads `CC_ENV_*` instead.
sealed class EnvironmentCommand {
  const EnvironmentCommand();

  /// Parses the `command` / `script` / verb forms.
  ///
  /// Throws [EnvironmentDefinitionException] listing every issue.
  factory EnvironmentCommand.fromJson(Object? json, {required String path}) {
    final issues = <EnvironmentDefinitionIssue>[];
    final command = read(json, path, issues);
    if (command == null || issues.isNotEmpty) {
      throw EnvironmentDefinitionException(issues);
    }
    return command;
  }

  /// Reads the `command` / `script` / verb forms at [path] into [issues].
  ///
  /// A list of strings and `{if, args}` objects is argv, a string is shell, and
  /// `{"shell": "…"}` or `{"script": [...]}` is shell. Null when it can't be
  /// built.
  static EnvironmentCommand? read(
    Object? json,
    String path,
    List<EnvironmentDefinitionIssue> issues,
  ) {
    void add(String at, String message) =>
        issues.add(EnvironmentDefinitionIssue(at, message));
    if (json is String) {
      if (json.trim().isEmpty) {
        add(path, 'Must not be empty');
        return null;
      }
      return ShellEnvironmentCommand(json);
    }
    if (json is List) {
      if (json.isEmpty) {
        add(path, 'Must not be empty');
        return null;
      }
      final items = [
        for (final (index, item) in json.indexed)
          EnvironmentArgvItem.read(item, '$path[$index]', issues),
      ];
      return items.contains(null)
          ? null
          : ArgvEnvironmentCommand(items.cast<EnvironmentArgvItem>());
    }
    if (json is Map) {
      final reader = EnvironmentJsonReader.of(json, path, issues)!;
      final hasShell = reader.has('shell');
      final hasScript = reader.has('script');
      EnvironmentCommand? command;
      if (hasShell && hasScript) {
        reader.reportHere('Use shell or script, not both');
      } else if (hasShell) {
        final shell = reader.string('shell', nonEmpty: true);
        command = shell == null ? null : ShellEnvironmentCommand(shell);
      } else if (hasScript) {
        command = scriptLines(reader, 'script');
      } else {
        reader.reportHere('Needs shell or script');
      }
      reader.finish();
      return command;
    }
    add(path, 'Must be an argv array or a shell string');
    return null;
  }

  /// The `script` lines at [key] of [reader] as one shell command.
  static EnvironmentCommand? scriptLines(
    EnvironmentJsonReader reader,
    String key,
  ) {
    if (reader.raw(key) is String) {
      reader.report(key, 'Must be a list of lines. For one line, use command');
      return null;
    }
    final lines = reader.strings(key, nonEmpty: true);
    if (lines == null) {
      return null;
    }
    final body = lines.join('\n');
    if (body.trim().isEmpty) {
      reader.report(key, 'Must not be empty');
      return null;
    }
    return ShellEnvironmentCommand(body);
  }

  /// JSON form.
  Object toJson();

  /// Every string that may hold a placeholder.
  Iterable<String> get templates;

  /// Every condition this command evaluates.
  Iterable<String> get conditions;
}

/// An argv command.
class ArgvEnvironmentCommand extends EnvironmentCommand {
  /// Creates an [ArgvEnvironmentCommand].
  ArgvEnvironmentCommand(this.items) {
    if (items.isEmpty) {
      throw ArgumentError('An argv command needs at least one item');
    }
  }

  /// The parts, in order.
  final List<EnvironmentArgvItem> items;

  /// The final argv for [values].
  List<String> resolve(EnvironmentValues values) => [
    for (final item in items) ...item.resolve(values),
  ];

  @override
  Object toJson() => [for (final item in items) item.toJson()];

  @override
  Iterable<String> get templates =>
      items.expand((item) => item.args).toList(growable: false);

  @override
  Iterable<String> get conditions =>
      items.map((item) => item.condition).whereType<String>();

  @override
  bool operator ==(Object other) =>
      other is ArgvEnvironmentCommand &&
      const DeepCollectionEquality().equals(other.toJson(), toJson());

  @override
  int get hashCode => const DeepCollectionEquality().hash(toJson());
}

/// One argv entry: a plain argument, or arguments behind a condition.
class EnvironmentArgvItem {
  /// A plain argument.
  EnvironmentArgvItem.plain(String argument)
    : condition = null,
      args = [argument];

  /// Arguments included only when [condition] holds.
  EnvironmentArgvItem.conditional({
    required String this.condition,
    required this.args,
  });

  /// Reads one entry at [path] into [issues], or null.
  static EnvironmentArgvItem? read(
    Object? json,
    String path,
    List<EnvironmentDefinitionIssue> issues,
  ) {
    if (json is String) {
      return EnvironmentArgvItem.plain(json);
    }
    if (json is! Map) {
      issues.add(
        EnvironmentDefinitionIssue(path, 'Must be a string or {if, args}'),
      );
      return null;
    }
    final reader = EnvironmentJsonReader.of(json, path, issues)!;
    final condition = reader.string('if', required: true, nonEmpty: true);
    final args = reader.strings('args', required: true);
    reader.finish();
    if (condition == null || args == null) {
      return null;
    }
    return EnvironmentArgvItem.conditional(condition: condition, args: args);
  }

  /// The condition, or null for a plain argument.
  final String? condition;

  /// The argument templates.
  final List<String> args;

  /// The expanded arguments, empty when the condition fails.
  List<String> resolve(EnvironmentValues values) {
    final test = condition;
    if (test != null && !values.evaluate(test)) {
      return const [];
    }
    return [for (final arg in args) values.expand(arg)];
  }

  /// JSON form.
  Object toJson() {
    final test = condition;
    return test == null ? args.single : {'if': test, 'args': args};
  }

  @override
  bool operator ==(Object other) =>
      other is EnvironmentArgvItem &&
      const DeepCollectionEquality().equals(other.toJson(), toJson());

  @override
  int get hashCode => const DeepCollectionEquality().hash(toJson());
}

/// A shell command, run as `bash -lc`.
class ShellEnvironmentCommand extends EnvironmentCommand {
  /// Creates a [ShellEnvironmentCommand].
  ShellEnvironmentCommand(this.body) {
    if (body.trim().isEmpty) {
      throw ArgumentError('A shell command must not be empty');
    }
  }

  /// The script text, exactly as stored.
  final String body;

  @override
  Object toJson() => {'shell': body};

  @override
  Iterable<String> get templates => const [];

  @override
  Iterable<String> get conditions => const [];

  @override
  bool operator ==(Object other) =>
      other is ShellEnvironmentCommand &&
      const DeepCollectionEquality().equals(other.toJson(), toJson());

  @override
  int get hashCode => const DeepCollectionEquality().hash(toJson());
}
