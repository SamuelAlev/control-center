/// The space lists the sidebar renders, filtered to the rows it shows.
library;

import 'package:cc_domain/features/messaging/domain/entities/space.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/space_activity.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether two snapshots of a space render the same sidebar row: the fields
/// the list shows or filters on. Everything else on [Space] — `updatedAt`
/// above all, which every message bumps, but also mode and provisioning —
/// has its own provider, so a change there must not rebuild the list.
bool sameSidebarSpace(Space a, Space b) =>
    identical(a, b) ||
    (a.id == b.id &&
        a.name == b.name &&
        a.kind == b.kind &&
        a.workspaceId == b.workspaceId &&
        a.pipelineRunId == b.pipelineRunId &&
        a.isArchived == b.isArchived);

/// A space list compared by what the sidebar renders of it ([sameSidebarSpace]
/// per row, in order), so a `.select` over the raw stream drops the
/// emissions that only moved a timestamp. A reorder (a message making another
/// space the most recent) is a real change and still passes.
@immutable
class _SidebarSpaceList {
  const _SidebarSpaceList(this.spaces);

  /// Null while loading, or when the stream failed.
  final List<Space>? spaces;

  @override
  bool operator ==(Object other) {
    if (other is! _SidebarSpaceList) {
      return false;
    }
    final a = spaces;
    final b = other.spaces;
    if (identical(a, b)) {
      return true;
    }
    if (a == null || b == null || a.length != b.length) {
      return false;
    }
    for (var i = 0; i < a.length; i++) {
      if (!sameSidebarSpace(a[i], b[i])) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode =>
      Object.hashAll([for (final space in spaces ?? const <Space>[]) space.id]);
}

/// The ids of the spaces that have any message, compared by value. The only
/// part of the activity aggregate the visible-space filter reads.
@immutable
class _MessagedSpaceIds {
  const _MessagedSpaceIds(this.ids);

  factory _MessagedSpaceIds.of(Map<String, SpaceActivity>? activity) =>
      _MessagedSpaceIds(
        activity == null
            ? null
            : {
                for (final entry in activity.entries)
                  if (entry.value.lastMessageAt != null) entry.key,
              },
      );

  /// Null while the aggregate is loading.
  final Set<String>? ids;

  @override
  bool operator ==(Object other) =>
      other is _MessagedSpaceIds &&
      (identical(other.ids, ids) ||
          (other.ids != null && ids != null && setEquals(other.ids, ids)));

  @override
  int get hashCode => ids == null ? 0 : Object.hashAllUnordered(ids!);
}

_SidebarSpaceList _sidebarProjection(AsyncValue<List<Space>> spaces) =>
    _SidebarSpaceList(
      spaces.maybeWhen(data: (value) => value, orElse: () => null),
    );

/// Sidebar-visible spaces (all workspaces), excluding pipeline-managed
/// (hidden) ones, archived ones and PR-workbench spaces (which need the
/// workspace-scoped activity aggregate to know whether they've been messaged —
/// without an active workspace they stay hidden). Used as the fallback when no
/// active workspace is resolved. Value-stable like
/// [workspaceVisibleSpacesProvider].
final visibleSpacesProvider = Provider<List<Space>>((ref) {
  final spaces = ref.watch(spacesProvider.select(_sidebarProjection)).spaces;
  if (spaces == null) {
    return const [];
  }
  return spaces
      .where((c) => c.pipelineRunId == null && !c.kind.isPr && !c.isArchived)
      .toList();
});

/// Workspace-scoped sidebar-visible spaces, excluding pipeline-managed
/// (hidden) ones, archived ones (shelved until restored from the archive
/// dialog) and never-messaged PR-workbench spaces.
///
/// A PR-workbench space is minted the moment any PR surface (chat/terminal/
/// files) needs a worktree anchor — merely opening a PR must not clutter the
/// sidebar. It surfaces once someone actually messages in it (the server-
/// computed activity aggregate reports a non-null `lastMessageAt`), i.e. once
/// the user engaged an agent on that PR.
///
/// Value-stable: every message bumps its space's `updatedAt` (re-emitting the
/// space stream) and rewrites the activity aggregate, yet neither usually
/// changes this list. Both inputs are watched through a `.select` of only
/// what the filter and the rows read, so this re-runs — and the sidebar
/// rebuilds — only when a visible row's rendered fields, the order, or a PR
/// space's messaged-ness actually change. The [Space] objects handed out can
/// therefore carry an older `updatedAt`, mode or provisioning state; read
/// those from their own providers.
final workspaceVisibleSpacesProvider = Provider.family<List<Space>, String>((
  ref,
  workspaceId,
) {
  final messaged = ref
      .watch(
        workspaceSpaceActivityProvider(
          workspaceId,
        ).select((activity) => _MessagedSpaceIds.of(activity.value)),
      )
      .ids;
  final spaces = ref
      .watch(workspaceSpacesProvider(workspaceId).select(_sidebarProjection))
      .spaces;
  if (spaces == null) {
    return const [];
  }
  return spaces.where((c) {
    if (c.isArchived) {
      return false;
    }
    if (c.pipelineRunId != null) {
      return false;
    }
    if (c.kind.isPr) {
      // Hidden while the aggregate is still loading too — a brief delay
      // before an interacted PR space appears beats a flash of clutter.
      return messaged?.contains(c.id) ?? false;
    }
    return true;
  }).toList();
});
