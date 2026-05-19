import 'dart:async';

import 'package:cc_domain/features/service_status/domain/entities/github_service_status.dart';
import 'package:cc_rpc/cc_rpc.dart' show RemoteRpcClient;
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/features/service_status/presentation/widgets/service_status_indicator.dart';
import 'package:control_center/features/service_status/providers/service_status_providers.dart';
import 'package:control_center/shared/widgets/refresh_control.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_wrap.dart';

/// The row's label is a plain [Text] (the status dot is a trailing badge at
/// the row's right edge, not a span inside the paragraph), and the flyout
/// header repeats the same title — `findRichText: true` keeps this matching
/// either flavour. Only row asserts on a fresh tree (flyout closed) may treat
/// it as unique.
Finder serviceStatusLabel() =>
    find.textContaining('Service status', findRichText: true);

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

/// A healthy-everywhere snapshot with per-provider overrides; a null field is
/// a page whose host-side fetch failed.
ServiceStatuses _statuses({
  GitHubServiceStatus? github,
  GitHubStatusIndicator? claude,
  List<GitHubStatusIncident> claudeIncidents = const [],
  GitHubStatusIndicator? openai,
  GitHubStatusIndicator? kimi,
}) => ServiceStatuses(
  github: github ?? _status(GitHubStatusIndicator.none),
  claude: claude == null
      ? _status(GitHubStatusIndicator.none)
      : _status(claude, incidents: claudeIncidents),
  openai: _status(openai ?? GitHubStatusIndicator.none),
  kimi: _status(kimi ?? GitHubStatusIndicator.none),
);

/// Combined notifier that immediately resolves to a data value.
class _DataNotifier extends ServiceStatusesNotifier {
  _DataNotifier(this._statuses);
  final ServiceStatuses _statuses;

  int refreshCalls = 0;

  @override
  Future<ServiceStatuses> build() async => _statuses;

  @override
  Future<void> refresh() async {
    refreshCalls++;
  }
}

/// Combined notifier that stays in loading state — [build] never completes.
class _LoadingNotifier extends ServiceStatusesNotifier {
  @override
  Future<ServiceStatuses> build() async {
    return Completer<ServiceStatuses>().future;
  }

  @override
  Future<void> refresh() async {}
}

/// Combined notifier whose build resolves only when the test completes it —
/// lets a test land a first snapshot mid-run.
class _PendingNotifier extends ServiceStatusesNotifier {
  final Completer<ServiceStatuses> _completer = Completer();

  void resolve(ServiceStatuses statuses) => _completer.complete(statuses);

  @override
  Future<ServiceStatuses> build() => _completer.future;

  @override
  Future<void> refresh() async {}
}

/// Wraps the entry in a [ProviderScope] with the combined status provider
/// overridden (all operational by default), plus `testWrap` infrastructure.
Widget _wrap({ServiceStatusesNotifier? notifier}) {
  return ProviderScope(
    overrides: [
      serviceStatusProvider.overrideWith(
        () => notifier ?? _DataNotifier(_statuses()),
      ),
    ],
    child: testWrap(const ServiceStatusSidebarEntry()),
  );
}

/// Minimal [RemoteRpcClient] stand-in answering only `serviceStatus.getAll` —
/// the REAL notifier runs against it, so the regression test below exercises
/// the real reload semantics (not an overridden `refresh`).
class _StatusRpcClientFake implements RemoteRpcClient {
  _StatusRpcClientFake(this.getAll);

  final Future<Map<String, dynamic>> Function() getAll;

