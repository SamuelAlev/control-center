import 'dart:async';

import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/features/messaging/domain/entities/space.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/presentation/widgets/space_hover_target.dart';
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
/// list (`SpacesSubSidebar`).
class SpaceSidebarItem extends ConsumerWidget {
  /// Creates a [SpaceSidebarItem].
  const SpaceSidebarItem({
    super.key,
    required this.space,
    required this.selected,
    required this.onPress,
    this.muted = false,
    this.conversationCount,
    this.runningShownOnConversations = false,
  });

  /// The space to render.
  final Space space;

  /// Whether the row reads as the route's selected space.
  final bool selected;

  /// Tap handler (navigation; the URL is the source of truth for selection).
  final VoidCallback onPress;

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    final status = ref.watch(spaceStatusProvider(space.id));
    // Muted agent rows never read the unread provider — their notifications are
    // deliberately suppressed.
    final unread = muted ? false : ref.watch(spaceUnreadProvider(space.id));
    final running =
        status == SpaceStatus.running && !runningShownOnConversations;

    final label = space.name.isNotEmpty ? space.name : l10n.spaceLabel;
    // The leading slot carries the running signal (a spinner), so the trailing
    // indicator stays clear of a redundant running dot.
    final leading = SpaceLeadingIcon(
      spaceId: space.id,
      running: running,
      selected: selected,
    );

