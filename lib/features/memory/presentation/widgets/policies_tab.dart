import 'package:cc_domain/core/domain/entities/memory_policy.dart';
import 'package:cc_domain/features/memory/domain/value_objects/memory_domain_scope.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/memory/presentation/widgets/memory_error_view.dart';
import 'package:control_center/features/memory/presentation/widgets/memory_list_panel.dart';
import 'package:control_center/features/memory/presentation/widgets/memory_policy_row.dart';
import 'package:control_center/features/memory/presentation/widgets/memory_scope_widgets.dart';
import 'package:control_center/features/memory/providers/memory_providers.dart';
import 'package:control_center/features/settings/presentation/widgets/kit/settings_kit.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/empty_state.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _kFacetAll = 'all';
const _kFacetActive = 'active';
const _kFacetInactive = 'inactive';

/// Workspace policies grouped by domain, with inactive policies demoted to a
/// trailing group.
class PoliciesTab extends ConsumerStatefulWidget {
  /// Creates a [PoliciesTab].
  const PoliciesTab({super.key, required this.workspaceId});

  /// Workspace whose policies are shown.
  final String workspaceId;

  @override
  ConsumerState<PoliciesTab> createState() => _PoliciesTabState();
}

class _PoliciesTabState extends ConsumerState<PoliciesTab> {
  String _query = '';
  String _facet = _kFacetAll;
  String? _scope = kAllMemoryScopes;

  bool _matches(MemoryPolicy policy, String query) {
    if (!matchesMemoryScope(policy.domain, _scope)) {
      return false;
    }
    return query.isEmpty ||
        policy.rule.toLowerCase().contains(query) ||
        policy.domain.toLowerCase().contains(query);
  }

  /// The rows in reading order: a rail, then its policies. Flat, so the list
  /// can build them lazily.
  List<Widget> _rows(AppLocalizations l10n, List<MemoryPolicy> shown) {
    final byDomain = <String, List<MemoryPolicy>>{};
    for (final policy in shown.where((policy) => policy.active)) {
      byDomain.putIfAbsent(policy.domain, () => []).add(policy);
    }
    final inactive = shown.where((policy) => !policy.active).toList();
    return [
      for (final MapEntry(key: domain, value: policies)
          in byDomain.entries) ...[
        MemoryGroupRail(
          // The bare name, with the repo beside it as a chip: the `repo:`
          // prefix is how the scope is stored, not something to read.
          label: MemoryDomainScope.parse(domain).name,
          count: policies.length,
          domainSlug: domain,
        ),
        for (final policy in policies) MemoryPolicyRow(policy: policy),
      ],
      if (inactive.isNotEmpty) ...[
        MemoryGroupRail(label: l10n.inactive, count: inactive.length),
        for (final policy in inactive) MemoryPolicyRow(policy: policy),
      ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    final policiesAsync = ref.watch(memoryPoliciesProvider(widget.workspaceId));
    return policiesAsync.when(
      data: (policies) => _buildList(context, policies),
      loading: () => const Center(child: CcSpinner()),
      error: (e, _) => MemoryErrorView(
        error: e,
        onRetry: () =>
            ref.invalidate(memoryPoliciesProvider(widget.workspaceId)),
      ),
    );
  }

  Widget _buildList(BuildContext context, List<MemoryPolicy> policies) {
    final l10n = AppLocalizations.of(context);
    if (policies.isEmpty) {
      return EmptyState(
        icon: AppIcons.scale,
        message: l10n.noPolicies,
        description: l10n.policiesHint,
      );
    }

    final query = _query.trim().toLowerCase();
    final matching = policies
        .where((policy) => _matches(policy, query))
        .toList();
    final active = matching.where((policy) => policy.active).length;
    final shown = matching
        .where(
          (policy) => switch (_facet) {
            _kFacetActive => policy.active,
            _kFacetInactive => !policy.active,
            _ => true,
          },
        )
        .toList();
    final rows = _rows(l10n, shown);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MemoryListToolbar(
          query: _query,
          onQueryChanged: (query) => setState(() => _query = query),
          searchHint: l10n.searchPoliciesHint,
          facets: [
            SettingsFacet(
              value: _kFacetAll,
              label: l10n.all,
              count: matching.length,
            ),
            SettingsFacet(
              value: _kFacetActive,
              label: l10n.memoryPolicyActive,
              count: active,
            ),
            SettingsFacet(
              value: _kFacetInactive,
              label: l10n.inactive,
              count: matching.length - active,
            ),
          ],
          facet: _facet,
          onFacetChanged: (facet) => setState(() => _facet = facet),
          shown: shown.length,
          total: policies.length,
          controls: [
            MemoryScopeFilter(
              domainSlugs: policies.map((policy) => policy.domain),
              value: _scope,
              onChanged: (scope) => setState(() => _scope = scope),
            ),
          ],
        ),
        Expanded(
          child: rows.isEmpty
              ? EmptyState(
                  icon: AppIcons.searchX,
                  message: l10n.noPoliciesMatch,
                  query: _query.isEmpty ? null : _query,
                )
              : ListView.builder(
                  padding: kMemoryListPadding,
                  itemCount: rows.length,
                  itemBuilder: (context, index) =>
                      MemoryListItem(first: index == 0, child: rows[index]),
                ),
        ),
      ],
    );
  }
}
