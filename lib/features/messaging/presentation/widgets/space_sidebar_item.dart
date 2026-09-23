import 'dart:async';

import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/features/messaging/domain/entities/space.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/presentation/widgets/space_row.dart';
import 'package:control_center/features/messaging/presentation/widgets/space_row_adornments.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/repos/providers/repo_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_scope.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

export 'package:control_center/features/messaging/presentation/widgets/space_row.dart';

/// Extracts the selected space id from the current [location] path, or null
/// when not on a `/workspaces/<ws>/spaces/<id>` location. Parses the location
/// rather than `pathParameters` because the sidebar sits in the shell, above
/// the space route, so its `:spaceId` is not in `GoRouterState` scope here.
String? selectedSpaceIdFromLocation(String location, String? workspaceId) {
  if (workspaceId == null) {
    return null;
  }
  final prefix = '${spacesRoute(workspaceId)}/';
  if (!location.startsWith(prefix)) {
    return null;
  }
  final rest = location.substring(prefix.length);
  final slash = rest.indexOf('/');
  final id = slash == -1 ? rest : rest.substring(0, slash);
  return id.isEmpty ? null : id;
}

/// A space row with its live status, unread signal and archive affordances,
/// shared by the global sidebar's inline space list
/// (`ConversationsSidebarSection`) and the spaces directory page's filtered
/// list (`SpacesSubSidebar`). Implements [CcFluidHoverTarget] so the enclosing
/// [CcSidebarGroup] can wash the row with the same travelling highlight as
/// Workspace nav.
class SpaceSidebarItem extends ConsumerWidget implements CcFluidHoverTarget {
  /// Creates a [SpaceSidebarItem].
  const SpaceSidebarItem({
    super.key,
    required this.space,
    required this.selected,
    required this.onPress,
    this.leading,
    this.absentLeading,
    this.subtitle,
    this.quietSelection = false,
    this.cardInset = EdgeInsets.zero,
    this.muted = false,
    this.conversationCount,
    this.runningShownOnConversations = false,
    this.unreadShownOnConversations = false,
  });

  /// The space to render.
  final Space space;

  /// Whether the row reads as the route's selected space.
  final bool selected;

  /// Tap handler (navigation; the URL is the source of truth for selection).
  final VoidCallback onPress;

  /// Replaces the whole leading slot (PR badge, spinner, absent mark).
  final Widget? leading;

  /// Leading mark when the space has no pull request and is not running.
  /// Null keeps the pencil. The global sidebar passes the empty dot.
  final Widget? absentLeading;

  /// Second line under the space name. A checked-out branch.
  final String? subtitle;

  /// Selected without the solid brand fill. The parent paints the panel.
  final bool quietSelection;

  /// Vertical air this row's fill paints. The sidebar card inset.
  final EdgeInsets cardInset;

  /// Whether this is a muted agent-DM row: dimmed and with no unread indicator,
  /// so agent chatter stays quiet and never touches the human unread counts.
  final bool muted;

  /// How many parallel conversations the space holds, shown as a quiet chip
  /// after the name when the global sidebar lists them beneath this row.
  /// Null hides the chip (single-conversation spaces, the directory page).
  final int? conversationCount;

  /// Whether a visible conversation row beneath this one is already spinning
  /// for the run that makes this space busy.
  ///
  /// The running signal belongs on the most specific row the user can SEE. A
  /// space listing four conversations spun on the parent and left all four
  /// looking idle, so the row that says "an agent is working" was never the row
  /// that says WHERE. When the children carry it, this row shows its ordinary
  /// leading glyph (the PR badge / pencil) instead of a second spinner.
  ///
  /// Only ever true when a listed conversation is actually running: a run this
  /// space owns that no visible row can claim (an archived conversation, a run
  /// with no conversation id) keeps its signal here rather than losing it.
  final bool runningShownOnConversations;

