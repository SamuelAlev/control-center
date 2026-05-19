import 'dart:math' as math;

import 'package:cc_domain/core/domain/value_objects/agent_lifecycle_status.dart';
import 'package:cc_domain/features/governance/domain/value_objects/agent_presence.dart';
import 'package:cc_domain/features/governance/domain/value_objects/org_node.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/agent_avatar.dart';
import 'package:control_center/shared/widgets/canvas/canvas_wheel_pan.dart';
import 'package:control_center/shared/widgets/canvas/canvas_zoom_controls.dart';
import 'package:control_center/shared/widgets/dot_grid_background.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The agent reporting hierarchy, drawn as an actual top-down org chart: each
/// manager sits above its direct reports, joined to them by a connector that
/// drops from the card, runs along a bus and drops again into each report.
///
/// ## Why it looks like this
///
/// It used to be a flat list of full-width rows with a left indent per level.
/// Indentation is how a file tree says "contained by"; it is not how an
/// organisation says "reports to", and at four peers under one manager the
/// four rows read as a list that happens to start further right — the one
/// relationship the chart exists to show was the thing you had to infer.
///
/// So the layout is computed rather than nested: every card is
/// [_nodeWidth] wide, a subtree is as wide as its widest generation, and the
/// connectors are painted from those measurements. That fixed width is what
/// makes the geometry knowable without a layout pass, and what lets a
/// generation stay aligned instead of drifting with the length of a title.
///
/// It is a CANVAS, not a scroll view — the same [InteractiveViewer] over a
/// dot grid the plan studio DAG and the memory knowledge graph use. A pair of
/// nested scroll views could reach every corner of the chart but only one
/// corner at a time, and they swallowed the trackpad pan-zoom the canvases get
/// for free, so the one gesture that could have shown a whole org at once did
/// nothing here.
class OrgChartView extends ConsumerStatefulWidget {
  /// Creates an [OrgChartView] for [workspaceId].
  const OrgChartView({super.key, required this.workspaceId});

  /// The workspace whose org chart is rendered.
  final String workspaceId;

  /// Width of one card. Fixed on purpose — see the class doc.
  static const double _nodeWidth = 208;

  /// Horizontal gap between two sibling subtrees.
  static const double _siblingGap = 20;

  /// Height of the connector band between a card and its reports.
  static const double _connectorHeight = 28;

  /// How far past the chart the canvas may be panned.
  static const double _boundaryMargin = 240;

  static const double _minScale = 0.3;
  static const double _maxScale = 2.5;

  /// The width [node] and everything under it occupies.
  ///
  /// A leaf is one card; a manager is the wider of its own card and the row of
  /// its reports. Recomputed per build rather than memoised: the tree is a
  /// workspace's agents, so it is tens of nodes, and a cache keyed on a mutable
  /// tree is a staleness bug waiting for the first reorg.
  static double subtreeWidth(OrgNode node) {
    if (node.reports.isEmpty) {
      return _nodeWidth;
    }
    final childrenWidth =
        node.reports.map(subtreeWidth).reduce((a, b) => a + b) +
        _siblingGap * (node.reports.length - 1);
    return math.max(_nodeWidth, childrenWidth);
  }

  @override
  ConsumerState<OrgChartView> createState() => _OrgChartViewState();
}

class _OrgChartViewState extends ConsumerState<OrgChartView> {
  final TransformationController _transform = TransformationController();
  late final CanvasWheelPan _wheelPan = CanvasWheelPan(_transform);

  /// Measures the laid-out chart so "fit to view" has something to fit. The
  /// card heights vary with presence and lifecycle badges, so the height is a
  /// render-time fact rather than one the layout constants can predict.
  final GlobalKey _chartKey = GlobalKey();

