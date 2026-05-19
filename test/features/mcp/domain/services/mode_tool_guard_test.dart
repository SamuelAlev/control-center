import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/ports/mode_resolver.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/features/mcp/domain/services/mode_tool_guard.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../fakes/fake_agent_run_log_repository.dart';

/// The workspace every fixture below operates in.
const _wsId = 'ws-1';

/// Resolves one mode, and only inside the workspace that owns the conversation.
///
/// A conversation id from another workspace lives in another database file, so
/// it resolves to the safe default ([Mode.chat]) rather than this workspace's
/// mode — the guard must not be escapable by naming a foreign channel.
class _FakeResolver implements ModeResolver {
  _FakeResolver(this._mode);
  final Mode _mode;

  @override
  Future<Mode> resolveForConversation(
    String workspaceId,
    String? conversationId,
  ) async {
    if (conversationId == null || workspaceId != _wsId) {
      return Mode.chat;
    }
    return _mode;
  }
}

void main() {
  group('ModeToolGuard', () {
    test('chat mode lets all tools through', () async {
      final guard = ModeToolGuard(_FakeResolver(Mode.chat));
      expect(
        await guard.rejectIfDisallowed(
          'create_workspace',
          workspaceId: _wsId,
          channelId: 'ch-chat',
        ),
        isNull,
      );
      expect(
        await guard.rejectIfDisallowed(
          'add_review_node',
          workspaceId: _wsId,
          channelId: 'ch-chat',
        ),
        isNull,
      );
    });

    test('review mode lets review-safe tools through', () async {
      final guard = ModeToolGuard(_FakeResolver(Mode.review));
      expect(
        await guard.rejectIfDisallowed(
          'add_review_node',
          workspaceId: _wsId,
          channelId: 'ch-review',
        ),
        isNull,
      );
      expect(
        await guard.rejectIfDisallowed(
          'finalize_review',
          workspaceId: _wsId,
          channelId: 'ch-review',
        ),
        isNull,
      );
      expect(
        await guard.rejectIfDisallowed(
          'create_ticket',
          workspaceId: _wsId,
          channelId: 'ch-review',
        ),
        isNull,
      );
    });

    test('review mode allows ticket completion and memory writes', () async {
      final guard = ModeToolGuard(_FakeResolver(Mode.review));
      // Pipeline agents run in review mode and must close out their tickets.
      expect(
        await guard.rejectIfDisallowed(
          'close_ticket',
          workspaceId: _wsId,
          channelId: 'ch-review',
        ),
        isNull,
      );
      expect(
        await guard.rejectIfDisallowed(
          'submit_output',
          workspaceId: _wsId,
          channelId: 'ch-review',
        ),
        isNull,
      );
      expect(
        await guard.rejectIfDisallowed(
          'fail_ticket',
          workspaceId: _wsId,
          channelId: 'ch-review',
        ),
        isNull,
      );
      // Knowledge contribution is never blocked by mode.
      expect(
        await guard.rejectIfDisallowed(
          'propose_fact',
          workspaceId: _wsId,
          channelId: 'ch-review',
        ),
        isNull,
      );
      expect(
        await guard.rejectIfDisallowed(
          'propose_policy',
          workspaceId: _wsId,
          channelId: 'ch-review',
        ),
        isNull,
      );
    });

    test('run-mechanics tools work in every non-chat mode', () async {
      // search_tool_bm25 is read-only catalogue discovery and todo_write is
      // how agents plan multi-step work — blocking them in review/plan mode
      // broke pipeline agents (librarian) and planning agents outright.
      for (final mode in [Mode.review, Mode.plan, Mode.orchestrate]) {
        final guard = ModeToolGuard(_FakeResolver(mode));
        expect(
          await guard.rejectIfDisallowed(
            'search_tool_bm25',
            workspaceId: _wsId,
            channelId: 'ch',
          ),
          isNull,
          reason: 'search_tool_bm25 in $mode',
        );
        // The authoritative "what can I call" introspection is read-only and
        // must never be gated — it is how an agent learns its restrictions.
        expect(
          await guard.rejectIfDisallowed(
            'list_my_tools',
            workspaceId: _wsId,
            channelId: 'ch',
          ),
          isNull,
          reason: 'list_my_tools in $mode',
        );
        expect(
          await guard.rejectIfDisallowed(
            'todo_write',
            workspaceId: _wsId,
            channelId: 'ch',
          ),
          isNull,
          reason: 'todo_write in $mode',
        );
      }
    });

    test('the typed ticket-edit tool is allowed in review and plan, blocked in '
        'orchestrate', () async {
      for (final mode in [Mode.review, Mode.plan]) {
        final guard = ModeToolGuard(_FakeResolver(mode));
        expect(
          await guard.rejectIfDisallowed(
            'update_ticket',
            workspaceId: _wsId,
            channelId: 'ch',
          ),
          isNull,
          reason: 'update_ticket in $mode',
        );
      }
      final orchestrate = ModeToolGuard(_FakeResolver(Mode.orchestrate));
      expect(
        await orchestrate.rejectIfDisallowed(
          'update_ticket',
          workspaceId: _wsId,
          channelId: 'ch',
        ),
        isNotNull,
        reason: 'orchestrators propose; ticket mutations happen post-approval',
      );
    });

    test('review mode blocks mutating tools', () async {
      final guard = ModeToolGuard(_FakeResolver(Mode.review));
      final rejection = await guard.rejectIfDisallowed(
        'create_workspace',
        workspaceId: _wsId,
        channelId: 'ch-review',
      );
      expect(rejection, isNotNull);
      expect(rejection, contains('review-mode'));
    });

    test(
      'plan mode allows read + comms + memory, blocks ticket creation',
      () async {
        final guard = ModeToolGuard(_FakeResolver(Mode.plan));
        expect(
          await guard.rejectIfDisallowed(
            'send_channel_message',
            workspaceId: _wsId,
            channelId: 'ch-plan',
          ),
          isNull,
        );
        expect(
          await guard.rejectIfDisallowed(
            'search_memory',
            workspaceId: _wsId,
            channelId: 'ch-plan',
          ),
          isNull,
        );
        expect(
          await guard.rejectIfDisallowed(
            'propose_fact',
            workspaceId: _wsId,
            channelId: 'ch-plan',
          ),
          isNull,
        );
        final rejection = await guard.rejectIfDisallowed(
          'create_ticket',
          workspaceId: _wsId,
          channelId: 'ch-plan',
        );
        expect(rejection, isNotNull);
        expect(rejection, contains('plan-mode'));
      },
    );

    test('null channel_id with no agent bypasses guard', () async {
      final guard = ModeToolGuard(_FakeResolver(Mode.review));
      expect(
        await guard.rejectIfDisallowed('create_workspace', workspaceId: _wsId),
        isNull,
      );
    });

    test(
      'omitting channel_id does NOT escape mode — resolves via agent run',
      () async {
        final runLogs = FakeAgentRunLogRepository()
          ..seed(
            AgentRunLog(
              id: 'run-1',
              agentId: 'agent-1',
              workspaceId: _wsId,
              conversationId: 'ch-review',
              startedAt: DateTime(2026),
              status: RunStatus.running,
            ),
          );
        final guard = ModeToolGuard(
          _FakeResolver(Mode.review),
          runLogs: runLogs,
        );
        final rejection = await guard.rejectIfDisallowed(
          'create_workspace',
          workspaceId: _wsId,
          agentId: 'agent-1',
        );
        expect(rejection, isNotNull);
        expect(rejection, contains('review-mode'));
      },
    );

    test('an agent run in another workspace resolves no mode', () async {
      // The run exists, but in a different workspace's database file, so the
      // agent id supplies no conversation to scope to here.
      final runLogs = FakeAgentRunLogRepository()
        ..seed(
          AgentRunLog(
            id: 'run-1',
            agentId: 'agent-1',
            workspaceId: 'ws-2',
            conversationId: 'ch-review',
            startedAt: DateTime(2026),
            status: RunStatus.running,
          ),
        );
      final guard = ModeToolGuard(_FakeResolver(Mode.review), runLogs: runLogs);
      expect(
        await guard.resolveMode(workspaceId: _wsId, agentId: 'agent-1'),
        isNull,
      );
    });

    test("a foreign channel id does not carry its workspace's mode", () async {
      // The resolver only knows ws-1's channels; asking for ws-2 falls back to
      // the safe default rather than leaking ws-1's restriction (or exemption).
      final guard = ModeToolGuard(_FakeResolver(Mode.review));
      expect(
        await guard.resolveMode(workspaceId: 'ws-2', channelId: 'ch-review'),
        Mode.chat,
      );
    });
  });
}
