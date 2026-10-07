import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/ports/confirmation_port.dart';
import 'package:cc_domain/core/domain/ports/mode_resolver.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/features/dispatch/domain/context/context_inspection.dart';
import 'package:cc_domain/features/dispatch/domain/modes/mode_capability_profile.dart';
import 'package:cc_domain/features/dispatch/domain/prompts/capability_preamble.dart';
import 'package:cc_domain/features/dispatch/domain/usecases/build_agent_prompt_use_case.dart';
import 'package:cc_domain/features/dispatch/domain/usecases/build_conversation_context_use_case.dart';
import 'package:cc_domain/features/dispatch/domain/usecases/build_memory_context_use_case.dart';
import 'package:cc_domain/features/dispatch/domain/usecases/dispatch_agent_use_case.dart';
import 'package:cc_domain/features/mcp/domain/services/mcp_tool_registry.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/settings/domain/entities/adapter.dart';
import 'package:cc_harness/context.dart';
import 'package:cc_harness/tools.dart';
import 'package:cc_harness_runtime/cc_harness_runtime.dart';
import 'package:cc_infra/cc_infra.dart';
import 'package:path/path.dart' as p;

/// Rebuilds — headlessly, without a run — what the NEXT dispatch for a
/// (workspace, space, agent) conversation would put in the model's context
/// window, sliced into the [ContextSegmentKind] categories with per-part sizes
/// and, on request, verbatim content.
///
/// What a run receives depends on its runner ([ContextRunner]). The built-in
/// harness sends our system prompt, our tools and a replayed transcript.
/// Claude Code sends none of those: each run gets our `<context>` prompt
/// (with a capped history block) inside Claude Code's own system prompt and
/// tools, which this service cannot see and reports as one runner segment.
///
/// Every input comes from the SAME assembly code the dispatch path executes
/// (`HarnessSystemPromptBuilder`, `buildHarnessToolRegistry`,
/// `BuildAgentPromptUseCase.inspectSections`, the mode capability profile), so
/// the breakdown cannot drift from what a run actually sends. What an
/// inspection cannot know is deliberately absent: the wake/mention layers
/// (no dispatch is in flight), the co-author trailer (no requesting human),
/// the task-dependent memory recall (no user prompt) and the conversation
/// itself (the client holds the messages and appends that segment itself).
class ContextInspectionService {
  /// Creates a [ContextInspectionService].
  const ContextInspectionService({
    required this._agentRepository,
    required this._messagingRepository,
    required this._modeResolver,
    required this._filesystem,
    required this._mcpRegistry,
    required this._fileSearch,
    this._memoryContextUseCase,
    this._sandboxManager,
    this._confirmationPort,
    this._protectedPathsResolver,
    this._toolDeferralEnabled = true,
    this._conversationContextUseCase,
    this._modelWindowOf,
  });

  final AgentRepository _agentRepository;
  final MessagingRepository _messagingRepository;
  final ModeResolver _modeResolver;
  final WorkspaceFilesystemPort _filesystem;
  final McpToolRegistry _mcpRegistry;
  final FileSearchPort _fileSearch;
  final BuildMemoryContextUseCase? _memoryContextUseCase;
  final SandboxManager? _sandboxManager;
  final ConfirmationPort? _confirmationPort;
  final Future<List<String>> Function(String workspaceId)?
  _protectedPathsResolver;

  /// Mirrors the server's `--tool-deferral` setting so this reports the surface
  /// a run would actually get, not the one the default would produce.
  final bool _toolDeferralEnabled;

  /// Builds the history block a Claude Code dispatch inlines — the same use
  /// case [DispatchAgentUseCase] calls. Null leaves that segment out.
  final BuildConversationContextUseCase? _conversationContextUseCase;

  /// The context window, in tokens, of a qualified harness model
  /// (`provider/model`), or null when the catalog does not know it.
  final int? Function(String qualifiedModel)? _modelWindowOf;

  /// The harness's own fallback when the model's window is unknown
  /// (`DispatchSession._runHarness`).
  static const int _harnessDefaultWindow = 128000;