  Size _viewport = Size.zero;
  bool _hasFitted = false;

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  /// Scales the whole chart to fit and centres it.
  ///
  /// Never magnifies past 1: a two-agent org blown up to fill a wide pane
  /// reads as a mistake, and "fit" should mean "all of it is on screen", not
  /// "it touches the edges".
  void _fitToView() {
    final size = _chartKey.currentContext?.size;
    if (size == null || size.isEmpty || _viewport.isEmpty) {
      return;
    }
    const pad = AppSpacing.xl;
    final scale = math
        .min(
          _viewport.width / (size.width + pad * 2),
          _viewport.height / (size.height + pad * 2),
        )
        .clamp(OrgChartView._minScale, 1.0)
        .toDouble();
    final dx = (_viewport.width - size.width * scale) / 2;
    final dy = (_viewport.height - size.height * scale) / 2;
    _transform.value = Matrix4.identity()
      ..translateByDouble(dx, dy, 0, 1)
      ..scaleByDouble(scale, scale, scale, 1);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final roots = ref.watch(orgChartProvider(widget.workspaceId));
    // Computed presence (availability × workload) per agent, read over RPC.
    // Empty while loading or if the read fails — the chart still renders.
    final presence =
        ref
            .watch(workspacePresenceProvider(widget.workspaceId))
            .asData
            ?.value ??
        const <String, AgentPresence>{};

    // The chart replaces the whole registry body, so it wears the same card
    // the roster does — otherwise pressing the toolbar toggle would swap a
    // framed surface for a bare one.
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: SectionCard(
        label: l10n.orgChart,
        padding: const EdgeInsets.fromLTRB(0, 14, 0, 0),
        headerPadding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.md,
        ),
        expands: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const CcDivider(),
            Expanded(child: _body(context, l10n, tokens, roots, presence)),
          ],
        ),
      ),
    );
  }

  Widget _body(
    BuildContext context,
    AppLocalizations l10n,
    DesignSystemTokens tokens,
    List<OrgNode> roots,
    Map<String, AgentPresence> presence,
  ) {
    if (roots.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Text(
          l10n.orgChartEmpty,
          style: CcTypography.bodySm.copyWith(color: tokens.textTertiary),
        ),
      );
    }

    final chartWidth =
        roots.map(OrgChartView.subtreeWidth).reduce((a, b) => a + b) +
        OrgChartView._siblingGap * 2 * (roots.length - 1);

    return ClipRect(
      child: Stack(
        // Both layers fill the viewport: the grid must not stop at the chart
        // bounds and the viewer must not size itself to its unbounded child.
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: ListenableBuilder(
                listenable: _transform,
                builder: (context, _) {
                  final m = _transform.value;
                  return DotGridBackground(
                    offset: Offset(m[12], m[13]),
                    scale: m.getMaxScaleOnAxis(),
                  );
                },
              ),
            ),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              _viewport = constraints.biggest;
              if (!_hasFitted && _viewport.isFinite && !_viewport.isEmpty) {
                _hasFitted = true;
                // The chart's height is only known once it has been laid out,
                // so the opening fit waits a frame rather than guessing.
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    _fitToView();
                  }
                });
              }
              return Listener(
                onPointerSignal: (event) => _wheelPan.onPointerSignal(
                  event,
                  viewport: constraints.biggest,
                  // Height is unknown until layout; the wheel leash only needs
                  // an honest lower bound, and the boundary margin supplies the
                  // slack past it.
                  canvas: Size(chartWidth, constraints.maxHeight),
                  boundaryMargin: OrgChartView._boundaryMargin,
                ),
                child: InteractiveViewer(
                  transformationController: _transform,
                  constrained: false,
                  minScale: OrgChartView._minScale,
                  maxScale: OrgChartView._maxScale,
                  boundaryMargin: const EdgeInsets.all(
                    OrgChartView._boundaryMargin,
                  ),
                  onInteractionStart: (_) => _wheelPan.beginInteraction(),
                  child: Padding(
                    key: _chartKey,
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (var i = 0; i < roots.length; i++) ...[
                          if (i > 0)
                            const SizedBox(width: OrgChartView._siblingGap * 2),
                          _Subtree(node: roots[i], presence: presence),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          Positioned(
            right: kCanvasControlInset,
            bottom: kCanvasControlInset,
            child: CanvasZoomControls(
              controller: _transform,
              viewport: () => _viewport,
              minScale: OrgChartView._minScale,
              maxScale: OrgChartView._maxScale,
              onReset: _fitToView,
            ),
          ),
        ],
      ),
    );
  }
}

/// One node and, recursively, everything reporting into it.
class _Subtree extends StatelessWidget {
  const _Subtree({required this.node, required this.presence});

  final OrgNode node;
  final Map<String, AgentPresence> presence;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final width = OrgChartView.subtreeWidth(node);
    final childWidths = [
      for (final r in node.reports) OrgChartView.subtreeWidth(r),
    ];

