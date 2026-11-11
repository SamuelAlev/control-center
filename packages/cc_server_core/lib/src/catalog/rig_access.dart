import 'package:cc_domain/cc_domain.dart'
    show
        AppException,
        AuthException,
        NotFoundException,
        ValidationException,
        WorkspaceMismatchException;
import 'package:cc_domain/core/domain/repositories/workspace_membership_repository.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/rigs/domain/entities/rig.dart';
import 'package:cc_domain/features/rigs/domain/ports/rig_port.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_spec.dart';
import 'package:cc_host/cc_host.dart';
import 'package:cc_server_core/src/catalog/owned_terminal_access.dart';
import 'package:cc_server_core/src/catalog/pr_data_gate.dart';
import 'package:cc_server_core/src/catalog/repo_forge_read.dart';
import 'package:cc_server_core/src/catalog/space_repo_access.dart';
import 'package:cc_server_core/src/rig_wire.dart';

/// What a rig's HTTP lanes ask before they open: whether a user may see or
/// drive a rig. [RigAccess] answers it.
abstract interface class RigLaneAccess {
  /// Whether [userId] may see rig [rigId] of [workspaceId]; false for an
  /// unknown rig.
  Future<bool> mayView(String workspaceId, String userId, String rigId);

  /// Whether [userId] may drive rig [rigId] of [workspaceId]; false for an
  /// unknown rig.
  Future<bool> mayDrive(String workspaceId, String userId, String rigId);

  /// Whether [userId] may read what is inside rig [rigId] of [workspaceId]
  /// (its clipboard and files): [mayView], and on a rig carrying a
  /// person's credentials only that person.
  Future<bool> mayReadContents(String workspaceId, String userId, String rigId);
}

/// Who may see a rig and who may drive it.
///
/// A rig opened in a space (its `conversationId` is that space's id: the
/// space's rig tabs, the agent's `*_use` tools, its environments) is the
/// space's machine, with the space's worktrees in reach. Seeing it (the
/// session list, frames, sound, the browser toolbar, its ports, its
/// clipboard and files) is reading the space: the space gate
/// ([PrDataGate.requireSpace] in the workspace). Driving it (input,
/// control, lifecycle, its forwarded ports, anything dropped into it) is
/// operating the space's environment: [mayOperateEnvironment], a write
/// grant on every repository the space exposes, each readable through the
/// caller's own forge sign-in.
///
/// A rig bound to no space reaches no worktree, and every member of its
/// workspace may see and drive it.
///
/// A rig carrying a person's own credentials ([RigSpec.credentialHolder]: a
/// terminal machine, or any machine opened for someone whose egress reaches
/// a forge) is driven by that person alone; others the space admits may
/// watch it. Somebody else's terminal machine ([RigSpec.isOwnedTerminal])
/// answers as if it did not exist, as their terminal sessions do.
///
/// RPC ops declare the same rule to the dispatcher through [reposOfRig] /
/// [reposOfSpaceArg], so a refusal carries its grant `{kind, level}`; the
/// HTTP lanes and live streams ask [mayView] / [mayDrive].
class RigAccess implements RigLaneAccess {
  /// Creates the rule over `rigs`, answered for spaces by `gate`.
  /// `standingChanges` ticks when a person's membership, grants or sign-ins
  /// in a workspace change, which moves their per-row drive flags.
  RigAccess({
    required this._rigs,
    required this._messaging,
    required this._gate,
    required this._spaceRepos,
    required this._members,
    required this._forgeRead,
    required this._standingChanges,
  });

  final RigPort _rigs;
  final MessagingRepository _messaging;
  final PrDataGate _gate;
  final SpaceRepoAccess _spaceRepos;
  final WorkspaceMembershipRepository? _members;
  final RepoForgeReadCheck _forgeRead;
  final Stream<void> Function(String workspaceId, String userId)
  _standingChanges;

  /// Rig [rigId] of [workspaceId] as [userId] may know it. Throws
  /// [NotFoundException] for a rig the workspace does not have and for
  /// somebody else's terminal machine alike.
  Future<Rig> rigFor(String workspaceId, String userId, String rigId) async {
    final rig = await _rigs.get(workspaceId, rigId);
    if (rig == null || !rig.spec.visibleTo(userId)) {
      throw const NotFoundException('Rig not found in this workspace');
    }
    return rig;
  }

