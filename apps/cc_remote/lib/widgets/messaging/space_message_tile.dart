import 'dart:async';

import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/value_objects/file_reference.dart';
import 'package:cc_domain/core/domain/value_objects/message_attachment.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_update.dart';
import 'package:cc_remote/app_icons.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/live_turns.dart';
import 'package:cc_remote/widgets/agent_transcript.dart';
import 'package:cc_remote/widgets/messaging/sent_attachments.dart';
import 'package:cc_remote/widgets/messaging/user_question_tile.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';

/// One space message: mine, a teammate's, or a live agent turn.
///
/// List rows no longer carry `segments`. A live turn reads them from [turns];
/// a finished row with `segments_elided` loads them once. The answer text
/// (`content`) shows while that load is in flight, so the row is never blank.
class SpaceMessageTile extends StatefulWidget {
  /// Creates a [SpaceMessageTile].
  const SpaceMessageTile({
    super.key,
    required this.message,
    required this.myUserId,
    required this.userNames,
    this.turns,
  });

  /// The message to render.
  final MessageDto message;

  /// Signed-in user id, used to right-align own messages.
  final String? myUserId;

  /// Display names of co-members keyed by user id.
  final Map<String, String> userNames;

  /// Live and finished transcripts for this space. Null in tests that render
  /// a row which still has its segments inline.
  final PhoneTurnRelay? turns;

  @override
  State<SpaceMessageTile> createState() => _SpaceMessageTileState();
}

class _SpaceMessageTileState extends State<SpaceMessageTile> {
  StreamSubscription<TranscriptUpdate>? _updates;
  StreamSubscription<String>? _registrations;
  List<TranscriptSegment>? _fetched;
  var _fetching = false;
  var _generation = 0;

  @override
  void initState() {
    super.initState();
    _bind();
    _maybeFetch();
  }

  @override
  void didUpdateWidget(SpaceMessageTile old) {
    super.didUpdateWidget(old);
    final idChanged = old.message.id != widget.message.id;
    if (idChanged) {
      _fetched = null;
      _fetching = false;
      _generation++;
    }
    if (idChanged || old.turns != widget.turns) {
      _bind();
    }
    _maybeFetch();
  }

  @override
  void dispose() {
    unawaited(_updates?.cancel());
    unawaited(_registrations?.cancel());
    super.dispose();
  }

  void _bind() {
    final previousUpdates = _updates;
    if (previousUpdates != null) {
      unawaited(previousUpdates.cancel());
    }
    _updates = null;
    final previousRegistrations = _registrations;
    if (previousRegistrations != null) {
      unawaited(previousRegistrations.cancel());
    }
    _registrations = null;
    final turns = widget.turns;
    if (turns == null) {
      return;
    }
    final id = widget.message.id;
    void listen() {
      final previous = _updates;
      if (previous != null) {
        unawaited(previous.cancel());
      }
      final stream = turns.updatesFor(id);
      if (stream == null) {
        _updates = null;
        return;
      }
      _updates = stream.listen((_) {
        if (mounted) {
          setState(() {});
        }
      });
    }

    listen();
    _registrations = turns.registrations.listen((registered) {
      if (registered != id || !mounted) {
        return;
      }
      listen();
      setState(() {});
    });
  }

  void _maybeFetch() {
    if (_fetching || _fetched != null || !_view.fetch) {
      return;
    }
    _fetching = true;
    unawaited(_fetch(widget.message.id, _generation));
  }

  PhoneTurnPresentation get _view {
    final message = widget.message;
    final isHuman = message.senderType == 'user';
    return presentPhoneTurn(
      message: message,
      isMine:
          isHuman &&
          (widget.myUserId == null || message.senderId == widget.myUserId),
      turns: widget.turns,
      fetched: _fetched,
    );
  }

  Future<void> _fetch(String id, int generation) async {
    final turns = widget.turns;
    if (turns == null) {
      if (generation == _generation) {
        _fetching = false;
      }
      return;
    }
    try {
      final segments = await turns.load(id);
      if (!mounted || generation != _generation || widget.message.id != id) {
        return;
      }
      setState(() => _fetched = segments);
    } catch (_) {
      // The answer text stays on screen. A later row update retries.
    } finally {
      if (generation == _generation) {
        _fetching = false;
      }
    }
  }

  Map<dynamic, dynamic>? get _meta {
    final metadata = widget.message.metadata;
    return metadata is Map<dynamic, dynamic> ? metadata : null;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final m = widget.message;
    final isHuman = m.senderType == 'user';
    final isMine =
        isHuman && (widget.myUserId == null || m.senderId == widget.myUserId);
    final meta = _meta;
    final view = _view;
    final segments = view.segments;
    final streamComplete = view.streamComplete;
    final showTranscript = view.showTranscript;
    final l10n = AppLocalizations.of(context);
    final agentName = isHuman
        ? ((widget.userNames[m.senderId]?.isNotEmpty ?? false)
              ? widget.userNames[m.senderId]!
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
                if (showTranscript && segments.isEmpty && m.content.isNotEmpty)
                  _textBubble(t, m.content, isMine),
                if (showTranscript)
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
    if (refs.isEmpty) {
      return [TextSpan(text: content)];
    }
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
