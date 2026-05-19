import 'dart:math' show max, min;

import 'package:cc_domain/core/domain/entities/memory_fact.dart';
import 'package:cc_domain/core/domain/entities/memory_policy.dart';
import 'package:cc_domain/features/memory/domain/entities/memory_domain.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/memory/presentation/widgets/confidence_meter.dart';
import 'package:control_center/features/memory/presentation/widgets/fact_edit_dialog.dart';
import 'package:control_center/features/memory/presentation/widgets/knowledge_graph_layout.dart';
import 'package:control_center/features/memory/presentation/widgets/knowledge_graph_node_sheet.dart';
import 'package:control_center/features/memory/presentation/widgets/memory_chip.dart';
import 'package:control_center/features/memory/presentation/widgets/memory_error_view.dart';
import 'package:control_center/features/memory/presentation/widgets/policy_edit_dialog.dart';
import 'package:control_center/features/memory/providers/memory_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/canvas/canvas_wheel_pan.dart';
import 'package:control_center/shared/widgets/canvas/canvas_zoom_controls.dart';
import 'package:control_center/shared/widgets/dot_grid_background.dart';
import 'package:control_center/shared/widgets/empty_state.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Node sizes. Sized so labels stay legible without zooming.
const _domainNodeSize = Size(148, 86);
const _topicNodeSize = Size(152, 64);
const _factNodeSize = Size(184, 116);
const _policyNodeSize = Size(168, 96);

/// Slack between a cluster's outermost card and its hull.
const _hullPadding = 26.0;

// Interaction bounds for the canvas viewport.
const _minScale = 0.25;
const _maxScale = 4.0;
// Slack added around the content so nodes stay draggable past the edges.
const _canvasMargin = 600.0;
// The pan leash. Infinite on purpose: unlike the plan DAG and the org chart,
// this canvas has DRAGGABLE nodes, so a person moves a card into the slack
// around the graph and then expects to follow it there. A finite boundary
// would also snap the transform the first time it was dragged out of bounds,
// which reads as the graph jumping. "Fit to view" is the way back.
const _boundaryMargin = double.infinity;

/// Interactive knowledge graph visualizing domains, topics, facts and policies
/// as a navigable node canvas.
///
/// ## How it reads
///
/// The graph is drawn as one CLUSTER per domain — a hull enclosing that
/// domain's card, its policies and a grid of topic columns — rather than as
/// rows of nodes joined by hierarchy edges. Two decisions follow from that, and
/// both are deliberate:
///
/// * **Containment replaces the hierarchy edges.** A domain with 27 topics drew
///   27 near-horizontal curves through one corridor; the hull says "these
///   belong to this domain" with no ink crossing anything. What is still drawn
///   is the edges that carry information you cannot get from position: a
///   topic to the facts stacked under it, and a policy to the facts it was
///   derived from.
/// * **Facts are collapsed by default.** The graph opens on the domain/topic
///   overview and a topic reveals its facts on demand, which is what keeps the
///   first screen at a readable size instead of rendering every card in the
///   workspace at once.
///
/// [KnowledgeGraphLayout] owns the geometry; this widget owns the rendering and
/// the interaction.
///
/// Pan and zoom are handled by an [InteractiveViewer] (a single GPU-composited
/// transform — no per-frame widget rebuilds), individual nodes are dragged via
/// per-node [ValueNotifier]s so only the moved node rebuilds and all edges and
/// hulls are drawn by one [CustomPaint] that repaints when any node moves.
///
/// The navigation vocabulary matches the app's other node canvases: drag or
/// wheel to move the view, ⌘/Ctrl + wheel or a trackpad pinch to zoom, and the
/// bottom-right controls for zoom in / out / fit.
class KnowledgeGraph extends ConsumerStatefulWidget {
  /// Creates a [KnowledgeGraph] for the given [workspaceId].
  const KnowledgeGraph({super.key, required this.workspaceId});

  /// The workspace identifier whose memory entities to display.
  final String workspaceId;

  @override
  ConsumerState<KnowledgeGraph> createState() => _KnowledgeGraphState();
}

class _KnowledgeGraphState extends ConsumerState<KnowledgeGraph> {
  final _transform = TransformationController();

  /// Makes a plain mouse wheel PAN this canvas instead of zooming it, the same
  /// way it pans the plan DAG and the org chart. `InteractiveViewer` hardwires
  /// a wheel to zoom at `exp(-dy/200)`, so one flick of a wheel collapsed the
  /// whole graph to the scale floor around the cursor — which looks exactly
  /// like the content being flung away, and left no wheel gesture for scrolling
  /// around. ⌘/Ctrl + wheel, a trackpad pinch and the zoom buttons still zoom.
  late final CanvasWheelPan _wheelPan = CanvasWheelPan(_transform);

  /// Node payloads keyed by stable graph key (e.g. `fact:<id>`).
  final _nodeData = <String, NodeData>{};

  /// Live top-left position of each node, keyed by graph key. Dragging a node
  /// mutates only its notifier, so only that node and the edge layer react.
  final _positions = <String, ValueNotifier<Offset>>{};

  /// Keys the operator has moved by hand.
  ///
  /// The data behind this graph is a live server subscription, so any agent
  /// writing a memory fact re-emits the whole list and re-flows the layout.
  /// Re-flowing a card somebody deliberately placed elsewhere threw their
  /// arrangement away: every moved node snapped back into its layout row
  /// mid-session, for no reason the operator could see. A pinned node keeps
  /// where it was put; everything else still re-flows.
  final _pinned = <String>{};

  /// Edges to draw between nodes, rebuilt whenever the data changes.
  ///
  /// Replaced rather than mutated in place, so `shouldRepaint`'s identity check
  /// is a truthful answer to "is there anything new to draw".
  var _edges = <_GraphEdge>[];

