import 'dart:async';

import 'package:cc_domain/features/github_status/domain/entities/github_service_status.dart';
import 'package:control_center/features/github_status/presentation/widgets/github_status_indicator.dart';
import 'package:control_center/features/github_status/providers/github_status_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_wrap.dart';

/// Helper to create a test status with the given indicator.
GitHubServiceStatus _status(GitHubStatusIndicator indicator) {
  return GitHubServiceStatus(
    indicator: indicator,
    description: 'All Systems Operational',
    components: const [],
    incidents: const [],
    fetchedAt: DateTime(2024),
  );
}

/// A notifier that immediately resolves to a data value.
class _DataNotifier extends GitHubStatusNotifier {
  _DataNotifier(this._status);
  final GitHubServiceStatus _status;

  @override
  Future<GitHubServiceStatus> build() async => _status;

  @override
  Future<void> refresh() async {}
}

/// A notifier that stays in loading state — [build] never completes.
class _LoadingNotifier extends GitHubStatusNotifier {
  @override
  Future<GitHubServiceStatus> build() async {
    return Completer<GitHubServiceStatus>().future;
  }
}

/// A notifier that sets state to error and stays there.
class _ErrorNotifier extends GitHubStatusNotifier {
  @override
  Future<GitHubServiceStatus> build() async {
    state = AsyncValue.error(Exception('Test error'), StackTrace.current);
    // Never complete — keeps state at error.
    return Completer<GitHubServiceStatus>().future;
  }
}
/// Wraps [child] in a [ProviderScope] with [githubStatusProvider] overridden
/// using [notifier], plus the standard `testWrap` infrastructure.
Widget _wrap(Widget child, GitHubStatusNotifier notifier) {
  return ProviderScope(
    overrides: [
      githubStatusProvider.overrideWith(() => notifier),
    ],
    child: testWrap(child),
  );
}

void main() {
  group('GitHubStatusButton chip', () {
    testWidgets('renders label', (tester) async {
      await tester.pumpWidget(_wrap(
        const GitHubStatusButton(),
        _DataNotifier(_status(GitHubStatusIndicator.none)),
      ));
      await tester.pumpAndSettle();

      expect(find.text('GitHub status'), findsOneWidget);
    });

    testWidgets('renders in loading state', (tester) async {
      await tester.pumpWidget(_wrap(
        const GitHubStatusButton(),
        _LoadingNotifier(),
      ));
      await tester.pump();

      expect(find.text('GitHub status'), findsOneWidget);
    });

    testWidgets('renders in error state', (tester) async {
      await tester.pumpWidget(_wrap(
        const GitHubStatusButton(),
        _ErrorNotifier(),
      ));
      await tester.pumpAndSettle();

      expect(find.text('GitHub status'), findsOneWidget);
    });

    for (final indicator in GitHubStatusIndicator.values) {
      testWidgets('builds with indicator ${indicator.name}', (tester) async {
        await tester.pumpWidget(_wrap(
          const GitHubStatusButton(),
          _DataNotifier(_status(indicator)),
        ));
        await tester.pumpAndSettle();

        expect(find.text('GitHub status'), findsOneWidget);
      });
    }
  });

  group('GitHubStatusButton flyout', () {
    testWidgets('shows loading body on tap while loading', (tester) async {
      await tester.pumpWidget(_wrap(
        const GitHubStatusButton(),
        _LoadingNotifier(),
      ));
      await tester.pump();

      await tester.tap(find.text('GitHub status'));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows error body on tap when errored', (tester) async {
      await tester.pumpWidget(_wrap(
        const GitHubStatusButton(),
        _ErrorNotifier(),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('GitHub status'));
      await tester.pump();
      tester.takeException(); // Consume pre-existing Row overflow

      expect(find.text("Couldn't reach githubstatus.com"), findsOneWidget);
      expect(find.text('Refresh'), findsOneWidget);
    });

    testWidgets('shows data body on tap with operational status', (tester) async {
      await tester.pumpWidget(_wrap(
        const GitHubStatusButton(),
        _DataNotifier(_status(GitHubStatusIndicator.none)),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('GitHub status'));
      await tester.pumpAndSettle();
      expect(find.text('All systems operational'), findsOneWidget);
    });

    testWidgets('shows data body with degraded status', (tester) async {
      final degraded = GitHubServiceStatus(
        indicator: GitHubStatusIndicator.minor,
        description: 'Minor Service Outage',
        components: const [],
        incidents: const [],
        fetchedAt: DateTime(2024),
      );

      await tester.pumpWidget(_wrap(
        const GitHubStatusButton(),
        _DataNotifier(degraded),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('GitHub status'));
      await tester.pumpAndSettle();

      expect(find.text('Minor Service Outage'), findsOneWidget);
    });

    testWidgets('shows data body with critical status', (tester) async {
      final critical = GitHubServiceStatus(
        indicator: GitHubStatusIndicator.critical,
        description: 'Major Service Outage',
        components: const [],
        incidents: const [],
        fetchedAt: DateTime(2024),
      );

      await tester.pumpWidget(_wrap(
        const GitHubStatusButton(),
        _DataNotifier(critical),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('GitHub status'));
      await tester.pumpAndSettle();

      expect(find.text('Major Service Outage'), findsOneWidget);
    });
  });
}
