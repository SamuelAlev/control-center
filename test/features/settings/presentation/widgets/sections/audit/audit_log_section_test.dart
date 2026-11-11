import 'package:cc_domain/cc_domain.dart' show UserDto;
import 'package:cc_domain/core/domain/entities/server_audit_entry.dart';
import 'package:cc_domain/core/domain/value_objects/audit_log_page.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/audit/audit_log_section.dart';
import 'package:control_center/features/settings/providers/audit_log_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  final now = DateTime.now();

  const serverScope = AuditLogScopeDto(
    key: 'server',
    kind: AuditLogScopeKind.server,
  );
  const alphaScope = AuditLogScopeDto(
    key: 'ws:ws-1',
    kind: AuditLogScopeKind.workspace,
    workspaceId: 'ws-1',
    name: 'Alpha',
  );

  AuditLogEntryDto ws(
    String id,
    int minutesAgo, {
    String userId = 'u-1',
    String action = 'agents.upsert',
    String? targetId,
    String? ip,
    String? countryCode,
  }) => AuditLogEntryDto(
    id: id,
    source: alphaScope.key,
    workspaceId: 'ws-1',
    userId: userId,
    action: action,
    outcome: AuditOutcome.ok,
    targetType: action.split('.').first,
    targetId: targetId,
    ip: ip,
    countryCode: countryCode,
    createdAt: now.subtract(Duration(minutes: minutesAgo)),
  );

  AuditLogEntryDto server(
    String id,
    int minutesAgo, {
    AuditOutcome outcome = AuditOutcome.ok,
  }) => AuditLogEntryDto(
    id: id,
    source: serverScope.key,
    userId: 'u-1',
    action: 'connect.setChoice',
    outcome: outcome,
    argNames: const ['mode', 'url'],
    createdAt: now.subtract(Duration(minutes: minutesAgo)),
  );

  final mixed = [
    ws('a1', 1, targetId: 'ceo', ip: '203.0.113.7', countryCode: 'FR'),
    server('s1', 2, outcome: AuditOutcome.denied),
    ws(
      'a2',
      3,
      userId: 'u-2',
      action: 'tickets.create',
      targetId: 'T-9',
      ip: '198.51.100.9',
      countryCode: 'US',
    ),
    ws('a3', 4, action: 'skills.delete', targetId: 'pdf', ip: '192.168.1.10'),
  ];

  List<AuditLogEntryDto> paged(int count) => [
    for (var i = 1; i <= count; i++) ws('p$i', i, targetId: 'a-$i'),
  ];

  final users = {
    'u-1': UserDto(
      id: 'u-1',
      handle: 'samuel.alev',
      displayName: 'Samuel Alev',
    ),
    'u-2': UserDto(id: 'u-2', handle: 'riley', displayName: 'Riley Chen'),
  };

  final queries = <AuditLogQuery>[];

  /// A server stand-in: filters, counts and pages [rows] the way the
  /// `audit.watchLog` frame would (cursor = offset, page size from the query).
  AuditLogPageDto pageFor(
    List<AuditLogEntryDto> rows,
    List<AuditLogScopeDto> scopes,
    AuditLogQuery q,
  ) {
    queries.add(q);
    final needle = q.search.toLowerCase();
    final hits = [
      for (final e in rows)
        if ((q.ip == null || e.ip == q.ip) &&
            (q.countryCode == null || e.countryCode == q.countryCode) &&
            (!q.localNetwork || (e.ip != null && e.countryCode == null)) &&
            (q.sources.isEmpty || q.sources.contains(e.source)) &&
            (q.outcomes.isEmpty || q.outcomes.contains(e.outcome)) &&
            (q.actorIds.isEmpty || q.actorIds.contains(e.userId)) &&
            q.time.every((c) => c.admits(e.createdAt)) &&
            (needle.isEmpty ||
                q.searchUserIds.contains(e.userId) ||
                e.action.contains(needle) ||
                (e.targetId?.toLowerCase().contains(needle) ?? false)))
          e,
    ];
    final offset = int.tryParse(q.cursor ?? '') ?? 0;
    final page = hits.skip(offset).take(q.limit).toList();
    final next = offset + q.limit;
    return AuditLogPageDto(
      entries: page,
      scopes: scopes,
      total: hits.length,
      start: offset + 1,
      nextCursor: next < hits.length ? '$next' : null,
      prevCursor: offset - q.limit > 0 ? '${offset - q.limit}' : null,
      actorCounts: {
        for (final e in rows) e.userId: rows.where((r) => r == e).length,
      },
      sourceCounts: {for (final s in scopes) s.key: 0},
      outcomeCounts: const {},
    );
  }

  Widget wrap(
    List<AuditLogEntryDto> rows, {
    List<AuditLogScopeDto> scopes = const [serverScope, alphaScope],
    CcThemeData? theme,
    bool canSee = true,
    TextDirection direction = TextDirection.ltr,
  }) {
    return ProviderScope(
      overrides: [
        auditLogPageProvider.overrideWith(
          (ref, q) => Stream.value(pageFor(rows, scopes, q)),
        ),
        canSeeAuditLogProvider.overrideWithValue(canSee),
        usersByIdProvider.overrideWith((ref) => Stream.value(users)),
        // MemberAvatar consults the current user for the host-GitHub-avatar
        // layer; null keeps every row on the initials fallback.
        currentUserIdProvider.overrideWithValue(null),
      ],
      child: CcTheme(
        data: theme ?? CcThemeData.light(),
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Directionality(
            textDirection: direction,
            child: const Scaffold(
              body: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: AuditLogSection(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  setUp(queries.clear);

  testWidgets('one table merges server and workspace records', (tester) async {
    await tester.pumpWidget(wrap(mixed));
    await tester.pump();

    expect(find.text('Samuel Alev'), findsNWidgets(3));
    expect(find.text('Riley Chen'), findsOneWidget);
    // Where each record ran, since the log spans two trails.
    expect(find.text('Alpha'), findsNWidgets(3));
    expect(find.text('Server'), findsOneWidget);
    // Server ops carry their argument names and, when not ok, the outcome.
    expect(find.text('connect.setChoice'), findsOneWidget);
    expect(find.text('mode, url'), findsOneWidget);
    expect(find.text('Denied'), findsOneWidget);
    expect(find.text('Succeeded'), findsNothing);
    expect(find.text('Updated agent · ceo'), findsOneWidget);
    expect(find.byType(CcTooltip), findsNWidgets(4));
    expect(find.text('1–4 of 4'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
  });

  testWidgets('a single trail drops the source label', (tester) async {
    await tester.pumpWidget(wrap(mixed.sublist(2), scopes: const [alphaScope]));
    await tester.pump();

    expect(find.text('Alpha'), findsNothing);
    expect(find.text('Created ticket · T-9'), findsOneWidget);
  });

  testWidgets('without an admin role the page explains why it is empty', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(mixed, canSee: false));
    await tester.pump();

    expect(find.text('Admins only'), findsOneWidget);
    expect(find.byType(CcAvatar), findsNothing);
    expect(queries, isEmpty);

    // Signed in as an admin elsewhere, but the server granted no trail.
    await tester.pumpWidget(wrap(mixed, scopes: const []));
    await tester.pump();
    expect(find.text('Admins only'), findsOneWidget);
  });

  testWidgets('search reaches the server with matching actors', (tester) async {
    await tester.pumpWidget(wrap(mixed));
    await tester.pump();

    await tester.enterText(find.byType(CcTextField), 'riley');
    await tester.pumpAndSettle();

    expect(queries.last.search, 'riley');
    expect(queries.last.searchUserIds, {'u-2'});
    expect(find.text('Created ticket · T-9'), findsOneWidget);
    expect(find.text('Updated agent · ceo'), findsNothing);

    await tester.enterText(find.byType(CcTextField), 'zzz-no-hit');
    await tester.pumpAndSettle();
    expect(find.text('No activity matches your filters'), findsOneWidget);
  });

  testWidgets('an IP chip filters, and its filter chip clears it', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(mixed));
    await tester.pump();

    await tester.tap(find.text('203.0.113.7'));
    await tester.pumpAndSettle();

    expect(queries.last.ip, '203.0.113.7');
    expect(find.text('IP 203.0.113.7'), findsOneWidget);
    expect(find.text('1–1 of 1'), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.widgetWithText(CcChip, 'IP 203.0.113.7'),
        matching: find.text('×'),
      ),
    );
    await tester.pumpAndSettle();
    expect(queries.last.ip, isNull);
    expect(find.text('1–4 of 4'), findsOneWidget);
  });

  testWidgets('a private address filters as the local network', (tester) async {
    await tester.pumpWidget(wrap(mixed));
    await tester.pump();

    await tester.tap(find.text('Localhost'));
    await tester.pumpAndSettle();

    expect(queries.last.localNetwork, isTrue);
    expect(queries.last.countryCode, isNull);
    expect(find.text('Country Localhost'), findsOneWidget);
    expect(find.text('Deleted skill · pdf'), findsOneWidget);
    expect(find.text('Updated agent · ceo'), findsNothing);
  });

  testWidgets('a time preset adds a comparison chip', (tester) async {
    await tester.pumpWidget(wrap(mixed));
    await tester.pump();

    await tester.tap(find.text('Time'));
    await tester.pumpAndSettle();
    // Pick "before", then the hour preset.
    await tester.tap(find.text('<'));
    await tester.pumpAndSettle();
    expect(find.text('Before'), findsOneWidget);
    await tester.tap(find.text('1 hour ago'));
    await tester.pumpAndSettle();

    final condition = queries.last.time.single;
    expect(condition.op.wire, 'lt');
    expect(find.textContaining('Time < '), findsOneWidget);
    // Every record is newer than an hour: nothing is before it.
    expect(find.text('No activity matches your filters'), findsOneWidget);
  });

  testWidgets('an exact time refuses what is not a date', (tester) async {
    await tester.pumpWidget(wrap(mixed));
    await tester.pump();

    await tester.tap(find.text('Time'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(CcTextField).last, '2026-02-30');
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    expect(find.text('Use YYYY-MM-DD, optionally with HH:MM'), findsOneWidget);
    expect(queries.last.time, isEmpty);

    await tester.enterText(find.byType(CcTextField).last, '2026-01-01 09:00');
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    expect(queries.last.time.single.op.wire, 'gte');
    expect(queries.last.time.single.at, DateTime(2026, 1, 1, 9).toUtc());
  });

  testWidgets('paginates with clamped bounds', (tester) async {
    await tester.pumpWidget(
      wrap(paged(kAuditLogPageSize + 2), scopes: const [alphaScope]),
    );
    await tester.pump();

    CcButton pageButton(IconData icon) => tester.widget<CcButton>(
      find.ancestor(of: find.byIcon(icon), matching: find.byType(CcButton)),
    );
    expect(find.text('1–25 of 27'), findsOneWidget);
    expect(pageButton(AppIcons.chevronLeft).onPressed, isNull);

    await tester.ensureVisible(find.byIcon(AppIcons.chevronRight));
    await tester.tap(find.byIcon(AppIcons.chevronRight));
    await tester.pumpAndSettle();
    expect(find.text('26–27 of 27'), findsOneWidget);
    expect(find.text('Updated agent · a-26'), findsOneWidget);
    expect(pageButton(AppIcons.chevronRight).onPressed, isNull);

    await tester.ensureVisible(find.byIcon(AppIcons.chevronLeft));
    await tester.tap(find.byIcon(AppIcons.chevronLeft));
    await tester.pumpAndSettle();
    expect(find.text('1–25 of 27'), findsOneWidget);
  });

  testWidgets('renders dark and right to left', (tester) async {
    await tester.pumpWidget(
      wrap(mixed, theme: CcThemeData.dark(), direction: TextDirection.rtl),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('connect.setChoice'), findsOneWidget);
    expect(find.text('Updated agent · ceo'), findsOneWidget);
  });

  testWidgets('next page writes ?cursor= onto the URL', (tester) async {
    final router = GoRouter(
      initialLocation: '/workspaces/ws-1/settings/server/audit',
      routes: [
        GoRoute(
          path: '/workspaces/:workspaceId/settings/server/audit',
          builder: (context, state) => const Scaffold(
            body: SingleChildScrollView(child: AuditLogSection()),
          ),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          auditLogPageProvider.overrideWith(
            (ref, q) => Stream.value(
              pageFor(paged(kAuditLogPageSize + 2), const [alphaScope], q),
            ),
          ),
          canSeeAuditLogProvider.overrideWithValue(true),
          usersByIdProvider.overrideWith((ref) => Stream.value(users)),
          currentUserIdProvider.overrideWithValue(null),
        ],
        child: CcTheme(
          data: CcThemeData.light(),
          child: MaterialApp.router(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(router.state.uri.queryParameters['cursor'], isNull);
    await tester.ensureVisible(find.byIcon(AppIcons.chevronRight));
    await tester.tap(find.byIcon(AppIcons.chevronRight));
    await tester.pumpAndSettle();

    expect(router.state.uri.queryParameters['cursor'], '25');
    expect(find.text('26–27 of 27'), findsOneWidget);
    expect(uriWithCursor(router.state.uri, null), isNot(contains('cursor=')));

    // A filter change returns to the newest page.
    await tester.enterText(find.byType(CcTextField), 'a-2');
    await tester.pumpAndSettle();
    expect(router.state.uri.queryParameters['cursor'], isNull);
  });
}
