import 'dart:convert';

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
import 'package:cc_domain/features/settings/domain/entities/adapter.dart'
    show AdapterTransport;
import 'package:crypto/crypto.dart';

/// Whether a prompt span is standing — stable across the turns of a
/// conversation, so it can be sent once and cached — or belongs to the turn
/// being dispatched, so it is rebuilt (and only it is sent again) on a native
/// session resume.
///
/// The scope is a property of the span's *label*, not of the position it
/// happens to occupy in the flattened prompt, so the split can never disagree
/// with the whole: [PromptBuilder.sections] tags every span from
/// [PromptBuilder.scopeForLabel] while slicing the buffer [PromptBuilder.build] returns.
enum PromptPartScope {
  /// Identity, protocols, persona, skills, contract, mode, language.
  standing,

  /// Wake reason, mentions, memory and the injected conversation window.
  turn,
}

/// One named span of a built prompt: everything written between the point the
/// span was opened and the point the next one was.
class PromptSection {
  /// Creates a [PromptSection].
  const PromptSection({
    required this.label,
    required this.text,
    required this.scope,
  });

  /// What this span is (`Identity`, `Persona`, `Conversation`, …).
  final String label;

  /// The verbatim slice of the assembled prompt.
  final String text;

  /// Whether this span is standing context or per-turn context.
  final PromptPartScope scope;
}

/// Who authored one conversation entry, from the resuming agent's point of
/// view.
///
/// Provenance is what lets a resumed native session skip the messages IT
/// produced: those are already in its own transcript, so re-sending them would
/// duplicate the window on every ordinary turn. It is recorded here — from the
/// message's own sender id — rather than inferred by matching text.
enum PromptConversationProvenance {
  /// This agent wrote it (its own prior native output).
  self,

  /// Another participant wrote it (the user, another agent, a ticket).
  other,

  /// Harness-generated framing (a run digest, a summary block).
  system,
}

/// ONE conversation entry the agent may need to be told about.
///
/// [key] is stable and revision-bearing: a message's id plus a digest of its
/// text, so an EDIT produces a different key (and is therefore re-delivered)
/// while an untouched message keeps its key forever.
class PromptConversationEntry {
  /// Creates a [PromptConversationEntry].
  const PromptConversationEntry({
    required this.key,
    required this.text,
    required this.provenance,
    this.runId,
  });

  /// Stable revision-bearing identity of this entry.
  final String key;

  /// How the entry renders inside the conversation block.
  final String text;

  /// Who authored it.
  final PromptConversationProvenance provenance;

  /// The RUN that produced this message, from its own metadata — the lineage
  /// that proves a session produced it. Null when a message carries none.
  final String? runId;
}

/// ONE per-turn context section (wake reason, @-mention summons, retrieved
/// memory), keyed so an UNCHANGED section is not re-sent on a resume.
class PromptTurnSection {
  /// Creates a [PromptTurnSection].
  const PromptTurnSection({
    required this.key,
    required this.text,
    this.alwaysDeliver = false,
  });

  /// Stable revision-bearing identity: label + digest of the rendered text.
  final String key;

  /// The rendered section.
  final String text;

  /// Whether this section is sent on every resumed turn regardless of its key —
  /// the wake reason, which is the run's cause and must always be present.
  final bool alwaysDeliver;
}

/// What a native session has ALREADY been delivered.
///
/// [revision] empty means continuity was never established (the previous run
/// did not exit cleanly), so no delta may be built from it.
class DeliveredPromptContext {
  /// Creates a [DeliveredPromptContext].
  const DeliveredPromptContext({
    required this.revision,
    this.conversationKeys = const [],
    this.sectionKeys = const [],
    this.producedRunIds = const [],
  });

  /// [AgentPromptParts.conversationRevision] at the last delivery. Empty means
  /// continuity was never established.
  final String revision;

  /// Keys of the conversation entries delivered then.
  final List<String> conversationKeys;

  /// Keys of the per-turn SECTIONS delivered then.
  final List<String> sectionKeys;

  /// Run ids this exact native session is known to have produced.
  ///
  /// This — not the sender id — is what proves a self-authored message is
  /// already in this session's transcript.
  final List<String> producedRunIds;
}

