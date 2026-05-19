import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/core/domain/value_objects/agent_capabilities.dart';
import 'package:cc_domain/core/domain/value_objects/run_cost.dart';
import 'package:cc_domain/features/dispatch/domain/entities/agent_process_event.dart';
import 'package:cc_infra/src/sandboxing/run_log_writer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tempDir;
  late String agentDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('run_log_writer_test_');
    agentDir = '${tempDir.path}/agent';
  });

  tearDown(() {
    try {
      tempDir.deleteSync(recursive: true);
    } catch (_) {}
  });

  /// Opens a [RunLogWriter] with sensible defaults for testing.
  /// Caller is responsible for calling [writer.close()].
  Future<RunLogWriter> openWriter({
    String cliName = 'test-cli',
    String? agentId,
    AgentCapabilities capabilities = const AgentCapabilities(),
    Set<String>? coalesceableLogTypes,
    Duration logCoalesceWindow = const Duration(milliseconds: 50),
    int logCoalesceMaxChars = 4000,
  }) async {
    final writer = RunLogWriter(
      coalesceableLogTypes:
          coalesceableLogTypes ?? const {'thinking', 'text'},
      logCoalesceWindow: logCoalesceWindow,
      logCoalesceMaxChars: logCoalesceMaxChars,
    );
    await writer.open(
      agentDirHostPath: agentDir,
      agentId: agentId,
      cliName: cliName,
      capabilities: capabilities,
    );
    return writer;
  }

  /// Reads the NDJSON log lines from a path.
  List<Map<String, dynamic>> readLogLines(String path) {
    final content = File(path).readAsStringSync();
    return content
        .split('\n')
        .where((l) => l.trim().isNotEmpty)
        .map((l) => jsonDecode(l) as Map<String, dynamic>)
        .toList();
  }

  /// Convenience: closes the writer and returns the parsed log lines.
  Future<List<Map<String, dynamic>>> closeAndRead(
    RunLogWriter writer, {
    int? exitCode,
    Object? error,
  }) async {
    await writer.close(exitCode: exitCode, error: error);
    return readLogLines(writer.logPath!);
  }

  group('RunLogWriter', () {
    group('open', () {
      test('creates runs directory and log file', () async {
        expect(Directory(agentDir).existsSync(), isFalse);

        final writer = await openWriter(agentId: 'a1');
        final lines = await closeAndRead(writer);

        expect(Directory('$agentDir/runs').existsSync(), isTrue);
        expect(lines, isNotEmpty);
      }, timeout: const Timeout.factor(2));

      test('start event contains metadata', () async {
        final writer = await openWriter(
          agentId: 'a1',
          cliName: 'test-cli',
          capabilities: const AgentCapabilities(
            canPushToRepo: true,
            canCallGitHubApi: false,
          ),
        );
        final lines = await closeAndRead(writer);
        final start = lines.first;

        expect(start['type'], 'start');
        expect(start['agentId'], 'a1');
        expect(start['cliName'], 'test-cli');
        expect(start['runId'], contains('a1'));
        expect(start['ts'], isNotNull);
        expect(start['capabilities'], isA<Map>());
        final capsJson = start['capabilities'] as Map<String, dynamic>;
        expect(capsJson['canPushToRepo'], isTrue);
        expect(capsJson['canCallGitHubApi'], isFalse);
      }, timeout: const Timeout.factor(2));

      test('runId includes agentId when provided', () async {
        final writer = await openWriter(agentId: 'myAgent');
        final lines = await closeAndRead(writer);
        final runId = lines.first['runId'] as String;
        expect(runId, endsWith('-myAgent'));
      }, timeout: const Timeout.factor(2));

      test('runId defaults to "agent" when no agentId', () async {
        final writer = await openWriter();
        final lines = await closeAndRead(writer);
        final runId = lines.first['runId'] as String;
        expect(runId, endsWith('-agent'));
      }, timeout: const Timeout.factor(2));
    });

    group('logEvent', () {
      test('writes non-coalesceable event immediately', () async {
        final writer = await openWriter();
        writer.logEvent(
          ToolCallEvent(toolName: 'bash', toolCallId: 'tc1'),
        );
        final lines = await closeAndRead(writer);

        // start + tool_call + end
        expect(lines.length, 3);
        final event = lines[1];
        expect(event['type'], 'event');
        expect(event['eventType'], 'tool_call');
        expect(event['content'], 'bash');
      }, timeout: const Timeout.factor(2));

      test('writes event with metadata from ToolCallEvent', () async {
        final writer = await openWriter();
        writer.logEvent(
          ToolCallEvent(
            toolName: 'grep',
            toolCallId: 'tc2',
            inputs: {'pattern': 'TODO'},
          ),
        );
        final lines = await closeAndRead(writer);

        final event = lines[1];
        final metadata = event['metadata'] as Map<String, dynamic>;
        expect(metadata, isNotNull);
        expect(metadata['toolName'], 'grep');
        expect(metadata['toolCallId'], 'tc2');
        expect(metadata['inputs'], isNotNull);
      }, timeout: const Timeout.factor(2));

      test('omits metadata when event has none', () async {
        final writer = await openWriter();
        writer.logEvent(ErrorEvent(content: 'boom'));
        final lines = await closeAndRead(writer);

        final event = lines[1];
        expect(event.containsKey('metadata'), isFalse);
      }, timeout: const Timeout.factor(2));

      test('does nothing when sink is null', () async {
        final writer = RunLogWriter();
        // Should not throw.
        writer.logEvent(TextEvent(content: 'should not crash'));
      }, timeout: const Timeout.factor(2));

      test('coalesces consecutive coalesceable events of same type',
          () async {
        final writer = await openWriter(
          logCoalesceWindow: const Duration(seconds: 10),
        );
        writer.logEvent(ThinkingEvent(content: 'step 1 '));
        writer.logEvent(ThinkingEvent(content: 'step 2 '));
        writer.logEvent(ThinkingEvent(content: 'step 3'));
        final lines = await closeAndRead(writer);

        // start + 1 coalesced thinking + end
        expect(lines.length, 3);
        final event = lines[1];
        expect(event['eventType'], 'thinking');
        expect(event['content'], 'step 1 step 2 step 3');
      }, timeout: const Timeout.factor(2));

      test('flushes buffer when event type changes', () async {
        final writer = await openWriter(
          logCoalesceWindow: const Duration(seconds: 10),
        );
        writer.logEvent(ThinkingEvent(content: 'hmm'));
        writer.logEvent(TextEvent(content: 'output'));
        final lines = await closeAndRead(writer);

        // start + coalesced thinking + text + end
        expect(lines.length, 4);
        expect(lines[1]['eventType'], 'thinking');
        expect(lines[1]['content'], 'hmm');
        expect(lines[2]['eventType'], 'text');
        expect(lines[2]['content'], 'output');
      }, timeout: const Timeout.factor(2));

      test('flushes buffer when max chars exceeded', () async {
        final writer = await openWriter(
          logCoalesceWindow: const Duration(seconds: 10),
          logCoalesceMaxChars: 10,
        );
        writer.logEvent(ThinkingEvent(content: '12345'));
        // 5 + 6 = 11 > 10, so buffer flushes and new one starts.
        writer.logEvent(ThinkingEvent(content: '67890x'));
        final lines = await closeAndRead(writer);

        // start + first flush + second flush + end
        expect(lines.length, 4);
        expect(lines[1]['content'], '12345');
        expect(lines[2]['content'], '67890x');
      }, timeout: const Timeout.factor(2));

      test('non-coalesceable event flushes pending buffer first', () async {
        final writer = await openWriter(
          logCoalesceWindow: const Duration(seconds: 10),
        );
        writer.logEvent(ThinkingEvent(content: 'buffered'));
        writer.logEvent(ErrorEvent(content: 'boom'));
        final lines = await closeAndRead(writer);

        // start + coalesced thinking + error + end
        expect(lines.length, 4);
        expect(lines[1]['eventType'], 'thinking');
        expect(lines[2]['eventType'], 'error');
      }, timeout: const Timeout.factor(2));

      test('redacts secrets in content', () async {
        final writer = await openWriter();
        writer.logEvent(
          TextEvent(content: 'key=sk-abc12345678901234567890ab'),
        );
        final lines = await closeAndRead(writer);

        final content = lines[1]['content'] as String;
        expect(content, contains('***REDACTED***'));
        expect(content, isNot(contains('sk-abc12345678901234567890ab')));
      }, timeout: const Timeout.factor(2));
    });

    group('flushBuffer', () {
      test('is no-op when buffer is empty', () async {
        final writer = await openWriter();
        writer.flushBuffer();
        final lines = await closeAndRead(writer);

        // start + end only — flushBuffer was a no-op
        expect(lines.length, 2);
        expect(lines[0]['type'], 'start');
        expect(lines[1]['type'], 'end');
      }, timeout: const Timeout.factor(2));
    });

    group('close', () {
      test('writes end event with exit code', () async {
        final writer = await openWriter();
        final lines = await closeAndRead(writer, exitCode: 0);

        final last = lines.last;
        expect(last['type'], 'end');
        expect(last['exitCode'], 0);
        expect(last['ts'], isNotNull);
      }, timeout: const Timeout.factor(2));

      test('writes end event with error', () async {
        final writer = await openWriter();
        final lines = await closeAndRead(
          writer,
          error: Exception('something went wrong'),
        );

        final last = lines.last;
        expect(last['type'], 'end');
        expect(last['error'], contains('something went wrong'));
      }, timeout: const Timeout.factor(2));

      test('writes end event without optional fields', () async {
        final writer = await openWriter();
        final lines = await closeAndRead(writer);

        final last = lines.last;
        expect(last['type'], 'end');
        expect(last['exitCode'], isNull);
        expect(last.containsKey('error'), isFalse);
      }, timeout: const Timeout.factor(2));

      test('flushes pending buffer before closing', () async {
        final writer = await openWriter(
          logCoalesceWindow: const Duration(seconds: 10),
        );
        writer.logEvent(ThinkingEvent(content: 'pending'));
        final lines = await closeAndRead(writer, exitCode: 0);

        // start + coalesced thinking + end
        expect(lines.length, 3);
        expect(lines[1]['eventType'], 'thinking');
        expect(lines[2]['type'], 'end');
      }, timeout: const Timeout.factor(2));

      test('idempotent when called twice', () async {
        final writer = await openWriter();
        await writer.close(exitCode: 0);
        // Second close should not throw.
        await writer.close();
      }, timeout: const Timeout.factor(2));
    });

    group('full lifecycle', () {
      test('writes complete log from open to close', () async {
        final writer = await openWriter(
          agentId: 'lifecycle-test',
          cliName: 'pi',
          capabilities: const AgentCapabilities(
            canPushToRepo: true,
            canAccessNetwork: true,
          ),
          logCoalesceWindow: const Duration(seconds: 10),
        );

        writer.logEvent(ThinkingEvent(content: 'analyzing code... '));
        writer.logEvent(ThinkingEvent(content: 'making changes'));
        writer.logEvent(
          ToolCallEvent(toolName: 'git commit', toolCallId: 'tc1'),
        );
        writer.logEvent(TextEvent(content: 'Changes committed'));
        writer.logEvent(ErrorEvent(content: 'network timeout'));

        final lines = await closeAndRead(writer, exitCode: 1, error: 'Timeout');

        // start + coalesced thinking + tool_call + text + error + end
        expect(lines.length, 6);

        expect(lines[0]['type'], 'start');
        expect(lines[0]['agentId'], 'lifecycle-test');
        expect(lines[0]['cliName'], 'pi');

        expect(lines[1]['eventType'], 'thinking');
        expect(lines[1]['content'], 'analyzing code... making changes');

        expect(lines[2]['eventType'], 'tool_call');
        expect(lines[3]['eventType'], 'text');
        expect(lines[4]['eventType'], 'error');
        expect(lines[4]['content'], 'network timeout');

        expect(lines[5]['type'], 'end');
        expect(lines[5]['exitCode'], 1);
        expect(lines[5]['error'], contains('Timeout'));
      }, timeout: const Timeout.factor(2));
    });

    group('re-open', () {
      test('opening again resets buffer state', () async {
        final writer = RunLogWriter(
          logCoalesceWindow: const Duration(seconds: 10),
        );

        await writer.open(
          agentDirHostPath: agentDir,
          cliName: 'first',
          capabilities: const AgentCapabilities(),
        );

        writer.logEvent(ThinkingEvent(content: 'leftover'));
        // Don't flush — the buffer should be cleared on re-open.

        await writer.open(
          agentDirHostPath: agentDir,
          cliName: 'second',
          capabilities: const AgentCapabilities(),
        );

        writer.logEvent(TextEvent(content: 'new session'));

        final lines = await closeAndRead(writer);

        // start + text + end — no leftover thinking from first session.
        expect(lines.length, 3);
        expect(lines[0]['cliName'], 'second');
        expect(lines[1]['eventType'], 'text');
        expect(lines[1]['content'], 'new session');
        expect(lines[2]['type'], 'end');
      }, timeout: const Timeout.factor(2));
    });

    group('logPath getter', () {
      test('is null before open', () {
        final writer = RunLogWriter();
        expect(writer.logPath, isNull);
      });

      test('is set after open', () async {
        final writer = await openWriter(agentId: 'a1');
        expect(writer.logPath, isNotNull);
        expect(writer.logPath, contains('.ndjson'));
        await writer.close();
      }, timeout: const Timeout.factor(2));
    });

    group('empty coalesceable types', () {
      test('all events are written immediately when set is empty', () async {
        final writer = await openWriter(
          coalesceableLogTypes: const {},
          logCoalesceWindow: const Duration(seconds: 10),
        );
        writer.logEvent(ThinkingEvent(content: 't1'));
        writer.logEvent(ThinkingEvent(content: 't2'));
        writer.logEvent(TextEvent(content: 'text1'));
        final lines = await closeAndRead(writer);

        // start + thinking + thinking + text + end
        expect(lines.length, 5);
        expect(lines[1]['content'], 't1');
        expect(lines[2]['content'], 't2');
        expect(lines[3]['content'], 'text1');
      }, timeout: const Timeout.factor(2));

      test('only specified types coalesce; others are immediate', () async {
        final writer = await openWriter(
          coalesceableLogTypes: const {'thinking'},
          logCoalesceWindow: const Duration(seconds: 10),
        );
        writer.logEvent(ThinkingEvent(content: 'think1'));
        writer.logEvent(ThinkingEvent(content: 'think2'));
        writer.logEvent(TextEvent(content: 'text_now')); // not coalesceable
        writer.logEvent(TextEvent(content: 'text_also')); // not coalesceable
        final lines = await closeAndRead(writer);

        // start + coalesced thinking + text_now + text_also + end
        expect(lines.length, 5);
        expect(lines[1]['eventType'], 'thinking');
        expect(lines[1]['content'], 'think1think2');
        expect(lines[2]['eventType'], 'text');
        expect(lines[2]['content'], 'text_now');
        expect(lines[3]['eventType'], 'text');
        expect(lines[3]['content'], 'text_also');
      }, timeout: const Timeout.factor(2));
    });

    group('timer-based flush', () {
      test('coalesced events flush after coalesce window expires', () async {
        final writer = await openWriter(
          logCoalesceWindow: const Duration(seconds: 1),
        );
        writer.logEvent(ThinkingEvent(content: 'pending'));
        // Wait for the timer to fire.
        await Future.delayed(const Duration(milliseconds: 1200));
        // Buffer should be empty now — flushBuffer was called by timer.
        final lines = await closeAndRead(writer);

        // start + flushed thinking + end
        expect(lines.length, 3);
        expect(lines[1]['eventType'], 'thinking');
        expect(lines[1]['content'], 'pending');
      }, timeout: const Timeout.factor(2));

      test('timer reset on new events of same type', () async {
        final writer = await openWriter(
          logCoalesceWindow: const Duration(seconds: 2),
        );
        writer.logEvent(ThinkingEvent(content: 'a'));
        await Future.delayed(const Duration(milliseconds: 300));
        // Timer resets because same type arrives before expiry.
        writer.logEvent(ThinkingEvent(content: 'b'));
        await Future.delayed(const Duration(milliseconds: 300));
        // Still within window from first event.
        writer.logEvent(ThinkingEvent(content: 'c'));
        // Wait for timer to fire (2s from last event).
        await Future.delayed(const Duration(seconds: 3));

        final lines = await closeAndRead(writer);
        // start + one coalesced thinking + end
        expect(lines.length, 3);
        expect(lines[1]['eventType'], 'thinking');
        expect(lines[1]['content'], 'abc');
      }, timeout: const Timeout.factor(2));
    });

    group('extended start event metadata', () {
      test('workspaceId, conversationId, ticketId in start event', () async {
        final writer = await openWriter(
          agentId: 'a1',
          cliName: 'test-cli',
          capabilities: const AgentCapabilities(),
        );
        // Re-open with extended metadata.
        await writer.close();

        final writer2 = RunLogWriter();
        await writer2.open(
          agentDirHostPath: agentDir,
          cliName: 'test-cli',
          agentId: 'a1',
          workspaceId: 'ws-42',
          conversationId: 'conv-7',
          ticketId: 'tkt-99',
          capabilities: const AgentCapabilities(),
        );
        final lines = await closeAndRead(writer2);
        final start = lines.first;
        expect(start['workspaceId'], 'ws-42');
        expect(start['conversationId'], 'conv-7');
        expect(start['ticketId'], 'tkt-99');
      }, timeout: const Timeout.factor(2));

      test('modelId in start event when provided', () async {
        final writer = RunLogWriter();
        await writer.open(
          agentDirHostPath: agentDir,
          cliName: 'test-cli',
          agentId: 'a1',
          modelId: 'gpt-5',
          capabilities: const AgentCapabilities(),
        );
        final lines = await closeAndRead(writer);
        final start = lines.first;
        expect(start['modelId'], 'gpt-5');
      }, timeout: const Timeout.factor(2));
    });

    group('event metadata for other event types', () {
      test('ToolResultEvent includes metadata', () async {
        final writer = await openWriter();
        writer.logEvent(ToolResultEvent(
          toolCallId: 'tc-1',
          outputs: 'result output',
          toolName: 'grep',
        ));
        final lines = await closeAndRead(writer);
        final event = lines[1];
        final meta = event['metadata'] as Map<String, dynamic>;
        expect(meta, isNotNull);
        expect(meta['toolCallId'], 'tc-1');
        expect(meta['outputs'], 'result output');
        expect(meta['toolName'], 'grep');
      }, timeout: const Timeout.factor(2));

      test('UsageEvent includes token metadata', () async {
        final writer = await openWriter();
        const usage = RunUsage(
          inputTokens: 100,
          outputTokens: 50,
          thoughtTokens: 20,
          estimatedCostCents: 3,
        );
        writer.logEvent(UsageEvent(usage: usage));
        final lines = await closeAndRead(writer);
        final event = lines[1];
        final meta = event['metadata'] as Map<String, dynamic>;
        expect(meta, isNotNull);
        expect(meta['inputTokens'], 100);
        expect(meta['outputTokens'], 50);
        expect(meta['estimatedCostCents'], 3);
      }, timeout: const Timeout.factor(2));

      test('SandboxViolationEvent includes action metadata', () async {
        final writer = await openWriter();
        writer.logEvent(SandboxViolationEvent(
          content: 'denied: file-read',
          action: 'file-read',
          target: '/etc/passwd',
          suggestedCapability: 'canReadFiles',
        ));
        final lines = await closeAndRead(writer);
        final event = lines[1];
        final meta = event['metadata'] as Map<String, dynamic>;
        expect(meta, isNotNull);
        expect(meta['action'], 'file-read');
        expect(meta['target'], '/etc/passwd');
        expect(meta['suggestedCapability'], 'canReadFiles');
      }, timeout: const Timeout.factor(2));
    });

    group('coalescing edge cases', () {
      test('first coalesceable event populates buffer without writing', () async {
        final writer = await openWriter(
          logCoalesceWindow: const Duration(seconds: 10),
        );
        writer.logEvent(ThinkingEvent(content: 'first'));
        // Buffer populated but not yet flushed.
        writer.flushBuffer();
        final lines = await closeAndRead(writer);

        // start + flushed thinking + end
        expect(lines.length, 3);
        expect(lines[1]['content'], 'first');
      }, timeout: const Timeout.factor(2));

      test('buffer flush resets state for next coalesce', () async {
        final writer = await openWriter(
          logCoalesceWindow: const Duration(seconds: 10),
        );
        writer.logEvent(ThinkingEvent(content: 'batch1'));
        writer.flushBuffer();
        writer.logEvent(ThinkingEvent(content: 'batch2'));
        final lines = await closeAndRead(writer);

        // start + batch1 + batch2 + end
        expect(lines.length, 4);
        expect(lines[1]['content'], 'batch1');
        expect(lines[2]['content'], 'batch2');
      }, timeout: const Timeout.factor(2));

      test('exact max chars boundary does not trigger flush', () async {
        final writer = await openWriter(
          logCoalesceWindow: const Duration(seconds: 10),
          logCoalesceMaxChars: 10,
        );
        writer.logEvent(ThinkingEvent(content: '12345'));
        // 5 + 5 = 10, equal to max, NOT greater. Should coalesce.
        writer.logEvent(ThinkingEvent(content: '67890'));
        final lines = await closeAndRead(writer);

        // start + one coalesced batch + end
        expect(lines.length, 3);
        expect(lines[1]['content'], '1234567890');
      }, timeout: const Timeout.factor(2));
    });
  });
}
