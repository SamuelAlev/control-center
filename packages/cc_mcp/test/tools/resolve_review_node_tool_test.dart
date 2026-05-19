import 'dart:convert';

import 'package:cc_domain/features/pr_review/domain/ports/review_finding_status_port.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_node_payload.dart';
import 'package:cc_mcp/src/tools/resolve_review_node_tool.dart';
import 'package:test/test.dart';

/// Records what the tool asked the port for. The behaviour behind the port —
/// the typed write, the trace in the room, the write-back onto the finalized
/// pass's counters — is covered where it lives, in cc_infra's
/// `review_finding_status_service_test.dart`. What matters here is that the
/// tool maps onto that one path rather than growing a second.
class _RecordingStatus implements ReviewFindingStatusPort {
  String? workspaceId;
  String? spaceId;
  String? nodeMessageId;
  ReviewNodeStatus? status;
  String? actorLabel;
  String? reason;
  Object? throwThis;

  @override
  Future<ReviewFindingStatusChange> setStatus({
    required String workspaceId,
    required String spaceId,
    required String nodeMessageId,
    required ReviewNodeStatus status,
    required String actorLabel,
    String? reason,
  }) async {
    if (throwThis != null) {
      throw throwThis!;
    }
    this.workspaceId = workspaceId;
    this.spaceId = spaceId;
    this.nodeMessageId = nodeMessageId;
    this.status = status;
    this.actorLabel = actorLabel;
    this.reason = reason;
    return ReviewFindingStatusChange(
      nodeMessageId: nodeMessageId,
      status: status,
      previousStatus: ReviewNodeStatus.open,
      suppressionRecorded: false,
    );
  }
}

Future<Map<String, dynamic>> _call(
  ResolveReviewNodeTool tool, {
  Map<String, dynamic> overrides = const {},
}) async {
  final result = await tool.call({
    'workspace_id': 'ws',
    'space_id': 'ch-1',
    'node_message_id': 'msg-1',
    'agent_id': 'engineer',
    ...overrides,
  });
  return {'isError': result.isError, 'text': result.content.first.text};
}

void main() {
  group('ResolveReviewNodeTool', () {
    late _RecordingStatus status;
    late ResolveReviewNodeTool tool;

    setUp(() {
      status = _RecordingStatus();
      tool = ResolveReviewNodeTool(status: status);
    });

    test('is named resolve_review_node', () {
      expect(tool.name, 'resolve_review_node');
    });

    test('delegates to the one status path', () async {
      // This is what gives `actionRate` a writer at all. The agent that made
      // the fix knows at the moment it is true; leaving it to a human pressing
      // "Fixed" afterwards is bookkeeping nobody does.
      final out = await _call(tool);
      expect(out['isError'], isFalse);
      expect(status.workspaceId, 'ws');
      expect(status.spaceId, 'ch-1');
      expect(status.nodeMessageId, 'msg-1');
      expect(status.status, ReviewNodeStatus.resolved);
      expect(status.actorLabel, 'engineer');
    });

    test('reports the move it made', () async {
      final out = await _call(tool);
      final json = jsonDecode(out['text'] as String) as Map<String, dynamic>;
      expect(json['status'], 'resolved');
      expect(json['previous_status'], 'open');
      expect(json['resolved_by'], 'engineer');
    });

    test('needs no reason, unlike a dismissal', () async {
      // A dismissal has to explain itself because it becomes a suppression
      // fact that silences the pattern on later PRs. A fix says the finding
      // was RIGHT — there is nothing to teach except to keep reporting it.
      final out = await _call(tool);
      expect(out['isError'], isFalse);
      expect(status.reason, isNull);
    });

    test('an optional note rides along to the room', () async {
      await _call(tool, overrides: const {'note': 'Guarded the null branch.'});
      expect(status.reason, 'Guarded the null branch.');
    });

    test('a non-string note is ignored rather than fatal', () async {
      // The note is a nicety. Refusing the whole resolve over a malformed one
      // would lose the status change, which is the part that matters.
      final out = await _call(tool, overrides: const {'note': 42});
      expect(out['isError'], isFalse);
      expect(status.status, ReviewNodeStatus.resolved);
      expect(status.reason, isNull);
    });

    test('rejects a missing workspace', () async {
      final result = await tool.call(const {
        'space_id': 'ch-1',
        'node_message_id': 'msg-1',
        'agent_id': 'engineer',
      });
      expect(result.isError, isTrue);
      expect(result.content.first.text, contains('workspace_id'));
      expect(status.status, isNull);
    });

    test('rejects a missing node id', () async {
      final result = await tool.call(const {
        'workspace_id': 'ws',
        'space_id': 'ch-1',
        'agent_id': 'engineer',
      });
      expect(result.isError, isTrue);
      expect(result.content.first.text, contains('node_message_id'));
      expect(status.status, isNull);
    });

    test('rejects a missing agent id', () async {
      // The trace in the room names who decided. "System marked this fixed"
      // tells a later reader nothing.
      final result = await tool.call(const {
        'workspace_id': 'ws',
        'space_id': 'ch-1',
        'node_message_id': 'msg-1',
      });
      expect(result.isError, isTrue);
      expect(result.content.first.text, contains('agent_id'));
      expect(status.status, isNull);
    });

    test('an unknown finding surfaces the reason verbatim', () async {
      status.throwThis = const ReviewFindingNotFound('msg-9');
      final out = await _call(tool);
      expect(out['isError'], isTrue);
      expect(out['text'], contains('msg-9'));
    });

    test('declares workspace_id required in its schema', () async {
      expect(tool.inputSchema['required'], contains('workspace_id'));
    });
  });
}
