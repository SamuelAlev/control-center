import 'package:cc_data/cc_data.dart' show RemoteConfirmationRepository;
import 'package:cc_domain/cc_domain.dart' show ConfirmationRequestDto;
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The RPC-backed repository for host-global agent-action approvals.
///
/// Backs the desktop/web approval surface, mirroring the phone's
/// (`cc_remote`) responder: it reads the SERVER's live pending queue and
/// resolves entries. The server publishes a request whenever an agent hits an
/// approval-gated action and blocks until a decision arrives (the registry has
/// no timeout — see `PendingConfirmationRegistry`).
final confirmationRepositoryProvider = Provider<RemoteConfirmationRepository>(
  (ref) => RemoteConfirmationRepository(ref.watch(rpcClientProvider)),
);

/// Live pending agent-action approvals across all workspaces (host-global). Each
/// entry is a privileged action an agent is blocked on until the user approves
/// or denies. Empty when nothing awaits a decision.
final pendingConfirmationsProvider =
    StreamProvider.autoDispose<List<ConfirmationRequestDto>>(
      (ref) => ref.watch(confirmationRepositoryProvider).watchPending(),
    );
