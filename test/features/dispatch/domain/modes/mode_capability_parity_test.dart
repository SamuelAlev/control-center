import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/features/dispatch/domain/modes/mode_capability_profile.dart';
import 'package:cc_domain/features/dispatch/domain/prompts/capability_preamble.dart';
import 'package:cc_domain/features/dispatch/domain/prompts/mode_prompts.dart';
import 'package:cc_domain/features/dispatch/domain/prompts/prompt_builder.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/plan_mode_contract.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/teammate_brief.dart';
import 'package:cc_domain/features/guardrails/domain/services/policy_resolver.dart';
import 'package:cc_domain/features/mcp/domain/value_objects/mode_tool_policy.dart';
import 'package:cc_harness/tools.dart';
import 'package:flutter_test/flutter_test.dart';

/// The tests that would have caught the plan-mode silent-success bug.
///
/// The bug survived because nothing asserted that the prompt, the MCP
/// allow-list, the tool surface and the guard preset agree about a mode. Each
/// of these is one of those agreements, expressed as an assertion.
void main() {
  group('every mode has a profile', () {
    test('the table is total', () {
      for (final mode in Mode.values) {
        expect(
          modeCapabilityProfiles[mode],
          isNotNull,
          reason: 'Mode.${mode.name} has no capability profile',
        );
        expect(profileFor(mode).mode, mode);
      }
    });
  });

  group('a required verb is always reachable', () {
    // This is the invariant orchestrate mode violated in production: its only
    // output verb declares `vendorSyncWrite`, which the read-only preset denies.
    test('required verbs survive the mode tool surface', () {
      for (final mode in Mode.values) {
        final profile = profileFor(mode);
        final surface = profile.toToolSurfaceSpec();
        for (final verb in profile.requiredVerbs) {
          expect(
            surface.pinnedNames,
            contains(verb),
            reason: '${mode.name}: `$verb` must be pinned into the surface',
          );
          // Pinned survives even a write-tier verb in a deny-by-name surface.
          expect(
            surface.admits(_FakeTool(verb, ToolApprovalTier.write)),
            isTrue,
            reason:
                '${mode.name}: the surface drops its own output verb `$verb`',
          );
        }
      }
    });

    test('required verbs are on the mode MCP allow-list', () {
      for (final mode in Mode.values) {
        for (final verb in profileFor(mode).requiredVerbs) {
          expect(
            ModeToolPolicy.isAllowed(verb, mode),
            isTrue,
            reason:
                '${mode.name}: `$verb` is not in the MCP allow-list, so the '
                'external-CLI path would refuse the mode its own deliverable',
          );
        }
      }
    });

    test('the sanctioned exit verb is allow-listed and pinned', () {
      for (final mode in Mode.values) {
        final profile = profileFor(mode);
        final exit = profile.sanctionedExitVerb;
        if (exit == null) {
          continue;
        }
        expect(ModeToolPolicy.isAllowed(exit, mode), isTrue);
        expect(profile.pinnedVerbs, contains(exit));
      }
    });

    test('interaction verbs are always pinned', () {
      // `ask_user_question` IS the approval mechanism — gating it would deadlock
      // a run that needs to ask something.
      for (final mode in Mode.values) {
        expect(
          profileFor(mode).pinnedVerbs,
          containsAll(ModeCapabilityProfile.interactionVerbs),
        );
      }
    });
  });

  group('the guard preset cannot deny a mode its deliverable', () {
    test('a pinned verb is exempt even when its effect class is denied', () {
      // The exemption lives at the dispatch gate (pinned verbs are pre-approved
      // before the resolver runs). Assert the two halves are consistent: the
      // class may be denied and the verb must be pinned so the exemption
      // applies.
      const resolver = PolicyResolver();
      for (final mode in Mode.values) {
        final profile = profileFor(mode);
        for (final cls in profile.deniedClasses) {
          final resolution = resolver.resolveClass(
            cls,
            rules: const [],
            mode: mode,
          );
          expect(
            resolution.decision.name,
            'deny',
            reason: '${mode.name}: the preset must deny ${cls.name}',
          );
        }
        if (profile.requiredVerbs.isNotEmpty) {
          expect(profile.pinnedVerbs, containsAll(profile.requiredVerbs));
        }
      }
    });
  });

  group('prompt / tool-surface parity', () {
    test('the generated preamble names every required verb', () {
      for (final mode in Mode.values) {
        final profile = profileFor(mode);
        if (profile.requiredVerbs.isEmpty) {
          continue;
        }
        final preamble = buildCapabilityPreamble(
          profile,
          materializedToolNames: profile.requiredVerbs.toList(),
        );
        for (final verb in profile.requiredVerbs) {
          expect(preamble, contains('`$verb`'));
        }
      }
    });

    test('the preamble flags a required verb missing from the tool list', () {
      // A composition fault should be loud in the prompt, not discovered by the
      // agent failing — a silent inconsistency is what caused this bug class.
      final preamble = buildCapabilityPreamble(
        profileFor(Mode.plan),
        materializedToolNames: const ['read', 'search'],
      );
      expect(preamble, contains('WARNING'));
      expect(preamble, contains('configuration fault'));
    });

    test('the preamble lists only tools the run actually has', () {
      final preamble = buildCapabilityPreamble(
        profileFor(Mode.plan),
        materializedToolNames: const ['read', 'submit_plan'],
      );
      final inventory = preamble
          .split('\n')
          .firstWhere((l) => l.startsWith('`'), orElse: () => '');
      expect(inventory, contains('`read`'));
      expect(inventory, contains('`submit_plan`'));
      // Absent tools appear ONLY in the "you do NOT have" sentence, never in
      // the inventory line the model reads as its capability list.
      expect(inventory, isNot(contains('`bash`')));
      expect(inventory, isNot(contains('`write`')));
      expect(preamble, contains('You do NOT have'));
      expect(preamble, contains('You have exactly 2 tools'));
    });

    test('every tool a mode prompt names is reachable in that mode', () {
      // The check that fails on drift. Two surfaces have to be consulted,
      // because two different mechanisms admit tools: bridged MCP tools go
      // through the curated allow-list, built-in harness tools go through the
      // tier/deny filter. The old plan prompt failed BOTH — it described a
      // `write` workflow the surface had removed and named
      // `list_pull_requests`, which is not on plan mode's allow-list.
      for (final mode in Mode.values) {
        final block = buildModeSystemBlock(
          mode,
          ctx: const ModePromptContext(planGoal: 'do the thing'),
        );
        final profile = profileFor(mode);
        final surface = profile.toToolSurfaceSpec();
        final named = RegExp(r'`([a-z_][a-z0-9_]*)`')
            .allMatches(block)
            .map((m) => m.group(1)!)
            .where(_knownToolNames.contains)
            .toSet();
        if (mode != Mode.chat) {
          // The read-only modes all carry curated guidance that names verbs;
          // chat's block is generic on purpose.
          expect(
            named,
            isNotEmpty,
            reason: '${mode.name} prompt names no tools at all — suspicious',
          );
        }
        for (final name in named) {
          if (profile.forbiddenVerbs.contains(name)) {
            // Named on purpose as unavailable. Assert it really is.
            final builtin = _builtinTiers[name];
            if (builtin != null) {
              expect(
                surface.admits(_FakeTool(name, builtin)),
                isFalse,
                reason:
                    '${mode.name} prompt calls `$name` forbidden, but the '
                    'surface still admits it',
              );
            }
            continue;
          }
          final builtinTier = _builtinTiers[name];
          final reachable = builtinTier != null
              ? surface.admits(_FakeTool(name, builtinTier))
              : ModeToolPolicy.isAllowed(name, mode);
          expect(
            reachable,
            isTrue,
            reason:
                '${mode.name} prompt names `$name`, which that mode cannot '
                'call — the prompt and the tool surface disagree',
          );
        }
      }
    });
  });

  group('staffing guidance stays inside the mode', () {
    // The "Your team" section and the "decide who does the work" step name
    // delegation verbs. Naming one a mode cannot call is the same class of bug
    // as the plan-mode `write` instruction: guidance the run cannot follow.
    test('every tool the full brief names is reachable in that mode', () {
      const teammate = TeammateBrief(
        id: 'agent-2',
        name: 'scribe',
        title: 'Technical writer',
        skills: ['writing'],
      );
      for (final mode in Mode.values) {
        final brief = PromptBuilder()
            .team(const [teammate], mode: mode)
            .executionProcedure(mode: mode)
            .buildPersistentBrief();
        final profile = profileFor(mode);
        final surface = profile.toToolSurfaceSpec();
        final named = RegExp(r'`([a-z_][a-z0-9_]*)`')
            .allMatches(brief)
            .map((m) => m.group(1)!)
            .where(_knownToolNames.contains)
            .toSet();
        for (final name in named) {
          final builtinTier = _builtinTiers[name];
          final reachable = builtinTier != null
              ? surface.admits(_FakeTool(name, builtinTier))
              : ModeToolPolicy.isAllowed(name, mode);
          expect(
            reachable,
            isTrue,
            reason:
                '${mode.name}: staffing guidance names `$name`, which that '
                'mode cannot call',
          );
        }
      }
    });

    test('chat mode gets the roster, the ids and the delegation verbs', () {
      const teammate = TeammateBrief(
        id: 'agent-2',
        name: 'scribe',
        title: 'Technical writer',
        skills: ['writing', 'docs'],
      );
      final brief = PromptBuilder()
          .team(const [teammate], mode: Mode.chat)
          .executionProcedure()
          .buildPersistentBrief();

      expect(brief, contains('Your team'));
      // The id is the argument delegate_task takes — without it the agent
      // cannot delegate even when it decides to.
      expect(brief, contains('@scribe (id: agent-2)'));
      expect(brief, contains('writing, docs'));
      expect(brief, contains('`delegate_task`'));
      expect(brief, contains('`hire_agent`'));
      // The decision is a step of its own, before "do the work".
      final decideAt = brief.indexOf('Decide who does the work');
      final workAt = brief.indexOf('Do the work immediately');
      expect(decideAt, greaterThan(-1));
      expect(workAt, greaterThan(decideAt));
    });

    test('a lone agent is still told it can hire', () {
      final brief = PromptBuilder()
          .team(const [], mode: Mode.chat)
          .buildPersistentBrief();

      expect(brief, contains('only agent in this workspace'));
      expect(brief, contains('`hire_agent`'));
    });

    test('read-only modes fall back to the verbs they actually have', () {
      const teammate = TeammateBrief(
        id: 'agent-2',
        name: 'scribe',
        title: 'Technical writer',
      );
      final brief = PromptBuilder().team(const [
        teammate,
      ], mode: Mode.plan).buildPersistentBrief();

      // Plan mode can propose a hire and consult, but cannot hire or delegate.
      expect(brief, contains('`propose_hire`'));
      expect(brief, contains('`consult_agent`'));
      expect(brief, isNot(contains('`hire_agent`')));
      expect(brief, isNot(contains('`delegate_task`')));
    });
  });

  group('the plan-mode prompt no longer promises a file', () {
    late String block;

    setUp(() {
      block = buildModeSystemBlock(
        Mode.plan,
        ctx: const ModePromptContext(planGoal: 'improve the tabs'),
      );
    });

    test('it names the output verb', () {
      expect(block, contains('`$planModeOutputVerb`'));
    });

    test('it carries no trace of the retired file contract', () {
      for (final ghost in const [
        'plans/',
        '{epochMs}',
        'kebab-slug',
        'write exactly ONE new file',
        'plans directory',
      ]) {
        expect(
          block,
          isNot(contains(ghost)),
          reason:
              'the plan prompt still references "$ghost", which has no '
              'writable path and no write tool behind it',
        );
      }
    });

    test('it names the forbidden verbs', () {
      for (final verb in planModeForbiddenVerbs) {
        expect(block, contains('`$verb`'));
      }
    });

    test('it still carries the conversation goal', () {
      expect(block, contains('improve the tabs'));
    });

    test('the execution procedure does not tell plan mode to write a file', () {
      final procedure = (PromptBuilder()..executionProcedure(mode: Mode.plan))
          .build('go');
      expect(procedure, isNot(contains('plans directory')));
      expect(procedure, contains(planModeOutputVerb));
    });
  });

  group('completion contracts', () {
    test('plan and orchestrate declare one; chat and review do not', () {
      expect(profileFor(Mode.plan).toCompletionContract(), isNotNull);
      expect(profileFor(Mode.orchestrate).toCompletionContract(), isNotNull);
      expect(profileFor(Mode.chat).toCompletionContract(), isNull);
      expect(profileFor(Mode.review).toCompletionContract(), isNull);
    });

    test('the plan contract requires exactly the plan-mode output verb', () {
      final contract = profileFor(Mode.plan).toCompletionContract()!;
      expect(contract.requiredToolNames, {planModeOutputVerb});
      expect(contract.maxNudges, 1);
      expect(contract.nudge, contains(planModeOutputVerb));
      // The nudge must authorize an honest no-deliverable exit: plan mode is a
      // channel setting, so a plain question can arrive inside it.
      expect(contract.nudge.toLowerCase(), contains('needs no plan'));
    });

    test('the unmet summary is plain language, not a code', () {
      final summary = profileFor(
        Mode.plan,
      ).toCompletionContract()!.unmetSummary;
      expect(summary.toLowerCase(), contains('without submitting a plan'));
    });
  });

  group('sandbox posture comes from the profile', () {
    test('only chat has a writable worktree', () {
      expect(profileFor(Mode.chat).worktreeWritable, isTrue);
      for (final mode in [Mode.review, Mode.plan, Mode.orchestrate]) {
        expect(profileFor(mode).worktreeWritable, isFalse);
      }
    });

    test('read-only surfaces drop the worktree mutators', () {
      for (final mode in [Mode.review, Mode.plan, Mode.orchestrate]) {
        final surface = profileFor(mode).toToolSurfaceSpec();
        for (final mutator in ToolSurfaceSpec.worktreeMutators) {
          expect(
            surface.admits(_FakeTool(mutator, ToolApprovalTier.write)),
            isFalse,
            reason: '${mode.name} must not expose `$mutator`',
          );
        }
        expect(
          surface.admits(_FakeTool('bash', ToolApprovalTier.exec)),
          isFalse,
        );
      }
    });

    test('read tools survive the allow-list in every read-only mode', () {
      // The safety valve: adopting curated allow-lists must not strip reads.
      for (final mode in [Mode.review, Mode.plan, Mode.orchestrate]) {
        final surface = profileFor(mode).toToolSurfaceSpec();
        for (final name in const ['read', 'search', 'find', 'get_pr_diff']) {
          expect(
            surface.admits(_FakeTool(name, ToolApprovalTier.read)),
            isTrue,
            reason: '${mode.name} lost read tool `$name`',
          );
        }
      }
    });

    test('chat admits everything', () {
      final surface = profileFor(Mode.chat).toToolSurfaceSpec();
      for (final t in [
        _FakeTool('read', ToolApprovalTier.read),
        _FakeTool('write', ToolApprovalTier.write),
        _FakeTool('bash', ToolApprovalTier.exec),
        _FakeTool('anything_at_all', ToolApprovalTier.write),
      ]) {
        expect(surface.admits(t), isTrue, reason: 'chat dropped ${t.name}');
      }
    });
  });
}

