// ignore_for_file: avoid_classes_with_only_static_members

import 'package:cc_domain/core/domain/value_objects/run_cost.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:cc_domain/features/dispatch/domain/entities/agent_process_event.dart';

/// Lossless JSON wire codec for the [AgentProcessEvent] sealed hierarchy.
///
/// A remote fleet worker uses this to stream its agent process events back to
/// the server over a JSON transport: [toWire] serializes each event into a
/// discriminated map (`kind` + `ts` + payload fields) and [fromWire]
/// reconstructs the exact subtype with every field intact, including the
/// original observation timestamp.
///
/// The `kind` discriminator is codec-local (camelCase, one per subtype) and is
/// intentionally distinct from [AgentProcessEventType]'s snake_case `name`,
/// which serves log-line coalescing rather than the wire.
abstract final class AgentProcessEventCodec {
  /// Serializes [event] into a JSON-safe map.
  ///
  /// The map always carries a `kind` discriminator and an ISO-8601 `ts`
  /// timestamp, followed by the subtype's structured fields. Optional fields
  /// are omitted when null so the round-trip is lossless.
  static Map<String, dynamic> toWire(AgentProcessEvent event) {
    final String ts = event.timestamp.toIso8601String();
    return switch (event) {
      TextEvent(:final content) => <String, dynamic>{
        'kind': 'text',
        'ts': ts,
        'content': content,
      },
      ThinkingEvent(:final content) => <String, dynamic>{
        'kind': 'thinking',
        'ts': ts,
        'content': content,
      },
      ToolCallEvent(:final toolName, :final toolCallId, :final inputs) =>
        <String, dynamic>{
          'kind': 'toolCall',
          'ts': ts,
          'toolName': toolName,
          'toolCallId': toolCallId,
          'inputs': ?inputs,
        },
      ToolResultEvent(
        :final toolCallId,
        :final outputs,
        :final toolName,
        :final isError,
        :final isPartial,
      ) =>
        <String, dynamic>{
          'kind': 'toolResult',
          'ts': ts,
          'toolCallId': toolCallId,
          'outputs': outputs,
          'toolName': ?toolName,
          'isError': isError,
          'isPartial': isPartial,
        },
      UsageEvent(:final usage, :final durationMs) => <String, dynamic>{
        'kind': 'usage',
        'ts': ts,
        'inputTokens': usage.inputTokens,
        'outputTokens': usage.outputTokens,
        'thoughtTokens': usage.thoughtTokens,
        'cachedReadTokens': usage.cachedReadTokens,
        'cachedWriteTokens': usage.cachedWriteTokens,
        'estimatedCostCents': usage.estimatedCostCents,
        'durationMs': ?durationMs,
      },
      ErrorEvent(:final content, :final code, :final source) =>
        <String, dynamic>{
          'kind': 'error',
          'ts': ts,
          'content': content,
          'code': ?code,
          'source': ?source,
        },
      SandboxViolationEvent(
        :final content,
        :final action,
        :final target,
        :final suggestedCapability,
      ) =>
        <String, dynamic>{
          'kind': 'sandboxViolation',
          'ts': ts,
          'content': content,
          'action': ?action,
          'target': ?target,
          'suggestedCapability': ?suggestedCapability,
        },
      DebugEvent(:final content) => <String, dynamic>{
        'kind': 'debug',
        'ts': ts,
        'content': content,
      },
      DoneEvent(:final outcome) => <String, dynamic>{
        'kind': 'done',
        'ts': ts,
        // Optional terminal-outcome override (e.g. 'max_turns') — absent on
        // a plain completion, so older readers see the shape they know.
        if (outcome != null) 'outcome': turnOutcomeToString(outcome),
      },
    };
  }

  /// Reconstructs an [AgentProcessEvent] from a wire map produced by [toWire].
  ///
  /// A missing or malformed `ts` degrades gracefully to [DateTime.now]. An
  /// unknown `kind` degrades to a [TextEvent] carrying whatever `content` was
  /// present, mirroring [AgentProcessEventTypeExtension.fromString].
  static AgentProcessEvent fromWire(Map<String, dynamic> json) {
    final DateTime timestamp = _parseTimestamp(json['ts']);
    final Object? kind = json['kind'];
    switch (kind) {
      case 'text':
        return TextEvent(
          content: _string(json['content']),
          timestamp: timestamp,
        );
      case 'thinking':
        return ThinkingEvent(
          content: _string(json['content']),
          timestamp: timestamp,
        );
      case 'toolCall':
        return ToolCallEvent(
          toolName: _string(json['toolName']),
          toolCallId: _string(json['toolCallId']),
          inputs: _mapOrNull(json['inputs']),
          timestamp: timestamp,
        );
      case 'toolResult':
        return ToolResultEvent(
          toolCallId: _string(json['toolCallId']),
          outputs: _string(json['outputs']),
          toolName: _stringOrNull(json['toolName']),
          isError: _bool(json['isError']),
          isPartial: _bool(json['isPartial']),
          timestamp: timestamp,
        );
      case 'usage':
        return UsageEvent(
          usage: RunUsage(
            inputTokens: _int(json['inputTokens']),
            outputTokens: _int(json['outputTokens']),
            thoughtTokens: _int(json['thoughtTokens']),
            cachedReadTokens: _int(json['cachedReadTokens']),
            cachedWriteTokens: _int(json['cachedWriteTokens']),
            estimatedCostCents: _int(json['estimatedCostCents']),
          ),
          durationMs: _intOrNull(json['durationMs']),
          timestamp: timestamp,
        );
      case 'error':
        return ErrorEvent(
          content: _string(json['content']),
          code: _stringOrNull(json['code']),
          source: _stringOrNull(json['source']),
          timestamp: timestamp,
        );
      case 'sandboxViolation':
        return SandboxViolationEvent(
          content: _string(json['content']),
          action: _stringOrNull(json['action']),
          target: _stringOrNull(json['target']),
          suggestedCapability: _stringOrNull(json['suggestedCapability']),
          timestamp: timestamp,
        );
      case 'debug':
        return DebugEvent(
          content: _string(json['content']),
          timestamp: timestamp,
        );
      case 'done':
        return DoneEvent(
          outcome: turnOutcomeFromString(_stringOrNull(json['outcome'])),
          timestamp: timestamp,
        );
      default:
        return TextEvent(
          content: _string(json['content']),
          timestamp: timestamp,
        );
    }
  }

  static DateTime _parseTimestamp(Object? raw) {
    if (raw is String) {
      final DateTime? parsed = DateTime.tryParse(raw);
      if (parsed != null) {
        return parsed;
      }
    }
    return DateTime.now();
  }

  static String _string(Object? value) => value is String ? value : '';

  static String? _stringOrNull(Object? value) => value is String ? value : null;

  static bool _bool(Object? value) => value is bool && value;

  static int _int(Object? value) => value is num ? value.toInt() : 0;

  static int? _intOrNull(Object? value) => value is num ? value.toInt() : null;

  static Map<String, dynamic>? _mapOrNull(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map(
        (Object? key, Object? v) => MapEntry<String, dynamic>('$key', v),
      );
    }
    return null;
  }
}
