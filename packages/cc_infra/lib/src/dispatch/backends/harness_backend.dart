import 'package:cc_domain/features/dispatch/domain/ports/agent_backend.dart';
import 'package:cc_domain/features/settings/domain/entities/adapter.dart';

/// Backend for Control Center's built-in agent loop.
///
/// Unlike the CLI/ACP backends, the harness spawns no external process — the
/// dispatch session runs the agent loop in-process when it sees
/// [AdapterTransport.harness]. This backend is therefore a pure marker: it
/// declares the transport and contributes no argv or env.
class HarnessBackend implements AgentBackend {
  /// Creates a [HarnessBackend] for [cliName].
  const HarnessBackend({this.cliName = 'cc-harness'});

  @override
  final String cliName;

  @override
  AdapterTransport get transport => AdapterTransport.harness;

  @override
  String? get acpArgs => null;

  @override
  List<String> buildArgs({String? modelId, String? effortLevel}) => const [];

  @override
  Map<String, String> defaultEnv() => const {};
}
