import 'package:control_center/core/domain/entities/agent.dart';
import 'package:control_center/core/domain/value_objects/agent_role.dart';
import 'package:control_center/core/domain/value_objects/agent_skills.dart';
import 'package:control_center/core/domain/value_objects/app_locale.dart';
import 'package:control_center/core/domain/value_objects/conversation_mode.dart';
import 'package:control_center/core/domain/value_objects/wake_context.dart';
import 'package:control_center/features/dispatch/domain/prompts/mode_prompts.dart';
import 'package:control_center/features/dispatch/domain/prompts/protocol_documentation.dart';
import 'package:control_center/features/dispatch/domain/prompts/role_personas.dart';
import 'package:control_center/features/dispatch/domain/value_objects/mention_context.dart';

/// Builds the system prompt context block sent to an agent before the user prompt.
class PromptBuilder {
  final StringBuffer _buf = StringBuffer();
  bool _hasContent = false;

  /// Sets the agent identity section: id, name, workspace, and memory scoping rules.
  PromptBuilder identity(Agent agent) {
    _section('Identity');
    _buf.writeln(
      'IMPORTANT: "the user" and "you" are different entities. '
      'You are an agent. The user is a human you are chatting with.',
    );
    _buf.writeln('- agent_id: ${agent.id}');
    _buf.writeln('- agent_name: ${agent.name}');
    // The workspace is intrinsic to the agent (never null), so it is always
    // surfaced — agents must scope every workspace MCP call to it.
    _buf.writeln('- workspace_id: ${agent.workspaceId}');
    _buf.writeln('When calling memory MCP tools '
        '(update_my_notes, record_observation, propose_fact, …) pass these '
        'exact UUIDs as `agent_id` and `workspace_id`. Never substitute the '
        'agent name or role.');
    return this;
  }

  /// Injects resource protocol documentation and search discipline instructions.
  PromptBuilder resourceProtocols({ConversationMode mode = ConversationMode.chat}) {
    _buf.writeln(resourceProtocolDocumentation);
    _buf.writeln(searchDisciplineInstructions);
    // Memory-write guidance only applies where the write tools exist. Review and
    // plan modes are read-only (see ConversationModeToolGuard), so injecting
    // "save facts proactively" there would tell agents to call blocked tools.
    if (mode == ConversationMode.chat) {
      _buf.writeln(memoryManagementInstructions);
    }
    _hasContent = true;
    return this;
  }

  /// Tells the agent how its working directory is laid out: it is cwd'd at the
  /// conversation root, which holds its `AGENTS.md` + `.mcp.json`, and any
  /// repositories it can work on are isolated copy-on-write worktrees under
  /// `repos/` — each already checked out on its own branch.
  PromptBuilder workspaceLayout() {
    _section('Workspace layout');
    _buf.writeln(
      'Your current working directory is this conversation\'s root. It holds '
      'your `AGENTS.md` and `.mcp.json`.',
    );
    _buf.writeln(
      'Any repositories you can work on are checked out under `repos/` — one '
      'subdirectory per repo, each an ISOLATED worktree already on its own '
      'branch (the original repo is never touched). Make all code changes '
      'inside `repos/<name>/`, commit there, and push to open a PR. If `repos/` '
      'is empty or absent, no repository is linked to this workspace yet.',
    );
    return this;
  }

  /// Appends a custom system prompt if non-empty.
  PromptBuilder systemPrompt(String? systemPrompt) {
    if (systemPrompt != null && systemPrompt.isNotEmpty) {
      _buf.writeln(systemPrompt);
      _hasContent = true;
    }
    return this;
  }

  /// Sets the agent's persona and strategic posture based on role.
  PromptBuilder persona(String? persona, {AgentRole? role}) {
    if (persona != null && persona.isNotEmpty) {
      _section('Persona');
      _buf.writeln(persona);
    }
    if (role != null) {
      _section('Strategic posture');
      _buf.writeln(strategicPosture(role));
      _section('Voice and tone');
      _buf.writeln(voiceAndTone(role));
    }
    return this;
  }

  /// Enumerates the agent's active skills.
  PromptBuilder skills(AgentSkills skills) {
    if (skills.isNotEmpty) {
      _section('Skills');
      _buf.writeln(skills.join(', '));
    }
    return this;
  }

