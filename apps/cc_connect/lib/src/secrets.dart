import 'dart:io';

/// How often a file-backed secret is re-read. A rotated Secret Manager
/// version mounted as a file is live within this window (plus the mount's own
/// propagation), well inside the 60-second rotation budget.
const Duration secretRefreshInterval = Duration(seconds: 30);

/// Reads a whole file as text. Injectable so tests never touch disk.
typedef SecretFileReader = String Function(String path);

String _readFromDisk(String path) => File(path).readAsStringSync();

/// A secret value from the environment (`NAME`) or from a mounted file
/// (`NAME_FILE`, the Docker / Cloud Run secret-volume convention).
///
/// File-backed values are re-read at most every [secretRefreshInterval]; a
/// failed re-read keeps the last good value so a briefly missing mount never
/// blanks a lane. Values are trimmed (secret files usually end in a newline).
final class SecretSource {
  SecretSource._({
    required this.name,
    required String inline,
    required this.path,
    required SecretFileReader readFile,
    required this._clock,
  }) : _value = inline.trim(),
       _reader = readFile;

  /// A fixed value (tests and programmatic embedding).
  factory SecretSource.value(String name, String value) => SecretSource._(
    name: name,
    inline: value,
    path: null,
    readFile: _readFromDisk,
    clock: DateTime.now,
  );

  /// The secret named [name] in [env], from `NAME` or `NAME_FILE`; null when
  /// neither is set. Throws [ArgumentError] when both are.
  static SecretSource? fromEnvironment(
    Map<String, String> env,
    String name, {
    SecretFileReader? readFile,
    DateTime Function()? clock,
  }) {
    final inline = env[name];
    final file = env['${name}_FILE'];
    final hasInline = inline != null && inline.trim().isNotEmpty;
    final hasFile = file != null && file.trim().isNotEmpty;
    if (hasInline && hasFile) {
      throw ArgumentError('set $name or ${name}_FILE, not both');
    }
    if (!hasInline && !hasFile) {
      return null;
    }
    final source = SecretSource._(
      name: name,
      inline: hasInline ? inline : '',
      path: hasFile ? file.trim() : null,
      readFile: readFile ?? _readFromDisk,
      clock: clock ?? DateTime.now,
    );
    if (hasFile) {
      source._reload(force: true);
    }
    return source;
  }

  /// The environment name, for operator-facing messages (never the value).
  final String name;

  /// The mounted file, when file-backed.
  final String? path;

  final SecretFileReader _reader;
  final DateTime Function() _clock;
  String _value;
  DateTime? _readAt;

  /// Whether the value comes from a file that is re-read.
  bool get isFileBacked => path != null;

  /// The current value; empty when a file has never been readable.
  String get value {
    _reload();
    return _value;
  }

  void _reload({bool force = false}) {
    final file = path;
    if (file == null) {
      return;
    }
    final now = _clock();
    final last = _readAt;
    if (!force &&
        last != null &&
        now.difference(last) < secretRefreshInterval) {
      return;
    }
    _readAt = now;
    try {
      _value = _reader(file).trim();
    } on Object {
      // Keep the last good value; the operator sees a lane go unavailable only
      // if the file was never readable.
    }
  }
}

/// A secret with a current and an optional previous generation, so a
/// rotation never races an in-flight refresh: new grants use [current] and
/// record [generation]; an upstream `invalid_client` during propagation is
/// retried once with [previous] ([previousGeneration]).
final class DualSecret {
  /// Creates the pair.
  const DualSecret({required this.current, this.previous, this.generation = 1});

  /// Reads `NAME` / `NAME_FILE`, `NAME_PREVIOUS` / `NAME_PREVIOUS_FILE` and
  /// the generation from [generationName] (default 1). Null when the current
  /// secret is not set.
  static DualSecret? fromEnvironment(
    Map<String, String> env,
    String name, {
    String? generationName,
    SecretFileReader? readFile,
    DateTime Function()? clock,
  }) {
    final current = SecretSource.fromEnvironment(
      env,
      name,
      readFile: readFile,
      clock: clock,
    );
    if (current == null) {
      return null;
    }
    final previous = SecretSource.fromEnvironment(
      env,
      '${name}_PREVIOUS',
      readFile: readFile,
      clock: clock,
    );
    var generation = 1;
    if (generationName != null) {
      final raw = env[generationName]?.trim() ?? '';
      if (raw.isNotEmpty) {
        final parsed = int.tryParse(raw);
        if (parsed == null || parsed < 1) {
          throw ArgumentError('$generationName must be a positive integer');
        }
        generation = parsed;
      }
    }
    return DualSecret(
      current: current,
      previous: previous,
      generation: generation,
    );
  }

  /// The active generation's secret.
  final SecretSource current;

  /// The previous generation's secret, kept during a rotation.
  final SecretSource? previous;

  /// The active generation number.
  final int generation;

  /// The previous generation number.
  int get previousGeneration => generation - 1;

  /// The active value; empty when unreadable.
  String get currentValue => current.value;

  /// The previous value, or null when none is configured or it is empty.
  String? get previousValue {
    final value = previous?.value ?? '';
    return value.isEmpty ? null : value;
  }

  /// Every non-empty value, current first.
  List<String> get values => [
    if (currentValue.isNotEmpty) currentValue,
    ?previousValue,
  ];
}
