import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/core/domain/ports/credential_broker_port.dart';
import 'package:cc_domain/core/domain/ports/sandbox_port.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_backend.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_event.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_handle.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_spec.dart';
import 'package:cc_domain/features/dispatch/domain/entities/agent_process_event.dart';
import 'package:cc_domain/features/dispatch/domain/ports/agent_backend.dart';
import 'package:cc_domain/features/dispatch/domain/prompts/prompt_builder.dart';
import 'package:cc_harness/loop.dart';
import 'package:cc_harness/messages.dart';
import 'package:cc_harness/provider.dart';
import 'package:cc_infra/src/dispatch/backends/harness_backend.dart';
import 'package:cc_infra/src/dispatch/dispatch_session.dart';
import 'package:cc_infra/src/harness/file_transcript_store.dart';
import 'package:test/test.dart';

import '../helpers/windows_safe_delete.dart';

class _Sandbox implements SandboxPort {
  @override
  SandboxBackend get backend => SandboxBackend.none;
  @override
  Stream<SandboxEvent> events(SandboxHandle handle) => const Stream.empty();
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Broker implements CredentialBrokerPort {
  @override
  Future<ScopedCredentials> mint({
    required String conversationId,
    required ForgeTokenScope scope,
    String? repoOwner,
    String? repoName,
    String? actingUserId,
    String? workspaceId,
  }) async => const ScopedCredentials(handle: 'test', environment: {});
  @override
  Future<void> revoke(String handle) async {}
}

class _Agents implements AgentRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Credentials implements ProviderCredentialStore {
  _Credentials(this.url);
  final String url;
  @override
  Future<ProviderCredential?> activeCredential(String providerId) async =>
      ProviderCredential(
        providerId: providerId,
        method: HarnessAuthMethod.none,
        baseUrl: url,
      );
  @override
  Future<List<ProviderCredential>> credentialsFor(String providerId) async => [
    (await activeCredential(providerId))!,
  ];
  @override
  Future<void> save(ProviderCredential credential) async {}
  @override
  Future<void> remove(
    String providerId, {
    String? accountLabel,
    String? credentialId,
  }) async {}
}

AgentPromptParts _parts(
  String message,
  List<PromptConversationEntry> entries, {
  String standing = 'standing-one',
}) {
  const memory = 'memory-exact-requirement';
  final conversation = entries.map((entry) => entry.text).join('\n');
  return AgentPromptParts(
    userText: message,
    standing: standing,
    standingRevision: standing,
    turnContext: memory,
    conversationContext: conversation,
    fullPrompt: '$standing\n$memory\n$conversation\n$message',
    conversationEntries: entries,
    turnSections: const [PromptTurnSection(key: 'memory:1', text: memory)],
  );
}

PromptConversationEntry _entry(String key, String text, {String? runId}) =>
    PromptConversationEntry(
      key: key,
      text: text,
      runId: runId,
      provenance: runId == null
          ? PromptConversationProvenance.other
          : PromptConversationProvenance.self,
    );

void main() {
  late Directory root;
  late HttpServer server;
  late List<Map<String, dynamic>> requests;
  late int runNumber;

  FileHarnessTranscriptStore store() =>
      FileHarnessTranscriptStore(workspaceDir: (_) => root.path);
  final key = FileHarnessTranscriptStore.keyFor(
    workspaceId: 'ws',
    conversationId: 'conversation',
    agentId: 'agent',
  );

  setUp(() async {
    root = await Directory.systemTemp.createTemp('cc-harness-resume-');
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    requests = [];
    runNumber = 0;
    server.listen((request) async {
      final body =
          jsonDecode(await utf8.decoder.bind(request).join())
              as Map<String, dynamic>;
      requests.add(body);
      request.response.headers.contentType = ContentType(
        'text',
        'event-stream',
      );
      request.response.write(
        'data: ${jsonEncode({
          'choices': [
            {
              'delta': {'content': 'Completed verified response.'},
              'finish_reason': null,
            },
          ],
        })}\n\n',
      );
      request.response.write(
        'data: ${jsonEncode({
          'choices': [
            {'delta': {}, 'finish_reason': 'stop'},
          ],
          'usage': {'prompt_tokens': 20, 'completion_tokens': 5},
        })}\n\ndata: [DONE]\n\n',
      );
      await request.response.close();
    });
  });

  tearDown(() async {
    await server.close(force: true);
    await deleteDirBestEffort(root);
  });

  Future<String> run(AgentPromptParts parts) async {
    runNumber++;
    final session = DispatchSession(
      deps: SandboxDispatchDeps(
        sandbox: _Sandbox(),
        broker: _Broker(),
        agentRepo: _Agents(),
        runLogRepo: null,
        eventBus: null,
        backendRegistry: BackendRegistry({
          'cc-harness': const HarnessBackend(),
        }),
        harnessCredentialStore: _Credentials(
          'http://127.0.0.1:${server.port}/v1',
        ),
        transcriptStore: store(),
      ),
      onResolveHandle:
          ({
            required String sessionId,
            required SandboxSpec spec,
            required void Function(AgentProcessEvent) emit,
          }) async => SandboxHandle(
            sessionId: sessionId,
            backend: SandboxBackend.none,
            state: SandboxState.warm,
          ),
      onScheduleCooldown: (_) {},
      dispatchId: 'dispatch-$runNumber',
      cliName: 'cc-harness',
      prompt: parts.fullPrompt,
      userText: parts.userText,
      promptParts: parts,
      agentDirHostPath: root.path,
      modelId: 'openai/test-model',
      callerEnv: const {},
      agentId: 'agent',
      workspaceId: 'ws',
      conversationId: 'conversation',
      runLogId: 'run-$runNumber',
      mode: Mode.chat,
    );
    final events = <AgentProcessEvent>[];
    final subscription = session.controller.stream.listen(events.add);
    await session.run().timeout(const Duration(seconds: 15));
    await subscription.cancel();
    expect(events.whereType<ErrorEvent>(), isEmpty);
    final messages = requests.last['messages'] as List;
    final user = messages.cast<Map>().lastWhere(
      (message) => message['role'] == 'user',
    );
    return jsonEncode(user['content']);
  }

  test(
    'fresh input retains assembled context; restarted sessions deliver only new or edited entries',
    () async {
      final old = _entry('peer:1#old', 'peer-old-observation');
      final first = await run(_parts('first-question', [old]));
      expect(first, contains('standing-one'));
      expect(first, contains('memory-exact-requirement'));
      expect(first, contains('peer-old-observation'));

      final own = _entry('self:1#one', 'own-native-output', runId: 'run-1');
      final parked = _entry(
        'self:2#two',
        'output-produced-in-another-session',
        runId: 'parked-run',
      );
      final fresh = _entry('peer:2#one', 'new-peer-observation');
      final second = await run(
        _parts('second-question', [old, own, parked, fresh]),
      );
      expect(second, contains('new-peer-observation'));
      expect(second, contains('output-produced-in-another-session'));
      expect(second, isNot(contains('peer-old-observation')));
      expect(second, isNot(contains('own-native-output')));
      expect(second, isNot(contains('memory-exact-requirement')));
      expect(second, isNot(contains('standing-one')));

      final edited = _entry('peer:2#edited', 'edited-peer-observation');
      final third = await run(
        _parts('third-question', [old, own, parked, edited]),
      );
      expect(third, contains('edited-peer-observation'));
      expect(third, isNot(contains('output-produced-in-another-session')));
    },
  );

  test(
    'legacy transcript and changed standing instructions cannot lose full context',
    () async {
      await store().save(
        key,
        HarnessTranscript(
          messages: [
            HarnessMessage.user('legacy-history'),
            HarnessMessage.assistant('legacy-answer'),
          ],
        ),
      );
      final entries = [_entry('peer:1', 'must-deliver-peer-context')];
      final legacy = await run(_parts('legacy-followup', entries));
      expect(legacy, contains('must-deliver-peer-context'));
      expect(legacy, contains('memory-exact-requirement'));
      final changed = await run(
        _parts(
          'new-brief-question',
          entries,
          standing: 'new-standing-constraint',
        ),
      );
      expect(changed, contains('new-standing-constraint'));
      final stable = await run(
        _parts(
          'same-brief-question',
          entries,
          standing: 'new-standing-constraint',
        ),
      );
      expect(stable, isNot(contains('new-standing-constraint')));
    },
  );
}
