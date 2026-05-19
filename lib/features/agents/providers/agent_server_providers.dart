// VM-only agent providers (server-side execution half of `agent_providers.dart`).
//
// The hire-agent use case writes agent rows + agent files locally, so it owns
// the local Drift `dao*` repository directly (not the RPC-flipped public repo,
// which would cycle through the in-process host). It is driven only by the MCP
// `hire_agent` tool and orchestration materialization — both server-side — so
// it lives here, never in the web graph. The web-safe UI providers (agent
// lists, detail, run-log/live-state derivations) stay in `agent_providers.dart`.
library;

import 'package:cc_infra/src/usecases/hire_agent_use_case.dart';
import 'package:control_center/di/server_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provides the shared [HireAgentUseCase] used by the hire tool and the
/// orchestration materializer.
///
/// Server-side EXECUTION (driven by the MCP `hire_agent` tool and orchestration
/// materialization), so it owns the DB directly via [daoAgentRepositoryProvider]
/// rather than routing the agent write through the RPC path (which would cycle:
/// registry → Rpc agent repo → rpcClient → MCP dispatcher → registry).
final hireAgentUseCaseProvider = Provider<HireAgentUseCase>((ref) {
  return HireAgentUseCase(
    repository: ref.watch(daoAgentRepositoryProvider),
    filesystem: ref.watch(workspaceFilesystemPortProvider),
  );
});
