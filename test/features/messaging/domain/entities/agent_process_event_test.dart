import 'package:cc_domain/core/domain/value_objects/run_cost.dart';
import 'package:cc_domain/features/dispatch/domain/entities/agent_process_event.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AgentProcessEventType enum', () {
    test('has all nine values', () {
      expect(AgentProcessEventType.values, [
        AgentProcessEventType.thinking,
        AgentProcessEventType.text,
        AgentProcessEventType.toolCall,
        AgentProcessEventType.toolResult,
        AgentProcessEventType.usage,
        AgentProcessEventType.error,
        AgentProcessEventType.sandboxViolation,
        AgentProcessEventType.debug,
        AgentProcessEventType.done,
      ]);
    });
  });

  group('AgentProcessEventTypeExtension.name', () {
    test('returns correct name for each type', () {
      expect(AgentProcessEventType.thinking.name, 'thinking');
      expect(AgentProcessEventType.text.name, 'text');
      expect(AgentProcessEventType.toolCall.name, 'tool_call');
      expect(AgentProcessEventType.toolResult.name, 'tool_result');
      expect(AgentProcessEventType.usage.name, 'usage');
      expect(AgentProcessEventType.error.name, 'error');
      expect(AgentProcessEventType.done.name, 'done');
    });
  });

  group('AgentProcessEventTypeExtension.fromString', () {
    test('parses thinking', () {
      expect(
        AgentProcessEventTypeExtension.fromString('thinking'),
        AgentProcessEventType.thinking,
      );
    });

    test('parses text', () {
      expect(
        AgentProcessEventTypeExtension.fromString('text'),
        AgentProcessEventType.text,
      );
    });

    test('parses message as text (alias)', () {
      expect(
        AgentProcessEventTypeExtension.fromString('message'),
        AgentProcessEventType.text,
      );
    });

    test('parses tool_call', () {
      expect(
        AgentProcessEventTypeExtension.fromString('tool_call'),
        AgentProcessEventType.toolCall,
      );
    });

    test('parses tool_result', () {
      expect(
        AgentProcessEventTypeExtension.fromString('tool_result'),
        AgentProcessEventType.toolResult,
      );
    });

    test('parses usage', () {
      expect(
        AgentProcessEventTypeExtension.fromString('usage'),
        AgentProcessEventType.usage,
      );
    });

    test('parses error', () {
      expect(
        AgentProcessEventTypeExtension.fromString('error'),
        AgentProcessEventType.error,
      );
    });

    test('parses stderr as error (alias)', () {
      expect(
        AgentProcessEventTypeExtension.fromString('stderr'),
        AgentProcessEventType.error,
      );
    });

    test('parses done', () {
      expect(
        AgentProcessEventTypeExtension.fromString('done'),
        AgentProcessEventType.done,
      );
    });

    test('returns text for unknown values', () {
      expect(
        AgentProcessEventTypeExtension.fromString('unknown'),
        AgentProcessEventType.text,
      );
    });

    test('returns text for empty string', () {
      expect(
        AgentProcessEventTypeExtension.fromString(''),
        AgentProcessEventType.text,
      );
    });
  });

  group('AgentProcessEvent typed constructors', () {
    test('TextEvent creates event with correct type and content', () {
      final event = TextEvent(content: 'Hello');
      expect(event.type, AgentProcessEventType.text);
      expect(event.content, 'Hello');
      expect(event.metadata, isNull);
    });

    test('ThinkingEvent creates event with correct type and content', () {
      final event = ThinkingEvent(content: '...');
      expect(event.type, AgentProcessEventType.thinking);
      expect(event.content, '...');
    });

    test('ToolCallEvent creates event with structured fields', () {
      final event = ToolCallEvent(toolName: 'read', toolCallId: 'id-1');
      expect(event.type, AgentProcessEventType.toolCall);
      expect(event.content, 'read');
      expect(event.metadata, isNotNull);
      expect(event.metadata!['toolName'], 'read');
      expect(event.metadata!['toolCallId'], 'id-1');
    });

    test('ToolResultEvent creates event with outputs', () {
      final event = ToolResultEvent(toolCallId: 'id-1', outputs: 'result');
      expect(event.type, AgentProcessEventType.toolResult);
      expect(event.content, 'result');
      expect(event.metadata!['toolCallId'], 'id-1');
    });

    test('UsageEvent creates event with RunUsage', () {
      const usage = RunUsage(inputTokens: 100, outputTokens: 50);
      final event = UsageEvent(usage: usage);
      expect(event.type, AgentProcessEventType.usage);
      expect(event.content, '');
      expect(event.metadata!['inputTokens'], 100);
      expect(event.metadata!['outputTokens'], 50);
    });

    test('ErrorEvent creates event with correct type and content', () {
      final event = ErrorEvent(content: 'Something went wrong');
      expect(event.type, AgentProcessEventType.error);
      expect(event.content, 'Something went wrong');
    });

    test('SandboxViolationEvent creates event with correct type and content',
        () {
      final event = SandboxViolationEvent(content: 'file-read denied');
      expect(event.type, AgentProcessEventType.sandboxViolation);
      expect(event.content, 'file-read denied');
    });

    test('DebugEvent creates event with correct type and content', () {
      final event = DebugEvent(content: 'launching pi');
      expect(event.type, AgentProcessEventType.debug);
      expect(event.content, 'launching pi');
    });

    test('DoneEvent creates event with correct type', () {
      final event = DoneEvent();
      expect(event.type, AgentProcessEventType.done);
      expect(event.content, '');
    });
  });

  group('AgentProcessEvent == and hashCode', () {
    test('identical events are equal', () {
      final a = TextEvent(content: 'Hello');
      final b = TextEvent(content: 'Hello');
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('different type makes unequal', () {
      final a = TextEvent(content: 'Hello');
      final b = ThinkingEvent(content: 'Hello');
      expect(a, isNot(equals(b)));
    });

    test('different content makes unequal', () {
      final a = TextEvent(content: 'Hello');
      final b = TextEvent(content: 'World');
      expect(a, isNot(equals(b)));
    });

    test('metadata is excluded from equality', () {
      final a = ToolCallEvent(toolName: 'read', toolCallId: 'id-1');
      final b = ToolCallEvent(toolName: 'read', toolCallId: 'id-2');
      // Both have content = 'read' and type = toolCall, so they are equal
      // despite different metadata (toolCallId).
      expect(a, equals(b));
    });

    test('self equality', () {
      final a = TextEvent(content: 'Test');
      expect(a, equals(a));
    });
  });
}
