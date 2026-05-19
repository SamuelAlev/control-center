import 'dart:convert';

import 'package:control_center/core/errors/app_exceptions.dart';
import 'package:control_center/features/mcp/application/tools/publish_review_to_github_tool.dart';
import 'package:control_center/features/pr_review/domain/ports/review_publisher_port.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeReviewPublisher implements ReviewPublisherPort {
  PublishReviewResult? _stubResult;
  Object? _stubError;

  void stubResult(PublishReviewResult result) => _stubResult = result;
  void stubError(Object error) => _stubError = error;

  String? lastWorkspaceId;
  String? lastChannelId;
  ReviewPublishSelection? lastSelection;
  bool? lastApproveOnShip;

  @override
  Future<PublishReviewResult> publish({
    required String workspaceId,
    required String channelId,
    ReviewPublishSelection selection = ReviewPublishSelection.consensus,
    bool approveOnShip = false,
  }) async {
    lastWorkspaceId = workspaceId;
    lastChannelId = channelId;
    lastSelection = selection;
    lastApproveOnShip = approveOnShip;

    if (_stubError != null) {
      throw _stubError!;
    }
    return _stubResult!;
  }
}

void main() {
  group('PublishReviewToGithubTool', () {
    late _FakeReviewPublisher service;
    late PublishReviewToGithubTool tool;

    setUp(() {
      service = _FakeReviewPublisher();
      tool = PublishReviewToGithubTool(service: service);
    });

    group('metadata', () {
      test('name', () {
        expect(tool.name, 'publish_review_to_github');
      });

      test('description mentions publishing', () {
        expect(tool.description, isNotEmpty);
        expect(tool.description, contains('Publishes'));
      });

      test('inputSchema has required fields', () {
        final schema = tool.inputSchema;
        expect(schema['type'], 'object');
        final required = schema['required'] as List<dynamic>;
        expect(required, contains('workspace_id'));
        expect(required, contains('channel_id'));
      });

      test('inputSchema properties include selection and approve_on_ship', () {
        final props = tool.inputSchema['properties'] as Map<String, dynamic>;
        final selectionProp = props['selection'] as Map<String, dynamic>;
        expect(selectionProp['type'], 'string');
        expect(selectionProp['enum'], ['consensus', 'all_open']);

        final approveProp = props['approve_on_ship'] as Map<String, dynamic>;
        expect(approveProp['type'], 'boolean');
      });

      test('definition matches name', () {
        final def = tool.definition;
        expect(def.name, 'publish_review_to_github');
        expect(def.inputSchema, tool.inputSchema);
      });
      test('requiresApproval defaults to false', () {
        expect(tool.requiresApproval, isFalse);
      });
    });

    group('argument validation', () {
      test('rejects missing workspace_id', () async {
        final result = await tool.call({'channel_id': 'ch-1'});

        expect(result.isError, isTrue);
        expect(result.content.first.text, contains('workspace_id'));
      });

      test('rejects non-string workspace_id', () async {
        final result = await tool.call({
          'workspace_id': 42,
          'channel_id': 'ch-1',
        });

        expect(result.isError, isTrue);
        expect(result.content.first.text, contains('workspace_id'));
      });

      test('rejects missing channel_id', () async {
        final result = await tool.call({'workspace_id': 'ws-1'});

        expect(result.isError, isTrue);
        expect(result.content.first.text, contains('channel_id'));
      });

      test('rejects non-string channel_id', () async {
        final result = await tool.call({
          'workspace_id': 'ws-1',
          'channel_id': true,
        });

        expect(result.isError, isTrue);
        expect(result.content.first.text, contains('channel_id'));
      });
    });

    group('default argument values', () {
      test('selection defaults to consensus when omitted', () async {
        service.stubResult(const PublishReviewResult(
          reviewId: 1,
          event: 'COMMENT',
          findingCount: 0,
          inlineCount: 0,
          usedFallback: false,
        ));

        await tool.call({'workspace_id': 'ws-1', 'channel_id': 'ch-1'});

        expect(service.lastSelection, ReviewPublishSelection.consensus);
      });

      test('selection defaults to consensus when unrecognized', () async {
        service.stubResult(const PublishReviewResult(
          reviewId: 2,
          event: 'COMMENT',
          findingCount: 0,
          inlineCount: 0,
          usedFallback: false,
        ));

        await tool.call({
          'workspace_id': 'ws-1',
          'channel_id': 'ch-1',
          'selection': 'bogus_value',
        });

        expect(service.lastSelection, ReviewPublishSelection.consensus);
      });

      test('selection all_open maps to allOpen', () async {
        service.stubResult(const PublishReviewResult(
          reviewId: 3,
          event: 'COMMENT',
          findingCount: 0,
          inlineCount: 0,
          usedFallback: false,
        ));

        await tool.call({
          'workspace_id': 'ws-1',
          'channel_id': 'ch-1',
          'selection': 'all_open',
        });

        expect(service.lastSelection, ReviewPublishSelection.allOpen);
      });

      test('approve_on_ship defaults to false', () async {
        service.stubResult(const PublishReviewResult(
          reviewId: 4,
          event: 'COMMENT',
          findingCount: 0,
          inlineCount: 0,
          usedFallback: false,
        ));

        await tool.call({'workspace_id': 'ws-1', 'channel_id': 'ch-1'});

        expect(service.lastApproveOnShip, isFalse);
      });

      test('approve_on_ship true is forwarded', () async {
        service.stubResult(const PublishReviewResult(
          reviewId: 5,
          event: 'APPROVE',
          findingCount: 0,
          inlineCount: 0,
          usedFallback: false,
        ));

        await tool.call({
          'workspace_id': 'ws-1',
          'channel_id': 'ch-1',
          'approve_on_ship': true,
        });

        expect(service.lastApproveOnShip, isTrue);
      });

      test('approve_on_ship false (explicit) is forwarded as false', () async {
        service.stubResult(const PublishReviewResult(
          reviewId: 6,
          event: 'COMMENT',
          findingCount: 0,
          inlineCount: 0,
          usedFallback: false,
        ));

        await tool.call({
          'workspace_id': 'ws-1',
          'channel_id': 'ch-1',
          'approve_on_ship': false,
        });

        expect(service.lastApproveOnShip, isFalse);
      });
    });

    group('success', () {
      test('returns published result as JSON', () async {
        service.stubResult(const PublishReviewResult(
          reviewId: 42,
          event: 'APPROVE',
          findingCount: 7,
          inlineCount: 5,
          usedFallback: false,
        ));

        final result = await tool.call({
          'workspace_id': 'ws-1',
          'channel_id': 'ch-1',
        });

        expect(result.isError, isFalse);
        final data =
            jsonDecode(result.content.first.text) as Map<String, dynamic>;
        expect(data['status'], 'published');
        expect(data['review_id'], 42);
        expect(data['event'], 'APPROVE');
        expect(data['finding_count'], 7);
        expect(data['inline_count'], 5);
        expect(data['used_body_fallback'], false);
      });

      test('passes workspace and channel through to service', () async {
        service.stubResult(const PublishReviewResult(
          reviewId: 10,
          event: 'COMMENT',
          findingCount: 1,
          inlineCount: 1,
          usedFallback: false,
        ));

        await tool.call({
          'workspace_id': 'ws-alpha',
          'channel_id': 'ch-beta',
        });

        expect(service.lastWorkspaceId, 'ws-alpha');
        expect(service.lastChannelId, 'ch-beta');
      });

      test('reports used_body_fallback true', () async {
        service.stubResult(const PublishReviewResult(
          reviewId: 99,
          event: 'REQUEST_CHANGES',
          findingCount: 3,
          inlineCount: 0,
          usedFallback: true,
        ));

        final result = await tool.call({
          'workspace_id': 'ws-1',
          'channel_id': 'ch-1',
        });

        final data =
            jsonDecode(result.content.first.text) as Map<String, dynamic>;
        expect(data['used_body_fallback'], true);
        expect(data['inline_count'], 0);
      });

      test('REQUEST_CHANGES event is surfaced', () async {
        service.stubResult(const PublishReviewResult(
          reviewId: 77,
          event: 'REQUEST_CHANGES',
          findingCount: 2,
          inlineCount: 2,
          usedFallback: false,
        ));

        final result = await tool.call({
          'workspace_id': 'ws-1',
          'channel_id': 'ch-1',
        });

        final data =
            jsonDecode(result.content.first.text) as Map<String, dynamic>;
        expect(data['event'], 'REQUEST_CHANGES');
      });
    });

    group('errors', () {
      test('WorkspaceMismatchException returns error with message', () async {
        service.stubError(
          const WorkspaceMismatchException('Channel belongs to workspace B'),
        );

        final result = await tool.call({
          'workspace_id': 'ws-A',
          'channel_id': 'ch-1',
        });

        expect(result.isError, isTrue);
        expect(
          result.content.first.text,
          'Channel belongs to workspace B',
        );
      });

      test('ArgumentError returns error with message', () async {
        service.stubError(ArgumentError('Invalid PR number: -1'));

        final result = await tool.call({
          'workspace_id': 'ws-1',
          'channel_id': 'ch-1',
        });

        expect(result.isError, isTrue);
        expect(
          result.content.first.text,
          'Invalid PR number: -1',
        );
      });

      test('ArgumentError with null message returns fallback', () async {
        service.stubError(ArgumentError());

        final result = await tool.call({
          'workspace_id': 'ws-1',
          'channel_id': 'ch-1',
        });

        expect(result.isError, isTrue);
        expect(
          result.content.first.text,
          'Invalid argument',
        );
      });

      test('AppException wraps message with prefix', () async {
        service.stubError(
          const NetworkException('Rate limit exceeded', code: 'RATE_LIMIT'),
        );

        final result = await tool.call({
          'workspace_id': 'ws-1',
          'channel_id': 'ch-1',
        });

        expect(result.isError, isTrue);
        expect(
          result.content.first.text,
          'Failed to publish review: Rate limit exceeded',
        );
      });

      test('unexpected exception is caught by call wrapper', () async {
        service.stubError(Exception('Something exploded'));

        final result = await tool.call({
          'workspace_id': 'ws-1',
          'channel_id': 'ch-1',
        });

        expect(result.isError, isTrue);
        expect(result.content.first.text, contains('Something exploded'));
      });
    });
  });
}
