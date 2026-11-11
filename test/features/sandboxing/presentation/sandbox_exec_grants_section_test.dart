import 'package:cc_data/cc_data.dart'
    show
        RemoteSandboxExecGrantRepository,
        SandboxExecGrantView,
        SandboxExecGrantViewPage;
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/sandboxing/presentation/settings/sandbox_exec_grants_section.dart';
import 'package:control_center/features/sandboxing/providers/sandbox_exec_grant_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

class _FixedWs extends ActiveWorkspaceIdNotifier {
  @override
  String? build() => 'ws1';
}

/// Pages and filters like the server: newest first, substring on the path.
class _FakeRepo implements RemoteSandboxExecGrantRepository {
  _FakeRepo(int count)
    : rows = [
        for (var i = count - 1; i >= 0; i--)
          SandboxExecGrantView(
            id: 'g$i',
            path: '/data/spaces/s$i/repos',
            allowed: true,
            createdAt: DateTime.utc(2026, 1, 1).add(Duration(hours: i)),
          ),
      ];

  final List<SandboxExecGrantView> rows;
  final List<({String query, int offset})> calls = [];

  @override
  Future<SandboxExecGrantViewPage> list(
    String workspaceId, {
    String query = '',
    int offset = 0,
    int limit = 25,
  }) async {
    calls.add((query: query, offset: offset));
    final matching = [
      for (final r in rows)
        if (r.path.contains(query)) r,
    ];
    return SandboxExecGrantViewPage(
      grants: matching.skip(offset).take(limit).toList(),
      total: matching.length,
    );
  }

  @override
  Future<void> revoke(String workspaceId, String id) async =>
      rows.removeWhere((r) => r.id == id);
}

Widget _wrap(_FakeRepo repo) => ProviderScope(
  overrides: [
    activeWorkspaceIdProvider.overrideWith(_FixedWs.new),
    sandboxExecGrantRepositoryProvider.overrideWithValue(repo),
  ],
  child: MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: CcTheme(
      data: CcThemeData.light(),
      child: const Scaffold(
        body: SingleChildScrollView(child: SandboxExecGrantsSection()),
      ),
    ),
  ),
);

void main() {
  testWidgets('loads one page and appends the next on show more', (
    tester,
  ) async {
    final repo = _FakeRepo(30);
    await tester.pumpWidget(_wrap(repo));
    await tester.pumpAndSettle();

    expect(find.text('Revoke'), findsNWidgets(25));
    expect(find.text('25 of 30'), findsOneWidget);

    await tester.ensureVisible(find.text('Show more'));
    await tester.tap(find.text('Show more'));
    await tester.pumpAndSettle();

    expect(find.text('Revoke'), findsNWidgets(30));
    expect(find.text('30 of 30'), findsOneWidget);
    expect(find.text('Show more'), findsNothing);
    expect(repo.calls.last, (query: '', offset: 25));
  });

  testWidgets('searches on the server after a pause in typing', (tester) async {
    final repo = _FakeRepo(30);
    await tester.pumpWidget(_wrap(repo));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(EditableText), 's1');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(repo.calls.last, (query: 's1', offset: 0));
    // s1 and s10–s19.
    expect(find.text('Revoke'), findsNWidgets(11));
    expect(find.text('11 of 11'), findsOneWidget);

    await tester.enterText(find.byType(EditableText), 'nothing-like-this');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(find.text('No grants match your search'), findsOneWidget);
    expect(
      find.byType(EditableText),
      findsOneWidget,
      reason: 'the field must stay so the query can be cleared',
    );
  });

  testWidgets('a short list has no search field', (tester) async {
    await tester.pumpWidget(_wrap(_FakeRepo(3)));
    await tester.pumpAndSettle();

    expect(find.text('Revoke'), findsNWidgets(3));
    expect(find.byType(EditableText), findsNothing);
    expect(find.text('Show more'), findsNothing);
  });

  testWidgets('revoking drops the row and the count', (tester) async {
    final repo = _FakeRepo(10);
    await tester.pumpWidget(_wrap(repo));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Revoke').first);
    await tester.pumpAndSettle();
    // The dialog's confirm button is the last "Revoke" on screen.
    await tester.tap(find.text('Revoke').last);
    await tester.pumpAndSettle();

    expect(find.text('/data/spaces/s9/repos'), findsNothing);
    expect(find.text('9 of 9'), findsOneWidget);
    expect(repo.calls, hasLength(1), reason: 'no refetch of loaded pages');
  });
}
