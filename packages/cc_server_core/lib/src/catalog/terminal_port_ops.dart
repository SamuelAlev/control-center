import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/features/rigs/domain/ports/rig_ports_port.dart';
import 'package:cc_harness/tools.dart';
import 'package:cc_host/cc_host.dart';

/// Host-shell forwarded-port mutations (`terminal.*Port*`).
///
/// Same snapshots and mutations as `rig.*Port*`, keyed by the PTY
/// `session_id` plus the caller's current `space_id`. A session whose
/// stored space is not this space reads as absent — same-number listeners
/// in two spaces must not mix. Present only when [rigPorts] is wired
/// (demo omits them). Mutations stay `networkEgress`.
///
/// Spread from `buildRemoteRpcCatalog` so the catalog freeze does not grow.
List<RepoOp> buildTerminalPortOps({required RigPortsPort rigPorts}) => [
  RepoOp(
    name: 'terminal.setPortsAutoForward',
    kind: RepoOpKind.mutate,
    requiredArgs: const ['session_id', 'space_id', 'enabled'],
    actionClasses: const {ActionClass.networkEgress},
    handler: (ctx) async {
      final ids = _sessionSpace(ctx);
      final ok = await rigPorts.setTerminalPortsAutoForward(
        ctx.workspaceId!,
        ids.sessionId,
        spaceId: ids.spaceId,
        enabled: ctx.args['enabled'] == true,
      );
      return {'ok': ok};
    },
  ),
  RepoOp(
    name: 'terminal.addPort',
    kind: RepoOpKind.mutate,
    requiredArgs: const ['session_id', 'space_id', 'guest_port'],
    actionClasses: const {ActionClass.networkEgress},
    handler: (ctx) async {
      final ids = _sessionSpace(ctx);
      final port = _guestPort(ctx.args['guest_port']);
      if (port == null) {
        throw const ValidationException(
          'Invalid argument: guest_port (expected 1-65535)',
        );
      }
      final hostPort = ctx.args.containsKey('host_port')
          ? _guestPort(ctx.args['host_port'])
          : null;
      if (ctx.args.containsKey('host_port') && hostPort == null) {
        throw const ValidationException(
          'Invalid argument: host_port (expected 1-65535)',
        );
      }
      final ok = await rigPorts.addTerminalPortForward(
        ctx.workspaceId!,
        ids.sessionId,
        spaceId: ids.spaceId,
        guestPort: port,
        hostPort: hostPort,
      );
      return {'ok': ok};
    },
  ),
  RepoOp(
    name: 'terminal.removePort',
    kind: RepoOpKind.mutate,
    requiredArgs: const ['session_id', 'space_id', 'guest_port'],
    actionClasses: const {ActionClass.networkEgress},
    handler: (ctx) async {
      final ids = _sessionSpace(ctx);
      final port = _guestPort(ctx.args['guest_port']);
      if (port == null) {
        throw const ValidationException(
          'Invalid argument: guest_port (expected 1-65535)',
        );
      }
      final ok = await rigPorts.removeTerminalPortForward(
        ctx.workspaceId!,
        ids.sessionId,
        spaceId: ids.spaceId,
        guestPort: port,
      );
      return {'ok': ok};
    },
  ),
  RepoOp(
    name: 'terminal.setPortLan',
    kind: RepoOpKind.mutate,
    requiredArgs: const ['session_id', 'space_id', 'guest_port', 'exposed'],
    actionClasses: const {ActionClass.networkEgress},
    handler: (ctx) async {
      final ids = _sessionSpace(ctx);
      final port = _guestPort(ctx.args['guest_port']);
      if (port == null) {
        throw const ValidationException(
          'Invalid argument: guest_port (expected 1-65535)',
        );
      }
      final ok = await rigPorts.setTerminalPortLanExposed(
        ctx.workspaceId!,
        ids.sessionId,
        spaceId: ids.spaceId,
        guestPort: port,
        exposed: ctx.args['exposed'] == true,
      );
      return {'ok': ok};
    },
  ),
  RepoOp(
    name: 'terminal.setPortDomain',
    kind: RepoOpKind.mutate,
    requiredArgs: const ['session_id', 'space_id', 'guest_port'],
    actionClasses: const {ActionClass.networkEgress},
    handler: (ctx) async {
      final ids = _sessionSpace(ctx);
      final port = _guestPort(ctx.args['guest_port']);
      if (port == null) {
        throw const ValidationException(
          'Invalid argument: guest_port (expected 1-65535)',
        );
      }
      try {
        final ok = await rigPorts.setTerminalPortDomain(
          ctx.workspaceId!,
          ids.sessionId,
          spaceId: ids.spaceId,
          guestPort: port,
          domain: ctx.args['domain'] as String?,
        );
        return {'ok': ok};
      } on ArgumentError catch (e) {
        throw ValidationException('${e.message}');
      }
    },
  ),
];

({String sessionId, String spaceId}) _sessionSpace(RepoOpContext ctx) {
  final sessionId = ctx.args['session_id'];
  final spaceId = ctx.args['space_id'];
  if (sessionId is! String || sessionId.isEmpty) {
    throw const ValidationException('Missing or invalid argument: session_id');
  }
  if (spaceId is! String) {
    throw const ValidationException('Missing or invalid argument: space_id');
  }
  return (sessionId: sessionId, spaceId: spaceId);
}

/// Reads a guest port from a client arg, accepting the int and the numeric
/// string a JSON client may send. Null on anything outside 1–65535.
int? _guestPort(Object? raw) {
  final port = switch (raw) {
    final int i => i,
    final String s => int.tryParse(s),
    _ => null,
  };
  return (port == null || port <= 0 || port > 65535) ? null : port;
}
