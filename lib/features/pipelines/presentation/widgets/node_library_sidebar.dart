import 'package:cc_domain/features/pipelines/domain/services/node_type_library.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pipelines/presentation/widgets/node_type_visuals.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';

/// Vertical, categorized, searchable list of [NodeType] entries the user can
/// drag onto the editor canvas. Each entry is a [Draggable] whose payload is
/// the [NodeType]. Icons come from [visualForNodeTypeId] so the palette and
/// the canvas tiles agree.
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
    final triggerEntries = filterTriggerEntries(
      triggerPaletteEntries(l10n),
      _query,
    );
    final grouped = groupNodeTypes(
      filterNodeTypes(widget.library.types, _query),
    );
    final empty = triggerEntries.isEmpty && grouped.isEmpty;

    return ColoredBox(
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
            child: empty
                ? Center(
                    child: Text(
                      l10n.nodeLibraryNoMatches,
                      style: TextStyle(
                        color: tokens.textTertiary,
                        fontSize: 12,
                      ),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    children: [
                      if (triggerEntries.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(2, 6, 2, 6),
                          child: Text(
                            l10n.nodeCategoryTriggers.toUpperCase(),
                            style: pipelineNodeEyebrowStyle(tokens),
                          ),
                        ),
                        for (final entry in triggerEntries)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: _PaletteDraggable<TriggerPaletteEntry>(
                              data: entry,
                              icon: entry.icon,
                              title: entry.title,
                              description: entry.description,
                            ),
                          ),
                        const SizedBox(height: 6),
                      ],
                      for (final (category, types) in grouped) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(2, 6, 2, 6),
                          child: Text(
                            pipelineNodeCategoryLabel(
                              l10n,
                              category,
                            ).toUpperCase(),
                            style: pipelineNodeEyebrowStyle(tokens),
                          ),
                        ),
                        for (final type in types)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: _PaletteDraggable<NodeType>(
                              data: type,
                              icon: visualForNodeTypeId(type.id).icon,
                              title: type.displayName,
                              description: type.description,
                            ),
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

/// Drag source for one palette row. Hover washes the card; the cursor is
/// grab at rest and grabbing while the payload is in flight.
class _PaletteDraggable<T extends Object> extends StatefulWidget {
  const _PaletteDraggable({
    required this.data,
    required this.icon,
    required this.title,
    required this.description,
  });

  final T data;
  final IconData icon;
  final String title;
  final String description;

  @override
  State<_PaletteDraggable<T>> createState() => _PaletteDraggableState<T>();
}

class _PaletteDraggableState<T extends Object>
    extends State<_PaletteDraggable<T>> {
  bool _hovered = false;
  bool _dragging = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    Widget card({required bool washed}) {
      return CcCard(
        hovered: washed,
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(widget.icon, size: 16, color: tokens.textSecondary),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: TextStyle(
                      color: tokens.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.description,
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
    }

    final rest = card(washed: _hovered && !_dragging);
    return MouseRegion(
      cursor: _dragging ? SystemMouseCursors.grabbing : SystemMouseCursors.grab,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Draggable<T>(
        data: widget.data,
        dragAnchorStrategy: pointerDragAnchorStrategy,
        onDragStarted: () => setState(() => _dragging = true),
        onDragEnd: (_) => setState(() => _dragging = false),
        feedback: SizedBox(width: 220, child: card(washed: false)),
        childWhenDragging: Opacity(opacity: 0.4, child: card(washed: false)),
        child: rest,
      ),
    );
  }
}
