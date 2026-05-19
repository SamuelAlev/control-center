import 'package:cc_domain/features/service_status/domain/entities/github_service_status.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/service_status/presentation/widgets/github_degraded_banner.dart';
import 'package:control_center/features/service_status/providers/service_status_providers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_wrap.dart';

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

GitHubStatusIncident _incident(String id, String name) => GitHubStatusIncident(
  id: id,
  name: name,
  status: 'investigating',
  shortlink: 'https://stspg.io/$id',
  createdAt: DateTime(2026, 8, 17),
  updatedAt: DateTime(2026, 8, 17),
);

/// Status notifier resolving immediately to a scripted value.
class _StatusNotifier extends GitHubStatusNotifier {
  _StatusNotifier(this._value);
  final GitHubServiceStatus _value;

  @override
  Future<GitHubServiceStatus> build() async => _value;

  @override
  Future<void> refresh() async {}
}

Widget _wrap(GitHubServiceStatus status) => ProviderScope(
  overrides: [githubStatusProvider.overrideWith(() => _StatusNotifier(status))],
  child: testWrap(const GitHubDegradedBanner()),
);

void main() {
  group('isGitHubDegraded', () {
    test('flags every trouble indicator', () {
      expect(isGitHubDegraded(GitHubStatusIndicator.minor), isTrue);
      expect(isGitHubDegraded(GitHubStatusIndicator.major), isTrue);
      expect(isGitHubDegraded(GitHubStatusIndicator.critical), isTrue);
      expect(isGitHubDegraded(GitHubStatusIndicator.maintenance), isTrue);
    });

    test('an unreachable or unloaded status page is not trouble', () {
      expect(isGitHubDegraded(GitHubStatusIndicator.none), isFalse);
      expect(isGitHubDegraded(GitHubStatusIndicator.unknown), isFalse);
      expect(isGitHubDegraded(null), isFalse);
    });
  });

  group('githubDegradedKey', () {
    test('keys on the open incidents, order-independently', () {
      final key = githubDegradedKey(
        _status(
          GitHubStatusIndicator.major,
          incidents: [_incident('b', 'Second'), _incident('a', 'First')],
        ),
      );

      expect(key, 'a,b');
    });

    test('falls back to the indicator when GitHub named no incident', () {
      expect(
        githubDegradedKey(_status(GitHubStatusIndicator.maintenance)),
        'indicator:maintenance',
      );
    });

    test('is null while GitHub is healthy', () {
      expect(githubDegradedKey(_status(GitHubStatusIndicator.none)), isNull);
      expect(githubDegradedKey(null), isNull);
    });
  });

  group('GitHubDegradedBanner', () {
    testWidgets('stays out of the way while GitHub is healthy', (tester) async {
      await tester.pumpWidget(_wrap(_status(GitHubStatusIndicator.none)));
      await tester.pumpAndSettle();

      expect(find.byType(CcAlert), findsNothing);
      expect(tester.getSize(find.byType(GitHubDegradedBanner)), Size.zero);
    });

    testWidgets('reports the status word and the named incident', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          _status(
            GitHubStatusIndicator.critical,
            incidents: [_incident('i1', 'Incident with GitHub.com')],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('GitHub is reporting problems'), findsOneWidget);
      expect(find.textContaining('Outage'), findsOneWidget);
      expect(find.textContaining('Incident with GitHub.com'), findsOneWidget);
      expect(find.text('Open githubstatus.com'), findsOneWidget);
    });

    testWidgets('a real outage reads as danger', (tester) async {
      await tester.pumpWidget(_wrap(_status(GitHubStatusIndicator.critical)));
      await tester.pumpAndSettle();

      expect(
        tester.widget<CcAlert>(find.byType(CcAlert)).variant,
        CcAlertVariant.danger,
      );
    });

    testWidgets('a maintenance window reads as warning, not danger', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(_status(GitHubStatusIndicator.maintenance)),
      );
      await tester.pumpAndSettle();

      expect(
        tester.widget<CcAlert>(find.byType(CcAlert)).variant,
        CcAlertVariant.warning,
      );
    });

    testWidgets('dismissing hides it for that incident', (tester) async {
      final status = _status(
        GitHubStatusIndicator.major,
        incidents: [_incident('i1', 'Incident with GitHub.com')],
      );
      final container = ProviderContainer(
        overrides: [
          githubStatusProvider.overrideWith(() => _StatusNotifier(status)),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: testWrap(const GitHubDegradedBanner()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(CcAlert), findsOneWidget);

      container.read(dismissedGitHubBannersProvider.notifier).dismiss('i1');
      await tester.pumpAndSettle();

      expect(find.byType(CcAlert), findsNothing);
      // A NEW incident is new news — the old dismissal must not swallow it.
      expect(
        container.read(dismissedGitHubBannersProvider).contains('i2'),
        isFalse,
      );
    });
  });
}
