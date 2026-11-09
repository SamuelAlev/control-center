part of 'chat_bridge_service.dart';

/// Accumulates one agent turn: the answer text that is relayed verbatim and the
/// summary that becomes its card.
///
/// Only [TextSegment]s are *relayed*: tool output is a wall of diffs, which
/// does not belong in a chat thread. Text is kept per segment index so a
/// [SegmentClosed] can *replace* a partially-streamed segment (which is how
/// atomic segments arrive) while the bytes already sent stay accounted for.
///
/// The card's title is the *current* line — a setup note, "Thinking…", or the
/// latest tool — replaced in place. The thought is that row's details, once
/// reasoning finishes; tool output stays in Control Center.
class _TurnRelay {
  _TurnRelay({
    required this.target,
    required this.ccSpaceId,
    required this.cardId,
    required this.title,
    this.link,
  });

  final _ChatTarget target;

  /// The Control Center space this relay reports on.
  final String ccSpaceId;

  /// Stable id of this turn's card, so every update edits the same one.
  final String cardId;

  /// What the turn is working on.
  final String title;

  /// Where the card points back to, when the server is reachable by link.
  final ChatTaskLink? link;

  final SplayTreeMap<int, StringBuffer> _text = SplayTreeMap();
  int _sent = 0;
  int _actions = 0;
  String? _bullet;
  final List<_LiveStep> _steps = [];
  final StringBuffer _reasoning = StringBuffer();
  int? _reasoningIndex;
  ChatTaskAction? _latestAction;
  String? _latestCallId;
  ChatTaskCard? _sentCard;
  ChatTaskCard? _cardBeforeSend;
  Timer? _flushTimer;
  Future<void> _lock = Future<void>.value();

  /// The live stream, once opened.
  ChatStreamHandle? handle;

  /// Whether anything at all has reached the reader on [handle]. A stream that
  /// never delivered can still be given up on without duplicating a prefix.
  bool get delivered => _delivered;
  bool _delivered = false;

  /// Whether the stream was given up on: it opened but would not take anything,
  /// so the reply is posted whole instead of finishing an empty message.
  bool get abandonedStream => _abandonedStream;
  bool _abandonedStream = false;

  void markDelivered() => _delivered = true;

  void abandonStream() => _abandonedStream = true;

  /// Everything the turn has said so far.
  String get rendered => _text.values.join('\n\n');

  bool get hasPending => rendered.length > _sent;

  /// Whether the card would say something new if it were sent now.
  bool get hasCardUpdate => buildCard(ChatTaskStatus.inProgress) != _sentCard;

  /// Whether the live line is currently "Thinking…".
  bool get isThinking => _bullet == _thinkingNote;

  /// What the workspace is doing while the turn has not started ("Cloning
  /// acme/widgets…"). Replaces the setup row in place; a later thought or tool
  /// is a new row.
  void setSetupNote(String? note) {
    if (note != null && note.isNotEmpty) {
      _bullet = note;
      _upsertStep(cardId, note, ChatTaskStatus.inProgress);
    }
  }

  void setText(int index, String text) {
    _text[index] = StringBuffer(text);
    _completeThinking();
  }

  /// The agent is reasoning. The row says `Thinking…`; the thought is the
  /// row's details, filled in when reasoning closes.
  void noteThinking({required int index, String? text}) {
    _reasoningIndex = index;
    _bullet = _thinkingNote;
    if (text != null) {
      _reasoning
        ..clear()
        ..write(text);
    }
    _upsertStep(
      _thinkId,
      _thinkingNote,
      ChatTaskStatus.inProgress,
      completeOthers: true,
    );
  }

  /// Reasoning finished. The thought becomes this row's details, once.
  void finishThinking({required int index, required String text}) {
    _reasoningIndex = index;
    _reasoning
      ..clear()
      ..write(text);
    _completeThinking();
  }

  /// Records that the agent started a tool. Counted here, on the call, so a tool
  /// still running is already visible.
  void noteToolCall(ToolSegment segment) {
    _actions++;
    _latestCallId = segment.toolCallId;
    _latestAction = _actionFrom(segment);
    _bullet = _actionLine(_latestAction!);
    _upsertStep(
      _toolStepId(segment),
      _bullet!,
      ChatTaskStatus.inProgress,
      completeOthers: true,
    );
  }

  /// Refreshes the latest action when *its* result lands — a call's arguments can
  /// arrive with the result rather than with the call.
  void noteToolResult(ToolSegment segment) {
    final action = _actionFrom(segment);
    if (_latestCallId == segment.toolCallId) {
      _latestAction = action;
      _bullet = _actionLine(action);
    }
    final id = _toolStepId(segment);
    if (_steps.any((step) => step.id == id)) {
      _upsertStep(
        id,
        _actionLine(action),
        segment.isError ? ChatTaskStatus.error : ChatTaskStatus.complete,
      );
    }
  }

  void append(int index, String delta) {
    _text[index]?.write(delta);
    if (_reasoningIndex == index) {
      _reasoning.write(delta);
    }
  }

  void _completeThinking() {
    final body = _reasoning.toString().trim();
    for (final step in _steps) {
      if (step.id == _thinkId && step.status == ChatTaskStatus.inProgress) {
        step.status = ChatTaskStatus.complete;
        if (body.isNotEmpty) {
          step.details = body;
        }
      }
    }
  }