  /// Cap on one skill body read for the explorer (the scanner's autoload only
  /// ever reads frontmatter; the full body is an on-demand drill-in).
  static const int _maxSkillBodyChars = 64000;

  /// Inspects the conversation [spaceId] for [agentId] in [workspaceId].
  ///
  /// [includeContent] fills every part's `content` (the explorer); without it
  /// only sizes travel (the flyout). Throws when the agent or space does not
  /// belong to [workspaceId] — an id from another workspace resolves to
  /// nothing, never to that workspace's data.
  Future<ContextInspection> inspect({
    required String workspaceId,
    required String spaceId,
    required String agentId,
    bool includeContent = false,
  }) async {
    final agent = await _agentRepository.getById(workspaceId, agentId);
    if (agent == null) {
      throw ArgumentError('Agent $agentId not found in workspace $workspaceId');
    }
    final space = await _messagingRepository.getSpaceById(workspaceId, spaceId);
    if (space == null) {
      throw ArgumentError('Space $spaceId not found in workspace $workspaceId');
    }

    final mode = await _modeResolver.resolveForConversation(
      workspaceId,
      spaceId,
    );
    final slug = agentSlugFor(agent, agentId);

    // The working directory a dispatch would cwd into: the per-agent overlay
    // under the conversation root when it has been provisioned (dispatch
    // reuses it), else the agent's global dir — the same fallback
    // `ensureSpaceWorkspace` returns when nothing is linked.
    final agentDir = await _filesystem.agentDir(workspaceId, slug);
    // Dispatch heals the agent's skill links before it builds the prompt
    // (`AgentDispatchService`). Do the same here, or the explorer reports the
    // name list from `Agent.skills` while a run would have loaded each
    // SKILL.md. A failure leaves whatever is already linked.
    try {
      await _filesystem.syncAgentSkillLinks(
        workspaceId,
        slug,
        agent.skills.toList(),
      );
    } on Object {
      // Best-effort, matching the dispatch heal.
    }
    final spaceDir = await _filesystem.spaceDir(workspaceId, spaceId);
    final overlay = p.join(spaceDir, 'agents', slug);
    final workingDirectory = Directory(overlay).existsSync()
        ? overlay
        : agentDir;
    final runner = _runnerFor(agent);
    final harness = runner == ContextRunner.harness;

    // ── System prompt layer (base + AGENTS.md + skills index) ──
    final systemParts = await const HarnessSystemPromptBuilder().build(
      workspaceId: workspaceId,
      workingDirectory: workingDirectory,
      agentConfigDir: agentDir,
      // The same roots a dispatch passes (`DispatchSession._permittedLinkRoots`).
      // Everything the overlay offers is a symlink, so without these the
      // explorer would show an empty AGENTS.md block and no attached skills —
      // drifting from what a run actually receives, which this service exists
      // to prevent.
      permittedLinkRoots: [
        agentDir,
        p.join(p.dirname(p.dirname(agentDir)), 'skills'),
        p.join(spaceDir, 'repos'),
      ],
      // No requesting human at inspection time → no trailer line.
    );

    // ── Tool surface for the conversation's mode ──
    final profile = profileFor(mode);
    final registry = buildHarnessToolRegistry(
      mode: mode,
      // Only the schemas are read here; the network posture changes what the
      // web tools do when called, not whether they are advertised.
      networkEnabled: true,
      env: const {},
      workspaceId: workspaceId,
      agentId: agentId,
      conversationId: spaceId,
      sandboxManager: _sandboxManager,
      confirmationPort: _confirmationPort,
      fileSearch: _fileSearch,
      mcpRegistry: _mcpRegistry,
      protectedPaths: _protectedPathsResolver == null
          ? null
          : () => _protectedPathsResolver(workspaceId),
    );
    // The top-level run always gets `task` (depth 0 is below the cap); the
    // dummy spawner is never called — only the schema is read.
    registry.register(TaskTool(_InspectionSubagentSpawner()));
    // The SAME assembly a run gets, deferral included — the point of this
    // service is to answer "what would the next dispatch send?", and a second
    // computation of that answer is the drift it exists to catch.
    final partition = materializeHarnessToolSurface(
      registry: registry,
      surface: profile.toToolSurfaceSpec(),
      residency: profile.toToolResidencySpec(enabled: _toolDeferralEnabled),
    );
    final tools = partition.resident;
    final deferredTools = partition.deferred;
    final capabilityBlock = buildCapabilityPreamble(
      profile,
      materializedToolNames: [for (final t in tools) t.name],
      deferredToolNames: [for (final t in deferredTools) t.name],
    );

    // ── The <context> block's standing sections ──
    String? memoryContext;
    final memoryUseCase = _memoryContextUseCase;
    if (memoryUseCase != null) {
      try {
        // No task description at inspection time: this is the standing
        // preamble (policies + working memory), not the task-matched fact
        // shortlist a concrete dispatch would add.
        memoryContext = await memoryUseCase.execute(
          workspaceId: agent.workspaceId,
          agentId: agent.id,
        );
      } on Object {
        memoryContext = null;
      }
    }
    final teammates = await _loadTeammates(agent);
    final sections = const BuildAgentPromptUseCase().inspectSections(
      agent: agent,
      memoryContext: memoryContext,
      mode: mode,
      teammates: teammates,
    );

    // ── Slice everything into segments ──
    final buckets = <ContextSegmentKind, List<ContextPart>>{
      for (final kind in ContextSegmentKind.values) kind: [],
    };

    void add(
      ContextSegmentKind kind, {
      required String id,
      required String title,
      String? subtitle,
      required String text,
    }) {
      buckets[kind]!.add(
        ContextPart(
          id: id,
          title: title,
          subtitle: subtitle,
          tokens: TokenEstimator.instance.estimate(text),
          chars: text.length,
          content: includeContent ? text : null,
        ),
      );
    }

    // System prompt: base instructions, then the generated capability
    // preamble (joined into the same system string at dispatch). Claude Code
    // never receives either — nor our AGENTS.md read, skills index, tool
    // surface or subagent profiles: its own stand-ins are the runner segment.
    if (harness) {
        add(
        ContextSegmentKind.systemPrompt,
        id: 'system:base',
        title: 'Base instructions',
        text: systemParts.baseInstructions,
      );
      if (capabilityBlock.isNotEmpty) {
        add(
          ContextSegmentKind.systemPrompt,
          id: 'system:capability-preamble',
          title: 'Capability preamble',
          subtitle: 'mode: ${mode.name}',
          text: capabilityBlock,
        );
      }

      // Rules: the AGENTS.md hierarchy, one part per file.
      for (final file in systemParts.agentsMdFiles) {
        add(
          ContextSegmentKind.rules,
          id: 'agents-md:${file.path}',
          title: file.label,
          subtitle: file.truncated ? '${file.path} (truncated)' : file.path,
          text: file.content,
        );
      }

      // Skills: the autoloaded index line per skill; the SKILL.md body is the
      // drill-in content (read on demand, like the agent itself reads it).
      for (final skill in systemParts.skills) {
        final desc = skill.description.isEmpty ? '' : ' — ${skill.description}';
        final indexLine = '- ${skill.name}$desc (${skill.path})';
        final body = includeContent ? await _readSkillBody(skill.path) : null;
        buckets[ContextSegmentKind.skills]!.add(
          ContextPart(
            id: 'skill:${skill.name}',
            title: skill.name,
            subtitle: skill.description.isEmpty ? skill.path : skill.description,
            tokens: TokenEstimator.instance.estimate(indexLine),
            chars: indexLine.length,
            // The index line is what occupies the context; the body is what the
            // agent WOULD read on demand — shown as the part's content so the
            // explorer can drill into it without inflating the count.
            content: body == null
                ? (includeContent ? indexLine : null)
                : 'Index line (what the context holds):\n$indexLine\n\n'
                      '── SKILL.md body (read on demand, not in the context) ──\n\n$body',
          ),
        );
      }
    }

    // The <context> block sections, grouped by kind.
    for (final section in sections) {
      add(
        contextSegmentKindForSection(section.label),
        id: 'section:${section.label}',
        title: section.label,
        text: section.text,
      );
    }

    if (harness) {
      // Tool definitions, split into built-in and bridged MCP tools. The cost
      // formula mirrors the loop's own overhead accounting
      // (AgentLoopRunner._overheadTokens): name + description + JSON schema.
      for (final tool in tools) {
        final schemaText = const JsonEncoder.withIndent(
          '  ',
        ).convert(tool.inputSchema);
        final text = '${tool.description}\n\n$schemaText';
        final tokens = TokenEstimator.instance.estimate(
          '${tool.name} ${tool.description} ${jsonEncode(tool.inputSchema)}',
        );
        buckets[tool is McpToolBridge
                ? ContextSegmentKind.mcpTools
                : ContextSegmentKind.toolDefinitions]!
            .add(
              ContextPart(
                id: 'tool:${tool.name}',
                title: tool.name,
                subtitle: tool.approvalTier.name,
                tokens: tokens,
                chars: text.length,
                content: includeContent ? text : null,
              ),
            );
      }

      // Deferred tools: one index line each, which is all the request carries
      // for them. The `content` still shows the full definition so the explorer
      // can answer "what WOULD this cost if the run pulled it in?" — that is the
      // question the whole two-tier design is a bet on.
      for (final tool in deferredTools) {
        final schemaText = const JsonEncoder.withIndent(
          '  ',
        ).convert(tool.inputSchema);
        final withheld = TokenEstimator.instance.estimate(
          '${tool.name} ${tool.description} ${jsonEncode(tool.inputSchema)}',
        );
        buckets[ContextSegmentKind.deferredTools]!.add(
          ContextPart(
            id: 'deferred:${tool.name}',
            title: tool.name,
            subtitle: '${tool.approvalTier.name} · $withheld tokens withheld',
            // What the context actually holds is the NAME, in the preamble's
            // index. Charging this part the schema's tokens would report a cost
            // no request pays.
            tokens: TokenEstimator.instance.estimate(tool.name),
            chars: tool.name.length,
            content: includeContent
                ? 'Listed by name only; loads on first use.\n\n'
                      '${tool.description}\n\n$schemaText'
                : null,
          ),
        );
      }

      // Subagent profiles the `task` tool can spawn.
      for (final type in SubagentType.values) {
        final sub = subagentProfileFor(type);
        final tiers = [for (final tier in sub.allowedTiers) tier.name]..sort();
        add(
          ContextSegmentKind.subagents,
          id: 'subagent:${type.name}',
          title: type.name,
          subtitle: '≤ ${sub.maxTurns} turns · ${tiers.join('/')}',
          text: sub.systemPromptAddendum,
        );
      }
    }

    if (!harness) {
      // The history block the dispatch inlines into the `<context>` prompt —
      // not the conversation, which the run never sees beyond this.
      final history = await _claudeCodeHistory(
        workspaceId: workspaceId,
        spaceId: spaceId,
        agent: agent,
        agentId: agentId,
      );
      if (history != null && history.isNotEmpty) {
        add(
          ContextSegmentKind.conversation,
          id: 'conversation:history-block',
          title: 'Conversation history',
          subtitle:
              'Recent messages, capped at '
              '${conversationCharacterBudget(agent.contextSize)} characters',
          text: history,
        );
      }
      // Sized by the client from the run's reported reading: whatever the
      // model held beyond every part above is Claude Code's own.
      buckets[ContextSegmentKind.runner]!.add(
        ContextPart(
          id: 'runner:claude-code',
          title: 'Claude Code',
          subtitle: 'System prompt, built-in tools, MCP schemas and turn work',
          tokens: 0,
          chars: 0,
          content: includeContent
              ? 'Claude Code wraps the prompt above in its own system prompt, '
                    'its built-in tool definitions, the MCP tool schemas it '
                    'loads and any CLAUDE.md files in the working directory. '
                    "During a turn the model's tool calls and their results "
                    'join the context too. None of that is visible here; its '
                    'size is what the run reported minus every part listed '
                    'above.'
              : null,
        ),
      );
    }

    final segments = <ContextSegment>[
      for (final kind in ContextSegmentKind.values)
        if (buckets[kind]!.isNotEmpty)
          ContextSegment(
            kind: kind,
            tokens: buckets[kind]!.fold(0, (sum, part) => sum + part.tokens),
            chars: buckets[kind]!.fold(0, (sum, part) => sum + part.chars),
            parts: buckets[kind]!,
          ),
    ];

    return ContextInspection(
      workspaceId: workspaceId,
      spaceId: spaceId,
      agentId: agentId,
      agentName: agent.name,
      mode: mode.name,
      runner: runner,
      modelId: agent.modelId,
      workingDirectory: workingDirectory,
      windowTokens: _windowFor(agent, runner),
      hasContent: includeContent,
      segments: segments,
    );
  }

