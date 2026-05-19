import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/value_objects/agent_role.dart';
import 'package:cc_domain/core/domain/value_objects/agent_skills.dart';
import 'package:cc_domain/core/domain/value_objects/app_locale.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/core/domain/value_objects/output_contract_mode.dart';
import 'package:cc_domain/core/domain/value_objects/wake_context.dart';
import 'package:cc_domain/features/dispatch/domain/prompts/mode_prompts.dart';
import 'package:cc_domain/features/dispatch/domain/prompts/output_contract_prompt.dart';
import 'package:cc_domain/features/dispatch/domain/prompts/protocol_documentation.dart';
import 'package:cc_domain/features/dispatch/domain/prompts/role_personas.dart';
import 'package:cc_domain/features/dispatch/domain/prompts/uncertainty_protocol.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/mention_context.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/plan_mode_contract.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/teammate_brief.dart';
import 'package:cc_domain/features/mcp/domain/value_objects/mode_tool_policy.dart';

/// One named span of a built prompt: everything written between the point the
/// span was opened and the point the next one was.
class PromptSection {
  /// Creates a [PromptSection].
  const PromptSection({required this.label, required this.text});

  /// What this span is (`Identity`, `Persona`, `Conversation`, …).
  final String label;

  /// The verbatim slice of the assembled prompt.
  final String text;
}

/// Builds the system prompt context block sent to an agent before the user prompt.
class PromptBuilder {
  final StringBuffer _buf = StringBuffer();
  bool _hasContent = false;

  /// Section labels paired with the offset in [_buf] where each begins.
  ///
  /// Recorded as offsets rather than as separate buffers on purpose: [sections]
  /// slices the SAME string [build] returns, so an attributed breakdown can
  /// never disagree with the prompt actually sent — the two cannot drift
  /// because there is only one buffer.
  final List<({String label, int offset})> _marks = [];

  /// Sets the agent identity section: id, name, workspace and memory scoping rules.
  PromptBuilder identity(Agent agent) {
    _section(identityLabel);
    _buf.writeln(
      'IMPORTANT: "the user" and "you" are different entities. '
      'You are an agent. The user is a human you are chatting with.',
    );
    _buf.writeln('- agent_id: ${agent.id}');
    _buf.writeln('- agent_name: ${agent.name}');
    // The workspace is intrinsic to the agent (never null), so it is always
    // surfaced — agents must scope every workspace MCP call to it.
    _buf.writeln('- workspace_id: ${agent.workspaceId}');
    _buf.writeln(
      'When calling memory MCP tools '
      '(update_my_notes, record_observation, propose_fact, …) pass these '
      'exact UUIDs as `agent_id` and `workspace_id`. Never substitute the '
      'agent name or role. The control-center MCP server also injects them '
      'automatically when you omit them and it always pins `workspace_id` '
      'to YOUR workspace — you cannot act on another workspace.',
    );
    return this;
  }

  /// Documents the tool surface: everything catalogued is callable by name,
  /// whether or not its schema is loaded, and tool search is the shortcut for
  /// finding the right one by intent.
  ///
  /// Deliberately worded to be true on BOTH transports. The built-in harness
  /// loads only a resident subset up front and pulls the rest in on first use;
  /// an external MCP client is shown the complete list. "Callable by name"
  /// holds either way — which is the property that lets one paragraph serve
  /// both without the prompt having to know which one it is talking to.
  PromptBuilder toolCatalog() {
    _section(toolCatalogLabel);
    _buf.writeln(
      'All Control Center capabilities (tickets, todos, memory, messaging, '
      'goals, work products, code graph, …) are MCP tools on the '
      '`control-center` server. Every catalogued tool is directly callable by '
      'name. Some are listed by name without their arguments until you first '
      'use one — call it anyway; its schema loads on that first call. If you '
      'are unsure which tool fits a task, search for it by intent '
      '(`search_tools` in the built-in harness, `search_tool_bm25` on an MCP '
      'client): it returns matching names with their arguments. If a tool '
      'call fails with "tool not found", search or re-list once before '
      'concluding the capability is missing.',
    );
    return this;
  }

