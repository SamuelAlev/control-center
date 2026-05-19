import 'package:cc_domain/cc_domain.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/workspace/workspace_activity_section.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime.now();

  final entries = [
    UserActivityDto(
      id: 'a1',
      workspaceId: 'ws-1',
      userId: 'u-1',
      action: 'agents.upsert',
      targetType: 'agents',
      targetId: 'ceo',
      createdAt: now.subtract(const Duration(minutes: 16)),
    ),
    UserActivityDto(
      id: 'a2',
      workspaceId: 'ws-1',
      userId: 'u-1',
      action: 'fs.persistLogo',
      targetType: 'fs',
      createdAt: now.subtract(const Duration(minutes: 16)),
    ),
    UserActivityDto(
      id: 'a3',
      workspaceId: 'ws-1',
      userId: 'u-2',
      action: 'members.invite',
      targetType: 'members',
      createdAt: now.subtract(const Duration(hours: 3)),
    ),
  ];

  final networkEntries = [
    UserActivityDto(
      id: 'n1',
      workspaceId: 'ws-1',
      userId: 'u-1',
      action: 'agents.upsert',
      targetType: 'agents',
      targetId: 'ceo',
      ip: '203.0.113.7',
      countryCode: 'FR',
      createdAt: now.subtract(const Duration(minutes: 2)),
    ),
    UserActivityDto(
      id: 'n2',
      workspaceId: 'ws-1',
      userId: 'u-2',
      action: 'tickets.create',
      targetType: 'tickets',
      targetId: 'T-9',
      ip: '198.51.100.9',
      countryCode: 'US',
      createdAt: now.subtract(const Duration(minutes: 4)),
    ),
    UserActivityDto(
      id: 'n3',
      workspaceId: 'ws-1',
      userId: 'u-1',
      action: 'skills.delete',
      targetType: 'skills',
      targetId: 'pdf',
      ip: '192.168.1.10',
      createdAt: now.subtract(const Duration(minutes: 6)),
    ),
  ];

  List<UserActivityDto> pagedEntries(int count) => [
    for (var i = 1; i <= count; i++)
      UserActivityDto(
        id: 'p$i',
        workspaceId: 'ws-1',
        userId: 'u-1',
        action: 'agents.upsert',
        targetType: 'agents',
        targetId: 'a-$i',
        createdAt: now.subtract(Duration(minutes: i)),
      ),
  ];

  final users = {
    'u-1': UserDto(
      id: 'u-1',
      handle: 'samuel.alev',
      displayName: 'Samuel Alev',
    ),
    'u-2': UserDto(id: 'u-2', handle: 'riley', displayName: 'Riley Chen'),
  };

  Widget wrap(List<UserActivityDto> activity, {required CcThemeData theme}) {
    return ProviderScope(
      overrides: [
        workspaceActivityProvider(
          'ws-1',
        ).overrideWith((ref) => Stream.value(activity)),
        usersByIdProvider.overrideWith((ref) => Stream.value(users)),
        // MemberAvatar consults the current user for the host-GitHub-avatar
        // layer; pinning it to null keeps every row on the initials fallback.
        currentUserIdProvider.overrideWithValue(null),
      ],
      child: CcTheme(
        data: theme,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: WorkspaceActivitySection(workspaceId: 'ws-1'),
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('renders actor, action, description and timestamp per entry', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(entries, theme: CcThemeData.light()));
    await tester.pump();

    expect(find.text('Samuel Alev'), findsNWidgets(2));
    expect(find.text('Riley Chen'), findsOneWidget);
    // The op stays machine truth on the action chip.
    expect(find.text('agents.upsert'), findsOneWidget);
    expect(find.text('fs.persistLogo'), findsOneWidget);
    // The meta line is a prose description, not the raw target type.
    expect(find.text('Updated agent · ceo'), findsOneWidget);
    expect(find.text('Saved the workspace logo'), findsOneWidget);
    expect(find.text('Invited member'), findsOneWidget);
    expect(find.text('agents ceo'), findsNothing);
    expect(find.text('fs'), findsNothing);
    // Every entry carries an accessible absolute timestamp.
    expect(find.byType(CcTooltip), findsNWidgets(3));
    // Rows render the member avatar (initials fallback).
    expect(find.byType(CcAvatar), findsNWidgets(3));
    // A short trail is a single page.
    expect(find.text('1–3 of 3'), findsOneWidget);
  });

  testWidgets('header shows the entry count', (tester) async {
    await tester.pumpWidget(wrap(entries, theme: CcThemeData.light()));
    await tester.pump();

    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('empty state and no count chip when the trail is empty', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(const [], theme: CcThemeData.light()));
    await tester.pump();

    expect(find.text('0'), findsNothing);
    expect(find.byType(CcAvatar), findsNothing);
    expect(find.byType(CcTextField), findsNothing);
  });

  testWidgets('renders in the dark theme', (tester) async {
    await tester.pumpWidget(wrap(entries, theme: CcThemeData.dark()));
    await tester.pump();

    expect(find.text('Samuel Alev'), findsNWidgets(2));
    expect(find.text('agents.upsert'), findsOneWidget);
    expect(find.text('Updated agent · ceo'), findsOneWidget);
  });

  testWidgets('paginates ten rows per page with clamped bounds', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(pagedEntries(12), theme: CcThemeData.light()));
    await tester.pump();

    // Page 1: rows 1–10, footer ledger, previous disabled.
    expect(find.text('1–10 of 12'), findsOneWidget);
    expect(find.text('Updated agent · a-10'), findsOneWidget);
    expect(find.text('Updated agent · a-11'), findsNothing);
    // The header count chip still reports the full trail.
    expect(find.text('12'), findsOneWidget);

    CcButton pageButton(IconData icon) => tester.widget<CcButton>(
      find.ancestor(of: find.byIcon(icon), matching: find.byType(CcButton)),
    );
    expect(pageButton(AppIcons.chevronLeft).onPressed, isNull);
    expect(pageButton(AppIcons.chevronRight).onPressed, isNotNull);

    await tester.ensureVisible(find.byIcon(AppIcons.chevronRight));
    await tester.tap(find.byIcon(AppIcons.chevronRight));
    await tester.pump();

    // Page 2: rows 11–12 swap in, next now disabled.
    expect(find.text('11–12 of 12'), findsOneWidget);
    expect(find.text('Updated agent · a-11'), findsOneWidget);
    expect(find.text('Updated agent · a-1'), findsNothing);
    expect(pageButton(AppIcons.chevronLeft).onPressed, isNotNull);
    expect(pageButton(AppIcons.chevronRight).onPressed, isNull);

    await tester.ensureVisible(find.byIcon(AppIcons.chevronLeft));
    await tester.tap(find.byIcon(AppIcons.chevronLeft));
    await tester.pump();
    expect(find.text('1–10 of 12'), findsOneWidget);
  });

  testWidgets('search narrows rows across name, action and target', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(entries, theme: CcThemeData.light()));
    await tester.pump();

    await tester.enterText(find.byType(CcTextField), 'ceo');
    await tester.pump();

    expect(find.text('Updated agent · ceo'), findsOneWidget);
    expect(find.text('Saved the workspace logo'), findsNothing);
    expect(find.text('Invited member'), findsNothing);
    expect(find.text('1–1 of 1'), findsOneWidget);

    // A query matching nothing reports the no-matches state.
    await tester.enterText(find.byType(CcTextField), 'zzz-no-hit');
    await tester.pump();
    expect(find.text('No activity matches your filters'), findsOneWidget);
    expect(find.byType(CcAvatar), findsNothing);
  });

  testWidgets('tapping an IP chip filters the list and shows a clear chip', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(networkEntries, theme: CcThemeData.light()));
    await tester.pump();

    // Each row exposes its network origin as chips.
    expect(find.text('203.0.113.7'), findsOneWidget);
    expect(find.text('FR'), findsOneWidget);
    expect(find.text('198.51.100.9'), findsOneWidget);

    await tester.tap(find.text('203.0.113.7'));
    await tester.pump();

    // Only the matching row remains; the active filter is dismissible.
    expect(find.text('Updated agent · ceo'), findsOneWidget);
    expect(find.text('Created ticket · T-9'), findsNothing);
    expect(find.text('Deleted skill · pdf'), findsNothing);
    expect(find.text('IP 203.0.113.7'), findsOneWidget);
    expect(find.text('1–1 of 1'), findsOneWidget);

    await tester.tap(find.byIcon(AppIcons.x));
    await tester.pump();
    expect(find.text('Created ticket · T-9'), findsOneWidget);
    expect(find.text('IP 203.0.113.7'), findsNothing);
    expect(find.text('1–3 of 3'), findsOneWidget);
  });

  testWidgets('a private IP reads Localhost and filters by it', (tester) async {
    await tester.pumpWidget(wrap(networkEntries, theme: CcThemeData.light()));
    await tester.pump();

    // 192.168.1.10 carries no GeoIP signal — labeled Localhost, no country.
    expect(find.text('Localhost'), findsOneWidget);

    await tester.tap(find.text('Localhost'));
    await tester.pump();

    expect(find.text('Deleted skill · pdf'), findsOneWidget);
    expect(find.text('Updated agent · ceo'), findsNothing);
    expect(find.text('Country Localhost'), findsOneWidget);
  });
}
