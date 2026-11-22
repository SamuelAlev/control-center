import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_mode_limits.dart';
import 'package:cc_rpc/cc_rpc.dart' show RemoteRpcException;
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/code_mode/presentation/settings/code_mode_limit_specs.dart';
import 'package:control_center/features/code_mode/presentation/settings/code_mode_settings_view.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/l10n/localizations_loader.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/active_workspace.dart';
import '../../helpers/test_wrap.dart';
import 'code_mode_fakes.dart';

void main() {
  late AppLocalizations l10n;
  late FakeCodeModeRepository repo;

  setUpAll(() async {
    l10n = await appLocalizationsDelegate.load(const Locale('en'));
  });

  setUp(() => repo = FakeCodeModeRepository());

  Future<void> pump(
    WidgetTester tester, {
    bool admin = true,
    bool demo = false,
    TextDirection direction = TextDirection.ltr,
  }) async {
    await tester.binding.setSurfaceSize(const Size(1000, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeWorkspaceIdOverride(),
          codeModeRepositoryProvider.overrideWithValue(repo),
          myWorkspaceRoleProvider(kTestWorkspaceId).overrideWith(
            (ref) => admin ? WorkspaceRole.admin : WorkspaceRole.member,
          ),
        ],
        child: testWrap(
          const CodeModeSettingsView(),
          textDirection: direction,
          isDemo: demo,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('availability', () {
    testWidgets('available: the status, the runner and the limits show, and '
        'nothing sets a mode', (tester) async {
      await pump(tester);
      expect(find.text(l10n.codeModeAvailable), findsOneWidget);
      expect(find.text(l10n.codeModeLimitsDisclosure), findsOneWidget);
      expect(find.text('Hybrid'), findsNothing);
      expect(find.text('Off'), findsNothing);
      expect(find.text('Only'), findsNothing);
    });

    testWidgets('unavailable: the reason shows', (tester) async {
      repo.status_ = codeModeStatus(
        available: false,
        reason: 'The script runner is missing.',
      );
      await pump(tester);
      expect(find.text(l10n.codeModeUnavailable), findsOneWidget);
      expect(
        find.text(
          l10n.codeModeUnavailableNote('The script runner is missing.'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('unavailable without a reason says none was given', (
      tester,
    ) async {
      repo.status_ = codeModeStatus(available: false);
      await pump(tester);
      expect(
        find.text(l10n.codeModeUnavailableNote(l10n.codeModeNoReason)),
        findsOneWidget,
      );
    });

    testWidgets('a demo server shows the status and no limits', (tester) async {
      repo.status_ = codeModeStatus(
        available: false,
        reason: 'a public demo runs no scripts',
      );
      await pump(tester, demo: true);
      expect(find.text(l10n.codeModeUnavailable), findsOneWidget);
      expect(find.text(l10n.codeModeLimitsDisclosure), findsNothing);
    });

    testWidgets('a refused limits write is localized by its kind', (
      tester,
    ) async {
      await pump(tester);
      await tester.tap(find.text(l10n.codeModeLimitsDisclosure));
      await tester.pumpAndSettle();
      repo.writeError = RemoteRpcException(-32602, 'raw server text', {
        'kind': 'code_mode_limit_out_of_range',
      });
      await tester.enterText(
        find.descendant(
          of: find.ancestor(
            of: find.text(l10n.codeModeLimitWallClock),
            matching: find.byWidgetPredicate(
              (w) => w.runtimeType.toString() == 'SettingsField',
            ),
          ),
          matching: find.byType(EditableText),
        ),
        '60',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.save));
      await tester.pumpAndSettle();
      expect(find.text(l10n.codeModeRefusedLimitOutOfRange), findsOneWidget);
      expect(find.text('raw server text'), findsNothing);
    });

    testWidgets('renders right to left without overflow', (tester) async {
      repo.status_ = codeModeStatus(available: false, reason: 'No runner.');
      await pump(tester, direction: TextDirection.rtl);
      await tester.tap(find.text(l10n.codeModeLimitsDisclosure));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text(l10n.codeModeLimitWallClock), findsOneWidget);
    });
  });

  group('limits', () {
    Future<void> open(WidgetTester tester) async {
      await tester.tap(find.text(l10n.codeModeLimitsDisclosure));
      await tester.pumpAndSettle();
    }

    Finder field(String label) => find.descendant(
      of: find.ancestor(
        of: find.text(label),
        matching: find.byWidgetPredicate(
          (w) => w.runtimeType.toString() == 'SettingsField',
        ),
      ),
      matching: find.byType(EditableText),
    );

    CcButton saveButton(WidgetTester tester) => tester.widget<CcButton>(
      find.ancestor(of: find.text(l10n.save), matching: find.byType(CcButton)),
    );

    testWidgets('folded by default, at defaults', (tester) async {
      await pump(tester);
      expect(find.text(l10n.codeModeLimitsAtDefaults), findsOneWidget);
      expect(find.text(l10n.codeModeLimitWallClock), findsNothing);
    });

    testWidgets('shows each default and bound, in the edited unit', (
      tester,
    ) async {
      await pump(tester);
      await open(tester);
      // Five minutes, between one second and twenty-five minutes.
      expect(find.text(l10n.codeModeLimitRange('300', '1', '1,500')), findsOne);
      // 256 MiB between 16 and 1,024.
      expect(
        find.text(l10n.codeModeLimitRange('256', '16', '1,024')),
        findsOne,
      );
      // The server's own bounds, read-only.
      expect(
        find.text(
          '${l10n.codeModeServerCap(4)} ${l10n.codeModeServerWorkspaceShare(3)}',
        ),
        findsOneWidget,
      );
    });

    testWidgets('memory is held to the server owner\'s heap ceiling', (
      tester,
    ) async {
      // The owner capped every script at 128 MiB, under the 256 MiB default.
      repo.status_ = codeModeStatus(
        limits: CodeModeLimits.defaults.withOverridesJson({
          'heap_bytes': 128 * 1024 * 1024,
        }),
        maxHeapBytes: 128 * 1024 * 1024,
      );
      await pump(tester);
      await open(tester);
      expect(find.text(l10n.codeModeLimitRange('128', '16', '128')), findsOne);
      await tester.enterText(field(l10n.codeModeLimitHeap), '512');
      await tester.pumpAndSettle();
      expect(find.text(l10n.codeModeLimitOutOfRange('16', '128')), findsOne);
      expect(saveButton(tester).onPressed, isNull);

      // At the ceiling the field is at its default: nothing is stored.
      await tester.enterText(field(l10n.codeModeLimitHeap), '128');
      await tester.enterText(field(l10n.codeModeLimitWallClock), '60');
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.save));
      await tester.pumpAndSettle();
      expect(repo.limitWrites, [
        {'wall_clock_ms': 60000},
      ]);
    });

    testWidgets('an out-of-range value is flagged and cannot be saved', (
      tester,
    ) async {
      await pump(tester);
      await open(tester);
      await tester.enterText(field(l10n.codeModeLimitInFlight), '64');
      await tester.pumpAndSettle();
      expect(find.text(l10n.codeModeLimitOutOfRange('1', '32')), findsOne);
      expect(saveButton(tester).onPressed, isNull);

      await tester.enterText(field(l10n.codeModeLimitInFlight), '');
      await tester.pumpAndSettle();
      expect(saveButton(tester).onPressed, isNull);
      expect(repo.limitWrites, isEmpty);
    });

    testWidgets('saves only what differs from the defaults, in stored units', (
      tester,
    ) async {
      await pump(tester);
      await open(tester);
      await tester.enterText(field(l10n.codeModeLimitWallClock), '60');
      await tester.enterText(field(l10n.codeModeLimitHeap), '512');
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.save));
      await tester.pumpAndSettle();
      expect(repo.limitWrites, [
        {'wall_clock_ms': 60000, 'heap_bytes': 512 * 1024 * 1024},
      ]);
      expect(find.text(l10n.codeModeLimitsChangedCount(2)), findsOneWidget);
    });

    testWidgets('use defaults stages every default, then saves none', (
      tester,
    ) async {
      repo.status_ = codeModeStatus(
        limits: CodeModeLimits.defaults.withOverridesJson({
          'max_nested_calls': 50,
        }),
      );
      await pump(tester);
      expect(find.text(l10n.codeModeLimitsChangedCount(1)), findsOneWidget);
      await open(tester);
      await tester.tap(find.text(l10n.codeModeLimitsUseDefaults));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.save));
      await tester.pumpAndSettle();
      expect(repo.limitWrites, [null]);
      expect(find.text(l10n.codeModeLimitsAtDefaults), findsOneWidget);
    });

    testWidgets('a non-admin cannot edit the limits', (tester) async {
      await pump(tester, admin: false);
      await open(tester);
      final text = tester.widget<EditableText>(
        field(l10n.codeModeLimitWallClock),
      );
      expect(text.readOnly, isTrue);
      expect(find.text(l10n.save), findsNothing);
    });

    test('every adjustable limit has a spec, and units divide evenly', () {
      expect(
        {for (final s in kCodeModeLimitSpecs) s.key},
        {for (final b in CodeModeLimits.adjustable) b.key},
      );
      for (final s in kCodeModeLimitSpecs) {
        expect(s.bound.defaultValue % s.unit.factor, 0, reason: s.key);
        expect(s.bound.floor % s.unit.factor, 0, reason: s.key);
        expect(s.bound.ceiling % s.unit.factor, 0, reason: s.key);
      }
    });
  });
}