  /// Whether a visible conversation row beneath this one already carries the
  /// unread dot for the unseen agent work that makes this space unread.
  ///
  /// Same placement rule as [runningShownOnConversations]: the signal belongs
  /// on the most specific row the user can see. When the children carry it,
  /// this row drops the idle unread dot so one unseen reply does not light
  /// both the parent and the child. A never-listed single-conversation space
  /// (and unread on an archived conversation no visible row can claim) keeps
  /// the dot here.
  final bool unreadShownOnConversations;

  @override
  bool get fluidHoverEnabled => true;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    final status = ref.watch(spaceStatusProvider(space.id));
    // Muted agent rows never read the unread provider — their notifications are
    // deliberately suppressed.
    final unread = muted
        ? false
        : (!unreadShownOnConversations &&
              ref.watch(spaceUnreadProvider(space.id)));
    final running =
        status == SpaceStatus.running && !runningShownOnConversations;

    final label = space.name.isNotEmpty ? space.name : l10n.spaceLabel;
    // The leading slot carries the running signal (a spinner), so the trailing
    // indicator stays clear of a redundant running dot.
    final mark =
        leading ??
        SpaceLeadingIcon(
          spaceId: space.id,
          running: running,
          // Quiet selection paints no brand fill, so the status-colored PR
          // glyph stays. Recolouring is only for the solid selected row.
          selected: selected && !quietSelection,
          absent: absentLeading,
        );

    return SpaceRow(
      leading: mark,
      label: label,
      subtitle: subtitle,
      quietSelection: quietSelection,
      cardInset: cardInset,
      selected: selected,
      status: status,
      unread: unread,
      leadingHandlesRunning: true,
      muted: muted,
      count: conversationCount,
      onPress: onPress,
      menuSemanticLabel: l10n.spaceActions,
      menuItems: [
        CcMenuItem(
          label: l10n.renameSpace,
          icon: AppIcons.pencil,
          onSelected: () => unawaited(_rename(context, ref)),
        ),
        CcMenuItem(
          label: l10n.editSpaceRepos,
          icon: AppIcons.gitBranch,
          onSelected: () =>
              unawaited(showEditSpaceReposDialog(context, ref, space)),
        ),
        CcMenuItem(
          label: l10n.archiveSpace,
          icon: AppIcons.archive,
          onSelected: () => unawaited(_archive(context, ref)),
        ),
      ],
    );
  }

  /// Renames the space in place (the row follows the live watch; no
  /// navigation — the id, and so the URL, never changes).
  Future<void> _rename(BuildContext context, WidgetRef ref) async {
    final name = await showRenameDialog(
      context,
      title: AppLocalizations.of(context).renameSpace,
      initialValue: space.name,
    );
    if (name == null || !context.mounted) {
      return;
    }
    await ref
        .read(messagingServiceProvider)
        .updateSpaceName(ref.requireWorkspaceId(), space.id, name);
  }

  /// Archives the space — a reversible soft hide, so no confirmation: the
  /// space leaves the sidebar (and, when it is the open route space, the URL
  /// drops back to the space list) and the archive trigger beside the `+`
  /// button brings it back. Messages, participants and worktrees all survive.
  Future<void> _archive(BuildContext context, WidgetRef ref) async {
    final service = ref.read(messagingServiceProvider);
    await service.archiveSpace(ref.requireWorkspaceId(), space.id);

    if (context.mounted) {
      // If the archived space is the one open in the URL, drop back to the
      // space list (the URL is the source of truth for selection).
      final workspaceId = context.currentWorkspaceId;
      final routeSpaceId = selectedSpaceIdFromLocation(
        GoRouterState.of(context).uri.path,
        workspaceId,
      );
      if (routeSpaceId == space.id && workspaceId != null) {
        GoRouter.of(context).go(spacesRoute(workspaceId));
      }
    }
  }
}