  /// Which runner assembles [agent]'s context.
  static ContextRunner _runnerFor(Agent agent) {
    final adapter = predefinedAdapters
        .where((a) => a.id == agent.adapterId)
        .firstOrNull;
    return adapter?.transport == AdapterTransport.claudeCli
        ? ContextRunner.claudeCode
        : ContextRunner.harness;
  }

  /// The window [agent]'s runs actually get, in tokens.
  ///
  /// Claude Code's is the agent's setting as given, else the one its model id
  /// runs with; the harness's is the model's, capped by the setting — both
  /// mirror what the run reports.
  int _windowFor(Agent agent, ContextRunner runner) {
    if (runner == ContextRunner.claudeCode) {
      return agent.contextSize ??
          AcpModelsService.claudeCodeContextWindow(agent.modelId);
    }
    final spec = (agent.modelId ?? '')
        .split('|')
        .map((s) => s.trim())
        .firstWhere((s) => s.isNotEmpty, orElse: () => '');
    final parsed = const HarnessProviderFactory().parseModel(
      spec.isEmpty ? null : spec,
    );
    final model = parsed.model;
    final modelWindow =
        (model == null
            ? null
            : _modelWindowOf?.call('${parsed.providerId}/$model')) ??
        _harnessDefaultWindow;
    final override = agent.contextSize;
    return override != null && override > 0 && override < modelWindow
        ? override
        : modelWindow;
  }

