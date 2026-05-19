import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pr_review/providers/pr_context_rail_provider.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/pr_title_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Right-rail pre-loading context panel shown on the PR detail AI-review tab.
///
/// Surfaces author's recent PRs, related channel threads, and related
/// newsfeed articles without any extra API calls.
class PrContextRail extends ConsumerWidget {
  /// Creates a [PrContextRail].
  const PrContextRail({super.key, required this.prNumber});

  /// PR number for data lookups.
  final int prNumber;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncCtx = ref.watch(prContextRailProvider(prNumber));
    final pr = ref.watch(prDetailProvider(prNumber)).value;
    final authorLogin = pr?.author?.login ?? '—';

    return asyncCtx.when(
      loading: () =>
          const _RailShell(child: Center(child: CcSpinner())),
      error: (e, _) => const SizedBox.shrink(),
      data: (ctx) => _RailShell(
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            if (ctx.authorRecentPrs.isNotEmpty) ...[
              _SectionHeader(
                icon: AppIcons.gitPullRequest,
                label: 'Other PRs by $authorLogin',
              ),
              const SizedBox(height: 4),
              for (final p in ctx.authorRecentPrs) _PrChip(pr: p),
              const SizedBox(height: 12),
            ],
            if (ctx.relatedMessages.isNotEmpty) ...[
              const _SectionHeader(
                icon: AppIcons.messageSquare,
                label: 'Related threads',
              ),
              const SizedBox(height: 4),
              for (final r in ctx.relatedMessages)
                _MessageChip(
                  channel: r.channel.name,
                  content: r.message.content,
                ),
              const SizedBox(height: 12),
            ],
            if (ctx.authorRecentPrs.isEmpty && ctx.relatedMessages.isEmpty)
              _EmptyState(),
          ],
        ),
      ),
    );
  }
}

class _RailShell extends StatelessWidget {
  const _RailShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ds = context.designSystem ?? DesignSystemTokens.light();
    return Container(
      width: 220,
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: ds.borderSecondary)),
      ),
      child: child,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final ds = context.designSystem ?? DesignSystemTokens.light();
    return Row(
      children: [
        Icon(icon, size: 11, color: ds.textTertiary),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: ds.textTertiary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _PrChip extends StatelessWidget {
  const _PrChip({required this.pr});

  final PullRequest pr;

  @override
  Widget build(BuildContext context) {
    final ds = context.designSystem ?? DesignSystemTokens.light();
    final style = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: ds.textPrimary);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(
              AppIcons.gitPullRequest,
              size: 11,
              color: ds.textTertiary,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: PrTitleText(
              pr.title,
              style: style,
              leading: [TextSpan(text: '#${pr.number} ', style: style)],
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageChip extends StatelessWidget {
  const _MessageChip({required this.channel, required this.content});

  final String channel;
  final String content;

  @override
  Widget build(BuildContext context) {
    final ds = context.designSystem ?? DesignSystemTokens.light();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '#$channel',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: ds.textTertiary,
            ),
          ),
          Text(
            content,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: ds.textPrimary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Text(
        'No related context found.',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: (context.designSystem ?? DesignSystemTokens.light())
              .textTertiary,
          fontStyle: FontStyle.italic,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