  /// One entry per domain, in packed order.
  final _clusters = <GraphCluster>[];

  /// The live bounding boxes the painter draws behind each cluster. Rebuilt
  /// with the position store, and read from the notifiers at paint time so a
  /// dragged card takes its hull with it.
  var _hulls = <_ClusterHull>[];

  /// Topic keys whose facts are currently shown.
  ///
  /// Empty by default. A workspace with 27 topics has 27 fact cards, and
  /// rendering them all is what turned this tab into a wall: the overview is
  /// domains and topics, and facts are a topic you asked about.
  final _expandedTopics = <String>{};

  /// Size of the scrollable content area inside the viewer.
  Size _canvasSize = Size.zero;

  /// Most recent viewport size, captured from the canvas [LayoutBuilder]. Used
  /// to center content on first layout and from the "Fit to view" button.
  Size _viewport = Size.zero;

  List<MemoryFact>? _lastFacts;
  List<MemoryPolicy>? _lastPolicies;
  List<MemoryDomain>? _lastDomains;
  bool _hasCentered = false;

  void _retry() {
    ref.invalidate(memoryFactsProvider(widget.workspaceId));
    ref.invalidate(memoryPoliciesProvider(widget.workspaceId));
    ref.invalidate(memoryDomainsProvider(widget.workspaceId));
  }

  /// Bring the graph into view: scale to fit the content and center it.
  void _fitToView() => _centerContent();

  @override
  void dispose() {
    _transform.dispose();
    for (final notifier in _positions.values) {
      notifier.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final factsAsync = ref.watch(memoryFactsProvider(widget.workspaceId));
    final policiesAsync = ref.watch(memoryPoliciesProvider(widget.workspaceId));
    final domainsAsync = ref.watch(memoryDomainsProvider(widget.workspaceId));

    return factsAsync.when(
      data: (facts) => policiesAsync.when(
        data: (policies) => domainsAsync.when(
          data: (domains) {
            if (!identical(_lastFacts, facts) ||
                !identical(_lastPolicies, policies) ||
                !identical(_lastDomains, domains)) {
              _lastFacts = facts;
              _lastPolicies = policies;
              _lastDomains = domains;
              _rebuildGraph(facts, policies, domains);
            }
            return _buildGraphCanvas(context);
          },
          loading: () => const Center(child: CcSpinner()),
          error: (e, _) => MemoryErrorView(error: e, onRetry: _retry),
        ),
        loading: () => const Center(child: CcSpinner()),
        error: (e, _) => MemoryErrorView(error: e, onRetry: _retry),
      ),
      loading: () => const Center(child: CcSpinner()),
      error: (e, _) => MemoryErrorView(error: e, onRetry: _retry),
    );
  }

  /// `supersededBy` → the facts it superseded, built ONCE per rebuild.
  ///
  /// This index used to be rebuilt over the entire fact list inside
  /// [_resolveSupersededChain], which is called for every non-superseded
  /// fact: 500 facts meant 500 map constructions and 250k iterations per
  /// rebuild, and 3,000 facts visibly froze the tab.
  static Map<String, List<MemoryFact>> _indexBySuperseder(
    List<MemoryFact> allFacts,
  ) {
    final bySuperseder = <String, List<MemoryFact>>{};
    for (final f in allFacts) {
      final supersededBy = f.supersededBy;
      if (supersededBy != null) {
        bySuperseder.putIfAbsent(supersededBy, () => []).add(f);
      }
    }
    return bySuperseder;
  }

  List<MemoryFact> _resolveSupersededChain(
    MemoryFact current,
    Map<String, List<MemoryFact>> bySuperseder,
  ) {
    final chain = <MemoryFact>[];
    void walk(String factId) {
      final predecessors = bySuperseder[factId];
      if (predecessors == null) {
        return;
      }
      for (final p in predecessors) {
        chain.add(p);
        walk(p.id);
      }
    }

    walk(current.id);
    return chain;
  }

  /// Topic keys are scoped by DOMAIN.
  ///
  /// Two domains can legitimately name a topic the same thing, and keying on
  /// the bare name merged them into one node belonging to whichever domain
  /// happened to hold the first fact — an edge crossing between two clusters,
  /// which is exactly what clustering exists to prevent.
  static String _topicKey(String domain, String topic) =>
      'topic:$domain/$topic';

  void _rebuildGraph(
    List<MemoryFact> facts,
    List<MemoryPolicy> policies,
    List<MemoryDomain> domains,
  ) {
    _nodeData.clear();
    _clusters.clear();

    final domainLabels = {for (final d in domains) d.name: d.label};

    // Single-pass group-bys, replacing a `facts.where(...)` scan per domain and
    // another per topic — each of which walked the whole list.
    //
    // Superseded facts are excluded here rather than at render time: they get
    // no node, so a topic that counted them advertised facts expanding it would
    // never show.
    final factsByTopic = <String, List<MemoryFact>>{};
    final topicNames = <String, String>{};
    final topicsByDomain = <String, List<String>>{};
    for (final fact in facts) {
      if (fact.isSuperseded) {
        continue;
      }
      final topicKey = _topicKey(fact.domain, fact.topic);
      factsByTopic
          .putIfAbsent(topicKey, () {
            topicNames[topicKey] = fact.topic;
            (topicsByDomain[fact.domain] ??= []).add(topicKey);
            return [];
          })
          .add(fact);
    }
    final policiesByDomain = <String, List<MemoryPolicy>>{};
    for (final policy in policies) {
      (policiesByDomain[policy.domain] ??= []).add(policy);
    }
    final bySuperseder = _indexBySuperseder(facts);

    // Every domain with something to show, in a STABLE order. Packing is
    // positional and the domain set used to be iterated in insertion order, so
    // a fact arriving in a new domain could reshuffle the whole canvas.
    final domainSlugs =
        <String>{
            for (final d in domains) d.name,
            for (final f in facts)
              if (!f.isSuperseded) f.domain,
            for (final p in policies) p.domain,
          }.where((slug) {
            final hasTopics = topicsByDomain[slug]?.isNotEmpty ?? false;
            final hasPolicies = policiesByDomain[slug]?.isNotEmpty ?? false;
            return hasTopics || hasPolicies;
          }).toList()
          ..sort((a, b) {
            final left = (domainLabels[a] ?? a).toLowerCase();
            final right = (domainLabels[b] ?? b).toLowerCase();
            final byLabel = left.compareTo(right);
            return byLabel != 0 ? byLabel : a.compareTo(b);
          });

    for (final slug in domainSlugs) {
      final domainKey = 'domain:$slug';
      final topicKeys = topicsByDomain[slug] ?? const <String>[];
      final domainPolicies = policiesByDomain[slug] ?? const <MemoryPolicy>[];

      var factTotal = 0;
      for (final topicKey in topicKeys) {
        factTotal += factsByTopic[topicKey]!.length;
      }
      _nodeData[domainKey] = NodeData(
        type: NodeType.domain,
        domainSlug: slug,
        domainLabel: domainLabels[slug] ?? slug,
        factCount: factTotal,
        policyCount: domainPolicies.length,
      );

      final strips = <GraphStrip>[];
      for (final topicKey in topicKeys) {
        final topicFacts = factsByTopic[topicKey]!;
        _nodeData[topicKey] = NodeData(
          type: NodeType.topic,
          topic: topicNames[topicKey],
          factCount: topicFacts.length,
        );

        final factKeys = <String>[];
        if (_expandedTopics.contains(topicKey)) {
          for (final fact in topicFacts) {
            final factKey = 'fact:${fact.id}';
            _nodeData[factKey] = NodeData(
              type: NodeType.fact,
              fact: fact,
              supersededFacts: _resolveSupersededChain(fact, bySuperseder),
            );
            factKeys.add(factKey);
          }
        }
        strips.add(GraphStrip(topicKey: topicKey, factKeys: factKeys));
      }

      final policyKeys = <String>[];
      for (final policy in domainPolicies) {
        final policyKey = 'policy:${policy.id}';
        _nodeData[policyKey] = NodeData(type: NodeType.policy, policy: policy);
        policyKeys.add(policyKey);
      }

      _clusters.add(
        GraphCluster(
          domainKey: domainKey,
          strips: strips,
          policyKeys: policyKeys,
        ),
      );
    }

    final positions = KnowledgeGraphLayout.compute(
      clusters: _clusters,
      sizes: {
        for (final entry in _nodeData.entries)
          entry.key: _sizeForNodeType(entry.value.type),
      },
    );

    // Every node in [_nodeData] must have a position — a node the layout did
    // not place falls back to the origin rather than being dropped, keeping the
    // render loop's lookups total.
    final fullPositions = <String, Offset>{
      for (final key in _nodeData.keys) key: positions[key] ?? Offset.zero,
    };

    _syncPositions(fullPositions);
    _canvasSize = _computeCanvasSize(fullPositions);
    _buildHulls();
    _buildEdges(policies);
  }

  /// Toggles one topic's facts. A local action, so it re-flows without touching
  /// the view: the operator asked about this topic, not for the camera to move.
  void _toggleTopic(String topicKey) {
    setState(() {
      if (!_expandedTopics.remove(topicKey)) {
        _expandedTopics.add(topicKey);
      }
      _reflow();
    });
  }

  /// Expands or collapses every topic at once, then re-fits. Unlike the
  /// per-topic toggle this changes the size of the whole graph, so leaving the
  /// camera where it was would strand the content off screen.
  void _toggleAllTopics() {
    setState(() {
      if (_allTopicsExpanded) {
        _expandedTopics.clear();
      } else {
        for (final cluster in _clusters) {
          for (final strip in cluster.strips) {
            _expandedTopics.add(strip.topicKey);
          }
        }
      }
      _reflow();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _centerContent();
      }
    });
  }

