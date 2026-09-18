part of 'knowledge_graph.dart';

extension _RenderMethods on _KnowledgeGraphState {
  /// Rebuilds the hulls drawn behind each cluster. They hold their members'
  /// position NOTIFIERS rather than offsets, so a hull follows a card the
  /// operator drags instead of going stale behind it.
  void _buildHulls() {
    final hulls = <ClusterHull>[];
    for (final cluster in _clusters) {
      final members = <HullMember>[];
      for (final key in cluster.memberKeys) {
        final position = _positions[key];
        final data = _nodeData[key];
        if (position == null || data == null) {
          continue;
        }
        members.add(HullMember(position, _sizeForNodeType(data.type)));
      }
      if (members.isNotEmpty) {
        hulls.add(ClusterHull(members));
      }
    }
    _hulls = hulls;
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
    final edges = <GraphEdge>[];
    void add(String srcKey, String destKey, EdgeRole role) {
      final src = _positions[srcKey];
      final dest = _positions[destKey];
      final srcType = _nodeData[srcKey]?.type;
      final destType = _nodeData[destKey]?.type;
      if (src == null || dest == null || srcType == null || destType == null) {
        return;
      }
      edges.add(
        GraphEdge(
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
          add(strip.topicKey, factKey, EdgeRole.topicFact);
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
        add(policyKey, 'fact:$factId', EdgeRole.policyFact);
      }
    }
    _edges = edges;
  }

  Widget _buildNodeVisual(BuildContext context, String key, NodeData data) {
    switch (data.type) {
      case NodeType.domain:
        return DomainNode(
          domainLabel: data.domainLabel ?? data.domainSlug ?? '',
          factCount: data.factCount,
          policyCount: data.policyCount,
          onTap: () => _showNodeSheet(context, key),
        );
      case NodeType.topic:
        return TopicNode(
          topic: data.topic!,
          factCount: data.factCount,
          expanded: _expandedTopics.contains(key),
          onToggle: () => _toggleTopic(key),
          onTap: () => _showNodeSheet(context, key),
        );
      case NodeType.fact:
        return FactNode(
          fact: data.fact!,
          supersededCount: data.supersededFacts.length,
          onTap: () => _showNodeSheet(context, key),
        );
      case NodeType.policy:
        return PolicyNode(
          policy: data.policy!,
          onTap: () => _showNodeSheet(context, key),
        );
    }
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
    final hullBorderColor = tokens.borderSecondary.withValues(alpha: 0.7);
    final hullFillColor = tokens.textPrimary.withValues(alpha: 0.025);

    final positionsListenable = Listenable.merge(_positions.values.toList());

    return Stack(
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
        Positioned.fill(
          child: LayoutBuilder(
            builder: (context, constraints) {
              _viewport = constraints.biggest;
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
                                painter: EdgePainter(
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
                          GraphNode(
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
          LegendItem(
            icon: AppIcons.tag,
            color: tokens.fgBrandPrimary,
            label: l10n.domain,
          ),
          LegendItem(
            icon: AppIcons.hash,
            color: tokens.fgQuaternary,
            label: l10n.topic,
          ),
          LegendItem(
            icon: AppIcons.lightbulb,
            color: tokens.fgQuaternary,
            label: l10n.fact,
          ),
          LegendItem(
            icon: AppIcons.scale,
            color: tokens.fgQuaternary,
            label: l10n.policy,
          ),
        ],
      ),
    );
  }
}
