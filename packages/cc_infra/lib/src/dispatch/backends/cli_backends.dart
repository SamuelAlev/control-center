import 'package:cc_domain/features/dispatch/domain/ports/agent_backend.dart';
import 'package:cc_domain/features/settings/domain/entities/adapter.dart';

/// Backend for the Pi CLI's structured NDJSON mode (`pi --mode json`). Driven
/// by the dispatch session's sandbox-exec path; this class only builds the
/// argv + declares its (empty) default env.
class StructuredCliBackend implements AgentBackend {
  /// Creates a [StructuredCliBackend].
  const StructuredCliBackend({
    required this.cliName,
    this.jsonModeConstraint = _defaultJsonConstraint,
  });

  @override
  final String cliName;

  @override
  AdapterTransport get transport => AdapterTransport.structuredCli;

  @override
  String? get acpArgs => null;

  /// The system-prompt constraint that makes Pi emit one JSON object per line.
  final String jsonModeConstraint;

  static const String _defaultJsonConstraint =
      'Output structured JSON events. Each line must be a valid JSON object.';

  @override
  List<String> buildArgs({String? modelId, String? effortLevel}) {
    final args = <String>['--mode', 'json'];
    if (modelId != null && modelId.isNotEmpty) {
      args.addAll(['--model', modelId]);
    }
    // Pi exposes reasoning via `--thinking <level>`.
    if (effortLevel != null && effortLevel.isNotEmpty) {
      args.addAll(['--thinking', effortLevel]);
    }
    args.addAll(['--append-system-prompt', jsonModeConstraint]);
    return args;
  }

  @override
  Map<String, String> defaultEnv() => const {};
}

/// Backend for Claude Code's in-app PTY relay. Driven by the dispatch
/// session's `_runClaudeRelay` path; this class only builds the relay argv +
/// declares its (empty) default env. Reasoning is passed as `--effort <level>`.
class RelayBackend implements AgentBackend {
  /// Creates a [RelayBackend].
  const RelayBackend({this.cliName = 'claude'});

  @override
  final String cliName;

  @override
  AdapterTransport get transport => AdapterTransport.relay;

  @override
  String? get acpArgs => null;

  @override
  List<String> buildArgs({String? modelId, String? effortLevel}) {
    final args = <String>[];
    if (modelId != null && modelId.isNotEmpty) {
      args.addAll(['--model', modelId]);
    }
    if (effortLevel != null && effortLevel.isNotEmpty) {
      args.addAll(['--effort', effortLevel]);
    }
    return args;
  }

  @override
  Map<String, String> defaultEnv() => const {};
}
