import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/analytics/domain/entities/workspace_health.dart';
import 'package:control_center/features/analytics/presentation/widgets/sections/analytics_shared.dart';
import 'package:control_center/features/analytics/providers/analytics_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// A card showing workspace health metrics including pulse score and
/// sub-metrics for responsiveness, quality, and throughput.
class WorkspacePulseCard extends ConsumerWidget {
/// Creates the workspace pulse card widget.
  const WorkspacePulseCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final healths = ref.watch(allWorkspaceHealthProvider);
    final l10n = AppLocalizations.of(context);
    return SectionCard(
      label: l10n.workspacePulse,
      child: healths.when(
        loading: () => const SizedBox(
          height: 140,
          child: Center(child: CcSpinner()),
        ),
        error: (e, _) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Center(child: Text(l10n.failedWithError('$e'))),
        ),
        data: (list) {
          if (list.isEmpty) {
            return const SectionEmpty(
              icon: LucideIcons.activity,
              message: 'No workspaces tracked yet',
            );
          }
          return Column(
            children: [
              for (var i = 0; i < list.length; i++) ...[
                _WorkspacePulseRow(health: list[i]),
                if (i < list.length - 1) const SizedBox(height: 10),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _WorkspacePulseRow extends StatelessWidget {
  const _WorkspacePulseRow({required this.health});
  final WorkspaceHealth health;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final fg = tokens.textPrimary;
    final muted = tokens.textTertiary;
    final color = _healthColor(health.score, tokens);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                health.workspaceName,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
              ),
            ),
            Text(
              health.score.round().toString(),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: (health.score / 100).clamp(0, 1),
            minHeight: 6,
            backgroundColor: tokens.bgTertiary,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 10,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _SubMetric(
              label: l10n.activity,
              value: health.activityScore,
              color: color,
            ),
            _SubMetric(
              label: l10n.throughput,
              value: health.throughputScore,
              color: color,
            ),
            _SubMetric(
              label: l10n.reviewsLabel,
              value: health.reviewHealthScore,
              color: color,
            ),
            _SubMetric(
              label: l10n.success,
              value: health.successRateScore,
              color: color,
            ),
            Text(
              '${health.openPRs} open · ${health.prsMergedThisWeek} merged',
              style: TextStyle(fontSize: 12, height: 1.4, color: muted),
            ),
          ],
        ),
      ],
    );
  }
}

class _SubMetric extends StatelessWidget {
  const _SubMetric({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final muted = tokens.textTertiary;
    final filled = (value / 25).round().clamp(0, 4);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: List.generate(4, (i) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0.8),
              child: Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: i < filled ? color : tokens.bgTertiary,
                  shape: BoxShape.circle,
                ),
              ),
            );
          }),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(fontSize: 12, height: 1.4, color: muted),
        ),
      ],
    );
  }
}

Color _healthColor(double score, DesignSystemTokens tokens) {
  if (score >= 70) {
    return tokens.fgSuccessPrimary;
  }
  if (score >= 40) {
    return tokens.fgWarningPrimary;
  }
  return tokens.fgErrorPrimary;
}
