import 'package:cc_domain/core/domain/entities/channel_message.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_node_payload.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/theme/font_settings.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/auth/providers/auth_providers.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/pr_review/presentation/utils/review_item_palette.dart';
import 'package:control_center/features/pr_review/presentation/widgets/anchored_code_block.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/github_markdown_body.dart';
import 'package:control_center/shared/widgets/github_user_avatar.dart';
import 'package:control_center/shared/widgets/markdown/markdown_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// An expandable accordion item displaying a single review finding.
class ReviewAccordionItem extends ConsumerStatefulWidget {
  /// Creates a [ReviewAccordionItem].
  const ReviewAccordionItem({
    super.key,
    required this.message,
    required this.payload,
    required this.channelId,
    required this.isSelected,
    required this.selectionMode,
    required this.onToggleSelect,
    required this.fetchFileContent,
    required this.onFix,
    required this.onComment,
    this.prNumber,
  });

  /// The message containing the review finding.
  final ChannelMessage message;

  /// Parsed payload describing the finding's kind, priority, and anchor.
  final ReviewNodePayload payload;

  /// Channel ID this message belongs to.
  final String channelId;

  /// Whether this item is selected in batch mode.
  final bool isSelected;

  /// Whether selection mode is active.
  final bool selectionMode;

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

  @override
  ConsumerState<ReviewAccordionItem> createState() =>
      _ReviewAccordionItemState();
}

class _ReviewAccordionItemState extends ConsumerState<ReviewAccordionItem> {
  bool _expanded = false;
  final _replyController = TextEditingController();
  bool _sending = false;

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
    final decor = reviewItemDecor(context, payload.kind, payload.priority);
    final isDismissed = payload.status == ReviewNodeStatus.dismissed;
    final isResolved = payload.status == ReviewNodeStatus.resolved;
    final opacity = isDismissed
        ? 0.4
        : isResolved
        ? 0.65
        : 1.0;

    return Opacity(
      opacity: opacity,
      child: Column(
        children: [
          _CollapsedRow(
            decor: decor,
            payload: payload,
            msg: msg,
            channelId: widget.channelId,
            expanded: _expanded,
            selectionMode: widget.selectionMode,
            isSelected: widget.isSelected,
            onToggleExpand: _toggleExpand,
            onToggleSelect: widget.onToggleSelect,
          ),
          if (_expanded) _buildExpandedBody(tokens),
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

    final asyncMessages = ref.watch(channelMessagesProvider(widget.channelId));
    final thread = asyncMessages.maybeWhen(
      data: (msgs) => msgs.where((m) => m.parentMessageId == msg.id).toList(),
      orElse: () => const <ChannelMessage>[],
    );

    final canComment =
        payload.anchor.filePath != null && payload.anchor.lineNumber != null;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: BoxDecoration(
        color: tokens.bgPrimary,
        border: Border(bottom: BorderSide(color: tokens.borderSecondary)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MetaRow(msg: msg, payload: payload),
          const SizedBox(height: 12),
          GitHubMarkdownBody(
            data: msg.content,
            githubToken: ref.watch(githubAuthTokenProvider),
            styleSheet: githubMarkdownStyleSheet(
              context,
              compact: true,
              codeFontFamily: ref.watch(codeFontFamilyProvider),
            ),
            builders: {
              'code': InlineCodeBuilder(),
              'pre': CodeBlockBuilder(
                codeFontFamily: ref.watch(codeFontFamilyProvider),
              ),
            },
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
          if (payload.confirmedBy.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context).confirmedBy,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: tokens.textTertiary),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (final id in payload.confirmedBy) _AgentChip(id: id),
              ],
            ),
          ],
          if (thread.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context).threadLabel,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: tokens.textTertiary),
            ),
            const SizedBox(height: 4),
            for (final reply in thread) _ThreadReply(message: reply),
          ],
          const SizedBox(height: 12),
          _Composer(
            controller: _replyController,
            sending: _sending,
            onSend: _sendReply,
          ),
          const SizedBox(height: 8),
          _ActionBar(
            canComment: canComment,
            onFix: widget.onFix,
            onComment: widget.onComment,
          ),
        ],
      ),
    );
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
            channelId: widget.channelId,
            content: text,
            senderId: 'user',
            senderType: 'user',
            parentMessageId: widget.message.id,
          );
      _replyController.clear();
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }
}

class _CollapsedRow extends ConsumerWidget {
  const _CollapsedRow({
    required this.decor,
    required this.payload,
    required this.msg,
    required this.channelId,
    required this.expanded,
    required this.selectionMode,
    required this.isSelected,
    required this.onToggleExpand,
    required this.onToggleSelect,
  });