  /// Whether no topic is left to expand (vacuously true when there are none).
  bool get _allTopicsExpanded {
    for (final cluster in _clusters) {
      for (final strip in cluster.strips) {
        if (!_expandedTopics.contains(strip.topicKey)) {
          return false;
        }
      }
    }
    return true;
  }

  /// Re-runs the layout against the data already on screen.
  void _reflow() {
    final facts = _lastFacts;
    final policies = _lastPolicies;
    final domains = _lastDomains;
    if (facts == null || policies == null || domains == null) {
      return;
    }
    _rebuildGraph(facts, policies, domains);
  }

  /// Rebuilds the hulls drawn behind each cluster. They hold their members'
  /// position NOTIFIERS rather than offsets, so a hull follows a card the
  /// operator drags instead of going stale behind it.
  void _buildHulls() {
    final hulls = <_ClusterHull>[];
    for (final cluster in _clusters) {
      final members = <_HullMember>[];
      for (final key in cluster.memberKeys) {
        final position = _positions[key];
        final data = _nodeData[key];
        if (position == null || data == null) {
          continue;
        }
        members.add(_HullMember(position, _sizeForNodeType(data.type)));
      }
      if (members.isNotEmpty) {
        hulls.add(_ClusterHull(members));
      }
    }
    _hulls = hulls;
  }

