import 'package:cc_domain/cc_domain.dart';
import 'package:cc_remote/app_icons.dart';
import 'package:cc_remote/conversation_drafts.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/operation_scope.dart';
import 'package:cc_remote/widgets/messaging/conversation_controls.dart';
import 'package:cc_remote/widgets/messaging/detail_header.dart';
import 'package:cc_remote/widgets/messaging/pending_approvals.dart';
import 'package:cc_remote/widgets/touch_target.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ConversationHeader extends StatelessWidget {
  const ConversationHeader({
    required this.scope,
    required this.title,
    super.key,
  });
  final RemoteConversationKey scope;
  final String title;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final space = Uri.encodeComponent(scope.spaceId);
    return Row(
      children: [
        Expanded(
          child: DetailHeader(title: title.isEmpty ? l10n.thread : title),
        ),
        PhoneIconButton(
          icon: AppIcons.layers,
          semanticLabel: l10n.mobileConversations,
          onPressed: () => context.push(
            remoteWorkspaceLocation(
              '/spaces/$space/conversations',
              scope.workspaceId,
            ),
          ),
        ),
        PhoneIconButton(
          icon: AppIcons.moreHorizontal,
          semanticLabel: l10n.mobileProgress,
          onPressed: () => context.push(
            remoteWorkspaceLocation(
              '/spaces/$space/progress?conversation_id=${Uri.encodeQueryComponent(scope.conversationId)}',
              scope.workspaceId,
            ),
          ),
        ),
      ],
    );
  }
}

/// Attention and expanded run queues cannot push the composer off a short
/// viewport. The transcript and input keep their own independent scroll areas.
class ConversationAttention extends StatelessWidget {
  const ConversationAttention({
    required this.scope,
    required this.runs,
    required this.queued,
    required this.canWrite,
    required this.archived,
    required this.readError,
    required this.onReadRetry,
    required this.maxHeight,
    super.key,
  });
  final RemoteConversationKey scope;
  final AsyncValue<List<AgentRunLogDto>> runs;
  final List<MessageDto> queued;
  final bool canWrite;
  final bool archived;
  final Object? readError;
  final VoidCallback onReadRetry;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PendingApprovals(spaceId: scope.spaceId),
            ConversationControls(
              scope: scope,
              runs: runs,
              queued: queued,
              canWrite: canWrite,
            ),
            if (archived)
              CcAlert(title: l10n.mobileArchived, variant: CcAlertVariant.info),
            if (readError != null)
              CcAlert(
                title: l10n.mobileReadFailed,
                description: Text('$readError'),
                action: CcButton(
                  onPressed: onReadRetry,
                  child: Text(l10n.retry),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
