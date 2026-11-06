import 'dart:async';

import 'package:cc_domain/core/domain/entities/memory_fact.dart';
import 'package:cc_domain/core/domain/entities/memory_policy.dart';
import 'package:cc_domain/features/memory/domain/value_objects/memory_domain_scope.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/memory/presentation/widgets/confidence_meter.dart';
import 'package:control_center/features/memory/presentation/widgets/memory_actions.dart';
import 'package:control_center/features/memory/presentation/widgets/memory_record_page.dart';
import 'package:control_center/features/memory/presentation/widgets/memory_scope_widgets.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/app_timestamp.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The rows every record shares: where it lives and when it changed.
List<Widget> _placeRows(
  AppLocalizations l10n, {
  required String domain,
  required DateTime createdAt,
  required DateTime updatedAt,
}) => [
  MemoryDetailRow(
    label: l10n.domainLabel,
    child: Text(MemoryDomainScope.parse(domain).name),
  ),
  if (MemoryDomainScope.repoSlugOf(domain) != null)
    MemoryDetailRow(
      label: l10n.repository,
      child: MemoryScopeChip(domainSlug: domain),
    ),
  MemoryDetailRow(label: l10n.created, child: AppTimestamp.relative(createdAt)),
  MemoryDetailRow(
    label: l10n.prPropertyUpdated,
    child: AppTimestamp.relative(updatedAt),
  ),
];

/// What a fact is, beyond what it says.
class MemoryFactDetails extends StatelessWidget {
  /// Creates a [MemoryFactDetails].
  const MemoryFactDetails({super.key, required this.fact});

  /// The fact.
  final MemoryFact fact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SectionCard(
      label: l10n.detailsLabel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: memoryFactDetailRows(l10n, fact),
      ),
    );
  }
}

/// The rows of a fact's details, for any panel that shows them.
List<Widget> memoryFactDetailRows(AppLocalizations l10n, MemoryFact fact) => [
  MemoryDetailRow(
    label: l10n.sortConfidence,
    child: ConfidenceMeter(confidence: fact.confidence),
  ),
  MemoryDetailRow(
    label: l10n.memoryFactType,
    child: Text(fact.memoryType.label),
  ),
  if (fact.authoredByRole != null)
    MemoryDetailRow(
      label: l10n.roleLabel,
      child: Text(fact.authoredByRole!.label),
    ),
  MemoryDetailRow(
    label: l10n.memoryTimesRecalled,
    child: Text('${fact.recallCount}'),
  ),
  ..._placeRows(
    l10n,
    domain: fact.domain,
    createdAt: fact.createdAt,
    updatedAt: fact.updatedAt,
  ),
];

/// What a policy is, beyond what it says, and the switch that turns it off.
class MemoryPolicyDetails extends ConsumerWidget {
  /// Creates a [MemoryPolicyDetails].
  const MemoryPolicyDetails({super.key, required this.policy});

  /// The policy.
  final MemoryPolicy policy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return SectionCard(
      label: l10n.detailsLabel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          MemoryDetailRow(
            label: l10n.memoryPolicyActive,
            child: CcSwitch(
              value: policy.active,
              semanticLabel: l10n.memoryPolicyActive,
              onChanged: (active) =>
                  unawaited(setMemoryPolicyActive(ref, policy, active: active)),
            ),
          ),
          ...memoryPolicyDetailRows(l10n, policy),
        ],
      ),
    );
  }
}

/// The rows of a policy's details, for any panel that shows them.
List<Widget> memoryPolicyDetailRows(
  AppLocalizations l10n,
  MemoryPolicy policy,
) => [
  MemoryDetailRow(
    label: l10n.roleLabel,
    child: Text(policy.requiredRole?.label ?? l10n.noneAllRoles),
  ),
  ..._placeRows(
    l10n,
    domain: policy.domain,
    createdAt: policy.createdAt,
    updatedAt: policy.updatedAt,
  ),
];
