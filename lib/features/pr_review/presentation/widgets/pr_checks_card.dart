import 'package:cc_domain/features/pr_review/domain/entities/check_run.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/theme/app_fonts.dart';
import 'package:control_center/core/theme/font_settings.dart';
import 'package:control_center/features/pr_review/presentation/utils/relative_time.dart';
import 'package:control_center/features/pr_review/presentation/utils/review_status_palette.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/utils/open_url.dart';
import 'package:control_center/shared/widgets/app_timestamp.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Pr checks card.
class PrChecksCard extends StatelessWidget {
  /// PrChecksCard({super.key,.
  const PrChecksCard({super.key, required this.checks});

  /// CI check runs to display.
  final List<CheckRun> checks;

  @override
  Widget build(BuildContext context) {
    return CcCard(
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(failing: checks.where((c) => c.isFailing).length),
            const SizedBox(height: 12),
            if (checks.isEmpty)
              _EmptyState()
            else
              ...List.generate(checks.length, (i) {
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: i == checks.length - 1 ? 0 : 12,
                  ),
                  child: _CheckTile(check: checks[i]),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.failing});

  final int failing;

  @override
  Widget build(BuildContext context) {
    final ds = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Icon(AppIcons.shieldCheck, size: 16, color: ds.textTertiary),
        const SizedBox(width: 8),
        Text(
          l10n.ciCdChecks,
          style: CcTypography.body.copyWith(
            fontWeight: FontWeight.w600,
            color: ds.textPrimary,
          ),
        ),
        const Spacer(),
        if (failing > 0)
          CcBadge(
            label: l10n.checksFailingBadge(failing),
            variant: CcBadgeVariant.danger,
          ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text(
      AppLocalizations.of(context).noChecksOnCommit,
      style: CcTypography.caption.copyWith(
        color:
            (context.designSystem ?? DesignSystemTokens.light()).textTertiary,
      ),
    );
  }
}

class _CheckTile extends ConsumerWidget {
  const _CheckTile({required this.check});

  final CheckRun check;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ds = context.designSystem ?? DesignSystemTokens.light();
    final codeFont = ref.watch(codeFontFamilyProvider);
    final (icon, color, label) = _statusFor(check, context);
    final failed = check.isFailing;
    final l10n = AppLocalizations.of(context);
    final completedAt = check.completedAt;
    final subtitle = failed
        ? '${l10n.failed}${completedAt != null ? ' · ${formatRelative(completedAt)}' : ''}'
        : check.isSuccess
        ? '${l10n.checkCompletedSuccessfully}${completedAt != null ? ' · ${formatRelative(completedAt)}' : ''}'
        : label;

    Widget? subtitleWidget;
    if (subtitle.isNotEmpty) {
      subtitleWidget = Text(
        subtitle,
        style: CcTypography.caption.copyWith(color: ds.textTertiary),
      );
      // The subtitle only carries a concrete instant on a completed pass/fail;
      // a queued/running label has none to reveal.
      if (completedAt != null && (failed || check.isSuccess)) {
        subtitleWidget = AppTimestamp(
          dateTime: completedAt,
          child: subtitleWidget,
        );
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: failed
            ? const Color(0xFFCF222E).withValues(alpha: 0.06)
            : ds.bgSecondary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: failed
              ? const Color(0xFFCF222E).withValues(alpha: 0.2)
              : ds.borderSecondary,
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              check.status == CheckRunStatus.inProgress
                  ? const CcSpinner(size: 18, color: ReviewStatusColors.running)
                  : Icon(icon, size: 18, color: color),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      check.name,
                      style: CcTypography.body.copyWith(
                        fontWeight: FontWeight.w600,
                        color: ds.textPrimary,
                      ),
                    ),
                    ?subtitleWidget,
                  ],
                ),
              ),
              if (failed && check.htmlUrl.isNotEmpty)
                InkWell(
                  borderRadius: BorderRadius.circular(4),
                  onTap: () => openExternalUrl(check.htmlUrl),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                    child: Text(
                      l10n.viewLogs,
                      style: CcTypography.caption.copyWith(
                        color: const Color(0xFFCF222E),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          if (failed && check.output.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: ds.bgPrimary,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: ds.borderSecondary),
              ),
              child: SelectableText(
                check.output,
                style: AppFonts.codeStyleDynamic(
                  codeFont,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  (IconData, Color, String) _statusFor(CheckRun check, BuildContext context) {
    if (!check.isComplete) {
      return (
        AppIcons.loader,
        (context.designSystem ?? DesignSystemTokens.light()).textTertiary,
        check.status == CheckRunStatus.queued
            ? AppLocalizations.of(context).queued
            : AppLocalizations.of(context).runningLabel,
      );
    }
    if (check.isSuccess) {
      return (
        AppIcons.checkCircle2,
        const Color(0xFF2DA44E),
        AppLocalizations.of(context).successLabel,
      );
    }
    if (check.isFailing) {
      return (
        AppIcons.xCircle,
        const Color(0xFFCF222E),
        AppLocalizations.of(context).failure,
      );
    }
    return (
      AppIcons.minusCircle,
      DesignSystemPalette.gray500,
      AppLocalizations.of(context).neutral,
    );
  }
}
