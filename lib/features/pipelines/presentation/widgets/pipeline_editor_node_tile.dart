import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_definition.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_trigger.dart';
import 'package:cc_domain/features/pipelines/domain/entities/step_kind.dart';
import 'package:cc_domain/features/pipelines/domain/services/node_type_library.dart';
import 'package:cc_domain/features/pipelines/domain/services/template_renderer.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pipelines/presentation/widgets/node_type_visuals.dart';
import 'package:control_center/features/pipelines/presentation/widgets/pipeline_editor_connect_port.dart';
import 'package:control_center/features/pipelines/presentation/widgets/pipeline_editor_geometry.dart';
import 'package:control_center/features/pipelines/presentation/widgets/pipeline_quick_insert.dart';
import 'package:control_center/features/pipelines/presentation/widgets/template_node_title.dart';
import 'package:control_center/features/pipelines/presentation/widgets/trigger_labels.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/graph_node_card.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/widgets.dart';

/// One editor tile: card, eyebrow, output port.
///
/// Dragging the card moves the node (trackpad two-finger pans are left to
/// the viewer — same carve-out as the knowledge graph). Dragging the port
/// starts an on-canvas connect; dropping on empty canvas opens a type picker.
class PipelineEditorNodeTile extends StatefulWidget {
  /// Creates a [PipelineEditorNodeTile].
  const PipelineEditorNodeTile({
    super.key,
    required this.step,
    required this.library,
    required this.selected,
    required this.connectSource,
    required this.dropTarget,
    required this.awaitingConnect,
    required this.eyebrow,
    required this.onSelect,
    required this.onMoveUpdate,
    required this.onMoveEnd,
    required this.onConnectDragStart,
    required this.onConnectDragUpdate,
    required this.onConnectDragEnd,
    this.onConnectDragCancel,
    this.onConnectHandleHover,
  });

  /// Step this tile represents.
  final PipelineStepDefinition step;

  /// Palette used to resolve icon / title fallback.
  final NodeTypeLibrary library;

  /// Whether this tile is the editor's selection.
  final bool selected;

  /// Whether `e` marked this tile as the connect source (shape marker).
  final bool connectSource;

  /// Whether a connect-drag is hovering this tile as a valid target.
  final bool dropTarget;

  /// True while any connect-drag is in flight (shows input ports on
  /// valid targets).
  final bool awaitingConnect;

  /// Optional uppercase eyebrow (`When this happens` / `Do this`).
  final String? eyebrow;

  /// Tap / keyboard select.
  final VoidCallback onSelect;

  /// Live drag of the tile, in definition-space delta (already zoom-corrected).
  final void Function(Offset delta) onMoveUpdate;

  /// Commit the drag.
  final VoidCallback onMoveEnd;

  /// Pointer landed on the output port.
  final VoidCallback onConnectDragStart;

  /// Port-drag pointer, in global coordinates (canvas converts to definition).
  final void Function(Offset globalPosition) onConnectDragUpdate;

  /// Port-drag released.
  final void Function(Offset globalPosition) onConnectDragEnd;

  /// Port-drag cancelled (no edge).
  final VoidCallback? onConnectDragCancel;

  /// Pointer entered/left the output handle.
  final ValueChanged<bool>? onConnectHandleHover;

  @override
  State<PipelineEditorNodeTile> createState() => _PipelineEditorNodeTileState();
}

