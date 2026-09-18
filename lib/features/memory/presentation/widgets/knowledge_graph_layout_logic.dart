part of 'knowledge_graph.dart';

/// Graph rebuild, layout, topic toggling and viewport centering for
/// [KnowledgeGraph].
extension _LayoutLogic on _KnowledgeGraphState {
  void _rebuildGraph(
    List<MemoryFact> facts,
    List<MemoryPolicy> policies,
    List<MemoryDomain> domains,
  ) {
    _nodeData.clear();
    _clusters.clear();

    final domainLabels = {for (final d in domains) d.name: d.label};

    final factsByTopic = <String, List<MemoryFact>>{};
    final topicNames = <String, String>{};
    final topicsByDomain = <String, List<String>>{};
    for (final fact in facts) {
      if (fact.isSuperseded) {
        continue;
      }
      final topicKey = _KnowledgeGraphState._topicKey(fact.domain, fact.topic);
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
    final bySuperseder = _KnowledgeGraphState._indexBySuperseder(facts);

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

    final fullPositions = <String, Offset>{
      for (final key in _nodeData.keys) key: positions[key] ?? Offset.zero,
    };

    _syncPositions(fullPositions);
    _canvasSize = _computeCanvasSize(fullPositions);
    _buildHulls();
    _buildEdges(policies);
  }

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

  void _reflow() {
    final facts = _lastFacts;
    final policies = _lastPolicies;
    final domains = _lastDomains;
    if (facts == null || policies == null || domains == null) {
      return;
    }
    _rebuildGraph(facts, policies, domains);
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

  Size _sizeForNodeType(NodeType type) {
    switch (type) {
      case NodeType.domain:
        return domainNodeSize;
      case NodeType.topic:
        return topicNodeSize;
      case NodeType.fact:
        return factNodeSize;
      case NodeType.policy:
        return policyNodeSize;
    }
  }

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
    final tx = _viewport.width / 2 - fitScale * center.dx;
    final ty = _viewport.height / 2 - fitScale * center.dy;
    _transform.value = Matrix4.identity()
      ..translateByDouble(tx, ty, 0, 1)
      ..scaleByDouble(fitScale, fitScale, fitScale, 1);
  }
}
