import 'dart:convert';

import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_mcp/src/tools/start_ai_review_tool.dart';
import 'package:test/test.dart';

// ---------------------------------------------------------------------------
// Fake hub start
// ---------------------------------------------------------------------------

class FakeHubStart {
  Map<String, dynamic>? _nextResult;

  /// Arguments captured from the last call.
  String? lastWorkspaceId;
  String? lastOwner;
  String? lastRepo;
  int? lastPrNumber;
  String? lastLevel;

  void stub(Map<String, dynamic>? result) {
    _nextResult = result;
  }

  Future<Map<String, dynamic>> call({
    required String workspaceId,
    required String owner,
    required String repo,
    required int prNumber,
    String? requestedByUserId,
    String? level,
  }) async {
    lastWorkspaceId = workspaceId;
    lastOwner = owner;
    lastRepo = repo;
    lastPrNumber = prNumber;
    lastLevel = level;
    return _nextResult ??
        (throw StateError('FakeHubStart: no result stubbed — call stub()'));
  }
}

Future<CallResult> _call(
  StartAiReviewTool tool, {
  dynamic workspaceId,
  dynamic prNumber,
  dynamic repoFullName,
  dynamic level,
}) {
  final args = <String, dynamic>{};
  if (workspaceId != null) {
    args['workspace_id'] = workspaceId;
  }
  if (prNumber != null) {
    args['pr_number'] = prNumber;
  }
  if (repoFullName != null) {
    args['repo_full_name'] = repoFullName;
  }
  if (level != null) {
    args['level'] = level;
  }
  return tool.run(args);
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late FakeHubStart hub;
  late StartAiReviewTool tool;

  setUp(() {
    hub = FakeHubStart();
    tool = StartAiReviewTool(start: hub.call);
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
      expect(
        required,
        containsAll(['workspace_id', 'pr_number', 'repo_full_name']),
      );
      expect(required, hasLength(3));

      final props = schema['properties'] as Map<String, dynamic>;
      expect((props['workspace_id'] as Map<String, dynamic>)['type'], 'string');
      expect((props['pr_number'] as Map<String, dynamic>)['type'], 'integer');
      expect(
        (props['repo_full_name'] as Map<String, dynamic>)['type'],
        'string',
      );
    });
  });

  // ===== Validation errors =====

  group('validation errors', () {
    test('missing workspace_id → error', () async {
      final result = await _call(
        tool,
        prNumber: 42,
        repoFullName: 'owner/repo',
      );
      expect(result.isError, isTrue);
      expect(result.content[0].text, contains('workspace_id'));
    });

    test('missing pr_number → error', () async {
      final result = await _call(
        tool,
        workspaceId: 'ws-1',
        repoFullName: 'owner/repo',
      );
      expect(result.isError, isTrue);
      expect(result.content[0].text, contains('pr_number'));
    });

    test('missing repo_full_name → error', () async {
      final result = await _call(tool, workspaceId: 'ws-1', prNumber: 42);
      expect(result.isError, isTrue);
      expect(result.content[0].text, contains('repo_full_name'));
    });

    test('workspace_id as int → error', () async {
      final result = await _call(
        tool,
        workspaceId: 123,
        prNumber: 42,
        repoFullName: 'owner/repo',
      );
      expect(result.isError, isTrue);
      expect(result.content[0].text, contains('workspace_id'));
    });

    test('pr_number as String → error (expected int)', () async {
      final result = await _call(
        tool,
        workspaceId: 'ws-1',
        prNumber: '42',
        repoFullName: 'owner/repo',
      );
      expect(result.isError, isTrue);
      expect(result.content[0].text, contains('pr_number'));
    });

    test('repo_full_name as int → error', () async {
      final result = await _call(
        tool,
        workspaceId: 'ws-1',
        prNumber: 42,
        repoFullName: 99,
      );
      expect(result.isError, isTrue);
      expect(result.content[0].text, contains('repo_full_name'));
    });

    test('pr_number as double → error (expected int)', () async {
      final result = await _call(
        tool,
        workspaceId: 'ws-1',
        prNumber: 42.0,
        repoFullName: 'owner/repo',
      );
      expect(result.isError, isTrue);
      expect(result.content[0].text, contains('pr_number'));
    });

    test('repo_full_name with no slash → error', () async {
      final result = await _call(
        tool,
        workspaceId: 'ws-1',
        prNumber: 42,
        repoFullName: 'norepo',
      );
      expect(result.isError, isTrue);
      expect(result.content[0].text, contains('owner/repo'));
    });

    test('repo_full_name with multiple slashes → error', () async {
      final result = await _call(
        tool,
        workspaceId: 'ws-1',
        prNumber: 42,
        repoFullName: 'a/b/c',
      );
      expect(result.isError, isTrue);
      expect(result.content[0].text, contains('owner/repo'));
    });
  });

  // ===== Success paths =====

  group('success', () {
    test('result payload is passed through verbatim', () async {
      hub.stub({
        'status': 'started',
        'space_id': 'ch-abc',
        'pr_external_id': 'node-1',
      });
      final result = await _call(
        tool,
        workspaceId: 'ws-x',
        prNumber: 99,
        repoFullName: 'acme/rocket',
      );

      expect(result.isError, isFalse);
      final body = jsonDecode(result.content[0].text) as Map<String, dynamic>;
      expect(body['status'], 'started');
      expect(body['space_id'], 'ch-abc');
    });

    test('start called with the parsed repo coordinates', () async {
      hub.stub({'status': 'started'});
      await _call(
        tool,
        workspaceId: 'ws-x',
        prNumber: 42,
        repoFullName: 'acme/rocket',
      );

      expect(hub.lastWorkspaceId, 'ws-x');
      expect(hub.lastOwner, 'acme');
      expect(hub.lastRepo, 'rocket');
      expect(hub.lastPrNumber, 42);
    });

    test('pr_number as 0 → valid integer', () async {
      hub.stub({'status': 'started'});
      final result = await _call(
        tool,
        workspaceId: 'ws-1',
        prNumber: 0,
        repoFullName: 'owner/repo',
      );
      expect(result.isError, isFalse);
      final body = jsonDecode(result.content[0].text) as Map<String, dynamic>;
      expect(body['status'], 'started');
    });
  });

  group('review level', () {
    test('omitting level leaves it to the workspace default', () async {
      hub.stub({'status': 'started'});
      await _call(
        tool,
        workspaceId: 'ws-1',
        prNumber: 7,
        repoFullName: 'owner/repo',
      );
      expect(hub.lastLevel, isNull);
    });

    test('a valid level is forwarded verbatim', () async {
      hub.stub({'status': 'started'});
      for (final level in ['light', 'balanced', 'thorough']) {
        final result = await _call(
          tool,
          workspaceId: 'ws-1',
          prNumber: 7,
          repoFullName: 'owner/repo',
          level: level,
        );
        expect(result.isError, isFalse, reason: level);
        expect(hub.lastLevel, level);
      }
    });

    test('an unknown level is rejected rather than coerced', () async {
      // Silently reviewing at some other depth would hide the caller's bug.
      hub.stub({'status': 'started'});
      final result = await _call(
        tool,
        workspaceId: 'ws-1',
        prNumber: 7,
        repoFullName: 'owner/repo',
        level: 'exhaustive',
      );
      expect(result.isError, isTrue);
      expect(result.content[0].text, contains('level'));
    });

    test('a non-string level is rejected', () async {
      hub.stub({'status': 'started'});
      final result = await _call(
        tool,
        workspaceId: 'ws-1',
        prNumber: 7,
        repoFullName: 'owner/repo',
        level: 3,
      );
      expect(result.isError, isTrue);
    });

    test('the schema advertises the three levels', () {
      final props = tool.inputSchema['properties'] as Map<String, dynamic>;
      final level = props['level'] as Map<String, dynamic>;
      expect(level['enum'], ['light', 'balanced', 'thorough']);
      // Optional: a caller that says nothing gets the workspace default.
      expect(tool.inputSchema['required'], isNot(contains('level')));
    });
  });
}