  /// The history block a Claude Code dispatch would inline right now, or null
  /// when the use case is not wired or the read fails.
  Future<String?> _claudeCodeHistory({
    required String workspaceId,
    required String spaceId,
    required Agent agent,
    required String agentId,
  }) async {
    final useCase = _conversationContextUseCase;
    if (useCase == null) {
      return null;
    }
    try {
      return await useCase.execute(
        workspaceId: workspaceId,
        spaceId: spaceId,
        selfAgentId: agentId,
        selfAgentName: agent.name,
        // No prompt yet, so no semantic recall: the block's recent window is
        // the part every dispatch carries.
        taskDescription: '',
        characterBudget: conversationCharacterBudget(agent.contextSize),
      );
    } on Object {
      return null;
    }
  }

  /// The workspace's other agents, mirroring `DispatchAgentUseCase`'s roster
  /// lookup so the "Your team" section reads as it would at dispatch.
  Future<List<TeammateBrief>> _loadTeammates(Agent agent) async {
    try {
      final agents = await _agentRepository
          .watchByWorkspace(agent.workspaceId)
          .first;
      return [
        for (final other in agents)
          if (other.id != agent.id)
            TeammateBrief(
              id: other.id,
              name: other.name,
              title: other.title,
              skills: other.skills.toList(),
              isTopLevel: other.isTopLevel,
            ),
      ];
    } on Object {
      return const [];
    }
  }

  /// Reads a skill's `SKILL.md` body for drill-in, capped. Null when missing.
  Future<String?> _readSkillBody(String path) async {
    try {
      final file = File(path);
      if (!file.existsSync()) {
        return null;
      }
      final content = await file.readAsString();
      if (content.length <= _maxSkillBodyChars) {
        return content;
      }
      return '${content.substring(0, _maxSkillBodyChars)}\n…(truncated)';
    } on Object {
      return null;
    }
  }
}

/// A spawner that never runs: the inspection only materializes the tool's
/// SCHEMA, never executes it.
class _InspectionSubagentSpawner implements SubagentSpawner {
  @override
  Future<SubagentResult> spawn(SubagentSpawnRequest request) {
    throw StateError('inspection does not spawn subagents');
  }
}
