import 'package:cc_data/cc_data.dart' show RpcClaudeAccountsRepository;
import 'package:cc_domain/features/settings/domain/entities/claude_session_settings.dart';
import 'package:control_center/features/settings/presentation/widgets/kit/settings_kit.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/claude_compaction_section.dart';
import 'package:control_center/features/settings/providers/claude_account_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/l10n/localizations_loader.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../helpers/test_wrap.dart';

class _FakeRepo implements RpcClaudeAccountsRepository {
  _FakeRepo([ClaudeSessionSettings? initial])
    : current = initial ?? ClaudeSessionSettings();

  ClaudeSessionSettings current;
  final saves = <ClaudeSessionSettings>[];
  bool failSaves = false;

  @override
  Future<ClaudeSessionSettings> sessionSettings() async => current;

  @override
  Future<void> setSessionSettings(ClaudeSessionSettings settings) async {
    if (failSaves) {
      throw StateError('offline');
    }
    saves.add(settings);
    current = settings;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  Future<AppLocalizations> pump(
    WidgetTester tester,
    _FakeRepo repo, {
    bool isDemo = false,
    TextDirection? textDirection,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [claudeAccountsRepositoryProvider.overrideWithValue(repo)],
        child: testWrap(
          const SingleChildScrollView(child: ClaudeCompactionSection()),
          isDemo: isDemo,
          textDirection: textDirection,
        ),
      ),
    );
    await tester.pumpAndSettle();
    return appLocalizationsDelegate.load(const Locale('en'));
  }

  Future<void> submit(WidgetTester tester, String text) async {
    await tester.enterText(find.byType(EditableText), text);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
  }

  testWidgets('shows what the server holds', (tester) async {
    final l10n = await pump(
      tester,
      _FakeRepo(
        ClaudeSessionSettings(
          autoCompactWindow: 300000,
          compactIdleBeforeCacheExpires: true,
        ),
      ),
    );

    expect(find.text(l10n.claudeCompactionTitle), findsOneWidget);
    expect(find.text('300000'), findsOneWidget);
    expect(
      tester.widget<SettingsToggle>(find.byType(SettingsToggle)).value,
      isTrue,
    );
  });

  testWidgets('saves a valid window and keeps the toggle', (tester) async {
    final repo = _FakeRepo(
      ClaudeSessionSettings(compactIdleBeforeCacheExpires: true),
    );
    await pump(tester, repo);

    await submit(tester, '250000');

    expect(repo.saves, [
      ClaudeSessionSettings(
        autoCompactWindow: 250000,
        compactIdleBeforeCacheExpires: true,
      ),
    ]);
  });

  testWidgets('clearing the window hands it back to Claude Code', (
    tester,
  ) async {
    final repo = _FakeRepo(ClaudeSessionSettings(autoCompactWindow: 300000));
    await pump(tester, repo);

    await submit(tester, '');

    expect(repo.saves, [ClaudeSessionSettings()]);
  });

  testWidgets('refuses a window outside the limits, without saving', (
    tester,
  ) async {
    final repo = _FakeRepo();
    final l10n = await pump(tester, repo);

    await submit(tester, '5');

    expect(repo.saves, isEmpty);
    expect(
      find.text(l10n.claudeAutoCompactInvalid('100,000', '1,000,000')),
      findsOneWidget,
    );
  });

  testWidgets('the toggle saves and keeps the window', (tester) async {
    final repo = _FakeRepo(ClaudeSessionSettings(autoCompactWindow: 300000));
    await pump(tester, repo);

    tester.widget<SettingsToggle>(find.byType(SettingsToggle)).onChanged!(true);
    await tester.pumpAndSettle();

    expect(repo.saves, [
      ClaudeSessionSettings(
        autoCompactWindow: 300000,
        compactIdleBeforeCacheExpires: true,
      ),
    ]);
  });

  testWidgets('a failed save says so', (tester) async {
    final repo = _FakeRepo()..failSaves = true;
    final l10n = await pump(tester, repo);

    await submit(tester, '250000');

    expect(find.text(l10n.claudeCompactionSaveFailed), findsOneWidget);
  });

  testWidgets('the demo shows nothing it would refuse', (tester) async {
    final l10n = await pump(tester, _FakeRepo(), isDemo: true);

    expect(find.text(l10n.claudeCompactionTitle), findsNothing);
  });

  testWidgets('lays out right to left', (tester) async {
    final l10n = await pump(
      tester,
      _FakeRepo(),
      textDirection: TextDirection.rtl,
    );

    expect(find.text(l10n.claudeCompactionTitle), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
