import 'dart:math' show max, min;

import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/domain/entities/memory_fact.dart';
import 'package:control_center/core/domain/entities/memory_policy.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/memory/domain/entities/memory_domain.dart';
import 'package:control_center/features/memory/presentation/widgets/confidence_meter.dart';
import 'package:control_center/features/memory/presentation/widgets/fact_edit_dialog.dart';
import 'package:control_center/features/memory/presentation/widgets/knowledge_graph_node_sheet.dart';
import 'package:control_center/features/memory/presentation/widgets/memory_chip.dart';
import 'package:control_center/features/memory/presentation/widgets/memory_error_view.dart';
import 'package:control_center/features/memory/presentation/widgets/policy_edit_dialog.dart';
import 'package:control_center/features/memory/providers/memory_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/dot_grid_background.dart';
import 'package:control_center/shared/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

// Layout constants. Sized so labels stay legible without zooming.
const _domainNodeSize = Size(148, 86);
const _topicNodeSize = Size(132, 60);
const _factNodeSize = Size(184, 116);
const _policyNodeSize = Size(168, 96);

const _layerDomainY = 100.0;
const _layerTopicY = 260.0;
const _layerFactY = 430.0;
const _domainGap = 100.0;
const _topicGap = 30.0;
const _factGap = 20.0;
const _policyGap = 15.0;
const _startX = 150.0;

// Interaction bounds for the canvas viewport.
const _minScale = 0.25;
const _maxScale = 4.0;
// Slack added around the content so nodes stay draggable past the edges.
const _canvasMargin = 600.0;

