import 'package:cc_domain/cc_domain.dart' show UserDto;
import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_domain/core/domain/ports/import_hold_review.dart';
import 'package:cc_domain/core/domain/ports/server_notice_feed.dart';
import 'package:cc_domain/core/domain/repositories/server_notice_repository.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/repos/providers/repo_providers.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/system/import_holds_section.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/system/server_notices_section.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/l10n/localizations_loader.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// Settings → Server → Backup & restore, the two review cards above the
/// backups: what only the server owner can fix (a read-only workspace), and
/// the grants a restored copy carried, waiting to be accepted or dismissed.
void main() {
  final now = DateTime.utc(2026, 11, 12, 9);
  final payments = Workspace(
    id: 'ws-1',
    name: 'Payments',
    createdAt: now,
    updatedAt: now,
  );

  Widget wrap({
    required ServerNoticeFeed notices,
    required ImportHoldReview holds,
    required Widget child,
    bool owner = true,
    TextDirection textDirection = TextDirection.ltr,
  }) {
    return ProviderScope(
      overrides: [
        isServerOwnerProvider.overrideWithValue(owner),
        workspacesProvider.overrideWith((ref) => Stream.value([payments])),
        serverNoticeFeedProvider.overrideWithValue(notices),
        importHoldReviewProvider.overrideWithValue(holds),
        usersByIdProvider.overrideWith(
          (ref) => Stream.value({
            'u1': UserDto(id: 'u1', handle: 'ada', displayName: 'Ada Lovelace'),
          }),
        ),
        reposForWorkspaceProvider.overrideWith(
          (ref, workspaceId) => Stream.value([
            Repo(
              id: 'r1',
              name: 'shop-ui',
              path: '/repos/shop-ui',
              remoteOwner: 'acme',
              remoteName: 'shop-ui',
              createdAt: now,
              updatedAt: now,
            ),
          ]),
        ),
      ],
      child: CcTheme(
        data: CcThemeData.light(),
        child: MaterialApp(
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Directionality(
            textDirection: textDirection,
            child: CcToastScope(
              child: Scaffold(body: SingleChildScrollView(child: child)),
            ),
          ),
        ),
      ),
    );
  }

  void tallView(WidgetTester tester) {
    tester.view.physicalSize = const Size(1400, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  group('server notices', () {
    testWidgets('a read-only workspace is named, dated and explained', (
      tester,
    ) async {
      final feed = _Notices([
        ServerNotice(
          kind: ServerNoticeKind.workspaceReadOnly,
          subject: 'ws-1',
          detail: '*** in database main ***\nrow 12 missing from index',
          createdAt: now,
        ),
      ]);
      await tester.pumpWidget(
        wrap(
          notices: feed,
          holds: _Holds({}),
          child: const ServerNoticesSection(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Needs your attention'), findsOneWidget);
      expect(find.text('Payments'), findsOneWidget);
      expect(find.text('Read-only'), findsOneWidget);
      expect(find.textContaining('Since '), findsOneWidget);
      expect(
        find.textContaining('Restore it from a backup in the lists below'),
        findsOneWidget,
      );
      // The database's own finding stays behind Details until asked for.
      expect(find.textContaining('row 12 missing'), findsNothing);
      await tester.tap(find.text('Details'));
      await tester.pumpAndSettle();
      expect(find.textContaining('row 12 missing'), findsOneWidget);
    });

    testWidgets('a workspace this client cannot name shows its id', (
      tester,
    ) async {
      final feed = _Notices([
        ServerNotice(
          kind: ServerNoticeKind.workspaceReadOnly,
          subject: 'ws-gone',
          detail: '',
          createdAt: now,
        ),
      ]);
      await tester.pumpWidget(
        wrap(
          notices: feed,
          holds: _Holds({}),
          child: const ServerNoticesSection(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ws-gone'), findsOneWidget);
      expect(find.text('Details'), findsNothing);
    });

    testWidgets('no notices, no card', (tester) async {
      await tester.pumpWidget(
        wrap(
          notices: _Notices(const []),
          holds: _Holds({}),
          child: const ServerNoticesSection(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Needs your attention'), findsNothing);
    });

    testWidgets('anyone but the server owner never asks', (tester) async {
      final feed = _Notices(const []);
      await tester.pumpWidget(
        wrap(
          notices: feed,
          holds: _Holds({}),
          owner: false,
          child: const ServerNoticesSection(),
        ),
      );
      await tester.pumpAndSettle();

      expect(feed.calls, 0);
    });
  });

  group('held grants', () {
    ImportHoldView hold(String id, String kind, Map<String, Object?> payload) =>
        ImportHoldView(
          id: id,
          wireKind: kind,
          payload: payload,
          importedAt: now,
          sourceInstallId: 'install-a',
        );

    List<ImportHoldView> everyKind() => [
      hold('h-allow', 'action_policy', {
        'scope_type': 'workspace',
        'scope_id': 'ws-1',
        'command_prefix': 'git push',
        'decision': 'allow',
      }),
      hold('h-prompt', 'action_policy', {
        'scope_type': 'agent',
        'scope_id': 'agent-9',
        'command_prefix': 'rm',
        'decision': 'prompt',
      }),
      hold('h-exec', 'sandbox_exec_grant', {
        'path': '/usr/bin/make',
        'decision': 'allow',
      }),
      hold('h-write', 'repo_grant', {
        'user_id': 'u1',
        'repo_id': 'r1',
        'level': 'write',
      }),
      hold('h-review', 'repo_grant', {
        'user_id': 'u2',
        'repo_id': 'r2',
        'level': 'review',
      }),
      hold('h-role', 'membership_role', {
        'user_id': 'u3',
        'role': 'admin',
        'display_name': 'Grace',
      }),
      hold('h-invite', 'invite', {
        'role': 'admin',
        'repo_grants_json': '{"r1":"write","r2":"read"}',
      }),
      hold('h-new', 'grant_from_the_future', {'x': 1}),
    ];

    Finder inRow(String holdId, String text) => find.descendant(
      of: find.byKey(ValueKey(holdId)),
      matching: find.text(text),
    );

    testWidgets('no holds, no card', (tester) async {
      await tester.pumpWidget(
        wrap(
          notices: _Notices(const []),
          holds: _Holds({'ws-1': []}),
          child: const ImportHoldsSection(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Held back from restored copies'), findsNothing);
    });

    testWidgets('each kind says what it would grant to whom', (tester) async {
      tallView(tester);
      await tester.pumpWidget(
        wrap(
          notices: _Notices(const []),
          holds: _Holds({'ws-1': everyKind()}),
          child: const ImportHoldsSection(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Held back from restored copies'), findsOneWidget);
      expect(find.text('Payments'), findsOneWidget);
      for (final sentence in [
        'Agents may do this without approval: Run commands starting with git push',
        'Agents may do this once a person approves: Run commands starting with rm',
        'Sandboxes may run /usr/bin/make',
        'Ada Lovelace may change shop-ui',
        'u2 may review pull requests in r2',
        'Grace gets the Admin role',
        'An open invite to join with the Admin role and review or write access to 1 repository',
        "A permission this version of the app can't describe",
      ]) {
        expect(find.text(sentence), findsOneWidget, reason: sentence);
      }
      expect(inRow('h-allow', 'Everywhere in this workspace'), findsOneWidget);
      expect(inRow('h-prompt', 'For agent agent-9'), findsOneWidget);
      // Nobody can accept what nobody could read first.
      expect(inRow('h-new', 'Accept'), findsNothing);
      expect(inRow('h-new', 'Dismiss'), findsOneWidget);
    });

    testWidgets('accepting a rule confirms first, then applies it', (
      tester,
    ) async {
      tallView(tester);
      final review = _Holds({'ws-1': everyKind()});
      await tester.pumpWidget(
        wrap(
          notices: _Notices(const []),
          holds: review,
          child: const ImportHoldsSection(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(inRow('h-allow', 'Accept'));
      await tester.pumpAndSettle();
      expect(find.text('Grant this permission?'), findsOneWidget);
      expect(review.resolved, isEmpty);

      await tester.tap(find.text('Accept').last);
      await tester.pumpAndSettle();

      expect(review.resolved, [('ws-1', 'h-allow', true)]);
      expect(find.text('Permission granted.'), findsOneWidget);
      expect(find.byKey(const ValueKey('h-allow')), findsNothing);
    });

    testWidgets('cancelling the confirmation applies nothing', (tester) async {
      tallView(tester);
      final review = _Holds({'ws-1': everyKind()});
      await tester.pumpWidget(
        wrap(
          notices: _Notices(const []),
          holds: review,
          child: const ImportHoldsSection(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(inRow('h-exec', 'Accept'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(review.resolved, isEmpty);
      expect(find.byKey(const ValueKey('h-exec')), findsOneWidget);
    });

    testWidgets('a repository grant is accepted without a dialog', (
      tester,
    ) async {
      tallView(tester);
      final review = _Holds({'ws-1': everyKind()}, applied: false);
      await tester.pumpWidget(
        wrap(
          notices: _Notices(const []),
          holds: review,
          child: const ImportHoldsSection(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(inRow('h-write', 'Accept'));
      await tester.pumpAndSettle();

      expect(find.text('Grant this permission?'), findsNothing);
      expect(review.resolved, [('ws-1', 'h-write', true)]);
      // Its member left in the meantime: the server applied nothing.
      expect(
        find.text(
          'Nothing was granted: who or what it was for is no longer in this '
          'workspace.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('dismissing drops it, even a kind nobody can read', (
      tester,
    ) async {
      tallView(tester);
      final review = _Holds({'ws-1': everyKind()});
      await tester.pumpWidget(
        wrap(
          notices: _Notices(const []),
          holds: review,
          child: const ImportHoldsSection(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(inRow('h-new', 'Dismiss'));
      await tester.pumpAndSettle();

      expect(review.resolved, [('ws-1', 'h-new', false)]);
      expect(find.byKey(const ValueKey('h-new')), findsNothing);
    });

    testWidgets('anyone but the server owner sees nothing and asks nothing', (
      tester,
    ) async {
      final review = _Holds({'ws-1': everyKind()});
      await tester.pumpWidget(
        wrap(
          notices: _Notices(const []),
          holds: review,
          owner: false,
          child: const ImportHoldsSection(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Held back from restored copies'), findsNothing);
      expect(review.lists, 0);
    });

    testWidgets('mirrors under a right-to-left locale', (tester) async {
      tallView(tester);
      await tester.pumpWidget(
        wrap(
          notices: _Notices(const []),
          holds: _Holds({'ws-1': everyKind()}),
          textDirection: TextDirection.rtl,
          child: const ImportHoldsSection(),
        ),
      );
      await tester.pumpAndSettle();

      final sentence = tester.getRect(
        find.text('Sandboxes may run /usr/bin/make'),
      );
      final accept = tester.getRect(inRow('h-exec', 'Accept'));
      expect(accept.right, lessThan(sentence.left));
    });
  });
}

class _Notices implements ServerNoticeFeed {
  _Notices(this.notices);

  final List<ServerNotice> notices;
  int calls = 0;

  @override
  Future<List<ServerNotice>> open() async {
    calls++;
    return notices;
  }
}

/// Holds per workspace; a resolved hold leaves the list, as on the server.
class _Holds implements ImportHoldReview {
  _Holds(this.byWorkspace, {this.applied = true});

  final Map<String, List<ImportHoldView>> byWorkspace;
  final bool applied;
  final List<(String, String, bool)> resolved = [];
  int lists = 0;

  @override
  Future<List<ImportHoldView>> list(String workspaceId) async {
    lists++;
    return List.of(byWorkspace[workspaceId] ?? const []);
  }

  @override
  Future<bool> resolve({
    required String workspaceId,
    required String holdId,
    required bool accept,
  }) async {
    resolved.add((workspaceId, holdId, accept));
    byWorkspace[workspaceId]?.removeWhere((h) => h.id == holdId);
    return accept && applied;
  }
}
