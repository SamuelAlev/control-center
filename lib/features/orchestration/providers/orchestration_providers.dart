import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/features/orchestration/domain/entities/orchestration.dart';
import 'package:cc_domain/features/orchestration/domain/repositories/orchestration_repository.dart';
import 'package:cc_domain/features/orchestration/domain/services/orchestration_proposal_validator.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/ticketing/providers/ticketing_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The [OrchestrationRepository] the UI reads through — flipped to the cc_data
/// RpcX adapter over the desktop's in-process RPC server (the composition
/// flip). Server-side use-cases/listeners/bodies and the MCP `propose_*` tool
/// use the Dao-backed `daoOrchestrationRepositoryProvider` (`di/providers.dart`)
/// directly, to stay on the DB and avoid cycling through `rpcClientProvider`.
final orchestrationRepositoryProvider = Provider<OrchestrationRepository>(
  (ref) => RpcOrchestrationRepository(ref.watch(rpcClientProvider)),
);

/// Provides the deterministic proposal validator, wired to the shared schema
/// validator so declared output schemas are checked for well-formedness.
final orchestrationProposalValidatorProvider =
    Provider<OrchestrationProposalValidator>(
  (ref) => OrchestrationProposalValidator(
    schemaValidator: ref.watch(schemaValidatorProvider),
  ),
);

/// Watches a single orchestration by id within [workspaceId].
final orchestrationProvider =
    StreamProvider.family<Orchestration?, ({String workspaceId, String id})>(
  (ref, args) => ref
      .watch(orchestrationRepositoryProvider)
      .watchById(args.workspaceId, args.id),
);

/// Watches all orchestrations in a workspace, newest first.
final workspaceOrchestrationsProvider =
    StreamProvider.family<List<Orchestration>, String>(
  (ref, workspaceId) => ref
      .watch(orchestrationRepositoryProvider)
      .watchForWorkspace(workspaceId),
);

/// Live child sub-tickets of an orchestration's parent ticket (for in-bubble
/// progress). Derived from the workspace ticket stream filtered by parent.
final orchestrationChildTicketsProvider = StreamProvider.family<List<Ticket>,
    ({String workspaceId, String parentTicketId})>(
  (ref, args) => ref
      .watch(ticketRepositoryProvider)
      .watchForWorkspace(args.workspaceId)
      .map((tickets) => tickets
          .where((t) => t.parentTicketId == args.parentTicketId)
          .toList()),
);
