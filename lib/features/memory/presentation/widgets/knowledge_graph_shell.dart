part of 'knowledge_graph.dart';

extension _ShellMethods on _KnowledgeGraphState {
  Widget _buildGraphShell(BuildContext context) {
    if (_nodeData.isEmpty) {
      return _buildGraphCanvas(context);
    }
    final key = _selectedKey;
    final data = key == null ? null : _nodeData[key];
    return LayoutBuilder(
      builder: (context, constraints) {
        final docked = constraints.maxWidth >= _inspectorDockBreakpoint;
        final width = docked
            ? kKnowledgeGraphInspectorWidth
            : constraints.maxWidth;
        return ClipRect(
          child: Stack(
            children: [
              PositionedDirectional(
                top: 0,
                bottom: 0,
                start: 0,
                end: docked && data != null ? width : 0,
                child: _buildGraphCanvas(context),
              ),
              PositionedDirectional(
                top: 0,
                bottom: 0,
                end: 0,
                width: width,
                child: _buildInspectorSlot(context, key, data),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Slides the inspector in from the end, and out again when it closes. The
  /// key is fixed so moving between nodes swaps the content in place.
  Widget _buildInspectorSlot(
    BuildContext context,
    String? key,
    NodeData? data,
  ) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    return AnimatedSwitcher(
      duration: CcMotion.resolveTravel(context, CcMotion.moderate),
      reverseDuration: CcMotion.resolveTravel(context, CcMotion.moderateExit),
      switchInCurve: CcMotion.emphasized,
      switchOutCurve: CcMotion.standard,
      transitionBuilder: (child, animation) => SlideTransition(
        position: animation.drive(
          Tween(begin: Offset(isRtl ? -1 : 1, 0), end: Offset.zero),
        ),
        child: child,
      ),
      child: key == null || data == null
          ? const SizedBox.shrink(key: ValueKey('no-inspector'))
          : _buildInspector(context, key, data),
    );
  }

  Widget _buildInspector(BuildContext context, String key, NodeData data) {
    final fact = data.fact;
    final policy = data.policy;
    return KnowledgeGraphInspector(
      key: const ValueKey('inspector'),
      nodeData: data,
      onClose: _clearSelection,
      onOpen: switch (data.type) {
        NodeType.fact => () => openMemoryFact(context, fact!),
        NodeType.policy => () => openMemoryPolicy(context, policy!),
        _ => null,
      },
      onDelete: switch (data.type) {
        NodeType.fact => () => unawaited(deleteMemoryFact(context, ref, fact!)),
        NodeType.policy => () =>
          unawaited(deleteMemoryPolicy(context, ref, policy!)),
        _ => null,
      },
      onToggleActive: policy == null
          ? null
          : (active) =>
                unawaited(setMemoryPolicyActive(ref, policy, active: active)),
      onToggleFacts: data.type == NodeType.topic
          ? () => _toggleTopic(key)
          : null,
      factsShown: _expandedTopics.contains(key),
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
