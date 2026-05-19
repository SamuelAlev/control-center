import 'package:cc_domain/features/dispatch/domain/ports/agent_backend.dart';
import 'package:cc_domain/features/settings/domain/entities/adapter.dart';
import 'package:cc_infra/src/dispatch/acp/acp_client.dart' show AcpClient;

/// Backend for ACP-native adapters (OpenCode, Gemini, Goose, Cursor, Codex).
///
/// It is a stateless config holder: the dispatch session spawns
/// `<cliPath> <acpArgs> <argsOverride>` per dispatch and drives the ACP
/// handshake via [AcpClient] (process state lives in the session, mirroring
/// how the claude-relay path works). One [AcpBackend] instance serves every
/// ACP adapter; it carries only the per-adapter invocation + env.
class AcpBackend implements AgentBackend {
  /// Creates an [AcpBackend].
  const AcpBackend({
    required this.cliName,
    this.acpArgs,
    this.defaultEnvironment = const {},
  });

  @override
  final String cliName;

  @override
  final String? acpArgs;

  /// Per-adapter default env (e.g. `{'GOOSE_MODE': 'auto'}` for Goose).
  final Map<String, String> defaultEnvironment;

  @override
  AdapterTransport get transport => AdapterTransport.acp;

  /// ACP args live in [acpArgs] / the protocol, so the extra argv after the
  /// binary are empty here (per-adapter overrides are appended by the session).
  @override
  List<String> buildArgs({String? modelId, String? effortLevel}) => const [];

  @override
  Map<String, String> defaultEnv() => defaultEnvironment;
}
