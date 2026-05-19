import 'package:control_center/core/theme/app_fonts.dart';
import 'package:control_center/core/theme/design_system_palette.dart';
import 'package:control_center/core/theme/font_settings.dart';
import 'package:control_center/features/pr_review/domain/entities/check_run.dart';
import 'package:control_center/features/pr_review/presentation/utils/relative_time.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

/// Pr checks card.
class PrChecksCard extends StatelessWidget {
  /// PrChecksCard({super.key,.
  const PrChecksCard({super.key, required this.checks});

  /// CI check runs to display.
  final List<CheckRun> checks;

  @override
  Widget build(BuildContext context) {
    return FCard.raw(
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
    return Row(
      children: [
        Icon(
          LucideIcons.shieldCheck,
          size: 16,
          color: context.theme.colors.mutedForeground,
        ),
        const SizedBox(width: 8),
        Text(
          'CI/CD Checks',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: context.theme.colors.foreground,
          ),
        ),
        const Spacer(),
        if (failing > 0)
          FBadge(
            variant: FBadgeVariant.destructive,
            child: Text('$failing failing'),
          ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text(
      'No checks have run on this commit.',
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: context.theme.colors.mutedForeground,
      ),
    );
  }
}

class _CheckTile extends ConsumerWidget {
  const _CheckTile({required this.check});

  final CheckRun check;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final codeFont = ref.watch(codeFontFamilyProvider);
    final (icon, color, label) = _statusFor(check, context);
    final failed = check.isFailing;
    final completedAt = check.completedAt;
    final subtitle = failed
        ? 'Failed${completedAt != null ? ' · ${formatRelative(completedAt)}' : ''}'
        : check.isSuccess
        ? 'Completed successfully${completedAt != null ? ' · ${formatRelative(completedAt)}' : ''}'
        : label;

    return Container(
      decoration: BoxDecoration(
        color: failed
            ? const Color(0xFFCF222E).withValues(alpha: 0.06)
            : context.theme.colors.secondary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: failed
              ? const Color(0xFFCF222E).withValues(alpha: 0.2)
              : context.theme.colors.border,
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      check.name,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: context.theme.colors.foreground,
                      ),
                    ),
                    if (subtitle.isNotEmpty)
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: context.theme.colors.mutedForeground,
                        ),
                      ),
                  ],
                ),
              ),
              if (failed && check.htmlUrl.isNotEmpty)
                InkWell(
                  borderRadius: BorderRadius.circular(4),
                  onTap: () => launchUrl(Uri.parse(check.htmlUrl)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                    child: Text(
                      'View logs',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
                color: context.theme.colors.background,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: context.theme.colors.border),
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
        LucideIcons.loader,
        context.theme.colors.mutedForeground,
        check.status == CheckRunStatus.queued ? AppLocalizations.of(context).queued : AppLocalizations.of(context).runningLabel,
      );
    }
    if (check.isSuccess) {
      return (LucideIcons.checkCircle2, const Color(0xFF2DA44E), AppLocalizations.of(context).successLabel);
    }
    if (check.isFailing) {
      return (LucideIcons.xCircle, const Color(0xFFCF222E), AppLocalizations.of(context).failure);
    }
    return (LucideIcons.minusCircle, DesignSystemPalette.gray500, AppLocalizations.of(context).neutral);
  }
}

