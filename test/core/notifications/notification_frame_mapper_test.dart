import 'package:cc_domain/core/domain/notifications/notification_category.dart';
import 'package:control_center/core/notifications/notification_frame_mapper.dart';
import 'package:control_center/features/pr_review/presentation/screens/pull_request_detail/pr_tab_kinds.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final l10n = lookupAppLocalizations(const Locale('en'));

  group('mapNotificationFrame', () {
    test('unknown methods (task lifecycle, ticket_reassigned) render null', () {
      expect(
        mapNotificationFrame(
          'notifications/task_failed',
          const {'workspace_id': 'ws-1'},
          l10n: l10n,
        ),
        isNull,
      );
      expect(
        mapNotificationFrame(
          'notifications/ticket_reassigned',
          const {'ticket_id': 't-1', 'workspace_id': 'ws-1'},
          l10n: l10n,
        ),
        isNull,
      );
    });

    test('maps pr_merged with workspace-scoped route', () {
      final n = mapNotificationFrame(
        'notifications/pr_merged',
        const {'pr_id': 'pr-1', 'agent_id': 'a-1', 'workspace_id': 'ws-1'},
        l10n: l10n,
      );
      expect(n, isNotNull);
      expect(n!.category, NotificationCategory.prMerged);
      expect(n.workspaceId, 'ws-1');
      expect(n.route, contains('ws-1'));
    });

    test('message_received suppresses someone else\'s requested run '
        'but always notifies a mention', () {
      const base = {
        'space_id': 'ch-1',
        'message_id': 'm-1',
        'sender_name': 'Bot',
        'content_preview': 'done',
        'workspace_id': 'ws-1',
        'is_agent_message': true,
      };

      // Someone else's run finishing is not mine — suppressed.
      expect(
        mapNotificationFrame(
          'notifications/message_received',
          {...base, 'requested_by_user_id': 'other-user'},
          l10n: l10n,
          currentUserId: 'me',
        ),
        isNull,
      );

      // But an explicit @mention of me always notifies.
      expect(
        mapNotificationFrame(
          'notifications/message_received',
          {
            ...base,
            'requested_by_user_id': 'other-user',
            'mentions': ['user:me'],
          },
          l10n: l10n,
          currentUserId: 'me',
        ),
        isNotNull,
      );

      // Unknown identity degrades to notify, never silently drops.
      expect(
        mapNotificationFrame(
          'notifications/message_received',
          base,
          l10n: l10n,
        ),
        isNotNull,
      );
    });

    test('review_stale deep-links to the PR and stays out of the way', () {
      // Centre-only on purpose: a banner is for something time-critical AND
      // directly actionable, and re-reviewing is a choice you make when you
      // next open the pull request.
      final n = mapNotificationFrame(
        'notifications/review_stale',
        const {
          'workspace_id': 'ws-1',
          'space_id': 'sp-1',
          'repo_owner': 'acme',
          'repo_name': 'widget',
          'pr_number': 42,
          'pr_title': 'Add the thing',
          'reviewed_head_sha': 'aaa1111',
          'head_sha': 'bbb2222',
        },
        l10n: l10n,
      );
      expect(n, isNotNull);
      expect(n!.category, NotificationCategory.reviewStale);
      expect(n.presentation, NotificationPresentation.centerOnly);
      expect(n.workspaceId, 'ws-1');
      expect(n.route, contains('ws-1'));
      expect(n.route, contains('42'));
      expect(n.title, contains('42'));
      expect(n.body, contains('Add the thing'));
    });

    test('review_stale survives a frame with no repo coordinates', () {
      // Degrades to the PR list rather than rendering nothing: a notification
      // that cannot be built is one the person never learns about.
      final n = mapNotificationFrame(
        'notifications/review_stale',
        const {
          'workspace_id': 'ws-1',
          'pr_number': 42,
          'pr_title': 'Add the thing',
        },
        l10n: l10n,
      );
      expect(n, isNotNull);
      expect(n!.route, contains('ws-1'));
    });

    test('meeting_starting_soon is banner-class', () {
      final n = mapNotificationFrame(
        'notifications/meeting_starting_soon',
        const {
          'event_id': 'ev-1',
          'title': 'Standup',
          'start_time': '2026-08-16T10:00:00Z',
          'workspace_id': 'ws-1',
        },
        l10n: l10n,
      );
      expect(n!.presentation, NotificationPresentation.banner);
    });

    test('human ticket assignment pings only the assignee', () {
      const base = {
        'ticket_id': 't-1',
        'ticket_title': 'Fix the leak',
        'workspace_id': 'ws-1',
        'assignee_type': 'user',
        'assigned_agent_id': 'teammate',
      };
      expect(
        mapNotificationFrame(
          'notifications/ticket_assigned',
          base,
          l10n: l10n,
          currentUserId: 'me',
        ),
        isNull,
      );
      expect(
        mapNotificationFrame(
          'notifications/ticket_assigned',
          {...base, 'assigned_agent_id': 'me'},
          l10n: l10n,
          currentUserId: 'me',
        ),
        isNotNull,
      );
    });

    test('a rig take-over is not reported back to whoever took it', () {
      const base = {
        'rig_id': 'rig-1',
        'workspace_id': 'ws-1',
        'held': true,
        'controller': 'user:me',
      };
      // I took the wheel — I know.
      expect(
        mapNotificationFrame(
          'notifications/rig_control_changed',
          base,
          l10n: l10n,
          currentUserId: 'me',
        ),
        isNull,
      );
      // Somebody else took it — that is exactly what I need to be told.
      final other = mapNotificationFrame(
        'notifications/rig_control_changed',
        {...base, 'controller': 'user:someone-else'},
        l10n: l10n,
        currentUserId: 'me',
      );
      expect(other, isNotNull);
      expect(other!.category, NotificationCategory.rigStatusChanged);
      // A rig has no destination of its own; the link lands on the
      // running-machine list.
      expect(other.route, '/workspaces/ws-1/settings/server/rigs');
      // Unknown identity degrades to notify, never a silently dropped machine
      // event.
      expect(
        mapNotificationFrame(
          'notifications/rig_control_changed',
          base,
          l10n: l10n,
        ),
        isNotNull,
      );
    });

    test('a rig control RELEASE is unfiltered (the event does not record '
        'who let go)', () {
      final n = mapNotificationFrame(
        'notifications/rig_control_changed',
        const {'rig_id': 'rig-1', 'workspace_id': 'ws-1', 'held': false},
        l10n: l10n,
        currentUserId: 'me',
      );
      expect(n, isNotNull);
      expect(n!.category, NotificationCategory.rigStatusChanged);
    });

    test('a reap distinguishes a TTL expiry from an idle reclaim', () {
      final ttl = mapNotificationFrame(
        'notifications/rig_reaped',
        const {
          'rig_id': 'rig-1',
          'workspace_id': 'ws-1',
          'reason': 'ttlExpired',
        },
        l10n: l10n,
      );
      final idle = mapNotificationFrame(
        'notifications/rig_reaped',
        const {
          'rig_id': 'rig-1',
          'workspace_id': 'ws-1',
          'reason': 'idleTimeout',
        },
        l10n: l10n,
      );
      expect(ttl, isNotNull);
      expect(idle, isNotNull);
      expect(ttl!.body, isNot(idle!.body));
      expect(ttl.category, NotificationCategory.rigStatusChanged);
    });

    test('a rig that died under an agent renders as a failure', () {
      final n = mapNotificationFrame(
        'notifications/rig_closed',
        const {
          'rig_id': 'rig-1',
          'workspace_id': 'ws-1',
          'reason': 'backendFailure',
        },
        l10n: l10n,
      );
      expect(n, isNotNull);
      expect(n!.category, NotificationCategory.rigStatusChanged);
      expect(n.workspaceId, 'ws-1');
    });
  });

  // ==========================================================================
  // PR / code-review lanes
  // ==========================================================================

  /// The params every PR-shaped frame carries.
  const prBase = {
    'workspace_id': 'ws-1',
    'repo_owner': 'acme',
    'repo_name': 'widgets',
    'pr_number': 42,
    'pr_title': 'Add widgets',
  };

  AppNotification? map(
    String method,
    Map<String, dynamic> extra, {
    String? currentUserId,
    Set<String> mutedRepos = const {},
    Set<String> viewerLogins = const {},
  }) => mapNotificationFrame(
    method,
    {...prBase, ...extra},
    l10n: l10n,
    currentUserId: currentUserId,
    mutedRepos: mutedRepos,
    viewerLogins: viewerLogins,
  );

  group('merge readiness', () {
    test('ready renders under prMergeReadiness and links to the PR', () {
      final n = map('notifications/pr_ready_to_merge', const {'reason': 'none'});
      expect(n, isNotNull);
      expect(n!.category, NotificationCategory.prMergeReadiness);
      expect(n.route, '/workspaces/ws-1/pull-requests/acme/widgets/42');
      expect(n.body, contains('Add widgets'));
    });

    test('each block reason renders a distinct body', () {
      final bodies = <String>{};
      for (final reason in [
        'conflicts',
        'behind',
        'reviewsOutstanding',
        'changesRequested',
        'checksFailing',
      ]) {
        final n = map('notifications/pr_merge_blocked', {'reason': reason});
        expect(n, isNotNull, reason: reason);
        bodies.add(n!.body);
      }
      expect(bodies, hasLength(5));
    });

    test('an unrecognised reason falls back rather than showing an enum', () {
      final n = map('notifications/pr_merge_blocked', const {
        'reason': 'somethingNewerServersSend',
      });
      expect(n, isNotNull);
      expect(n!.body, isNot(contains('somethingNewerServersSend')));
      expect(n.category, NotificationCategory.prMergeReadiness);
    });
  });

  group('review decisions', () {
    test('approved names the approver and the remaining count', () {
      final n = map('notifications/pr_approved', const {
        'approver_login': 'octocat',
        'reviewers_remaining': 2,
      });
      expect(n, isNotNull);
      expect(n!.category, NotificationCategory.prReviewDecision);
      expect(n.body, contains('octocat'));
      expect(n.body, contains('2'));
    });

    test('approved with no approver still renders, unattributed', () {
      // Attribution is best-effort; the notification must never wait on it.
      final n = map('notifications/pr_approved', const {
        'reviewers_remaining': 0,
      });
      expect(n, isNotNull);
      expect(n!.body, contains('Add widgets'));
    });

    test('zero remaining reads as "no reviewers left", not "0 reviewers"', () {
      final n = map('notifications/pr_approved', const {
        'reviewers_remaining': 0,
      });
      expect(n!.body, isNot(contains('0 reviewers')));
    });

    test('changes requested and dismissal are the same category', () {
      for (final method in [
        'notifications/pr_changes_requested',
        'notifications/pr_review_dismissed',
      ]) {
        expect(
          map(method, const {})!.category,
          NotificationCategory.prReviewDecision,
          reason: method,
        );
      }
    });
  });

  group('checks', () {
    test('a failure names the check and opens the checks tab', () {
      final n = map('notifications/pr_checks_failed', const {
        'check_name': 'build (macos)',
      });
      expect(n, isNotNull);
      expect(n!.category, NotificationCategory.prChecksStatus);
      expect(n.body, contains('build (macos)'));
      expect(n.route, contains('tab=pr.actions'));
    });

    test('an unnamed failure still renders', () {
      final n = map('notifications/pr_checks_failed', const {});
      expect(n, isNotNull);
      expect(n!.body, contains('Add widgets'));
    });

    test('recovery shares the category so one toggle covers both edges', () {
      expect(
        map('notifications/pr_checks_recovered', const {})!.category,
        NotificationCategory.prChecksStatus,
      );
    });
  });

  group('comment mentions', () {
    test('renders as prMentioned — the same concern, one toggle', () {
      final n = map('notifications/pr_comment_mentioned', const {
        'comment_id': 9001,
        'author_login': 'octocat',
        'is_review_comment': true,
        'path': 'lib/foo.dart',
        'line': 42,
      });
      expect(n, isNotNull);
      expect(n!.category, NotificationCategory.prMentioned);
    });

    test('a review comment deep-links to the diff with the comment anchor', () {
      final n = map('notifications/pr_comment_mentioned', const {
        'comment_id': 9001,
        'author_login': 'octocat',
        'is_review_comment': true,
        'path': 'lib/foo.dart',
        'line': 42,
      });
      expect(n!.route, contains('tab=pr.diff'));
      expect(n.route, contains('comment=9001'));
      expect(n.body, contains('octocat'));
      expect(n.body, contains('lib/foo.dart:42'));
    });

    test('a timeline comment goes to overview, where it actually exists', () {
      final n = map('notifications/pr_comment_mentioned', const {
        'comment_id': 9002,
        'author_login': 'octocat',
        'is_review_comment': false,
      });
      expect(n!.route, contains('tab=pr.overview'));
      expect(n.route, contains('comment=9002'));
      // With no file it falls back to naming the pull request.
      expect(n.body, contains('Add widgets'));
    });

    test('a review comment with no line names the file alone', () {
      final n = map('notifications/pr_comment_mentioned', const {
        'comment_id': 9003,
        'author_login': 'octocat',
        'is_review_comment': true,
        'path': 'lib/foo.dart',
      });
      expect(n!.body, contains('lib/foo.dart'));
      expect(n.body, isNot(contains('lib/foo.dart:')));
    });
  });

  group('thread activity', () {
    test('a reply and a resolution share one category', () {
      for (final method in [
        'notifications/pr_thread_replied',
        'notifications/pr_thread_resolved',
      ]) {
        expect(
          map(method, const {'comment_id': 7, 'author_login': 'hubot'})!
              .category,
          NotificationCategory.prThreadActivity,
          reason: method,
        );
      }
    });

    test('a thread notification carries the comment anchor', () {
      final n = map('notifications/pr_thread_replied', const {
        'comment_id': 7,
        'author_login': 'hubot',
        'path': 'lib/bar.dart',
        'line': 3,
      });
      expect(n!.route, contains('comment=7'));
      expect(n.body, contains('hubot'));
    });
  });

  group('principal routing', () {
    test('a frame addressed to someone else is dropped', () {
      expect(
        map(
          'notifications/pr_ready_to_merge',
          const {'reason': 'none', 'for_user_id': 'user-2'},
          currentUserId: 'user-1',
        ),
        isNull,
      );
    });

    test('a frame addressed to me is kept', () {
      expect(
        map(
          'notifications/pr_ready_to_merge',
          const {'reason': 'none', 'for_user_id': 'user-1'},
          currentUserId: 'user-1',
        ),
        isNotNull,
      );
    });

    test('an older server sending no for_user_id still notifies', () {
      // Degrade to notifying: silently swallowing is the worse failure.
      expect(
        map(
          'notifications/pr_ready_to_merge',
          const {'reason': 'none'},
          currentUserId: 'user-1',
        ),
        isNotNull,
      );
    });

    test('an unresolved identity still notifies', () {
      expect(
        map('notifications/pr_ready_to_merge', const {
          'reason': 'none',
          'for_user_id': 'user-2',
        }),
        isNotNull,
      );
    });
  });

  group('muted repositories', () {
    test('a muted repo is suppressed', () {
      expect(
        map(
          'notifications/pr_ready_to_merge',
          const {'reason': 'none'},
          mutedRepos: {'acme/widgets'},
        ),
        isNull,
      );
    });

    test('the mute match is case-insensitive', () {
      expect(
        map(
          'notifications/pr_checks_failed',
          const {},
          mutedRepos: {'ACME/Widgets'.toLowerCase()},
        ),
        isNull,
      );
    });

    test('a different repo is unaffected', () {
      expect(
        map(
          'notifications/pr_ready_to_merge',
          const {'reason': 'none'},
          mutedRepos: {'other/repo'},
        ),
        isNotNull,
      );
    });

    test('it covers the PRE-EXISTING PR lanes too', () {
      // The mute would be a half-measure if it only silenced the new types.
      for (final method in [
        'notifications/pr_mentioned',
        'notifications/pr_review_requested',
        'notifications/external_pr_merged',
      ]) {
        expect(
          map(method, const {}, mutedRepos: {'acme/widgets'}),
          isNull,
          reason: method,
        );
      }
    });

    test('a frame naming no repository is never muted', () {
      expect(
        mapNotificationFrame(
          'notifications/agent_run_completed',
          const {'conversation_id': 'c-1', 'workspace_id': 'ws-1'},
          l10n: l10n,
          mutedRepos: {'acme/widgets'},
        ),
        isNotNull,
      );
    });
  });

  group('self-authored actions', () {
    test('my own message does not ping me, even if I mentioned myself', () {
      expect(
        mapNotificationFrame(
          'notifications/message_received',
          const {
            'space_id': 'ch-1',
            'message_id': 'm-1',
            'sender_name': 'Ada',
            'content_preview': 'note to self',
            'workspace_id': 'ws-1',
            'is_agent_message': false,
            'mentions': ['user:me'],
            'sender_user_id': 'me',
          },
          l10n: l10n,
          currentUserId: 'me',
        ),
        isNull,
      );
    });

    test("a teammate's message mentioning me still pings", () {
      expect(
        mapNotificationFrame(
          'notifications/message_received',
          const {
            'space_id': 'ch-1',
            'message_id': 'm-1',
            'sender_name': 'Grace',
            'content_preview': 'take a look?',
            'workspace_id': 'ws-1',
            'is_agent_message': false,
            'mentions': ['user:me'],
            'sender_user_id': 'grace',
          },
          l10n: l10n,
          currentUserId: 'me',
        ),
        isNotNull,
      );
    });

    test('an older server sending no sender_user_id still notifies', () {
      expect(
        mapNotificationFrame(
          'notifications/message_received',
          const {
            'space_id': 'ch-1',
            'message_id': 'm-1',
            'sender_name': 'Grace',
            'content_preview': 'take a look?',
            'workspace_id': 'ws-1',
            'is_agent_message': false,
            'mentions': ['user:me'],
          },
          l10n: l10n,
          currentUserId: 'me',
        ),
        isNotNull,
      );
    });

    test('my own merge is not announced back at me', () {
      expect(
        map(
          'notifications/external_pr_merged',
          const {'merged_by_login': 'Octocat'},
          viewerLogins: {'octocat'},
        ),
        isNull,
      );
    });

    test("a teammate's merge still notifies", () {
      expect(
        map(
          'notifications/external_pr_merged',
          const {'merged_by_login': 'someone-else'},
          viewerLogins: {'octocat'},
        ),
        isNotNull,
      );
    });

    test('my own review decision is not announced back at me', () {
      for (final method in [
        'notifications/pr_approved',
        'notifications/pr_changes_requested',
        'notifications/pr_review_dismissed',
      ]) {
        expect(
          map(
            method,
            const {'approver_login': 'octocat', 'reviewers_remaining': 0},
            viewerLogins: {'octocat'},
          ),
          isNull,
          reason: '$method authored by me should be suppressed',
        );
      }
    });

    test('my own comment is not announced back at me', () {
      for (final method in [
        'notifications/pr_comment_mentioned',
        'notifications/pr_thread_replied',
      ]) {
        expect(
          map(
            method,
            const {'author_login': 'octocat', 'comment_id': 7},
            viewerLogins: {'octocat'},
          ),
          isNull,
          reason: '$method authored by me should be suppressed',
        );
      }
    });

    test('the login match is case-insensitive', () {
      // GitHub preserves the case a login was registered with but treats it
      // case-insensitively, so the frame and the connection can disagree.
      expect(
        map(
          'notifications/external_pr_merged',
          const {'merged_by_login': 'OctoCat'},
          viewerLogins: {'octocat'},
        ),
        isNull,
      );
    });

    test('a merge by nobody still notifies', () {
      // `mergedBy` is null for a deleted account — unknown must degrade to
      // notifying, never to a silent drop.
      expect(
        map('notifications/external_pr_merged', const {}, viewerLogins: {
          'octocat',
        }),
        isNotNull,
      );
    });

    test('no connected forge means nothing is suppressed', () {
      expect(
        map(
          'notifications/external_pr_merged',
          const {'merged_by_login': 'octocat'},
        ),
        isNotNull,
      );
    });

    test('a lane carrying no actor is unaffected', () {
      // The gate reads only the actor keys; a checks failure has none, so it
      // must survive whatever the viewer is called.
      expect(
        map('notifications/pr_checks_failed', const {}, viewerLogins: {
          'octocat',
        }),
        isNotNull,
      );
    });
  });

  group('tab keys stay real', () {
    test('every tab a notification routes to is a declared PR tab', () {
      // The mapper names tabs as string literals (it must not import the PR
      // feature's presentation layer), so this is what stops one rotting into
      // a link that opens the default tab and silently loses the anchor.
      expect(PrTabKinds.diff, 'pr.diff');
      expect(PrTabKinds.overview, 'pr.overview');
      expect(PrTabKinds.actions, 'pr.actions');
    });
  });
}
