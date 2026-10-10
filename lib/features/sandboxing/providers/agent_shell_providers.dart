import 'dart:async';

import 'package:cc_data/cc_data.dart' show RpcAgentShellProcessPort;
import 'package:cc_domain/core/domain/entities/agent_shell_process.dart';
import 'package:cc_domain/core/domain/ports/agent_shell_process_port.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/di/demo_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// How often the TERMINALS section re-reads the space's agent commands. A
/// process table has no change feed, and a stuck command is not urgent to the
/// second.
const kAgentShellPollInterval = Duration(seconds: 3);

/// The client adapter for the server's agent shell commands.
final agentShellProcessPortProvider = Provider<AgentShellProcessPort>(
  (ref) => RpcAgentShellProcessPort(ref.watch(rpcClientProvider)),
);

/// Which space's agent commands to read.
typedef AgentShellsKey = ({String workspaceId, String spaceId});

/// The shell commands agents left running in one space — backgrounded tasks
/// and foreground ones that outlived a quick call — polled while something
/// watches it. A failed poll keeps the last list rather than blanking it.
final spaceAgentShellsProvider = StreamProvider.autoDispose
    .family<List<AgentShellProcess>, AgentShellsKey>((ref, key) async* {
      // The demo runs no agents, and its server refuses the `process.` family.
      if (ref.watch(isDemoServerProvider)) {
        yield const [];
        return;
      }
      final port = ref.watch(agentShellProcessPortProvider);
      // The wait between polls is cancelled on dispose: a bare
      // `Future.delayed` would outlive the provider and fire one more read
      // after nothing watches it.
      var disposed = false;
      Timer? wait;
      Completer<void>? woke;
      ref.onDispose(() {
        disposed = true;
        wait?.cancel();
        final pending = woke;
        if (pending != null && !pending.isCompleted) {
          pending.complete();
        }
      });
      var first = true;
      while (!disposed) {
        try {
          yield await port.list(
            workspaceId: key.workspaceId,
            spaceId: key.spaceId,
          );
        } on Object {
          if (first) {
            yield const [];
          }
        }
        first = false;
        final next = woke = Completer<void>();
        wait = Timer(kAgentShellPollInterval, next.complete);
        await next.future;
      }
    });