  /// Reconcile the [ValueNotifier] position store with the freshly computed
  /// [positions]: reuse notifiers for surviving keys (updating their value),
  /// create notifiers for new keys and dispose notifiers for removed keys.
  ///
  /// Removed notifiers are disposed in a post-frame callback so we never
  /// dispose one while a [ValueListenableBuilder] still listens to it during
  /// this frame's rebuild.
  void _syncPositions(Map<String, Offset> positions) {
    final removed = _positions.keys
        .where((key) => !positions.containsKey(key))
        .toList();
    final orphaned = <ValueNotifier<Offset>>[];
    for (final key in removed) {
      orphaned.add(_positions.remove(key)!);
      _pinned.remove(key);
    }

    for (final entry in positions.entries) {
      final existing = _positions[entry.key];
      if (existing != null) {
        // A node the operator moved keeps its place across data refreshes.
        if (!_pinned.contains(entry.key)) {
          existing.value = entry.value;
        }
      } else {
        _positions[entry.key] = ValueNotifier<Offset>(entry.value);
      }
    }

    if (orphaned.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        for (final notifier in orphaned) {
          notifier.dispose();
        }
      });
    }
  }

  Size _computeCanvasSize(Map<String, Offset> positions) {
    var maxRight = 0.0;
    var maxBottom = 0.0;
    for (final entry in positions.entries) {
      final size = _sizeForNodeType(_nodeData[entry.key]!.type);
      maxRight = max(maxRight, entry.value.dx + size.width);
      maxBottom = max(maxBottom, entry.value.dy + size.height);
    }
    return Size(maxRight + _canvasMargin, maxBottom + _canvasMargin);
  }

  /// Collects the edges worth drawing.
  ///
  /// Deliberately NOT every relationship in the model. Domain to topic and
  /// domain to policy are carried by the cluster hull — drawing them put every
  /// topic on a curve back to one point, which is the starburst that made this
  /// canvas unreadable at 27 topics. What survives is the two relationships
  /// containment cannot express: a topic to the facts stacked under it (short,
  /// vertical, inside one strip) and a policy to the facts it was derived from,
  /// which is the only edge here that crosses the cluster and the only one that
  /// tells a reader something position does not.
  void _buildEdges(List<MemoryPolicy> policies) {
    final edges = <_GraphEdge>[];
    void add(String srcKey, String destKey, _EdgeRole role) {
      final src = _positions[srcKey];
      final dest = _positions[destKey];
      final srcType = _nodeData[srcKey]?.type;
      final destType = _nodeData[destKey]?.type;
      if (src == null || dest == null || srcType == null || destType == null) {
        return;
      }
      edges.add(
        _GraphEdge(
          src: src,
          srcSize: _sizeForNodeType(srcType),
          dest: dest,
          destSize: _sizeForNodeType(destType),
          role: role,
        ),
      );
    }

    for (final cluster in _clusters) {
      for (final strip in cluster.strips) {
        for (final factKey in strip.factKeys) {
          add(strip.topicKey, factKey, _EdgeRole.topicFact);
        }
      }
    }
    // A collapsed topic has no fact nodes, so `add` drops the reference and the
    // policy simply shows no derivation until its facts are on screen.
    for (final policy in policies) {
      final policyKey = 'policy:${policy.id}';
      if (!_nodeData.containsKey(policyKey)) {
        continue;
      }
      for (final factId in policy.sourceFactIds) {
        add(policyKey, 'fact:$factId', _EdgeRole.policyFact);
      }
    }
    _edges = edges;
  }

  Size _sizeForNodeType(NodeType type) {
    switch (type) {
      case NodeType.domain:
        return _domainNodeSize;
      case NodeType.topic:
        return _topicNodeSize;
      case NodeType.fact:
        return _factNodeSize;
      case NodeType.policy:
        return _policyNodeSize;
    }
  }

  /// Bounding box of all node rectangles in canvas coordinates.
  Rect? _contentBounds() {
    if (_positions.isEmpty) {
      return null;
    }
    var minX = double.infinity;
    var minY = double.infinity;
    var maxX = -double.infinity;
    var maxY = -double.infinity;
    for (final entry in _positions.entries) {
      final pos = entry.value.value;
      final size = _sizeForNodeType(_nodeData[entry.key]!.type);
      minX = min(minX, pos.dx);
      minY = min(minY, pos.dy);
      maxX = max(maxX, pos.dx + size.width);
      maxY = max(maxY, pos.dy + size.height);
    }
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  /// Center the content in the viewport, scaling down to fit when needed (but
  /// never zooming past 100%).
  void _centerContent() {
    if (_viewport.isEmpty) {
      return;
    }
    final bounds = _contentBounds();
    if (bounds == null || bounds.isEmpty) {
      return;
    }

    const pad = 48.0;
    final contentWidth = bounds.width + pad * 2;
    final contentHeight = bounds.height + pad * 2;
    final fitScale = min(
      _viewport.width / contentWidth,
      _viewport.height / contentHeight,
    ).clamp(_minScale, 1.0);

    final center = bounds.center;
    // Affine transform mapping content → viewport: scale about origin then
    // translate so the content center lands on the viewport center.
    final tx = _viewport.width / 2 - fitScale * center.dx;
    final ty = _viewport.height / 2 - fitScale * center.dy;
    // Scale all THREE axes, and this is not cosmetic. Everything that reads
    // the current zoom back — the zoom controls, the wheel pan, the dot grid
    // and `InteractiveViewer` itself — asks `Matrix4.getMaxScaleOnAxis`, which
    // is the LARGEST column norm. A matrix that scaled x and y to 0.25 and
    // left z at 1 therefore reported a zoom of 1.0 while the graph was drawn
    // at a quarter size, so the first press of "+" computed `1.0 * 1.25` and
    // jumped the canvas five times bigger in a single step (and the dot grid
    // tiled at the wrong spacing until the first gesture corrected it).
    _transform.value = Matrix4.identity()
      ..translateByDouble(tx, ty, 0, 1)
      ..scaleByDouble(fitScale, fitScale, fitScale, 1);
  }

  Widget _buildGraphCanvas(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (_nodeData.isEmpty) {
      return EmptyState(
        icon: AppIcons.workflow,
        message: l10n.noMemoryData,
        description: l10n.memoryDataHint,
      );
    }

    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final edgeColor = tokens.borderSecondary;
    final factEdgeColor = tokens.textTertiary.withValues(alpha: 0.3);
    // The hull carries the hierarchy, so it has to read as a REGION rather
    // than as another card: a hairline and a wash barely above the canvas.
    final hullBorderColor = tokens.borderSecondary.withValues(alpha: 0.7);
    final hullFillColor = tokens.textPrimary.withValues(alpha: 0.025);

    // Repaints the edge layer whenever any node moves.
    final positionsListenable = Listenable.merge(_positions.values.toList());

    return Stack(
      children: [
        // Dot-grid backdrop that pans and zooms with the graph. It reads the
        // viewer's transform (translation + scale) so the grid stays locked to
        // the nodes.
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
        Positioned.fill(
          child: LayoutBuilder(
            builder: (context, constraints) {
              _viewport = constraints.biggest;
              // Center the graph on its content the first time it has any, so
              // the operator doesn't open onto an off-screen cluster.
              if (!_hasCentered &&
                  _positions.isNotEmpty &&
                  _viewport.isFinite &&
                  !_viewport.isEmpty) {
                _hasCentered = true;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    _centerContent();
                  }
                });
              }
              return Listener(
                onPointerSignal: (event) => _wheelPan.onPointerSignal(
                  event,
                  viewport: constraints.biggest,
                  canvas: _canvasSize,
                  boundaryMargin: _boundaryMargin,
                ),
                child: InteractiveViewer(
                  transformationController: _transform,
                  constrained: false,
                  minScale: _minScale,
                  maxScale: _maxScale,
                  boundaryMargin: const EdgeInsets.all(_boundaryMargin),
                  // Snapshots the transform before the viewer changes it — the
                  // wheel rewrite needs the pre-zoom matrix.
                  onInteractionStart: (_) => _wheelPan.beginInteraction(),
                  child: SizedBox(
                    width: _canvasSize.width,
                    height: _canvasSize.height,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned.fill(
                          child: IgnorePointer(
                            child: RepaintBoundary(
                              child: CustomPaint(
                                painter: _EdgePainter(
                                  edges: _edges,
                                  hulls: _hulls,
                                  repaint: positionsListenable,
                                  edgeColor: edgeColor,
                                  factEdgeColor: factEdgeColor,
                                  hullBorderColor: hullBorderColor,
                                  hullFillColor: hullFillColor,
                                ),
                              ),
                            ),
                          ),
                        ),
                        for (final entry in _nodeData.entries)
                          _GraphNode(
                            key: ValueKey(entry.key),
                            position: _positions[entry.key]!,
                            size: _sizeForNodeType(entry.value.type),
                            onMoved: () => _pinned.add(entry.key),
                            child: _buildNodeVisual(
                              context,
                              entry.key,
                              entry.value,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Positioned(
          top: AppSpacing.md,
          right: AppSpacing.md,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildExpandControl(context),
              const SizedBox(height: AppSpacing.sm),
              _buildLegend(context),
            ],
          ),
        ),
        // Fit joins zoom in the shared bottom-right stack: the three are one
        // question ("show me more / less / all of it") and were answered from
        // two different corners, one of them by gesture only.
        Positioned(
          right: kCanvasControlInset,
          bottom: kCanvasControlInset,
          child: CanvasZoomControls(
            controller: _transform,
            viewport: () => _viewport,
            minScale: _minScale,
            maxScale: _maxScale,
            onReset: _fitToView,
          ),
        ),
      ],
    );
  }

  Widget _buildNodeVisual(BuildContext context, String key, NodeData data) {
    switch (data.type) {
      case NodeType.domain:
        return _DomainNode(
          domainLabel: data.domainLabel ?? data.domainSlug ?? '',
          factCount: data.factCount,
          policyCount: data.policyCount,
          onTap: () => _showNodeSheet(context, key),
        );
      case NodeType.topic:
        return _TopicNode(
          topic: data.topic!,
          factCount: data.factCount,
          expanded: _expandedTopics.contains(key),
          onToggle: () => _toggleTopic(key),
          onTap: () => _showNodeSheet(context, key),
        );
      case NodeType.fact:
        return _FactNode(
          fact: data.fact!,
          supersededCount: data.supersededFacts.length,
          onTap: () => _showNodeSheet(context, key),
        );
      case NodeType.policy:
        return _PolicyNode(
          policy: data.policy!,
          onTap: () => _showNodeSheet(context, key),
        );
    }
  }

  void _showNodeSheet(BuildContext context, String key) {
    final data = _nodeData[key];
    if (data == null) {
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => KnowledgeGraphNodeSheet(
        nodeData: data,
        workspaceId: widget.workspaceId,
        onEditFact: data.type == NodeType.fact
            ? () => _editFact(context, data.fact!)
            : null,
        onDeleteFact: data.type == NodeType.fact
            ? () => _deleteFact(context, data.fact!)
            : null,
        onEditPolicy: data.type == NodeType.policy
            ? () => _editPolicy(context, data.policy!)
            : null,
        onDeletePolicy: data.type == NodeType.policy
            ? () => _deletePolicy(context, data.policy!)
            : null,
        onTogglePolicy: data.type == NodeType.policy
            ? () => _togglePolicy(data.policy!)
            : null,
      ),
    );
  }

  Future<void> _editFact(BuildContext context, MemoryFact fact) async {
    final edited = await showDialog<MemoryFact>(
      context: context,
      builder: (_) => FactEditDialog(fact: fact),
    );
    if (edited == null) {
      return;
    }
    final repo = ref.read(memoryFactRepositoryProvider);
    await repo.upsert(edited);
  }

  Future<void> _deleteFact(BuildContext context, MemoryFact fact) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showCcDialog<bool>(
      context: context,
      builder: (dialogContext) => CcDialog(
        title: l10n.deleteFact,
        content: Text(l10n.deleteTopicConfirm(fact.topic)),
        actions: [
          CcButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            variant: CcButtonVariant.secondary,
            child: Text(l10n.cancel),
          ),
          CcButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            variant: CcButtonVariant.destructive,
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    final repo = ref.read(memoryFactRepositoryProvider);
    await repo.delete(fact.workspaceId, fact.id);
  }

  Future<void> _editPolicy(BuildContext context, MemoryPolicy policy) async {
    final edited = await showDialog<MemoryPolicy>(
      context: context,
      builder: (_) => PolicyEditDialog(policy: policy),
    );
    if (edited == null) {
      return;
    }
    final repo = ref.read(memoryPolicyRepositoryProvider);
    await repo.upsert(edited);
  }

  Future<void> _deletePolicy(BuildContext context, MemoryPolicy policy) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showCcDialog<bool>(
      context: context,
      builder: (dialogContext) => CcDialog(
        title: l10n.deletePolicy,
        content: Text(l10n.deletePolicyConfirm),
        actions: [
          CcButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            variant: CcButtonVariant.secondary,
            child: Text(l10n.cancel),
          ),
          CcButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            variant: CcButtonVariant.destructive,
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    final repo = ref.read(memoryPolicyRepositoryProvider);
    await repo.delete(policy.workspaceId, policy.id);
  }

  Future<void> _togglePolicy(MemoryPolicy policy) async {
    final repo = ref.read(memoryPolicyRepositoryProvider);
    await repo.upsert(policy.copyWith(active: !policy.active));
  }

  /// The one control that acts on every topic at once. The per-topic chevron
  /// is the precise instrument; this is the "show me everything" / "give me
  /// the overview back" pair, and it sits beside the legend because both
  /// answer "what am I looking at".
  Widget _buildExpandControl(BuildContext context) {
    var topics = 0;
    for (final cluster in _clusters) {
      topics += cluster.strips.length;
    }
    if (topics == 0) {
      return const SizedBox.shrink();
    }

    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final expanded = _allTopicsExpanded;
    final label = expanded
        ? l10n.memoryGraphCollapseAll
        : l10n.memoryGraphExpandAll;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.bgPrimary,
        borderRadius: AppRadii.brMd,
        border: Border.all(color: tokens.borderSecondary),
      ),
      child: CcIconButton(
        icon: expanded ? AppIcons.chevronsDownUp : AppIcons.chevronsUpDown,
        tooltip: label,
        semanticLabel: label,
        onPressed: _toggleAllTopics,
      ),
    );
  }

  Widget _buildLegend(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: tokens.bgPrimary,
        borderRadius: AppRadii.brMd,
        border: Border.all(color: tokens.borderSecondary),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.legendLabel.toUpperCase(),
            style: CcTypography.caption.copyWith(
              color: tokens.textTertiary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          // Glyphs mirror the node glyphs so the legend reads against the graph.
          _LegendItem(
            icon: AppIcons.tag,
            color: tokens.fgBrandPrimary,
            label: l10n.domain,
          ),
          _LegendItem(
            icon: AppIcons.hash,
            color: tokens.fgQuaternary,
            label: l10n.topic,
          ),
          _LegendItem(
            icon: AppIcons.lightbulb,
            color: tokens.fgQuaternary,
            label: l10n.fact,
          ),
          _LegendItem(
            icon: AppIcons.scale,
            color: tokens.fgQuaternary,
            label: l10n.policy,
          ),
        ],
      ),
    );
  }
}

/// A single node placed on the canvas. Backed by a [ValueNotifier<Offset>] so
/// dragging it rebuilds only this widget (and repaints the edge layer) rather
/// than the whole graph.
class _GraphNode extends StatelessWidget {
  const _GraphNode({
    required this.position,
    required this.size,
    required this.onMoved,
    required this.child,
    super.key,
  });

  final ValueNotifier<Offset> position;
  final Size size;

  /// Called on every drag update so the host can stop re-flowing this node.
  final VoidCallback onMoved;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Offset>(
      valueListenable: position,
      builder: (context, pos, child) {
        return Positioned(
          left: pos.dx,
          top: pos.dy,
          width: size.width,
          height: size.height,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            // A trackpad two-finger scroll is a request to move the VIEW, not
            // this card. A pan recogniser accepts pan-zoom events as readily as
            // pointer drags and, being the inner one, wins the arena — so a
            // scroll that happened to start over a node dragged the node
            // instead of panning, amplified by 1/scale (four screen pixels per
            // finger pixel at the zoom floor). Excluding the trackpad kind
            // leaves the gesture to the viewer; a click-drag on a laptop
            // trackpad arrives as a mouse pointer, so dragging still works.
            supportedDevices: const {
              PointerDeviceKind.mouse,
              PointerDeviceKind.touch,
              PointerDeviceKind.stylus,
              PointerDeviceKind.invertedStylus,
              PointerDeviceKind.unknown,
            },
            // `delta` arrives in this widget's local (content) coordinates,
            // already corrected for the viewer's zoom, so it applies directly.
            onPanUpdate: (details) {
              position.value += details.delta;
              onMoved();
            },
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

/// The visual role of an edge, which determines its color, thickness and the
/// node anchors it connects.
enum _EdgeRole {
  /// A topic down to one of the facts stacked under it.
  topicFact,

  /// A policy back to a fact it was derived from.
  policyFact,
}

/// One node inside a cluster hull, held by its live position notifier.
class _HullMember {
  const _HullMember(this.position, this.size);

  final ValueNotifier<Offset> position;
  final Size size;
}

/// The live bounding box of one domain's cards.
class _ClusterHull {
  const _ClusterHull(this.members);

  final List<_HullMember> members;

  /// The box enclosing every member at its CURRENT position, so dragging a
  /// card carries its hull along instead of leaving it behind.
  Rect bounds() {
    var left = double.infinity;
    var top = double.infinity;
    var right = -double.infinity;
    var bottom = -double.infinity;
    for (final member in members) {
      final at = member.position.value;
      left = min(left, at.dx);
      top = min(top, at.dy);
      right = max(right, at.dx + member.size.width);
      bottom = max(bottom, at.dy + member.size.height);
    }
    return Rect.fromLTRB(left, top, right, bottom).inflate(_hullPadding);
  }
}

/// An edge between two nodes. Holds references to the endpoints' live position
/// notifiers so the painter always reads their current positions.
class _GraphEdge {
  const _GraphEdge({
    required this.src,
    required this.srcSize,
    required this.dest,
    required this.destSize,
    required this.role,
  });

  final ValueNotifier<Offset> src;
  final Size srcSize;
  final ValueNotifier<Offset> dest;
  final Size destSize;
  final _EdgeRole role;
}

/// Paints each cluster's hull and then every edge as a smooth curve between
/// node anchors. Repaints whenever any node position notifier fires (passed as
/// `repaint`), which is what keeps both live under a drag.
class _EdgePainter extends CustomPainter {
  _EdgePainter({
    required this.edges,
    required this.hulls,
    required Listenable repaint,
    required this.edgeColor,
    required this.factEdgeColor,
    required this.hullBorderColor,
    required this.hullFillColor,
  }) : super(repaint: repaint);

  final List<_GraphEdge> edges;
  final List<_ClusterHull> hulls;
  final Color edgeColor;
  final Color factEdgeColor;
  final Color hullBorderColor;
  final Color hullFillColor;

  @override
  void paint(Canvas canvas, Size size) {
    final hullFill = Paint()..color = hullFillColor;
    final hullStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = hullBorderColor
      ..isAntiAlias = true;
    for (final hull in hulls) {
      final bounds = hull.bounds();
      if (bounds.isEmpty) {
        continue;
      }
      canvas.drawRect(bounds, hullFill);
      canvas.drawRect(bounds, hullStroke);
    }

    for (final edge in edges) {
      final style = _styleFor(edge.role);
      final srcPos = edge.src.value;
      final destPos = edge.dest.value;

      final from = Offset(
        srcPos.dx + edge.srcSize.width * ((style.start.x + 1) / 2),
        srcPos.dy + edge.srcSize.height * ((style.start.y + 1) / 2),
      );
      final to = Offset(
        destPos.dx + edge.destSize.width * ((style.end.x + 1) / 2),
        destPos.dy + edge.destSize.height * ((style.end.y + 1) / 2),
      );

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = style.thickness
        ..color = style.color
        ..isAntiAlias = true;

      canvas.drawPath(_curvePath(from, to, style.start, style.end), paint);
    }
  }

  ({Color color, double thickness, Alignment start, Alignment end}) _styleFor(
    _EdgeRole role,
  ) {
    switch (role) {
      case _EdgeRole.topicFact:
        return (
          color: edgeColor,
          thickness: 1.2,
          start: Alignment.bottomCenter,
          end: Alignment.topCenter,
        );
      case _EdgeRole.policyFact:
        return (
          color: factEdgeColor,
          thickness: 1.2,
          start: Alignment.bottomCenter,
          end: Alignment.topCenter,
        );
    }
  }

  /// Smooth curve between [from] and [to], easing out along the anchor
  /// directions. Mirrors the curve geometry of the previous flow-chart edges.
  Path _curvePath(Offset from, Offset to, Alignment start, Alignment end) {
    final distance = (to - from).distance / 3;

    var dx = 0.0;
    var dy = 0.0;
    if (start.x > 0) {
      dx = distance;
    } else if (start.x < 0) {
      dx = -distance;
    }
    if (start.y > 0) {
      dy = distance;
    } else if (start.y < 0) {
      dy = -distance;
    }
    final p1 = Offset(from.dx + dx, from.dy + dy);

    dx = 0;
    dy = 0;
    if (end.x > 0) {
      dx = distance;
    } else if (end.x < 0) {
      dx = -distance;
    }
    if (end.y > 0) {
      dy = distance;
    } else if (end.y < 0) {
      dy = -distance;
    }
    final p3 = end == Alignment.center ? to : Offset(to.dx + dx, to.dy + dy);
    final p2 = Offset(p1.dx + (p3.dx - p1.dx) / 2, p1.dy + (p3.dy - p1.dy) / 2);

    return Path()
      ..moveTo(from.dx, from.dy)
      ..conicTo(p1.dx, p1.dy, p2.dx, p2.dy, 1)
      ..conicTo(p3.dx, p3.dy, to.dx, to.dy, 1);
  }

  @override
  bool shouldRepaint(_EdgePainter old) =>
      !identical(old.edges, edges) ||
      !identical(old.hulls, hulls) ||
      old.edgeColor != edgeColor ||
      old.factEdgeColor != factEdgeColor ||
      old.hullBorderColor != hullBorderColor ||
      old.hullFillColor != hullFillColor;
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.icon,
    required this.color,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: AppSpacing.sm),
          Text(
            label,
            style: CcTypography.caption.copyWith(color: tokens.textSecondary),
          ),
        ],
      ),
    );
  }
}

