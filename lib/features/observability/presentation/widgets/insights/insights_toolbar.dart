import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/value_objects/agent_run_role.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/observability/providers/insights_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The Insights toolbar: faceted filter menu (agent / model / status / role)
/// with dismissible selection chips, then the global time-range picker on the
/// trailing edge.
class InsightsToolbar extends ConsumerWidget {
  /// Creates an [InsightsToolbar].
  const InsightsToolbar({super.key, required this.rangeController});

  /// Controls the range-picker popover (owned by the tab so a selection can
  /// close it).
  final CcOverlayController rangeController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final filters = ref.watch(obsRunFiltersProvider);
    final options = ref.watch(insightsFilterOptionsProvider);

    return Row(
      children: [
        CcFilterMenu(
          semanticLabel: l10n.obsAddFilter,
          target: _ChipChrome(icon: AppIcons.plus, label: l10n.obsAddFilter),
          categories: [
            _category(
              ref,
              id: 'agent',
              label: l10n.obsFilterAgent,
              options: options.agents,
              selected: filters.agentIds,
              sync: _syncAgents,
            ),
            _category(
              ref,
              id: 'model',
              label: l10n.obsFilterModel,
              options: options.models,
              selected: filters.modelKeys,
              sync: _syncModels,
            ),
            _category(
              ref,
              id: 'status',
              label: l10n.obsFilterStatus,
              options: options.statuses,
              selected: {for (final s in filters.statuses) s.name},
              sync: _syncStatuses,
            ),
            _category(
              ref,
              id: 'role',
              label: l10n.obsFilterRole,
              options: options.roles,
              selected: {for (final r in filters.roles) r.name},
              sync: _syncRoles,
            ),
          ],
        ),
        if (filters.agentIds.isNotEmpty) ...[
          const SizedBox(width: AppSpacing.sm),
          CcChip(
            label: _selectionSummary(
              l10n.obsFilterAgent,
              _agentLabels(filters, options),
            ),
            onDeleted: () =>
                ref.read(obsRunFiltersProvider.notifier).clearAgents(),
          ),
        ],
        if (filters.modelKeys.isNotEmpty) ...[
          const SizedBox(width: AppSpacing.sm),
          CcChip(
            label: _selectionSummary(l10n.obsFilterModel, [
              for (final key in filters.modelKeys) key.isEmpty ? '—' : key,
            ]),
            onDeleted: () =>
                ref.read(obsRunFiltersProvider.notifier).clearModels(),
          ),
        ],
        if (filters.statuses.isNotEmpty) ...[
          const SizedBox(width: AppSpacing.sm),
          CcChip(
            label: _selectionSummary(l10n.obsFilterStatus, [
              for (final s in filters.statuses) _statusLabel(l10n, s),
            ]),
            onDeleted: () =>
                ref.read(obsRunFiltersProvider.notifier).clearStatuses(),
          ),
        ],
        if (filters.roles.isNotEmpty) ...[
          const SizedBox(width: AppSpacing.sm),
          CcChip(
            label: _selectionSummary(l10n.obsFilterRole, [
              for (final r in filters.roles) _roleLabel(l10n, r),
            ]),
            onDeleted: () =>
                ref.read(obsRunFiltersProvider.notifier).clearRoles(),
          ),
        ],
        const Spacer(),
        _RangePicker(controller: rangeController),
      ],
    );
  }

  CcFilterCategory _category(
    WidgetRef ref, {
    required String id,
    required String label,
    required List<ObsFilterOptionValue> options,
    required Set<String> selected,
    required void Function(WidgetRef ref, Set<String> next) sync,
  }) {
    return CcFilterCategory(
      id: id,
      label: label,
      options: [
        for (final option in options)
          CcFilterOption(
            value: option.value,
            label: option.label,
            count: option.count,
          ),
      ],
      selected: selected,
      onChanged: (next) => sync(ref, next),
    );
  }

  static List<String> _agentLabels(
    ObsRunFilters filters,
    ({
      List<ObsFilterOptionValue> agents,
      List<ObsFilterOptionValue> models,
      List<ObsFilterOptionValue> statuses,
      List<ObsFilterOptionValue> roles,
    })
    options,
  ) {
    final names = {for (final a in options.agents) a.value: a.label};
    return [for (final id in filters.agentIds) names[id] ?? id];
  }

  static String _selectionSummary(String category, List<String> values) {
    final shown = values.take(2).join(', ');
    final rest = values.length - 2;
    return '$category: $shown${rest > 0 ? ' +$rest' : ''}';
  }

  static String _statusLabel(AppLocalizations l10n, RunStatus status) =>
      switch (status) {
        RunStatus.pending => l10n.obsStatusPending,
        RunStatus.running => l10n.obsStatusRunning,
        RunStatus.completed => l10n.obsStatusCompleted,
        RunStatus.error => l10n.obsStatusError,
      };

  static String _roleLabel(AppLocalizations l10n, AgentRunRole role) =>
      switch (role) {
        AgentRunRole.main => l10n.obsRoleMain,
        AgentRunRole.sub => l10n.obsAgentKindSub,
        AgentRunRole.advisor => l10n.obsRoleAdvisor,
      };

  static void _syncAgents(WidgetRef ref, Set<String> next) {
    final notifier = ref.read(obsRunFiltersProvider.notifier);
    final current = ref.read(obsRunFiltersProvider).agentIds;
    for (final value in current.difference(next)) {
      notifier.toggleAgent(value);
    }
    for (final value in next.difference(current)) {
      notifier.toggleAgent(value);
    }
  }

  static void _syncModels(WidgetRef ref, Set<String> next) {
    final notifier = ref.read(obsRunFiltersProvider.notifier);
    final current = ref.read(obsRunFiltersProvider).modelKeys;
    for (final value in current.difference(next)) {
      notifier.toggleModel(value);
    }
    for (final value in next.difference(current)) {
      notifier.toggleModel(value);
    }
  }

  static void _syncStatuses(WidgetRef ref, Set<String> next) {
    final notifier = ref.read(obsRunFiltersProvider.notifier);
    final current = {
      for (final s in ref.read(obsRunFiltersProvider).statuses) s.name,
    };
    for (final value in current.difference(next)) {
      notifier.toggleStatus(RunStatus.values.byName(value));
    }
    for (final value in next.difference(current)) {
      notifier.toggleStatus(RunStatus.values.byName(value));
    }
  }

  static void _syncRoles(WidgetRef ref, Set<String> next) {
    final notifier = ref.read(obsRunFiltersProvider.notifier);
    final current = {
      for (final r in ref.read(obsRunFiltersProvider).roles) r.name,
    };
    for (final value in current.difference(next)) {
      notifier.toggleRole(AgentRunRole.values.byName(value));
    }
    for (final value in next.difference(current)) {
      notifier.toggleRole(AgentRunRole.values.byName(value));
    }
  }
}

