import 'package:cc_host/src/repo_rpc/audit_details.dart';
import 'package:test/test.dart';

void main() {
  test('drops workspace_id and blobs, keeps the setting that changed', () {
    expect(
      auditDetailsOf(
        args: {
          'workspace_id': 'ws-1',
          'key': 'conversation_titles',
          'value': 'llm',
        },
      ),
      {'key': 'conversation_titles', 'value': 'llm'},
    );
  });

  test('redacts credential keys and omits PTY bytes', () {
    expect(
      auditDetailsOf(
        args: {
          'session_id': 'tty1',
          'data': 'bHM=',
          'token': 'ghp_secret',
        },
      ),
      {'session_id': 'tty1', 'token': '[REDACTED]'},
    );
  });

  test('merges contextual result fields the args did not carry', () {
    expect(
      auditDetailsOf(
        args: {'rig_id': 'rig-1', 'reason': 'requested'},
        result: {'conversation_id': 'space-9', 'surface': 'computer', 'ok': true},
      ),
      {
        'rig_id': 'rig-1',
        'reason': 'requested',
        'conversation_id': 'space-9',
        'surface': 'computer',
      },
    );
  });

  test('truncates long values and returns null when nothing survives', () {
    final long = 'x' * 300;
    final details = auditDetailsOf(args: {'name': long});
    expect(details!['name'], endsWith('…'));
    expect((details['name'] as String).length, 201);
    expect(auditDetailsOf(args: {'workspace_id': 'ws-1', 'data': 'xx'}), isNull);
  });
}
