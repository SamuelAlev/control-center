import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/ports/conversation_mode_resolver.dart';
import 'package:cc_domain/core/domain/value_objects/conversation_mode.dart';
import 'package:cc_domain/features/mcp/domain/services/conversation_mode_tool_guard.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../fakes/fake_agent_run_log_repository.dart';

class _FakeResolver implements ConversationModeResolver {
  _FakeResolver(this._mode);
  final ConversationMode _mode;

  @override
  Future<ConversationMode> resolveForConversation(String? conversationId) async {
    if (conversationId == null) {
      return ConversationMode.chat;
    }
    return _mode;
  }
}

void main() {
  group('ConversationModeToolGuard', () {
    test('chat mode lets all tools through', () async {
      final guard = ConversationModeToolGuard(
        _FakeResolver(ConversationMode.chat),
      );
      expect(
        await guard.rejectIfDisallowed('create_workspace', channelId: 'ch-chat'),
        isNull,
      );
      expect(
        await guard.rejectIfDisallowed('add_review_node', channelId: 'ch-chat'),
        isNull,
      );
    });

    test('review mode lets review-safe tools through', () async {
      final guard = ConversationModeToolGuard(
        _FakeResolver(ConversationMode.review),
      );
      expect(
        await guard.rejectIfDisallowed('add_review_node', channelId: 'ch-review'),
        isNull,
      );
      expect(
        await guard.rejectIfDisallowed('finalize_review', channelId: 'ch-review'),
        isNull,
      );
      expect(
        await guard.rejectIfDisallowed('create_ticket', channelId: 'ch-review'),
        isNull,
      );
    });

    test('review mode allows ticket completion and memory writes', () async {
      final guard = ConversationModeToolGuard(
        _FakeResolver(ConversationMode.review),
      );
      // Pipeline agents run in review mode and must close out their tickets.
      expect(
        await guard.rejectIfDisallowed('complete_ticket', channelId: 'ch-review'),
        isNull,
      );
      expect(
        await guard.rejectIfDisallowed('fail_ticket', channelId: 'ch-review'),
        isNull,
      );
      // Knowledge contribution is never blocked by mode.
      expect(
        await guard.rejectIfDisallowed('propose_fact', channelId: 'ch-review'),
        isNull,
      );
      expect(
        await guard.rejectIfDisallowed('propose_policy', channelId: 'ch-review'),
        isNull,
      );
    });

    test('review mode blocks mutating tools', () async {
      final guard = ConversationModeToolGuard(
        _FakeResolver(ConversationMode.review),
      );
      final rejection = await guard.rejectIfDisallowed(
        'create_workspace',
        channelId: 'ch-review',
      );
      expect(rejection, isNotNull);
      expect(rejection, contains('review-mode'));
    });

    test('plan mode allows read + comms + memory, blocks ticket creation',
        () async {
      final guard = ConversationModeToolGuard(
        _FakeResolver(ConversationMode.plan),
      );
      expect(
        await guard.rejectIfDisallowed('send_channel_message',
            channelId: 'ch-plan'),
        isNull,
      );
      expect(
        await guard.rejectIfDisallowed('search_memory', channelId: 'ch-plan'),
        isNull,
      );
      expect(
        await guard.rejectIfDisallowed('propose_fact', channelId: 'ch-plan'),
        isNull,
      );
      final rejection = await guard.rejectIfDisallowed(
        'create_ticket',
        channelId: 'ch-plan',
      );
      expect(rejection, isNotNull);
      expect(rejection, contains('plan-mode'));
    });

    test('null channel_id with no agent bypasses guard', () async {
      final guard = ConversationModeToolGuard(
        _FakeResolver(ConversationMode.review),
      );
      expect(
        await guard.rejectIfDisallowed('create_workspace'),
        isNull,
      );
    });

    test('omitting channel_id does NOT escape mode — resolves via agent run',
        () async {
      final runLogs = FakeAgentRunLogRepository()
        ..seed(
          AgentRunLog(
            id: 'run-1',
            agentId: 'agent-1',
            workspaceId: 'ws-1',
            conversationId: 'ch-review',
            startedAt: DateTime(2026),
            status: RunStatus.running,
          ),
        );
      final guard = ConversationModeToolGuard(
        _FakeResolver(ConversationMode.review),
        runLogs: runLogs,
      );
      final rejection = await guard.rejectIfDisallowed(
        'create_workspace',
        agentId: 'agent-1',
      );
      expect(rejection, isNotNull);
      expect(rejection, contains('review-mode'));
    });
  });
}
