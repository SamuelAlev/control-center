import 'package:cc_data/cc_data.dart' show RemoteCredentialGateRepository;
import 'package:cc_domain/cc_domain.dart' show RunCredentialBlockDto;
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The RPC-backed repository for runs parked on a credential.
final credentialGateRepositoryProvider =
    Provider<RemoteCredentialGateRepository>(
      (ref) => RemoteCredentialGateRepository(ref.watch(rpcClientProvider)),
    );

/// Live runs the SERVER has parked because the credential they need cannot
/// serve them — a Claude Code account with no plan headroom or no sign-in, a
/// harness provider with no key.
///
/// Each entry is a turn that has NOT failed: it is waiting, and it continues on
/// its own the moment the credential works. Empty when nothing is parked, which
/// is the overwhelmingly common case — so the surface that watches this renders
/// nothing at all until it does not.
///
/// Host-global (an operator spans workspaces), already filtered server-side to
/// workspaces the caller belongs to.
final blockedRunsProvider =
    StreamProvider.autoDispose<List<RunCredentialBlockDto>>(
      (ref) => ref.watch(credentialGateRepositoryProvider).watchBlocked(),
    );