  final ReviewItemDecor decor;
  final ReviewNodePayload payload;
  final ChannelMessage msg;
  final String channelId;
  final bool expanded;
  final bool selectionMode;
  final bool isSelected;
  final VoidCallback onToggleExpand;
  final ValueChanged<bool> onToggleSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.designSystem!;
    final agentAsync = ref.watch(agentDetailProvider(msg.senderId));
    final agentName = agentAsync.value?.name ?? msg.senderId;
    final statusLabel = switch (payload.status) {
      ReviewNodeStatus.open => AppLocalizations.of(context).openStatus,
      ReviewNodeStatus.consensusReady => AppLocalizations.of(context).consensus,
      ReviewNodeStatus.resolved => AppLocalizations.of(context).resolved,
      ReviewNodeStatus.dismissed => AppLocalizations.of(context).dismissed,
    };
    final statusColor = reviewStatusRingColor(payload.status, context);
    final lineInfo = payload.anchor.filePath != null
        ? '${payload.anchor.filePath}${payload.anchor.lineNumber != null ? ':${payload.anchor.lineNumber}' : ''}'
        : null;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onToggleExpand,
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: expanded
              ? tokens.bgSecondary.withValues(alpha: 0.5)
              : tokens.bgPrimary,
          border: Border(bottom: BorderSide(color: tokens.borderSecondary)),
        ),
        child: Row(
          children: [
            if (selectionMode)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: CcCheckbox(
                  value: isSelected,
                  onChanged: (_) => onToggleSelect(!isSelected),
                ),
              ),
            Icon(decor.icon, size: 14, color: decor.accent),
            const SizedBox(width: 6),
            Text(
              decor.label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: decor.accent,
                fontWeight: FontWeight.w700,
                fontSize: 10,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '· ${payload.priority.name.toUpperCase()}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: reviewPriorityColor(payload.priority, context),
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '· ${(payload.confidence * 100).round()}%',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: tokens.textTertiary,
                fontSize: 10,
              ),
            ),
            if (lineInfo != null) ...[
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  '· $lineInfo',
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: tokens.textTertiary,
                    fontSize: 10,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                statusLabel,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontSize: 9,
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Spacer(),
            GitHubUserAvatar(login: agentName, size: 18, showHoverCard: false),
            const SizedBox(width: 4),
            Icon(
              expanded ? AppIcons.chevronUp : AppIcons.chevronDown,
              size: 14,
              color: tokens.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaRow extends ConsumerWidget {
  const _MetaRow({required this.msg, required this.payload});

  final ChannelMessage msg;
  final ReviewNodePayload payload;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.designSystem!;
    final agent = ref.watch(agentDetailProvider(msg.senderId)).value;
    final agentName = agent?.name ?? msg.senderId;

    final chips = <Widget>[
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GitHubUserAvatar(login: agentName, size: 14, showHoverCard: false),
          const SizedBox(width: 4),
          _Chip(label: agentName),
        ],
      ),
      _Chip(label: 'priority: ${payload.priority.name.toUpperCase()}'),
      _Chip(label: '${(payload.confidence * 100).round()}% conf'),
      _Chip(label: 'status: ${payload.status.name}'),
      if (payload.anchor.filePath != null)
        _Chip(
          label:
              '${payload.anchor.filePath}${payload.anchor.lineNumber != null ? ':${payload.anchor.lineNumber}' : ''}',
          mono: true,
        ),
    ];

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final c in chips)
          DefaultTextStyle(
            style: Theme.of(context).textTheme.labelSmall!.copyWith(
              color: tokens.textPrimary,
              fontSize: 10,
            ),
            child: c,
          ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, this.mono = false});

  final String label;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: tokens.bgSecondary,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontSize: 10,
          color: tokens.textPrimary,
          fontFamily: mono ? 'monospace' : null,
        ),
      ),
    );
  }
}

class _AgentChip extends StatelessWidget {
  const _AgentChip({required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: tokens.bgBrandPrimary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '@$id',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: tokens.fgBrandPrimary,
          fontSize: 10,
        ),
      ),
    );
  }
}

class _ThreadReply extends ConsumerWidget {
  const _ThreadReply({required this.message});

  final ChannelMessage message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.designSystem!;
    final agent = ref.watch(agentDetailProvider(message.senderId)).value;
    final agentName = agent?.name ?? message.senderId;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: tokens.bgSecondary.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GitHubUserAvatar(
                  login: agentName,
                  size: 12,
                  showHoverCard: false,
                ),
                const SizedBox(width: 4),
                Text(
                  agentName,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: tokens.textTertiary,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              message.content,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: tokens.textPrimary),
            ),
          ],
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.sending,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool sending;
  final Future<void> Function() onSend;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem!;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: tokens.bgSecondary.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: tokens.borderSecondary),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: 3,
              minLines: 1,
              decoration: InputDecoration(
                isDense: true,
                hintText: AppLocalizations.of(context).replyEllipsis,
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          CcButton(
            onPressed: sending ? null : onSend,
            size: CcButtonSize.sm,
            child: sending
                ? const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(AppLocalizations.of(context).send),
          ),
        ],
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.canComment,
    required this.onFix,
    required this.onComment,
  });

  final bool canComment;
  final VoidCallback onFix;
  final VoidCallback onComment;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CcButton(
          size: CcButtonSize.sm,
          variant: CcButtonVariant.primary,
          onPressed: onFix,
          icon: AppIcons.wrench,
          child: Text(AppLocalizations.of(context).fix),
        ),
        const SizedBox(width: 8),
        if (!canComment)
          CcTooltip(
            message: AppLocalizations.of(context).noFileAnchor,
            child: CcButton(
              size: CcButtonSize.sm,
              variant: CcButtonVariant.secondary,
              onPressed: null,
              icon: AppIcons.messageSquarePlus,
              child: Text(AppLocalizations.of(context).comment),
            ),
          )
        else
          CcButton(
            size: CcButtonSize.sm,
            variant: CcButtonVariant.secondary,
            onPressed: onComment,
            icon: AppIcons.messageSquarePlus,
            child: Text(AppLocalizations.of(context).comment),
          ),
      ],
    );
  }
}
