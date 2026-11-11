import 'package:cc_domain/core/domain/value_objects/agent_commit_attribution.dart';
import 'package:test/test.dart';

void main() {
  test('a workspace choice overrides every member, and clearing it restores '
      'their own preference', () {
    for (final user in ['true', 'false']) {
      expect(
        resolveAgentCommitAttribution(
          userPreference: user,
          workspaceOverride: 'false',
        ),
        isFalse,
      );
      expect(
        resolveAgentCommitAttribution(
          userPreference: user,
          workspaceOverride: 'true',
        ),
        isTrue,
      );
      expect(
        resolveAgentCommitAttribution(
          userPreference: user,
          workspaceOverride: AgentAttributionOverride.inherit.storedValue,
        ),
        user == 'true',
      );
    }
  });

  test('an unset or unreadable choice is on', () {
    expect(
      resolveAgentCommitAttribution(
        userPreference: null,
        workspaceOverride: null,
      ),
      isTrue,
    );
    expect(
      resolveAgentCommitAttribution(
        userPreference: 'invalid',
        workspaceOverride: 'invalid',
      ),
      isTrue,
    );
  });

  test('the override round-trips through its stored value', () {
    for (final override in AgentAttributionOverride.values) {
      expect(
        AgentAttributionOverride.fromStored(override.storedValue),
        override,
      );
    }
    expect(AgentAttributionOverride.inherit.value, isNull);
    expect(AgentAttributionOverride.enabled.value, isTrue);
    expect(AgentAttributionOverride.disabled.value, isFalse);
  });

  test('the instruction every adapter gets names the trailer variable and '
      'forbids overriding identity or signing', () {
    expect(
      agentCommitAttributionInstruction,
      contains('CC_GIT_COAUTHOR_TRAILER'),
    );
    expect(agentCommitAttributionInstruction, contains('Signed-off-by'));
    expect(agentCommitAttributionInstruction, contains('signing'));
  });
}