  /// Injects resource protocol documentation and search discipline instructions.
  PromptBuilder resourceProtocols({Mode mode = Mode.chat}) {
    _mark(resourceProtocolsLabel);
    _buf.writeln(resourceProtocolDocumentation);
    _buf.writeln(searchDisciplineInstructions);
    // Memory contribution is allowed in every mode — knowledge writes are not
    // artifact mutations (the guard permits them in review/plan/orchestrate),
    // so every agent gets the management guidance and the uncertainty protocol.
    _buf.writeln(memoryManagementInstructions);
    _buf.writeln(uncertaintyProtocol);
    _hasContent = true;
    return this;
  }

  /// Tells the agent how its working directory is laid out: it is cwd'd at
  /// its private overlay inside the conversation's workspace (`AGENTS.md` +
  /// `.mcp.json`) and any repositories it can work on are isolated
  /// copy-on-write worktrees under `repos/` — each already on its own branch,
  /// with the original checkouts kept entirely outside the agent's reach.
  PromptBuilder workspaceLayout() {
    _section(workspaceLayoutLabel);
    _buf.writeln(
      'Your current working directory is your private overlay inside this '
      'conversation\'s workspace. It holds your `AGENTS.md` and `.mcp.json`; '
      'other agents in this conversation have their own overlays.',
    );
    _buf.writeln(
      'Any repositories you can work on are checked out under `repos/` — one '
      'subdirectory per repo, each an ISOLATED copy-on-write worktree already '
      'on its own branch. The ORIGINAL repository checkouts are never part of '
      'your workspace: do not read, write, or run commands against any repo '
      'path outside these roots (`list_repos` reports the paths of your '
      'isolated copies, never the originals). Make all code changes '
      'inside `repos/<name>/`, commit there and push to open a PR. If `repos/` '
      'is empty or absent, no repository is linked to this workspace yet.',
    );
    return this;
  }

  /// Appends a custom system prompt if non-empty.
  PromptBuilder systemPrompt(String? systemPrompt) {
    if (systemPrompt != null && systemPrompt.isNotEmpty) {
      _mark(agentInstructionsLabel);
      _buf.writeln(systemPrompt);
      _hasContent = true;
    }
    return this;
  }

  /// Sets the agent's persona and strategic posture based on role.
  PromptBuilder persona(String? persona, {AgentRole? role}) {
    if (persona != null && persona.isNotEmpty) {
      _section(personaLabel);
      _buf.writeln(persona);
    }
    if (role != null) {
      _section(strategicPostureLabel);
      _buf.writeln(strategicPosture(role));
      _section(voiceAndToneLabel);
      _buf.writeln(voiceAndTone(role));
    }
    return this;
  }

