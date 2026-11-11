import 'package:cc_domain/cc_domain.dart' show UserDto;
import 'package:cc_domain/core/domain/entities/server_audit_entry.dart';
import 'package:cc_domain/core/domain/value_objects/audit_log_page.dart'
    show AuditLogPageDto, AuditLogScopeDto, AuditLogScopeKind;
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/audit/audit_log_row.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/audit/audit_time_filter.dart';
import 'package:control_center/features/settings/providers/audit_log_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The name a scope reads as: the workspace's name, or "Server".
String auditScopeLabel(AppLocalizations l10n, AuditLogScopeDto scope) =>
    scope.kind == AuditLogScopeKind.server
    ? l10n.auditLogSourceServer
    : (scope.name?.isNotEmpty ?? false)
    ? scope.name!
    : l10n.auditLogSourceWorkspace;

/// The audit log's search field, facet filter menu (actor, workspace,
/// outcome, with how many records each would show), time conditions, and a
/// dismissible chip per active filter. Every change drops the page cursor
/// through [onFiltersChanged].
class AuditLogToolbar extends ConsumerStatefulWidget {
  /// Creates the toolbar.
  const AuditLogToolbar({
    super.key,
    required this.page,
    required this.users,
    required this.onFiltersChanged,
  });

  /// The current page, for facet options and counts; null while loading.
  final AuditLogPageDto? page;

  /// Display names for actors.
  final Map<String, UserDto> users;

  /// Called after any filter changed.
  final VoidCallback onFiltersChanged;

  @override
  ConsumerState<AuditLogToolbar> createState() => _AuditLogToolbarState();
}

class _AuditLogToolbarState extends ConsumerState<AuditLogToolbar> {
  late final TextEditingController _search = TextEditingController(
    text: ref.read(auditLogFiltersProvider).search,
  );
  final CcOverlayController _time = CcOverlayController();

  @override
  void dispose() {
    _search.dispose();
    _time.dispose();
    super.dispose();
  }

  AuditLogFiltersNotifier get _filters =>
      ref.read(auditLogFiltersProvider.notifier);

