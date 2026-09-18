import 'package:cc_domain/features/pr_review/domain/usecases/classify_pr_inbox_use_case.dart';
import 'package:cc_remote/app_icons.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/pr_providers.dart';
import 'package:cc_remote/providers.dart';
import 'package:cc_remote/widgets/inbox/approval_card.dart';
import 'package:cc_remote/widgets/pr/pr_notices.dart';
import 'package:cc_remote/widgets/pr_row.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Inbox tab: everything waiting on the operator, in one scroll.
///
/// Two lanes, in strict order. **Blocked agents first** — an agent frozen
/// mid-run is the only thing on this screen where the cost of not looking
/// keeps growing, and it is answerable in one tap from a phone. **Then the
/// classified PR sections**, using the same [ClassifyPrInboxUseCase] the
/// desktop runs over the same server feed, so the phone and the desk never
/// disagree about what needs reviewing.
///
/// The strict inclusion rule is the whole design: a section that shows things
/// which do not need the operator turns the inbox into a second notification
/// firehose, and then it gets ignored. Sections with nothing in them are not
/// rendered at all.
class InboxScreen extends ConsumerWidget {
  /// Creates an [InboxScreen].
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final pending =
        ref.watch(workspacePendingConfirmationsProvider).value ?? const [];
    final inbox = ref.watch(prInboxProvider);
    final logins = ref.watch(viewerLoginsProvider);
    final inaccessible =
        ref.watch(openPrsProvider).value?.inaccessibleRepos ?? const [];
    final suspended = [
      for (final repo in inaccessible)
        if (repo.isInstallationSuspended) repo,
    ];

    return ColoredBox(
      color: t.canvas,
      child: inbox.when(
        loading: () => const Center(child: CcSpinner(size: 24)),
        error: (e, _) => CcEmptyState(
          icon: AppIcons.triangleAlert,
          message: l10n.inboxLoadFailed,
          description: e.toString(),
        ),
        data: (data) {
          final sections = [
            for (final section in PrInboxSection.values)
              if (data.of(section).isNotEmpty) section,
          ];
          if (pending.isEmpty && sections.isEmpty) {
            final names = [
              for (final repo in suspended)
                if (repo.repoFullName.isNotEmpty) repo.repoFullName,
            ].join(', ');
            return CcEmptyState(
              icon: suspended.isNotEmpty
                  ? AppIcons.triangleAlert
                  : AppIcons.inbox,
              message: suspended.isNotEmpty
                  ? l10n.installationSuspendedTitle
                  : l10n.allCaughtUp,
              description: suspended.isNotEmpty
                  ? l10n.installationSuspendedBody(names)
                  : (logins.value ?? const {}).isEmpty
                  ? l10n.inboxNoForgeAccount
                  : l10n.inboxNothingWaiting,
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              InaccessibleReposNotice(repos: inaccessible),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  children: [
                    if (pending.isNotEmpty) ...[
                      _SectionHeader(
                        label: l10n.blocked,
                        count: pending.length,
                        icon: AppIcons.bot,
                        urgent: true,
                      ),
                      const SizedBox(height: 8),
                      for (final request in pending)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: ApprovalCard(
                            key: ValueKey(request.id),
                            request: request,
                          ),
                        ),
                      const SizedBox(height: 16),
                    ],
                    for (final section in sections) ...[
                      _SectionHeader(
                        label: _sectionLabel(l10n, section),
                        count: data.of(section).length,
                        icon: _sectionIcon(section),
                        urgent:
                            section == PrInboxSection.needsYourReview ||
                            section == PrInboxSection.returnedToYou,
                      ),
                      const SizedBox(height: 8),
                      for (final item in data.of(section))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: PrRow(item: item),
                        ),
                      const SizedBox(height: 16),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static String _sectionLabel(AppLocalizations l10n, PrInboxSection section) =>
      switch (section) {
        PrInboxSection.needsYourReview => l10n.sectionNeedsYourReview,
        PrInboxSection.returnedToYou => l10n.sectionReturnedToYou,
        PrInboxSection.approved => l10n.sectionApprovedAndReady,
        PrInboxSection.drafts => l10n.sectionYourDrafts,
        PrInboxSection.waitingForReviewers => l10n.sectionWaitingForReviewers,
        PrInboxSection.mergingAndMerged => l10n.sectionMergingAndMerged,
        PrInboxSection.waitingForAuthor => l10n.sectionWaitingForAuthor,
      };

  static IconData _sectionIcon(PrInboxSection section) => switch (section) {
    PrInboxSection.needsYourReview => AppIcons.eye,
    PrInboxSection.returnedToYou => AppIcons.circleX,
    PrInboxSection.approved => AppIcons.circleCheck,
    PrInboxSection.drafts => AppIcons.gitPullRequestDraft,
    PrInboxSection.waitingForReviewers => AppIcons.clock,
    PrInboxSection.mergingAndMerged => AppIcons.gitMerge,
    PrInboxSection.waitingForAuthor => AppIcons.users,
  };
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.label,
    required this.count,
    required this.icon,
    this.urgent = false,
  });

  final String label;
  final int count;
  final IconData icon;
  final bool urgent;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final color = urgent ? t.textPrimary : t.textSecondary;
    return Row(
      children: [
        Icon(icon, size: 15, color: urgent ? t.accent : t.fgTertiary),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        const SizedBox(width: 6),
        Text('$count', style: TextStyle(fontSize: 12, color: t.textTertiary)),
      ],
    );
  }
}
