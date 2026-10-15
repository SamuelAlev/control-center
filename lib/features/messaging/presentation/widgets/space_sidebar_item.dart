import 'dart:async';

import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/features/messaging/domain/entities/space.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/presentation/widgets/space_folder_picker_dialog.dart';
import 'package:control_center/features/messaging/presentation/widgets/space_route_selection.dart';
import 'package:control_center/features/messaging/presentation/widgets/space_row.dart';
import 'package:control_center/features/messaging/presentation/widgets/space_row_adornments.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/messaging/providers/space_folder_providers.dart';
import 'package:control_center/features/repos/providers/repo_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_scope.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

export 'package:control_center/features/messaging/presentation/widgets/space_route_selection.dart';
export 'package:control_center/features/messaging/presentation/widgets/space_row.dart';

part 'space_sidebar_item_route.dart';
part 'space_sidebar_item_repo_dialog.dart';

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
    this.interactive = true,
    this.menuRevealed = false,
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

  /// Whether this row is its own press target. False when an enclosing card
  /// owns the press, so the title is content on that card.
  final bool interactive;

  /// Shows the overflow trigger from the enclosing card's hover or focus.
  final bool menuRevealed;

  @override
  bool get fluidHoverEnabled => true;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final workspaceId = ref.watch(activeWorkspaceIdProvider);

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
          unreadConversationCount: muted
              ? 0
              : ref.watch(spaceUnreadConversationCountProvider(space.id)),
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
      onPress: interactive ? onPress : null,
      menuRevealed: menuRevealed,
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
        if (workspaceId != null && !muted)
          CcMenuItem(
            label: l10n.moveSpaceToFolder,
            icon: AppIcons.folder,
            onSelected: () => unawaited(
              showMoveSpaceToFolderDialog(
                context,
                ref,
                workspaceId: workspaceId,
                spaceId: space.id,
              ),
            ),
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

  /// Archives the space and removes its personal folder membership. Messages,
  /// participants and worktrees survive; restoring leaves it unfiled.
  Future<void> _archive(BuildContext context, WidgetRef ref) async {
    final workspaceId = ref.requireWorkspaceId();
    final router = GoRouter.of(context);
    await archiveSpaceAndUnlink(ref, workspaceId, space.id);

    // Archiving may unmount this row before the preference write finishes.
    // Read the live URL from the captured router rather than this context.
    if (selectedSpaceIdFromLocation(
          router.routeInformationProvider.value.uri.path,
          workspaceId,
        ) ==
        space.id) {
      router.go(spacesRoute(workspaceId));
    }
  }
}

/// Opens a single-field name dialog, prefilled with [initialValue].
/// Returns null for cancellation, an empty name or an unchanged name.
Future<String?> showRenameDialog(
  BuildContext context, {
  required String title,
  required String initialValue,
  String? hintText,
  String? confirmLabel,
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
          hintText: hintText,
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
          child: Text(confirmLabel ?? l10n.save),
        ),
      ],
    ),
  );
  if (name == null || name.isEmpty || name == initialValue) {
    return null;
  }
  return name;
}
