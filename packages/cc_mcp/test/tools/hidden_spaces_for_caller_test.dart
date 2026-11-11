import 'package:cc_domain/features/mcp/domain/value_objects/mcp_call_scope.dart';
import 'package:cc_mcp/src/tools/hidden_spaces_for_caller.dart';
import 'package:test/test.dart';

void main() {
  test('reads the attested caller, ignoring an empty one', () {
    expect(
      callerConversationOf({McpCallScope.callerConversationKey: 'conv-1'}),
      'conv-1',
    );
    expect(
      callerConversationOf({McpCallScope.callerConversationKey: ''}),
      isNull,
    );
    expect(callerConversationOf(const {}), isNull);
  });

  test('a space is hidden when the caller\'s set names it', () async {
    String? askedFor;
    Future<Set<String>> hidden({
      required String workspaceId,
      required String? callerConversationId,
    }) async {
      askedFor = callerConversationId;
      return {'space-review'};
    }

    final args = {McpCallScope.callerConversationKey: 'conv-1'};
    expect(
      await isSpaceHiddenFromCaller(
        hidden,
        args,
        workspaceId: 'ws',
        spaceId: 'space-review',
      ),
      isTrue,
    );
    expect(askedFor, 'conv-1');
    expect(
      await isSpaceHiddenFromCaller(
        hidden,
        args,
        workspaceId: 'ws',
        spaceId: 'space-general',
      ),
      isFalse,
    );
  });
}