    return SizedBox(
      width: width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: OrgChartView._nodeWidth,
            child: _OrgCard(node: node, presence: presence[node.agent.id]),
          ),
          if (node.reports.isNotEmpty) ...[
            CustomPaint(
              size: const Size.fromHeight(OrgChartView._connectorHeight),
              painter: _ConnectorPainter(
                childWidths: childWidths,
                gap: OrgChartView._siblingGap,
                color: tokens.borderPrimary,
              ),
              child: const SizedBox(
                width: double.infinity,
                height: OrgChartView._connectorHeight,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < node.reports.length; i++) ...[
                  if (i > 0) const SizedBox(width: OrgChartView._siblingGap),
                  _Subtree(node: node.reports[i], presence: presence),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Paints the elbow between a card and its reports: a stub down from the
/// card's centre, a bus spanning the first and last report centres, and a stub
/// down into each report.
///
/// The bus stops at the outer reports' centres rather than spanning the whole
/// band, because a line that overshoots into empty space reads as a connection
/// to something that is not there.
class _ConnectorPainter extends CustomPainter {
  const _ConnectorPainter({
    required this.childWidths,
    required this.gap,
    required this.color,
  });

  /// Width of each report's own subtree, in display order.
  final List<double> childWidths;

  /// Horizontal gap between two sibling subtrees.
  final double gap;

  /// Hairline colour.
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (childWidths.isEmpty) {
      return;
    }
    final stroke = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Report centres, measured in the band's own coordinates. The row of
    // reports is centred under the card, so it starts wherever the band is
    // wider than the reports themselves.
    final reportsWidth =
        childWidths.reduce((a, b) => a + b) + gap * (childWidths.length - 1);
    var x = (size.width - reportsWidth) / 2;
    final centres = <double>[];
    for (final w in childWidths) {
      centres.add(x + w / 2);
      x += w + gap;
    }

    final midY = size.height / 2;
    final cardCentre = size.width / 2;

    // Down from the card, along the bus, then down into each report. Snapped to
    // a half pixel so a 1px hairline lands on one device pixel instead of
    // smearing across two.
    canvas
      ..drawLine(
        Offset(_snap(cardCentre), 0),
        Offset(_snap(cardCentre), _snap(midY)),
        stroke,
      )
      ..drawLine(
        Offset(centres.first, _snap(midY)),
        Offset(centres.last, _snap(midY)),
        stroke,
      );
    for (final centre in centres) {
      canvas.drawLine(
        Offset(_snap(centre), _snap(midY)),
        Offset(_snap(centre), size.height),
        stroke,
      );
    }
  }

  static double _snap(double v) => v.floorToDouble() + 0.5;

  @override
  bool shouldRepaint(_ConnectorPainter old) =>
      old.color != color ||
      old.gap != gap ||
      !_sameWidths(old.childWidths, childWidths);

  static bool _sameWidths(List<double> a, List<double> b) {
    if (a.length != b.length) {
      return false;
    }
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }
    return true;
  }
}

/// One agent's card in the chart: who they are, what they are doing, and
/// whether they are paused or archived.
class _OrgCard extends StatelessWidget {
  const _OrgCard({required this.node, this.presence});

  final OrgNode node;
  final AgentPresence? presence;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final agent = node.agent;
    final isPaused = agent.lifecycleStatus == AgentLifecycleStatus.paused;
    final isArchived = agent.lifecycleStatus == AgentLifecycleStatus.archived;
    final presence = this.presence;
    final reports = node.reports.length;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: tokens.panel,
        borderRadius: AppRadii.brMd,
        border: Border.all(color: tokens.borderSecondary),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AgentAvatar(
                agentId: agent.id,
                name: agent.name,
                size: 28,
                showHoverCard: false,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      agent.title,
                      style: CcTypography.bodySm.copyWith(
                        color: tokens.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      agent.role?.label ?? agent.name,
                      style: CcTypography.caption.copyWith(
                        color: tokens.textTertiary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Live presence (availability × workload), e.g. "online + working
          // (2/3)" — never colour-only; the label is explicit text. Omitted
          // until the RPC presence read resolves.
          if (presence != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              presence.summary,
              style: CcTypography.caption.copyWith(
                color: presence.hasFreeSlot
                    ? tokens.textTertiary
                    : tokens.textSecondary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (isPaused || isArchived || reports > 0) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                if (isPaused || isArchived)
                  CcBadge(
                    label: agent.lifecycleStatus.label,
                    variant: isPaused
                        ? CcBadgeVariant.warning
                        : CcBadgeVariant.neutral,
                  ),
                // The report count is what a collapsed branch would otherwise
                // hide, and it is the number a manager card is read for.
                if (reports > 0)
                  CcBadge(
                    label: AppLocalizations.of(
                      context,
                    ).orgChartReportCount(reports),
                    variant: CcBadgeVariant.neutral,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
