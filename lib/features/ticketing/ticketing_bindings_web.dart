// Web bindings for the ticketing write/sync services declared in
// `ticketing_providers.dart`.
//
// The ticket write services (`TicketWorkflowService` / `TicketLinkService` /
// `ProjectService`) are pure cc_domain logic over repository INTERFACES, so on
// web they are constructed over the RPC-flipped repositories — ticket
// create/update/assign/link/project writes GENUINELY work over RPC (no host
// cycle exists on web, so reading the public RPC repos here is safe). The
// remote→local pull is the server's job, so `triggerTicketSync` is an honest
// no-op on web (the web client never owns the local mirror).
library;

import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/features/ticketing/domain/services/project_service.dart';
import 'package:cc_domain/features/ticketing/domain/services/ticket_link_service.dart';
import 'package:cc_domain/features/ticketing/domain/services/ticket_workflow_service.dart';
import 'package:control_center/core/providers/event_bus_provider.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/core/utils/app_log.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Web ticket WRITE path over RPC.
TicketWorkflowService buildTicketWorkflowService(Ref ref) {
  return TicketWorkflowService(
    repository: RpcTicketRepository(ref.watch(rpcClientProvider)),
    eventBus: ref.watch(domainEventBusProvider),
    onWarn: (message) => AppLog.w('TicketWorkflowService', message),
  );
}

/// Web ticket dependency-link write service over RPC.
TicketLinkService buildTicketLinkService(Ref ref) {
  final client = ref.watch(rpcClientProvider);
  return TicketLinkService(
    linkRepository: RpcTicketLinkRepository(client),
    ticketRepository: RpcTicketRepository(client),
  );
}

/// Web project write service over RPC.
ProjectService buildProjectService(Ref ref) {
  return ProjectService(repository: RpcProjectRepository(ref.watch(rpcClientProvider)));
}

/// The remote→local mirror pull is owned by the server; the web client never
/// holds the local mirror, so triggering a sync from web is an honest no-op.
void triggerTicketSync(Ref ref, String workspaceId) {}
