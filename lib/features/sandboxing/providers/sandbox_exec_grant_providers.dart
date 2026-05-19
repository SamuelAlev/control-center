import 'package:cc_data/cc_data.dart'
    show RemoteSandboxExecGrantRepository, SandboxExecGrantView;
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The client adapter for the server's sandbox exec-grant store.
final sandboxExecGrantRepositoryProvider =
    Provider<RemoteSandboxExecGrantRepository>(
      (ref) => RemoteSandboxExecGrantRepository(ref.watch(rpcClientProvider)),
    );

/// Every recorded decision in the given workspace.
///
/// A server predating exec grants answers with an empty list rather than an
/// error, so the settings page shows its empty state instead of a failure.
final sandboxExecGrantsProvider =
    FutureProvider.family<List<SandboxExecGrantView>, String>(
      (ref, workspaceId) =>
          ref.watch(sandboxExecGrantRepositoryProvider).list(workspaceId),
    );