  @override
  Future<Map<String, dynamic>> call(
    String op,
    Map<String, dynamic> args, {
    int? opVersion,
    String? idempotencyKey,
    bool dryRun = false,
    Duration? timeout,
    bool? coalesce,
  }) => op == 'serviceStatus.getAll'
      ? getAll()
      : throw UnimplementedError('StatusRpcClientFake.op $op');

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('StatusRpcClientFake.${invocation.memberName}');
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
      expect(serviceStatusLabel(), findsOneWidget);
      expect(find.text('Operational'), findsNothing);
      expect(
        tester.getSize(find.byType(ServiceStatusSidebarEntry)).height,
        kCcSidebarItemExtent,
      );
    });

    testWidgets('renders before the first snapshot lands', (tester) async {
      await tester.pumpWidget(_wrap(notifier: _LoadingNotifier()));
      await tester.pump();

      // The row is up at boot — but no "Unknown" flash before real data.
      expect(serviceStatusLabel(), findsOneWidget);
      expect(find.text('Unknown'), findsNothing);
    });

    testWidgets('stays quiet while one page failed and the rest are healthy', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          notifier: _DataNotifier(
            ServiceStatuses(
              github: _status(GitHubStatusIndicator.none),
              claude: _status(GitHubStatusIndicator.none),
              openai: _status(GitHubStatusIndicator.none),
              // No summary came back for Kimi — its slice is an error, which
              // must not flash anything onto the healthy row.
              kimi: null,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(serviceStatusLabel(), findsOneWidget);
      expect(find.text('Operational'), findsNothing);
      expect(find.text('Unknown'), findsNothing);
    });

    testWidgets('keeps the status word off the row once a provider degrades', (
      tester,
    ) async {
      final pending = _PendingNotifier();
      await tester.pumpWidget(_wrap(notifier: pending));
      await tester.pump();

      expect(find.text('Minor issues'), findsNothing);

      pending.resolve(_statuses(claude: GitHubStatusIndicator.minor));
      await tester.pumpAndSettle();

      // The row stays a colored dot; the word is in the flyout, not the badge.
      expect(find.text('Minor issues'), findsNothing);
    });

    testWidgets('reports the worst status in the flyout, not the row', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          notifier: _DataNotifier(
            _statuses(claude: GitHubStatusIndicator.critical),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Outage'), findsNothing);

      await tester.tap(serviceStatusLabel());
      await tester.pumpAndSettle();

      expect(find.text('Outage'), findsOneWidget);
    });

    testWidgets('a minor issue beats a healthy provider', (tester) async {
      await tester.pumpWidget(
        _wrap(
          notifier: _DataNotifier(
            _statuses(github: _status(GitHubStatusIndicator.minor)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Minor issues'), findsNothing);

      await tester.tap(serviceStatusLabel());
      await tester.pumpAndSettle();

      expect(find.text('Minor issues'), findsOneWidget);
    });
  });

  group('ServiceStatusSidebarEntry flyout', () {
    testWidgets(
      'lists all providers; no page-link button once a provider is readable',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            notifier: _DataNotifier(
              _statuses(
                claude: GitHubStatusIndicator.minor,
                claudeIncidents: [_incident('Elevated API errors')],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(serviceStatusLabel());
        await tester.pumpAndSettle();

        // Twice: the sidebar row's own label plus the flyout header.
        expect(serviceStatusLabel(), findsNWidgets(2));
        expect(find.text('GitHub'), findsOneWidget);
        expect(find.text('Claude'), findsOneWidget);
        expect(find.text('Codex'), findsOneWidget);
        expect(find.text('Kimi'), findsOneWidget);
        // No status-page button anywhere: the incident tile IS the link, and
        // a degraded provider no longer stacks a second one under it.
        expect(find.text('Elevated API errors'), findsOneWidget);
        expect(find.text('Open githubstatus.com'), findsNothing);
        expect(find.text('Open status.claude.com'), findsNothing);
        expect(find.text('Open status.openai.com'), findsNothing);
        expect(find.text('Open status.moonshot.cn'), findsNothing);
      },
    );

    testWidgets('shows incidents when a provider has them', (tester) async {
      await tester.pumpWidget(
        _wrap(
          notifier: _DataNotifier(
            _statuses(
              claude: GitHubStatusIndicator.minor,
              claudeIncidents: [_incident('Elevated API errors')],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(serviceStatusLabel());
      await tester.pumpAndSettle();

      expect(find.text('Elevated API errors'), findsOneWidget);
    });

    testWidgets('shows degraded components and hides healthy ones', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          notifier: _DataNotifier(
            ServiceStatuses(
              github: _status(
                GitHubStatusIndicator.minor,
                components: [
                  _component('API Requests', GitHubComponentStatus.operational),
                  _component('Webhooks', GitHubComponentStatus.partialOutage),
                ],
              ),
              claude: _status(GitHubStatusIndicator.none),
              openai: _status(GitHubStatusIndicator.none),
              kimi: _status(GitHubStatusIndicator.none),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(serviceStatusLabel());
      await tester.pumpAndSettle();

      expect(find.text('Webhooks'), findsOneWidget);
      expect(find.text('API Requests'), findsNothing);
    });

    testWidgets('one provider failing leaves the other readable', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          notifier: _DataNotifier(
            ServiceStatuses(
              // No summary for GitHub — its slice renders the fetch-failed
              // state with its status-page link.
              github: null,
              claude: _status(GitHubStatusIndicator.minor),
              openai: _status(GitHubStatusIndicator.none),
              kimi: _status(GitHubStatusIndicator.none),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(serviceStatusLabel());
      await tester.pumpAndSettle();

      expect(find.text("Couldn't reach githubstatus.com"), findsOneWidget);
      // The failed provider is the one case that keeps a status-page link:
      // it renders no incident tiles, so the button is its only way through.
      expect(find.text('Open githubstatus.com'), findsOneWidget);
      // Claude still renders its own block — and, being readable, no button.
      expect(find.text('Claude'), findsOneWidget);
      expect(find.text('Open status.claude.com'), findsNothing);
    });

    testWidgets('shows a spinner per provider while the snapshot loads', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(notifier: _LoadingNotifier()));
      await tester.pump();

      await tester.tap(serviceStatusLabel());
      await tester.pump();

      // One combined fetch means all four blocks load together.
      expect(find.byType(CcSpinner), findsNWidgets(4));
    });

    testWidgets('header refresh control refetches the shared snapshot', (
      tester,
    ) async {
      final notifier = _DataNotifier(
        _statuses(kimi: GitHubStatusIndicator.minor),
      );
      await tester.pumpWidget(_wrap(notifier: notifier));
      await tester.pumpAndSettle();

      await tester.tap(serviceStatusLabel());
      await tester.pumpAndSettle();

      // The shared ghost refresh control with the AppTimestamp freshness card,
      // same as every other remote-data surface.
      expect(find.byType(RefreshControl), findsOneWidget);
      // Opening the flyout already refreshed once.
      expect(notifier.refreshCalls, 1);

      await tester.tap(find.byType(RefreshControl));
      await tester.pump();

      expect(notifier.refreshCalls, 2);
    });
  });

  group('ServiceStatusSidebarEntry refresh flash regression', () {
    Map<String, dynamic> summaryPage() => <String, dynamic>{
      'status': {'indicator': 'none', 'description': 'All Systems Operational'},
    };

    Map<String, dynamic> allOperational() => <String, dynamic>{
      'github': summaryPage(),
      'claude': summaryPage(),
      'openai': summaryPage(),
      'kimi': summaryPage(),
    };

    /// Every circular dot painted [color] — the row badge and, once the flyout
    /// is open, the per-provider blocks. A status dot is a `Container` with a
    /// circle `BoxDecoration`, so this is the badge's exact paint.
    Finder dotsOf(Color color) => find.byWidgetPredicate(
      (w) =>
          w is Container &&
          w.decoration is BoxDecoration &&
          (w.decoration as BoxDecoration).shape == BoxShape.circle &&
          (w.decoration as BoxDecoration).color == color,
    );

    testWidgets('the row dot stays green while the open-refresh is in flight', (
      tester,
    ) async {
      // First fetch resolves healthy; the second (triggered by OPENING the
      // flyout) hangs until the test completes it.
      var callCount = 0;
      final hangingFetch = Completer<Map<String, dynamic>>();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            rpcClientProvider.overrideWithValue(
              _StatusRpcClientFake(() {
                callCount++;
                return callCount == 1
                    ? Future.value(allOperational())
                    : hangingFetch.future;
              }),
            ),
          ],
          child: testWrap(const ServiceStatusSidebarEntry()),
        ),
      );
      await tester.pumpAndSettle();

      final tokens = DesignSystemTokens.light();
      expect(dotsOf(tokens.success), findsWidgets);
      expect(dotsOf(tokens.muted), findsNothing);

      // Opening the flyout toggles the row selected AND starts a refresh.
      await tester.tap(serviceStatusLabel());
      await tester.pump();

      // The refresh must be in flight for this regression to mean anything.
      expect(callCount, 2);

      // While it hangs, the dot must hold the RETAINED snapshot's green —
      // before the fix the blanked loading state flipped the headline to null
      // and the dot to muted gray (the recorded green → black-ish → green).
      expect(dotsOf(tokens.success), findsWidgets);
      expect(dotsOf(tokens.muted), findsNothing);

      hangingFetch.complete(allOperational());
      await tester.pumpAndSettle();

      expect(dotsOf(tokens.success), findsWidgets);
      expect(dotsOf(tokens.muted), findsNothing);
    });
  });
}