  /// Names the other agents in the workspace and makes staffing an explicit
  /// decision the agent owns.
  ///
  /// An agent that cannot see a roster delegates to nobody: `delegate_task` and
  /// `ask_agent` both take an agent **id**, so without this section the only way
  /// to find one is a `list_agents` call the agent is never told to make — which
  /// is why the seeded CEO, whose own `AGENTS.md` tells it to delegate and hire,
  /// did every job itself.
  ///
  /// Verb names are resolved against [mode]'s allow-list, so this section can
  /// never name a tool the run does not have (the same rule the generated
  /// capability preamble follows).
  PromptBuilder team(List<TeammateBrief> teammates, {Mode mode = Mode.chat}) {
    final delegateVerb = _firstAllowed(const [
      'delegate_task',
      'delegate_ticket',
    ], mode);
    final askVerb = _firstAllowed(const ['ask_agent', 'consult_agent'], mode);
    // Nothing to say: no teammates to describe.
    if (teammates.isEmpty) {
      return this;
    }

    _section(teamLabel);
    _buf.writeln(
      'You are not the only agent in this workspace. These teammates exist '
      'right now — the id is what the delegation tools take:',
    );
    for (final mate in teammates) {
      final skills = mate.skills.isEmpty
          ? ''
          : ' — skills: ${mate.skills.join(', ')}';
      final peer = mate.isTopLevel ? 'peer' : 'reports to someone';
      _buf.writeln(
        '  - @${mate.name} (id: ${mate.id}) — ${mate.title} [$peer]$skills',
      );
    }

    _buf.writeln();
    _buf.writeln(
      'Staffing is YOUR decision on every task and you own the '
      'outcome either way:',
    );
    if (delegateVerb != null) {
      _buf.writeln(
        '- A teammate above is clearly better suited (their skills match and '
        'yours do not) → hand that piece of work to them with `$delegateVerb`, '
        'passing their id and a self-contained brief plus acceptance criteria.',
      );
    }
    if (askVerb != null) {
      _buf.writeln(
        '- You only need an answer, not a hand-off → `$askVerb` and keep the '
        'work yourself.',
      );
    }
    _buf.writeln(
      '- You are the right agent for it → do it yourself. Do not delegate work '
      'you can finish faster than the hand-off costs, never delegate the whole '
      'request you were asked to own and never sit idle waiting on someone '
      'you could have been working alongside.',
    );
    return this;
  }

  /// The first name in [candidates] that [mode] actually permits, or null.
  static String? _firstAllowed(List<String> candidates, Mode mode) {
    for (final name in candidates) {
      if (ModeToolPolicy.isAllowed(name, mode)) {
        return name;
      }
    }
    return null;
  }

  /// Enumerates the agent's active skills.
  PromptBuilder skills(AgentSkills skills) {
    if (skills.isNotEmpty) {
      _section(skillsLabel);
      _buf.writeln(skills.join(', '));
    }
    return this;
  }

  /// Injects the execution contract rules that the agent must follow.
  PromptBuilder executionContract({Mode mode = Mode.chat}) {
    _mark(executionContractLabel);
    _buf.writeln();
    _buf.writeln('## Execution Contract');
    _buf.writeln('You MUST follow these rules during every run:');
    _buf.writeln(
      '1. **Start actionable work immediately.** '
      'Do not stop at planning unless the task explicitly asks for a plan. '
      'Begin implementation in the same session.',
    );
    _buf.writeln(
      '2. **Leave durable progress.** Write files, create commits, post '
      'comments, or update documents. Do not exit with only verbal output.',
    );
    _buf.writeln(
      '3. **Use child tasks for parallel work.** When work can be decomposed '
      'into independent subtasks, create them for parallel execution.',
    );
    _buf.writeln(
      '4. **Mark blockers with owner + action.** If blocked, state clearly '
      'what is blocking you, who needs to act and what they need to do.',
    );
    _buf.writeln('5. **Final disposition.** When finished, report one of:');
    _buf.writeln('   - **done**: Task is complete with deliverables attached.');
    _buf.writeln(
      '   - **in_review**: Work is ready for review (specify reviewer).',
    );
    _buf.writeln(
      '   - **blocked**: Cannot proceed (state blocker + required action).',
    );
    _buf.writeln(
      '6. **Never ask a human to do what an agent could do.** Execute '
      'directly rather than delegating to the user.',
    );
    if (mode == Mode.chat) {
      _buf.writeln(
        '7. **Lean on shared memory.** Consult `search_memory` and the code '
        'index before exploring by hand and save durable facts and '
        'observations the moment you learn them — do not wait to be asked.',
      );
    } else {
      _buf.writeln(
        '7. **Consult shared memory first.** Search `search_memory` and the '
        'code index for prior decisions and relevant code before exploring '
        'files by hand.',
      );
    }
    return this;
  }

