import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_node_payload.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/theme/font_settings.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/pr_review/presentation/utils/review_item_palette.dart';
import 'package:control_center/features/pr_review/presentation/widgets/anchored_code_block.dart';
import 'package:control_center/features/pr_review/presentation/widgets/review_finding_attachment.dart';
import 'package:control_center/features/pr_review/presentation/widgets/review_finding_controls.dart';
import 'package:control_center/features/pr_review/presentation/widgets/review_finding_header.dart';
import 'package:control_center/features/pr_review/presentation/widgets/review_finding_status_action.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_scope.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/github_markdown_body.dart';
import 'package:control_center/shared/widgets/github_user_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// An expandable accordion item displaying a single review finding.
class ReviewAccordionItem extends ConsumerStatefulWidget {
  /// Creates a [ReviewAccordionItem].
  const ReviewAccordionItem({
    super.key,
    required this.message,
    required this.payload,
    required this.spaceId,
    required this.isSelected,
    required this.onToggleSelect,
    required this.fetchFileContent,
    required this.onFix,
    required this.onComment,
    this.prNumber,
    this.alwaysExpanded = false,
    this.anchorKey,
    this.sliver = false,
  });

  /// The message containing the review finding.
  final Message message;

  /// Parsed payload describing the finding's kind, priority and anchor.
  final ReviewNodePayload payload;

  /// Space ID this message belongs to.
  final String spaceId;

  /// Whether this finding's checkbox is ticked. Checkboxes are always on —
  /// the bulk verbs act on the ticked subset, or on every open P0–P2 finding
  /// when nothing is ticked.
  final bool isSelected;

  /// Called when the selection checkbox is toggled.
  final ValueChanged<bool> onToggleSelect;

  /// Fetches file content for the anchored code block.
  final Future<String> Function(String path)? fetchFileContent;

  /// Called when the user taps "Fix".
  final VoidCallback onFix;

  /// Called when the user taps "Comment".
  final VoidCallback onComment;

  /// PR number for inline comment posting.
  final int? prNumber;

  /// Renders the finding open with no collapse affordance at all.
  ///
  /// Distinct from the default, which is open AND collapsible: a review is read
  /// by working down the findings, so making the reader click fifty times to
  /// see fifty bodies is the wrong default. The chevron stays so anything
  /// already dealt with can be folded away.
  final bool alwaysExpanded;

  /// Attached to this finding's root so a host rail can scroll to it.
  final GlobalKey? anchorKey;

  /// Builds as a SLIVER instead of a box: the finding's row becomes a pinned
  /// header over its own body, the way the diff pins a file header over its
  /// hunks.
  ///
  /// A finding can run to a screenful — a code block, a thread, a composer —
  /// and in a flat list the row telling you WHICH finding you are reading
  /// scrolls off the top before its body ends. The row is a fixed 44px, so it
  /// can declare its extent honestly; the filter bar could not, which is why
  /// that one is not pinned.
  ///
  /// Must be placed in a [CustomScrollView]. The box form is what a test pumps
  /// and what any non-sliver host uses; both share one state and one body.
  final bool sliver;

  @override
  ConsumerState<ReviewAccordionItem> createState() =>
      _ReviewAccordionItemState();
}

class _ReviewAccordionItemState extends ConsumerState<ReviewAccordionItem> {
  bool _expanded = true;
  final _replyController = TextEditingController();

  bool get _open => widget.alwaysExpanded || _expanded;
  bool _sending = false;

  /// The status move in flight, so the pressed button is the one that spins.
  ReviewNodeStatus? _pendingStatus;

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem!;
    final payload = widget.payload;
    final msg = widget.message;
    final opacity = reviewSettledOpacity(payload.status);

    final row = _CollapsedRow(
      payload: payload,
      msg: msg,
      expanded: _expanded,
      isSelected: widget.isSelected,
      onToggleExpand: _toggleExpand,
      onToggleSelect: widget.onToggleSelect,
    );

    if (widget.sliver) {
      return SliverOpacity(
        opacity: opacity,
        sliver: SliverMainAxisGroup(
          slivers: [
            if (!widget.alwaysExpanded)
              SliverPersistentHeader(
                pinned: true,
                delegate: _FindingRowHeader(key: widget.anchorKey, child: row),
              ),
            if (_open) SliverToBoxAdapter(child: _buildExpandedBody(tokens)),
          ],
        ),
      );
    }