class _PipelineEditorNodeTileState extends State<PipelineEditorNodeTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final type = nodeTypeForStep(widget.step, widget.library);
    final visual = visualForStep(widget.step, widget.library);
    final isTrigger = widget.step.kind == StepKind.trigger;
    final title =
        widget.step.config.label ?? type?.displayName ?? widget.step.id;
    final subtitle = _subtitle(l10n, type);
    final glyphColor = isTrigger ? tokens.fgBrandPrimary : tokens.textSecondary;
    // Placeholders stay authored on the editor; draw them as variable badges
    // so `#{{pr_number}}` does not read as a broken template.
    final titleChild = const TemplateRenderer().containsPlaceholders(title)
        ? TemplateNodeTitle(title)
        : null;

    // Outer box is the visual card plus trailing chrome. Clip.none is paint
    // only — a 220-wide RenderBox would reject hits on the port, so it sits
    // at positive `left` inside [kPipelineEditorTileExtentWidth].
    // MouseRegion is defer-to-child so the empty chrome strip does not eat
    // canvas taps. The card pan/tap target stops short of the output handle
    // so a press on the bullet cannot start a node drag. The eyebrow stays
    // painted above the box (non-interactive).
    return MouseRegion(
      opaque: false,
      hitTestBehavior: HitTestBehavior.deferToChild,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: SizedBox(
        width: kPipelineEditorTileExtentWidth,
        height: kPipelineEditorNodeHeight,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 0,
              top: 0,
              width: kPipelineEditorNodeWidth,
              height: kPipelineEditorNodeHeight,
              child: IgnorePointer(
                child: GraphNodeCard(
                  glyph: Icon(visual.icon, size: 14, color: glyphColor),
                  title: title,
                  titleChild: titleChild,
                  subtitle: subtitle,
                  selected: widget.selected,
                  hovered: _hovered || widget.dropTarget,
                  fill: isTrigger ? tokens.bgBrandPrimary : null,
                  border: widget.connectSource
                      ? tokens.accent
                      : (isTrigger ? tokens.borderBrand : null),
                ),
              ),
            ),
            Positioned(
              left: 0,
              top: 0,
              width: kPipelineEditorNodeWidth - 20,
              height: kPipelineEditorNodeHeight,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                supportedDevices: const {
                  PointerDeviceKind.mouse,
                  PointerDeviceKind.touch,
                  PointerDeviceKind.stylus,
                  PointerDeviceKind.invertedStylus,
                  PointerDeviceKind.unknown,
                },
                onTap: widget.onSelect,
                onPanUpdate: (d) => widget.onMoveUpdate(d.delta),
                onPanEnd: (_) => widget.onMoveEnd(),
              ),
            ),
            if (widget.connectSource)
              Positioned(
                left: kPipelineEditorNodeWidth - 20,
                top: 6,
                child: IgnorePointer(
                  child: Icon(AppIcons.link, size: 12, color: tokens.accent),
                ),
              ),
            if (widget.eyebrow != null)
              Positioned(
                left: 0,
                width: kPipelineEditorNodeWidth,
                top: -18,
                child: Text(
                  widget.eyebrow!.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: pipelineNodeEyebrowStyle(tokens),
                ),
              ),
            if (!isTrigger && (widget.dropTarget || widget.awaitingConnect))
              Positioned(
                left: -6,
                top: (kPipelineEditorNodeHeight - 16) / 2,
                child: PipelineEditorInputPort(emphasized: widget.dropTarget),
              ),
            Positioned(
              key: PipelineEditorConnectPort.keyFor(widget.step.id),
              left: kPipelineEditorNodeWidth - 20,
              top: (kPipelineEditorNodeHeight - 40) / 2,
              child: PipelineEditorConnectPort(
                tooltip: l10n.pipelineDragToConnect,
                emphasized: widget.connectSource || widget.selected,
                onDragStart: widget.onConnectDragStart,
                onDragUpdate: widget.onConnectDragUpdate,
                onDragEnd: widget.onConnectDragEnd,
                onDragCancel: widget.onConnectDragCancel,
                onHoverChange: widget.onConnectHandleHover,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _subtitle(AppLocalizations l10n, NodeType? type) {
    final prompt = widget.step.config.prompt?.trim();
    if (prompt != null && prompt.isNotEmpty) {
      return _firstLine(prompt);
    }
    final script = widget.step.config.script?.trim();
    if (script != null && script.isNotEmpty) {
      return _firstLine(script);
    }
    final agent = widget.step.config.agentId?.trim();
    if (agent != null && agent.isNotEmpty) {
      return agent;
    }
    final team = widget.step.config.teamId?.trim();
    if (team != null && team.isNotEmpty) {
      return team;
    }
    return type?.displayName ?? widget.step.bodyKey;
  }

  String _firstLine(String text) {
    for (final line in text.split('\n')) {
      final t = line.trim();
      if (t.isNotEmpty) {
        return t;
      }
    }
    return text;
  }
}

/// One start-trigger tile. It *is* the graph node (id matches the
/// [PipelineTrigger] row), so outgoing wires belong only to this start.
class PipelineEditorTriggerTile extends StatefulWidget {
  /// Creates a [PipelineEditorTriggerTile].
  const PipelineEditorTriggerTile({
    super.key,
    required this.trigger,
    required this.selected,
    required this.connectSource,
    required this.eyebrow,
    required this.onSelect,
    required this.onMoveUpdate,
    required this.onMoveEnd,
    required this.onConnectDragStart,
    required this.onConnectDragUpdate,
    required this.onConnectDragEnd,
    this.onConnectDragCancel,
    this.onConnectHandleHover,
  });

  /// The trigger this tile is.
  final PipelineTrigger trigger;

  /// Whether [trigger] is the editor selection.
  final bool selected;

  /// Whether this tile started the in-flight connect.
  final bool connectSource;

  /// Optional uppercase eyebrow (first tile only).
  final String? eyebrow;

  /// Tap selects this trigger.
  final VoidCallback onSelect;

  /// Live drag of the tile, in definition-space delta.
  final void Function(Offset delta) onMoveUpdate;

  /// Commit the drag.
  final VoidCallback onMoveEnd;

  /// Output-port pan start.
  final VoidCallback onConnectDragStart;

  /// Output-port pan update (global).
  final void Function(Offset globalPosition) onConnectDragUpdate;

  /// Output-port pan end (global).
  final void Function(Offset globalPosition) onConnectDragEnd;

  /// Port-drag cancelled.
  final VoidCallback? onConnectDragCancel;

  /// Pointer entered/left the output handle.
  final ValueChanged<bool>? onConnectHandleHover;

  @override
  State<PipelineEditorTriggerTile> createState() =>
      _PipelineEditorTriggerTileState();
}

class _PipelineEditorTriggerTileState extends State<PipelineEditorTriggerTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final enabled = widget.trigger.enabled;
    final title = triggerEventLabel(l10n, widget.trigger.eventType);
    final subtitle = triggerDetailLabel(l10n, widget.trigger);
    final glyphColor = enabled ? tokens.fgBrandPrimary : tokens.textTertiary;

    return MouseRegion(
      opaque: false,
      hitTestBehavior: HitTestBehavior.deferToChild,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: SizedBox(
        width: kPipelineEditorTileExtentWidth,
        height: kPipelineEditorNodeHeight,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 0,
              top: 0,
              width: kPipelineEditorNodeWidth,
              height: kPipelineEditorNodeHeight,
              child: IgnorePointer(
                child: Opacity(
                  opacity: enabled ? 1 : 0.55,
                  child: GraphNodeCard(
                    glyph: Icon(
                      iconForTriggerEventType(widget.trigger.eventType),
                      size: 14,
                      color: glyphColor,
                    ),
                    title: title,
                    subtitle: subtitle,
                    selected: widget.selected,
                    hovered: _hovered,
                    fill: enabled ? tokens.bgBrandPrimary : tokens.bgSecondary,
                    border: widget.connectSource
                        ? tokens.accent
                        : (enabled
                              ? tokens.borderBrand
                              : tokens.borderSecondary),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              top: 0,
              width: kPipelineEditorNodeWidth - 20,
              height: kPipelineEditorNodeHeight,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                supportedDevices: const {
                  PointerDeviceKind.mouse,
                  PointerDeviceKind.touch,
                  PointerDeviceKind.stylus,
                  PointerDeviceKind.invertedStylus,
                  PointerDeviceKind.unknown,
                },
                onTap: widget.onSelect,
                onPanUpdate: (d) => widget.onMoveUpdate(d.delta),
                onPanEnd: (_) => widget.onMoveEnd(),
              ),
            ),
            if (!enabled)
              Positioned(
                // RTL carve-out: DAG tiles stay LTR; chip sits on the card.
                left: kPipelineEditorNodeWidth - 72,
                top: 6,
                width: 64,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: tokens.bgPrimary,
                    border: Border.all(color: tokens.borderSecondary),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    child: Text(
                      l10n.disabled,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: tokens.textSecondary,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                ),
              ),
            if (widget.connectSource)
              Positioned(
                left: kPipelineEditorNodeWidth - 20,
                top: 6,
                child: IgnorePointer(
                  child: Icon(AppIcons.link, size: 12, color: tokens.accent),
                ),
              ),
            if (widget.eyebrow != null)
              Positioned(
                left: 0,
                width: kPipelineEditorNodeWidth,
                top: -18,
                child: Text(
                  widget.eyebrow!.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: pipelineNodeEyebrowStyle(tokens),
                ),
              ),
            Positioned(
              key: PipelineEditorConnectPort.keyFor(widget.trigger.id),
              left: kPipelineEditorNodeWidth - 20,
              top: (kPipelineEditorNodeHeight - 40) / 2,
              child: PipelineEditorConnectPort(
                tooltip: l10n.pipelineDragToConnect,
                emphasized: widget.connectSource || widget.selected,
                onDragStart: widget.onConnectDragStart,
                onDragUpdate: widget.onConnectDragUpdate,
                onDragEnd: widget.onConnectDragEnd,
                onDragCancel: widget.onConnectDragCancel,
                onHoverChange: widget.onConnectHandleHover,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Placeholder at the entry anchor when the template has no start triggers.
class PipelineEditorGhostTriggerTile extends StatelessWidget {
  /// Creates a [PipelineEditorGhostTriggerTile].
  const PipelineEditorGhostTriggerTile({super.key, required this.onAddTrigger});

  /// Ghost-picker pick.
  final void Function(String eventType) onAddTrigger;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      width: kPipelineEditorNodeWidth,
      height: kPipelineEditorNodeHeight,
      child: CustomPaint(
        painter: _DashedRectPainter(color: tokens.borderSecondary),
        child: PipelineTriggerGhostPicker(
          onPick: onAddTrigger,
          child: Row(
            children: [
              const SizedBox(width: 12),
              Icon(AppIcons.plus, size: 14, color: tokens.textTertiary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.pipelineAddTrigger,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: tokens.textSecondary,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedRectPainter extends CustomPainter {
  _DashedRectPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()..addRect(Offset.zero & size);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    const dash = 5.0;
    const gap = 4.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = (distance + dash).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRectPainter old) => old.color != color;
}
