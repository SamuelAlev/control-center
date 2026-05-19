import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/value_objects/agent_skills.dart';
import 'package:cc_domain/features/settings/domain/entities/claude_account.dart';
import 'package:cc_harness/provider.dart'
    show HarnessAuthMethod, HarnessProviderEnabled, HarnessProviderInfo;
import 'package:control_center/features/settings/presentation/settings_contributions.dart';
import 'package:control_center/features/settings/presentation/widgets/agent_account_pools_tab.dart';
import 'package:control_center/features/settings/providers/claude_account_providers.dart';
import 'package:control_center/features/settings/providers/harness_providers_providers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
// `flutter_riverpod` does not re-export `Override`; `misc.dart` is its public
// home in riverpod 3.
import 'package:riverpod/misc.dart' show Override;

Agent _agent({String? adapterId}) => Agent(
  id: 'agent-1',
  name: 'Ada',
  title: 'Engineer',
  agentMdPath: '/tmp/ada.md',
  workspaceId: 'ws-1',
  skills: AgentSkills(const []),
  adapterId: adapterId,
  createdAt: DateTime.utc(2026),
);

List<ClaudeAccountView> _claudeAccounts(int n) => [
  for (var i = 0; i < n; i++)
    ClaudeAccountView(
      account: ClaudeAccount(id: 'acct-$i', label: 'Account $i', loggedIn: true),
    ),
];

/// Evaluates the contributed predicate inside a real `WidgetRef`.
Future<bool> _visible(
  WidgetTester tester, {
  required Agent agent,
  int claudeAccounts = 0,
  List<HarnessProviderInfo> rotatable = const [],
}) async {
  final overrides = <Override>[
    claudeAccountsProvider.overrideWith(
      (ref) async => _claudeAccounts(claudeAccounts),
    ),
    rotatableHarnessProvidersProvider.overrideWithValue(rotatable),
  ];

  late bool result;
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: Consumer(
        builder: (context, ref, _) {
          result = agentHasAccountsToRotate(ref, agent);
          return const SizedBox.shrink();
        },
      ),
    ),
  );
  // The account probe is a future; let it land before reading the verdict.
  await tester.pump();
  return result;
}

void main() {
  group('accountLaneForAdapter', () {
    test('a null adapter is the built-in harness, matching dispatch', () {
      // `DispatchAgentUseCase` falls back to `builtInAdapter` for a null id, so
      // treating null as "no lane" would describe a lane the run never uses.
      expect(accountLaneForAdapter(null), AccountLane.harness);
      expect(accountLaneForAdapter('cc-harness'), AccountLane.harness);
    });

    test('claude-code is its own lane', () {
      expect(accountLaneForAdapter('claude-code'), AccountLane.claudeCode);
    });

    test('a runner that owns its credential has no lane here', () {
      expect(accountLaneForAdapter('codex'), AccountLane.none);
      expect(accountLaneForAdapter('opencode'), AccountLane.none);
    });
  });

  group('the Accounts tab is offered only when it has a choice to make', () {
    testWidgets('claude-code with two accounts shows it', (tester) async {
      expect(
        await _visible(
          tester,
          agent: _agent(adapterId: 'claude-code'),
          claudeAccounts: 2,
        ),
        isTrue,
      );
    });

    testWidgets('claude-code with one account hides it', (tester) async {
      // One login is not a pool. The editor refuses to render below two
      // candidates anyway, so the tab could only ever have been empty.
      expect(
        await _visible(
          tester,
          agent: _agent(adapterId: 'claude-code'),
          claudeAccounts: 1,
        ),
        isFalse,
      );
    });

    testWidgets('claude-code with no accounts hides it', (tester) async {
      expect(
        await _visible(
          tester,
          agent: _agent(adapterId: 'claude-code'),
        ),
        isFalse,
      );
    });

    testWidgets('a harness agent ignores the Claude logins', (tester) async {
      // The regression the gate exists for: a built-in-harness agent used to
      // get an Accounts tab headed by Claude Code logins it cannot use.
      expect(
        await _visible(
          tester,
          agent: _agent(adapterId: 'cc-harness'),
          claudeAccounts: 3,
        ),
        isFalse,
      );
    });

    testWidgets('a harness agent shows it for a rotatable provider', (
      tester,
    ) async {
      expect(
        await _visible(
          tester,
          agent: _agent(adapterId: 'cc-harness'),
          rotatable: const [
            HarnessProviderInfo(
              id: 'anthropic',
              displayName: 'Anthropic',
              authMethods: [HarnessAuthMethod.apiKey],
              enabled: HarnessProviderEnabled.account,
              hasCredential: true,
            ),
          ],
        ),
        isTrue,
      );
    });

    testWidgets('another runner never shows it', (tester) async {
      expect(
        await _visible(
          tester,
          agent: _agent(adapterId: 'codex'),
          claudeAccounts: 3,
          rotatable: const [
            HarnessProviderInfo(
              id: 'anthropic',
              displayName: 'Anthropic',
              authMethods: [HarnessAuthMethod.apiKey],
              enabled: HarnessProviderEnabled.account,
              hasCredential: true,
            ),
          ],
        ),
        isFalse,
      );
    });
  });
}