    return Opacity(
      key: widget.anchorKey,
      opacity: opacity,
      child: Column(
        children: [
          if (!widget.alwaysExpanded) row,
          if (_open) _buildExpandedBody(tokens),
        ],
      ),
    );
  }

  void _toggleExpand() {
    setState(() => _expanded = !_expanded);
  }

  Widget _buildExpandedBody(DesignSystemTokens tokens) {
    final msg = widget.message;
    final payload = widget.payload;

    final asyncMessages = ref.watch(spaceWideMessagesProvider(widget.spaceId));
    // Discussion messages link to this review node via `metadata['reviewNodeId']`
    // (message threading was removed — findings and their discussion live in the
    // space's standing conversation, joined by this metadata key).
    final discussion = asyncMessages.maybeWhen(
      data: (msgs) =>
          msgs.where((m) => m.metadata?['reviewNodeId'] == msg.id).toList(),
      orElse: () => const <Message>[],
    );

    final canComment =
        payload.anchor.filePath != null && payload.anchor.lineNumber != null;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: tokens.bgPrimary,
        border: Border(bottom: BorderSide(color: tokens.borderSecondary)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ReviewFindingMetaRow(msg: msg, payload: payload),
          const SizedBox(height: AppSpacing.md),
          GitHubMarkdownBody(
            data: msg.content,
            compact: true,
            codeFontFamily: ref.watch(codeFontFamilyProvider),
            onSwitchToRepo: (workspaceId, repoId) async {
              await ref
                  .read(activeWorkspaceIdProvider.notifier)
                  .setActive(workspaceId);
              await ref.read(activeRepoIdProvider.notifier).setActive(repoId);
            },
          ),
          if (payload.anchor.hasAnchor &&
              widget.fetchFileContent != null &&
              payload.anchor.filePath != null)
            AnchoredCodeBlock(
              filePath: payload.anchor.filePath!,
              lineNumber: payload.anchor.lineNumber ?? 1,
              lineEnd: payload.anchor.lineEnd,
              fetchFileContent: widget.fetchFileContent!,
              prNumber: widget.prNumber,
            ),
          if (payload.fixDiff != null) ...[
            const SizedBox(height: AppSpacing.sm),
            ReviewFindingAttachment(
              title: AppLocalizations.of(context).reviewProposedFix,
              body: payload.fixDiff!,
              mono: true,
              // A proposed fix is a unified patch, so it reads as one whatever
              // language the file is in: the +/- lines carry the meaning.
              languageId: 'diff',
            ),
          ],
          if (payload.aiPrompt != null) ...[
            const SizedBox(height: AppSpacing.sm),
            ReviewFindingAttachment(
              title: AppLocalizations.of(context).reviewAiAgentPrompt,
              // The guard rides with the prompt rather than being displayed
              // beside it: what gets copied is what gets pasted, and a warning
              // left behind on screen protects nobody.
              body:
                  '$kAiAgentPromptGuardPreamble\n\n'
                  '${payload.aiPrompt}',
              mono: false,
              copyLabel: AppLocalizations.of(context).reviewCopyAiPrompt,
            ),
          ],
          if (payload.confirmedBy.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            _SectionLabel(text: AppLocalizations.of(context).confirmedBy),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                for (final id in payload.confirmedBy)
                  CcBadge(label: '@$id', variant: CcBadgeVariant.brand),
              ],
            ),
          ],
          if (discussion.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            _SectionLabel(text: AppLocalizations.of(context).discussion),
            const SizedBox(height: AppSpacing.xs),
            for (final reply in discussion) _ThreadReply(message: reply),
          ],
          // The footer is a GROUP, not a second box: one rule separates reading
          // the finding from acting on it, and the composer and the verbs sit
          // on the same left edge underneath it. They used to be two floating
          // bordered strips that lined up with neither the body nor each other.
          const SizedBox(height: AppSpacing.md),
          const CcDivider(),
          const SizedBox(height: AppSpacing.md),
          ReviewReplyComposer(
            controller: _replyController,
            sending: _sending,
            onSend: _sendReply,
          ),
          const SizedBox(height: AppSpacing.sm),
          ReviewFindingActionBar(
            status: payload.status,
            onSetStatus: _pendingStatus != null ? null : _setStatus,
            pending: _pendingStatus,
            canComment: canComment,
            onFix: widget.onFix,
            onComment: widget.onComment,
          ),
        ],
      ),
    );
  }

  /// Moves the finding. The mechanism (and its undo bookkeeping) lives in
  /// `review_finding_status_action.dart`; this only owns the pending flag.
  Future<void> _setStatus(ReviewNodeStatus status) async {
    setState(() => _pendingStatus = status);
    try {
      await applyReviewFindingStatus(
        ref,
        context,
        spaceId: widget.spaceId,
        nodeMessageId: widget.message.id,
        status: status,
      );
    } finally {
      if (mounted) {
        setState(() => _pendingStatus = null);
      }
    }
  }

  Future<void> _sendReply() async {
    final text = _replyController.text.trim();
    if (text.isEmpty) {
      return;
    }
    setState(() => _sending = true);
    try {
      await ref
          .read(messagingRepositoryProvider)
          .sendMessage(
            workspaceId: ref.requireWorkspaceId(),
            spaceId: widget.spaceId,
            content: text,
            senderId: 'user',
            senderType: 'user',
            metadata: {'reviewNodeId': widget.message.id},
          );
      _replyController.clear();
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }
}