/// The structured parts of one assembled agent prompt.
///
/// A dispatch can send the whole thing ([fullPrompt], a first turn) or only
/// the delta a resumed native session needs ([resumePrompt]). Splitting here —
/// off the same single assembly that produces [fullPrompt] — is what lets a
/// native resume keep its standing brief and conversation in the session
/// history instead of replaying a second textual copy of them.
class AgentPromptParts {
  /// Creates [AgentPromptParts].
  const AgentPromptParts({
    required this.userText,
    required this.standing,
    required this.turnContext,
    required this.conversationContext,
    required this.fullPrompt,
    required this.standingRevision,
    required this.conversationEntries,
    required this.turnSections,
  });

  /// Conversation entries in assembly order, each with a stable
  /// revision-bearing key and its provenance. [conversationRevision] is the
  /// digest of this list's keys, so an edit or a new message changes it.
  final List<PromptConversationEntry> conversationEntries;

  /// The user's message verbatim, before any context layering.
  final String userText;

  /// Standing instructions (identity, tool catalogue, protocols, workspace
  /// layout, agent instructions, persona, team, skills, execution contract and
  /// procedure, mode, language) — stable across the turns of a conversation.
  final String standing;

  /// Per-turn context that is NOT a replay of the conversation: the wake
  /// reason, @-mention summons and freshly retrieved memory. Empty when a
  /// dispatch carries none.
  final String turnContext;

  /// The injected conversation window, verbatim. This is the block a native
  /// resume must NOT replay — the session already holds the conversation.
  final String conversationContext;

  /// A revision fingerprint of the delivered conversation ENTRIES.
  ///
  /// It is the digest of [conversationEntries]' keys in order, so it changes
  /// when a message is added or edited and never when nothing moved. Empty
  /// entries yield a non-empty digest (the digest of nothing), which is why the
  /// persisted CURSOR — not this value — carries "unknown continuity" as the
  /// empty string.
  String get conversationRevision => PromptBuilder.promptRevisionOf(
    conversationEntries.map((e) => e.key).join('\u0000'),
  );

  /// Exactly what a first (non-resumed) turn sends: every span, `<context>`-
  /// wrapped around [userText]. Byte-for-byte what [PromptBuilder.build]
  /// returns for the same inputs.
  final String fullPrompt;

  /// Whether any context at all was assembled (false when a dispatch has no
  /// agent to build one for).
  bool get hasContext => standing.isNotEmpty || turnContext.isNotEmpty;

  /// The focused delta a native-resumed turn sends: the genuinely new per-turn
  /// context plus the user's message — never the standing brief and never the
  /// conversation, both of which live in the session's own history.
  ///
  /// Falls back to the bare message when there is no new context to add, so a
  /// resume never emits an empty `<context>` block.
  String get resumePrompt {
    final content = turnContext.trim();
    if (content.isEmpty) {
      return userText;
    }
    return '<context>\n$content\n</context>\n\n$userText';
  }

  /// A revision fingerprint of the standing brief.
  ///
  /// A resumed native session keeps whatever standing instructions the process
  /// that created it was given, so a CHANGE here must fork to a fresh session
  /// rather than resume under a brief the model no longer holds — this value
  /// belongs in the resume policy key.
  final String standingRevision;

  /// Per-turn sections in assembly order (wake, summons, memory), each keyed.
  final List<PromptTurnSection> turnSections;

  /// Whether the rendered conversation window is fully tracked by
  /// [conversationEntries].
  ///
  /// False only when a caller supplied a rendered window WITHOUT entries: such
  /// a window cannot be cursor-tracked, so no delta may be built from it (a
  /// synthesized whole-window entry would defeat the point of the cursor).
  bool get conversationTracked =>
      conversationEntries.isNotEmpty || conversationContext.trim().isEmpty;

  bool _selfProduced(PromptConversationEntry entry, DeliveredPromptContext d) =>
      entry.provenance == PromptConversationProvenance.self &&
      entry.runId != null &&
      d.producedRunIds.contains(entry.runId);

  /// Entries this session has NOT been delivered, in assembly order.
  ///
  /// An entry is skipped only when it is PROVEN to be in the session already:
  /// either its key was delivered before, or it is this agent's own output AND
  /// its run id is one this exact native session produced. Sender identity
  /// alone is NOT proof — the same agent can produce messages on another
  /// account/model/session while this one is parked, and those must be
  /// delivered. When the lineage is unavailable the entry is SENT (one
  /// duplicated output beats lost context).
  ///
  /// [delivered] null (or with an empty revision) means continuity was never
  /// established: this returns every entry, and [deltaPromptFor] returns null so
  /// the caller starts a FRESH session with [fullPrompt].
  List<PromptConversationEntry> undeliveredEntries(
    DeliveredPromptContext? delivered,
  ) {
    if (delivered == null || delivered.revision.isEmpty) {
      return conversationEntries;
    }
    final seen = delivered.conversationKeys.toSet();
    return [
      for (final entry in conversationEntries)
        if (!seen.contains(entry.key) && !_selfProduced(entry, delivered))
          entry,
    ];
  }

