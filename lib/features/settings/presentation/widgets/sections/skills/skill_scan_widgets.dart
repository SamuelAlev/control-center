import 'package:cc_domain/features/skills/domain/scanner/skill_scan_types.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/settings/providers/skill_security_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';

/// Shared pieces of the skills-antivirus UI (PRD 23 §3): the verdict badge,
/// finding tiles, the explicit quarantine override and the scan-report
/// dialog. Used by BOTH the registry browse flow (pre-install preview) and the
/// installed-skills surface (post-install status/re-scan), so the two never
/// drift apart visually.

/// The scan-verdict pill: a coloured dot AND an always-visible label, so the
/// verdict is never conveyed by colour alone (WCAG). [compact] shrinks it for
/// list tiles.
class SkillVerdictBadge extends StatelessWidget {
  /// Creates a [SkillVerdictBadge].
  const SkillVerdictBadge({
    super.key,
    required this.verdict,
    this.compact = false,
  });

  /// The verdict to render.
  final SkillScanVerdict verdict;

  /// Whether to render the small list-tile variant.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.designSystem;
    final (label, color, icon) = switch (verdict) {
      SkillScanVerdict.pass => (
        l10n.skillPreviewVerdictPass,
        tokens?.success,
        AppIcons.shieldCheck,
      ),
      SkillScanVerdict.warn => (
        l10n.skillPreviewVerdictWarn,
        tokens?.textWarningPrimary,
        AppIcons.shieldAlert,
      ),
      SkillScanVerdict.quarantine => (
        l10n.skillPreviewVerdictQuarantine,
        tokens?.danger,
        AppIcons.shieldOff,
      ),
    };
    final resolved = color ?? const Color(0xFF888888);
    return Container(
      padding: compact
          ? const EdgeInsets.symmetric(horizontal: 7, vertical: 3)
          : const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: resolved.withValues(alpha: 0.12),
        borderRadius: AppRadii.brSm,
        border: Border.all(color: resolved.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compact ? 11 : 14, color: resolved),
          SizedBox(width: compact ? 5 : 8),
          Text(
            label,
            style: TextStyle(
              fontSize: compact ? 10 : 13,
              fontWeight: FontWeight.w600,
              color: tokens?.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

/// One scanner finding: a severity tag + message + location + snippet.
class SkillFindingTile extends StatelessWidget {
  /// Creates a [SkillFindingTile].
  const SkillFindingTile({super.key, required this.finding});

  /// The finding to render.
  final SkillScanFinding finding;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.designSystem;
    final isBlock = finding.verdict == SkillScanVerdict.quarantine;
    final sevColor =
        (isBlock ? tokens?.danger : tokens?.textWarningPrimary) ??
        const Color(0xFF888888);
    final sevLabel = isBlock
        ? l10n.skillSeverityBlocked
        : l10n.skillSeverityWarn;

    final location = [
      if (finding.file.isNotEmpty) finding.file,
      if (finding.line > 0) '${l10n.skillFindingLine} ${finding.line}',
    ].join('  ·  ');

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: sevColor.withValues(alpha: 0.14),
                  borderRadius: AppRadii.brXs,
                  border: Border.all(color: sevColor.withValues(alpha: 0.5)),
                ),
                child: Text(
                  sevLabel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: sevColor,
                  ),
                ),
              ),
              if (finding.ruleId.isNotEmpty) ...[
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    finding.ruleId,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: tokens?.textTertiary),
                  ),
                ),
              ],
            ],
          ),
          if (finding.message.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              finding.message,
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                color: tokens?.textSecondary,
              ),
            ),
          ],
          if (location.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              location,
              style: TextStyle(fontSize: 11, color: tokens?.textTertiary),
            ),
          ],
          if (finding.snippet.isNotEmpty) ...[
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: tokens?.bgSecondary,
                borderRadius: AppRadii.brXs,
                border: Border.all(
                  color: tokens?.borderSecondary ?? const Color(0x22000000),
                ),
              ),
              child: Text(
                finding.snippet,
                style: TextStyle(
                  fontSize: 11,
                  height: 1.4,
                  fontFamily: CcFonts.codeFamily,
                  color: tokens?.textSecondary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The explicit quarantine acknowledgement ("install anyway" / "save anyway").
class SkillQuarantineOverride extends StatelessWidget {
  /// Creates a [SkillQuarantineOverride].
  const SkillQuarantineOverride({
    super.key,
    required this.checked,
    required this.onChanged,
    required this.checkboxLabel,
  });

  /// Whether the override is ticked.
  final bool checked;

  /// Fires with the new tick state; null disables interaction.
  final ValueChanged<bool>? onChanged;

  /// The action-specific acknowledgement label ("Install anyway" / "Save
  /// anyway").
  final Widget checkboxLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.designSystem;
    final danger = tokens?.danger ?? const Color(0xFFB00020);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: danger.withValues(alpha: 0.08),
        borderRadius: AppRadii.brSm,
        border: Border.all(color: danger.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.skillQuarantineWarning,
            style: TextStyle(
              fontSize: 12,
              height: 1.5,
              color: tokens?.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          CcCheckbox(
            value: checked,
            onChanged: onChanged,
            label: checkboxLabel,
          ),
        ],
      ),
    );
  }
}

