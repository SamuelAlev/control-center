import 'package:control_center/features/messaging/presentation/ide/editor/agent_activity_tab.dart';
import 'package:control_center/features/messaging/presentation/ide/editor/messaging_tab_kinds.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pins the run-activity tab's identity contract: it dedupes on the RUN and
/// every arg is a primitive so the layout codec can round-trip it (a tab holding
/// any non-primitive value is dropped on encode).
void main() {
  group('agentActivityTab', () {
    test('carries the activity kind and icon', () {
      final tab = agentActivityTab(
        workspaceId: 'ws-1',
        spaceId: 'c-1',
        runId: 'run-1',
        agentId: 'agent-1',
        label: 'scout',
        fallbackLabel: 'Agent activity',
      );

      expect(tab.kind, MessagingTabKinds.agentActivity);
      expect(tab.icon, AppIcons.activity);
    });

    test('dedupes on the run id, so re-opening refocuses one tab', () {
      final a = agentActivityTab(
        workspaceId: 'ws-1',
        spaceId: 'c-1',
        runId: 'run-1',
        agentId: 'agent-1',
        label: 'scout',
        fallbackLabel: 'Agent activity',
      );
      final b = agentActivityTab(
        workspaceId: 'ws-1',
        spaceId: 'c-2',
        runId: 'run-1',
        agentId: 'other',
        label: 'different label',
        fallbackLabel: 'Agent activity',
      );
      final c = agentActivityTab(
        workspaceId: 'ws-1',
        spaceId: 'c-1',
        runId: 'run-2',
        agentId: 'agent-1',
        label: 'scout',
        fallbackLabel: 'Agent activity',
      );

      expect(a.dedupKey, 'agentActivity:run-1');
      expect(b.dedupKey, a.dedupKey);
      expect(c.dedupKey, isNot(a.dedupKey));
    });

    test('records every arg the pane and a restore need', () {
      final tab = agentActivityTab(
        workspaceId: 'ws-1',
        spaceId: 'c-1',
        runId: 'run-1',
        agentId: 'agent-1',
        label: 'scout',
        fallbackLabel: 'Agent activity',
      );

      expect(tab.args['workspaceId'], 'ws-1');
      expect(tab.args['spaceId'], 'c-1');
      expect(tab.args['runId'], 'run-1');
      expect(tab.args['agentId'], 'agent-1');
      expect(tab.args['label'], 'scout');
    });

    test('every arg value is a primitive the codec accepts', () {
      final tab = agentActivityTab(
        workspaceId: 'ws-1',
        spaceId: 'c-1',
        runId: 'run-1',
        agentId: 'agent-1',
        label: 'scout',
        fallbackLabel: 'Agent activity',
      );

      for (final value in tab.args.values) {
        expect(
          value,
          anyOf(isA<String>(), isA<num>(), isA<bool>(), isNull),
          reason: 'a non-primitive arg would make the tab unrestorable',
        );
      }
    });

    group('label', () {
      test('is used as-is when short enough', () {
        final tab = agentActivityTab(
          workspaceId: 'ws-1',
          spaceId: 'c-1',
          runId: 'run-1',
          agentId: 'agent-1',
          label: 'scout the repo',
          fallbackLabel: 'Agent activity',
        );

        expect(tab.label, 'scout the repo');
      });

      test('truncates past the strip budget', () {
        final long = 'a' * 100;
        final tab = agentActivityTab(
          workspaceId: 'ws-1',
          spaceId: 'c-1',
          runId: 'run-1',
          agentId: 'agent-1',
          label: long,
          fallbackLabel: 'Agent activity',
        );

        expect(tab.label.length, kAgentActivityTabLabelMax);
        expect(tab.label, endsWith('…'));
      });

      test('falls back to the localized default when blank', () {
        final tab = agentActivityTab(
          workspaceId: 'ws-1',
          spaceId: 'c-1',
          runId: 'run-1',
          agentId: 'agent-1',
          label: '   ',
          fallbackLabel: 'Agent activity',
        );

        expect(tab.label, 'Agent activity');
        expect(tab.args['label'], 'Agent activity');
      });
    });
  });
}
