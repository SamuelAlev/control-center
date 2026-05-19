// VM-only ticketing providers (server-side execution half of
// `ticketing_providers.dart`).
//
// The local ticket adapter mirrors remote tickets into the local store, so the
// adapter pool, the remote→local pull (`TicketSyncService`) and the
// local→remote push (`TicketRemoteSyncHandler`) all own the Drift `dao*`
// repository directly — going over RPC here would loop through the in-process
// server back into this graph. These run only on the server, so they live here:
// imported by the desktop bootstrap, the MCP/orchestration server surfaces, and
// the io ticketing seam, never from the web graph. The web-safe UI providers
// (ticket/project/link RPC reads + selection/view-mode UI state) stay in
// `ticketing_providers.dart`.
library;

import 'package:cc_domain/features/ticketing/domain/entities/ticket_provider.dart';
import 'package:cc_domain/features/ticketing/domain/ports/ticket_provider_port.dart';
import 'package:cc_domain/features/ticketing/domain/services/ticket_remote_sync_handler.dart';
import 'package:cc_infra/src/network/app_network.dart';
import 'package:cc_infra/src/tickets/clickup_ticket_adapter.dart';
import 'package:cc_infra/src/tickets/jira_ticket_adapter.dart';
import 'package:cc_infra/src/tickets/linear/linear_ticket_adapter.dart';
import 'package:cc_infra/src/tickets/local_ticket_adapter.dart';
import 'package:cc_infra/src/tickets/ticket_sync_service.dart';
import 'package:control_center/core/providers/event_bus_provider.dart';
import 'package:control_center/di/server_providers.dart';
import 'package:control_center/features/auth/providers/auth_providers.dart';
import 'package:control_center/features/ticketing/providers/ticketing_providers.dart'
    show activeTicketProviderProvider;
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Dio for the Linear adapter, authorized with the stored ticketing key.
/// Adapter-scoped — only the Linear adapter pool entry consumes it.
final _linearTicketDioProvider = Provider<Dio>((ref) {
  final dio = createDio(baseUrl: 'https://api.linear.app/graphql');
  final creds = ref.watch(credentialsProvider).maybeWhen(
        data: (c) => c,
        orElse: () => null,
      );
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final key = creds?.ticketingApiKey ?? '';
        if (key.isNotEmpty) {
          options.headers['Authorization'] = key;
        }
        handler.next(options);
      },
    ),
  );
  return dio;
});

/// All adapter implementations (the `SandboxPort` pool analogue).
///
/// The local adapter is server-side ticket persistence (it mirrors remote
/// tickets into the local store), so it uses the Dao-backed repository — going
/// over RPC here would loop through the in-process server back into this graph.
final ticketProviderAdaptersPoolProvider =
    Provider<List<TicketProviderPort>>((ref) {
  return <TicketProviderPort>[
    LocalTicketAdapter(ref.watch(daoTicketRepositoryProvider)),
    LinearTicketAdapter(ref.watch(_linearTicketDioProvider)),
    const JiraTicketAdapter(),
    const ClickUpTicketAdapter(),
  ];
});

/// Resolves the [TicketProviderPort] for the active provider, falling back to
/// the always-available local adapter.
final ticketProviderPortProvider = Provider<TicketProviderPort>((ref) {
  final active = ref.watch(activeTicketProviderProvider);
  final pool = ref.watch(ticketProviderAdaptersPoolProvider);
  return pool.firstWhere(
    (a) => a.provider == active,
    orElse: () =>
        pool.firstWhere((a) => a.provider == TicketProvider.local),
  );
});

/// Pushes local ticket changes to the active remote provider (server-side sync
/// handler — Dao-backed).
final ticketRemoteSyncHandlerProvider = Provider<TicketRemoteSyncHandler>((ref) {
  final handler = TicketRemoteSyncHandler(
    eventBus: ref.watch(domainEventBusProvider),
    repository: ref.watch(daoTicketRepositoryProvider),
    providerPort: ref.watch(ticketProviderPortProvider),
  );
  handler.start();
  ref.onDispose(handler.dispose);
  return handler;
});

/// Keeps the ticket remote sync handler alive across the app lifetime.
final ticketRemoteSyncAliveProvider = Provider<void>((ref) {
  ref.watch(ticketRemoteSyncHandlerProvider);
});

/// Pulls remote tickets into the local mirror (no-op for the local provider).
/// Server-side sync — Dao-backed.
final ticketSyncServiceProvider = Provider<TicketSyncService>((ref) {
  return TicketSyncService(
    port: ref.watch(ticketProviderPortProvider),
    repository: ref.watch(daoTicketRepositoryProvider),
  );
});
