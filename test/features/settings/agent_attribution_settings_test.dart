import 'dart:async';

import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/core/domain/repositories/workspace_settings_repository.dart';
import 'package:cc_domain/core/domain/value_objects/agent_commit_attribution.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/general/agent_attribution_section.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/workspace/agent_attribution_workspace_section.dart';
import 'package:control_center/features/settings/providers/workspace_settings_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/active_workspace.dart';
import '../../helpers/test_wrap.dart';

class _Preferences implements RemoteIdentityRepository {
  final values = <String, String>{};
  final changed = StreamController<Map<String, String>>.broadcast();

  @override
  Stream<Map<String, String>> watchOwnPrefs() async* {
    yield Map.of(values);
    yield* changed.stream;
  }

  @override
  Future<void> prefsSet(String key, String? value) async {
    if (value == null) {
      values.remove(key);
    } else {
      values[key] = value;
    }
    changed.add(Map.of(values));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Settings implements WorkspaceSettingsRepository {
  final values = <String, Map<String, String>>{};
  final changed = StreamController<void>.broadcast();

  @override
  Future<Map<String, String>> getAll(String workspaceId) async =>
      Map.of(values[workspaceId] ?? const {});

  @override
  Future<String?> get(String workspaceId, String key) async =>
      values[workspaceId]?[key];

  @override
  Stream<Map<String, String>> watchAll(String workspaceId) async* {
    yield await getAll(workspaceId);
    await for (final _ in changed.stream) {
      yield await getAll(workspaceId);
    }
  }

  @override
  Future<void> set(String workspaceId, String key, String? value) async {
    final settings = values.putIfAbsent(workspaceId, () => {});
    if (value == null) {
      settings.remove(key);
    } else {
      settings[key] = value;
    }
    changed.add(null);
  }
}

void main() {
  const key = agentCommitAttributionSettingKey;
  late _Preferences preferences;
  late _Settings settings;
  late ProviderContainer container;

  Future<void> pump(
    WidgetTester tester, {
    bool admin = true,
    bool rtl = false,
  }) async {
    container = ProviderContainer(
      overrides: [
        activeWorkspaceIdOverride('ws-a'),
        identityRepositoryProvider.overrideWithValue(preferences),
        workspaceSettingsRepositoryProvider.overrideWithValue(settings),
        myWorkspaceRoleProvider('ws-a').overrideWith(
          (ref) => admin ? WorkspaceRole.admin : WorkspaceRole.member,
        ),
        myWorkspaceRoleProvider(
          'ws-b',
        ).overrideWith((ref) => WorkspaceRole.admin),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: testWrap(
          const SingleChildScrollView(
            child: Column(
              children: [
                AgentAttributionSection(),
                AgentAttributionWorkspaceSection(),
              ],
            ),
          ),
          textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  setUp(() {
    preferences = _Preferences();
    settings = _Settings();
    addTearDown(preferences.changed.close);
    addTearDown(settings.changed.close);
  });

  testWidgets(
    'workspace override locks effective value without changing personal preference',
    (tester) async {
      await pump(tester);
      CcSwitch toggle() => tester.widget<CcSwitch>(find.byType(CcSwitch));
      expect(toggle().value, isTrue);
      await tester.tap(find.byType(CcSwitch));
      await tester.pumpAndSettle();
      expect(preferences.values[key], 'false');
      expect(toggle().value, isFalse);

      await settings.set('ws-a', key, 'true');
      await tester.pumpAndSettle();
      expect(toggle().value, isTrue);
      expect(toggle().onChanged, isNull);
      await tester.tap(find.byType(CcSwitch));
      expect(preferences.values[key], 'false');

      await settings.set('ws-a', key, null);
      await tester.pumpAndSettle();
      expect(toggle().value, isFalse);
      expect(toggle().onChanged, isNotNull);
    },
  );

  testWidgets(
    'user yes and workspace no displays a disabled no, isolated to that workspace',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      preferences.values[key] = 'true';
      settings.values['ws-a'] = {key: 'false'};
      await pump(tester, rtl: true);
      var toggle = tester.widget<CcSwitch>(find.byType(CcSwitch));
      expect(toggle.value, isFalse);
      expect(toggle.onChanged, isNull);
      expect(tester.takeException(), isNull);

      await container
          .read(activeWorkspaceIdProvider.notifier)
          .setActive('ws-b');
      await tester.pumpAndSettle();
      toggle = tester.widget<CcSwitch>(find.byType(CcSwitch));
      expect(toggle.value, isTrue);
      expect(toggle.onChanged, isNotNull);
      expect(preferences.values[key], 'true');
    },
  );

  testWidgets('switching workspace closes an open policy menu', (tester) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    await pump(tester);
    final selector = find.byType(CcSelect<AgentAttributionOverride>);
    await tester.tap(selector);
    await tester.pumpAndSettle();
    expect(find.text(l10n.settingsWorkspaceAgentCoauthorNever), findsOneWidget);

    await container.read(activeWorkspaceIdProvider.notifier).setActive('ws-b');
    await tester.pumpAndSettle();
    expect(find.text(l10n.settingsWorkspaceAgentCoauthorNever), findsNothing);
    expect(settings.values, isEmpty);

    await tester.tap(selector);
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.settingsWorkspaceAgentCoauthorNever).last);
    await tester.pumpAndSettle();
    expect(settings.values['ws-b']?[key], 'false');
    expect(settings.values['ws-a'], isNull);
  });

  testWidgets(
    'workspace admin can select no and inherit; members cannot edit policy',
    (tester) async {
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      await pump(tester);
      final selector = find.byType(CcSelect<AgentAttributionOverride>);
      await tester.tap(selector);
      await tester.pumpAndSettle();
      await tester.tap(
        find.text(l10n.settingsWorkspaceAgentCoauthorNever).last,
      );
      await tester.pumpAndSettle();
      expect(settings.values['ws-a']?[key], 'false');
      expect(tester.widget<CcSwitch>(find.byType(CcSwitch)).onChanged, isNull);

      await tester.tap(selector);
      await tester.pumpAndSettle();
      await tester.tap(
        find.text(l10n.settingsWorkspaceAgentCoauthorInherit).last,
      );
      await tester.pumpAndSettle();
      expect(settings.values['ws-a']?.containsKey(key), isFalse);
      expect(
        tester.widget<CcSwitch>(find.byType(CcSwitch)).onChanged,
        isNotNull,
      );
    },
  );

  testWidgets('non-admin workspace policy is read-only', (tester) async {
    await pump(tester, admin: false);
    final select = tester.widget<CcSelect<AgentAttributionOverride>>(
      find.byType(CcSelect<AgentAttributionOverride>),
    );
    expect(select.enabled, isFalse);
    expect(tester.widget<CcSwitch>(find.byType(CcSwitch)).onChanged, isNotNull);
  });
}
