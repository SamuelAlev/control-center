import 'dart:async';

import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/core/domain/repositories/workspace_settings_repository.dart';
import 'package:cc_domain/features/messaging/domain/entities/conversation.dart';
import 'package:cc_domain/features/messaging/domain/entities/conversation_tree.dart';
import 'package:cc_domain/features/messaging/domain/repositories/conversation_repository.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/messaging/domain/services/conversation_title_model.dart';
import 'package:cc_harness/messages.dart';
import 'package:cc_harness/provider.dart';
import 'package:cc_harness_runtime/cc_harness_runtime.dart';
import 'package:cc_infra/src/dispatch/adapter_one_shot_runner.dart';
import 'package:cc_infra/src/messaging/conversation_title_service.dart';
import 'package:test/test.dart';

/// Exercises [ConversationTitleService] with canned providers and in-memory
/// fakes. Covers: off-until-set (no workspace setting → no call, no rename),
/// qualified-model parsing, the default-title-only guard (an EMPTY title is
/// the one auto-minted state and is renamed; any non-empty title — typed,
/// pipeline-set or legacy — is left alone), missing-credential skip,
/// quote/length/newline sanitization, refusal replies, the rename race
/// re-check, provider errors → fail-open, and the null-conversationId
/// standing-conversation resolution.
void main() {
  const workspaceId = 'ws1';
  const spaceId = 'sp1';
  const userId = 'user-1';

  late _FakeFactory factory;
  late _FakeCredStore creds;
  late _FakeWorkspaceSettings settings;
  late _FakeConversations conversations;
  late _FakeMessaging messaging;

  setUp(() {
    factory = _FakeFactory();
    creds = _FakeCredStore();
    settings = _FakeWorkspaceSettings();
    conversations = _FakeConversations();
    messaging = _FakeMessaging();
  });

  ConversationTitleService runner() => ConversationTitleService(
    runner: AdapterOneShotRunner(credentials: creds, factory: factory),
    settings: settings,
    conversationRepo: conversations,
    messagingRepo: messaging,
  );

  /// Points the workspace at the built-in harness on [model] — the adapter is
  /// what switches titling on, so every generating test must set it.
  void useHarness([String model = 'anthropic/x']) {
    settings.values[kConversationTitleAdapterSettingKey] = 'cc-harness';
    settings.values[kConversationTitleModelSettingKey] = model;
  }

  Conversation conversationWithTitle(String title) => Conversation(
    id: 'conv-1',
    workspaceId: workspaceId,
    spaceId: spaceId,
    title: title,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );

  Message humanMessage(String content) => Message(
    id: 'm1',
    spaceId: spaceId,
    conversationId: 'conv-1',
    senderId: userId,
    senderType: SenderType.user,
    content: content,
    messageType: MessageType.text,
    createdAt: DateTime(2026, 1, 1),
  );

  Future<void> send({String? conversationId = 'conv-1'}) =>
      runner().maybeGenerate(
        workspaceId: workspaceId,
        spaceId: spaceId,
        conversationId: conversationId,
      );

  test('no workspace setting → off: no LLM call, no rename', () async {
    conversations.put(conversationWithTitle('Control Center dev'));
    messaging.messages = [humanMessage('How do I rebase?')];
    factory.reply = 'Git rebase question';

    await send();

    expect(factory.calls, isEmpty);
    expect(conversations.renames, isEmpty);
  });

  test('empty adapter setting → off', () async {
    settings.values[kConversationTitleAdapterSettingKey] = '  ';
    settings.values[kConversationTitleModelSettingKey] = 'anthropic/x';
    conversations.put(conversationWithTitle(''));
    messaging.messages = [humanMessage('How do I rebase?')];

    await send();

    expect(factory.calls, isEmpty);
    expect(conversations.renames, isEmpty);
  });

  test('a model with no adapter is not a runner → off', () async {
    settings.values[kConversationTitleModelSettingKey] = 'anthropic/x';
    conversations.put(conversationWithTitle(''));
    messaging.messages = [humanMessage('How do I rebase?')];

    await send();

    expect(factory.calls, isEmpty);
    expect(conversations.renames, isEmpty);
  });

  test('adapter with no model → runs on the provider default', () async {
    settings.values[kConversationTitleAdapterSettingKey] = 'cc-harness';
    conversations.put(conversationWithTitle(''));
    messaging.messages = [humanMessage('How do I rebase?')];
    factory.reply = 'Git rebase question';

    await send();

    // parseModel(null) defaults the provider and leaves the model unset, so
    // the provider picks its own — an adapter alone is a complete runner.
    expect(factory.calls.single.providerId, 'anthropic');
    expect(factory.calls.single.model, isNull);
    expect(conversations.renames, hasLength(1));
  });

  test(
    'unknown adapter id → skipped, never a silent harness fallback',
    () async {
      settings.values[kConversationTitleAdapterSettingKey] = 'not-an-adapter';
      settings.values[kConversationTitleModelSettingKey] = 'anthropic/x';
      conversations.put(conversationWithTitle(''));
      messaging.messages = [humanMessage('How do I rebase?')];
      factory.reply = 'Git rebase question';

      await send();

      expect(factory.calls, isEmpty);
      expect(conversations.renames, isEmpty);
    },
  );

  test(
    'a title equal to the space name is treated as authored → left alone',
    () async {
      // The legacy space-name mint rule is gone: nothing produces such a
      // title automatically any more, so a non-empty title — even one
      // matching the space — reads as human-written and is never clobbered.
      useHarness('anthropic/claude-haiku-4-5');
      conversations.put(conversationWithTitle('Control Center dev'));
      messaging.messages = [humanMessage('How do I rebase onto main?')];
      factory.reply = 'Git rebase question';

      await send();

      expect(factory.calls, isEmpty);
      expect(conversations.renames, isEmpty);
    },
  );

  test('empty title is a default → renamed', () async {
    useHarness('openai/gpt-4o-mini');
    conversations.put(conversationWithTitle(''));
    messaging.messages = [humanMessage('Installing packages via pip')];
    factory.reply = 'Installing Python packages';

    await send();

    expect(factory.calls.single.providerId, 'openai');
    expect(factory.calls.single.model, 'gpt-4o-mini');
    expect(conversations.renames.single, (
      conversationId: 'conv-1',
      title: 'Installing Python packages',
    ));
  });

  test(
    "'Main' and 'Conversation' are legacy titles nothing mints → left alone",
    () async {
      useHarness('anthropic/x');
      factory.reply = 'T';
      for (final title in const ['Main', 'Conversation']) {
        conversations.reset();
        conversations.put(conversationWithTitle(title));
        messaging.messages = [humanMessage('hi')];

        await send();

        expect(factory.calls, isEmpty, reason: title);
        expect(conversations.renames, isEmpty, reason: title);
      }
    },
  );

  test('human-typed title is never renamed', () async {
    useHarness('anthropic/x');
    conversations.put(conversationWithTitle('My deploy checklist'));
    messaging.messages = [humanMessage('How do I rebase?')];
    factory.reply = 'Git rebase question';

    await send();

    expect(factory.calls, isEmpty);
    expect(conversations.renames, isEmpty);
  });

  test('already-generated title is not regenerated', () async {
    useHarness('anthropic/x');
    conversations.put(conversationWithTitle('Git rebase question'));
    messaging.messages = [humanMessage('More rebase trouble')];
    factory.reply = 'Rebase trouble again';

    await send();

    expect(conversations.renames, isEmpty);
  });

  test('no credential for the provider → skips quietly', () async {
    useHarness('anthropic/x');
    creds.credential = null;
    conversations.put(conversationWithTitle(''));
    messaging.messages = [humanMessage('hi')];

    await send();

    expect(factory.calls, isEmpty);
    expect(conversations.renames, isEmpty);
  });

  test('quotes, newlines and trailing period are stripped', () async {
    useHarness('anthropic/x');
    conversations.put(conversationWithTitle(''));
    messaging.messages = [humanMessage('hi')];
    factory.reply = '  "Git   rebase\nquestion."  ';

    await send();

    expect(conversations.renames.single.title, 'Git rebase question');
  });

  test('over-long reply is capped on a word boundary', () async {
    useHarness('anthropic/x');
    conversations.put(conversationWithTitle(''));
    messaging.messages = [humanMessage('hi')];
    final words = List.generate(40, (i) => 'word$i');
    factory.reply = words.join(' ');

    await send();

    final title = conversations.renames.single.title;
    expect(title.length, lessThanOrEqualTo(80));
    expect(title.endsWith(' '), isFalse);
  });

  test("refusal reply ('Sorry, I can…') → no rename", () async {
    useHarness('anthropic/x');
    conversations.put(conversationWithTitle(''));
    messaging.messages = [humanMessage('hi')];
    factory.reply = "Sorry, I can't assist with that.";

    await send();

    expect(conversations.renames, isEmpty);
  });

  test('conversation with no human message → skips', () async {
    useHarness('anthropic/x');
    conversations.put(conversationWithTitle(''));
    messaging.messages = const [];

    await send();

    expect(factory.calls, isEmpty);
  });

  test(
    'title renamed while the model ran → race guard keeps the new title',
    () async {
      useHarness('anthropic/x');
      final conv = conversationWithTitle('');
      conversations.put(conv);
      messaging.messages = [humanMessage('hi')];
      factory.reply = 'Model title';
      // The second getById (the re-check after the completion) sees a human
      // rename that landed meanwhile.
      conversations.getByIdResults = [conv, conversationWithTitle('Human won')];

      await send();

      expect(conversations.renames, isEmpty);
    },
  );

  test('provider streams LlmError → fail-open, never throws', () async {
    useHarness('anthropic/x');
    conversations.put(conversationWithTitle(''));
    messaging.messages = [humanMessage('hi')];
    factory.error = const LlmError('boom');

    await send();

    expect(conversations.renames, isEmpty);
  });

  test(
    'null conversationId resolves the standing conversation via ensure',
    () async {
      useHarness('anthropic/x');
      final standing = conversationWithTitle('');
      conversations.standing = standing;
      conversations.put(standing);
      messaging.messages = [humanMessage('How do I rebase?')];
      factory.reply = 'Git rebase question';

      await send(conversationId: null);

      expect(conversations.ensures, hasLength(1));
      expect(conversations.renames.single, (
        conversationId: standing.id,
        title: 'Git rebase question',
      ));
    },
  );

  test('system prompt is the agreed titling prompt', () async {
    useHarness('anthropic/x');
    conversations.put(conversationWithTitle(''));
    messaging.messages = [humanMessage('hi')];
    factory.reply = 'T';

    await send();

    final system = factory.calls.single.config.systemPrompt;
    expect(system, contains('pithy titles for chatbot conversations'));
    expect(system, contains('- Git rebase question'));
    expect(system, contains("Sorry, I can't assist with that."));
  });
}

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class _Call {
  _Call(this.providerId, this.model, this.prompt, this.config);
  final String providerId;
  final String? model;
  final String prompt;
  final LlmCompleteConfig config;
}

