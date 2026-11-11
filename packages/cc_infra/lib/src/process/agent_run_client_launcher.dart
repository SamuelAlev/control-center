import 'dart:io';
import 'dart:isolate';

import 'package:path/path.dart' as p;

/// How a run's shims start the agent run client
/// (`package:cc_infra/agent_run_client.dart`).
///
/// A compiled server is its own client (`cc_server agent-run <verb> …`). A
/// server run from source, and every test, runs the client's entry file
/// (`packages/cc_infra/bin/agent_run_client.dart`) on the same Dart VM.
final class AgentRunClientLauncher {
  /// Creates a launcher that runs [command] followed by the verb, from
  /// [files].
  const AgentRunClientLauncher({required this.command, required this.files});

  /// The launcher for this process. See [AgentRunClientLauncher].
  static final AgentRunClientLauncher current = _resolve();

  /// The argv every verb follows. Its first entry is an absolute path.
  final List<String> command;

  /// Every file [command] runs from. Every sandbox may execute the first
  /// and none may change any of them: another run's hook runs them.
  final List<String> files;

  /// [command] as `sh` words, each quoted (paths contain spaces).
  String get shellCommand => command.map(shellQuote).join(' ');

  /// [value] as one single-quoted `sh` word.
  static String shellQuote(String value) =>
      "'${value.replaceAll("'", r"'\''")}'";

  static AgentRunClientLauncher _resolve() {
    final executable = Platform.resolvedExecutable;
    // An AOT-compiled server is a product build; `dart run` and tests are not.
    if (const bool.fromEnvironment('dart.vm.product')) {
      return AgentRunClientLauncher(
        command: [executable, 'agent-run'],
        files: [executable],
      );
    }
    Uri? library;
    try {
      library = Isolate.resolvePackageUriSync(
        Uri.parse('package:cc_infra/agent_run_client.dart'),
      );
    } on UnsupportedError {
      // The Flutter engine resolves no package URIs: no client from here.
    }
    if (library == null || library.scheme != 'file') {
      throw StateError(
        'The agent run client cannot be found: this process resolves no '
        'package:cc_infra.',
      );
    }
    final source = library.toFilePath();
    final entry = p.join(
      p.dirname(p.dirname(source)),
      'bin',
      'agent_run_client.dart',
    );
    return AgentRunClientLauncher(
      command: [executable, entry],
      files: [executable, entry, source],
    );
  }
}