  void _changed(void Function(AuditLogFiltersNotifier f) change) {
    change(_filters);
    widget.onFiltersChanged();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final filters = ref.watch(auditLogFiltersProvider);
    final page = widget.page;
    final scopes = page?.scopes ?? const <AuditLogScopeDto>[];
    final scopeNames = {
      for (final s in scopes) s.key: auditScopeLabel(l10n, s),
    };
    String actorName(String id) {
      final name = widget.users[id]?.displayName ?? '';
      return name.isNotEmpty ? name : l10n.unknownUserLabel;
    }

    final actorCounts = page?.actorCounts ?? const <String, int>{};
    final actorIds = {...actorCounts.keys, ...filters.actorIds};

    final chips = <Widget>[
      if (filters.actorIds.isNotEmpty)
        CcChip(
          label: _summary(l10n, l10n.auditLogFilterActor, [
            for (final id in filters.actorIds) actorName(id),
          ]),
          onDeleted: () => _changed((f) => f.setActors(const {})),
        ),
      if (filters.sources.isNotEmpty)
        CcChip(
          label: _summary(l10n, l10n.auditLogFilterSource, [
            for (final key in filters.sources)
              scopeNames[key] ?? l10n.auditLogSourceWorkspace,
          ]),
          onDeleted: () => _changed((f) => f.setSources(const {})),
        ),
      if (filters.outcomes.isNotEmpty)
        CcChip(
          label: _summary(l10n, l10n.auditLogFilterOutcome, [
            for (final o in AuditOutcome.values)
              if (filters.outcomes.contains(o)) auditOutcomeLabel(l10n, o),
          ]),
          onDeleted: () => _changed((f) => f.setOutcomes(const {})),
        ),
      for (final (i, c) in filters.time.indexed)
        CcChip(
          label: auditTimeChipLabel(l10n, c),
          semanticLabel: auditTimeSemanticLabel(l10n, c),
          onDeleted: () => _changed((f) => f.removeTime(i)),
        ),
      if (filters.ip case final ip?)
        CcChip(
          label: l10n.activityFilterIp(ip),
          onDeleted: () => _changed((f) => f.toggleIp(ip)),
        ),
      if (filters.country case final country?)
        CcChip(
          label: l10n.activityFilterCountry(country),
          onDeleted: () => _changed((f) => f.toggleCountry(country)),
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: CcTextField(
                controller: _search,
                size: CcTextFieldSize.sm,
                hintText: l10n.activitySearchHint,
                prefix: Icon(AppIcons.search, size: 16, color: t.textTertiary),
                onChanged: (value) => _changed((f) => f.setSearch(value)),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            CcFilterMenu(
              semanticLabel: l10n.auditLogAddFilter,
              optionSearchHint: l10n.auditLogFilterOptionsHint,
              target: _ToolbarChip(
                icon: AppIcons.listFilter,
                label: l10n.auditLogAddFilter,
              ),
              categories: [
                CcFilterCategory(
                  id: 'actor',
                  label: l10n.auditLogFilterActor,
                  icon: AppIcons.users,
                  selected: filters.actorIds,
                  options: [
                    for (final id in actorIds)
                      CcFilterOption(
                        value: id,
                        label: actorName(id),
                        count: actorCounts[id] ?? 0,
                      ),
                  ]..sort((a, b) => b.count.compareTo(a.count)),
                  onChanged: (next) => _changed((f) => f.setActors(next)),
                ),
                if (scopes.length > 1)
                  CcFilterCategory(
                    id: 'source',
                    label: l10n.auditLogFilterSource,
                    icon: AppIcons.layers,
                    selected: filters.sources,
                    options: [
                      for (final s in scopes)
                        CcFilterOption(
                          value: s.key,
                          label: scopeNames[s.key]!,
                          count: page?.sourceCounts[s.key] ?? 0,
                          pinned: true,
                        ),
                    ],
                    onChanged: (next) => _changed((f) => f.setSources(next)),
                  ),
                CcFilterCategory(
                  id: 'outcome',
                  label: l10n.auditLogFilterOutcome,
                  icon: AppIcons.shieldCheck,
                  selected: {for (final o in filters.outcomes) o.name},
                  options: [
                    for (final o in AuditOutcome.values)
                      CcFilterOption(
                        value: o.name,
                        label: auditOutcomeLabel(l10n, o),
                        count: page?.outcomeCounts[o] ?? 0,
                        pinned: true,
                      ),
                  ],
                  onChanged: (next) => _changed(
                    (f) => f.setOutcomes({
                      for (final name in next) AuditOutcome.values.byName(name),
                    }),
                  ),
                ),
              ],
            ),
            const SizedBox(width: AppSpacing.sm),
            CcPopover(
              controller: _time,
              targetAnchor: AlignmentDirectional.bottomEnd,
              followerAnchor: AlignmentDirectional.topEnd,
              semanticLabel: l10n.auditLogFilterTime,
              target: _ToolbarChip(
                icon: AppIcons.clock,
                label: l10n.auditLogFilterTime,
              ),
              overlayBuilder: (context, _) => AuditTimeFilterPanel(
                onAdd: (condition) {
                  _time.hide();
                  _changed((f) => f.addTime(condition));
                },
              ),
            ),
          ],
        ),
        if (chips.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: chips,
          ),
        ],
      ],
    );
  }

  static String _summary(
    AppLocalizations l10n,
    String category,
    List<String> values,
  ) {
    final shown = values.take(2).join(', ');
    final rest = values.length - 2;
    return l10n.auditLogFilterChip(
      category,
      rest > 0 ? l10n.auditLogFilterChipMore(shown, rest) : shown,
    );
  }
}

/// Inert chip chrome for a popover/menu target: never a `CcButton`, which
/// would swallow the target's toggle tap.
class _ToolbarChip extends StatelessWidget {
  const _ToolbarChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        color: t.bgPrimary,
        border: Border.all(color: t.borderPrimary),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: t.textSecondary),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            maxLines: 1,
            style: CcTypography.bodySm.copyWith(color: t.textPrimary),
          ),
        ],
      ),
    );
  }
}
