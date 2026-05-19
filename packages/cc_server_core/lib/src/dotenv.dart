import 'dart:io';

/// The process environment, with a `.env` file layered UNDER it.
///
/// The server finds this file BY ITSELF. No client tells it where to look: a
/// desktop that passed a working directory down would be a client that knows
/// what a `.env` is, and the same server has to work when nothing spawned it.
///
/// A real environment variable always WINS over the file: `docker run -e` and a
/// systemd `Environment=` are deliberate, a file lying in a directory is
/// ambient.
///
/// [processEnvironment], [executable] and [workingDirectory] are injection
/// points for tests.
Map<String, String> environmentWithDotenv({
  Map<String, String>? processEnvironment,
  String? executable,
  Directory? workingDirectory,
}) => {
  ...readDotenv(
    directory: locateDotenvDirectory(
      executable: executable,
      workingDirectory: workingDirectory,
    ),
  ),
  ...processEnvironment ?? Platform.environment,
};

/// Where this server's `.env` lives, or null when it has none.
///
/// Three places, in order, each corresponding to a way somebody actually runs
/// this binary:
///
///  1. **The working directory** — `docker run -w`, a systemd
///     `WorkingDirectory=`, or `dart run` from a checkout.
///  2. **Beside the executable** — an operator who unpacked the server archive
///     and dropped a `.env` next to it. Deliberate placement, so it is taken
///     at face value.
///  3. **A source checkout above the executable** — the dev case, where the
///     binary sits at `<repo>/apps/cc_server/build/cli/<arch>/bundle/bin/`.
///     The walk only accepts a directory that ALSO looks like a checkout
///     (`.git` or `pubspec.yaml`), so a packaged app buried under
///     `/Applications` can never pick up a stray file on the way to the root.
Directory? locateDotenvDirectory({
  String? executable,
  Directory? workingDirectory,
}) {
  bool hasEnv(Directory dir) =>
      File('${dir.path}${Platform.pathSeparator}.env').existsSync();

  final cwd = workingDirectory ?? Directory.current;
  if (hasEnv(cwd)) {
    return cwd;
  }

  Directory dir;
  try {
    dir = File(executable ?? Platform.resolvedExecutable).parent;
  } on Object {
    return null;
  }
  if (hasEnv(dir)) {
    return dir;
  }

  // Bounded: deep enough for `apps/cc_server/build/cli/<arch>/bundle/bin`,
  // shallow enough that this cannot wander a whole filesystem.
  for (var hop = 0; hop < 10; hop++) {
    final parent = dir.parent;
    if (parent.path == dir.path) {
      return null;
    }
    dir = parent;
    final marker =
        Directory('${dir.path}${Platform.pathSeparator}.git').existsSync() ||
        File('${dir.path}${Platform.pathSeparator}pubspec.yaml').existsSync();
    if (marker && hasEnv(dir)) {
      return dir;
    }
  }
  return null;
}

/// Parses `<directory>/.env`, or an empty map when [directory] is null, absent
/// or unreadable.
///
/// One key/value per line, and a value may be quoted. Inside double quotes
/// `\n` decodes to a newline, which is what lets a PEM private key — the one
/// value here that is not a flat token — live on a single line:
///
/// ```
/// GITHUB_APP_PRIVATE_KEY="-----BEGIN RSA PRIVATE KEY-----\nMIIEow…\n-----END…"
/// ```
///
/// Single quotes are literal (no escapes), matching every other dotenv reader.
/// An unquoted value is the rest of its line, trimmed. An empty value reads as
/// absent, so `KEY=` in a copied template does not shadow a built-in default.
Map<String, String> readDotenv({Directory? directory}) {
  final parsed = <String, String>{};
  if (directory == null) {
    return parsed;
  }
  try {
    final file = File('${directory.path}${Platform.pathSeparator}.env');
    if (!file.existsSync()) {
      return parsed;
    }
    for (final raw in file.readAsLinesSync()) {
      final line = raw.trimLeft();
      if (line.isEmpty || line.startsWith('#')) {
        continue;
      }
      final eq = line.indexOf('=');
      if (eq <= 0) {
        continue;
      }
      final value = _value(line.substring(eq + 1).trim());
      if (value.isNotEmpty) {
        parsed[line.substring(0, eq).trim()] = value;
      }
    }
  } on Object {
    // Unreadable or malformed: callers fall back to the process environment,
    // then to whatever the build ships. A `.env` is a convenience, never a
    // dependency of booting.
  }
  return parsed;
}

/// Unwraps one quoted value, decoding `\n` inside double quotes.
String _value(String raw) {
  if (raw.length >= 2 && raw.startsWith("'") && raw.endsWith("'")) {
    return raw.substring(1, raw.length - 1);
  }
  if (raw.length >= 2 && raw.startsWith('"') && raw.endsWith('"')) {
    return raw
        .substring(1, raw.length - 1)
        .replaceAll(r'\n', '\n')
        .replaceAll(r'\"', '"');
  }
  return raw;
}
