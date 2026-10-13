import 'dart:convert';

import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/features/sandboxing/domain/terminal_session_port.dart';
import 'package:cc_host/cc_host.dart';

/// Server-hosted terminal output and foreground-process titles.
/// The port validates session ownership before opening either stream.
List<WatchQuery> buildTerminalWatchQueries(TerminalSessionPort terminals) => [
  WatchQuery(
    name: 'terminal.output',
    // PTY bytes are ordered deltas: coalescing loses cursor commands, and
    // equality suppression drops repeated keystroke echoes.
    isEventStream: true,
    handler: (ctx) {
      final sessionId = ctx.args['session_id'] as String?;
      if (sessionId == null) {
        throw const NotFoundException('Missing session_id');
      }
      return terminals
          .output(workspaceId: ctx.workspaceId!, sessionId: sessionId)
          .map((bytes) => {'chunk': base64Encode(bytes)});
    },
  ),
  WatchQuery(
    name: 'terminal.titles',
    handler: (ctx) {
      final sessionId = ctx.args['session_id'] as String?;
      if (sessionId == null) {
        throw const NotFoundException('Missing session_id');
      }
      return terminals
          .titles(workspaceId: ctx.workspaceId!, sessionId: sessionId)
          .map((title) => {'title': title});
    },
  ),
];