/// The type of a node in the knowledge graph.
enum NodeType {
  /// A memory domain grouping related topics.
  domain,

  /// A topic or category within a domain.
  topic,

  /// A fact assertion stored in the knowledge base.
  fact,

  /// A policy rule governing memory access or behavior.
  policy,
}

/// Data payload carried by each node in the knowledge graph.
class NodeData {
  /// Creates a [NodeData] with the required [type].
  const NodeData({
    required this.type,
    this.domainSlug,
    this.domainLabel,
    this.topic,
    this.fact,
    this.policy,
    this.factCount = 0,
    this.policyCount = 0,
    this.supersededFacts = const [],
  });

  /// The kind of knowledge graph node.
  final NodeType type;

  /// The machine-readable domain identifier.
  final String? domainSlug;

  /// The human-readable domain label.
  final String? domainLabel;

  /// The topic name.
  final String? topic;

  /// The fact associated with this node, when [type] is [NodeType.fact].
  final MemoryFact? fact;

  /// The policy associated with this node, when [type] is [NodeType.policy].
  final MemoryPolicy? policy;

  /// Number of facts grouped under this node.
  final int factCount;

  /// Number of policies grouped under this node.
  final int policyCount;

  /// Facts that were superseded by the current fact.
  final List<MemoryFact> supersededFacts;
}

