part of '../remote_rpc_catalog.dart';

List<WatchQuery> _rigWatchQueries(RigPort? rigs, RigPortsPort? rigPorts) => [
  // Status, display size and who holds control, pushed on every change. The
  // FRAMES do not come through here — video over a JSON-RPC subscription
  // would put base64 in the same lane as every other message. They ride the
  // separate `/rig/stream/<id>` chunked HTTP body.
  if (rigs != null)
    WatchQuery(
      name: 'rig.watchSessions',
      handler: (ctx) => rigs
          .watch(ctx.workspaceId!)
          .map(
            (list) => {
              'rigs': [for (final r in list) rigToWire(r)],
            },
          ),
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
        return rigPorts.watchPorts(ctx.workspaceId!, rigId);
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
        return rigPorts.watchTerminalPorts(
          ctx.workspaceId!,
          sessionId,
          spaceId: spaceId,
        );
      },
    ),
];
