import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/features/sandboxing/domain/command_policy/command_policy.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/widgets.dart';

/// A read-only view of CC's shell-command policy that makes its layering
/// legible: which command rules apply *always* (the global baseline) versus
/// which are imposed by the currently-selected conversation mode. Each rule
/// carries a provenance badge ([CcSourceBadge]) and a decision tag
/// ([CcStatusTag]).
///
/// This is the Phase 2/3 "where does this rule come from?" surface: a globally
/// denied command reads `GLOBAL`, a command denied only because the agent is in
/// a read-only mode reads as that mode's override.
class CommandRulesSection extends StatefulWidget {
  /// Creates a [CommandRulesSection].
  const CommandRulesSection({super.key});

  @override
  State<CommandRulesSection> createState() => _CommandRulesSectionState();
}

class _CommandRulesSectionState extends State<CommandRulesSection> {
  Mode _mode = Mode.chat;

  String _modeLabel(AppLocalizations l10n, Mode mode) => switch (mode) {
    Mode.chat => l10n.modeChat,
    Mode.plan => l10n.modePlan,
    Mode.review => l10n.modeReview,
    Mode.orchestrate => l10n.modeOrchestrate,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isReadOnly = _mode != Mode.chat;

    // Global baseline: always denied, plus the "ask first" set in chat.
    const baselineDeny = defaultDeny;
    final baselinePrompt = isReadOnly ? const <String>[] : defaultPrompt;
    // Mode overrides: read-only modes additionally deny the prompt + mutating
    // sets outright.
    final modeDenied = isReadOnly
        ? <String>[...defaultPrompt, ...mutatingCommands]
        : const <String>[];

    return SectionCard(
      label: l10n.commandRules,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Text(
              l10n.commandRulesDescription,
              style: CcTypography.bodySm.copyWith(
                color: context.designSystem?.textTertiary,
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: SegmentedToggle<Mode>(
              value: _mode,
              onChanged: (m) => setState(() => _mode = m),
              segments: [
                for (final m in Mode.values)
                  (value: m, label: _modeLabel(l10n, m)),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          for (final rule in baselineDeny)
            CcConfigRow(
              title: Text(rule),
              source: CcConfigSource.global,
              sourceLabel: l10n.scopeGlobal,
              status: CcStatusTag(
                label: l10n.ruleDenied,
                tone: CcStatusTone.negative,
                dot: false,
              ),
            ),
          for (final rule in baselinePrompt)
            CcConfigRow(
              title: Text(rule),
              source: CcConfigSource.defaultValue,
              status: CcStatusTag(
                label: l10n.ruleAsk,
                tone: CcStatusTone.caution,
                dot: false,
              ),
            ),
          for (final rule in modeDenied)
            CcConfigRow(
              title: Text(rule),
              source: CcConfigSource.localOverride,
              sourceLabel: _modeLabel(l10n, _mode).toUpperCase(),
              status: CcStatusTag(
                label: l10n.ruleDenied,
                tone: CcStatusTone.negative,
                dot: false,
              ),
            ),
        ],
      ),
    );
  }
}
