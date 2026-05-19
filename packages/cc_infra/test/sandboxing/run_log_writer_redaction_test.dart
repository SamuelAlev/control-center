import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/core/domain/value_objects/agent_capabilities.dart';
import 'package:cc_domain/features/dispatch/domain/entities/agent_process_event.dart';
import 'package:cc_infra/src/sandboxing/run_log_writer.dart';
import 'package:test/test.dart';

/// Locks the redaction WIRING in the persisted run log: a token that flows
/// through an agent's event stream (or a failing run's error) must never land
/// in the on-disk NDJSON. `redactSecrets` itself is covered by
/// command_redaction_test; this proves `RunLogWriter` actually applies it.
void main() {
  const token = 'ghp_1234567890abcdef1234567890abcdef1234';

  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('run_log_redact'));
  tearDown(() => dir.deleteSync(recursive: true));

  Future<String> logContents(RunLogWriter w) => File(w.logPath!).readAsString();

  test('redacts a token in a non-coalesced event (tool result)', () async {
    final w = RunLogWriter();
    await w.open(
      agentDirHostPath: dir.path,
      cliName: 'test',
      capabilities: const AgentCapabilities(),
    );
    w.logEvent(
      ToolResultEvent(
        toolName: 'bash',
        toolCallId: 'c1',
        outputs: 'cloning with $token failed',
      ),
    );
    await w.close(exitCode: 1);

    final body = await logContents(w);
    expect(body, isNot(contains(token)));
    expect(body, contains('***REDACTED***'));
  });

  test('redacts a token in coalesced text output', () async {
    final w = RunLogWriter();
    await w.open(
      agentDirHostPath: dir.path,
      cliName: 'test',
      capabilities: const AgentCapabilities(),
    );
    w.logEvent(TextEvent(content: 'here is the key $token, use it'));
    await w.close(); // flushes the coalesce buffer

    final body = await logContents(w);
    expect(body, isNot(contains(token)));
    expect(body, contains('***REDACTED***'));
  });

  test('redacts a token embedded in the final error payload', () async {
    final w = RunLogWriter();
    await w.open(
      agentDirHostPath: dir.path,
      cliName: 'test',
      capabilities: const AgentCapabilities(),
    );
    await w.close(
      exitCode: 128,
      error:
          'fatal: unable to access '
          "'https://x-access-token:$token@github.com/o/r.git'",
    );

    final body = await logContents(w);
    expect(body, isNot(contains(token)));
    // The end event carries the redaction marker in its error field.
    final endLine = const LineSplitter()
        .convert(body)
        .map((l) => jsonDecode(l) as Map<String, dynamic>)
        .firstWhere((m) => m['type'] == 'end');
    expect(endLine['error'], contains('***REDACTED***'));
  });
}
