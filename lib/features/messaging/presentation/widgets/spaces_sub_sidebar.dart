import 'package:cc_domain/features/messaging/domain/entities/space.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/presentation/widgets/conversations_sidebar_section.dart';
import 'package:control_center/features/messaging/presentation/widgets/space_sidebar_item.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The spaces directory's contextual sub-sidebar: a settings-like panel
/// (title row + name filter on top) listing every space of the active
/// workspace, shown next to the content area on `/spaces` routes while the
/// global sidebar is collapsed to its icon-only rail. (In the expanded sidebar
/// the inline [ConversationsSidebarSection] already carries the space list,
/// so mounting both would duplicate it.)
///
/// Rows reuse [SpaceSidebarItem], so live status, unread dots, PR badges,
/// and the delete affordances behave exactly like the global sidebar's list;
/// tapping a row navigates to that space ([spaceRoute]).
class SpacesSubSidebar extends ConsumerStatefulWidget {
  /// Creates a [SpacesSubSidebar].
  const SpacesSubSidebar({super.key});

  @override
  ConsumerState<SpacesSubSidebar> createState() => _SpacesSubSidebarState();
}

class _SpacesSubSidebarState extends ConsumerState<SpacesSubSidebar> {
  /// Free-text filter narrowing the space list by name (mirrors the
  /// settings sub-sidebar's category filter).
  final TextEditingController _filterController = TextEditingController();
  String _filter = '';

  @override
  void initState() {
    super.initState();
    _filterController.addListener(() {
      final next = _filterController.text;
      if (next != _filter) {
        setState(() => _filter = next);
      }
    });
  }

  @override
  void dispose() {
    _filterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    // Keeps the read-cursor side effect alive while the directory is mounted:
    // in rail mode the global sidebar's inline space list is gone, so this
    // is the watcher that stamps the read cursor on selection.
    ref.watch(selectedSpaceReadCursorEffectProvider);
    final workspaceId = ref.watch(activeWorkspaceIdProvider);
    // The URL is the source of truth for the open space (same derivation as
    // the global sidebar's list — the shell sits above the space route).
    final routeSpaceId = selectedSpaceIdFromLocation(
      GoRouterState.of(context).uri.path,
      workspaceId,
    );
    final spaces = workspaceId != null
        ? ref.watch(workspaceVisibleSpacesProvider(workspaceId))
        : ref.watch(visibleSpacesProvider);

    final filter = _filter.trim().toLowerCase();
    bool matches(Space c) {
      if (filter.isEmpty) {
        return true;
      }
      final name = c.name.isNotEmpty ? c.name : l10n.spaceLabel;
      return name.toLowerCase().contains(filter);
    }

    final humanSpaces = spaces
        .where((c) => !c.kind.isAgentPeer && matches(c))
        .toList();
    final agentSpaces = spaces
        .where((c) => c.kind.isAgentPeer && matches(c))
        .toList();

    void open(String spaceId) {
      final wsId = workspaceId;
      if (wsId != null) {
        GoRouter.of(context).go(spaceRoute(wsId, spaceId));
      }
    }

    return CcSidebar(
      width: 240,
      header: _SpacesSidebarHeader(controller: _filterController),
      children: [
        if (spaces.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
            child: Text(
              l10n.noSpacesYet,
              style: CcTypography.caption.copyWith(color: t.textTertiary),
            ),
          )
        else if (humanSpaces.isEmpty && agentSpaces.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Text(
              l10n.noSpacesMatch(_filter.trim()),
              style: CcTypography.caption.copyWith(color: t.textTertiary),
            ),
          )
        else ...[
          CcSidebarGroup(
            label: l10n.spaces,
            children: [
              for (final space in humanSpaces)
                SpaceSidebarItem(
                  space: space,
                  selected: space.id == routeSpaceId,
                  onPress: () => open(space.id),
                ),
            ],
          ),
          if (agentSpaces.isNotEmpty)
            CcSidebarGroup(
              label: l10n.agentsSectionLabel,
              children: [
                for (final space in agentSpaces)
                  SpaceSidebarItem(
                    space: space,
                    selected: space.id == routeSpaceId,
                    muted: true,
                    onPress: () => open(space.id),
                  ),
              ],
            ),
        ],
      ],
    );
  }
}

/// Header for the spaces sub-sidebar: a title row (with the new-space
/// action) plus the name filter that narrows the list below — the same shape
/// as the settings sub-sidebar header.
class _SpacesSidebarHeader extends ConsumerWidget {
  const _SpacesSidebarHeader({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                AppIcons.messagesSquare,
                size: 16,
                color: context.designSystem?.textTertiary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.spaces,
                  style: CcTypography.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: context.ds.textPrimary,
                  ),
                ),
              ),
              CcIconButton(
                icon: AppIcons.plus,
                size: CcButtonSize.sm,
                variant: CcButtonVariant.ghost,
                tooltip: l10n.newSpace,
                onPressed: () => showNewSpaceDialog(context, ref),
              ),
            ],
          ),
          const SizedBox(height: 12),
          CcTextField(controller: controller, hintText: l10n.filterSpacesHint),
        ],
      ),
    );
  }
}
