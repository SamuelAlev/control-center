import 'dart:async';

import 'package:cc_domain/features/service_status/domain/entities/github_service_status.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/service_status/presentation/widgets/service_status_indicator.dart';
import 'package:control_center/features/service_status/providers/service_status_providers.dart';
import 'package:control_center/shared/widgets/refresh_control.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_wrap.dart';

/// Helper to create a test status with the given indicator.
GitHubServiceStatus _status(
  GitHubStatusIndicator indicator, {
  List<GitHubStatusComponent> components = const [],
  List<GitHubStatusIncident> incidents = const [],
}) {
  return GitHubServiceStatus(
    indicator: indicator,
    description: 'All Systems Operational',
    components: components,
    incidents: incidents,
    fetchedAt: DateTime(2024),
  );
}

GitHubStatusIncident _incident(String name) => GitHubStatusIncident(
  id: 'i1',
  name: name,
  status: 'investigating',
  shortlink: 'https://stspg.io/abc',
  createdAt: DateTime(2024),
  updatedAt: DateTime(2024),
);

GitHubStatusComponent _component(String name, GitHubComponentStatus status) =>
    GitHubStatusComponent(id: name, name: name, status: status, position: 0);

/// GitHub notifier that immediately resolves to a data value.
class _GithubDataNotifier extends GitHubStatusNotifier {
  _GithubDataNotifier(this._status);
  final GitHubServiceStatus _status;

  int refreshCalls = 0;

  @override
  Future<GitHubServiceStatus> build() async => _status;

  @override
  Future<void> refresh() async {
    refreshCalls++;
  }
}

/// Claude notifier that immediately resolves to a data value.
class _ClaudeDataNotifier extends ClaudeStatusNotifier {
  _ClaudeDataNotifier(this._status);
  final GitHubServiceStatus _status;

  int refreshCalls = 0;

  @override
  Future<GitHubServiceStatus> build() async => _status;

  @override
  Future<void> refresh() async {
    refreshCalls++;
  }
}

/// OpenAI notifier that immediately resolves to a data value.
class _OpenAIDataNotifier extends OpenAIStatusNotifier {
  _OpenAIDataNotifier(this._status);
  final GitHubServiceStatus _status;

  int refreshCalls = 0;

  @override
  Future<GitHubServiceStatus> build() async => _status;

  @override
  Future<void> refresh() async {
    refreshCalls++;
  }
}

/// Kimi notifier that immediately resolves to a data value.
class _KimiDataNotifier extends KimiStatusNotifier {
  _KimiDataNotifier(this._status);
  final GitHubServiceStatus _status;

  int refreshCalls = 0;

  @override
  Future<GitHubServiceStatus> build() async => _status;

  @override
  Future<void> refresh() async {
    refreshCalls++;
  }
}

/// GitHub notifier that sets state to error and stays there.
class _GithubErrorNotifier extends GitHubStatusNotifier {
  @override
  Future<GitHubServiceStatus> build() async {
    state = AsyncValue.error(Exception('Test error'), StackTrace.current);
    // Never complete — keeps state at error.
    return Completer<GitHubServiceStatus>().future;
  }

  @override
  Future<void> refresh() async {}
}

/// Claude notifier that stays in loading state — [build] never completes.
class _ClaudeLoadingNotifier extends ClaudeStatusNotifier {
  @override
  Future<GitHubServiceStatus> build() async {
    return Completer<GitHubServiceStatus>().future;
  }

  @override
  Future<void> refresh() async {}
}

/// GitHub notifier that stays in loading state — [build] never completes.
class _GithubLoadingNotifier extends GitHubStatusNotifier {
  @override
  Future<GitHubServiceStatus> build() async {
    return Completer<GitHubServiceStatus>().future;
  }

  @override
  Future<void> refresh() async {}
}

/// OpenAI notifier that stays in loading state — [build] never completes.
class _OpenAILoadingNotifier extends OpenAIStatusNotifier {
  @override
  Future<GitHubServiceStatus> build() async {
    return Completer<GitHubServiceStatus>().future;
  }

  @override
  Future<void> refresh() async {}
}

