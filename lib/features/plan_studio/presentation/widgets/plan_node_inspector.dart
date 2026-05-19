import 'dart:convert';

import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/features/orchestration/domain/value_objects/plan_annotations.dart';
import 'package:cc_domain/features/plan_studio/domain/value_objects/plan_graph.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/plan_studio/presentation/widgets/plan_node_visuals.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/markdown/markdown_text_field.dart';
import 'package:flutter/widgets.dart';

/// The right-hand inspector for the selected plan node (PRD 17 §2/§3/§7).
///
/// Edits title/description/role/deps/priority/output-schema on work nodes
/// (structural nodes are read-only), shows the honest estimate detail, and
/// renders provenance chips. Already-executed nodes are read-only and marked
/// "already executed — edit forks the plan".
class PlanNodeInspector extends StatefulWidget {
  /// Creates a [PlanNodeInspector].
  const PlanNodeInspector({
    super.key,
    required this.graph,
    required this.node,
    required this.agents,
    required this.editable,
    required this.readOnly,
    required this.onNodeChanged,
    this.liveInfo,
  });

  /// The full graph (for the dependency editor + cycle guard).
  final PlanGraph graph;

  /// The selected node.
  final PlanNode node;

  /// Workspace agents, for role reassignment.
  final List<Agent> agents;

  /// Whether structural edits are allowed at all.
  final bool editable;

  /// Whether THIS node is read-only (already executed).
  final bool readOnly;

  /// Called with the edited node.
  final ValueChanged<PlanNode> onNodeChanged;

  /// Optional live execution info line (cost/duration actual vs estimate).
  final String? liveInfo;

  @override
  State<PlanNodeInspector> createState() => _PlanNodeInspectorState();
}

class _PlanNodeInspectorState extends State<PlanNodeInspector> {
  late TextEditingController _title;
  late TextEditingController _description;
  late TextEditingController _schema;
  final FocusNode _descFocus = FocusNode();
  String? _schemaError;

  @override
  void initState() {
    super.initState();
    _bind();
  }

  @override
  void didUpdateWidget(PlanNodeInspector old) {
    super.didUpdateWidget(old);
    if (old.node.key != widget.node.key) {
      _title.dispose();
      _description.dispose();
      _schema.dispose();
      _bind();
    }
  }

  void _bind() {
    _title = TextEditingController(text: widget.node.title);
    _description = TextEditingController(text: widget.node.description);
    _schema = TextEditingController(
      text: widget.node.expectedOutputSchema == null
          ? ''
          : const JsonEncoder.withIndent(
              '  ',
            ).convert(widget.node.expectedOutputSchema),
    );
    _schemaError = null;
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _schema.dispose();
    _descFocus.dispose();
    super.dispose();
  }

  bool get _canEdit =>
      widget.editable && widget.node.isWork && !widget.readOnly;

  void _emit(PlanNode node) => widget.onNodeChanged(node);

  @override
  Widget build(BuildContext context) {
    final ds = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final node = widget.node;
    final type = planNodeTypeVisual(node.type);

    return Container(
      width: 360,
      decoration: BoxDecoration(
        color: ds.bgSecondary,
        border: Border(left: BorderSide(color: ds.borderPrimary)),
      ),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Icon(type.icon, size: 15, color: ds.textTertiary),
              const SizedBox(width: 6),
              Text(
                type.label,
                style: TextStyle(
                  fontSize: 12,
                  color: ds.textTertiary,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (widget.readOnly)
            _Banner(
              icon: AppIcons.lock,
              text: l10n.planNodeAlreadyExecuted,
              color: ds.textWarningPrimary,
            ),
          _Label(l10n.planNodeTitle),
          CcTextField(
            controller: _title,
            enabled: _canEdit,
            onChanged: (v) => _emit(node.copyWith(title: v)),
          ),
          const SizedBox(height: 14),
          _Label(l10n.planNodeDescription),
          if (_canEdit)
            SizedBox(
              height: 160,
              child: MarkdownTextField(
                controller: _description,
                focusNode: _descFocus,
                hintText: l10n.planNodeDescriptionHint,
                minLines: 6,
              ),
            )
          else
            Text(
              node.description.isEmpty ? '—' : node.description,
              style: TextStyle(
                fontSize: 13,
                color: ds.textSecondary,
                decoration: TextDecoration.none,
              ),
            ),
          if (_canEdit)
            Align(
              alignment: Alignment.centerRight,
              child: CcButton(
                variant: CcButtonVariant.ghost,
                size: CcButtonSize.sm,
                onPressed: () =>
                    _emit(node.copyWith(description: _description.text)),
                child: Text(l10n.planNodeApplyDescription),
              ),
            ),
          const SizedBox(height: 14),
          if (node.roleKey != null) ...[
            _Label(l10n.planNodeRole),
            _RoleSelector(
              node: node,
              graph: widget.graph,
              agents: widget.agents,
              enabled: _canEdit,
              onChanged: _emit,
            ),
            const SizedBox(height: 14),
          ],
          _Label(l10n.planNodeDependencies),
          _DependencyEditor(
            graph: widget.graph,
            node: node,
            enabled: _canEdit,
            onChanged: _emit,
          ),
          const SizedBox(height: 14),
          if (node.isWork) ...[
            _Label(l10n.planNodeOutputSchema),
            CcTextField(
              controller: _schema,
              enabled: _canEdit,
              errorText: _schemaError,
              onChanged: _onSchemaChanged,
            ),
            const SizedBox(height: 14),
          ],
          _Label(l10n.planNodeEstimate),
          _EstimateDetail(estimate: node.estimate),
          if (widget.liveInfo != null) ...[
            const SizedBox(height: 6),
            Text(
              widget.liveInfo!,
              style: TextStyle(
                fontSize: 12,
                color: ds.textSecondary,
                decoration: TextDecoration.none,
              ),
            ),
          ],
          const SizedBox(height: 14),
          _Label(l10n.planNodeProvenance),
          _ProvenanceChips(refs: node.provenance),
        ],
      ),
    );
  }