  /// The space rig [rigId] of [workspaceId] belongs to, or null when it
  /// belongs to none, as [userId] may know it ([rigFor]).
  Future<String?> spaceOf(
    String workspaceId,
    String userId,
    String rigId,
  ) async => (await rigFor(workspaceId, userId, rigId)).conversationId;

  /// Refuses [userId] reading space [spaceId] of [workspaceId]: a space of
  /// another workspace, or one the space gate hides from them. The
  /// argument order of the catalog's `assertSpaceOwned`.
  Future<void> requireSpace(
    String workspaceId,
    String spaceId,
    String userId,
  ) async {
    if (await _messaging.getSpaceById(workspaceId, spaceId) == null) {
      throw const WorkspaceMismatchException(
        'Space belongs to a different workspace',
      );
    }
    await _gate.requireSpace(workspaceId, userId, spaceId);
  }

  /// Refuses [userId] seeing rig [rigId] of [workspaceId].
  Future<void> requireView(
    String workspaceId,
    String userId,
    String rigId,
  ) async {
    final spaceId = await spaceOf(workspaceId, userId, rigId);
    if (spaceId != null) {
      await requireSpace(workspaceId, spaceId, userId);
    }
  }

  /// Refuses [userId] driving rig [rigId] of [workspaceId] before any grant
  /// is asked: after [requireView], a rig carrying somebody else's
  /// credentials answers [rigHolderOnlyKind].
  Future<Rig> requireHolder(
    String workspaceId,
    String userId,
    String rigId,
  ) async {
    await requireView(workspaceId, userId, rigId);
    final rig = await rigFor(workspaceId, userId, rigId);
    if (!rig.spec.drivableBy(userId)) {
      throw const AuthException(
        'This machine carries another person\'s credentials; only they can '
        'drive it.',
        code: rigHolderOnlyKind,
      );
    }
    return rig;
  }

  /// For `RepoOp.repoAccessVia` over the `rig_id` argument: the repositories
  /// the rig's space exposes, after the space gate; none for a rig bound to
  /// no space.
  Future<List<String>> reposOfRig(RepoOpContext ctx) async {
    final workspaceId = ctx.workspaceId!;
    final spaceId = await spaceOf(
      workspaceId,
      ctx.userId,
      ctx.args['rig_id'] as String,
    );
    return spaceId == null ? const [] : _reposOf(ctx, spaceId);
  }

  /// As [reposOfRig] for an op that drives the rig: [requireHolder] first.
  Future<List<String>> reposOfDrivenRig(RepoOpContext ctx) async {
    await requireHolder(
      ctx.workspaceId!,
      ctx.userId,
      ctx.args['rig_id'] as String,
    );
    return reposOfRig(ctx);
  }

  /// For `RepoOp.repoAccessVia` over an optional space argument [arg] (what
  /// `rig.open` names its space by): as [reposOfRig] for that space.
  RepoAccessRepoResolver reposOfSpaceArg(String arg) => (ctx) async {
    final spaceId = ctx.args[arg];
    if (spaceId == null) {
      return const [];
    }
    if (spaceId is! String || spaceId.isEmpty) {
      throw ValidationException('Invalid argument: $arg (expected a string)');
    }
    return _reposOf(ctx, spaceId);
  };

  Future<List<String>> _reposOf(RepoOpContext ctx, String spaceId) async {
    await requireSpace(ctx.workspaceId!, spaceId, ctx.userId);
    return _spaceRepos.exposedBy(ctx.workspaceId!, spaceId);
  }

  @override
  Future<bool> mayView(String workspaceId, String userId, String rigId) async {
    try {
      await requireView(workspaceId, userId, rigId);
      return true;
    } on AppException {
      return false;
    }
  }

  /// Only its [RigSpec.credentialHolder] for a rig carrying a person's
  /// credentials; otherwise any member for a rig bound to no space,
  /// [mayOperateEnvironment] for one in a space.
  @override
  Future<bool> mayDrive(String workspaceId, String userId, String rigId) async {
    final String? spaceId;
    try {
      spaceId = (await requireHolder(
        workspaceId,
        userId,
        rigId,
      )).conversationId;
    } on AppException {
      return false;
    }
    return spaceId == null || await _mayOperate(workspaceId, userId, spaceId);
  }

