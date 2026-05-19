import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/features/pr_review/domain/usecases/classify_pr_inbox_use_case.dart';
import 'package:cc_remote/app_icons.dart';
import 'package:cc_remote/format.dart';
import 'package:cc_remote/pr_providers.dart';
import 'package:cc_remote/providers.dart';
import 'package:cc_remote/widgets/pr_row.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
    final pending =
        ref.watch(workspacePendingConfirmationsProvider).value ?? const [];
    final inbox = ref.watch(prInboxProvider);
    final logins = ref.watch(viewerLoginsProvider);

    return ColoredBox(
      color: t.canvas,
      child: inbox.when(
        loading: () => const Center(child: CcSpinner(size: 24)),
        error: (e, _) => CcEmptyState(
          icon: AppIcons.triangleAlert,
          message: "Couldn't load your inbox",
          description: e.toString(),
        ),
        data: (data) {
          final sections = [
            for (final section in PrInboxSection.values)
              if (data.of(section).isNotEmpty) section,
          ];
          if (pending.isEmpty && sections.isEmpty) {
            return CcEmptyState(
              icon: AppIcons.inbox,
              message: 'You’re all caught up',
              description: (logins.value ?? const {}).isEmpty
                  ? 'No forge account is connected on the server, so pull '
                        'requests can’t be attributed to you yet.'
                  : 'Nothing is blocked and no pull request is waiting on '
                        'you.',
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            children: [
              if (pending.isNotEmpty) ...[
                _SectionHeader(
                  label: 'Blocked',
                  count: pending.length,
                  icon: AppIcons.bot,
                  urgent: true,
                ),
                const SizedBox(height: 8),
                for (final request in pending)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    // Keyed by request id: the list reorders as approvals land
                    // and clear, and an unkeyed stateful card would hand its
                    // in-flight `_acting`/error state to whichever request
                    // slid into that slot.
                    child: _ApprovalCard(
                      key: ValueKey(request.id),
                      request: request,
                    ),
                  ),
                const SizedBox(height: 16),
              ],
              for (final section in sections) ...[
                _SectionHeader(
                  label: _sectionLabel(section),
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
          );
        },
      ),
    );
  }

  static String _sectionLabel(PrInboxSection section) => switch (section) {
    PrInboxSection.needsYourReview => 'Needs your review',
    PrInboxSection.returnedToYou => 'Returned to you',
    PrInboxSection.approved => 'Approved and ready',
    PrInboxSection.drafts => 'Your drafts',
    PrInboxSection.waitingForReviewers => 'Waiting for reviewers',
    PrInboxSection.mergingAndMerged => 'Merging and recently merged',
    PrInboxSection.waitingForAuthor => 'Waiting for author',
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

/// One blocked agent, with the two answers that unblock it.
///
/// The verbatim command is shown, not summarised: approving a destructive
/// action you have only seen paraphrased is not approval. Both buttons are
/// full-size touch targets — this is the one control on the phone where a
/// mis-tap has a side effect on someone's repository.
class _ApprovalCard extends ConsumerStatefulWidget {
  const _ApprovalCard({super.key, required this.request});

  final ConfirmationRequestDto request;

  @override
  ConsumerState<_ApprovalCard> createState() => _ApprovalCardState();
}

class _ApprovalCardState extends ConsumerState<_ApprovalCard> {
  bool _acting = false;
  String? _error;

  Future<void> _respond({required bool approved}) async {
    final client = ref.read(rpcClientProvider).value;
    if (client == null || _acting) {
      return;
    }
    setState(() {
      _acting = true;
      _error = null;
    });
    try {
      await RemoteConfirmationRepository(
        client,
      ).respond(widget.request.id, approved: approved);
      // No success state to render: the entry leaves `watchPending` on the
      // server's next snapshot, so the card simply goes away.
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '$e';
          _acting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final request = widget.request;
    final destructive = request.severity == 'destructive';
    final since = DateTime.tryParse(request.createdAt);

    return CcCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                destructive ? AppIcons.triangleAlert : AppIcons.bot,
                size: 16,
                color: destructive ? t.textErrorPrimary : t.textWarningPrimary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  request.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: t.textPrimary,
                  ),
                ),
              ),
              if (since != null)
                Text(
                  'waiting ${shortAgo(since)}',
                  style: TextStyle(fontSize: 11, color: t.textTertiary),
                ),
            ],
          ),
          if (request.detail.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              request.detail,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: t.textSecondary,
              ),
            ),
          ],
          if ((request.command ?? '').isNotEmpty) ...[
            const SizedBox(height: 10),
            DecoratedBox(
              decoration: BoxDecoration(
                color: t.bgTertiary,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Text(
                  request.command!,
                  style: CcFonts.code(
                    textStyle: TextStyle(
                      fontSize: 12,
                      height: 1.45,
                      color: t.textPrimary,
                    ),
                  ),
                ),
              ),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(fontSize: 12, color: t.textErrorPrimary),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: CcButton(
                  variant: CcButtonVariant.secondary,
                  onPressed: _acting ? null : () => _respond(approved: false),
                  child: const Text('Deny'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CcButton(
                  variant: destructive
                      ? CcButtonVariant.destructive
                      : CcButtonVariant.primary,
                  loading: _acting,
                  onPressed: _acting ? null : () => _respond(approved: true),
                  child: const Text('Approve'),
                ),
              ),
            ],
          ),
          if (request.spaceId.isNotEmpty) ...[
            const SizedBox(height: 6),
            CcButton(
              fullWidth: true,
              variant: CcButtonVariant.ghost,
              size: CcButtonSize.sm,
              icon: AppIcons.messageCircle,
              onPressed: () => context.push('/spaces/${request.spaceId}'),
              child: const Text('Open the conversation'),
            ),
          ],
        ],
      ),
    );
  }
}
