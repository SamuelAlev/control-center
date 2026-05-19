import 'package:cc_domain/core/domain/value_objects/account_pool.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/settings/presentation/widgets/account_pool_editor.dart';
import 'package:control_center/features/settings/providers/account_pool_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
// `flutter_riverpod` does not re-export `Override`; `misc.dart` is its public
// home in riverpod 3.
import 'package:riverpod/misc.dart' show Override;

const _scope = AccountPoolScope(lane: 'claude-code');
const _agentScope = AccountPoolScope(lane: 'claude-code', agentId: 'agent-1');

List<AccountPoolCandidate> _candidates([int n = 3]) => [
  for (var i = 0; i < n; i++)
    AccountPoolCandidate(id: 'c$i', label: 'Account $i'),
];

Widget _wrap(Widget child) => CcTheme(
  data: CcThemeData.light(),
  child: MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: SingleChildScrollView(child: child)),
  ),
);

List<Override> _overrides({
  required AccountPoolScope scope,
  required AccountPool pool,
  AccountPool? inherited,
}) => [
  accountPoolProvider(
    scope,
  ).overrideWith((ref) async => (pool: pool, inherited: inherited)),
];

Future<void> _pump(
  WidgetTester tester, {
  AccountPoolScope scope = _scope,
  AccountPool pool = const AccountPool(),
  AccountPool? inherited,
  List<AccountPoolCandidate>? candidates,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: _overrides(scope: scope, pool: pool, inherited: inherited),
      child: _wrap(
        AccountPoolEditor(
          scope: scope,
          candidates: candidates ?? _candidates(),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

void main() {
  testWidgets('renders nothing when there is nothing to choose between', (
    tester,
  ) async {
    // One credential is not a pool. The control is absent rather than
    // disabled, so a single-account install sees no new chrome.
    await _pump(tester, candidates: _candidates(1));
    expect(
      find.byType(CcSegmentedToggle<AccountRotationStrategy>),
      findsNothing,
    );
  });

  group('unconfigured', () {
    testWidgets('shows every candidate attached, in order', (tester) async {
      // Editing must start from what WOULD run. An empty list would imply
      // nothing is attached, which is the opposite of the truth.
      await _pump(tester);
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      expect(find.text(l10n.accountPoolUsingAll), findsOneWidget);
      for (var i = 0; i < 3; i++) {
        expect(find.text('Account $i'), findsOneWidget);
      }
      // Positions are stated, not inferred from vertical order.
      expect(find.text('1'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('an agent scope shows what it inherits, not everything', (
      tester,
    ) async {
      await _pump(
        tester,
        scope: _agentScope,
        inherited: const AccountPool(
          accountIds: ['c2'],
          strategy: AccountRotationStrategy.serial,
        ),
      );
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      expect(find.text(l10n.accountPoolInheriting), findsOneWidget);
      // Only the inherited one carries a position; the rest are detached.
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsNothing);
    });
  });

  group('configured', () {
    testWidgets('respects the stored order over the candidate order', (
      tester,
    ) async {
      await _pump(tester, pool: const AccountPool(accountIds: ['c2', 'c0']));
      // 'c2' is first in the pool, so it takes position 1 even though the
      // candidate list starts at c0.
      final rows = tester.widgetList<Text>(find.byType(Text)).toList();
      final labels = [for (final r in rows) r.data];
      expect(labels.indexOf('Account 2') < labels.indexOf('Account 0'), isTrue);
    });

    testWidgets('the strategy hint changes with the strategy', (tester) async {
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      await _pump(
        tester,
        pool: const AccountPool(
          accountIds: ['c0'],
          strategy: AccountRotationStrategy.serial,
        ),
      );
      expect(find.text(l10n.accountPoolSerialHint), findsOneWidget);
      expect(find.text(l10n.accountPoolRoundRobinHint), findsNothing);
    });

    testWidgets('an agent override offers a reset to the workspace', (
      tester,
    ) async {
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      await _pump(
        tester,
        scope: _agentScope,
        pool: const AccountPool(accountIds: ['c0']),
        inherited: const AccountPool(accountIds: ['c0', 'c1']),
      );
      expect(find.text(l10n.accountPoolResetToWorkspace), findsOneWidget);
    });

    testWidgets('a workspace scope has no reset affordance', (tester) async {
      // There is nothing above a workspace to fall back to.
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      await _pump(tester, pool: const AccountPool(accountIds: ['c0']));
      expect(find.text(l10n.accountPoolResetToWorkspace), findsNothing);
    });
  });

  testWidgets('an unavailable candidate stays selectable and says why', (
    tester,
  ) async {
    // Being out of quota is a passing state; removing the row would quietly
    // rewrite the operator's configuration.
    await tester.pumpWidget(
      ProviderScope(
        overrides: _overrides(
          scope: _scope,
          pool: const AccountPool(accountIds: ['c0', 'c1']),
        ),
        child: _wrap(
          const AccountPoolEditor(
            scope: _scope,
            candidates: [
              AccountPoolCandidate(id: 'c0', label: 'Account 0'),
              AccountPoolCandidate(
                id: 'c1',
                label: 'Account 1',
                unavailable: true,
                unavailableReason: 'out of quota until 14:20',
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Account 1'), findsOneWidget);
    expect(find.textContaining('out of quota until 14:20'), findsOneWidget);
    final boxes = tester.widgetList<CcCheckbox>(find.byType(CcCheckbox));
    expect(boxes.every((b) => b.value), isTrue, reason: 'both stay attached');
    expect(boxes.every((b) => b.onChanged != null), isTrue);
  });
}
