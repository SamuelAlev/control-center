import 'dart:convert';

import 'package:cc_domain/features/pr_review/domain/ports/review_finding_status_port.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_node_payload.dart';
import 'package:cc_mcp/src/tools/dismiss_review_node_tool.dart';
import 'package:test/test.dart';

/// Records what the tool asked the port for. The behaviour behind the port —
/// writing the status through the typed payload, tracing it in the room and
/// recording the suppression fact — is covered where it lives, in cc_infra's
/// `review_finding_status_service_test.dart`. What matters here is that the
/// tool maps its arguments onto that one path instead of growing a second.
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
      suppressionRecorded: true,
    );
  }
}

Future<Map<String, dynamic>> _call(
  DismissReviewNodeTool tool, {
  Map<String, dynamic> overrides = const {},
}) async {
  final result = await tool.call({
    'workspace_id': 'ws',
    'space_id': 'ch-1',
    'node_message_id': 'msg-1',
    'agent_id': 'architect',
    'reason': 'The framework handles this automatically.',
    ...overrides,
  });
  return {'isError': result.isError, 'text': result.content.first.text};
}

void main() {
  group('DismissReviewNodeTool', () {
    late _RecordingStatus status;
    late DismissReviewNodeTool tool;

    setUp(() {
      status = _RecordingStatus();
      tool = DismissReviewNodeTool(status: status);
    });

    test('is named dismiss_review_node', () {
      expect(tool.name, 'dismiss_review_node');
    });

    test('delegates to the one status path', () async {
      final out = await _call(tool);
      expect(out['isError'], isFalse);
      expect(status.workspaceId, 'ws');
      expect(status.spaceId, 'ch-1');
      expect(status.nodeMessageId, 'msg-1');
      expect(status.status, ReviewNodeStatus.dismissed);
      expect(status.actorLabel, 'architect');
      expect(status.reason, 'The framework handles this automatically.');
    });

    test('reports the move and whether it taught anything', () async {
      final out = await _call(tool);
      final json = jsonDecode(out['text'] as String) as Map<String, dynamic>;
      expect(json['status'], 'dismissed');
      expect(json['previous_status'], 'open');
      expect(json['suppression_recorded'], isTrue);
      expect(json['dismissed_by'], 'architect');
    });

    test('requires a reason', () async {
      // The reason IS the suppression fact — a dismissal without one hides a
      // row and teaches nothing.
      final result = await tool.call({
        'workspace_id': 'ws',
        'space_id': 'ch-1',
        'node_message_id': 'msg-1',
        'agent_id': 'architect',
      });
      expect(result.isError, isTrue);
      expect(result.content.first.text, contains('reason'));
      expect(status.status, isNull);
    });

    test('rejects a missing workspace', () async {
      final result = await tool.call({
        'space_id': 'ch-1',
        'node_message_id': 'msg-1',
        'agent_id': 'a',
        'reason': 'r',
      });
      expect(result.isError, isTrue);
      expect(result.content.first.text, contains('workspace_id'));
    });

    test('surfaces a missing finding as an error, not a crash', () async {
      status.throwThis = const ReviewFindingNotFound('msg-1');
      final out = await _call(tool);
      expect(out['isError'], isTrue);
      expect(out['text'], contains('msg-1'));
    });

    test('declares its schema without inventing new required args', () {
      expect(
        tool.inputSchema['required'],
        containsAll([
          'workspace_id',
          'space_id',
          'node_message_id',
          'agent_id',
          'reason',
        ]),
      );
    });
  });
}
