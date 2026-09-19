import 'package:cc_domain/features/pipelines/domain/services/node_type_library.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pipelines/presentation/widgets/node_type_visuals.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';

// RTL carve-out: DAG canvases stay LTR; popovers open past the output port
// on the tile's trailing (physical-right) edge.

/// "+" just past a tile's output port. Opens a searchable type picker
/// (n8n-style insert-after) and reports the pick via [onInsert].
class PipelineQuickInsert extends StatefulWidget {
  /// Creates a [PipelineQuickInsert].
  const PipelineQuickInsert({
    super.key,
    required this.library,
    required this.onInsert,
  });

  /// Palette to search.
  final NodeTypeLibrary library;

  /// Called with the chosen type; the popover is already closed.
  final void Function(NodeType type) onInsert;

  @override
  State<PipelineQuickInsert> createState() => _PipelineQuickInsertState();
}

class _PipelineQuickInsertState extends State<PipelineQuickInsert> {
  final _overlay = CcOverlayController();

  @override
  void dispose() {
    _overlay.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // The "+" lives inside InteractiveViewer. A child TapGestureRecognizer
    // loses the arena to the viewer's ScaleGestureRecognizer, so a tap that
    // hit-tests the button never fires onPressed. Pointer-down is not a
    // gesture — it always reaches us — and IgnorePointer keeps the button
    // from toggling a second time on the same click.
    return CcPopover(
      controller: _overlay,
      toggleOnTargetTap: false,
      targetAnchor: Alignment.centerRight,
      followerAnchor: Alignment.centerLeft,
      offset: const Offset(8, 0),
      target: CcTooltip(
        message: l10n.pipelineAddStep,
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (_) => _overlay.toggle(),
          child: IgnorePointer(
            child: CcIconButton(
              icon: AppIcons.plus,
              size: CcButtonSize.sm,
              tooltip: l10n.pipelineAddStep,
              semanticLabel: l10n.pipelineAddStep,
              onPressed: () {},
            ),
          ),
        ),
      ),
      overlayBuilder: (context, _) => SizedBox(
        width: 280,
        height: 320,
        child: PipelineNodeTypePicker(
          library: widget.library,
          onPick: (type) {
            _overlay.hide();
            widget.onInsert(type);
          },
        ),
      ),
    );
  }
}

/// Searchable, category-grouped list of [NodeType]s. Shared layout with the
/// sidebar so a type cannot hide in the picker that the palette still shows.
class PipelineNodeTypePicker extends StatefulWidget {
  /// Creates a [PipelineNodeTypePicker].
  const PipelineNodeTypePicker({
    super.key,
    required this.library,
    required this.onPick,
  });

  /// Palette to search.
  final NodeTypeLibrary library;

  /// Choosing a row.
  final void Function(NodeType type) onPick;

  @override
  State<PipelineNodeTypePicker> createState() => _PipelineNodeTypePickerState();
}

class _PipelineNodeTypePickerState extends State<PipelineNodeTypePicker> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _search.addListener(
      () => setState(() => _query = _search.text.trim().toLowerCase()),
    );
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final grouped = groupNodeTypes(filterNodeTypes(widget.library.types, _query));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.sm,
          ),
          child: CcTextField(
            controller: _search,
            hintText: l10n.nodeLibrarySearchHint,
            size: CcTextFieldSize.sm,
          ),
        ),
        const CcDivider(),
        Expanded(
          child: grouped.isEmpty
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
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.sm,
                  ),
                  children: [
                    for (final (category, types) in grouped) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(6, 8, 6, 4),
                        child: Text(
                          pipelineNodeCategoryLabel(
                            l10n,
                            category,
                          ).toUpperCase(),
                          style: pipelineNodeEyebrowStyle(tokens),
                        ),
                      ),
                      for (final type in types)
                        _PickerRow(
                          type: type,
                          onTap: () => widget.onPick(type),
                        ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

/// Searchable list of start-trigger palette entries. Used by the empty-canvas
/// ghost tile so each domain event is as findable as a body node.
class PipelineTriggerTypePicker extends StatefulWidget {
  /// Creates a [PipelineTriggerTypePicker].
  const PipelineTriggerTypePicker({super.key, required this.onPick});

  /// Chosen [TriggerPaletteEntry.eventType].
  final void Function(String eventType) onPick;

  @override
  State<PipelineTriggerTypePicker> createState() =>
      _PipelineTriggerTypePickerState();
}

class _PipelineTriggerTypePickerState extends State<PipelineTriggerTypePicker> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _search.addListener(
      () => setState(() => _query = _search.text.trim().toLowerCase()),
    );
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final entries = filterTriggerEntries(triggerPaletteEntries(l10n), _query);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.sm,
          ),
          child: CcTextField(
            controller: _search,
            hintText: l10n.nodeLibrarySearchHint,
            size: CcTextFieldSize.sm,
          ),
        ),
        const CcDivider(),
        Expanded(
          child: entries.isEmpty
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
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.sm,
                  ),
                  children: [
                    for (final entry in entries)
                      _TriggerPickerRow(
                        entry: entry,
                        onTap: () => widget.onPick(entry.eventType),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _TriggerPickerRow extends StatelessWidget {
  const _TriggerPickerRow({required this.entry, required this.onTap});

  final TriggerPaletteEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    return CcTappable(
      onPressed: onTap,
      builder: (context, states) {
        final hovered = states.contains(WidgetState.hovered);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          child: ColoredBox(
            color: hovered ? tokens.bgSecondary : const Color(0x00000000),
            child: Row(
              children: [
                Icon(entry.icon, size: 14, color: tokens.textSecondary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: tokens.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        entry.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: tokens.textTertiary,
                          fontSize: 11,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Popover listing start-trigger palette entries. Used by the empty-canvas
/// ghost tile.
class PipelineTriggerGhostPicker extends StatefulWidget {
  /// Creates a [PipelineTriggerGhostPicker].
  const PipelineTriggerGhostPicker({
    super.key,
    required this.onPick,
    required this.child,
  });

  /// Chosen [TriggerPaletteEntry.eventType].
  final void Function(String eventType) onPick;

  /// Ghost tile body (the dashed "Add a trigger" row).
  final Widget child;

  @override
  State<PipelineTriggerGhostPicker> createState() =>
      _PipelineTriggerGhostPickerState();
}

class _PipelineTriggerGhostPickerState extends State<PipelineTriggerGhostPicker> {
  final _overlay = CcOverlayController();

  @override
  void dispose() {
    _overlay.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CcPopover(
      controller: _overlay,
      toggleOnTargetTap: false,
      targetAnchor: Alignment.centerRight,
      followerAnchor: Alignment.centerLeft,
      offset: const Offset(8, 0),
      target: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (_) => _overlay.toggle(),
        child: widget.child,
      ),
      overlayBuilder: (context, _) => SizedBox(
        width: 280,
        height: 320,
        child: PipelineTriggerTypePicker(
          onPick: (eventType) {
            _overlay.hide();
            widget.onPick(eventType);
          },
        ),
      ),
    );
  }
}

class _PickerRow extends StatelessWidget {
  const _PickerRow({required this.type, required this.onTap});

  final NodeType type;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final visual = visualForNodeTypeId(type.id);
    return CcTappable(
      onPressed: onTap,
      builder: (context, states) {
        final hovered = states.contains(WidgetState.hovered);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          child: ColoredBox(
            color: hovered ? tokens.bgSecondary : const Color(0x00000000),
            child: Row(
              children: [
                Icon(visual.icon, size: 14, color: tokens.textSecondary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    type.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: tokens.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
