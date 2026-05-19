import 'package:control_center/core/domain/entities/channel_message.dart';
import 'package:control_center/features/messaging/presentation/widgets/channel_bubble/channel_bubble_shared.dart';
import 'package:control_center/features/messaging/presentation/widgets/channel_bubble/focusable_bubble.dart';
import 'package:control_center/features/messaging/presentation/widgets/channel_bubble/thinking_timeline.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/agent_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class StandaloneThinkingBubble extends ConsumerWidget {
  const StandaloneThinkingBubble({super.key, required this.message});

  final ChannelMessage message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = resolveTokens(context);
    final agentName = message.metadata?['agentName'] as String? ?? AppLocalizations.of(context).agent;
    final maxWidth = MediaQuery.sizeOf(context).width * maxBubbleFraction;
    final registry = ref.watch(activeStreamRegistryProvider);
    final eventStream = registry.eventStreamFor(message.id);
    final isLive = registry.isActive(message.id);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Semantics(
        label: '$agentName is thinking',
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AgentAvatar(
              agentId: message.senderId,
              name: agentName,
              size: avatarSize,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: IntrinsicWidth(
                  child: FocusableBubble(
                    child: Container(
                      padding: bubblePadding,
                      decoration: BoxDecoration(
                        color: tokens.bgPrimary,
                        borderRadius: BorderRadius.circular(bubbleRadius),
                        border: Border.all(color: tokens.borderSecondary),
                      ),
                      child: ThinkingTimeline(
                        events: message.thinkingEvents,
                        eventStream: eventStream,
                        isLive: isLive,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
