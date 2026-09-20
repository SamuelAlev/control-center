import 'dart:math' show max, min;

import 'package:cc_domain/core/domain/entities/memory_fact.dart';
import 'package:cc_domain/core/domain/entities/memory_policy.dart';
import 'package:cc_domain/features/memory/domain/entities/memory_domain.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/memory/presentation/widgets/fact_edit_dialog.dart';
import 'package:control_center/features/memory/presentation/widgets/knowledge_graph_chrome.dart';
import 'package:control_center/features/memory/presentation/widgets/knowledge_graph_data.dart';
import 'package:control_center/features/memory/presentation/widgets/knowledge_graph_layout.dart';
import 'package:control_center/features/memory/presentation/widgets/knowledge_graph_node_sheet.dart';
import 'package:control_center/features/memory/presentation/widgets/knowledge_graph_nodes.dart';
import 'package:control_center/features/memory/presentation/widgets/knowledge_graph_painter.dart';
import 'package:control_center/features/memory/presentation/widgets/knowledge_graph_policy_node.dart';
import 'package:control_center/features/memory/presentation/widgets/memory_error_view.dart';
import 'package:control_center/features/memory/presentation/widgets/policy_edit_dialog.dart';
import 'package:control_center/features/memory/providers/memory_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/canvas/canvas_wheel_pan.dart';
import 'package:control_center/shared/widgets/canvas/canvas_zoom_controls.dart';
import 'package:control_center/shared/widgets/dot_grid_background.dart';
import 'package:control_center/shared/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'knowledge_graph_actions.dart';
part 'knowledge_graph_layout_logic.dart';
part 'knowledge_graph_rendering.dart';

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
  var _edges = <GraphEdge>[];

  /// One entry per domain, in packed order.
  final _clusters = <GraphCluster>[];

  /// The live bounding boxes the painter draws behind each cluster. Rebuilt
  /// with the position store, and read from the notifiers at paint time so a
  /// dragged card takes its hull with it.
  var _hulls = <ClusterHull>[];

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

  void _toggleTopic(String topicKey) {
    setState(() {
      if (!_expandedTopics.remove(topicKey)) {
        _expandedTopics.add(topicKey);
      }
      _reflow();
    });
  }

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
}