/// Domain node — the brand-accented anchor of each cluster. Brand is the only
/// color here; topics, facts and policies stay neutral so blue keeps meaning.
class _DomainNode extends StatelessWidget {
  const _DomainNode({
    required this.domainLabel,
    required this.factCount,
    required this.policyCount,
    required this.onTap,
  });

  final String domainLabel;
  final int factCount;
  final int policyCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: tokens.bgBrandPrimary,
          borderRadius: AppRadii.brLg,
          border: Border.all(color: tokens.borderBrand),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(AppIcons.tag, size: 14, color: tokens.fgBrandPrimary),
                const SizedBox(width: AppSpacing.xs),
                Flexible(
                  child: Text(
                    domainLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CcTypography.body.copyWith(
                      color: tokens.textBrandPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              AppLocalizations.of(
                context,
              ).factsPoliciesCount(factCount, policyCount),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: CcTypography.caption.copyWith(
                color: tokens.textBrandSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Topic node — neutral grouping under a domain, and the graph's expand
/// control: its chevron is what reveals the facts stacked beneath it.
class _TopicNode extends StatelessWidget {
  const _TopicNode({
    required this.topic,
    required this.factCount,
    required this.expanded,
    required this.onToggle,
    required this.onTap,
  });

  final String topic;
  final int factCount;

  /// Whether this topic's facts are currently on the canvas.
  final bool expanded;

  /// Shows or hides this topic's facts.
  final VoidCallback onToggle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final label = expanded
        ? l10n.memoryGraphHideFacts
        : l10n.memoryGraphShowFacts;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          // An expanded topic heads a column of its own cards, so it takes the
          // ink border that says "this one is open" — shape, not colour, since
          // the whole grid is the same neutral.
          color: tokens.bgSecondary,
          borderRadius: AppRadii.brMd,
          border: Border.all(
            color: expanded ? tokens.borderPrimary : tokens.borderSecondary,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(AppIcons.hash, size: 12, color: tokens.fgQuaternary),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    topic,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CcTypography.caption.copyWith(
                      color: tokens.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            // The count row IS the toggle, so the target is the width of the
            // card rather than a 14px glyph, and opening a topic's facts stays
            // a different press from opening its detail sheet.
            CcTooltip(
              message: label,
              child: Semantics(
                button: true,
                label: label,
                child: GestureDetector(
                  onTap: onToggle,
                  behavior: HitTestBehavior.opaque,
                  child: SizedBox(
                    height: 22,
                    child: Row(
                      children: [
                        Text(
                          factCount == 1
                              ? l10n.factCount(factCount)
                              : l10n.factCountPlural(factCount),
                          style: CcTypography.caption.copyWith(
                            color: tokens.textTertiary,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          expanded ? AppIcons.chevronUp : AppIcons.chevronDown,
                          size: 14,
                          color: tokens.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fact node — neutral card; the only color is the confidence meter.
class _FactNode extends StatelessWidget {
  const _FactNode({
    required this.fact,
    required this.supersededCount,
    required this.onTap,
  });

  final MemoryFact fact;
  final int supersededCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: fact.isSuperseded ? 0.55 : 1.0,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: tokens.bgPrimary,
            borderRadius: AppRadii.brMd,
            border: Border.all(color: tokens.borderSecondary),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: MemoryMetaChip(
                      label: fact.topic,
                      icon: AppIcons.lightbulb,
                    ),
                  ),
                  if (supersededCount > 0) ...[
                    const SizedBox(width: AppSpacing.xs),
                    MemoryMetaChip(label: 'v${supersededCount + 1}'),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                fact.content.split('\n').first,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: CcTypography.caption.copyWith(
                  color: tokens.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              ConfidenceMeter(confidence: fact.confidence, compact: true),
            ],
          ),
        ),
      ),
    );
  }
}

/// Policy node — neutral card marked by the scale glyph, not a colored border.
class _PolicyNode extends StatelessWidget {
  const _PolicyNode({required this.policy, required this.onTap});

  final MemoryPolicy policy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: policy.active ? 1.0 : 0.55,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: tokens.bgPrimary,
            borderRadius: AppRadii.brMd,
            border: Border.all(color: tokens.borderSecondary),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(AppIcons.scale, size: 12, color: tokens.fgQuaternary),
                  const SizedBox(width: AppSpacing.xs),
                  Flexible(child: MemoryMetaChip(label: policy.domain)),
                  const Spacer(),
                  if (!policy.active)
                    Icon(AppIcons.eyeOff, size: 12, color: tokens.fgQuaternary),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                policy.rule.split('\n').first,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: CcTypography.caption.copyWith(
                  color: tokens.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
