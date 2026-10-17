import 'package:cc_domain/core/domain/ports/run_credential_gate_port.dart';
import 'package:cc_domain/features/pr_review/domain/usecases/classify_pr_inbox_use_case.dart';
import 'package:cc_domain/features/ticketing/domain/sync/ticket_sync_log_entry.dart';
import 'package:cc_remote/app_icons.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/pr_providers.dart';
import 'package:cc_remote/providers.dart';
import 'package:cc_remote/requests_activity_providers.dart';
import 'package:cc_remote/widgets/inbox/inbox_request_lanes.dart';
import 'package:cc_remote/widgets/inbox/inbox_section_header.dart';
import 'package:cc_remote/widgets/pr/pr_notices.dart';
import 'package:cc_remote/widgets/pr_row.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Urgent requests load independently of the classified pull-request lane.
class InboxScreen extends ConsumerWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final approvals = ref.watch(workspacePendingConfirmationsProvider);
    final questions = ref.watch(pendingQuestionsProvider);
    final credentials = ref.watch(workspaceCredentialBlocksProvider);
    final sync = ref.watch(failedTicketSyncProvider);
    final inbox = ref.watch(prInboxProvider);
    final inaccessible =
        ref.watch(openPrsProvider).value?.inaccessibleRepos ?? const [];
    final approvalItems = approvals.value ?? const [];
    final questionItems = questions.value ?? const <PendingQuestion>[];
    final credentialItems =
        credentials.value ?? const <RunCredentialBlockDto>[];
    final syncItems = sync.value ?? const <TicketSyncLogEntry>[];
    final sections = inbox.value == null
        ? const <PrInboxSection>[]
        : [
            for (final section in PrInboxSection.values)
              if (inbox.value!.of(section).isNotEmpty) section,
          ];
    final loading =
        approvals.isLoading ||
        questions.isLoading ||
        credentials.isLoading ||
        sync.isLoading;
    final errors = [
      if (approvals.hasError)
        '${l10n.agentApprovalRequired}: ${approvals.error}',
      if (questions.hasError) '${l10n.agentQuestionHeader}: ${questions.error}',
      if (credentials.hasError)
        '${l10n.inboxCredentialsBlocked}: ${credentials.error}',
      if (sync.hasError) '${l10n.inboxSyncFailures}: ${sync.error}',
    ];
    return ColoredBox(
      color: t.canvas,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        children: [
          if (loading) const Center(child: CcSpinner(size: 24)),
          for (final error in errors)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: CcEmptyState(
                icon: AppIcons.triangleAlert,
                message: l10n.inboxLoadFailed,
                description: error,
              ),
            ),
          InboxRequestLanes(
            approvals: approvalItems,
            questions: questionItems,
            credentials: credentialItems,
            syncFailures: syncItems,
          ),
          if (inbox.isLoading)
            const Center(child: CcSpinner(size: 24))
          else if (inbox.hasError)
            CcEmptyState(
              icon: AppIcons.triangleAlert,
              message: l10n.inboxLoadFailed,
              description: '${inbox.error}',
            )
          else ...[
            if (inaccessible.isNotEmpty)
              InaccessibleReposNotice(repos: inaccessible),
            for (final section in sections) ...[
              InboxSectionHeader(
                label: _sectionLabel(l10n, section),
                count: inbox.value!.of(section).length,
                icon: _sectionIcon(section),
                urgent:
                    section == PrInboxSection.needsYourReview ||
                    section == PrInboxSection.returnedToYou,
              ),
              const SizedBox(height: 8),
              for (final item in inbox.value!.of(section))
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: PrRow(item: item),
                ),
              const SizedBox(height: 16),
            ],
          ],
          if (!loading &&
              errors.isEmpty &&
              !inbox.isLoading &&
              !inbox.hasError &&
              approvalItems.isEmpty &&
              questionItems.isEmpty &&
              credentialItems.isEmpty &&
              syncItems.isEmpty &&
              sections.isEmpty)
            CcEmptyState(
              icon: AppIcons.inbox,
              message: l10n.allCaughtUp,
              description: l10n.inboxNothingWaiting,
            ),
        ],
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
