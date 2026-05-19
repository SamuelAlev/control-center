import 'dart:math' show max;

import 'package:control_center/core/domain/entities/memory_fact.dart';
import 'package:control_center/core/domain/entities/memory_policy.dart';
import 'package:control_center/core/theme/app_radii.dart';
import 'package:control_center/core/theme/app_spacing.dart';
import 'package:control_center/core/theme/design_system_tokens.dart';
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
import 'package:flutter_flow_chart/flutter_flow_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
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

/// Interactive knowledge graph visualizing domains, topics, facts, and policies
/// as a navigable flow chart.
class KnowledgeGraph extends ConsumerStatefulWidget {
  /// Creates a [KnowledgeGraph] for the given [workspaceId].
  const KnowledgeGraph({super.key, required this.workspaceId});

  /// The workspace identifier whose memory entities to display.
  final String workspaceId;

  @override
  ConsumerState<KnowledgeGraph> createState() => _KnowledgeGraphState();
}

class _KnowledgeGraphState extends ConsumerState<KnowledgeGraph> {
  final _dashboard = Dashboard<NodeData>();
  final _nodeData = <String, NodeData>{};
  final _elementForKey = <String, FlowElement<NodeData>>{};
  final _keyForElementId = <String, String>{};

  List<MemoryFact>? _lastFacts;
  List<MemoryPolicy>? _lastPolicies;
  List<MemoryDomain>? _lastDomains;
  bool _hasCentered = false;

  void _retry() {
    ref.invalidate(memoryFactsProvider(widget.workspaceId));
    ref.invalidate(memoryPoliciesProvider(widget.workspaceId));
    ref.invalidate(memoryDomainsProvider(widget.workspaceId));
  }

  /// Bring the graph into view: reset zoom and recenter on the content. Called
  /// once after the first non-empty layout, and from the "Fit to view" button.
  void _fitToView() {
    _dashboard
      ..setZoomFactor(1)
      ..recenter();
  }

  @override
  void initState() {
    super.initState();
    _dashboard.gridBackgroundParams = GridBackgroundParams(
      backgroundColor: Colors.transparent,
      gridColor: Colors.transparent,
      gridThickness: 0,
    );
  }

