import 'package:cc_domain/features/rigs/domain/entities/rig.dart';
import 'package:cc_domain/features/rigs/domain/entities/rig_action_log_entry.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/browser_action.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/computer_action.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/mobile_action.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_action.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_surface.dart';

/// The wire form of a [Rig] for the `rig.*` ops.
///
/// Deliberately does NOT carry the spec's egress allowlist or the worktree
/// path: the client renders status and identity, and a rig's reachability
/// policy is not something a viewer needs to know to draw a canvas.
Map<String, dynamic> rigToWire(Rig rig) => {
  'id': rig.id,
  'workspace_id': rig.workspaceId,
  'surface': rig.surface.wire,
  // An exec (terminal) rig and a computer_use rig share the `computer`
  // surface; the client needs the distinction to know which rig the ports
  // panel belongs to, and the spec is deliberately not on the wire.
  'is_exec': rig.spec.isExec,
  // Which browser a browser rig is running. On the wire for every rig (the
  // other surfaces carry the default and no client reads it there) because
  // the tab that opened it has to be able to tell its machine from the
  // Firefox one beside it, and the panel shows the engine as a badge.
  'browser_engine': rig.spec.browserEngine.wire,
  'backend': rig.backend.wire,
  'backend_label': rig.backend.label,
  'accelerated': rig.backend.isAccelerated,
  'phase': rig.status.phase.wire,
  if (rig.status.detail != null) 'detail': rig.status.detail,
  if (rig.status.closeReason != null)
    'close_reason': rig.status.closeReason!.wire,
  if (rig.display != null) ...{
    'display_width': rig.display!.width,
    'display_height': rig.display!.height,
  },
  if (rig.currentUrl != null) 'current_url': rig.currentUrl,
  'created_by': rig.createdBy.wire,
  if (rig.conversationId != null) 'conversation_id': rig.conversationId,
  // Which machine of this kind within the conversation. Absent means the
  // conversation's DEFAULT one — what an agent drives and what every tab
  // addressed before slots existed — so a client that knows nothing about
  // slots reads exactly the rig it used to.
  if (rig.spec.slotId != null) 'slot_id': rig.spec.slotId,
  if (rig.agentId != null) 'agent_id': rig.agentId,
  if (rig.workerId != null) 'worker_id': rig.workerId,
  if (rig.controller != null) 'controller': rig.controller!.wire,
  if (rig.controlHeldSince != null)
    'control_held_since': rig.controlHeldSince!.toIso8601String(),
  'created_at': rig.createdAt.toIso8601String(),
  if (rig.readyAt != null) 'ready_at': rig.readyAt!.toIso8601String(),
  'last_activity_at': rig.lastActivityAt.toIso8601String(),
  if (rig.closedAt != null) 'closed_at': rig.closedAt!.toIso8601String(),
  'expires_at': rig.expiresAt.toIso8601String(),
  'memory_mb': rig.spec.memoryMb,
  'cpu_count': rig.spec.cpuCount,
};

/// The wire form of one action-log entry.
Map<String, dynamic> rigActionToWire(RigActionLogEntry entry) => entry.toJson();

/// Parses an action payload for [surface].
///
/// The dispatch lives here rather than on [RigAction] so each surface's family
/// stays sealed in its own file — a single sealed root would force every verb
/// of every surface into one file to get exhaustiveness that no adapter wants
/// across surfaces anyway.
RigActionParse parseRigAction(
  RigSurface surface,
  Map<String, dynamic> arguments,
) => switch (surface) {
  RigSurface.computer => ComputerAction.parse(arguments),
  RigSurface.browser => BrowserAction.parse(arguments),
  RigSurface.mobile => MobileAction.parse(arguments),
};
