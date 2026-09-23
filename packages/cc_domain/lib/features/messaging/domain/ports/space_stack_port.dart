import 'package:cc_domain/features/messaging/domain/entities/space_stack_entry.dart';
import 'package:cc_domain/features/messaging/domain/services/stack_branch_names.dart';

/// The result of a stack read or mutation, shared by the RPC ops and the
/// agent tools.
class SpaceStackView {
  /// Creates a [SpaceStackView].
  const SpaceStackView({
    required this.ok,
    this.dirty = false,
    this.error,
    this.entries = const [],
    this.checkedOut = const {},
    this.opened = 0,
    this.grouped = false,
    this.stackError,
  });

  /// Whether the call did what was asked.
  final bool ok;

  /// True when cut or checkout refused because the worktree has uncommitted
  /// changes. The caller commits first.
  final bool dirty;

  /// Why [ok] is false, when it is.
  final String? error;

  /// Layers after the call, bottom to top within each repo.
  final List<SpaceStackEntry> entries;

  /// The branch each repo's checkout is on, keyed by repo id.
  final Map<String, String> checkedOut;

  /// Pull requests opened by this publish.
  final int opened;

  /// Whether the forge accepted the layers as one stack.
  final bool grouped;

  /// Set when the pull requests opened but grouping them failed.
  final String? stackError;

  /// Wire map for RPC and tool results.
  Map<String, dynamic> toWire() => {
    'ok': ok,
    'dirty': dirty,
    if (error != null) 'error': error,
    'entries': [
      for (final entry in entries)
        {
          'repo_id': entry.repoId,
          'position': entry.position,
          'branch': entry.branch,
          'base_branch': entry.baseBranch,
          'pr_number': entry.prNumber,
          'pr_external_id': entry.prExternalId,
          'rewritten': entry.rewritten,
          'current': checkedOut[entry.repoId] == entry.branch,
          'label': stackLayerLabel(
            entry.branch,
            bottom: _stackBottom(entries, entry.repoId),
          ),
        },
    ],
    'opened': opened,
    'grouped': grouped,
    if (stackError != null) 'stack_error': stackError,
  };
}

String? _stackBottom(List<SpaceStackEntry> entries, String repoId) {
  for (final entry in entries) {
    if (entry.repoId == repoId && entry.position == 0) {
      return entry.branch;
    }
  }
  return null;
}

/// Cuts, checks out, and publishes the branches of one space.
///
/// Git runs inside the space's existing checkout. This is the only writer of
/// stack rows and of the checkout's recorded branch for a stack move.
abstract class SpaceStackPort {
  /// The layers recorded for [spaceId]. Empty until the first cut.
  Future<SpaceStackView> list({
    required String workspaceId,
    required String spaceId,
  });

  /// Appends a layer named [name].
  ///
  /// With no [at], the new branch starts at HEAD. With [at] (an ancestor of
  /// HEAD), the current branch is reset to that commit and the new branch
  /// keeps the commits above it.
  Future<SpaceStackView> cut({
    required String workspaceId,
    required String spaceId,
    required String name,
    String? repoId,
    String? at,
  });

  /// Checks [branch] out. It must already be a recorded layer.
  Future<SpaceStackView> checkout({
    required String workspaceId,
    required String spaceId,
    required String branch,
    String? repoId,
  });

  /// Pushes every layer and opens a pull request for each one that does not
  /// have one yet. Each pull request targets the branch below it.
  Future<SpaceStackView> publish({
    required String workspaceId,
    required String spaceId,
    String? repoId,
    String? actingUserId,
    bool draft = true,
  });
}