/// Interactive knowledge graph visualizing domains, topics, facts, and policies
/// as a navigable node canvas.
///
/// Pan and zoom are handled by an [InteractiveViewer] (a single GPU-composited
/// transform — no per-frame widget rebuilds), individual nodes are dragged via
/// per-node [ValueNotifier]s so only the moved node rebuilds, and all edges are
/// drawn by one [CustomPaint] that repaints when any node moves.
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

  /// Node payloads keyed by stable graph key (e.g. `fact:<id>`).
  final _nodeData = <String, NodeData>{};

  /// Live top-left position of each node, keyed by graph key. Dragging a node
  /// mutates only its notifier, so only that node and the edge layer react.
  final _positions = <String, ValueNotifier<Offset>>{};

  /// Edges to draw between nodes, rebuilt whenever the data changes.
  final _edges = <_GraphEdge>[];

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

  List<MemoryFact> _resolveSupersededChain(
    MemoryFact current,
    List<MemoryFact> allFacts,
  ) {
    final chain = <MemoryFact>[];
    final bySuperseder = <String, List<MemoryFact>>{};
    for (final f in allFacts) {
      if (f.supersededBy != null) {
        bySuperseder.putIfAbsent(f.supersededBy!, () => []).add(f);
      }
    }
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

  void _rebuildGraph(
    List<MemoryFact> facts,
    List<MemoryPolicy> policies,
    List<MemoryDomain> domains,
  ) {
    _nodeData.clear();
    _edges.clear();

    // Track parent-child relationships for layout
    final topicsByDomain = <String, List<String>>{};
    final factsByTopic = <String, List<String>>{};
    final policiesByDomain = <String, List<String>>{};
    final policySourceFacts = <String, List<String>>{};

    // Build domain set
    final domainNames = <String>{};
    for (final d in domains) {
      domainNames.add(d.name);
    }
    for (final f in facts) {
      if (!f.isSuperseded) {
        domainNames.add(f.domain);
      }
    }
    for (final p in policies) {
      domainNames.add(p.domain);
    }

    final domainLabels = <String, String>{};
    for (final d in domains) {
      domainLabels[d.name] = d.label;
    }

    // Create domain nodes
    final domainKeys = <String>[];
    for (final slug in domainNames) {
      final domainFacts = facts.where((f) {
        if (f.isSuperseded) {
          return false;
        }
        return f.domain == slug;
      }).toList();
      final domainPolicies = policies.where((p) => p.domain == slug).toList();

      if (domainFacts.isEmpty && domainPolicies.isEmpty) {
        continue;
      }

      final key = 'domain:$slug';
      domainKeys.add(key);
      _nodeData[key] = NodeData(
        type: NodeType.domain,
        domainSlug: slug,
        domainLabel: domainLabels[slug] ?? slug,
        factCount: domainFacts.length,
        policyCount: domainPolicies.length,
      );
    }

    // Create topic nodes
    final topics = facts.map((f) => f.topic).toSet();
    for (final topic in topics) {
      final topicFacts = facts.where((f) => f.topic == topic).toList();
      if (topicFacts.isEmpty) {
        continue;
      }
      final domainSlug = topicFacts.first.domain;
      final domainKey = 'domain:$domainSlug';

      if (!_nodeData.containsKey(domainKey)) {
        continue;
      }

      final key = 'topic:$topic';
      _nodeData[key] = NodeData(
        type: NodeType.topic,
        topic: topic,
        factCount: topicFacts.length,
      );

      topicsByDomain.putIfAbsent(domainKey, () => []).add(key);
    }

    // Create fact nodes
    for (final fact in facts) {
      if (fact.isSuperseded) {
        continue;
      }

      final supersededChain = _resolveSupersededChain(fact, facts);
      final key = 'fact:${fact.id}';
      _nodeData[key] = NodeData(
        type: NodeType.fact,
        fact: fact,
        supersededFacts: supersededChain,
      );

      final topicKey = 'topic:${fact.topic}';
      if (_nodeData.containsKey(topicKey)) {
        factsByTopic.putIfAbsent(topicKey, () => []).add(key);
      }
    }

    // Create policy nodes
    for (final policy in policies) {
      final key = 'policy:${policy.id}';
      _nodeData[key] = NodeData(
        type: NodeType.policy,
        policy: policy,
      );

      final domainKey = 'domain:${policy.domain}';
      if (_nodeData.containsKey(domainKey)) {
        policiesByDomain.putIfAbsent(domainKey, () => []).add(key);
      }

      final sourceFactKeys = <String>[];
      for (final factId in policy.sourceFactIds) {
        final factKey = 'fact:$factId';
        if (_nodeData.containsKey(factKey)) {
          sourceFactKeys.add(factKey);
        }
      }
      if (sourceFactKeys.isNotEmpty) {
        policySourceFacts[key] = sourceFactKeys;
      }
    }

    // Compute layout positions
    final positions = _computeLayout(
      domainKeys,
      topicsByDomain,
      factsByTopic,
      policiesByDomain,
    );

    // Every node in [_nodeData] must have a position — a node that the layout
    // didn't place (e.g. an orphan fact whose topic was skipped) falls back to
    // the origin rather than being dropped, matching the prior behavior and
    // keeping the render loop's lookups total.
    final fullPositions = <String, Offset>{
      for (final key in _nodeData.keys) key: positions[key] ?? Offset.zero,
    };

    _syncPositions(fullPositions);
    _canvasSize = _computeCanvasSize(fullPositions);

    // Build edges from the resolved parent-child relationships.
    _buildEdges(
      topicsByDomain,
      factsByTopic,
      policiesByDomain,
      policySourceFacts,
    );
  }

  /// Reconcile the [ValueNotifier] position store with the freshly computed
  /// [positions]: reuse notifiers for surviving keys (updating their value),
  /// create notifiers for new keys, and dispose notifiers for removed keys.
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
    }

    for (final entry in positions.entries) {
      final existing = _positions[entry.key];
      if (existing != null) {
        existing.value = entry.value;
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

  /// Computes the on-canvas position of every node.
  ///
  /// Returned offsets are the node's **top-left** corner (they feed straight
  /// into [Positioned]). Note the layout deliberately seeds X from a subtree's
  /// horizontal center (`x + subtreeWidth / 2`) and uses that as the top-left —
  /// this reproduces the exact placement of the previous flow-chart renderer
  /// (which positioned elements via `Transform.translate(offset: position)`),
  /// so the `+ width / 2` terms are intentional parity, not a centering bug.
  Map<String, Offset> _computeLayout(
    List<String> domainKeys,
    Map<String, List<String>> topicsByDomain,
    Map<String, List<String>> factsByTopic,
    Map<String, List<String>> policiesByDomain,
  ) {
    final positions = <String, Offset>{};
    if (domainKeys.isEmpty) {
      return positions;
    }

    // Step 1: Compute subtree widths for topics
    final topicSubtreeWidths = <String, double>{};
    for (final topicKey in topicsByDomain.values.expand((v) => v)) {
      final factKeys = factsByTopic[topicKey] ?? [];
      final width = factKeys.isEmpty
          ? _topicNodeSize.width
          : max(
              _topicNodeSize.width,
              factKeys.length * _factNodeSize.width +
                  (factKeys.length - 1) * _factGap,
            );
      topicSubtreeWidths[topicKey] = width;
    }

    // Step 2: Compute subtree widths for domains
    final domainSubtreeWidths = <String, double>{};
    for (final domainKey in domainKeys) {
      final topicKeys = topicsByDomain[domainKey] ?? [];
      final policyKeys = policiesByDomain[domainKey] ?? [];

      double topicsWidth = 0;
      if (topicKeys.isNotEmpty) {
        for (final topicKey in topicKeys) {
          topicsWidth += topicSubtreeWidths[topicKey] ?? _topicNodeSize.width;
        }
        topicsWidth += (topicKeys.length - 1) * _topicGap;
      }

      // Policies go in a column to the right of the domain subtree
      final policiesWidth =
          policyKeys.isNotEmpty ? _policyNodeSize.width + _domainGap : 0.0;

      domainSubtreeWidths[domainKey] = max(
        _domainNodeSize.width,
        topicsWidth + policiesWidth,
      );
    }

    // Step 3: Position domains
    double x = _startX;
    for (final domainKey in domainKeys) {
      final subtreeWidth = domainSubtreeWidths[domainKey]!;
      positions[domainKey] = Offset(x + subtreeWidth / 2, _layerDomainY);
      x += subtreeWidth + _domainGap;
    }

    // Step 4: Position topics under domains
    for (final domainKey in domainKeys) {
      final topicKeys = topicsByDomain[domainKey] ?? [];
      if (topicKeys.isEmpty) {
        continue;
      }

      final domainCenterX = positions[domainKey]!.dx;

      double totalWidth = 0;
      for (final topicKey in topicKeys) {
        totalWidth += topicSubtreeWidths[topicKey] ?? _topicNodeSize.width;
      }
      totalWidth += (topicKeys.length - 1) * _topicGap;

      double topicX = domainCenterX - totalWidth / 2;
      for (final topicKey in topicKeys) {
        final width = topicSubtreeWidths[topicKey] ?? _topicNodeSize.width;
        positions[topicKey] = Offset(topicX + width / 2, _layerTopicY);
        topicX += width + _topicGap;
      }
    }

    // Step 5: Position facts under topics
    for (final topicKey in topicsByDomain.values.expand((v) => v)) {
      final factKeys = factsByTopic[topicKey] ?? [];
      if (factKeys.isEmpty) {
        continue;
      }

      final topicCenterX = positions[topicKey]!.dx;
      final totalWidth = factKeys.length * _factNodeSize.width +
          (factKeys.length - 1) * _factGap;
      double factX = topicCenterX - totalWidth / 2;

      for (final factKey in factKeys) {
        positions[factKey] =
            Offset(factX + _factNodeSize.width / 2, _layerFactY);
        factX += _factNodeSize.width + _factGap;
      }
    }

    // Step 6: Position policies in a column to the right of their domain
    for (final domainKey in domainKeys) {
      final policyKeys = policiesByDomain[domainKey] ?? [];
      if (policyKeys.isEmpty) {
        continue;
      }

      final subtreeWidth = domainSubtreeWidths[domainKey]!;
      final domainCenterX = positions[domainKey]!.dx;
      final policyX =
          domainCenterX + subtreeWidth / 2 + _policyNodeSize.width / 2 + 40;

      for (var i = 0; i < policyKeys.length; i++) {
        final y = _layerDomainY + i * (_policyNodeSize.height + _policyGap);
        positions[policyKeys[i]] = Offset(policyX, y);
      }
    }

    return positions;
  }

  void _buildEdges(
    Map<String, List<String>> topicsByDomain,
    Map<String, List<String>> factsByTopic,
    Map<String, List<String>> policiesByDomain,
    Map<String, List<String>> policySourceFacts,
  ) {
    void add(String srcKey, String destKey, _EdgeRole role) {
      final src = _positions[srcKey];
      final dest = _positions[destKey];
      final srcType = _nodeData[srcKey]?.type;
      final destType = _nodeData[destKey]?.type;
      if (src == null || dest == null || srcType == null || destType == null) {
        return;
      }
      _edges.add(
        _GraphEdge(
          src: src,
          srcSize: _sizeForNodeType(srcType),
          dest: dest,
          destSize: _sizeForNodeType(destType),
          role: role,
        ),
      );
    }

    for (final entry in topicsByDomain.entries) {
      for (final topicKey in entry.value) {
        add(entry.key, topicKey, _EdgeRole.domainTopic);
      }
    }
    for (final entry in factsByTopic.entries) {
      for (final factKey in entry.value) {
        add(entry.key, factKey, _EdgeRole.topicFact);
      }
    }
    for (final entry in policiesByDomain.entries) {
      for (final policyKey in entry.value) {
        add(entry.key, policyKey, _EdgeRole.domainPolicy);
      }
    }
    for (final entry in policySourceFacts.entries) {
      for (final factKey in entry.value) {
        add(entry.key, factKey, _EdgeRole.policyFact);
      }
    }
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
    _transform.value = Matrix4(
      fitScale, 0, 0, 0, //
      0, fitScale, 0, 0, //
      0, 0, 1, 0, //
      tx, ty, 0, 1, //
    );
  }

  Widget _buildGraphCanvas(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (_nodeData.isEmpty) {
      return EmptyState(
        icon: LucideIcons.workflow,
        message: l10n.noMemoryData,
        description: l10n.memoryDataHint,
      );
    }

    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final edgeColor = tokens.borderSecondary;
    final policyEdgeColor = tokens.textPrimary.withValues(alpha: 0.35);
    final factEdgeColor = tokens.textTertiary.withValues(alpha: 0.25);

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
              return InteractiveViewer(
                transformationController: _transform,
                constrained: false,
                minScale: _minScale,
                maxScale: _maxScale,
                boundaryMargin: const EdgeInsets.all(double.infinity),
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
                                repaint: positionsListenable,
                                edgeColor: edgeColor,
                                policyEdgeColor: policyEdgeColor,
                                factEdgeColor: factEdgeColor,
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
                          child: _buildNodeVisual(
                            context,
                            entry.key,
                            entry.value,
                          ),
                        ),
                    ],
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
              CcIconButton(
                icon: LucideIcons.maximize2,
                onPressed: _fitToView,
                variant: CcButtonVariant.secondary,
                tooltip: AppLocalizations.of(context).fitToView,
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildLegend(context),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNodeVisual(
    BuildContext context,
    String key,
    NodeData data,
  ) {
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
            icon: LucideIcons.tag,
            color: tokens.fgBrandPrimary,
            label: l10n.domain,
          ),
          _LegendItem(
            icon: LucideIcons.hash,
            color: tokens.fgQuaternary,
            label: l10n.topic,
          ),
          _LegendItem(
            icon: LucideIcons.lightbulb,
            color: tokens.fgQuaternary,
            label: l10n.fact,
          ),
          _LegendItem(
            icon: LucideIcons.scale,
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
    required this.child,
    super.key,
  });

  final ValueNotifier<Offset> position;
  final Size size;
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
            // `delta` arrives in this widget's local (content) coordinates,
            // already corrected for the viewer's zoom, so it applies directly.
            onPanUpdate: (details) => position.value += details.delta,
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

/// The visual role of an edge, which determines its color, thickness, and the
/// node anchors it connects.
enum _EdgeRole { domainTopic, topicFact, domainPolicy, policyFact }

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

/// Paints every edge as a smooth curve between node anchors. Repaints whenever
/// any node position notifier fires (passed as `repaint`).
class _EdgePainter extends CustomPainter {
  _EdgePainter({
    required this.edges,
    required Listenable repaint,
    required this.edgeColor,
    required this.policyEdgeColor,
    required this.factEdgeColor,
  }) : super(repaint: repaint);

  final List<_GraphEdge> edges;
  final Color edgeColor;
  final Color policyEdgeColor;
  final Color factEdgeColor;

  @override
  void paint(Canvas canvas, Size size) {
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
      case _EdgeRole.domainTopic:
        return (
          color: edgeColor,
          thickness: 1.5,
          start: Alignment.bottomCenter,
          end: Alignment.topCenter,
        );
      case _EdgeRole.topicFact:
        return (
          color: edgeColor,
          thickness: 1,
          start: Alignment.bottomCenter,
          end: Alignment.topCenter,
        );
      case _EdgeRole.domainPolicy:
        return (
          color: policyEdgeColor,
          thickness: 2,
          start: Alignment.centerRight,
          end: Alignment.centerLeft,
        );
      case _EdgeRole.policyFact:
        return (
          color: factEdgeColor,
          thickness: 1.5,
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
    final p3 = end == Alignment.center
        ? to
        : Offset(to.dx + dx, to.dy + dy);
    final p2 = Offset(
      p1.dx + (p3.dx - p1.dx) / 2,
      p1.dy + (p3.dy - p1.dy) / 2,
    );

    return Path()
      ..moveTo(from.dx, from.dy)
      ..conicTo(p1.dx, p1.dy, p2.dx, p2.dy, 1)
      ..conicTo(p3.dx, p3.dy, to.dx, to.dy, 1);
  }

  @override
  bool shouldRepaint(_EdgePainter old) =>
      !identical(old.edges, edges) ||
      old.edgeColor != edgeColor ||
      old.policyEdgeColor != policyEdgeColor ||
      old.factEdgeColor != factEdgeColor;
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
            style: CcTypography.caption.copyWith(
              color: tokens.textSecondary,
            ),
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
/// color here; topics, facts, and policies stay neutral so blue keeps meaning.
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
                Icon(LucideIcons.tag, size: 14, color: tokens.fgBrandPrimary),
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
              AppLocalizations.of(context)
                  .factsPoliciesCount(factCount, policyCount),
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

/// Topic node — neutral grouping under a domain.
class _TopicNode extends StatelessWidget {
  const _TopicNode({
    required this.topic,
    required this.factCount,
    required this.onTap,
  });

  final String topic;
  final int factCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: tokens.bgSecondary,
          borderRadius: AppRadii.brMd,
          border: Border.all(color: tokens.borderSecondary),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.hash, size: 12, color: tokens.fgQuaternary),
                const SizedBox(width: AppSpacing.xs),
                Flexible(
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
            Text(
              factCount == 1
                  ? l10n.factCount(factCount)
                  : l10n.factCountPlural(factCount),
              style: CcTypography.caption.copyWith(
                color: tokens.textTertiary,
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
                      icon: LucideIcons.lightbulb,
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
                  Icon(LucideIcons.scale, size: 12, color: tokens.fgQuaternary),
                  const SizedBox(width: AppSpacing.xs),
                  Flexible(child: MemoryMetaChip(label: policy.domain)),
                  const Spacer(),
                  if (!policy.active)
                    Icon(
                      LucideIcons.eyeOff,
                      size: 12,
                      color: tokens.fgQuaternary,
                    ),
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
