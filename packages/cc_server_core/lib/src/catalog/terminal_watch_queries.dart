import 'dart:async';
import 'dart:convert';

import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/features/sandboxing/domain/terminal_session_port.dart';
import 'package:cc_host/cc_host.dart';

/// Server-hosted terminal output and foreground-process titles.
/// The port checks the session's workspace and the person who opened it
/// before opening either stream.
///
/// [requireView] refuses an environment's session to a caller who may not
/// read its space, before either stream opens.
///
/// [mayDrive] is the right `terminal.write`, `resize` and `kill` check: the
/// first `terminal.output` frame is `{can_drive: bool}` from it, so a client
/// can disable input it would be refused.
List<WatchQuery> buildTerminalWatchQueries(
  TerminalSessionPort terminals, {
  required Future<bool> Function(RepoOpContext ctx) mayDrive,
  required Future<void>? Function(RepoOpContext ctx) requireView,
}) => [
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
      return _afterView(
        requireView(_opContext(ctx)),
        () => _afterDriveRight(
          terminals
              .output(
                workspaceId: ctx.workspaceId!,
                userId: ctx.userId,
                sessionId: sessionId,
              )
              .map((bytes) => <String, dynamic>{'chunk': base64Encode(bytes)}),
          () => mayDrive(_opContext(ctx)),
        ),
      );
    },
  ),
  WatchQuery(
    name: 'terminal.titles',
    handler: (ctx) {
      final sessionId = ctx.args['session_id'] as String?;
      if (sessionId == null) {
        throw const NotFoundException('Missing session_id');
      }
      return _afterView(
        requireView(_opContext(ctx)),
        () => terminals
            .titles(
              workspaceId: ctx.workspaceId!,
              userId: ctx.userId,
              sessionId: sessionId,
            )
            .map((title) => {'title': title}),
      );
    },
  ),
];

/// [open], once [check] (when there is one) has passed.
Stream<T> _afterView<T>(Future<void>? check, Stream<T> Function() open) =>
    check == null
    ? open()
    : Stream.fromFuture(check).asyncExpand((_) => open());

RepoOpContext _opContext(WatchQueryContext ctx) => RepoOpContext(
  args: ctx.args,
  workspaceId: ctx.workspaceId,
  deviceId: ctx.deviceId,
  userId: ctx.userId,
);

/// `{can_drive: ...}`, then [output]. [output] is listened to first and held
/// while the right is worked out: PTY bytes are live, so a late listen would
/// drop what the session printed meanwhile.
Stream<Map<String, dynamic>> _afterDriveRight(
  Stream<Map<String, dynamic>> output,
  Future<bool> Function() canDrive,
) async* {
  final held = StreamController<Map<String, dynamic>>();
  final subscription = output.listen(
    held.add,
    onError: held.addError,
    onDone: held.close,
  );
  try {
    yield {'can_drive': await canDrive()};
    yield* held.stream;
  } finally {
    await subscription.cancel();
  }
}
