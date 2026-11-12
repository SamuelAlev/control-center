import 'package:cc_domain/core/domain/value_objects/money.dart';
import 'package:cc_domain/features/guardrails/domain/entities/action_policy_rule.dart';
import 'package:cc_domain/features/guardrails/domain/value_objects/action_decision.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/settings/presentation/widgets/kit/settings_kit.dart';
import 'package:control_center/features/settings/providers/guardrail_policy_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/app_timestamp.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// What [rule] does, in one sentence: "Allowed for branches feature/**".
String guardrailEntryDescription(
  AppLocalizations l10n,
  Locale locale,
  ActionPolicyRule rule,
) {
  final number = NumberFormat.decimalPattern(locale.toString());
  final constraint = rule.constraint;
  final prefix = rule.commandPrefix;
  final refs = constraint?.refs;
  final paths = constraint?.paths;
  final hosts = constraint?.hosts;
  final commands = constraint?.commands;
  final tools = constraint?.tools;
  final maxCount = constraint?.maxCount;
  final maxMicros = constraint?.maxMicros;
  final facets = [
    if (prefix != null) l10n.guardrailCoversCommandPrefix(_isolate([prefix])),
    if (refs != null) l10n.guardrailCoversBranches(_isolate(refs)),
    if (paths != null) l10n.guardrailCoversPaths(_isolate(paths)),
    if (hosts != null) l10n.guardrailCoversHosts(_isolate(hosts)),
    if (commands != null) l10n.guardrailCoversCommands(_isolate(commands)),
    if (tools != null) l10n.guardrailCoversTools(_isolate(tools)),
    if (maxCount != null) l10n.guardrailCoversMaxCount(number.format(maxCount)),
    if (maxMicros != null)
      l10n.guardrailCoversMaxCents(number.format(maxMicros / microsPerCent)),
  ];
  final what = facets.isEmpty
      ? l10n.guardrailCoversEverything
      : facets.join(', ');
  return switch (rule.decision) {
    ActionDecision.allow => l10n.guardrailEntryAllow(what),
    ActionDecision.prompt => l10n.guardrailEntryPrompt(what),
    ActionDecision.deny => l10n.guardrailEntryDeny(what),
  };
}

/// Branch globs, paths and commands are left-to-right tokens whose trailing
/// `**` or `/` would jump to the wrong end inside a right-to-left sentence, so
/// they are isolated (FSI … PDI).
String _isolate(List<String> values) => '\u2068${values.join(', ')}\u2069';

/// The end time: the clock time when it is today, with the date otherwise
/// (an 8-hour approval given in the evening ends tomorrow).
String _endLabel(Locale locale, DateTime at) {
  final local = at.toLocal();
  final now = DateTime.now();
  final today =
      local.year == now.year &&
      local.month == now.month &&
      local.day == now.day;
  final tag = locale.toString();
  return today
      ? DateFormat.jm(tag).format(local)
      : DateFormat.MMMd(tag).add_jm().format(local);
}

/// One standing approval or conditional rule at the scope being edited: what
/// it allows, whose it is, when it ends, and a revoke action that appears on
/// hover. Revoking needs no confirmation: it only makes agents ask again.
class GuardrailStandingEntry extends ConsumerStatefulWidget {
  /// Creates a [GuardrailStandingEntry].
  const GuardrailStandingEntry({
    super.key,
    required this.rule,
    this.inEffect = true,
  });

  /// The rule this entry shows.
  final ActionPolicyRule rule;

  /// False for a standing approval of an action that is set to deny: it stays
  /// listed (and revocable) until it ends, and says it changes nothing.
  final bool inEffect;

  @override
  ConsumerState<GuardrailStandingEntry> createState() =>
      _GuardrailStandingEntryState();
}

class _GuardrailStandingEntryState
    extends ConsumerState<GuardrailStandingEntry> {
  bool _hovered = false;
  bool _revoking = false;

  Future<void> _revoke() async {
    final failed = AppLocalizations.of(context).guardrailRevokeFailed;
    final toasts = CcToastScope.maybeOf(context);
    setState(() => _revoking = true);
    try {
      await deleteActionPolicyRule(ref, widget.rule.id);
    } on Object {
      toasts?.show(failed, variant: CcToastVariant.danger);
    } finally {
      if (mounted) {
        setState(() => _revoking = false);
      }
    }
  }

  /// Who gave it, named only when it was somebody other than the viewer: a
  /// solo operator does not need their own name on every line.
  String? _giver() {
    final by = widget.rule.createdBy;
    if (by == null || by.isEmpty) {
      return null;
    }
    final me = ref.watch(currentUserIdProvider);
    if (me == null || me == by) {
      return null;
    }
    final name = ref.watch(usersByIdProvider).value?[by]?.displayName;
    return name == null || name.isEmpty ? null : name;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final locale = Localizations.localeOf(context);
    final rule = widget.rule;
    final description = guardrailEntryDescription(l10n, locale, rule);
    final giver = _giver();
    final expiresAt = rule.expiresAt;
    final meta = CcTypography.caption.copyWith(color: t.textTertiary);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.md,
        ),
        child: Row(
          children: [
            Icon(
              expiresAt == null ? AppIcons.shield : AppIcons.clock,
              size: 14,
              color: t.textTertiary,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text.rich(
                TextSpan(
                  style: meta,
                  children: [
                    TextSpan(
                      text: description,
                      style: CcTypography.bodySm.copyWith(
                        color: widget.inEffect
                            ? t.textSecondary
                            : t.textTertiary,
                      ),
                    ),
                    if (rule.isStandingApproval)
                      TextSpan(text: ' · ${l10n.guardrailStandingApproval}'),
                    if (!widget.inEffect)
                      TextSpan(text: ' · ${l10n.guardrailEntryInactive}'),
                    if (giver != null)
                      TextSpan(text: ' · ${l10n.guardrailEntryGivenBy(giver)}'),
                    const TextSpan(text: ' · '),
                    if (expiresAt == null)
                      TextSpan(text: l10n.guardrailEntryNoEnd)
                    else
                      WidgetSpan(
                        alignment: PlaceholderAlignment.baseline,
                        baseline: TextBaseline.alphabetic,
                        child: AppTimestamp(
                          dateTime: expiresAt,
                          child: Text(
                            l10n.guardrailEntryEnds(
                              _endLabel(locale, expiresAt),
                            ),
                            style: meta,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            SettingsHoverReveal(
              active: _hovered,
              child: CcIconButton(
                icon: AppIcons.x,
                size: CcButtonSize.sm,
                tooltip: l10n.revoke,
                semanticLabel: l10n.guardrailRevokeEntry(description),
                loading: _revoking,
                onPressed: _revoking ? null : _revoke,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