  /// Injects the step-by-step execution procedure the agent follows on each run.
  PromptBuilder executionProcedure({Mode mode = Mode.chat}) {
    _section(executionProcedureLabel);
    final steps = <String>[
      '**Check your identity** — your agent ID is shown above. Confirm who you are.',
      '**Understand why you were woken** — check the "Why you were woken" section or the CC_WAKE_REASON env var.',
      '**Consult the team brain first** — `search_memory` for prior decisions, conventions and gotchas and use `list_repos` + `search_code`/`code_symbol` to locate code before grepping or reading files by hand.',
      '**If assigned a ticket**, read it with `get_ticket`. Understand what is needed.',
    ];
    if (mode == Mode.plan) {
      steps.add(
        '**Produce the plan, do not execute.** Research read-only, then emit '
        'exactly one `$planModeOutputVerb` call carrying the plan as a typed '
        'node graph. Prose is not a deliverable here.',
      );
      steps.add(
        '**Never modify code, run commands, or create tickets in plan mode.** '
        'Those tools are not in your tool list; analyze, consult and plan.',
      );
    } else {
      // Before "do the work", not buried at the end: an agent told to do the
      // work immediately, with delegation mentioned twelve steps later as a
      // fallback for being stuck, does everything itself.
      final delegateVerb = _firstAllowed(const [
        'delegate_task',
        'delegate_ticket',
      ], mode);
      if (delegateVerb != null) {
        final options = <String>[
          'hand it to a better-suited teammate with `$delegateVerb`',
        ];
        steps.add(
          '**Decide who does the work** — check "Your team" above. You may '
          '${options.join(', or ')}. Otherwise it is yours. Deciding is not '
          'optional; doing everything yourself by default is a choice you have '
          'to be able to defend.',
        );
      }
      steps.add(
        '**Do the work immediately.** Do not stop at just a plan unless the task explicitly asks for planning.',
      );
    }
    steps.add(
      '**Leave durable progress** — comment on the ticket or update the space with what you did.',
    );
    steps.add(
      '**Record what you learned** — before finishing, save durable facts with `propose_fact` and private notes with `record_observation` and promote normative rules to a policy with `propose_policy`. Do not wait to be asked.',
    );
    // Ticket bookkeeping is only instructed where the mode actually has the
    // verbs — orchestrate has none of them and telling an agent to call a tool
    // it was never given is the same drift the capability preamble exists to
    // prevent.
    final closeVerb = _firstAllowed(const ['close_ticket'], mode);
    final failVerb = _firstAllowed(const ['fail_ticket'], mode);
    final submitVerb = _firstAllowed(const ['submit_output'], mode);
    if (closeVerb != null || submitVerb != null) {
      final buf = StringBuffer('**When complete**');
      if (closeVerb != null) {
        buf.write(', mark the ticket done with `$closeVerb`');
        if (failVerb != null) {
          buf.write(' (or `$failVerb` if it could not be done)');
        }
      }
      buf.write('.');
      if (submitVerb != null) {
        buf.write(
          ' If your run declares an output contract, submit the '
          'structured result with `$submitVerb` first.',
        );
      }
      steps.add(buf.toString());
    }
    final blockedVerb = _firstAllowed(const ['update_ticket'], mode);
    if (blockedVerb != null) {
      steps.add(
        '**If blocked**, set the ticket status to `blocked` with '
        '`$blockedVerb`, explain what is blocked and name who can unblock '
        'it.',
      );
    }
    final helpVerb = _firstAllowed(const ['ask_agent', 'consult_agent'], mode);
    if (helpVerb != null) {
      steps.add(
        '**If you get stuck mid-task**, `$helpVerb` a teammate rather '
        'than guessing or stalling.',
      );
    }
    steps.add('**Never ask a human to do what an agent could do.**');
    for (var i = 0; i < steps.length; i++) {
      _buf.writeln('${i + 1}. ${steps[i]}');
    }
    return this;
  }