/// The built-in harness tools and their approval tiers.
///
/// Built-ins are admitted by the surface's tier/deny filter, NOT by the MCP
/// allow-list — conflating the two is why a first draft of this test failed on
/// `search`, a perfectly reachable read tool that no allow-list mentions.
const Map<String, ToolApprovalTier> _builtinTiers = {
  'read': ToolApprovalTier.read,
  'search': ToolApprovalTier.read,
  'find': ToolApprovalTier.read,
  'search_files': ToolApprovalTier.read,
  'checkpoint': ToolApprovalTier.read,
  'rewind': ToolApprovalTier.read,
  'task': ToolApprovalTier.read,
  'write': ToolApprovalTier.write,
  'edit': ToolApprovalTier.write,
  'apply_patch': ToolApprovalTier.write,
  'bash': ToolApprovalTier.exec,
  'web_fetch': ToolApprovalTier.exec,
  'web_search': ToolApprovalTier.exec,
};

/// Every name that could plausibly be a tool reference in a prompt.
final Set<String> _knownToolNames = {
  ..._builtinTiers.keys,
  ...ModeToolPolicy.reviewAllowed,
  ...ModeToolPolicy.planAllowed,
  ...ModeToolPolicy.orchestrateAllowed,
  // Named in prompts as forbidden, so they must be recognized to be checked.
  'hire_agent',
  'delegate_ticket',
  'create_ticket',
  'list_pull_requests',
  // Named by the staffing guidance (the "Your team" section + the execution
  // procedure), which resolves its verbs against each mode's allow-list.
  'delegate_task',
  'ask_agent',
  'propose_hire',
  'consult_agent',
  'list_skills',
  'create_skill',
};

class _FakeTool extends HarnessTool {
  _FakeTool(this._name, this._tier);
  final String _name;
  final ToolApprovalTier _tier;

  @override
  String get name => _name;
  @override
  String get description => 'fake';
  @override
  Map<String, dynamic> get inputSchema => const {'type': 'object'};
  @override
  ToolApprovalTier get approvalTier => _tier;

  @override
  Future<HarnessToolResult> execute(
    Map<String, dynamic> args,
    HarnessToolContext context,
  ) async => HarnessToolResult.success('ok');
}