  /// Per-turn sections this session has NOT been delivered.
  ///
  /// [PromptTurnSection.alwaysDeliver] sections (the wake reason) are always
  /// included; everything else is skipped while its key was delivered.
  List<PromptTurnSection> undeliveredSections(
    DeliveredPromptContext? delivered,
  ) {
    if (delivered == null || delivered.revision.isEmpty) {
      return turnSections;
    }
    final seen = delivered.sectionKeys.toSet();
    return [
      for (final section in turnSections)
        if (section.alwaysDeliver || !seen.contains(section.key)) section,
    ];
  }

  /// The delta to send on a resumed turn, given what that session has already
  /// been delivered, or null when continuity cannot be established or the
  /// rendered window is untracked.
  ///
  /// Sends ONLY the genuinely new or edited conversation entries and the
  /// changed turn sections, plus the user's message — never the whole window.
  String? deltaPromptFor(DeliveredPromptContext? delivered) {
    if (delivered == null || delivered.revision.isEmpty) {
      return null;
    }
    if (!conversationTracked) {
      // A rendered window with no entries cannot be cursor-tracked: send the
      // full prompt in a fresh session rather than an opaque re-send.
      return null;
    }
    final blocks = <String>[
      for (final entry in undeliveredEntries(delivered)) entry.text,
      for (final section in undeliveredSections(delivered)) section.text,
    ];
    if (blocks.isEmpty) {
      return userText;
    }
    return '<context>\n${blocks.join('\n\n')}\n</context>\n\n$userText';
  }

  /// Whether anything at all must be re-delivered to a session last given
  /// [delivered].
  bool hasUndeliveredContext(DeliveredPromptContext? delivered) =>
      undeliveredEntries(delivered).isNotEmpty ||
      undeliveredSections(delivered).isNotEmpty;

  /// The keys to persist as delivered for a session given this prompt.
  List<String> deliveredConversationKeysFor() => [
    for (final e in conversationEntries) e.key,
  ];

  /// The section keys to persist as delivered.
  List<String> deliveredSectionKeysFor() => [
    for (final s in turnSections)
      if (!s.alwaysDeliver) s.key,
  ];
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
  ///
  /// The discovery sentence names the verb the *adapter* actually has
  /// [transport], because naming the wrong one sends the model after a tool it
  /// cannot call: the built-in harness owns `search_tools`, an external MCP
  /// client owns `search_tool_bm25`, and Claude Code defers and discovers tools
  /// through its OWN host tool search — there is no Control Center search verb
  /// to call there. Null keeps the built-in harness wording.
  PromptBuilder toolCatalog({AdapterTransport? transport}) {
    _section(toolCatalogLabel);
    _buf.writeln(
      'All Control Center capabilities (tickets, todos, memory, messaging, '
      'goals, work products, code graph, …) are MCP tools on the '
      '`control-center` server. Every catalogued tool is directly callable by '
      'name. Some are listed by name without their arguments until you first '
      'use one — call it anyway; its schema loads on that first call. If you '
      'are unsure which tool fits a task, ${_toolDiscoverySentence(transport)} '
      'If a tool call fails with "tool not found", search or re-list once '
      'before concluding the capability is missing.',
    );
    return this;
  }