  /// The space half of [mayDrive]: [mayOperateEnvironment] in [spaceId].
  Future<bool> _mayOperate(String workspaceId, String userId, String spaceId) =>
      mayOperateEnvironment(
        RepoOpContext(
          args: const {},
          workspaceId: workspaceId,
          deviceId: '',
          userId: userId,
        ),
        spaceId: spaceId,
        members: _members,
        reposExposedBySpace: (ctx) =>
            _spaceRepos.exposedBy(workspaceId, ctx.args['space_id'] as String?),
        requireRepoForgeRead: _forgeRead,
        assertSpaceOwned: requireSpace,
      );

  @override
  Future<bool> mayReadContents(
    String workspaceId,
    String userId,
    String rigId,
  ) async {
    try {
      await requireView(workspaceId, userId, rigId);
      return (await rigFor(workspaceId, userId, rigId)).spec.drivableBy(userId);
    } on AppException {
      return false;
    }
  }

  /// [rig]'s wire row for [userId], with their drive flags ([rowsFor]).
  Future<Map<String, dynamic>> rowFor(
    String workspaceId,
    String userId,
    Rig rig,
  ) async => (await rowsFor(workspaceId, userId, [rig])).single;

  /// [rigs]' wire rows for [userId], each with `can_drive` (exactly what
  /// [mayDrive] answers) and `holder_only` (it carries somebody else's
  /// credentials, [RigSpec.drivableBy]). The space half is asked once per
  /// space.
  Future<List<Map<String, dynamic>>> rowsFor(
    String workspaceId,
    String userId,
    List<Rig> rigs,
  ) async {
    final operate = <String, Future<bool>>{};
    final rows = <Map<String, dynamic>>[];
    for (final rig in rigs) {
      final holderOnly = !rig.spec.drivableBy(userId);
      final space = rig.conversationId;
      final canDrive =
          !holderOnly &&
          (space == null ||
              await operate.putIfAbsent(
                space,
                () => _mayOperate(workspaceId, userId, space),
              ));
      rows.add({
        ...rigToWire(rig),
        'can_drive': canDrive,
        'holder_only': holderOnly,
      });
    }
    return rows;
  }

  /// [rigs] without those whose space [userId] may not read and without
  /// somebody else's terminal machines.
  Future<List<Rig>> visible(
    String workspaceId,
    String userId,
    List<Rig> rigs,
  ) async {
    final hidden = await _gate.hiddenSpaces(workspaceId, userId);
    return [
      for (final r in rigs)
        if (!hidden.contains(r.conversationId) && r.spec.visibleTo(userId)) r,
    ];
  }

  /// `{rigs}` frames of [workspaceId] as [userId] may see them, each row
  /// with its drive flags ([rowsFor]). Re-sent when the rigs change and when
  /// [userId]'s membership, grants or sign-ins do ([_standingChanges]):
  /// those move a row's `can_drive` without hiding it, which the space
  /// filter alone would not re-send.
  Stream<Map<String, dynamic>> watchVisible(String workspaceId, String userId) {
    final rows =
        Stream<List<Rig>>.multi((out) {
          List<Rig>? latest;
          final rigsSub = _rigs.watch(workspaceId).listen((rigs) {
            latest = rigs;
            out.add(rigs);
          }, onError: out.addError);
          final tickSub = _standingChanges(workspaceId, userId).listen((_) {
            final rigs = latest;
            if (rigs != null) {
              out.add(rigs);
            }
          }, onError: out.addError);
          out.onCancel = () async {
            await rigsSub.cancel();
            await tickSub.cancel();
          };
        }).asyncMap((rigs) async {
          final mine = [
            for (final r in rigs)
              if (r.spec.visibleTo(userId)) r,
          ];
          final wire = await rowsFor(workspaceId, userId, mine);
          return [for (var i = 0; i < mine.length; i++) (mine[i], wire[i])];
        });
    return _gate.spaceRows(
      workspaceId,
      userId,
      rows,
      ((Rig, Map<String, dynamic>) r) => r.$1.conversationId,
      (list) => {
        'rigs': [for (final r in list) r.$2],
      },
    );
  }
}

/// The refusal `kind` for driving a machine that carries another person's
/// credentials ([RigSpec.credentialHolder]); it may be watched, not driven.
const String rigHolderOnlyKind = 'rig_holder_only';
