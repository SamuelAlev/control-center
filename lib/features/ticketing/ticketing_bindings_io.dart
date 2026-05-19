// Desktop (thin-client) bindings for the ticketing write/sync services declared
// in `ticketing_providers.dart`.
//
// The desktop opens no local database — it is a thin client; `databaseProvider`
// throws and `rpcClientProvider` is the connected (spawned) `cc_server` — so the
// ticket write services run over RPC, identical to the web client. They are pure
// cc_domain logic over repository INTERFACES, so constructing them over the
// RPC-flipped repositories GENUINELY performs the writes on the server (no
// in-process host exists to cycle through). The remote→local mirror pull is the
// server's job, so `triggerTicketSync` is an honest no-op here.
library;

import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/features/ticketing/domain/services/project_service.dart';
import 'package:cc_domain/features/ticketing/domain/services/ticket_link_service.dart';
import 'package:cc_domain/features/ticketing/domain/services/ticket_workflow_service.dart';
import 'package:control_center/core/providers/event_bus_provider.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/core/utils/app_log.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ticket WRITE path (create/update/assign/close) over RPC.
TicketWorkflowService buildTicketWorkflowService(Ref ref) {
  return TicketWorkflowService(
    repository: RpcTicketRepository(ref.watch(rpcClientProvider)),
    eventBus: ref.watch(domainEventBusProvider),
    onWarn: (message) => AppLog.w('TicketWorkflowService', message),
  );
}

/// Ticket dependency-link write service over RPC.
TicketLinkService buildTicketLinkService(Ref ref) {
  final client = ref.watch(rpcClientProvider);
  return TicketLinkService(
    linkRepository: RpcTicketLinkRepository(client),
    ticketRepository: RpcTicketRepository(client),
  );
}

/// Project write service over RPC.
ProjectService buildProjectService(Ref ref) {
  return ProjectService(
    repository: RpcProjectRepository(ref.watch(rpcClientProvider)),
  );
}

/// The remote→local mirror pull is owned by the server; the thin client never
/// holds the local mirror, so triggering a sync from here is an honest no-op.
void triggerTicketSync(Ref ref, String workspaceId) {}
