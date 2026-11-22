import 'package:cc_data/cc_data.dart' show RpcCodeModeRepository;
import 'package:cc_domain/cc_domain.dart' show CodeModeStatusDto;
import 'package:cc_remote/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Code mode on the paired server for [workspaceId]: whether it runs
/// scripts, and why not when it does not. Null until a client is connected,
/// or when [workspaceId] is no longer the active workspace.
final remoteCodeModeStatusProvider = FutureProvider.autoDispose
    .family<CodeModeStatusDto?, String>((ref, workspaceId) async {
      final active = ref.watch(activeWorkspaceIdProvider).value;
      final client = ref.watch(rpcClientProvider).value;
      if (active != workspaceId || client == null) {
        return null;
      }
      return RpcCodeModeRepository(client).status(workspaceId);
    });
