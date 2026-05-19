import 'dart:convert';

import 'package:control_center/features/mcp/application/tools/dispatch_reviewers_tool.dart';
import 'package:control_center/features/pipelines/domain/ports/dispatch_reviewers_port.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeDispatchReviewersPort implements DispatchReviewersPort {
  final List<_DispatchCall> calls = [];
  Map<String, dynamic>? _nextResult;

  void stubResult(Map<String, dynamic> result) => _nextResult = result;

  @override
  Future<Map<String, dynamic>> dispatch({
    required String channelId,
    required String workspaceId,
    required List<Map<String, dynamic>> reviewers,
    int? concurrency,
  }) async {
    calls.add(_DispatchCall(
      channelId: channelId,
      workspaceId: workspaceId,
      reviewers: reviewers,
      concurrency: concurrency,
    ));
    return _nextResult ?? {'dispatched': [], 'unmatched': []};
  }
}

class _DispatchCall {

  const _DispatchCall({
    required this.channelId,
    required this.workspaceId,
    required this.reviewers,
    this.concurrency,
  });
  final String channelId;
  final String workspaceId;
  final List<Map<String, dynamic>> reviewers;
  final int? concurrency;
}

void main() {
  group('DispatchReviewersTool', () {
    late _FakeDispatchReviewersPort service;
    late DispatchReviewersTool tool;

    setUp(() {
      service = _FakeDispatchReviewersPort();
      tool = DispatchReviewersTool(service: service);
    });

    group('metadata', () {
      test('has correct name', () {
        expect(tool.name, 'dispatch_reviewers');
      });

      test('has non-empty description', () {
        expect(tool.description, isNotEmpty);
      });

      test('inputSchema declares required fields', () {
        final schema = tool.inputSchema;
        expect(schema['type'], 'object');
        expect(
          schema['required'],
          containsAll(['channel_id', 'workspace_id', 'reviewers']),
        );
      });

      test('inputSchema properties have correct types', () {
        final props =
            tool.inputSchema['properties'] as Map<String, dynamic>;
        expect(
          (props['channel_id'] as Map<String, dynamic>)['type'],
          'string',
        );
        expect(
          (props['workspace_id'] as Map<String, dynamic>)['type'],
          'string',
        );
        expect(
          (props['reviewers'] as Map<String, dynamic>)['type'],
          'array',
        );
        expect(
          (props['concurrency'] as Map<String, dynamic>)['type'],
          'integer',
        );
      });

      test('requiresApproval is false (dispatch is idempotent/read-only)', () {
        expect(tool.requiresApproval, isFalse);
      });
    });

    group('argument validation', () {
      test('rejects missing channel_id', () async {
        final result = await tool.call({
          'workspace_id': 'ws-1',
          'reviewers': [
            {'role': 'security'},
          ],
        });
        expect(result.isError, isTrue);
        expect(
          result.content.first.text,
          contains('channel_id'),
        );
        expect(service.calls, isEmpty);
      });

      test('rejects null channel_id', () async {
        final result = await tool.call({
          'channel_id': null,
          'workspace_id': 'ws-1',
          'reviewers': [
            {'role': 'security'},
          ],
        });
        expect(result.isError, isTrue);
        expect(
          result.content.first.text,
          contains('channel_id'),
        );
      });

      test('rejects non-string channel_id', () async {
        final result = await tool.call({
          'channel_id': 42,
          'workspace_id': 'ws-1',
          'reviewers': [
            {'role': 'security'},
          ],
        });
        expect(result.isError, isTrue);
        expect(
          result.content.first.text,
          contains('channel_id'),
        );
      });

      test('rejects missing workspace_id', () async {
        final result = await tool.call({
          'channel_id': 'ch-1',
          'reviewers': [
            {'role': 'security'},
          ],
        });
        expect(result.isError, isTrue);
        expect(
          result.content.first.text,
          contains('workspace_id'),
        );
      });

      test('rejects null workspace_id', () async {
        final result = await tool.call({
          'channel_id': 'ch-1',
          'workspace_id': null,
          'reviewers': [
            {'role': 'security'},
          ],
        });
        expect(result.isError, isTrue);
        expect(
          result.content.first.text,
          contains('workspace_id'),
        );
      });

      test('rejects non-string workspace_id', () async {
        final result = await tool.call({
          'channel_id': 'ch-1',
          'workspace_id': [],
          'reviewers': [
            {'role': 'security'},
          ],
        });
        expect(result.isError, isTrue);
        expect(
          result.content.first.text,
          contains('workspace_id'),
        );
      });

      test('rejects missing reviewers', () async {
        final result = await tool.call({
          'channel_id': 'ch-1',
          'workspace_id': 'ws-1',
        });
        expect(result.isError, isTrue);
        expect(
          result.content.first.text,
          contains('reviewers'),
        );
      });

      test('rejects null reviewers', () async {
        final result = await tool.call({
          'channel_id': 'ch-1',
          'workspace_id': 'ws-1',
          'reviewers': null,
        });
        expect(result.isError, isTrue);
        expect(
          result.content.first.text,
          contains('reviewers'),
        );
      });

      test('rejects non-list reviewers', () async {
        final result = await tool.call({
          'channel_id': 'ch-1',
          'workspace_id': 'ws-1',
          'reviewers': 'not-a-list',
        });
        expect(result.isError, isTrue);
        expect(
          result.content.first.text,
          contains('reviewers'),
        );
      });

      test('rejects non-integer concurrency', () async {
        final result = await tool.call({
          'channel_id': 'ch-1',
          'workspace_id': 'ws-1',
          'reviewers': [
            {'role': 'security'},
          ],
          'concurrency': 'fast',
        });
        expect(result.isError, isTrue);
        expect(
          result.content.first.text,
          contains('concurrency'),
        );
      });

      test('accepts integer concurrency', () async {
        service.stubResult({'dispatched': [], 'unmatched': []});
        final result = await tool.call({
          'channel_id': 'ch-1',
          'workspace_id': 'ws-1',
          'reviewers': [
            {'role': 'security'},
          ],
          'concurrency': 4,
        });
        expect(result.isError, isFalse);
        expect(service.calls.single.concurrency, 4);
      });
    });

    group('success', () {
      test('forwards arguments to service with all fields', () async {
        service.stubResult({'dispatched': [], 'unmatched': []});
        final reviewers = [
          {'role': 'security', 'scope': 'lib/auth/**'},
          {'role': 'frontend', 'prompt_override': 'Check for a11y'},
        ];
        await tool.call({
          'channel_id': 'ch-1',
          'workspace_id': 'ws-1',
          'reviewers': reviewers,
          'concurrency': 3,
        });

        expect(service.calls, hasLength(1));
        final call = service.calls.first;
        expect(call.channelId, 'ch-1');
        expect(call.workspaceId, 'ws-1');
        expect(call.concurrency, 3);
        expect(call.reviewers, hasLength(2));
        expect(call.reviewers[0]['role'], 'security');
        expect(call.reviewers[0]['scope'], 'lib/auth/**');
        expect(call.reviewers[1]['role'], 'frontend');
        expect(call.reviewers[1]['prompt_override'], 'Check for a11y');
      });

      test('filters out non-Map entries from reviewers list', () async {
        service.stubResult({'dispatched': [], 'unmatched': []});
        await tool.call({
          'channel_id': 'ch-1',
          'workspace_id': 'ws-1',
          'reviewers': [
            {'role': 'security'},
            'not-a-map',
            42,
            null,
            {'role': 'backend'},
          ],
        });

        final call = service.calls.first;
        expect(call.reviewers, hasLength(2));
        expect(call.reviewers[0]['role'], 'security');
        expect(call.reviewers[1]['role'], 'backend');
      });

      test('omits concurrency when not provided', () async {
        service.stubResult({'dispatched': [], 'unmatched': []});
        await tool.call({
          'channel_id': 'ch-1',
          'workspace_id': 'ws-1',
          'reviewers': [
            {'role': 'security'},
          ],
        });

        expect(service.calls.first.concurrency, isNull);
      });

      test('returns dispatched and unmatched lists', () async {
        service.stubResult({
          'dispatched': [
            {'role': 'security', 'agent_id': 'agent-1'},
          ],
          'unmatched': [
            {'role': 'rust-expert'},
          ],
        });
        final result = await tool.call({
          'channel_id': 'ch-1',
          'workspace_id': 'ws-1',
          'reviewers': [
            {'role': 'security'},
            {'role': 'rust-expert'},
          ],
        });

        expect(result.isError, isFalse);
        final data =
            jsonDecode(result.content.first.text) as Map<String, dynamic>;
        expect(data['dispatched'] as List, hasLength(1));
        expect(
          (data['dispatched'] as List)[0],
          containsPair('role', 'security'),
        );
        expect(data['unmatched'] as List, hasLength(1));
        expect(
          (data['unmatched'] as List)[0],
          containsPair('role', 'rust-expert'),
        );
      });

      test('next_step is reviewers_ready when nothing unmatched', () async {
        service.stubResult({
          'dispatched': [
            {'role': 'security', 'agent_id': 'agent-1'},
          ],
          'unmatched': <Map<String, dynamic>>[],
        });
        final result = await tool.call({
          'channel_id': 'ch-1',
          'workspace_id': 'ws-1',
          'reviewers': [
            {'role': 'security'},
          ],
        });

        final data =
            jsonDecode(result.content.first.text) as Map<String, dynamic>;
        expect(data['next_step'], 'reviewers_ready');
      });

      test(
          'next_step hints propose_hire when unmatched roles exist',
          () async {
        service.stubResult({
          'dispatched': [],
          'unmatched': [
            {'role': 'rust-expert'},
          ],
        });
        final result = await tool.call({
          'channel_id': 'ch-1',
          'workspace_id': 'ws-1',
          'reviewers': [
            {'role': 'rust-expert'},
          ],
        });

        final data =
            jsonDecode(result.content.first.text) as Map<String, dynamic>;
        expect(data['next_step'], 'call propose_hire for each unmatched role');
      });
    });

    group('error propagation', () {
      test('wraps service exception into CallResult.error', () async {
        // Replace the fake with a throwing one.
        final throwingService = _ThrowingDispatchReviewersPort();
        final throwingTool = DispatchReviewersTool(service: throwingService);
        final result = await throwingTool.call({
          'channel_id': 'ch-1',
          'workspace_id': 'ws-1',
          'reviewers': [
            {'role': 'security'},
          ],
        });

        expect(result.isError, isTrue);
        expect(result.content.first.text, contains('BOOM'));
      });
    });
  });
}

class _ThrowingDispatchReviewersPort implements DispatchReviewersPort {
  @override
  Future<Map<String, dynamic>> dispatch({
    required String channelId,
    required String workspaceId,
    required List<Map<String, dynamic>> reviewers,
    int? concurrency,
  }) async {
    throw Exception('BOOM');
  }
}
