import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/messaging_events.dart';
import 'package:cc_domain/core/domain/events/pr_events.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:cc_server_core/src/notification_feed_recorder.dart';
import 'package:test/test.dart';

import 'helpers/test_database.dart';

Future<void> _pump() => Future<void>.delayed(const Duration(milliseconds: 50));

void main() {
  late DomainEventBus bus;
  late WorkspaceDatabaseManager dbs;
  late DaoNotificationFeedRepository repository;
  late NotificationFeedRecorder recorder;

  setUp(() {
    bus = DomainEventBus();
    dbs = createTestWorkspaceDatabases();
    repository = DaoNotificationFeedRepository(dbs);
    recorder = NotificationFeedRecorder(eventBus: bus, repository: repository)
      ..start();
  });

  tearDown(() async {
    await recorder.dispose();
    bus.dispose();
    await dbs.closeAll();
  });

  test('records one row per event into the owning workspace', () async {
    bus.publish(
      PrMerged(
        prId: 'pr-1',
        workspaceId: 'ws-1',
        agentId: 'agent-1',
        occurredAt: DateTime(2026, 8, 16),
      ),
    );
    await _pump();

    final items = await repository.watchFeed('ws-1').first;
    expect(items, hasLength(1));
    expect(items.single.method, 'notifications/pr_merged');
    expect(items.single.params['pr_id'], 'pr-1');
    expect(items.single.params['workspace_id'], 'ws-1');

    // The row landed in ws-1's file only.
    expect(await repository.watchFeed('ws-2').first, isEmpty);
  });

  test('applies the forwarding gate: un-mentioned human messages are not '
      'recorded, agent messages are', () async {
    bus.publish(
      MessageReceived(
        spaceId: 'ch-1',
        messageId: 'm-1',
        senderName: 'Sam',
        contentPreview: 'hello',
        isAgentMessage: false,
        workspaceId: 'ws-1',
        occurredAt: DateTime(2026, 8, 16),
      ),
    );
    bus.publish(
      MessageReceived(
        spaceId: 'ch-1',
        messageId: 'm-2',
        senderName: 'Bot',
        contentPreview: 'done',
        isAgentMessage: true,
        workspaceId: 'ws-1',
        occurredAt: DateTime(2026, 8, 16),
      ),
    );
    await _pump();

    final items = await repository.watchFeed('ws-1').first;
    expect(items, hasLength(1));
    expect(items.single.params['message_id'], 'm-2');
  });

  test('skips frames without a workspace id', () async {
    bus.publish(
      MessageReceived(
        spaceId: 'ch-1',
        messageId: 'm-1',
        senderName: 'Bot',
        contentPreview: 'done',
        isAgentMessage: true,
        workspaceId: null,
        occurredAt: DateTime(2026, 8, 16),
      ),
    );
    await _pump();

    expect(await repository.watchFeed('ws-1').first, isEmpty);
  });

  group('PR / code-review lanes', () {
    final at = DateTime(2026, 8, 30);

    /// Publishes [event] and returns the single method it recorded.
    Future<String> methodFor(DomainEvent event) async {
      bus.publish(event);
      await _pump();
      final items = await repository.watchFeed('ws-1').first;
      expect(items, hasLength(1));
      return items.single.method;
    }

    test('merge readiness records both edges under distinct methods', () async {
      expect(
        await methodFor(
          PrMergeReadinessChanged(
            workspaceId: 'ws-1',
            repoOwner: 'acme',
            repoName: 'widgets',
            prNumber: 42,
            prTitle: 'Add widgets',
            ready: true,
            reason: 'none',
            occurredAt: at,
          ),
        ),
        'notifications/pr_ready_to_merge',
      );
    });

    test('a blocked edge carries its reason', () async {
      bus.publish(
        PrMergeReadinessChanged(
          workspaceId: 'ws-1',
          repoOwner: 'acme',
          repoName: 'widgets',
          prNumber: 42,
          prTitle: 'Add widgets',
          ready: false,
          reason: 'conflicts',
          occurredAt: at,
        ),
      );
      await _pump();
      final item = (await repository.watchFeed('ws-1').first).single;
      expect(item.method, 'notifications/pr_merge_blocked');
      expect(item.params['reason'], 'conflicts');
    });

    test('each review decision maps to its own method', () async {
      const expected = {
        'approved': 'notifications/pr_approved',
        'changesRequested': 'notifications/pr_changes_requested',
        'dismissed': 'notifications/pr_review_dismissed',
      };
      for (final entry in expected.entries) {
        bus.publish(
          PrReviewDecisionChanged(
            workspaceId: 'ws-${entry.key}',
            repoOwner: 'acme',
            repoName: 'widgets',
            prNumber: 42,
            prTitle: 'Add widgets',
            decision: entry.key,
            reviewersRemaining: 1,
            occurredAt: at,
          ),
        );
        await _pump();
        final items = await repository.watchFeed('ws-${entry.key}').first;
        expect(items.single.method, entry.value, reason: entry.key);
        expect(items.single.params['reviewers_remaining'], 1);
      }
    });

    test('checks record their edge and the failing check', () async {
      bus.publish(
        PrChecksStatusChanged(
          workspaceId: 'ws-1',
          repoOwner: 'acme',
          repoName: 'widgets',
          prNumber: 42,
          prTitle: 'Add widgets',
          failing: true,
          failingCheckName: 'build',
          failingCheckUrl: 'https://ci.example/1',
          occurredAt: at,
        ),
      );
      await _pump();
      final item = (await repository.watchFeed('ws-1').first).single;
      expect(item.method, 'notifications/pr_checks_failed');
      expect(item.params['check_name'], 'build');
    });

    test('a comment mention records its anchor', () async {
      bus.publish(
        PrCommentMentioned(
          workspaceId: 'ws-1',
          repoOwner: 'acme',
          repoName: 'widgets',
          prNumber: 42,
          prTitle: 'Add widgets',
          commentId: 9001,
          authorLogin: 'octocat',
          bodyPreview: 'take a look',
          isReviewComment: true,
          path: 'lib/foo.dart',
          line: 42,
          occurredAt: at,
        ),
      );
      await _pump();
      final item = (await repository.watchFeed('ws-1').first).single;
      expect(item.method, 'notifications/pr_comment_mentioned');
      expect(item.params['comment_id'], 9001);
      expect(item.params['path'], 'lib/foo.dart');
      expect(item.params['line'], 42);
      expect(item.params['is_review_comment'], isTrue);
    });

    test('thread activity records both kinds', () async {
      expect(
        await methodFor(
          PrThreadReplied(
            workspaceId: 'ws-1',
            repoOwner: 'acme',
            repoName: 'widgets',
            prNumber: 42,
            prTitle: 'Add widgets',
            commentId: 7,
            authorLogin: 'hubot',
            bodyPreview: 'done',
            occurredAt: at,
          ),
        ),
        'notifications/pr_thread_replied',
      );
    });

    test('a resolved thread records its thread id', () async {
      bus.publish(
        PrThreadResolved(
          workspaceId: 'ws-1',
          repoOwner: 'acme',
          repoName: 'widgets',
          prNumber: 42,
          prTitle: 'Add widgets',
          threadId: 'PRRT_abc',
          commentId: 7,
          occurredAt: at,
        ),
      );
      await _pump();
      final item = (await repository.watchFeed('ws-1').first).single;
      expect(item.method, 'notifications/pr_thread_resolved');
      expect(item.params['thread_id'], 'PRRT_abc');
    });

    test('for_user_id rides along so the client can route it', () async {
      bus.publish(
        PrChecksStatusChanged(
          workspaceId: 'ws-1',
          repoOwner: 'acme',
          repoName: 'widgets',
          prNumber: 42,
          prTitle: 'Add widgets',
          failing: true,
          forUserId: 'user-1',
          occurredAt: at,
        ),
      );
      await _pump();
      final item = (await repository.watchFeed('ws-1').first).single;
      expect(item.params['for_user_id'], 'user-1');
    });
  });
}