  /// Injects the execution contract rules that the agent must follow.
  PromptBuilder executionContract({ConversationMode mode = ConversationMode.chat}) {
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
      'what is blocking you, who needs to act, and what they need to do.',
    );
    _buf.writeln(
      '5. **Final disposition.** When finished, report one of:',
    );
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
    if (mode == ConversationMode.chat) {
      _buf.writeln(
        '7. **Lean on shared memory.** Consult `search_memory` and the code '
        'index before exploring by hand, and save durable facts and '
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
  PromptBuilder executionProcedure({ConversationMode mode = ConversationMode.chat}) {
    _section('Execution procedure');
    final steps = <String>[
      '**Check your identity** — your agent ID is shown above. Confirm who you are.',
      '**Understand why you were woken** — check the "Why you were woken" section or the CC_WAKE_REASON env var.',
      '**Consult the team brain first** — `search_memory` for prior decisions, conventions, and gotchas, and use `list_repos` + `search_code`/`code_symbol` to locate code before grepping or reading files by hand.',
      '**If assigned a ticket**, read it with `read ticket://<id>`. Understand what is needed.',
    ];
    if (mode == ConversationMode.plan) {
      steps.add('**Plan before acting.** Analyze the task, break it into steps, and write a plan file to the plans directory.');
      steps.add('**Never modify code in plan mode.** Only analyze, consult, and plan.');
    } else {
      steps.add('**Do the work immediately.** Do not stop at just a plan unless the task explicitly asks for planning.');
    }
    steps.add('**Leave durable progress** — comment on the ticket or update the channel with what you did.');
    if (mode == ConversationMode.chat) {
      steps.add('**Record what you learned** — before finishing, save durable facts with `propose_fact` and private notes with `record_observation`. Do not wait to be asked.');
    }
    steps.add('**When complete**, call `complete_ticket` with your output. Mark the ticket `done`.');
    steps.add('**If blocked**, mark the ticket `blocked`, explain what is blocked, and name who can unblock it.');
    steps.add('**If you need help**, use `consult_agent` or `suggest_tasks` to delegate sub-work.');
    steps.add('**Never ask a human to do what an agent could do.**');
    for (var i = 0; i < steps.length; i++) {
      _buf.writeln('${i + 1}. ${steps[i]}');
    }
    return this;
  }

  /// Describes why the agent was woken and the target context.
  PromptBuilder wakeContext(WakeContext? wc) {
    if (wc == null) {
      return this;
    }
    _section('Why you were woken');
    _buf.writeln('You were dispatched for the following reason: ${wc.wakeReason.name}.');
    if (wc.ticketId != null) {
      _buf.writeln('- Target ticket: ${wc.ticketId}');
    }
    if (wc.channelId != null) {
      _buf.writeln('- Source channel: ${wc.channelId}');
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

  /// Injects @-mention context: who summoned the agent and the channel roster.
  PromptBuilder mentions(MentionContext? mentionContext, String agentName) {
    if (mentionContext == null) {
      return this;
    }
    _section('Summons');
    _buf.writeln(
      'You are responding because @$agentName was mentioned by '
      '${mentionContext.summonedBy} in this channel.',
    );
    _buf.writeln(
      'You can mention other agents in your reply (e.g. "@name can you weigh in?") '
      'and they will be woken automatically.',
    );
    if (mentionContext.channelRoster.isNotEmpty) {
      _buf.writeln('Available agents in this channel:');
      for (final entry in mentionContext.channelRoster) {
        final tier = entry.isTopLevel ? 'top-level' : 'subordinate';
        _buf.writeln('  - @${entry.name} — $tier');
      }
    }
    _buf.writeln(
      'Mentioning yourself does nothing. Use @-mentions sparingly and only '
      'when another agent\'s expertise is genuinely needed.',
    );
    return this;
  }

  /// Injects the mode-specific system block (chat, plan, review, etc.).
  PromptBuilder mode(
    ConversationMode mode, {
    ModePromptContext? ctx,
  }) {
    final block = buildModeSystemBlock(mode, ctx: ctx);
    if (block.isNotEmpty) {
      _section('Mode');
      _buf.writeln(block);
    }
    return this;
  }

  /// Injects relevant memory context from shared memory search results.
  PromptBuilder memoryContext(String? context) {
    if (context != null && context.isNotEmpty) {
      _buf.writeln();
      _buf.writeln(context);
      _hasContent = true;
    }
    return this;
  }

  /// Injects recent conversation context for continuity.
  PromptBuilder conversationContext(String? context) {
    if (context != null && context.isNotEmpty) {
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
    _section('Language');
    _buf.writeln(
      'Respond to the user in $language. '
      'All your outputs, explanations, code comments, and messages '
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
    _buf.writeln();
    _buf.writeln('## $title');
    _hasContent = true;
  }
}