    return GestureDetector(
      onSecondaryTapDown: (details) =>
          _showArchiveMenu(context, ref, details.globalPosition),
      // Touch parity: a long-press is the mobile right-click, so it OPENS the
      // same menu — archiving (or any row action) always takes the deliberate
      // second tap, never the hold itself.
      onLongPressStart: (details) =>
          _showArchiveMenu(context, ref, details.globalPosition),
      // Dwelling on the row opens a flyout to its right with the space's live
      // state (which agents and subagents are running, for how long, how much
      // context is left). The row itself is unchanged; the card is additive.
      child: SpaceHoverTarget(
        space: space,
        child: SpaceRow(
          leading: leading,
          label: label,
          selected: selected,
          status: status,
          unread: unread,
          leadingHandlesRunning: true,
          muted: muted,
          count: conversationCount,
          onPress: onPress,
        ),
      ),
    );
  }

  void _showArchiveMenu(BuildContext context, WidgetRef ref, Offset position) {
    final l10n = AppLocalizations.of(context);
    showCcMenuAt(
      context: context,
      position: position,
      items: [
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

/// A space navigation row that reproduces [CcSidebarItem]'s exact look — the
/// solid `bgBrandSolid` fill + reserved 1px `accent` border when [selected],
/// with `accentOn` content, the same hover/pressed washes and padding — so
/// spaces read as first-class sidebar items. It can't be a [CcSidebarItem]
/// itself because that widget's icon-only API hosts no [leading] widget (an
/// agent avatar / PR badge / spinner). (The 4px inter-item gap comes from the
/// enclosing [CcSidebarGroup], same as [CcSidebarItem].)
class SpaceRow extends StatelessWidget {
  /// Creates a [SpaceRow].
  const SpaceRow({
    super.key,
    required this.leading,
    required this.label,
    required this.selected,
    required this.status,
    required this.unread,
    required this.leadingHandlesRunning,
    required this.onPress,
    this.muted = false,
    this.count,
  });

  /// The leading slot: a spinner while running, else the PR badge / pencil.
  final Widget leading;

  /// The space display name.
  final String label;

  /// Whether this is the route's selected space.
  final bool selected;

  /// The space's live status (drives the trailing indicator).
  final SpaceStatus status;

  /// Whether the space has unseen agent messages (drives the notification dot
  /// on idle spaces).
  final bool unread;

  /// Whether the leading slot already shows the running signal (the space
  /// leading spins). Suppresses a redundant trailing running dot when true.
  final bool leadingHandlesRunning;

  /// Whether this is a muted agent-DM row: dimmed label and no trailing
  /// status/unread indicator.
  final bool muted;

  /// Optional conversation count, rendered as a quiet chip hugging the label
  /// (an inventory count, not a notification — it must not compete with the
  /// accent unread/needs-input signals trailing the row). Null hides it.
  final int? count;

  /// Tap handler.
  final VoidCallback onPress;

  Color _background(DesignSystemTokens t, Set<WidgetState> states) {
    if (selected) {
      return t.bgBrandSolid;
    }
    if (states.contains(WidgetState.pressed)) {
      return t.hoverStrong;
    }
    if (states.contains(WidgetState.hovered)) {
      return t.hover;
    }
    // Alpha-0 hover colour (not transparent-black), mirroring CcSidebarItem, so
    // the AnimatedContainer lerps only alpha on hover↔idle (no dark-gray flash).
    return t.hover.withValues(alpha: 0);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final fg = selected
        ? t.accentOn
        : (muted ? t.textTertiary : t.textSecondary);
    final transitioning = CcSidebarScope.transitioningOf(context) ?? false;

    return CcTappable(
      onPressed: onPress,
      borderRadius: AppRadii.brSm,
      semanticLabel: label,
      // Mirrors CcSidebarItem: the brand focus ring would vanish against the
      // selected row's solid brand fill, so on that row the ring is accentOn.
      focusRingColor: selected ? t.accentOn : null,
      builder: (context, states) {
        // Mirrors CcSidebarItem: the fill lerps over CcMotion.fast, so the
        // foreground lerps with it — same duration and curve — or a white
        // label flashes on the still-light mid-lerp fill (white-on-white on
        // select, dark-ink-on-orange on deselect).
        return TweenAnimationBuilder<Color?>(
          duration: CcMotion.fast,
          curve: CcMotion.standard,
          tween: ColorTween(end: fg),
          builder: (context, animatedFg, _) {
            final contentColor = animatedFg ?? fg;
            return AnimatedContainer(
              duration: CcMotion.fast,
              curve: CcMotion.standard,
              // Mirrors CcSidebarItem's fixed 32px row height and its
              // asymmetric inset (left 9 + the 1px reserved border = the visual
              // 10px) so a space row's leading glyph lands on the same x=27
              // line as a nav item's icon in both modes. While the width
              // animates the trailing inset drops to 0 so the fixed leading
              // glyph + gap can't overflow the narrowing row.
              height: kCcSidebarItemExtent,
              padding: EdgeInsets.only(left: 9, right: transitioning ? 0 : 10),
              decoration: BoxDecoration(
                color: _background(t, states),
                borderRadius: AppRadii.brSm,
                // A 1px border is reserved on every row (alpha-0 when idle) so the
                // layout never shifts when [selected] toggles the brand border on —
                // mirrors CcSidebarItem's selected treatment (the border reads as
                // the solid pill's edge: invisible in light, a brighter rim in
                // dark).
                border: Border.all(
                  color: selected ? t.accent : t.accent.withValues(alpha: 0),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  IconTheme.merge(
                    data: IconThemeData(color: contentColor, size: 18),
                    child: leading,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    // The label fades while the sidebar's width animates — kept
                    // in the layout so the row geometry never changes — mirroring
                    // CcSidebarItem's label fade.
                    child: AnimatedOpacity(
                      opacity: transitioning ? 0 : 1,
                      duration: CcMotion.fast,
                      curve: CcMotion.standard,
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.4,
                                fontWeight: CcTypography.regularWeight,
                                color: contentColor,
                              ),
                            ),
                          ),
                          if (count != null) ...[
                            const SizedBox(width: AppSpacing.sm),
                            SpaceCountChip(count: count!, selected: selected),
                          ],
                        ],
                      ),
                    ),
                  ),
                  if (!muted &&
                      !transitioning &&
                      SpaceTrailingIndicator.shouldShow(
                        status: status,
                        unread: unread,
                        leadingHandlesRunning: leadingHandlesRunning,
                      )) ...[
                    const SizedBox(width: AppSpacing.sm),
                    SpaceTrailingIndicator(
                      status: status,
                      unread: unread,
                      leadingHandlesRunning: leadingHandlesRunning,
                      selected: selected,
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ── Dialogs ────────────────────────────────────────────────────────────────

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
