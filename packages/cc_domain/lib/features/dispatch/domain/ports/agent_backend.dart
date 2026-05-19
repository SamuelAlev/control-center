import 'package:cc_domain/features/settings/domain/entities/adapter.dart';

/// Interface for agent execution backends. The [BackendRegistry] maps a CLI
/// name to one [AgentBackend]; the dispatch session resolves the backend for
/// a run and asks it for its argv / env, then drives execution based on the
/// backend's [transport].
///
/// Backends are stateless config holders: they build argv and declare default
/// env. Process lifecycle (sandbox exec, claude-relay, ACP subprocess) is
/// owned by the dispatch session, which switches on [transport].
abstract interface class AgentBackend {
  /// The CLI name this backend handles (e.g. 'pi', 'claude', 'gemini').
  String get cliName;

  /// How this backend's CLI is driven.
  AdapterTransport get transport;

  /// Extra argv appended after the CLI binary to enter the adapter's ACP mode
  /// (e.g. `'acp'`, `'--acp'`). Non-null only for ACP backends.
  String? get acpArgs;

  /// Builds argv[1..] (everything after the binary path) for this backend,
  /// given the resolved model + effort level. The structured-CLI backend
  /// returns its `--mode json` / `--model` / constraint argv; ACP backends
  /// return `[]` (their args live in [acpArgs] / the protocol).
  List<String> buildArgs({String? modelId, String? effortLevel});

  /// Default env this backend contributes (e.g. `GOOSE_MODE=auto`). Merged
  /// under the caller / broker env; an explicit per-adapter override wins.
  Map<String, String> defaultEnv();
}

/// Maps CLI names to their [AgentBackend]. The dispatch session resolves a
/// backend via [backendFor]; an unknown CLI name returns null and the session
/// emits a clear error rather than throwing.
class BackendRegistry {
  /// Creates a [BackendRegistry] from an explicit [cliName → backend] map.
  BackendRegistry(this._backends);

  final Map<String, AgentBackend> _backends;

  /// Returns the backend for [cliName], or null when no backend is registered.
  AgentBackend? backendFor(String cliName) => _backends[cliName];

  /// Whether a backend is registered for [cliName].
  bool handles(String cliName) => _backends.containsKey(cliName);
}

