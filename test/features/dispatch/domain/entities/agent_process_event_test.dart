import 'package:control_center/core/domain/value_objects/run_cost.dart';
import 'package:control_center/features/dispatch/domain/entities/agent_process_event.dart';
import 'package:test/test.dart';

void main() {
  // ---- AgentProcessEventType ----------------------------------------------

  group('AgentProcessEventTypeExtension', () {
    test('name returns correct string for each type', timeout: const Timeout.factor(2), () {
      expect(AgentProcessEventType.thinking.name, 'thinking');
      expect(AgentProcessEventType.text.name, 'text');
      expect(AgentProcessEventType.toolCall.name, 'tool_call');
      expect(AgentProcessEventType.toolResult.name, 'tool_result');
      expect(AgentProcessEventType.usage.name, 'usage');
      expect(AgentProcessEventType.error.name, 'error');
      expect(AgentProcessEventType.sandboxViolation.name, 'sandbox_violation');
      expect(AgentProcessEventType.debug.name, 'debug');
      expect(AgentProcessEventType.done.name, 'done');
    });

    group('fromString', () {
      test('parses known values', timeout: const Timeout.factor(2), () {
        expect(AgentProcessEventTypeExtension.fromString('thinking'), AgentProcessEventType.thinking);
        expect(AgentProcessEventTypeExtension.fromString('text'), AgentProcessEventType.text);
        expect(AgentProcessEventTypeExtension.fromString('tool_call'), AgentProcessEventType.toolCall);
        expect(AgentProcessEventTypeExtension.fromString('tool_result'), AgentProcessEventType.toolResult);
        expect(AgentProcessEventTypeExtension.fromString('usage'), AgentProcessEventType.usage);
        expect(AgentProcessEventTypeExtension.fromString('error'), AgentProcessEventType.error);
        expect(AgentProcessEventTypeExtension.fromString('sandbox_violation'), AgentProcessEventType.sandboxViolation);
        expect(AgentProcessEventTypeExtension.fromString('debug'), AgentProcessEventType.debug);
        expect(AgentProcessEventTypeExtension.fromString('done'), AgentProcessEventType.done);
      });

      test('"message" aliases to text', timeout: const Timeout.factor(2), () {
        expect(AgentProcessEventTypeExtension.fromString('message'), AgentProcessEventType.text);
      });

      test('"stderr" aliases to error', timeout: const Timeout.factor(2), () {
        expect(AgentProcessEventTypeExtension.fromString('stderr'), AgentProcessEventType.error);
      });

      test('unknown defaults to text', timeout: const Timeout.factor(2), () {
        expect(AgentProcessEventTypeExtension.fromString('unknown'), AgentProcessEventType.text);
        expect(AgentProcessEventTypeExtension.fromString(''), AgentProcessEventType.text);
      });
    });
  });

  // ---- Base class equality ------------------------------------------------

  group('AgentProcessEvent equality', () {
    test('events with same type and content are equal', timeout: const Timeout.factor(2), () {
      final a = TextEvent(content: 'hello');
      final b = TextEvent(content: 'hello');
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('events with different content are not equal', timeout: const Timeout.factor(2), () {
      final a = TextEvent(content: 'hello');
      final b = TextEvent(content: 'world');
      expect(a, isNot(equals(b)));
    });

    test('events of different subtypes are not equal even with same content', timeout: const Timeout.factor(2), () {
      final a = TextEvent(content: 'test');
      final b = ThinkingEvent(content: 'test');
      expect(a, isNot(equals(b)));
    });
  });

  // ---- TextEvent ----------------------------------------------------------

  group('TextEvent', () {
    test('has correct type and content', timeout: const Timeout.factor(2), () {
      final e = TextEvent(content: 'output text');
      expect(e.type, AgentProcessEventType.text);
      expect(e.content, 'output text');
    });

    test('metadata is null', timeout: const Timeout.factor(2), () {
      final e = TextEvent(content: 'x');
      expect(e.metadata, isNull);
    });

    test('accepts custom timestamp', timeout: const Timeout.factor(2), () {
      final ts = DateTime(2025, 1, 1);
      final e = TextEvent(content: 'x', timestamp: ts);
      expect(e.timestamp, ts);
    });
  });

  // ---- ThinkingEvent ------------------------------------------------------

  group('ThinkingEvent', () {
    test('has correct type', timeout: const Timeout.factor(2), () {
      final e = ThinkingEvent(content: 'reasoning...');
      expect(e.type, AgentProcessEventType.thinking);
      expect(e.content, 'reasoning...');
    });
  });

  // ---- ToolCallEvent ------------------------------------------------------

  group('ToolCallEvent', () {
    test('content is the tool name', timeout: const Timeout.factor(2), () {
      final e = ToolCallEvent(toolName: 'read_file', toolCallId: 'tc-1');
      expect(e.type, AgentProcessEventType.toolCall);
      expect(e.content, 'read_file');
      expect(e.toolName, 'read_file');
      expect(e.toolCallId, 'tc-1');
    });

    test('includes inputs in metadata', timeout: const Timeout.factor(2), () {
      final e = ToolCallEvent(
        toolName: 'write_file',
        toolCallId: 'tc-2',
        inputs: {'path': '/tmp/x.txt', 'content': 'hi'},
      );
      expect(e.metadata, isNotNull);
      expect(e.metadata!['toolName'], 'write_file');
      expect(e.metadata!['toolCallId'], 'tc-2');
      expect(e.metadata!['inputs'], isA<Map>());
    });

    test('metadata omits inputs when null', timeout: const Timeout.factor(2), () {
      final e = ToolCallEvent(toolName: 'bash', toolCallId: 'tc-3');
      expect(e.metadata!['inputs'], isNull);
    });
  });

  // ---- ToolResultEvent ----------------------------------------------------

  group('ToolResultEvent', () {
    test('has correct type and content is outputs', timeout: const Timeout.factor(2), () {
      final e = ToolResultEvent(toolCallId: 'tc-1', outputs: 'file contents');
      expect(e.type, AgentProcessEventType.toolResult);
      expect(e.content, 'file contents');
      expect(e.toolCallId, 'tc-1');
      expect(e.isError, isFalse);
      expect(e.isPartial, isFalse);
    });

    test('metadata includes error and partial flags', timeout: const Timeout.factor(2), () {
      final e = ToolResultEvent(
        toolCallId: 'tc-2',
        outputs: 'error msg',
        isError: true,
        isPartial: true,
        toolName: 'bash',
      );
      expect(e.metadata!['isError'], isTrue);
      expect(e.metadata!['partial'], isTrue);
      expect(e.metadata!['toolName'], 'bash');
    });

    test('metadata omits toolName when null', timeout: const Timeout.factor(2), () {
      final e = ToolResultEvent(toolCallId: 'tc-3', outputs: 'ok');
      expect(e.metadata!.containsKey('toolName'), isFalse);
    });

    test('metadata omits partial when false', timeout: const Timeout.factor(2), () {
      final e = ToolResultEvent(toolCallId: 'tc-4', outputs: 'ok');
      expect(e.metadata!.containsKey('partial'), isFalse);
    });
  });

  // ---- UsageEvent ---------------------------------------------------------

  group('UsageEvent', () {
    test('has correct type and empty content', timeout: const Timeout.factor(2), () {
      const usage = RunUsage(inputTokens: 100, outputTokens: 50);
      final e = UsageEvent(usage: usage);
      expect(e.type, AgentProcessEventType.usage);
      expect(e.content, '');
    });

    test('metadata includes token counts', timeout: const Timeout.factor(2), () {
      const usage = RunUsage(
        inputTokens: 100,
        outputTokens: 50,
        thoughtTokens: 10,
        cachedReadTokens: 20,
        cachedWriteTokens: 5,
        estimatedCostCents: 42,
      );
      final e = UsageEvent(usage: usage, durationMs: 1500);
      final meta = e.metadata!;
      expect(meta['inputTokens'], 100);
      expect(meta['outputTokens'], 50);
      expect(meta['thoughtTokens'], 10);
      expect(meta['cachedReadTokens'], 20);
      expect(meta['cachedWriteTokens'], 5);
      expect(meta['estimatedCostCents'], 42);
      expect(meta['durationMs'], 1500);
    });

    test('metadata omits zero-valued optional fields', timeout: const Timeout.factor(2), () {
      const usage = RunUsage(inputTokens: 100);
      final e = UsageEvent(usage: usage);
      expect(e.metadata!.containsKey('thoughtTokens'), isFalse);
      expect(e.metadata!.containsKey('cachedReadTokens'), isFalse);
      expect(e.metadata!.containsKey('cachedWriteTokens'), isFalse);
      expect(e.metadata!.containsKey('durationMs'), isFalse);
    });
  });

  // ---- ErrorEvent ---------------------------------------------------------

  group('ErrorEvent', () {
    test('has correct type and content', timeout: const Timeout.factor(2), () {
      final e = ErrorEvent(content: 'something went wrong');
      expect(e.type, AgentProcessEventType.error);
      expect(e.content, 'something went wrong');
    });
  });

  // ---- SandboxViolationEvent ----------------------------------------------

  group('SandboxViolationEvent', () {
    test('has correct type', timeout: const Timeout.factor(2), () {
      final e = SandboxViolationEvent(content: 'denied: file-read /etc/passwd');
      expect(e.type, AgentProcessEventType.sandboxViolation);
      expect(e.content, 'denied: file-read /etc/passwd');
    });

    test('metadata includes action, target, suggestedCapability', timeout: const Timeout.factor(2), () {
      final e = SandboxViolationEvent(
        content: 'denied',
        action: 'file-read',
        target: '/etc/passwd',
        suggestedCapability: 'fs.read',
      );
      expect(e.metadata!['action'], 'file-read');
      expect(e.metadata!['target'], '/etc/passwd');
      expect(e.metadata!['suggestedCapability'], 'fs.read');
    });

    test('metadata omits null fields', timeout: const Timeout.factor(2), () {
      final e = SandboxViolationEvent(content: 'denied');
      expect(e.metadata, isNotNull);
      expect(e.metadata!.isEmpty, isTrue);
    });
  });

  // ---- DebugEvent ---------------------------------------------------------

  group('DebugEvent', () {
    test('has correct type and content', timeout: const Timeout.factor(2), () {
      final e = DebugEvent(content: 'launching pi');
      expect(e.type, AgentProcessEventType.debug);
      expect(e.content, 'launching pi');
    });
  });

  // ---- DoneEvent ----------------------------------------------------------

  group('DoneEvent', () {
    test('has correct type and empty content', timeout: const Timeout.factor(2), () {
      final e = DoneEvent();
      expect(e.type, AgentProcessEventType.done);
      expect(e.content, '');
    });
  });

  // ---- Timestamp defaults -------------------------------------------------

  group('timestamp', () {
    test('defaults to DateTime.now() when not provided', timeout: const Timeout.factor(2), () {
      final before = DateTime.now();
      final e = TextEvent(content: 'x');
      final after = DateTime.now();
      expect(e.timestamp.isAfter(before.subtract(const Duration(milliseconds: 1))), isTrue);
      expect(e.timestamp.isBefore(after.add(const Duration(milliseconds: 1))), isTrue);
    });
  });
}
