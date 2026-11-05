import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/messaging/presentation/widgets/bubbles/bubble_icon_button.dart';
import 'package:control_center/features/workspaces/providers/workspace_scope.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A quiet thumbs-up / thumbs-down rating under a completed agent turn. A
/// lightweight quality signal: tapping a thumb sets the rating, tapping the
/// active thumb again clears it. Persisted under the message's
/// `metadata['feedback']`, leaving the transcript untouched.
class AgentFeedbackBar extends ConsumerWidget {
  /// Creates an [AgentFeedbackBar].
  const AgentFeedbackBar({super.key, required this.message});

  /// The completed agent-turn message being rated.
  final Message message;

  Future<void> _set(WidgetRef ref, MessageFeedback? next) async {
    final metadata = message.metadataWithFeedback(
      next,
      atEpochMs: DateTime.now().millisecondsSinceEpoch,
    );
    await ref
        .read(messagingRepositoryProvider)
        .updateMessage(
          ref.requireWorkspaceId(),
          message.id,
          metadata: metadata,
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final current = message.feedback;

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          BubbleIconButton(
            icon: AppIcons.thumbsUp,
            tokens: t,
            tooltip: l10n.feedbackHelpful,
            restColor: t.fgQuaternary,
            activeColor: current == MessageFeedback.helpful ? t.success : null,
            onTap: () => _set(
              ref,
              current == MessageFeedback.helpful
                  ? null
                  : MessageFeedback.helpful,
            ),
          ),
          const SizedBox(width: AppSpacing.xxs),
          BubbleIconButton(
            icon: AppIcons.thumbsDown,
            tokens: t,
            tooltip: l10n.feedbackNotHelpful,
            restColor: t.fgQuaternary,
            activeColor: current == MessageFeedback.notHelpful
                ? t.danger
                : null,
            onTap: () => _set(
              ref,
              current == MessageFeedback.notHelpful
                  ? null
                  : MessageFeedback.notHelpful,
            ),
          ),
        ],
      ),
    );
  }
}