/// The global time-range picker: a chip-styled popover target showing the
/// active preset, opening a panel of the four presets.
class _RangePicker extends ConsumerWidget {
  const _RangePicker({required this.controller});

  final CcOverlayController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final range = ref.watch(obsTimeRangeProvider);

    return CcPopover(
      controller: controller,
      targetAnchor: Alignment.bottomRight,
      followerAnchor: Alignment.topRight,
      semanticLabel: _label(l10n, range),
      target: _ChipChrome(
        icon: AppIcons.chevronDown,
        label: _label(l10n, range),
        iconTrailing: true,
      ),
      overlayBuilder: (context, _) {
        final t = context.designSystem ?? DesignSystemTokens.light();
        return SizedBox(
          width: 200,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final preset in ObsTimeRange.values)
                CcTappable(
                  semanticLabel: _label(l10n, preset),
                  onPressed: () {
                    ref.read(obsTimeRangeProvider.notifier).setRange(preset);
                    controller.hide();
                  },
                  builder: (context, states) {
                    final hovered = states.contains(WidgetState.hovered);
                    return Container(
                      color: hovered ? t.bgSecondary : t.bgPrimary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _label(l10n, preset),
                              style: CcTypography.bodySm.copyWith(
                                color: t.textPrimary,
                              ),
                            ),
                          ),
                          if (preset == range)
                            Icon(
                              AppIcons.check,
                              size: 14,
                              color: t.textSecondary,
                            ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  static String _label(AppLocalizations l10n, ObsTimeRange range) =>
      switch (range) {
        ObsTimeRange.last24h => l10n.obsRangeLast24h,
        ObsTimeRange.last7d => l10n.obsRangeLast7d,
        ObsTimeRange.last30d => l10n.obsRangeLast30d,
        ObsTimeRange.all => l10n.obsRangeAll,
      };
}

/// Inert chip chrome for popover/menu targets — NEVER a `CcButton` (it would
/// swallow the target's toggle tap).
class _ChipChrome extends StatelessWidget {
  const _ChipChrome({
    required this.icon,
    required this.label,
    this.iconTrailing = false,
  });

  final IconData icon;
  final String label;
  final bool iconTrailing;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final iconWidget = Icon(icon, size: 14, color: t.textSecondary);
    final labelWidget = Flexible(
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: CcTypography.bodySm.copyWith(color: t.textPrimary),
      ),
    );
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: t.bgPrimary,
        borderRadius: AppRadii.brLg,
        border: Border.all(color: t.borderPrimary),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!iconTrailing) ...[
            iconWidget,
            const SizedBox(width: AppSpacing.xs),
          ],
          labelWidget,
          if (iconTrailing) ...[
            const SizedBox(width: AppSpacing.xs),
            iconWidget,
          ],
        ],
      ),
    );
  }
}