  /// The tool-discovery sentence for [transport], naming only verbs the
  /// adapter actually exposes.
  static String _toolDiscoverySentence(AdapterTransport? transport) =>
      switch (transport) {
        AdapterTransport.claudeCli =>
          'use your own tool search — your host withholds the definitions it '
              'can defer and loads the ones you ask for on demand, returning '
              'matching names with their arguments.',
        AdapterTransport.acp =>
          'search for it by intent (`search_tool_bm25`): it returns '
              'matching names with their arguments.',
        AdapterTransport.harness || null =>
          'search for it by intent (`search_tools`): it returns matching '
              'names with their arguments.',
      };

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
    _buf.writeln(
      '7. **Ask the operator through `ask_user`, never in prose.** If a '
      'preference, missing requirement, or genuine fork would change what '
      'you build, call `ask_user` with concrete options. A chat-message '
      'question ends the turn and they have to re-prompt. Do not use it to '
      'ask permission (the approval gate handles that) or to report '
      'progress. If a sensible default exists, take it, state the '
      'assumption, and continue.',
    );
    if (mode == Mode.chat) {
      _buf.writeln(
        '8. **Lean on shared memory.** Consult `search_memory` and the code '
        'index before exploring by hand and save durable facts and '
        'observations the moment you learn them — do not wait to be asked.',
      );
    } else {
      _buf.writeln(
        '8. **Consult shared memory first.** Search `search_memory` and the '
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
    steps.add(
      '**If you need a human decision**, call `ask_user` with concrete '
      'options — never write the question as a chat message.',
    );
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
        out.add(
          PromptSection(label: label, text: slice, scope: scopeForLabel(label)),
        );
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

  /// The structured parts of this assembly around [prompt].
  ///
  /// Derived from the SAME [sections] slice of the SAME buffer [build] wraps,
  /// so [AgentPromptParts.fullPrompt] is byte-for-byte [build] and the split
  /// can never disagree with it. `standing` re-joins the standing spans in
  /// assembly order and `turnContext` the per-turn ones (with the injected
  /// conversation window pulled out separately, because a native resume must
  /// drop exactly that block and keep the rest).
  AgentPromptParts parts(String prompt) {
    final standing = StringBuffer();
    final turn = StringBuffer();
    final conversation = StringBuffer();
    final turnSections = <PromptTurnSection>[];
    for (final section in sections()) {
      if (section.scope == PromptPartScope.turn &&
          section.label != conversationLabel) {
        turnSections.add(
          PromptTurnSection(
            key:
                'turn:${section.label}#'
                '${promptRevisionOf(section.text)}',
            text: section.text,
            // The wake reason is the run's CAUSE: a resumed turn must always
            // carry it, even when the text is unchanged.
            alwaysDeliver: section.label == wakeContextLabel,
          ),
        );
      }
      if (section.scope == PromptPartScope.standing) {
        if (standing.isNotEmpty) {
          standing.write('\n\n');
        }
        standing.write(section.text);
      } else if (section.label == conversationLabel) {
        if (conversation.isNotEmpty) {
          conversation.write('\n\n');
        }
        conversation.write(section.text);
      } else {
        if (turn.isNotEmpty) {
          turn.write('\n\n');
        }
        turn.write(section.text);
      }
    }
    return AgentPromptParts(
      userText: prompt,
      standing: standing.toString(),
      turnContext: turn.toString(),
      conversationContext: conversation.toString(),
      fullPrompt: build(prompt),
      standingRevision: promptRevisionOf(standing.toString()),
      // Entries are passed through as the caller supplied them. Nothing is
      // synthesized: a rendered window with no entries is UNTRACKED, and
      // [AgentPromptParts.deltaPromptFor] refuses to build a delta from it.
      conversationEntries: _conversationEntries,
      turnSections: turnSections,
    );
  }

  /// The structured conversation entries behind [conversationContext].
  ///
  /// Set by the use case that renders them, so each entry keeps a stable
  /// identity and its provenance instead of being re-derived from text.
  List<PromptConversationEntry> _conversationEntries = const [];

  /// Supplies the per-entry conversation parts for [parts].
  PromptBuilder conversationEntries(List<PromptConversationEntry> entries) {
    _conversationEntries = entries;
    return this;
  }

  /// A stable revision fingerprint of a prompt span.
  ///
  /// Used as the resume policy's standing-brief revision and as the
  /// per-session conversation cursor: both are "has this exact text already
  /// reached the session", so a digest is enough and never needs to be secret.
  static String promptRevisionOf(String text) =>
      sha256.convert(utf8.encode(text)).toString();

  /// Whether the span [label] is standing context or per-turn context.
  ///
  /// The labels in the per-turn set are exactly the ones a concrete dispatch
  /// supplies — the wake reason, the @-mention summons, retrieved memory and
  /// the injected conversation window. Everything else is standing framing.
  static PromptPartScope scopeForLabel(String label) => switch (label) {
    wakeContextLabel ||
    summonsLabel ||
    memoryLabel ||
    conversationLabel => PromptPartScope.turn,
    _ => PromptPartScope.standing,
  };

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