  /// Injects the output-contract block when the ticket declares a schema.
  PromptBuilder outputContract(
    Map<String, dynamic>? schema, {
    OutputContractMode mode = OutputContractMode.strict,
  }) {
    if (schema != null && schema.isNotEmpty) {
      _mark(outputContractLabel);
      _buf.writeln(renderOutputContract(schema, mode: mode));
      _hasContent = true;
    }
    return this;
  }

  /// Describes why the agent was woken and the target context.
  PromptBuilder wakeContext(WakeContext? wc) {
    if (wc == null) {
      return this;
    }
    _section(wakeContextLabel);
    _buf.writeln(
      'You were dispatched for the following reason: ${wc.wakeReason.name}.',
    );
    if (wc.ticketId != null) {
      _buf.writeln('- Target ticket: ${wc.ticketId}');
    }
    if (wc.spaceId != null) {
      _buf.writeln('- Source space: ${wc.spaceId}');
    }
    if (wc.messageId != null) {
      _buf.writeln('- Triggering message: ${wc.messageId}');
    }
    if (wc.pipelineRunId != null) {
      _buf.writeln('- Pipeline run: ${wc.pipelineRunId}');
    }
    _buf.writeln('Your run ID is ${wc.runId}.');
    return this;
  }

  /// Injects @-mention context: who summoned the agent and the space roster.
  PromptBuilder mentions(MentionContext? mentionContext, String agentName) {
    if (mentionContext == null) {
      return this;
    }
    _section(summonsLabel);
    _buf.writeln(
      'You are responding because @$agentName was mentioned by '
      '${mentionContext.summonedBy} in this space.',
    );
    _buf.writeln(
      'You can mention other agents in your reply (e.g. "@name can you weigh in?") '
      'and they will be woken automatically once your turn finishes. Use the '
      'exact name as listed below — a name that does not match, or matches two '
      'agents, wakes nobody. Mentions inside code blocks or backticks are '
      'ignored, so quoting code that contains an "@" is safe.',
    );
    if (mentionContext.spaceRoster.isNotEmpty) {
      _buf.writeln('Available participants in this space:');
      for (final entry in mentionContext.spaceRoster) {
        final role = switch (entry.kind) {
          MentionRosterKind.user => 'human member',
          MentionRosterKind.agent =>
            entry.isTopLevel ? 'top-level agent' : 'subordinate agent',
        };
        _buf.writeln('  - @${entry.name} — $role');
      }
    }
    _buf.writeln(
      'Mentioning yourself does nothing. Use @-mentions sparingly and only '
      'when another agent\'s expertise is genuinely needed.',
    );
    return this;
  }

  /// Injects the mode-specific system block (chat, plan, review, etc.).
  PromptBuilder mode(Mode mode, {ModePromptContext? ctx}) {
    final block = buildModeSystemBlock(mode, ctx: ctx);
    if (block.isNotEmpty) {
      _section(modeLabel);
      _buf.writeln(block);
    }
    return this;
  }

  /// Injects relevant memory context from shared memory search results.
  PromptBuilder memoryContext(String? context) {
    if (context != null && context.isNotEmpty) {
      _mark(memoryLabel);
      _buf.writeln();
      _buf.writeln(context);
      _hasContent = true;
    }
    return this;
  }

  /// Injects recent conversation context for continuity.
  PromptBuilder conversationContext(String? context) {
    if (context != null && context.isNotEmpty) {
      _mark(conversationLabel);
      _buf.writeln();
      _buf.writeln(context);
      _hasContent = true;
    }
    return this;
  }

  /// Sets the response language based on the user's locale.
  PromptBuilder locale(AppLocale? locale) {
    if (locale == null || locale.isEnglish || !locale.hasLocalization) {
      return this;
    }
    final language = locale.displayName;
    if (language == null) {
      return this;
    }
    _section(languageLabel);
    _buf.writeln(
      'Respond to the user in $language. '
      'All your outputs, explanations, code comments and messages '
      'must be in $language.',
    );
    return this;
  }