/// Opens a small single-field rename dialog with [initialValue] prefilled and
/// returns the trimmed new name — null when cancelled, emptied or unchanged,
/// so callers can skip the round-trip in every no-op case.
Future<String?> showRenameDialog(
  BuildContext context, {
  required String title,
  required String initialValue,
}) async {
  final l10n = AppLocalizations.of(context);
  final controller = TextEditingController(text: initialValue);
  final name = await showCcDialog<String>(
    context: context,
    builder: (ctx) => CcDialog(
      title: title,
      content: SizedBox(
        width: 320,
        child: CcTextField(
          controller: controller,
          autofocus: true,
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
      ),
      actions: [
        CcButton(
          variant: CcButtonVariant.secondary,
          onPressed: () => Navigator.pop(ctx),
          child: Text(l10n.cancel),
        ),
        CcButton(
          onPressed: () => Navigator.pop(ctx, controller.text.trim()),
          child: Text(l10n.save),
        ),
      ],
    ),
  );
  if (name == null || name.isEmpty || name == initialValue) {
    return null;
  }
  return name;
}

/// Opens [space]'s repository editor: the same repo multi-select the create
/// dialog offers, WITHOUT the agent picker — agents on a space are managed
/// from the space header, never from here. Saving a selection that drops
/// repos tears those worktree folders down server-side, and one that ADDS a
/// repo re-provisions the space so the new checkout is materialized; the
/// dialog says so before the user commits to it.
///
/// Save returns as soon as the selection is written — the checkout runs in the
/// background and the space reports it through its ordinary provisioning
/// status (the composer parks behind "preparing workspace" and shows the same
/// per-repo progress a new space does), so there is nothing to await here.
Future<void> showEditSpaceReposDialog(
  BuildContext context,
  WidgetRef ref,
  Space space,
) async {
  final workspaceId = ref.requireWorkspaceId();
  final repos = await ref.read(reposForWorkspaceProvider(workspaceId).future);
  final current = await ref
      .read(messagingServiceProvider)
      .getSpaceRepos(workspaceId, space.id);
  if (!context.mounted) {
    return;
  }
  final saved = await showCcDialog<({List<String>? repoIds})>(
    context: context,
    builder: (_) => _EditSpaceReposDialog(repos: repos, current: current),
  );
  if (saved == null || !context.mounted) {
    return;
  }
  await ref
      .read(messagingServiceProvider)
      .setSpaceRepos(workspaceId, space.id, saved.repoIds);
}

class _EditSpaceReposDialog extends StatefulWidget {
  const _EditSpaceReposDialog({required this.repos, required this.current});

  /// Every repo linked to the workspace (the picker's universe).
  final List<Repo> repos;

  /// The space's effective selection on open: null → all workspace repos,
  /// an EMPTY list → explicitly none, a subset → those ids.
  final List<String>? current;

  @override
  State<_EditSpaceReposDialog> createState() => _EditSpaceReposDialogState();
}

class _EditSpaceReposDialogState extends State<_EditSpaceReposDialog> {
  /// "All workspace repos" is the default, so a null (unrestricted) selection
  /// starts as every repo checked — the same default the create dialog uses.
  late final Set<String> _selected = {
    for (final r in widget.repos)
      if (widget.current == null || widget.current!.contains(r.id)) r.id,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return CcDialog(
      title: l10n.editSpaceReposTitle,
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CcMultiSelect<String>(
              values: _selected,
              hintText: l10n.spaceReposHint,
              options: widget.repos
                  .map(
                    (repo) =>
                        CcSelectOption(value: repo.id, label: repo.fullName),
                  )
                  .toList(),
              onChanged: (next) => setState(
                () => _selected
                  ..clear()
                  ..addAll(next),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.editSpaceReposWarning,
              style: CcTypography.caption.copyWith(
                color: context.designSystem?.textTertiary,
              ),
            ),
          ],
        ),
      ),
      actions: [
        CcButton(
          variant: CcButtonVariant.secondary,
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        CcButton(
          onPressed: () {
            // Everything checked (or a repo-less workspace) is the "all
            // repos" default — persisted as null so repos added to the
            // workspace later follow the space. An explicitly emptied
            // selection stays an empty list: the space checks out nothing.
            final repoIds = _selected.length == widget.repos.length
                ? null
                : _selected.toList();
            Navigator.of(context).pop((repoIds: repoIds));
          },
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