  void _onSchemaChanged(String raw) {
    if (raw.trim().isEmpty) {
      setState(() => _schemaError = null);
      _emit(widget.node.copyWith(clearExpectedOutputSchema: true));
      return;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        setState(() => _schemaError = 'Schema must be a JSON object.');
        return;
      }
      setState(() => _schemaError = null);
      _emit(widget.node.copyWith(expectedOutputSchema: decoded));
    } catch (_) {
      setState(() => _schemaError = 'Invalid JSON.');
    }
  }
}

class _RoleSelector extends StatelessWidget {
  const _RoleSelector({
    required this.node,
    required this.graph,
    required this.agents,
    required this.enabled,
    required this.onChanged,
  });

  final PlanNode node;
  final PlanGraph graph;
  final List<Agent> agents;
  final bool enabled;
  final ValueChanged<PlanNode> onChanged;

  @override
  Widget build(BuildContext context) {
    // Role keys available in the plan (from other nodes) + the current one.
    final roleKeys = <String>{
      for (final n in graph.nodes)
        if (n.roleKey != null && n.roleKey!.isNotEmpty) n.roleKey!,
    }.toList()..sort();
    return CcSelect<String>(
      value: roleKeys.contains(node.roleKey) ? node.roleKey : null,
      enabled: enabled,
      options: [
        for (final key in roleKeys) CcSelectOption(value: key, label: key),
      ],
      onChanged: (v) {
        onChanged(node.copyWith(roleKey: v));
      },
    );
  }
}

/// The dependency editor for one node.
///
/// Small plans keep the flat checkbox list: with a handful of candidates it is
/// the fastest thing to read and one tap to toggle. Past
/// [_inlineDependencyLimit] that list stops being a list and becomes a wall —
/// a 30-node plan rendered 29 unchecked rows, which buries the two dependencies
/// that are set and reads as "this node depends on everything". Above the
/// threshold it collapses into the design system's [CcMultiSelect], which shows
/// the selection as chips, floats selected rows to the top of its panel, and is
/// keyboard-navigable.
class _DependencyEditor extends StatelessWidget {
  const _DependencyEditor({
    required this.graph,
    required this.node,
    required this.enabled,
    required this.onChanged,
  });

  /// Candidate count above which the flat list collapses into a picker.
  static const int _inlineDependencyLimit = 8;

  final PlanGraph graph;
  final PlanNode node;
  final bool enabled;
  final ValueChanged<PlanNode> onChanged;

