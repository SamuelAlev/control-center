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
  /// A list of strings and `{if, args}` objects is argv, a string is shell, and
  /// `{"shell": "…"}` or `{"script": [...]}` is shell.
  factory EnvironmentCommand.fromJson(Object? json, {required String path}) {
    if (json is String) {
      if (json.trim().isEmpty) {
        throw FormatException('$path must not be empty');
      }
      return ShellEnvironmentCommand(json);
    }
    if (json is List) {
      return ArgvEnvironmentCommand([
        for (final (index, item) in json.indexed)
          EnvironmentArgvItem.fromJson(item, path: '$path[$index]'),
      ]);
    }
    if (json is Map) {
      final shell = json['shell'];
      if (shell is String) {
        return EnvironmentCommand.fromJson(shell, path: '$path.shell');
      }
      final script = json['script'];
      if (script is List) {
        return ShellEnvironmentCommand(script.join('\n'));
      }
    }
    throw FormatException('$path must be an argv array or a shell string');
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

  /// Parses one entry.
  factory EnvironmentArgvItem.fromJson(Object? json, {required String path}) {
    if (json is String) {
      return EnvironmentArgvItem.plain(json);
    }
    if (json is Map && json['if'] is String && json['args'] is List) {
      return EnvironmentArgvItem.conditional(
        condition: json['if'] as String,
        args: [for (final arg in json['args'] as List) '$arg'],
      );
    }
    throw FormatException('$path must be a string or {if, args}');
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
