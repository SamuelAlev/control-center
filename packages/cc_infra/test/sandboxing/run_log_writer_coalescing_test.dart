import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/core/domain/value_objects/agent_capabilities.dart';
import 'package:cc_domain/core/domain/value_objects/run_cost.dart';
import 'package:cc_domain/features/dispatch/domain/entities/agent_process_event.dart';
import 'package:cc_infra/src/sandboxing/run_log_writer.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// Exercises the COALESCING + STRUCTURE path of [RunLogWriter] (the redaction
/// wiring is covered by run_log_writer_redaction_test). Proves: open writes a
/// start line with all metadata, non-coalesced events flush immediately and
/// carry metadata, coalesced text/thinking buffers merge within the window,
/// type-changes/size-cap flush the buffer, close writes the end line, and a
/// closed writer is a safe no-op.
void main() {
  late Directory dir;
  late AgentCapabilities caps;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('run_log_coal_');
    caps = const AgentCapabilities();
  });
  tearDown(() => dir.deleteSync(recursive: true));

  /// Reads + decodes the persisted NDJSON into a list of record maps.
  Future<List<Map<String, dynamic>>> records(RunLogWriter w) async {
    final body = await File(w.logPath!).readAsString();
    return body
        .trim()
        .split('\n')
        .map((l) => jsonDecode(l) as Map<String, dynamic>)
        .toList();
  }

  group('RunLogWriter.open — start record', () {
    test('writes a start record carrying all metadata fields', () async {
      final w = RunLogWriter();
      await w.open(
        agentDirHostPath: dir.path,
        agentId: 'a1',
        workspaceId: 'ws1',
        conversationId: 'c1',
        ticketId: 't1',
        cliName: 'claude',
        modelId: 'm1',
        capabilities: caps,
      );
      await w.close();
      expect(w.logPath, endsWith('.ndjson'));
      final recs = await records(w);
      final start = recs.firstWhere((r) => r['type'] == 'start');
      expect(start['agentId'], 'a1');
      expect(start['workspaceId'], 'ws1');
      expect(start['conversationId'], 'c1');
      expect(start['ticketId'], 't1');
      expect(start['cliName'], 'claude');
      expect(start['modelId'], 'm1');
      expect(start['runId'], contains('a1'));
      expect(start['capabilities'], isA<Map>());
    });

    test('logPath is absolute under <agentDir>/runs', () async {
      final w = RunLogWriter();
      await w.open(
        agentDirHostPath: dir.path,
        agentId: 'agent',
        cliName: 'test',
        capabilities: caps,
      );
      await w.close();
      expect(p.isAbsolute(w.logPath!), isTrue);
      expect(w.logPath!, contains('runs'));
    });
  });

  group('RunLogWriter.logEvent — non-coalesced', () {
    test(
      'flushes immediately and writes an event record with metadata',
      () async {
        final w = RunLogWriter();
        await w.open(
          agentDirHostPath: dir.path,
          cliName: 't',
          capabilities: caps,
        );
        w.logEvent(
          ToolCallEvent(
            toolName: 'bash',
            toolCallId: 'tc1',
            inputs: {'command': 'ls'},
          ),
        );
        await w.close();

        final recs = await records(w);
        final ev = recs.firstWhere((r) => r['type'] == 'event');
        expect(ev['eventType'], 'tool_call');
        expect(ev['content'], 'bash');
        expect(ev['metadata'], isNotNull);
        final metadata = ev['metadata'] as Map<String, dynamic>;
        expect(metadata['toolName'], 'bash');
        expect(metadata['toolCallId'], 'tc1');
        expect(metadata['inputs'], {'command': 'ls'});
      },
    );

    test('a usage event carries token metadata', () async {
      final w = RunLogWriter();
      await w.open(
        agentDirHostPath: dir.path,
        cliName: 't',
        capabilities: caps,
      );
      w.logEvent(
        UsageEvent(
          usage: const RunUsage(
            inputTokens: 10,
            outputTokens: 20,
            thoughtTokens: 0,
            cachedReadTokens: 0,
            cachedWriteTokens: 0,
            estimatedCostCents: 3,
          ),
          durationMs: 500,
        ),
      );
      await w.close();

      final ev = (await records(w)).firstWhere((r) => r['type'] == 'event');
      expect(ev['eventType'], 'usage');
      final metadata = ev['metadata'] as Map<String, dynamic>;
      expect(metadata['inputTokens'], 10);
      expect(metadata['outputTokens'], 20);
      expect(metadata['estimatedCostCents'], 3);
      expect(metadata['durationMs'], 500);
    });

    test('a debug event has no metadata key', () async {
      final w = RunLogWriter();
      await w.open(
        agentDirHostPath: dir.path,
        cliName: 't',
        capabilities: caps,
      );
      w.logEvent(DebugEvent(content: 'launching pi'));
      await w.close();

      final ev = (await records(w)).firstWhere((r) => r['type'] == 'event');
      expect(ev['eventType'], 'debug');
      expect(ev['content'], 'launching pi');
      expect(ev.containsKey('metadata'), isFalse);
    });
  });

  group('RunLogWriter.logEvent — coalesced', () {
    test(
      'merges same-type text deltas into one buffered record on flush',
      () async {
        final w = RunLogWriter(
          logCoalesceWindow: const Duration(minutes: 1),
          logCoalesceMaxChars: 10000,
        );
        await w.open(
          agentDirHostPath: dir.path,
          cliName: 't',
          capabilities: caps,
        );
        w.logEvent(TextEvent(content: 'Hello'));
        w.logEvent(TextEvent(content: ', '));
        w.logEvent(TextEvent(content: 'world'));
        w.flushBuffer();
        await w.close();

        final events = (await records(
          w,
        )).where((r) => r['type'] == 'event').toList();
        expect(events, hasLength(1));
        expect(events.single['eventType'], 'text');
        expect(events.single['content'], 'Hello, world');
      },
    );

    test('a type change flushes the previous buffer first', () async {
      final w = RunLogWriter(
        logCoalesceWindow: const Duration(minutes: 1),
        logCoalesceMaxChars: 10000,
      );
      await w.open(
        agentDirHostPath: dir.path,
        cliName: 't',
        capabilities: caps,
      );
      w.logEvent(TextEvent(content: 't1'));
      // thinking is coalesced too but a DIFFERENT type → flush text first.
      w.logEvent(ThinkingEvent(content: 'th1'));
      w.flushBuffer();
      await w.close();

      final events = (await records(
        w,
      )).where((r) => r['type'] == 'event').toList();
      expect(events, hasLength(2));
      expect(events[0]['eventType'], 'text');
      expect(events[0]['content'], 't1');
      expect(events[1]['eventType'], 'thinking');
      expect(events[1]['content'], 'th1');
    });

    test('exceeding the char cap flushes the buffer mid-stream', () async {
      final w = RunLogWriter(
        logCoalesceWindow: const Duration(minutes: 1),
        logCoalesceMaxChars: 10, // tiny cap
      );
      await w.open(
        agentDirHostPath: dir.path,
        cliName: 't',
        capabilities: caps,
      );
      w.logEvent(TextEvent(content: '0123456789')); // 10 chars, fills buffer
      // Next event would overflow → flush the first buffer before buffering.
      w.logEvent(TextEvent(content: 'overflow'));
      w.flushBuffer();
      await w.close();

      final events = (await records(
        w,
      )).where((r) => r['type'] == 'event').toList();
      expect(events, hasLength(2));
      expect(events[0]['content'], '0123456789');
      expect(events[1]['content'], 'overflow');
    });

    test('logEvent before open is a safe no-op', () {
      final w = RunLogWriter();
      // No throw, no sink.
      expect(() => w.logEvent(TextEvent(content: 'x')), returnsNormally);
    });

    test('flushBuffer with nothing buffered is a no-op', () async {
      final w = RunLogWriter();
      await w.open(
        agentDirHostPath: dir.path,
        cliName: 't',
        capabilities: caps,
      );
      w.flushBuffer();
      await w.close();
      final recs = await records(w);
      // Only start + end, no event.
      expect(recs.where((r) => r['type'] == 'event'), isEmpty);
    });
  });

  group('RunLogWriter.close', () {
    test('writes the end record with exit code', () async {
      final w = RunLogWriter();
      await w.open(
        agentDirHostPath: dir.path,
        cliName: 't',
        capabilities: caps,
      );
      await w.close(exitCode: 0);
      final end = (await records(w)).firstWhere((r) => r['type'] == 'end');
      expect(end['exitCode'], 0);
      expect(end.containsKey('error'), isFalse);
    });

    test('close without open is a safe no-op', () async {
      final w = RunLogWriter();
      expect(w.close, returnsNormally);
      expect(w.logPath, isNull);
    });

    test('flushes any pending buffered event on close', () async {
      final w = RunLogWriter(
        logCoalesceWindow: const Duration(minutes: 1),
        logCoalesceMaxChars: 10000,
      );
      await w.open(
        agentDirHostPath: dir.path,
        cliName: 't',
        capabilities: caps,
      );
      w.logEvent(TextEvent(content: 'buffered-on-close'));
      // Don't call flushBuffer explicitly — close must flush it.
      await w.close();
      final events = (await records(
        w,
      )).where((r) => r['type'] == 'event').toList();
      expect(events.single['content'], 'buffered-on-close');
    });
  });
}
