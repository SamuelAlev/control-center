import 'package:cc_domain/features/dispatch/domain/ports/agent_backend.dart';
import 'package:cc_domain/features/settings/domain/entities/adapter.dart';
import 'package:cc_infra/src/dispatch/backends/acp_backend.dart';
import 'package:cc_infra/src/dispatch/backends/cli_backends.dart';

/// Builds the default [BackendRegistry] from [predefinedAdapters], mapping
/// every adapter's [Adapter.cliName] to the backend for its
/// [AdapterTransport]. One registry instance serves all dispatches; backends
/// are stateless config holders (per-dispatch process state lives in the
/// dispatch session).
BackendRegistry buildBackendRegistry({
  Iterable<Adapter>? adapters,
}) {
  final source = adapters ?? predefinedAdapters;
  final backends = <String, AgentBackend>{};
  for (final adapter in source) {
    if (backends.containsKey(adapter.cliName)) {
      continue;
    }
    backends[adapter.cliName] = _backendFor(adapter);
  }
  return BackendRegistry(backends);
}

AgentBackend _backendFor(Adapter adapter) {
  switch (adapter.transport) {
    case AdapterTransport.acp:
      return AcpBackend(
        cliName: adapter.cliName,
        acpArgs: adapter.acpArgs,
        // Goose runs in auto-approve mode via env rather than a flag.
        defaultEnvironment:
            adapter.cliName == 'goose' ? const {'GOOSE_MODE': 'auto'} : const {},
      );
    case AdapterTransport.structuredCli:
      return StructuredCliBackend(cliName: adapter.cliName);
    case AdapterTransport.relay:
      return RelayBackend(cliName: adapter.cliName);
  }
}
