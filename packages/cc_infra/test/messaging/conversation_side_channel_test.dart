import 'dart:async';
import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/core/domain/repositories/workspace_settings_repository.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/messaging/domain/services/conversation_title_model.dart';
import 'package:cc_harness/messages.dart';
import 'package:cc_harness/provider.dart';
import 'package:cc_harness_runtime/cc_harness_runtime.dart';
import 'package:cc_infra/src/dispatch/adapter_one_shot_runner.dart';
import 'package:cc_infra/src/messaging/conversation_side_channel_service.dart';
import 'package:test/test.dart';

Message _user(String text) => Message(
  id: 'u',
  spaceId: 's',
  conversationId: 'c',
  senderId: 'me',
  senderType: SenderType.user,
  content: text,
  messageType: MessageType.text,
  createdAt: DateTime(2026),
);

Message _agent({String content = '', List<TranscriptSegment> segments = const []}) =>
    Message(
      id: 'a',
      spaceId: 's',
      conversationId: 'c',
      senderId: 'agent-1',
      senderType: SenderType.agent,
      messageType: MessageType.agentTurn,
      content: content,
      createdAt: DateTime(2026),
      metadata: {
        'agentName': 'Scout',
        if (segments.isNotEmpty) 'segments': encodeTranscript(segments),
      },
    );

void main() {
  group('renderConversationForSideChannel', () {
    test('labels each speaker', () {
      final out = renderConversationForSideChannel([
        _user('fix the tests'),
        _agent(content: 'done'),
      ]);
      expect(out, contains('User: fix the tests'));
      expect(out, contains('Scout: done'));
    });

    test('renders an agent turn from its transcript segments', () {
      // Agent turns carry their substance in segments, not `content`.
      final out = renderConversationForSideChannel([
        _agent(
          segments: [
            TextSegment(text: 'I looked at auth.', startedAt: DateTime(2026)),
            ToolSegment(
              toolName: 'edit',
              toolCallId: 't1',
              inputs: const {'path': 'lib/auth.dart'},
              startedAt: DateTime(2026),
            ),
          ],
        ),
      ]);
      expect(out, contains('I looked at auth.'));
      expect(
        out,
        contains('[edit lib/auth.dart]'),
        reason: 'the tool CALL is the useful signal for a handoff',
      );
    });

    test('keeps the NEWEST messages when it must cut', () {
      // A handoff is about where the work stands; dropping the tail to keep
      // the opening answers about the wrong end of the conversation.
      final messages = [
        for (var i = 0; i < 50; i++) _user('message number $i with padding'),
      ];
      final out = renderConversationForSideChannel(messages, maxChars: 200);
      expect(out, contains('message number 49'));
      expect(out, isNot(contains('message number 0 ')));
      expect(out, contains('earlier conversation omitted'));
    });

    test('preserves chronological order after truncation', () {
      final messages = [for (var i = 0; i < 10; i++) _user('m$i')];
      final out = renderConversationForSideChannel(messages, maxChars: 60);
      final positions = [
        for (final m in ['m7', 'm8', 'm9'])
          if (out.contains(m)) out.indexOf(m),
      ];
      expect(
        positions,
        orderedEquals([...positions]..sort()),
        reason: 'reading backwards would confuse the model about what came '
            'first',
      );
    });

    test('skips empty messages', () {
      final out = renderConversationForSideChannel([
        _user('   '),
        _user('real'),
      ]);
      expect(out.trim(), 'User: real');
    });

    test('an empty conversation renders empty', () {
      expect(renderConversationForSideChannel(const []), isEmpty);
    });
  });

  test('paged history does not scan the conversation', () async {
    final messaging = _ScanMessaging();
    final settings = _Settings()
      ..values[kConversationTitleAdapterSettingKey] = 'cc-harness'
      ..values[kConversationTitleModelSettingKey] = 'anthropic/x';
    final factory = _Factory()..reply = 'the aside';
    final service = ConversationSideChannelService(
      repo: messaging,
      runner: AdapterOneShotRunner(credentials: _Creds(), factory: factory),
      settings: settings,
      sideChannelMessages:
          ({
            required String workspaceId,
            required String spaceId,
            String? conversationId,
            required int maxChars,
          }) async => [_user('from the window')],
    );
    final result = await service.aside(
      workspaceId: 'ws',
      spaceId: 's',
      conversationId: 'c',
      question: 'where are we?',
    );
    expect(result.text, 'the aside');
    expect(factory.calls.single.prompt, contains('User: from the window'));
    expect(messaging.scanned, isFalse);
  });
}

class _ScanMessaging implements MessagingRepository {
  bool scanned = false;

  @override
  Future<List<Message>> getMessages(
    String workspaceId,
    String spaceId, {
    String? conversationId,
  }) async {
    scanned = true;
    throw StateError('full scan');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _Settings implements WorkspaceSettingsRepository {
  final Map<String, String> values = {};

  @override
  Future<String?> get(String workspaceId, String key) async => values[key];

  @override
  Future<Map<String, String>> getAll(String workspaceId) async => values;

  @override
  Stream<Map<String, String>> watchAll(String workspaceId) =>
      Stream.value(values);

  @override
  Future<void> set(String workspaceId, String key, String? value) async {
    if (value == null) {
      values.remove(key);
    } else {
      values[key] = value;
    }
  }
}

class _Creds implements ProviderCredentialStore {
  @override
  Future<ProviderCredential?> activeCredential(String providerId) async =>
      const ProviderCredential(
        providerId: 'anthropic',
        method: HarnessAuthMethod.apiKey,
        apiKey: 'k',
      );

  @override
  dynamic noSuchMethod(Invocation invocation) {}
}

class _Call {
  _Call(this.prompt);
  final String prompt;
}

class _Factory extends HarnessProviderFactory {
  String reply = '';
  final List<_Call> calls = [];

  @override
  LlmProviderPort create({
    required String providerId,
    String? model,
    ProviderCredential? credential,
    ProviderTokenResolver? tokenResolver,
  }) {
    return _Provider(reply, calls);
  }
}

class _Provider implements LlmProviderPort {
  _Provider(this.reply, this.calls);
  final String reply;
  final List<_Call> calls;

  @override
  Stream<LlmEvent> complete({
    required List<HarnessMessage> messages,
    List<LlmToolSchema> tools = const [],
    LlmCompleteConfig config = const LlmCompleteConfig(),
  }) async* {
    calls.add(_Call(messages.first.textContent));
    yield LlmTextDelta(reply);
  }

  @override
  String get displayName => 'fake';

  @override
  String get defaultModel => 'fake-model';

  @override
  Future<List<ProviderModel>> listModels() async => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) {}
}
