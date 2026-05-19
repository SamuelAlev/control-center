import 'package:cc_domain/core/domain/entities/channel_message.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:cc_domain/features/dispatch/domain/context/compaction_config.dart';
import 'package:cc_domain/features/dispatch/domain/context/conversation_compactor.dart';
import 'package:cc_domain/features/dispatch/domain/context/conversation_summarizer.dart';
import 'package:test/test.dart';

final _t0 = DateTime.utc(2026);
var _seq = 0;

ChannelMessage _user(String text) => ChannelMessage(
      id: 'u${_seq++}',
      channelId: 'c',
      senderId: 'user',
      senderType: ChannelSenderType.user,
      content: text,
      messageType: ChannelMessageType.text,
      createdAt: _t0.add(Duration(seconds: _seq)),
    );

ChannelMessage _turn(String answer, {List<String> tools = const []}) {
  final segs = <TranscriptSegment>[
    for (final t in tools)
      ToolSegment(
        toolName: t,
        toolCallId: '$t$_seq',
        outputs: 'X' * 4000, // fat output that compaction must drop
        startedAt: _t0,
        durationMs: 1,
      ),
    TextSegment(text: answer, startedAt: _t0),
  ];
  return ChannelMessage(
    id: 'a${_seq++}',
    channelId: 'c',
    senderId: 'agent',
    senderType: ChannelSenderType.agent,
    content: answer,
    messageType: ChannelMessageType.agentTurn,
    metadata: {'segments': encodeTranscript(segs)},
    createdAt: _t0.add(Duration(seconds: _seq)),
  );
}

ChannelMessage _summary(String text) => ChannelMessage(
      id: 's${_seq++}',
      channelId: 'c',
      senderId: 'system',
      senderType: ChannelSenderType.agent,
      content: text,
      messageType: ChannelMessageType.compaction,
      metadata: const {'compactionReason': 'auto'},
      createdAt: _t0.add(Duration(seconds: _seq)),
    );

void main() {
  setUp(() => _seq = 0);
  const compactor = ConversationCompactor();

  test('no compaction when under pressure', () {
    final messages = [_user('hi'), _turn('hello')];
    final plan = compactor.plan(
      messages: messages,
      contextWindowTokens: 200000,
    );
    expect(plan, isNull);
  });

  test('100-turn conversation compacts to summary + last N turns', () {
    final messages = <ChannelMessage>[];
    messages.add(_user('IMPORTANT: use snake_case for all file names'));
    messages.add(_turn('Understood, snake_case it is.'));
    for (var i = 0; i < 99; i++) {
      messages.add(_user('step $i please'));
      messages.add(_turn('did step $i', tools: ['bash', 'read']));
    }

    // Small window forces pressure.
    final plan = compactor.plan(
      messages: messages,
      contextWindowTokens: 8000,
      config: const CompactionConfig(keepTurns: 3, buffer: 1000),
    );
    expect(plan, isNotNull);
    // The kept tail starts at a user message (never mid-turn).
    final tail = messages.firstWhere((m) => m.id == plan!.tailStartId);
    expect(tail.isUser, isTrue);
    // Early decision is in the compacted span (recoverable + summarized).
    expect(
      plan!.messagesToCompact.first.content,
      contains('snake_case'),
    );
    // The newest 3 turns are NOT compacted.
    final compactedIds = plan.idsToCompact.toSet();
    expect(compactedIds.contains(messages[messages.length - 1].id), isFalse);
  });

  test('manual force compacts even under no pressure', () {
    final messages = <ChannelMessage>[];
    for (var i = 0; i < 10; i++) {
      messages.add(_user('q$i'));
      messages.add(_turn('a$i'));
    }
    final plan = compactor.plan(
      messages: messages,
      contextWindowTokens: 1000000,
      force: true,
    );
    expect(plan, isNotNull);
    expect(plan!.reason, CompactionReason.manual);
  });

  test('re-anchors after a prior compaction: only newer region folds', () {
    final messages = <ChannelMessage>[];
    messages.add(_summary('## Conversation summary (compacted)\nearlier stuff'));
    for (var i = 0; i < 20; i++) {
      messages.add(_user('q$i'));
      messages.add(_turn('a$i'));
    }
    final plan = compactor.plan(
      messages: messages,
      contextWindowTokens: 4000,
      config: const CompactionConfig(keepTurns: 2, buffer: 500),
      force: true,
    );
    expect(plan, isNotNull);
    expect(plan!.previousSummary, contains('earlier stuff'));
    // Nothing before the prior summary is re-compacted.
    expect(plan.idsToCompact.any((id) => id.startsWith('s')), isFalse);
  });

  group('StructuralConversationSummarizer', () {
    test('keeps user requests + agent answers, drops tool fat', () async {
      const summarizer = StructuralConversationSummarizer();
      final summary = await summarizer.summarize(
        CompactionInput(
          messages: [
            _user('build the login form'),
            _turn('Done — added LoginForm widget.', tools: ['read', 'edit']),
          ],
          selfAgentName: 'architect',
        ),
      );
      expect(summary, contains('build the login form'));
      expect(summary, contains('LoginForm widget'));
      expect(summary, contains('actions: read, edit'));
      // The 4000-char fat tool output must not appear.
      expect(summary.contains('X' * 100), isFalse);
    });

    test('carries the previous summary forward', () async {
      const summarizer = StructuralConversationSummarizer();
      final summary = await summarizer.summarize(
        CompactionInput(
          messages: [_user('next task')],
          previousSummary: '## Conversation summary (compacted)\nprior facts',
        ),
      );
      expect(summary, contains('Established context'));
      expect(summary, contains('prior facts'));
      expect(summary, contains('next task'));
    });
  });

  group('buildCompactionUserPrompt', () {
    test('wraps the prior summary in a previous-summary anchor', () {
      final prompt = buildCompactionUserPrompt(
        CompactionInput(
          messages: [_user('hi')],
          previousSummary: 'old summary',
        ),
      );
      expect(prompt, contains('<previous-summary>'));
      expect(prompt, contains('old summary'));
      expect(prompt, contains('<conversation-history>'));
    });

    test('asks for a fresh summary when there is no prior', () {
      final prompt = buildCompactionUserPrompt(
        CompactionInput(messages: [_user('hi')]),
      );
      expect(prompt, isNot(contains('<previous-summary>')));
      expect(prompt, contains('Create an anchored summary'));
    });
  });
}
