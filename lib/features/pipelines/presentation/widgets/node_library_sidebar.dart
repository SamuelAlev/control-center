import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pipelines/domain/services/node_type_library.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Editor palette categories. The mandatory trigger entry node is not in the
/// palette (it is a fixed, single entry node), so there is no trigger category.
enum _NodeCategory { flow, pr, agents, messaging, code, demo }

/// Maps a `NodeType.id` to its palette category. Defaults to `_NodeCategory.flow`.
_NodeCategory _categoryFor(String id) {
  switch (id) {
    case 'bash.clonePr':
    case 'prReview.comment':
    case 'prompt.reviewer':
      return _NodeCategory.pr;
    case 'prompt.custom':
    case 'team.dispatch':
      return _NodeCategory.agents;
    case 'messaging.postChannel':
      return _NodeCategory.messaging;
    case 'bash.script':
      return _NodeCategory.code;
    case 'hello.greet':
    case 'hello.world':
      return _NodeCategory.demo;
    case 'prompt.join':
    case 'pipeline.condition':
    case 'condition.fileExists':
    case 'condition.anyOf':
    case 'condition.allOf':
    case 'human.gate':
    case 'flow.forEach':
    case 'flow.callPipeline':
    default:
      return _NodeCategory.flow;
  }
}

String _categoryLabel(AppLocalizations l10n, _NodeCategory c) {
  return switch (c) {
    _NodeCategory.flow => l10n.nodeCategoryFlow,
    _NodeCategory.pr => l10n.nodeCategoryPr,
    _NodeCategory.agents => l10n.nodeCategoryAgents,
    _NodeCategory.messaging => l10n.nodeCategoryMessaging,
    _NodeCategory.code => l10n.nodeCategoryCode,
    _NodeCategory.demo => l10n.nodeCategoryDemo,
  };
}

/// Vertical, categorized, searchable list of [NodeType] entries the user can
/// drag onto the editor canvas. Each entry is a [Draggable] whose payload is
/// the [NodeType].
class NodeLibrarySidebar extends StatefulWidget {
  /// Creates a [NodeLibrarySidebar].
  const NodeLibrarySidebar({super.key, required this.library});

  /// The node type library providing palette entries.
  final NodeTypeLibrary library;

  @override
  State<NodeLibrarySidebar> createState() => _NodeLibrarySidebarState();
}

class _NodeLibrarySidebarState extends State<NodeLibrarySidebar> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(
      () => setState(() => _query = _searchCtrl.text.trim().toLowerCase()),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);

    final filtered = _query.isEmpty
        ? widget.library.types
        : widget.library.types
            .where((t) =>
                t.displayName.toLowerCase().contains(_query) ||
                t.description.toLowerCase().contains(_query))
            .toList();

    // Group by category, preserving the enum declaration order.
    final grouped = <_NodeCategory, List<NodeType>>{};
    for (final t in filtered) {
      grouped.putIfAbsent(_categoryFor(t.id), () => []).add(t);
    }
    final orderedCategories =
        _NodeCategory.values.where(grouped.containsKey).toList();

    return Container(
      color: tokens.bgPrimary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
            child: Text(
              l10n.nodeLibraryTitle,
              style: TextStyle(
                color: tokens.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              l10n.nodeLibraryHint,
              style: TextStyle(color: tokens.textTertiary, fontSize: 12),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: CcTextField(
              controller: _searchCtrl,
              hintText: l10n.nodeLibrarySearchHint,
            ),
          ),
          const CcDivider(),
          Expanded(
            child: orderedCategories.isEmpty
                ? Center(
                    child: Text(
                      l10n.nodeLibraryNoMatches,
                      style:
                          TextStyle(color: tokens.textTertiary, fontSize: 12),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    children: [
                      for (final category in orderedCategories) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(2, 6, 2, 6),
                          child: Text(
                            _categoryLabel(l10n, category).toUpperCase(),
                            style: TextStyle(
                              color: tokens.textTertiary,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                        for (final type in grouped[category]!)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: _DraggableEntry(type: type),
                          ),
                        const SizedBox(height: 6),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _DraggableEntry extends StatelessWidget {
  const _DraggableEntry({required this.type});

  final NodeType type;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final card = CcCard(
      padding: const EdgeInsets.all(10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            LucideIcons.gripVertical,
            size: 16,
            color: tokens.textTertiary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type.displayName,
                  style: TextStyle(
                    color: tokens.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  type.description,
                  style: TextStyle(
                    color: tokens.textTertiary,
                    fontSize: 11,
                    height: 1.35,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return Draggable<NodeType>(
      data: type,
      dragAnchorStrategy: pointerDragAnchorStrategy,
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(width: 220, child: card),
      ),
      childWhenDragging: Opacity(opacity: 0.4, child: card),
      child: card,
    );
  }
}
