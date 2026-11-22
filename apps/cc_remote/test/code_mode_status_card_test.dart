@TestOn('browser')
library;

import 'package:cc_domain/cc_domain.dart' show CodeModeStatusDto;
import 'package:cc_domain/features/code_mode/domain/value_objects/code_mode_limits.dart';
import 'package:cc_remote/code_mode_providers.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/l10n/remote_locales.dart';
import 'package:cc_remote/providers.dart';
import 'package:cc_remote/widgets/code_mode_status_card.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

CodeModeStatusDto _status({bool available = true, String? reason}) =>
    CodeModeStatusDto(
      available: available,
      reason: reason,
      limits: CodeModeLimits.defaults,
      limitOverrides: const {},
      maxProcesses: 4,
      maxParkedProcesses: 16,
      maxWorkspaceProcesses: 3,
      maxHeapBytes: CodeModeLimits.heap.ceiling,
    );

void main() {
  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  Future<void> pump(
    WidgetTester tester,
    CodeModeStatusDto? status, {
    Locale locale = const Locale('en'),
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeWorkspaceIdProvider.overrideWith((ref) async* {
            yield 'ws1';
          }),
          remoteCodeModeStatusProvider(
            'ws1',
          ).overrideWith((ref) async => status),
        ],
        child: WidgetsApp(
          color: const Color(0xFFFFFFFF),
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: kSupportedRemoteLocales,
          textStyle: const TextStyle(
            fontSize: 14,
            color: Color(0xFF202020),
            decoration: TextDecoration.none,
          ),
          builder: (_, child) => CcTheme(
            data: CcThemeData.light(),
            child: const CodeModeStatusCard(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows that the server runs scripts, and nothing about a '
      'mode', (tester) async {
    await pump(tester, _status());
    expect(find.text(l10n.codeModeTitle), findsOneWidget);
    expect(find.text(l10n.codeModeAvailable), findsOneWidget);
    expect(
      find.text(
        "Change it in the desktop app, under the workspace's settings.",
      ),
      findsNothing,
    );
    expect(find.textContaining('This workspace:'), findsNothing);
  });

  testWidgets('says why the server cannot run scripts', (tester) async {
    await pump(tester, _status(available: false, reason: 'No runner.'));
    expect(find.text(l10n.codeModeUnavailable), findsOneWidget);
    expect(find.text(l10n.codeModeUnavailableNote('No runner.')), findsOne);
  });

  testWidgets('an unavailable status with no reason still says something', (
    tester,
  ) async {
    await pump(tester, _status(available: false));
    expect(
      find.text(l10n.codeModeUnavailableNote(l10n.codeModeNoReason)),
      findsOne,
    );
  });

  testWidgets('shows nothing until there is a status', (tester) async {
    await pump(tester, null);
    expect(find.text(l10n.codeModeTitle), findsNothing);
  });

  testWidgets('lays out right to left', (tester) async {
    await pump(tester, _status(), locale: const Locale('ar'));
    expect(tester.takeException(), isNull);
    expect(
      Directionality.of(tester.element(find.byType(CodeModeStatusCard))),
      TextDirection.rtl,
    );
  });
}