/// A [HarnessProviderFactory] recording every create() and returning a
/// provider that streams one canned reply (or a canned error).
class _FakeFactory extends HarnessProviderFactory {
  String reply = '';
  LlmError? error;

  final List<_Call> calls = [];

  @override
  LlmProviderPort create({
    required String providerId,
    String? model,
    ProviderCredential? credential,
    ProviderTokenResolver? tokenResolver,
  }) {
    final events = <LlmEvent>[
      if (error != null) error! else LlmTextDelta(reply),
    ];
    return _RecordingProvider(providerId, model, calls, events);
  }
}

class _RecordingProvider implements LlmProviderPort {
  _RecordingProvider(this.providerId, this.model, this.calls, this.events);

  final String providerId;
  final String? model;
  final List<_Call> calls;
  final List<LlmEvent> events;

  @override
  Stream<LlmEvent> complete({
    required List<HarnessMessage> messages,
    List<LlmToolSchema> tools = const [],
    LlmCompleteConfig config = const LlmCompleteConfig(),
  }) async* {
    calls.add(_Call(providerId, model, messages.first.textContent, config));
    for (final e in events) {
      yield e;
    }
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

class _FakeCredStore implements ProviderCredentialStore {
  ProviderCredential? credential = const ProviderCredential(
    providerId: 'anthropic',
    method: HarnessAuthMethod.apiKey,
    apiKey: 'k',
  );

  @override
  Future<ProviderCredential?> activeCredential(String providerId) async =>
      credential;

  @override
  dynamic noSuchMethod(Invocation invocation) {}
}

class _FakeWorkspaceSettings implements WorkspaceSettingsRepository {
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

  @override
  dynamic noSuchMethod(Invocation invocation) {}
}

class _FakeConversations implements ConversationRepository {
  final Map<String, Conversation> _byId = {};
  final List<({String conversationId, String title})> renames = [];
  final List<String> ensures = [];

  /// When set, [getById] pops from this queue instead of the map — simulates
  /// the title changing between the pre-check and the post-completion
  /// re-check.
  List<Conversation>? getByIdResults;

  Conversation? standing;

  void put(Conversation c) => _byId[c.id] = c;

  void reset() {
    _byId.clear();
    renames.clear();
    ensures.clear();
    getByIdResults = null;
  }

  @override
  Future<Conversation?> getById({
    required String workspaceId,
    required String conversationId,
  }) async {
    final q = getByIdResults;
    if (q != null && q.isNotEmpty) {
      return q.removeAt(0);
    }
    return _byId[conversationId];
  }

  @override
  Future<Conversation> ensure({
    required String workspaceId,
    required String spaceId,
  }) async {
    ensures.add(spaceId);
    final s = standing;
    if (s != null) {
      return s;
    }
    throw StateError('no standing conversation configured');
  }

  @override
  Future<void> rename({
    required String workspaceId,
    required String conversationId,
    required String title,
  }) async {
    renames.add((conversationId: conversationId, title: title));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {}
}

class _FakeMessaging implements MessagingRepository {
  List<Message> messages = const [];

  @override
  Future<List<Message>> getMessages(
    String workspaceId,
    String spaceId, {
    String? conversationId,
  }) async => messages;

  @override
  dynamic noSuchMethod(Invocation invocation) {}

  /// The tree is not exercised by this fake — a branch it silently accepted
  /// would be a pointer move nothing could observe, so it refuses instead.
  @override
  Future<ConversationTree> conversationTree({
    required String workspaceId,
    required String conversationId,
  }) async => throw UnimplementedError();

  @override
  Future<void> branchConversationAt({
    required String workspaceId,
    required String conversationId,
    required String messageId,
  }) async => throw UnimplementedError();

  @override
  Future<String> forkConversation({
    required String workspaceId,
    required String spaceId,
    required String conversationId,
    String? messageId,
    String? title,
  }) async => throw UnimplementedError();
}
