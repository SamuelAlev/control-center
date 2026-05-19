import 'package:control_center/core/domain/ports/conversation_mode_resolver.dart';
import 'package:control_center/core/domain/value_objects/conversation_mode.dart';
import 'package:control_center/features/mcp/domain/services/conversation_mode_tool_guard.dart';
import 'package:flutter_test/flutter_test.dart';

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
        await guard.rejectIfDisallowed('create_workspace', 'ch-chat'),
        isNull,
      );
      expect(
        await guard.rejectIfDisallowed('add_review_node', 'ch-chat'),
        isNull,
      );
    });

    test('review mode lets review-safe tools through', () async {
      final guard = ConversationModeToolGuard(
        _FakeResolver(ConversationMode.review),
      );
      expect(
        await guard.rejectIfDisallowed('add_review_node', 'ch-review'),
        isNull,
      );
      expect(
        await guard.rejectIfDisallowed('finalize_review', 'ch-review'),
        isNull,
      );
      expect(
        await guard.rejectIfDisallowed('create_ticket', 'ch-review'),
        isNull,
      );
    });

    test('review mode blocks mutating tools', () async {
      final guard = ConversationModeToolGuard(
        _FakeResolver(ConversationMode.review),
      );
      final rejection = await guard.rejectIfDisallowed(
        'create_workspace',
        'ch-review',
      );
      expect(rejection, isNotNull);
      expect(rejection, contains('review-mode'));
    });

    test('plan mode allows read + comms, blocks tickets', () async {
      final guard = ConversationModeToolGuard(
        _FakeResolver(ConversationMode.plan),
      );
      expect(
        await guard.rejectIfDisallowed('send_channel_message', 'ch-plan'),
        isNull,
      );
      expect(
        await guard.rejectIfDisallowed('search_memory', 'ch-plan'),
        isNull,
      );
      final rejection = await guard.rejectIfDisallowed(
        'create_ticket',
        'ch-plan',
      );
      expect(rejection, isNotNull);
      expect(rejection, contains('plan-mode'));
    });

    test('null channel_id bypasses guard regardless of mode', () async {
      final guard = ConversationModeToolGuard(
        _FakeResolver(ConversationMode.review),
      );
      expect(
        await guard.rejectIfDisallowed('create_workspace', null),
        isNull,
      );
    });
  });
}