/// Kimi notifier that stays in loading state — [build] never completes.
class _KimiLoadingNotifier extends KimiStatusNotifier {
  @override
  Future<GitHubServiceStatus> build() async {
    return Completer<GitHubServiceStatus>().future;
  }

  @override
  Future<void> refresh() async {}
}

/// GitHub notifier whose build resolves only when the test completes it —
/// lets a test land a first snapshot mid-run.
class _GithubPendingNotifier extends GitHubStatusNotifier {
  final Completer<GitHubServiceStatus> _completer = Completer();

  void resolve(GitHubServiceStatus status) => _completer.complete(status);

  @override
  Future<GitHubServiceStatus> build() => _completer.future;

  @override
  Future<void> refresh() async {}
}

/// Wraps the entry in a [ProviderScope] with all four status providers
/// overridden (all operational by default), plus `testWrap` infrastructure.
Widget _wrap({
  GitHubStatusNotifier? github,
  ClaudeStatusNotifier? claude,
  OpenAIStatusNotifier? openai,
  KimiStatusNotifier? kimi,
}) {
  return ProviderScope(
    overrides: [
      githubStatusProvider.overrideWith(
        () =>
            github ?? _GithubDataNotifier(_status(GitHubStatusIndicator.none)),
      ),
      claudeStatusProvider.overrideWith(
        () =>
            claude ?? _ClaudeDataNotifier(_status(GitHubStatusIndicator.none)),
      ),
      openaiStatusProvider.overrideWith(
        () =>
            openai ?? _OpenAIDataNotifier(_status(GitHubStatusIndicator.none)),
      ),
      kimiStatusProvider.overrideWith(
        () => kimi ?? _KimiDataNotifier(_status(GitHubStatusIndicator.none)),
      ),
    ],
    child: testWrap(const ServiceStatusSidebarEntry()),
  );
}

