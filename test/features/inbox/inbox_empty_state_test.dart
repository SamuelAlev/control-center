import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_domain/features/service_status/domain/entities/github_service_status.dart';
import 'package:control_center/features/forge/providers/forge_providers.dart';
import 'package:control_center/features/inbox/presentation/widgets/inbox_empty_state.dart';
import 'package:control_center/features/service_status/providers/service_status_providers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_wrap.dart';

GitHubServiceStatus _status(
  GitHubStatusIndicator indicator, {
  List<GitHubStatusIncident> incidents = const [],
}) => GitHubServiceStatus(
  indicator: indicator,
  description: 'Partial System Outage',
  components: const [],
  incidents: incidents,
  fetchedAt: DateTime(2026, 8, 17),
);

GitHubStatusIncident _incident(String name) => GitHubStatusIncident(
  id: 'i1',
  name: name,
  status: 'investigating',
  shortlink: 'https://stspg.io/abc',
  createdAt: DateTime(2026, 8, 17),
  updatedAt: DateTime(2026, 8, 17),
);

Widget _wrap({
  required GitHubStatusIndicator indicator,
  String login = 'samuelalev',
  List<GitHubStatusIncident> incidents = const [],
}) => ProviderScope(
  overrides: [
    githubStatusProvider.overrideWithValue(
      AsyncValue.data(_status(indicator, incidents: incidents)),
    ),
    viewerLoginsProvider.overrideWith(
      (ref) => login.isEmpty ? const {} : {ForgeHost.github: login},
    ),
  ],
  child: testWrap(const InboxEmptyState()),
);

void main() {
  group('resolveInboxEmptyCaveat', () {
    test('a healthy GitHub with a resolved login has no caveat', () {
      expect(
        resolveInboxEmptyCaveat(
          indicator: GitHubStatusIndicator.none,
          viewerLogins: const {ForgeHost.github: 'octocat'},
        ),
        isNull,
      );
    });

    test('every degraded indicator raises the GitHub caveat', () {
      for (final indicator in [
        GitHubStatusIndicator.minor,
        GitHubStatusIndicator.major,
        GitHubStatusIndicator.critical,
        GitHubStatusIndicator.maintenance,
      ]) {
        expect(
          resolveInboxEmptyCaveat(
            indicator: indicator,
            viewerLogins: const {ForgeHost.github: 'octocat'},
          ),
          InboxEmptyCaveat.githubDegraded,
          reason: '$indicator must be flagged',
        );
      }
    });

    test('an unresolved login raises the identity caveat', () {
      expect(
        resolveInboxEmptyCaveat(
          indicator: GitHubStatusIndicator.none,
          viewerLogins: const {},
        ),
        InboxEmptyCaveat.identityUnresolved,
      );
    });

    // The specific fact wins: "GitHub might be down" is true during an outage
    // but leaves the operator with no idea why their inbox is empty, while an
    // unresolved login says it is empty by construction.
    test('an unresolved login outranks a degraded GitHub', () {
      expect(
        resolveInboxEmptyCaveat(
          indicator: GitHubStatusIndicator.critical,
          viewerLogins: const {},
        ),
        InboxEmptyCaveat.identityUnresolved,
      );
    });

    test(
      'an unloaded or unreachable status page is not evidence by itself',
      () {
        expect(
          resolveInboxEmptyCaveat(
            indicator: null,
            viewerLogins: const {ForgeHost.github: 'octocat'},
          ),
          isNull,
        );
        expect(
          resolveInboxEmptyCaveat(
            indicator: GitHubStatusIndicator.unknown,
            viewerLogins: const {ForgeHost.github: 'octocat'},
          ),
          isNull,
        );
      },
    );
  });

  group('InboxEmptyState', () {
    testWidgets('claims "all caught up" only when GitHub is healthy', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(indicator: GitHubStatusIndicator.none));
      await tester.pumpAndSettle();

      expect(find.text("You're all caught up"), findsOneWidget);
      expect(find.text('GitHub might be down'), findsNothing);
    });

    testWidgets('reports a possible outage instead of a clear queue', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          indicator: GitHubStatusIndicator.critical,
          incidents: [_incident('Incident with GitHub.com')],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text("You're all caught up"), findsNothing);
      expect(find.text('GitHub might be down'), findsOneWidget);
      // The status word matches the service-status tag's vocabulary and the
      // incident GitHub named is quoted verbatim.
      expect(find.textContaining('Outage'), findsOneWidget);
      expect(find.textContaining('Incident with GitHub.com'), findsOneWidget);
      expect(find.text('Open githubstatus.com'), findsOneWidget);
    });

    testWidgets('explains an unresolved identity rather than an empty queue', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(indicator: GitHubStatusIndicator.none, login: ''),
      );
      await tester.pumpAndSettle();

      expect(find.text("You're all caught up"), findsNothing);
      expect(find.text("Couldn't confirm your GitHub account"), findsOneWidget);
      expect(
        find.text('Open githubstatus.com'),
        findsNothing,
        reason: 'a healthy GitHub is not the culprit, so do not point there',
      );
    });

    // The state the operator actually hit: GitHub degraded AND the login
    // unresolved. The headline must be the specific fact, with the outage
    // named as the likely cause.
    testWidgets('during an outage it still names the identity as the blocker', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          indicator: GitHubStatusIndicator.major,
          login: '',
          incidents: [_incident('Incident with GitHub.com')],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text("Couldn't confirm your GitHub account"), findsOneWidget);
      expect(find.text('GitHub might be down'), findsNothing);
      expect(
        find.textContaining('GitHub status: Major issues.'),
        findsOneWidget,
      );
      expect(find.textContaining('Incident with GitHub.com'), findsOneWidget);
      expect(find.text('Open githubstatus.com'), findsOneWidget);
    });
  });
}
