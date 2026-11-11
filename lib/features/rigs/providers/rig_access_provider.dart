// What a person may do with a rig, as the server has said so far.
//
// Each rig row says it for the caller (`can_drive`, and `holder_only` when the
// machine carries somebody else's own sign-ins), so a rig with a row follows
// its row. What has no row yet (Start before any machine exists, a viewing
// refusal) follows the space: someone with only a read grant on its
// repositories may watch but not drive, and someone who cannot read it may
// not even watch. That per-space state starts from "may drive" and moves
// down on the first refusal by kind (`repo_grant_required` and the forge
// refusals) or on a 403 from a lane of a rig whose row does not say.
library;

import 'package:control_center/features/forge/presentation/repo_code_refusal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// How far a person may use the rigs of one space.
enum RigAccess {
  /// Watch and drive: input, control, ports, paste and file drop.
  drive,

  /// Watch only: frames, sound, ports and browser state, but no input.
  watch,

  /// Neither: the person cannot read the space.
  none,
}

/// The space (conversation) whose rigs share one [RigAccess].
typedef RigSpaceKey = ({String workspaceId, String spaceId});

/// What the server has said about a person's use of a space's rigs.
class RigAccessState {
  /// Creates a [RigAccessState].
  const RigAccessState(this.access, [this.refusal]);

  /// How far the person may go.
  final RigAccess access;

  /// The refusal that lowered [access], when an RPC carried one. Null for
  /// the starting state and for a lane's bare 403.
  final Object? refusal;
}

/// The [RigAccess] a refusal from a rig op means FOR THE SPACE, or null when
/// [error] says nothing about the space (a closed rig, a lost lock, a
/// timeout, or `rig_holder_only`, which is about one machine and never about
/// the others in its space).
///
/// Read by kind, never by message text: no write grant leaves watching,
/// anything that denies reading the space (no read grant, the person's own
/// forge account, a sign-in the forge needs) leaves nothing.
RigAccess? rigAccessFromRefusal(Object error) =>
    isRepoGrantRefusal(error, level: 'write')
    ? RigAccess.watch
    : isRepoAccessRefusal(error)
    ? RigAccess.none
    : null;

/// Holds one space's [RigAccessState]; only ever moves down.
class RigAccessNotifier extends Notifier<RigAccessState> {
  /// Creates the notifier for [key].
  RigAccessNotifier(this.key);

  /// The space this tracks.
  final RigSpaceKey key;

  @override
  RigAccessState build() => const RigAccessState(RigAccess.drive);

  /// Lowers the access from a refused rig op. Returns whether [error] was a
  /// refusal about the person's rights.
  bool noteRefusal(Object error) {
    final access = rigAccessFromRefusal(error);
    if (access == null) {
      return false;
    }
    _lower(RigAccessState(access, error));
    return true;
  }

  /// Lowers the access from a 403 on one of the rig's HTTP lanes: a drive
  /// lane (microphone, clipboard write, file drop) leaves watching, a viewing
  /// lane (frames, sound, clipboard or file read) leaves nothing.
  void noteLaneForbidden({required bool drive}) =>
      _lower(RigAccessState(drive ? RigAccess.watch : RigAccess.none));

  void _lower(RigAccessState next) {
    if (next.access.index > state.access.index) {
      state = next;
    }
  }
}

/// One space's rig access, dropped when no rig surface of the space is on
/// screen so a grant given meanwhile is met by the next look.
final rigAccessProvider = NotifierProvider.autoDispose
    .family<RigAccessNotifier, RigAccessState, RigSpaceKey>(
      RigAccessNotifier.new,
    );

/// [RigAccess] for the space of a rig in [workspaceId] bound to
/// [conversationId]; a rig bound to no space is always drivable.
RigAccess watchRigAccess(
  WidgetRef ref,
  String workspaceId,
  String? conversationId,
) => conversationId == null || conversationId.isEmpty
    ? RigAccess.drive
    : ref
          .watch(
            rigAccessProvider((
              workspaceId: workspaceId,
              spaceId: conversationId,
            )),
          )
          .access;

/// Records a refusal or a lane's 403 for the space of a rig bound to
/// [conversationId]; nothing for a rig bound to no space.
RigAccessNotifier? rigAccessNotifierOf(
  WidgetRef ref,
  String workspaceId,
  String? conversationId,
) => conversationId == null || conversationId.isEmpty
    ? null
    : ref.read(
        rigAccessProvider((
          workspaceId: workspaceId,
          spaceId: conversationId,
        )).notifier,
      );

/// How far the person may use one rig, and whether that is because the rig
/// carries somebody else's sign-ins.
typedef RigDriveAccess = ({RigAccess access, bool holderOnly});

/// One rig's access from its row's per-caller answer ([canDrive], null when
/// the row did not say, and [holderOnly]) and [space], the space's state. A
/// space the person cannot read wins over any row; otherwise a row that says
/// is the answer, both ways round, and a row that does not leaves [space].
RigDriveAccess rigAccessFrom({
  required bool? canDrive,
  required bool holderOnly,
  required RigAccess space,
}) {
  if (space == RigAccess.none || canDrive == null) {
    return (access: space, holderOnly: false);
  }
  return canDrive
      ? (access: RigAccess.drive, holderOnly: false)
      : (access: RigAccess.watch, holderOnly: holderOnly);
}
