import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/value_objects/file_reference.dart';
import 'package:cc_domain/core/domain/value_objects/message_attachment.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:cc_remote/app_icons.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/widgets/agent_transcript.dart';
import 'package:cc_remote/widgets/messaging/sent_attachments.dart';
import 'package:cc_remote/widgets/messaging/user_question_tile.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';

/// One space message: mine, a teammate's, or a live agent turn.
class SpaceMessageTile extends StatelessWidget {
  /// Creates a [SpaceMessageTile].
  const SpaceMessageTile({
    super.key,
    required this.message,
    required this.myUserId,
    required this.userNames,
  });

  /// The message to render.
  final MessageDto message;

  /// Signed-in user id, used to right-align own messages.
  final String? myUserId;

  /// Display names of co-members keyed by user id.
  final Map<String, String> userNames;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final m = message;
    final isHuman = m.senderType == 'user';
    final isMine = isHuman && (myUserId == null || m.senderId == myUserId);
    final meta = m.metadata is Map ? m.metadata as Map : null;
    final segments = decodeTranscript(meta?['segments']);
    final isAgentTurn = !isMine && !isHuman && segments.isNotEmpty;
    final streamComplete = (meta?['streamComplete'] as bool?) ?? !isAgentTurn;
    final l10n = AppLocalizations.of(context);
    final agentName = isHuman
        ? ((userNames[m.senderId]?.isNotEmpty ?? false)
              ? userNames[m.senderId]!
              : l10n.teammate)
        : (meta?['agentName'] as String?) ?? m.senderType;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: isMine
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: Column(
              crossAxisAlignment: isMine
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (!isMine)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(
                      start: 4,
                      bottom: 3,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          m.senderType == 'user' ? AppIcons.user : AppIcons.bot,
                          size: 12,
                          color: t.fgTertiary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          agentName.isEmpty ? l10n.agent : agentName,
                          style: TextStyle(fontSize: 11, color: t.fgTertiary),
                        ),
                      ],
                    ),
                  ),
                if (isAgentTurn)
                  _agentBubble(t, segments, streamComplete)
                else if (m.messageType == 'user_question')
                  UserQuestionTile(message: m)
                else
                  _textBubble(t, m.content, isMine),
                SentAttachments(
                  attachments: MessageAttachment.attachmentsFromMetadata(
                    meta?.cast<String, dynamic>(),
                  ),
                  alignEnd: isMine,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _textBubble(DesignSystemTokens t, String content, bool isMine) {
    final body = TextStyle(fontSize: 14, height: 1.4, color: t.textPrimary);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isMine ? t.accentSoft : t.bgSecondary,
        borderRadius: const BorderRadius.all(Radius.circular(12)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text.rich(
          TextSpan(children: _bodySpans(t, content, body)),
          style: body,
        ),
      ),
    );
  }

  List<InlineSpan> _bodySpans(
    DesignSystemTokens t,
    String content,
    TextStyle body,
  ) {
    final refs = findFileRefs(content);
    if (refs.isEmpty) return [TextSpan(text: content)];
    final spans = <InlineSpan>[];
    var cursor = 0;
    for (final ref in refs) {
      if (ref.start > cursor) {
        spans.add(TextSpan(text: content.substring(cursor, ref.start)));
      }
      spans.add(
        TextSpan(
          text: ref.name,
          style: body.copyWith(color: t.accent, fontWeight: FontWeight.w500),
        ),
      );
      cursor = ref.end;
    }
    if (cursor < content.length) {
      spans.add(TextSpan(text: content.substring(cursor)));
    }
    return spans;
  }

  Widget _agentBubble(
    DesignSystemTokens t,
    List<TranscriptSegment> segments,
    bool streamComplete,
  ) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: t.bgSecondary,
          borderRadius: const BorderRadius.all(Radius.circular(12)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: AgentTranscript(segments: segments, isLive: !streamComplete),
        ),
      ),
    );
  }
}