/// The review tab's variant of the shared finding header: the same row, plus
/// the selection checkbox the bulk verbs read and the author's avatar.
class _CollapsedRow extends ConsumerWidget {
  const _CollapsedRow({
    required this.payload,
    required this.msg,
    required this.expanded,
    required this.isSelected,
    required this.onToggleExpand,
    required this.onToggleSelect,
  });

  final ReviewNodePayload payload;
  final Message msg;
  final bool expanded;
  final bool isSelected;
  final VoidCallback onToggleExpand;
  final ValueChanged<bool> onToggleSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agentAsync = ref.watch(agentDetailProvider(msg.senderId));
    final agentName = agentAsync.value?.name ?? msg.senderId;

    return ReviewFindingHeader(
      payload: payload,
      summary: reviewFindingSummary(msg.content),
      expanded: expanded,
      onToggle: onToggleExpand,
      leading: CcCheckbox(
        value: isSelected,
        onChanged: (_) => onToggleSelect(!isSelected),
      ),
      trailing: GitHubUserAvatar(
        login: agentName,
        size: 18,
        showHoverCard: false,
      ),
    );
  }
}

/// The quiet heading of a block inside the finding's body — a group label, not
/// a second card.
class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem!;
    return Text(
      text.toUpperCase(),
      style: CcTypography.label.copyWith(color: tokens.textTertiary),
    );
  }
}

class _ThreadReply extends ConsumerWidget {
  const _ThreadReply({required this.message});

  final Message message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.designSystem!;
    final agent = ref.watch(agentDetailProvider(message.senderId)).value;
    final agentName = agent?.name ?? message.senderId;
    // A left rule and an indent, not a filled rounded slab: a reply is a nested
    // block of the same document, and boxing each one turned a short thread
    // into a stack of grey pills.
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Container(
        padding: const EdgeInsets.only(left: AppSpacing.md),
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: tokens.borderSecondary, width: 2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GitHubUserAvatar(
                  login: agentName,
                  size: 14,
                  showHoverCard: false,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  agentName,
                  style: CcTypography.caption.copyWith(
                    color: tokens.textTertiary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              message.content,
              style: CcTypography.bodySm.copyWith(color: tokens.textPrimary),
            ),
          ],
        ),
      ),
    );
  }
}

class _FindingRowHeader extends SliverPersistentHeaderDelegate {
  const _FindingRowHeader({required this.child, this.key});

  final Widget child;

  /// Attached to the built row so a host can scroll this finding into view.
  final GlobalKey? key;

  @override
  double get minExtent => kReviewFindingHeaderExtent;

  @override
  double get maxExtent => kReviewFindingHeaderExtent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => SizedBox(key: key, height: kReviewFindingHeaderExtent, child: child);

  @override
  bool shouldRebuild(_FindingRowHeader old) =>
      old.child != child || old.key != key;
}