  /// Applies [selected] while preserving dependency ORDER: existing deps keep
  /// their position and additions append. `dependsOn.last` is load-bearing — the
  /// canvas's `x` keybinding cuts the newest inbound edge — so a set round-trip
  /// must not reshuffle the list.
  void _apply(Set<String> selected) {
    onChanged(
      node.copyWith(
        dependsOn: [
          for (final dep in node.dependsOn)
            if (selected.contains(dep)) dep,
          for (final key in selected)
            if (!node.dependsOn.contains(key)) key,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ds = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    // Candidate deps: every OTHER node. Toggling one runs the cycle guard via
    // PlanGraph.validate on the tentative edit.
    final candidates = graph.nodes.where((n) => n.key != node.key).toList();
    if (candidates.isEmpty) {
      return Text(
        '—',
        style: TextStyle(
          color: ds.textTertiary,
          decoration: TextDecoration.none,
        ),
      );
    }
    final selected = node.dependsOn.toSet();

    if (candidates.length <= _inlineDependencyLimit) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final c in candidates)
            _DepRow(
              label: c.title.isEmpty ? c.key : c.title,
              selected: selected.contains(c.key),
              enabled: enabled,
              onToggle: (on) => _apply(
                on ? {...selected, c.key} : {...selected}
                  ..remove(c.key),
              ),
            ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CcMultiSelect<String>(
          values: selected,
          enabled: enabled,
          showChips: true,
          hintText: l10n.planNodeDependenciesHint,
          countLabel: l10n.planNodeDependencyCount,
          onChanged: _apply,
          options: [
            for (final c in candidates)
              CcSelectOption(
                value: c.key,
                label: c.title.isEmpty ? c.key : c.title,
              ),
          ],
        ),
        if (selected.isEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.planNodeNoDependencies,
            style: TextStyle(
              fontSize: 12,
              color: ds.textSecondary,
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ],
    );
  }
}

class _DepRow extends StatelessWidget {
  const _DepRow({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onToggle,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final ds = context.designSystem ?? DesignSystemTokens.light();
    return GestureDetector(
      onTap: enabled ? () => onToggle(!selected) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Icon(
              selected ? AppIcons.squareCheck : AppIcons.square,
              size: 15,
              color: selected ? ds.accent : ds.textTertiary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: enabled ? ds.textSecondary : ds.textTertiary,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EstimateDetail extends StatelessWidget {
  const _EstimateDetail({required this.estimate});

  final PlanNodeEstimate? estimate;

  @override
  Widget build(BuildContext context) {
    final ds = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final e = estimate;
    TextStyle style() => TextStyle(
      fontSize: 12,
      color: ds.textSecondary,
      decoration: TextDecoration.none,
    );
    if (e == null || !e.hasHistory) {
      return Text(l10n.planEstimateNoHistory, style: style());
    }
    final costLo = ((e.costCentsLow ?? 0) / 100).toStringAsFixed(2);
    final costHi = ((e.costCentsHigh ?? 0) / 100).toStringAsFixed(2);
    final durLo = _mins(e.durationMsLow);
    final durHi = _mins(e.durationMsHigh);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('\$$costLo–$costHi · n=${e.sampleSize}', style: style()),
        if (e.durationMsLow != null)
          Text(l10n.planEstimateDuration('$durLo–$durHi'), style: style()),
        Text(
          e.blastRadiusFiles != null
              ? l10n.planEstimateBlastRadius(
                  e.blastRadiusFiles!,
                  e.blastRadiusSymbols ?? 0,
                )
              : l10n.planEstimateBlastUnknown,
          style: style(),
        ),
      ],
    );
  }

  static String _mins(int? ms) =>
      ms == null ? '?' : '${(ms / 60000).toStringAsFixed(1)}m';
}

class _ProvenanceChips extends StatelessWidget {
  const _ProvenanceChips({required this.refs});

  final List<PlanProvenanceRef> refs;

  @override
  Widget build(BuildContext context) {
    final ds = context.designSystem ?? DesignSystemTokens.light();
    if (refs.isEmpty) {
      return Text(
        '—',
        style: TextStyle(
          color: ds.textTertiary,
          decoration: TextDecoration.none,
        ),
      );
    }
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final ref in refs)
          CcTooltip(
            // The full ref stays reachable: the chip shows the readable name,
            // the tooltip shows what it actually points at.
            message: '${ref.kind}: ${ref.ref}',
            child: CcChip(
              label: _labelFor(ref),
              leadingIcon: _iconFor(ref.kind),
              semanticLabel: '${ref.kind}: ${ref.label ?? ref.ref}',
            ),
          ),
      ],
    );
  }

  /// What the chip reads as.
  ///
  /// A labelled ref shows its label. An unlabelled one used to render
  /// `kind:ref` verbatim, which for a code-graph symbol is `symbol:` plus a
  /// content hash — the id is deterministic, not human-readable, so that chip
  /// said nothing at all. Labels are resolved server-side when a plan is
  /// submitted; this is the fallback for the plans written before that and for
  /// a symbol that has since been re-indexed away: name what we can (a file's
  /// basename), and otherwise say the kind plus a short id rather than a wall
  /// of hash.
  static String _labelFor(PlanProvenanceRef ref) {
    final label = ref.label?.trim() ?? '';
    if (label.isNotEmpty) {
      return label;
    }
    final target = ref.ref.trim();
    if (target.isEmpty) {
      return ref.kind;
    }
    if (ref.kind == 'file') {
      return target.split('/').last;
    }
    if (target.length <= 12) {
      return '${ref.kind} $target';
    }
    return '${ref.kind} ${target.substring(0, 8)}…';
  }

  IconData _iconFor(String kind) => switch (kind) {
    'symbol' => AppIcons.code,
    'file' => AppIcons.file,
    'memory' => AppIcons.brain,
    'message' => AppIcons.messageSquare,
    'goal' => AppIcons.target,
    'answer' => AppIcons.circleHelp,
    _ => AppIcons.link,
  };
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final ds = context.designSystem ?? DesignSystemTokens.light();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: ds.textTertiary,
          decoration: TextDecoration.none,
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.icon, required this.text, required this.color});
  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: color,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