/// A small field label for dialog sections.
class SkillFieldLabel extends StatelessWidget {
  /// Creates a [SkillFieldLabel].
  const SkillFieldLabel({super.key, required this.text});

  /// The label text.
  final String text;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem;
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: tokens?.textTertiary,
      ),
    );
  }
}

/// Shows a full scan report (verdict, capabilities, findings and the
/// detached-agents notice when a quarantine was just enforced). Read-only —
/// the actions live with the caller's flow.
Future<void> showSkillScanReportDialog(
  BuildContext context, {
  required String title,
  required SkillScanReport report,
}) {
  return showCcDialog<void>(
    context: context,
    builder: (_) => _SkillScanReportDialog(title: title, report: report),
  );
}

class _SkillScanReportDialog extends StatelessWidget {
  const _SkillScanReportDialog({required this.title, required this.report});

  final String title;
  final SkillScanReport report;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.designSystem;
    return CcDialog(
      title: title,
      onClose: () => Navigator.of(context).pop(),
      maxWidth: 560,
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 460),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkillFieldLabel(text: l10n.skillPreviewVerdictLabel),
              const SizedBox(height: 6),
              Row(
                children: [
                  SkillVerdictBadge(verdict: report.verdict),
                  if (report.llmReviewed) ...[
                    const SizedBox(width: 10),
                    Text(
                      l10n.skillPreviewLlmReviewed,
                      style: TextStyle(
                        fontSize: 12,
                        color: tokens?.textTertiary,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              SkillFieldLabel(text: l10n.skillPreviewCapabilities),
              const SizedBox(height: 6),
              if (report.capabilities.isEmpty)
                Text(
                  l10n.skillPreviewNoCapabilities,
                  style: TextStyle(fontSize: 12, color: tokens?.textTertiary),
                )
              else
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final cap in report.capabilities) CcChip(label: cap),
                  ],
                ),
              if (report.requiredActionClasses.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  '${l10n.skillPreviewGuardedActions}: '
                  '${report.requiredActionClasses.join(', ')}',
                  style: TextStyle(fontSize: 11, color: tokens?.textTertiary),
                ),
              ],
              const SizedBox(height: 16),
              SkillFieldLabel(text: l10n.skillPreviewFindings),
              const SizedBox(height: 6),
              if (report.findings.isEmpty)
                Text(
                  l10n.skillPreviewNoFindings,
                  style: TextStyle(fontSize: 12, color: tokens?.textTertiary),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final f in report.findings)
                      SkillFindingTile(finding: f),
                  ],
                ),
              if (report.detachedAgents.isNotEmpty) ...[
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(AppIcons.shieldOff, size: 14, color: tokens?.danger),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.skillDetachedFromAgents(
                          report.detachedAgents.join(', '),
                        ),
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.5,
                          color: tokens?.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        CcButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.close),
        ),
      ],
    );
  }
}
