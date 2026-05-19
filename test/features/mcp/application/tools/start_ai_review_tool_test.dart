import 'dart:convert';

import 'package:control_center/features/mcp/application/tools/start_ai_review_tool.dart';
import 'package:control_center/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:control_center/features/pipelines/domain/entities/pipeline_run.dart';
import 'package:control_center/features/pipelines/domain/entities/pipeline_run_status.dart';
import 'package:control_center/features/pipelines/domain/services/pipeline_engine.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Fake pipeline engine
// ---------------------------------------------------------------------------

class FakePipelineEngine implements PipelineEngine {
  PipelineRun? _nextResult;

  /// Arguments captured from last [start] call.
  String? lastTemplateId;
  String? lastWorkspaceId;
  String? lastTriggerEventType;
  Map<String, dynamic>? lastTriggerPayload;
  String? lastDedupKey;

  void stub(PipelineRun? result) {
    _nextResult = result;
  }

  @override
  Future<PipelineRun?> start(
    String templateId, {
    required String workspaceId,
    String? triggerEventType,
    Map<String, dynamic>? triggerPayload,
    String? dedupKey,
    String? parentPipelineRunId,
    String? parentStepId,
    bool dryRun = false,
  }) async {
    lastTemplateId = templateId;
    lastWorkspaceId = workspaceId;
    lastTriggerEventType = triggerEventType;
    lastTriggerPayload = triggerPayload;
    lastDedupKey = dedupKey;
    return _nextResult;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

PipelineRun _makeRun({
  String id = 'run-001',
  String templateId = 'pr_review',
  String workspaceId = 'ws-1',
  PipelineRunStatus status = PipelineRunStatus.running,
}) {
  return PipelineRun(
    id: id,
    templateId: templateId,
    workspaceId: workspaceId,
    status: status,
    startedAt: DateTime(2026, 6, 11, 12, 0, 0),
  );
}

Future<CallResult> _call(
  StartAiReviewTool tool, {
  dynamic workspaceId,
  dynamic prNodeId,
  dynamic prNumber,
  dynamic repoFullName,
}) {
  final args = <String, dynamic>{};
  if (workspaceId != null) {
    args['workspace_id'] = workspaceId;
  }
  if (prNodeId != null) {
    args['pr_node_id'] = prNodeId;
  }
  if (prNumber != null) {
    args['pr_number'] = prNumber;
  }
  if (repoFullName != null) {
    args['repo_full_name'] = repoFullName;
  }
  return tool.run(args);
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late FakePipelineEngine engine;
  late StartAiReviewTool tool;

  setUp(() {
    engine = FakePipelineEngine();
    tool = StartAiReviewTool(engine: engine as PipelineEngine);
  });

  // ===== Metadata =====

  group('StartAiReviewTool metadata', () {
    test('name is start_ai_review', () {
      expect(tool.name, 'start_ai_review');
    });

    test('description is non-empty', () {
      expect(tool.description, isNotEmpty);
      expect(tool.description.contains('AI review'), isTrue);
    });

    test('inputSchema structure', () {
      final schema = tool.inputSchema;
      expect(schema['type'], 'object');

      final required = schema['required'] as List<dynamic>;
      expect(required, containsAll([
        'workspace_id',
        'pr_node_id',
        'pr_number',
        'repo_full_name',
      ]));
      expect(required, hasLength(4));

      final props = schema['properties'] as Map<String, dynamic>;
      expect((props['workspace_id'] as Map<String, dynamic>)['type'], 'string');
      expect((props['pr_node_id'] as Map<String, dynamic>)['type'], 'string');
      expect((props['pr_number'] as Map<String, dynamic>)['type'], 'integer');
      expect((props['repo_full_name'] as Map<String, dynamic>)['type'], 'string');
    });
  });

  // ===== Validation errors =====

  group('validation errors', () {
    test('missing workspace_id → error', () async {
      final result = await _call(tool,
        prNodeId: 'node-1',
        prNumber: 42,
        repoFullName: 'owner/repo',
      );
      expect(result.isError, isTrue);
      expect(result.content[0].text, contains('workspace_id'));
    });

    test('missing pr_node_id → error', () async {
      final result = await _call(tool,
        workspaceId: 'ws-1',
        prNumber: 42,
        repoFullName: 'owner/repo',
      );
      expect(result.isError, isTrue);
      expect(result.content[0].text, contains('pr_node_id'));
    });

    test('missing pr_number → error', () async {
      final result = await _call(tool,
        workspaceId: 'ws-1',
        prNodeId: 'node-1',
        repoFullName: 'owner/repo',
      );
      expect(result.isError, isTrue);
      expect(result.content[0].text, contains('pr_number'));
    });

    test('missing repo_full_name → error', () async {
      final result = await _call(tool,
        workspaceId: 'ws-1',
        prNodeId: 'node-1',
        prNumber: 42,
      );
      expect(result.isError, isTrue);
      expect(result.content[0].text, contains('repo_full_name'));
    });

    test('workspace_id as int → error', () async {
      final result = await _call(tool,
        workspaceId: 123,
        prNodeId: 'node-1',
        prNumber: 42,
        repoFullName: 'owner/repo',
      );
      expect(result.isError, isTrue);
      expect(result.content[0].text, contains('workspace_id'));
    });

    test('pr_node_id as int → error', () async {
      final result = await _call(tool,
        workspaceId: 'ws-1',
        prNodeId: 999,
        prNumber: 42,
        repoFullName: 'owner/repo',
      );
      expect(result.isError, isTrue);
      expect(result.content[0].text, contains('pr_node_id'));
    });

    test('pr_number as String → error (expected int)', () async {
      final result = await _call(tool,
        workspaceId: 'ws-1',
        prNodeId: 'node-1',
        prNumber: '42',
        repoFullName: 'owner/repo',
      );
      expect(result.isError, isTrue);
      expect(result.content[0].text, contains('pr_number'));
    });

    test('repo_full_name as int → error', () async {
      final result = await _call(tool,
        workspaceId: 'ws-1',
        prNodeId: 'node-1',
        prNumber: 42,
        repoFullName: 99,
      );
      expect(result.isError, isTrue);
      expect(result.content[0].text, contains('repo_full_name'));
    });

    test('pr_number as double → error (expected int)', () async {
      final result = await _call(tool,
        workspaceId: 'ws-1',
        prNodeId: 'node-1',
        prNumber: 42.0,
        repoFullName: 'owner/repo',
      );
      expect(result.isError, isTrue);
      expect(result.content[0].text, contains('pr_number'));
    });

    test('repo_full_name with no slash → error', () async {
      final result = await _call(tool,
        workspaceId: 'ws-1',
        prNodeId: 'node-1',
        prNumber: 42,
        repoFullName: 'norepo',
      );
      expect(result.isError, isTrue);
      expect(result.content[0].text, contains('owner/repo'));
    });

    test('repo_full_name with multiple slashes → error', () async {
      final result = await _call(tool,
        workspaceId: 'ws-1',
        prNodeId: 'node-1',
        prNumber: 42,
        repoFullName: 'a/b/c',
      );
      expect(result.isError, isTrue);
      expect(result.content[0].text, contains('owner/repo'));
    });

    test('repo_full_name with only slash at start → accepted (split produces 2 parts)', () async {
      engine.stub(_makeRun());
      final result = await _call(tool,
        workspaceId: 'ws-1',
        prNodeId: 'node-1',
        prNumber: 42,
        repoFullName: '/repo',
      );
      expect(result.isError, isFalse,
          reason: '"/repo" splits to ["", "repo"] → length 2 → passes check');
    });

    test('repo_full_name with only slash at end → accepted (split produces 2 parts)', () async {
      engine.stub(_makeRun());
      final result = await _call(tool,
        workspaceId: 'ws-1',
        prNodeId: 'node-1',
        prNumber: 42,
        repoFullName: 'owner/',
      );
      expect(result.isError, isFalse,
          reason: '"owner/" splits to ["owner", ""] → length 2 → passes check');
    });
  });

  // ===== Edge value acceptance =====

  group('edge value acceptance', () {
    test('empty string workspace_id is passed through', () async {
      engine.stub(_makeRun());
      final result = await _call(tool,
        workspaceId: '',
        prNodeId: 'node-1',
        prNumber: 42,
        repoFullName: 'owner/repo',
      );
      expect(result.isError, isFalse);
      expect(engine.lastWorkspaceId, '');
    });

    test('empty string pr_node_id is passed through', () async {
      engine.stub(_makeRun());
      final result = await _call(tool,
        workspaceId: 'ws-1',
        prNodeId: '',
        prNumber: 42,
        repoFullName: 'owner/repo',
      );
      expect(result.isError, isFalse);
      expect(
        engine.lastTriggerPayload?['prNodeId'],
        '',
      );
    });

    test('pr_number as 0 → valid integer', () async {
      engine.stub(_makeRun());
      final result = await _call(tool,
        workspaceId: 'ws-1',
        prNodeId: 'node-1',
        prNumber: 0,
        repoFullName: 'owner/repo',
      );
      expect(result.isError, isFalse);
      final body = jsonDecode(result.content[0].text) as Map<String, dynamic>;
      expect(body['status'], 'started');
    });
  });

  // ===== Success paths =====

  group('success', () {
    test('engine returns run → response has pipeline_run_id and status=started',
        () async {
      engine.stub(_makeRun(id: 'run-abc', workspaceId: 'ws-x'));
      final result = await _call(tool,
        workspaceId: 'ws-x',
        prNodeId: 'node-1',
        prNumber: 99,
        repoFullName: 'acme/rocket',
      );

      expect(result.isError, isFalse);
      final body = jsonDecode(result.content[0].text) as Map<String, dynamic>;
      expect(body['pipeline_run_id'], 'run-abc');
      expect(body['status'], 'started');
    });

    test('triggerPayload has correct structure', () async {
      engine.stub(_makeRun());
      await _call(tool,
        workspaceId: 'ws-x',
        prNodeId: 'node-abc',
        prNumber: 42,
        repoFullName: 'acme/rocket',
      );

      final payload = engine.lastTriggerPayload;
      expect(payload, isNotNull);
      expect(payload!['workspaceId'], 'ws-x');
      expect(payload['repoOwner'], 'acme');
      expect(payload['repoName'], 'rocket');
      expect(payload['repoFullName'], 'acme/rocket');
      expect(payload['prNodeId'], 'node-abc');
      expect(payload['prNumber'], 42);
    });

    test('dedupKey is owner/repo#prNumber', () async {
      engine.stub(_makeRun());
      await _call(tool,
        workspaceId: 'ws-1',
        prNodeId: 'node-1',
        prNumber: 123,
        repoFullName: 'org/app',
      );

      expect(engine.lastDedupKey, 'org/app#123');
    });

    test('engine start called with correct params', () async {
      engine.stub(_makeRun());
      await _call(tool,
        workspaceId: 'ws-alpha',
        prNodeId: 'node-beta',
        prNumber: 7,
        repoFullName: 'team/lib',
      );

      expect(engine.lastTemplateId, 'pr_review');
      expect(engine.lastWorkspaceId, 'ws-alpha');
      expect(engine.lastTriggerEventType, 'mcp');
    });

    test('engine returns null (duplicate) → status=duplicate with message',
        () async {
      engine.stub(null);
      final result = await _call(tool,
        workspaceId: 'ws-1',
        prNodeId: 'node-1',
        prNumber: 42,
        repoFullName: 'owner/repo',
      );

      expect(result.isError, isFalse);
      final body = jsonDecode(result.content[0].text) as Map<String, dynamic>;
      expect(body['status'], 'duplicate');
      expect(body['message'], isNotEmpty);
      expect(
        body['message'],
        contains('already active'),
      );
    });
  });
}