  @override
  void dispose() {
    _dashboard.dispose();
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
              _rebuildGraph(context, facts, policies, domains);
            }
            // Center the graph on its content the first time it has any, so the
            // operator doesn't open onto an empty canvas and have to hunt.
            if (!_hasCentered && _nodeData.isNotEmpty) {
              _hasCentered = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  _dashboard.recenter();
                }
              });
            }
            return _buildFlowChart(context);
          },
          loading: () => const Center(child: FCircularProgress()),
          error: (e, _) => MemoryErrorView(error: e, onRetry: _retry),
        ),
        loading: () => const Center(child: FCircularProgress()),
        error: (e, _) => MemoryErrorView(error: e, onRetry: _retry),
      ),
      loading: () => const Center(child: FCircularProgress()),
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
    BuildContext context,
    List<MemoryFact> facts,
    List<MemoryPolicy> policies,
    List<MemoryDomain> domains,
  ) {
    _dashboard.removeAllElements(notify: false);
    _elementForKey.clear();
    _keyForElementId.clear();
    _nodeData.clear();

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

    // Create FlowElements
    for (final entry in _nodeData.entries) {
      final key = entry.key;
      final data = entry.value;
      final pos = positions[key] ?? Offset.zero;
      final size = _sizeForNodeType(data.type);

      final element = FlowElement<NodeData>(
        position: pos,
        size: size,
        kind: ElementKind.custom,
        handlers: [],
        handlerSize: 0,
        isDraggable: true,
        isConnectable: false,
        isResizable: false,
        isDeletable: false,
        backgroundColor: Colors.transparent,
        borderColor: Colors.transparent,
        borderThickness: 0,
        elevation: 0,
        elementData: data,
      );

      _dashboard.addElement(element, notify: false);
      _elementForKey[key] = element;
      _keyForElementId[element.id] = key;
    }

    // Create connections
    _addConnections(
      context,
      topicsByDomain,
      factsByTopic,
      policiesByDomain,
      policySourceFacts,
    );
  }

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

  void _addConnections(
    BuildContext context,
    Map<String, List<String>> topicsByDomain,
    Map<String, List<String>> factsByTopic,
    Map<String, List<String>> policiesByDomain,
    Map<String, List<String>> policySourceFacts,
  ) {
    final colors = context.theme.colors;
    final edgeColor = colors.border;
    final policyEdgeColor = colors.primary.withValues(alpha: 0.35);
    final factEdgeColor = colors.mutedForeground.withValues(alpha: 0.25);

    // Domain → Topic
    for (final entry in topicsByDomain.entries) {
      final domainElement = _elementForKey[entry.key];
      if (domainElement == null) {
        continue;
      }

      for (final topicKey in entry.value) {
        final topicElement = _elementForKey[topicKey];
        if (topicElement == null) {
          continue;
        }

        _dashboard.addNextById(
          domainElement,
          topicElement.id,
          ArrowParams(
            thickness: 1.5,
            color: edgeColor,
            headRadius: 0,
            tailLength: 0,
            style: ArrowStyle.curve,
            startArrowPosition: Alignment.bottomCenter,
            endArrowPosition: Alignment.topCenter,
          ),
          notify: false,
        );
      }
    }

    // Topic → Fact
    for (final entry in factsByTopic.entries) {
      final topicElement = _elementForKey[entry.key];
      if (topicElement == null) {
        continue;
      }

      for (final factKey in entry.value) {
        final factElement = _elementForKey[factKey];
        if (factElement == null) {
          continue;
        }

        _dashboard.addNextById(
          topicElement,
          factElement.id,
          ArrowParams(
            thickness: 1,
            color: edgeColor,
            headRadius: 0,
            tailLength: 0,
            style: ArrowStyle.curve,
            startArrowPosition: Alignment.bottomCenter,
            endArrowPosition: Alignment.topCenter,
          ),
          notify: false,
        );
      }
    }

    // Domain → Policy
    for (final entry in policiesByDomain.entries) {
      final domainElement = _elementForKey[entry.key];
      if (domainElement == null) {
        continue;
      }

      for (final policyKey in entry.value) {
        final policyElement = _elementForKey[policyKey];
        if (policyElement == null) {
          continue;
        }

        _dashboard.addNextById(
          domainElement,
          policyElement.id,
          ArrowParams(
            thickness: 2,
            color: policyEdgeColor,
            headRadius: 0,
            tailLength: 0,
            style: ArrowStyle.curve,
            startArrowPosition: Alignment.centerRight,
            endArrowPosition: Alignment.centerLeft,
          ),
          notify: false,
        );
      }
    }

    // Policy → Fact
    for (final entry in policySourceFacts.entries) {
      final policyElement = _elementForKey[entry.key];
      if (policyElement == null) {
        continue;
      }

      for (final factKey in entry.value) {
        final factElement = _elementForKey[factKey];
        if (factElement == null) {
          continue;
        }

        _dashboard.addNextById(
          policyElement,
          factElement.id,
          ArrowParams(
            thickness: 1.5,
            color: factEdgeColor,
            headRadius: 0,
            tailLength: 0,
            style: ArrowStyle.curve,
            startArrowPosition: Alignment.bottomCenter,
            endArrowPosition: Alignment.topCenter,
          ),
          notify: false,
        );
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

  Widget _buildFlowChart(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (_nodeData.isEmpty) {
      return EmptyState(
        icon: LucideIcons.workflow,
        message: l10n.noMemoryData,
        description: l10n.memoryDataHint,
      );
    }

    return Stack(
      children: [
        // Dot-grid backdrop that pans and zooms with the graph. The dashboard
        // drives `gridBackgroundParams.offset` (pan) and `.scale` (zoom) as a
        // ChangeNotifier, so reading them keeps the grid locked to the nodes.
        Positioned.fill(
          child: IgnorePointer(
            child: ListenableBuilder(
              listenable: _dashboard.gridBackgroundParams,
              builder: (context, _) {
                final params = _dashboard.gridBackgroundParams;
                return DotGridBackground(
                  offset: params.offset,
                  scale: params.scale,
                );
              },
            ),
          ),
        ),
        FlowChart<NodeData>(
          dashboard: _dashboard,
          customElementBuilder: _buildCustomElement,
          onElementPressed: (context, position, element) {
            _showNodeSheet(context, element.id);
          },
        ),
        Positioned(
          top: AppSpacing.md,
          right: AppSpacing.md,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              FTooltip(
                tipBuilder: (_, _) => Text(AppLocalizations.of(context).fitToView),
                child: FButton.icon(
                  onPress: _fitToView,
                  variant: FButtonVariant.outline,
                  child: const Icon(LucideIcons.maximize2, size: 16),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildLegend(context),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCustomElement(
    BuildContext context,
    FlowElement<NodeData> element,
  ) {
    final data = element.elementData;
    if (data == null) {
      return const SizedBox.shrink();
    }

    switch (data.type) {
      case NodeType.domain:
        return _DomainNode(
          domainLabel: data.domainLabel ?? data.domainSlug ?? '',
          factCount: data.factCount,
          policyCount: data.policyCount,
          onTap: () => _showNodeSheet(context, element.id),
        );
      case NodeType.topic:
        return _TopicNode(
          topic: data.topic!,
          factCount: data.factCount,
          onTap: () => _showNodeSheet(context, element.id),
        );
      case NodeType.fact:
        return _FactNode(
          fact: data.fact!,
          supersededCount: data.supersededFacts.length,
          onTap: () => _showNodeSheet(context, element.id),
        );
      case NodeType.policy:
        return _PolicyNode(
          policy: data.policy!,
          onTap: () => _showNodeSheet(context, element.id),
        );
    }
  }

  void _showNodeSheet(BuildContext context, String elementId) {
    final key = _keyForElementId[elementId];
    if (key == null) {
      return;
    }

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
    final confirmed = await showFDialog<bool>(
      context: context,
      builder: (dialogContext, style, animation) => FDialog(
        style: style,
        animation: animation,
        title: Text(l10n.deleteFact),
        body: Text(l10n.deleteTopicConfirm(fact.topic)),
        actions: [
          SizedBox(
            width: double.infinity,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FButton(
                  onPress: () => Navigator.of(dialogContext).pop(false),
                  variant: FButtonVariant.outline,
                  child: Text(l10n.cancel),
                ),
                const SizedBox(width: 8),
                FButton(
                  onPress: () => Navigator.of(dialogContext).pop(true),
                  variant: FButtonVariant.destructive,
                  child: Text(l10n.delete),
                ),
              ],
            ),
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
    final confirmed = await showFDialog<bool>(
      context: context,
      builder: (dialogContext, style, animation) => FDialog(
        style: style,
        animation: animation,
        title: Text(l10n.deletePolicy),
        body: Text(l10n.deletePolicyConfirm),
        actions: [
          SizedBox(
            width: double.infinity,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FButton(
                  onPress: () => Navigator.of(dialogContext).pop(false),
                  variant: FButtonVariant.outline,
                  child: Text(l10n.cancel),
                ),
                const SizedBox(width: 8),
                FButton(
                  onPress: () => Navigator.of(dialogContext).pop(true),
                  variant: FButtonVariant.destructive,
                  child: Text(l10n.delete),
                ),
              ],
            ),
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
            style: context.theme.typography.xs.copyWith(
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
            style: context.theme.typography.xs.copyWith(
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

/// Data payload carried by each node in the knowledge graph flow chart.
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
                    style: context.theme.typography.sm.copyWith(
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
              style: context.theme.typography.xs.copyWith(
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
                    style: context.theme.typography.xs.copyWith(
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
              style: context.theme.typography.xs.copyWith(
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
                style: context.theme.typography.xs.copyWith(
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
                style: context.theme.typography.xs.copyWith(
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
