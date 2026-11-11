import 'package:cc_domain/features/guardrails/domain/entities/action_policy_rule.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/system/guardrail_standing_entry.dart';
import 'package:flutter/widgets.dart';

/// The standing approvals and conditional rules listed under one action row
/// (or in the Commands group), soonest-ending first, then the permanent ones.
class GuardrailStandingList extends StatelessWidget {
  /// Creates a [GuardrailStandingList].
  const GuardrailStandingList({
    super.key,
    required this.rules,
    this.classDenied = false,
  });

  /// The live rules to list, all at the scope being edited.
  final List<ActionPolicyRule> rules;

  /// Whether the action these rules are about is set to deny. A standing
  /// approval never answers a deny, so it is then listed as not in effect.
  final bool classDenied;

  @override
  Widget build(BuildContext context) {
    final sorted = [...rules]..sort(_soonestEndFirst);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final rule in sorted)
            GuardrailStandingEntry(
              key: ValueKey(rule.id),
              rule: rule,
              inEffect: !(classDenied && rule.isStandingApproval),
            ),
        ],
      ),
    );
  }

  static int _soonestEndFirst(ActionPolicyRule a, ActionPolicyRule b) {
    final ae = a.expiresAt;
    final be = b.expiresAt;
    if (ae == null || be == null) {
      return ae == null ? (be == null ? 0 : 1) : -1;
    }
    return ae.compareTo(be);
  }
}