  /// Assembles the final prompt by wrapping accumulated context around the user prompt.
  String build(String prompt) {
    if (!_hasContent && _buf.isEmpty) {
      return prompt;
    }
    final content = _buf.toString().trim();
    if (content.isEmpty) {
      return prompt;
    }
    return '<context>\n$content\n</context>\n\n$prompt';
  }

  /// Returns the accumulated prompt builder content as a plain string without wrapping.
  String buildPersistentBrief() {
    return _buf.toString().trim();
  }

  void _section(String title) {
    _mark(title);
    _buf.writeln();
    _buf.writeln('## $title');
    _hasContent = true;
  }

  /// Opens a named span at the current write position without emitting
  /// anything. Used for the blocks that carry their own headings (or none at
  /// all) so every byte of the prompt is still attributable to something.
  void _mark(String label) {
    _marks.add((label: label, offset: _buf.length));
  }

  /// The assembled prompt sliced into its named spans.
  ///
  /// Empty spans are dropped (a builder step that contributed nothing is not
  /// worth a row). Anything written before the first mark — there is nothing
  /// today, but a future step could — comes back under [preambleLabel].
  List<PromptSection> sections() {
    final text = _buf.toString();
    final out = <PromptSection>[];
    void add(String label, int start, int end) {
      final slice = text.substring(start, end).trim();
      if (slice.isNotEmpty) {
        out.add(PromptSection(label: label, text: slice));
      }
    }

    if (_marks.isEmpty) {
      add(preambleLabel, 0, text.length);
      return out;
    }
    add(preambleLabel, 0, _marks.first.offset);
    for (var i = 0; i < _marks.length; i++) {
      final end = i + 1 < _marks.length ? _marks[i + 1].offset : text.length;
      add(_marks[i].label, _marks[i].offset, end);
    }
    return out;
  }

  /// Label for content written before any section was opened.
  static const String preambleLabel = 'Preamble';

  /// Section labels are constants, not literals: the inspection breakdown
  /// (`contextSegmentKindForSection`) groups sections into segment kinds by
  /// these names, so a renamed label must fail to compile, not silently
  /// regroup.
  static const String identityLabel = 'Identity';

  /// See [identityLabel].
  static const String toolCatalogLabel = 'Tool catalogue';

  /// See [identityLabel].
  static const String resourceProtocolsLabel = 'Resource protocols';

  /// See [identityLabel].
  static const String workspaceLayoutLabel = 'Workspace layout';

  /// See [identityLabel].
  static const String agentInstructionsLabel = 'Agent instructions';

  /// See [identityLabel].
  static const String personaLabel = 'Persona';

  /// See [identityLabel].
  static const String strategicPostureLabel = 'Strategic posture';

  /// See [identityLabel].
  static const String voiceAndToneLabel = 'Voice and tone';

  /// See [identityLabel].
  static const String teamLabel = 'Your team';

  /// See [identityLabel].
  static const String skillsLabel = 'Skills';

  /// See [identityLabel].
  static const String executionContractLabel = 'Execution contract';

  /// See [identityLabel].
  static const String executionProcedureLabel = 'Execution procedure';

  /// See [identityLabel].
  static const String outputContractLabel = 'Output contract';

  /// See [identityLabel].
  static const String wakeContextLabel = 'Why you were woken';

  /// See [identityLabel].
  static const String summonsLabel = 'Summons';

  /// See [identityLabel].
  static const String modeLabel = 'Mode';

  /// See [identityLabel].
  static const String memoryLabel = 'Memory';

  /// See [identityLabel].
  static const String conversationLabel = 'Conversation';

  /// See [identityLabel].
  static const String languageLabel = 'Language';
}
