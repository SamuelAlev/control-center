part of '../remote_rpc_catalog.dart';

// Every stream shows a rig only to a caller who may read its space
// ([RigAccess]).
List<WatchQuery> _rigWatchQueries(
  RigPort? rigs,
  RigPortsPort? rigPorts,
  RigAccess? access,
  TerminalSessionPort? terminals,
) => [
  // Status, display size and who holds control, pushed on every change. The
  // FRAMES do not come through here — video over a JSON-RPC subscription
  // would put base64 in the same lane as every other message. They ride the
  // separate `/rig/stream/<id>` chunked HTTP body.
  if (rigs != null)
    WatchQuery(
      name: 'rig.watchSessions',
      handler: (ctx) => access!.watchVisible(ctx.workspaceId!, ctx.userId),
    ),
  // The panel's data. One stream per rig, pushed on every port that opens,
  // closes or is forwarded — the discovery poll is server-side, so the
  // client never polls the guest.
  if (rigPorts != null)
    WatchQuery(
      name: 'rig.watchPorts',
      handler: (ctx) {
        final rigId = ctx.args['rig_id'];
        if (rigId is! String || rigId.isEmpty) {
          throw const ValidationException(
            'Missing or invalid argument: rig_id',
          );
        }
        return Stream.fromFuture(
          access!.requireView(ctx.workspaceId!, ctx.userId, rigId),
        ).asyncExpand((_) => rigPorts.watchPorts(ctx.workspaceId!, rigId));
      },
    ),
  if (rigPorts != null)
    WatchQuery(
      name: 'terminal.watchPorts',
      handler: (ctx) {
        final sessionId = ctx.args['session_id'];
        final spaceId = ctx.args['space_id'];
        if (sessionId is! String || sessionId.isEmpty) {
          throw const ValidationException(
            'Missing or invalid argument: session_id',
          );
        }
        if (spaceId is! String) {
          throw const ValidationException(
            'Missing or invalid argument: space_id',
          );
        }
        return Stream.fromFuture(
          access!.requireSpace(ctx.workspaceId!, spaceId, ctx.userId),
        ).asyncExpand(
          // Somebody else's session is silent, exactly as a missing one.
          (_) => isOthersTerminal(terminals, sessionId, ctx.userId)
              ? Stream<Map<String, dynamic>>.multi((_) {})
              : rigPorts.watchTerminalPorts(
                  ctx.workspaceId!,
                  sessionId,
                  spaceId: spaceId,
                ),
        );
      },
    ),
];