void main() {
  group('ServiceStatusSidebarEntry row', () {
    testWidgets('always renders, even when every provider is healthy', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      // Always mounted — presence is the point. Healthy stays quiet: the dot
      // alone carries it, no status word in the row.
      expect(find.text('Service status'), findsOneWidget);
      expect(find.text('Operational'), findsNothing);
      expect(
        tester.getSize(find.byType(ServiceStatusSidebarEntry)).height,
        kCcSidebarItemExtent,
      );
    });

    testWidgets('renders before the first snapshot lands', (tester) async {
      await tester.pumpWidget(
        _wrap(
          github: _GithubLoadingNotifier(),
          claude: _ClaudeLoadingNotifier(),
          openai: _OpenAILoadingNotifier(),
          kimi: _KimiLoadingNotifier(),
        ),
      );
      await tester.pump();

      // The row is up at boot — but no "Unknown" flash before real data.
      expect(find.text('Service status'), findsOneWidget);
      expect(find.text('Unknown'), findsNothing);
    });

    testWidgets('stays quiet while the loaded providers are all healthy', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(claude: _ClaudeLoadingNotifier()));
      await tester.pumpAndSettle();

      expect(find.text('Service status'), findsOneWidget);
      expect(find.text('Operational'), findsNothing);
    });

    testWidgets('shows the status word once a provider degrades', (
      tester,
    ) async {
      final github = _GithubPendingNotifier();
      await tester.pumpWidget(_wrap(github: github));
      await tester.pump();

      expect(find.text('Minor issues'), findsNothing);

      github.resolve(_status(GitHubStatusIndicator.minor));
      await tester.pumpAndSettle();

      expect(find.text('Minor issues'), findsOneWidget);
    });

    testWidgets('reports the worst status word across providers', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          claude: _ClaudeDataNotifier(_status(GitHubStatusIndicator.critical)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Outage'), findsOneWidget);
    });

    testWidgets('a minor issue beats a healthy provider', (tester) async {
      await tester.pumpWidget(
        _wrap(
          github: _GithubDataNotifier(_status(GitHubStatusIndicator.minor)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Minor issues'), findsOneWidget);
    });
  });

  group('ServiceStatusSidebarEntry flyout', () {
    testWidgets('lists all providers with their status word and page link', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          claude: _ClaudeDataNotifier(_status(GitHubStatusIndicator.minor)),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Service status'));
      await tester.pumpAndSettle();

      // Twice: the sidebar row's own label plus the flyout header.
      expect(find.text('Service status'), findsNWidgets(2));
      expect(find.text('GitHub'), findsOneWidget);
      expect(find.text('Claude'), findsOneWidget);
      expect(find.text('Codex'), findsOneWidget);
      expect(find.text('Kimi'), findsOneWidget);
      expect(find.text('Open githubstatus.com'), findsOneWidget);
      expect(find.text('Open status.claude.com'), findsOneWidget);
      expect(find.text('Open status.openai.com'), findsOneWidget);
      expect(find.text('Open status.moonshot.cn'), findsOneWidget);
    });

    testWidgets('shows incidents when a provider has them', (tester) async {
      await tester.pumpWidget(
        _wrap(
          claude: _ClaudeDataNotifier(
            _status(
              GitHubStatusIndicator.minor,
              incidents: [_incident('Elevated API errors')],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Service status'));
      await tester.pumpAndSettle();

      expect(find.text('Elevated API errors'), findsOneWidget);
    });

    testWidgets('shows degraded components and hides healthy ones', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          github: _GithubDataNotifier(
            _status(
              GitHubStatusIndicator.minor,
              components: [
                _component('API Requests', GitHubComponentStatus.operational),
                _component('Webhooks', GitHubComponentStatus.partialOutage),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Service status'));
      await tester.pumpAndSettle();

      expect(find.text('Webhooks'), findsOneWidget);
      expect(find.text('API Requests'), findsNothing);
    });

    testWidgets('one provider failing leaves the other readable', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          github: _GithubErrorNotifier(),
          claude: _ClaudeDataNotifier(_status(GitHubStatusIndicator.minor)),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Service status'));
      await tester.pumpAndSettle();

      expect(find.text("Couldn't reach githubstatus.com"), findsOneWidget);
      // The failed provider still offers its status-page link.
      expect(find.text('Open githubstatus.com'), findsOneWidget);
      // Claude still renders its own block.
      expect(find.text('Claude'), findsOneWidget);
      expect(find.text('Open status.claude.com'), findsOneWidget);
    });

    testWidgets('shows a spinner for a provider still loading', (tester) async {
      await tester.pumpWidget(
        _wrap(
          github: _GithubDataNotifier(_status(GitHubStatusIndicator.minor)),
          claude: _ClaudeLoadingNotifier(),
        ),
      );
      await tester.pumpAndSettle();

      // GitHub loaded degraded so the word is up; Claude is still fetching, so
      // its flyout block reports the spinner instead.
      await tester.tap(find.text('Service status'));
      await tester.pump();

      expect(find.byType(CcSpinner), findsOneWidget);
      // GitHub's block is unaffected.
      expect(find.text('GitHub'), findsOneWidget);
    });

    testWidgets('header refresh control refetches all four providers', (
      tester,
    ) async {
      final github = _GithubDataNotifier(_status(GitHubStatusIndicator.none));
      final claude = _ClaudeDataNotifier(_status(GitHubStatusIndicator.none));
      final openai = _OpenAIDataNotifier(_status(GitHubStatusIndicator.none));
      final kimi = _KimiDataNotifier(_status(GitHubStatusIndicator.minor));
      await tester.pumpWidget(
        _wrap(github: github, claude: claude, openai: openai, kimi: kimi),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Service status'));
      await tester.pumpAndSettle();

      // The shared ghost refresh control with the AppTimestamp freshness card,
      // same as every other remote-data surface.
      expect(find.byType(RefreshControl), findsOneWidget);
      // Opening the flyout already refreshed each provider once.
      expect(github.refreshCalls, 1);

      await tester.tap(find.byType(RefreshControl));
      await tester.pump();

      expect(github.refreshCalls, 2);
      expect(claude.refreshCalls, 2);
      expect(openai.refreshCalls, 2);
      expect(kimi.refreshCalls, 2);
    });
  });
}
