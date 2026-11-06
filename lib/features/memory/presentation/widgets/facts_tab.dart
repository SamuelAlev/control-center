import 'package:cc_domain/core/domain/entities/memory_fact.dart';
import 'package:cc_domain/features/memory/domain/value_objects/memory_type.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/memory/presentation/widgets/memory_error_view.dart';
import 'package:control_center/features/memory/presentation/widgets/memory_fact_row.dart';
import 'package:control_center/features/memory/presentation/widgets/memory_list_panel.dart';
import 'package:control_center/features/memory/presentation/widgets/memory_scope_widgets.dart';
import 'package:control_center/features/memory/providers/memory_providers.dart';
import 'package:control_center/features/settings/presentation/widgets/kit/settings_kit.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/empty_state.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// How the fact list is ordered.
enum _FactSort { recent, confidence }

/// Facet showing every current fact. The others are a type's wire name, or
/// [_kFacetSuperseded].
const _kFacetAll = 'all';

/// Facet showing the facts a newer one has replaced, which every other facet
/// leaves out.
const _kFacetSuperseded = 'superseded';

/// Searchable, sortable list of memory facts for the active workspace.
class FactsTab extends ConsumerStatefulWidget {
  /// Creates a [FactsTab].
  const FactsTab({super.key, required this.workspaceId});

  /// Workspace whose facts are shown.
  final String workspaceId;

  @override
  ConsumerState<FactsTab> createState() => _FactsTabState();
}

class _FactsTabState extends ConsumerState<FactsTab> {
  String _query = '';
  String _facet = _kFacetAll;
  _FactSort _sort = _FactSort.recent;

  /// Selected scope: [kAllMemoryScopes], null for workspace-wide, or a repo
  /// slug. Starts at "all" so nothing is hidden before the person asks.
  String? _scope = kAllMemoryScopes;

  bool _matches(MemoryFact fact, String query) {
    if (!matchesMemoryScope(fact.domain, _scope)) {
      return false;
    }
    return query.isEmpty ||
        fact.topic.toLowerCase().contains(query) ||
        fact.content.toLowerCase().contains(query) ||
        fact.domain.toLowerCase().contains(query);
  }

  /// The facets over what scope and search leave, most common type first. Only
  /// types with something behind them appear, and the selected one stays so a
  /// search can't strand the reader on a facet with no way to see it.
  List<SettingsFacet<String>> _facets(
    AppLocalizations l10n,
    List<MemoryFact> matching,
  ) {
    final current = matching.where((fact) => !fact.isSuperseded);
    final byType = <MemoryType, int>{};
    for (final fact in current) {
      byType.update(fact.memoryType, (count) => count + 1, ifAbsent: () => 1);
    }
    final types = byType.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final superseded = matching.length - current.length;
    return [
      SettingsFacet(value: _kFacetAll, label: l10n.all, count: current.length),
      for (final type in types)
        SettingsFacet(
          value: type.key.wireName,
          label: type.key.label,
          count: type.value,
        ),
      if (_facet != _kFacetAll &&
          _facet != _kFacetSuperseded &&
          types.every((type) => type.key.wireName != _facet))
        SettingsFacet(
          value: _facet,
          label: MemoryType.parse(_facet).label,
          count: 0,
        ),
      if (superseded > 0 || _facet == _kFacetSuperseded)
        SettingsFacet(
          value: _kFacetSuperseded,
          label: l10n.superseded,
          count: superseded,
        ),
    ];
  }

  List<MemoryFact> _shown(List<MemoryFact> matching) {
    final shown = matching.where(
      (fact) => switch (_facet) {
        _kFacetAll => !fact.isSuperseded,
        _kFacetSuperseded => fact.isSuperseded,
        final type => !fact.isSuperseded && fact.memoryType.wireName == type,
      },
    );
    return shown.toList()..sort(
      (a, b) => switch (_sort) {
        _FactSort.recent => b.updatedAt.compareTo(a.updatedAt),
        _FactSort.confidence => b.confidence.compareTo(a.confidence),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final factsAsync = ref.watch(memoryFactsProvider(widget.workspaceId));
    return factsAsync.when(
      data: (facts) => _buildList(context, facts),
      loading: () => const Center(child: CcSpinner()),
      error: (e, _) => MemoryErrorView(
        error: e,
        onRetry: () => ref.invalidate(memoryFactsProvider(widget.workspaceId)),
      ),
    );
  }

  Widget _buildList(BuildContext context, List<MemoryFact> facts) {
    final l10n = AppLocalizations.of(context);
    if (facts.isEmpty) {
      return EmptyState(
        icon: AppIcons.lightbulb,
        message: l10n.noFacts,
        description: l10n.factsHint,
      );
    }

    final query = _query.trim().toLowerCase();
    final matching = facts.where((fact) => _matches(fact, query)).toList();
    final facets = _facets(l10n, matching);
    final shown = _shown(matching);
    final total = facts.where((fact) => !fact.isSuperseded).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MemoryListToolbar(
          query: _query,
          onQueryChanged: (query) => setState(() => _query = query),
          searchHint: l10n.searchFactsHint,
          facets: facets,
          facet: _facet,
          onFacetChanged: (facet) => setState(() => _facet = facet),
          shown: shown.length,
          total: total,
          controls: [
            MemoryScopeFilter(
              domainSlugs: facts.map((fact) => fact.domain),
              value: _scope,
              onChanged: (scope) => setState(() => _scope = scope),
            ),
            CcSegmentedToggle<_FactSort>(
              value: _sort,
              segments: [
                CcSegment(
                  value: _FactSort.recent,
                  label: l10n.sortRecent,
                  icon: AppIcons.clock,
                ),
                CcSegment(
                  value: _FactSort.confidence,
                  label: l10n.sortConfidence,
                  icon: AppIcons.gauge,
                ),
              ],
              onChanged: (sort) => setState(() => _sort = sort),
            ),
          ],
        ),
        Expanded(
          child: shown.isEmpty
              ? EmptyState(
                  icon: AppIcons.searchX,
                  message: l10n.noFactsMatch,
                  query: _query.isEmpty ? null : _query,
                )
              : ListView.builder(
                  padding: kMemoryListPadding,
                  itemCount: shown.length,
                  itemBuilder: (context, index) => MemoryListItem(
                    key: ValueKey(shown[index].id),
                    first: index == 0,
                    child: MemoryFactRow(fact: shown[index]),
                  ),
                ),
        ),
      ],
    );
  }
}
