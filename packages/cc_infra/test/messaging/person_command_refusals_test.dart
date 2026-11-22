import 'package:cc_domain/cc_domain.dart'
    show GoalAlreadyActiveException, ValidationException;
import 'package:cc_infra/cc_infra.dart';
import 'package:test/test.dart';

/// A refused person command is one typed system row: the plain English
/// refusal as its text, and `kind: command_refused`, `refusalKind` (the
/// refusal's `data.kind`) and `command` (the command word) as its metadata,
/// the fields the client's `command_refused` row reads.
void main() {
  final rows = <({String text, Map<String, Object?> metadata})>[];

  setUp(rows.clear);

  Future<void> send(String prompt, Object refusal) => startGoalFromMessage(
    ({
      required workspaceId,
      required spaceId,
      required agentId,
      required prompt,
      required requestedByUserId,
      conversationId,
    }) async => throw refusal,
    workspaceId: 'ws-1',
    spaceId: 'sp-1',
    agentId: 'agent-1',
    prompt: prompt,
    requestedByUserId: 'user-1',
    conversationId: 'conv-1',
    say: (text, metadata) async => rows.add((text: text, metadata: metadata)),
  );

  for (final (prompt, word) in [
    ('/goal ship it', 'goal'),
    ('/loop 20m check the build', 'loop'),
    ('/schedule tomorrow 9:00 standup', 'schedule'),
    ('/refine', 'refine'),
    ('/refine the last run', 'refine'),
  ]) {
    test('$prompt refused: one row with its kind and the word $word', () async {
      await send(
        prompt,
        const ValidationException('That does not read.', code: 'some_kind'),
      );
      expect(rows.single.text, 'That does not read.');
      expect(rows.single.metadata, {
        'kind': 'command_refused',
        'refusalKind': 'some_kind',
        'command': word,
      });
    });
  }

  test('the kind is the refusal exception\'s own data.kind', () async {
    await send(
      '/goal two',
      const GoalAlreadyActiveException(workspaceId: 'ws-1', agentId: 'a'),
    );
    expect(rows.single.metadata['refusalKind'], 'goal_already_active');
    expect(rows.single.metadata['command'], 'goal');
  });

  test(
    'a refusal with no kind has no refusalKind; the row is still typed',
    () async {
      await send('/loop 20m x', const ValidationException('Not here.'));
      expect(rows.single.metadata, {
        'kind': commandRefusedRowKind,
        'command': 'loop',
      });
    },
  );

  test('a command that starts is no row', () async {
    await startGoalFromMessage(
      ({
        required workspaceId,
        required spaceId,
        required agentId,
        required prompt,
        required requestedByUserId,
        conversationId,
      }) async => 'run-1',
      workspaceId: 'ws-1',
      spaceId: 'sp-1',
      agentId: 'agent-1',
      prompt: '/goal ship it',
      requestedByUserId: 'user-1',
      conversationId: 'conv-1',
      say: (text, metadata) async => rows.add((text: text, metadata: metadata)),
    );
    expect(rows, isEmpty);
  });
}
