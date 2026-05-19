import 'package:cc_harness/tools.dart';
import 'package:test/test.dart';

void main() {
  group('SubagentType.fromId', () {
    test('parses known ids', () {
      expect(SubagentType.fromId('explore'), SubagentType.explore);
      expect(SubagentType.fromId('plan'), SubagentType.plan);
      expect(SubagentType.fromId('general'), SubagentType.general);
    });

    test('defaults to general for unknown/null', () {
      expect(SubagentType.fromId(null), SubagentType.general);
      expect(SubagentType.fromId('nope'), SubagentType.general);
    });
  });

  group('SubagentProfile', () {
    test('explore and plan are read-only (no write/exec tiers)', () {
      for (final type in [SubagentType.explore, SubagentType.plan]) {
        final p = subagentProfileFor(type);
        expect(p.surface.maxTier, ToolApprovalTier.write);
        expect(p.surface.denyNames, ToolSurfaceSpec.worktreeMutators);
        expect(p.allowedTiers, {ToolApprovalTier.read});
        expect(p.allowedTiers.contains(ToolApprovalTier.write), isFalse);
        expect(p.allowedTiers.contains(ToolApprovalTier.exec), isFalse);
      }
    });

    test('general permits read/write/exec unrestricted', () {
      final p = subagentProfileFor(SubagentType.general);
      expect(p.surface.maxTier, ToolApprovalTier.exec);
      expect(p.surface.denyNames, isEmpty);
      expect(p.allowedTiers, {
        ToolApprovalTier.read,
        ToolApprovalTier.write,
        ToolApprovalTier.exec,
      });
    });

    test('buildSystemPrompt appends the addendum to the base', () {
      final p = subagentProfileFor(SubagentType.explore);
      final prompt = p.buildSystemPrompt('BASE');
      expect(prompt, startsWith('BASE'));
      expect(prompt, contains(p.systemPromptAddendum));
    });

    test('the prompt states whether this level may spawn', () {
      final p = subagentProfileFor(SubagentType.general);
      expect(
        p.buildSystemPrompt('BASE', canSpawn: false),
        contains('cannot spawn further subagents'),
      );
      final spawning = p.buildSystemPrompt('BASE', canSpawn: true);
      expect(spawning, contains('`task`'));
      expect(
        spawning,
        contains('cannot spawn any further'),
        reason: 'a spawning level must still be told its children are the last',
      );
      expect(spawning, isNot(contains('You cannot spawn further subagents')));
    });

    test('nesting is capped at two levels: agent -> sub -> sub', () {
      expect(maxSubagentDepth, 2);
    });

    test('a read-only parent cannot spawn a write/exec child', () {
      final explore = subagentProfileFor(SubagentType.explore);
      final plan = subagentProfileFor(SubagentType.plan);
      final general = subagentProfileFor(SubagentType.general);

      // `task` is read-tier, so it survives the read-only clamp — this check is
      // the only thing preventing an explore child from reaching write/exec
      // tools through a general grandchild.
      expect(explore.admitsChildType(SubagentType.general), isFalse);
      expect(plan.admitsChildType(SubagentType.general), isFalse);

      // Read-only siblings are fine, and a general parent keeps full reach.
      expect(explore.admitsChildType(SubagentType.explore), isTrue);
      expect(explore.admitsChildType(SubagentType.plan), isTrue);
      for (final t in SubagentType.values) {
        expect(general.admitsChildType(t), isTrue);
      }
    });
  });
}
