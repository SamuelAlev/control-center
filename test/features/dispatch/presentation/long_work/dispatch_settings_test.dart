import 'dart:async';
import 'dart:convert';

import 'package:cc_domain/core/domain/repositories/workspace_settings_repository.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/unattended_policy.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/dispatch/presentation/settings/dispatch_settings_view.dart';
import 'package:control_center/features/settings/providers/workspace_settings_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'long_work_harness.dart';

class _FakeSettings implements WorkspaceSettingsRepository {
  final writes = <String>[];

  @override
  Future<String?> get(String workspaceId, String key) async => null;

  @override
  Future<Map<String, String>> getAll(String workspaceId) async => const {};

  @override
  Stream<Map<String, String>> watchAll(String workspaceId) =>
      Stream.value(const {});

  @override
  Future<void> set(String workspaceId, String key, String? value) async =>
      writes.add('$workspaceId:$key=$value');
}

void main() {
  late FakeWakeRuleRepository rules;
  late _FakeSettings settings;

  setUp(() {
    rules = FakeWakeRuleRepository();
    settings = _FakeSettings();
  });

  Future<AppLocalizations> pump(
    WidgetTester tester, {
    WorkspaceRole role = WorkspaceRole.admin,
    bool settle = true,
  }) async {
    await pumpLongWork(
      tester,
      const DispatchSettingsView(),
      overrides: [
        ...longWorkOverrides(rules: rules, role: role),
        workspaceSettingsRepositoryProvider.overrideWithValue(settings),
        workspaceSettingsProvider.overrideWith((ref) => Stream.value({})),
      ],
      settle: settle,
    );
    return AppLocalizations.of(
      tester.element(find.byType(DispatchSettingsView)),
    );
  }

  Finder field(String label) => find.descendant(
    of: find.ancestor(of: find.text(label), matching: find.byType(Row)).first,
    matching: find.byType(EditableText),
  );

  testWidgets('an admin changes the schedule limits through setLimits', (
    tester,
  ) async {
    final l = await pump(tester);
    await tester.enterText(field(l.dispatchLimitPerConversation), '7');
    await tester.pumpAndSettle();
    await tester.tap(find.text(l.save).first);
    await tester.pumpAndSettle();
    expect(rules.calls, ['setLimits:7']);
    expect(rules.saved.perConversation, 7);
  });

  testWidgets('a limit out of range blocks Save', (tester) async {
    final l = await pump(tester);
    await tester.enterText(field(l.dispatchLimitPerConversation), '1000');
    await tester.pumpAndSettle();
    expect(find.text(l.dispatchLimitRange(100)), findsWidgets);
    final save = tester.widget<CcButton>(
      find.ancestor(
        of: find.text(l.save).first,
        matching: find.byType(CcButton),
      ),
    );
    expect(save.onPressed, isNull);
  });

  testWidgets('loading shows a spinner and no save bar', (tester) async {
    rules.limitsGate = Completer<void>();
    final l = await pump(tester, settle: false);
    expect(find.byType(CcSpinner), findsOneWidget);
    expect(find.text(l.save), findsNothing);
    rules.limitsGate!.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('a refused read shows its sentence and no save bar', (
    tester,
  ) async {
    rules.limitsError = refusal('mystery_kind');
    final l = await pump(tester);
    expect(find.textContaining('mystery_kind'), findsOneWidget);
    expect(find.text(l.save), findsNothing);
  });

  testWidgets('a member reads the limits and is told who changes them', (
    tester,
  ) async {
    final l = await pump(tester, role: WorkspaceRole.member);
    expect(find.text(l.settingsWorkspaceAdminOnly), findsNWidgets(2));
    expect(find.text(l.save), findsNothing);
  });

  testWidgets('the digest hour and request expiry save as the setting', (
    tester,
  ) async {
    final l = await pump(tester);
    await tester.enterText(
      find.byKey(const ValueKey('unattended-digest')),
      '7',
    );
    await tester.enterText(
      find.byKey(const ValueKey('unattended-expiry')),
      '48',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(l.save).last);
    await tester.pumpAndSettle();
    expect(settings.writes, hasLength(1));
    final value = settings.writes.single.split('=').skip(1).join('=');
    final policy = UnattendedPolicy.fromSetting(value);
    expect(settings.writes.single, startsWith('$kTestWorkspaceId:'));
    expect(settings.writes.single, contains(unattendedPolicySettingKey));
    expect(policy.digestHour, 7);
    expect(policy.expiry, const Duration(hours: 48));
    expect(jsonDecode(value), isA<Map<String, dynamic>>());
  });
}