  String get _thinkId => '$cardId-think';

  String _toolStepId(ToolSegment segment) => segment.toolCallId.isNotEmpty
      ? segment.toolCallId
      : '$cardId-tool-$_actions';

  void _upsertStep(
    String id,
    String title,
    ChatTaskStatus status, {
    bool completeOthers = false,
  }) {
    if (completeOthers) {
      for (final step in _steps) {
        if (step.id != id && step.status == ChatTaskStatus.inProgress) {
          step.status = ChatTaskStatus.complete;
          if (step.id == _thinkId) {
            final body = _reasoning.toString().trim();
            if (body.isNotEmpty) {
              step.details = body;
            }
          }
        }
      }
    }
    for (final step in _steps) {
      if (step.id == id) {
        step
          ..title = title
          ..status = status;
        return;
      }
    }
    _steps.add(_LiveStep(id: id, title: title, status: status));
  }

  /// The card as it stands, at [status].
  ChatTaskCard buildCard(ChatTaskStatus status, {String? result}) {
    final finished =
        status == ChatTaskStatus.complete || status == ChatTaskStatus.error;
    if (finished) {
      _completeThinking();
    }
    return ChatTaskCard(
      id: cardId,
      title: title,
      status: status,
      // One live bullet, replaced as work moves on. A finished turn with an
      // answer drops it so the card is not still showing the last tool; a
      // failed setup has no answer, so the excuse stays on the bullet.
      narration: finished && rendered.trim().isNotEmpty ? null : _bullet,
      steps: [
        for (final step in _steps)
          ChatTaskStep(
            id: step.id,
            title: step.title,
            status: finished && step.status == ChatTaskStatus.inProgress
                ? status
                : step.status,
            details: step.details,
          ),
      ],
      actionCount: _actions,
      latestAction: _latestAction,
      result: result,
      link: link,
    );
  }

  /// The card to send now, or null when nothing about it changed since the last
  /// one the provider was given.
  ChatTaskCard? takeCard(ChatTaskStatus status, {String? result}) {
    final next = buildCard(status, result: result);
    if (next == _sentCard) {
      return null;
    }
    _cardBeforeSend = _sentCard;
    _sentCard = next;
    return next;
  }

  /// Un-marks the last card as sent after a failed send, so the next flush
  /// carries it again.
  void restoreCard() => _sentCard = _cardBeforeSend;

  static ChatTaskAction _actionFrom(ToolSegment segment) => ChatTaskAction(
    name: segment.toolName,
    detail: _detailFrom(segment.inputs),
  );

  static String _actionLine(ChatTaskAction action) {
    final detail = action.detail?.trim() ?? '';
    return detail.isEmpty ? action.name : '${action.name} $detail';
  }

  /// The one argument worth showing for a tool call.
  ///
  /// Deliberately a short allow-list rather than "the first string in the map": an
  /// unknown tool's arguments can be an entire prompt or file body and a card is
  /// a status line. Anything not named here shows as the tool's name alone.
  static String? _detailFrom(Map<String, dynamic>? inputs) {
    if (inputs == null) {
      return null;
    }
    for (final key in const [
      // The per-call summary script tools are required to send; a status line
      // reads better as "checking the failing test" than as a raw command.
      'description',
      'command',
      'file_path',
      'path',
      'pattern',
      'url',
      'query',
      'title',
      'name',
    ]) {
      final value = inputs[key];
      if (value is String && value.trim().isNotEmpty) {
        return _cap(value.trim().replaceAll('\n', ' '), _maxDetailLength);
      }
    }
    return null;
  }

  /// Shortens [value] to [max], keeping the end of a path (the file name is what
  /// identifies it) and the start of anything else.
  static String _cap(String value, int max) {
    if (value.length <= max) {
      return value;
    }
    if (value.contains('/')) {
      return '…${value.substring(value.length - max + 1)}';
    }
    return '${value.substring(0, max - 1).trimRight()}…';
  }

  static const int _maxDetailLength = 80;

  /// Text not yet handed to the provider, marking it as sent.
  String takePending() {
    final all = rendered;
    if (all.length <= _sent) {
      return '';
    }
    final chunk = all.substring(_sent);
    _sent = all.length;
    return chunk;
  }

  /// Un-marks [chunk] as sent after a failed send, so the next flush retries.
  void restore(String chunk) => _sent = (_sent - chunk.length).clamp(0, _sent);

  void scheduleFlush(Duration interval, Future<void> Function() flush) {
    if (_flushTimer != null) {
      return;
    }
    _flushTimer = Timer(interval, () {
      _flushTimer = null;
      unawaited(sequence(flush));
    });
  }

  void cancelFlush() {
    _flushTimer?.cancel();
    _flushTimer = null;
  }

  /// Serializes provider calls for this turn: appends must arrive in order and a
  /// throttled flush can fire while the previous one is still in flight.
  Future<void> sequence(Future<void> Function() op) {
    final next = _lock.then((_) => op());
    _lock = next.catchError((Object _) {});
    return next;
  }

  void dispose() => cancelFlush();
}

/// One plan row while the turn is running. Title and status are edited in place.
class _LiveStep {
  _LiveStep({required this.id, required this.title, required this.status});

  final String id;
  String title;
  ChatTaskStatus status;
  String? details;
}
