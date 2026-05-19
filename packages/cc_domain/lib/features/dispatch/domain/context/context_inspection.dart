import 'package:cc_domain/features/dispatch/domain/prompts/prompt_builder.dart';

/// The categories a conversation's context window is made of.
///
/// Ordered the way the model actually receives them: the standing instructions
/// first, then the tool surface, then what is retrieved per turn, then the
/// conversation itself. The UI renders the stacked bar in this order, so the
/// declaration order is load-bearing.
enum ContextSegmentKind {
  /// The harness base instructions, the generated capability preamble and the
  /// standing framing sections of the `<context>` block (identity, workspace
  /// layout, execution contract, mode, language).
  systemPrompt,

  /// Operator-authored standing rules: the repo's `AGENTS.md`, the agent's own
  /// system prompt and its persona / posture.
  rules,

  /// The skills index — one line per available skill, whose `SKILL.md` body the
  /// agent reads on demand.
  skills,

  /// The built-in harness tool definitions (name + description + JSON schema).
  toolDefinitions,

  /// Bridged Control Center MCP tools and any tools bridged in from external
  /// MCP servers.
  mcpTools,

  /// The name-only index of tools that are callable but whose schemas are
  /// withheld until first use. The whole point of the two-tier surface is that
  /// this segment is ~1k tokens where its schemas would be ~20k, so it is
  /// reported separately rather than folded into [mcpTools].
  deferredTools,

  /// The subagent profiles the `task` tool can spawn.
  subagents,

  /// The memory preamble: active policies, the agent's working-memory notes and
  /// the task-relevant fact shortlist.
  memory,

  /// The live (non-compacted) conversation messages.
  conversation;

  /// Parses a wire name, or null when unknown (forward compatibility: a client
  /// on an older build drops a segment it does not know rather than failing).
  static ContextSegmentKind? fromWire(String? wire) =>
      ContextSegmentKind.values.where((k) => k.name == wire).firstOrNull;
}

/// One inspectable piece of the context: a prompt section, a tool definition, a
/// skill entry, a message.
///
/// [content] is optional so the same shape serves both the flyout (counts only)
/// and the explorer (counts plus text) — the summary request must not carry a
/// copy of every tool schema and every message across the wire.
class ContextPart {
  /// Creates a [ContextPart].
  const ContextPart({
    required this.id,
    required this.title,
    required this.tokens,
    required this.chars,
    this.subtitle,
    this.content,
  });

  /// Rebuilds a part from its wire map.
  factory ContextPart.fromJson(Map<String, dynamic> json) => ContextPart(
    id: json['id'] as String? ?? '',
    title: json['title'] as String? ?? '',
    subtitle: json['subtitle'] as String?,
    tokens: (json['tokens'] as num?)?.toInt() ?? 0,
    chars: (json['chars'] as num?)?.toInt() ?? 0,
    content: json['content'] as String?,
  );

  /// Stable id, unique within its segment. Keys the explorer's selection.
  final String id;

  /// Human-readable name (`AGENTS.md`, `bash`, `search_memory`, a message
  /// author + time).
  final String title;

  /// Optional one-line qualifier (a path, a tool's approval tier, a role).
  final String? subtitle;

  /// Estimated tokens this part occupies.
  final int tokens;

  /// Character length of [content], carried even when the content itself is
  /// elided so the summary can show weight.
  final int chars;

  /// The part's verbatim text, or null when the caller asked for counts only.
  final String? content;

  /// The wire map.
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    if (subtitle != null) 'subtitle': subtitle,
    'tokens': tokens,
    'chars': chars,
    if (content != null) 'content': content,
  };
}

/// One category of the context window, with the parts that make it up.
class ContextSegment {
  /// Creates a [ContextSegment].
  const ContextSegment({
    required this.kind,
    required this.tokens,
    required this.chars,
    this.parts = const [],
  });

  /// Rebuilds a segment from its wire map, or null when [kind] is unknown to
  /// this build.
  static ContextSegment? fromJson(Map<String, dynamic> json) {
    final kind = ContextSegmentKind.fromWire(json['kind'] as String?);
    if (kind == null) {
      return null;
    }
    return ContextSegment(
      kind: kind,
      tokens: (json['tokens'] as num?)?.toInt() ?? 0,
      chars: (json['chars'] as num?)?.toInt() ?? 0,
      parts: [
        for (final p in (json['parts'] as List?) ?? const [])
          if (p is Map<String, dynamic>) ContextPart.fromJson(p),
      ],
    );
  }

  /// Which category this is.
  final ContextSegmentKind kind;

  /// Estimated tokens for the whole segment. Authoritative: it is the sum the
  /// producer measured, not a re-derivation from [parts] (which a summary
  /// response may cap).
  final int tokens;

  /// Character length of the whole segment.
  final int chars;

  /// The individual pieces, in the order the model receives them.
  final List<ContextPart> parts;

  /// The wire map.
  Map<String, dynamic> toJson() => {
    'kind': kind.name,
    'tokens': tokens,
    'chars': chars,
    'parts': [for (final p in parts) p.toJson()],
  };

  /// A copy with [parts] replaced.
  ContextSegment withParts(List<ContextPart> parts) =>
      ContextSegment(kind: kind, tokens: tokens, chars: chars, parts: parts);
}

/// Everything the server knows about what fills a conversation's context window
/// for one agent, minus the conversation itself.
///
/// The conversation segment is deliberately NOT here: the client already holds
/// the space's messages and re-estimating them locally keeps the meter live
/// (it moves as a turn streams) without an RPC per message. The server owns
/// exactly what only it can know — the assembled prompt, what is on disk and
/// the materialized tool surface — which is why this is called the *persistent*
/// context.
class ContextInspection {
  /// Creates a [ContextInspection].
  const ContextInspection({
    required this.workspaceId,
    required this.spaceId,
    required this.agentId,
    required this.agentName,
    required this.mode,
    required this.windowTokens,
    required this.segments,
    this.modelId,
    this.workingDirectory,
    this.hasContent = false,
  });

  /// Rebuilds an inspection from its wire map.
  factory ContextInspection.fromJson(Map<String, dynamic> json) =>
      ContextInspection(
        workspaceId: json['workspace_id'] as String? ?? '',
        spaceId: json['space_id'] as String? ?? '',
        agentId: json['agent_id'] as String? ?? '',
        agentName: json['agent_name'] as String? ?? '',
        mode: json['mode'] as String? ?? 'chat',
        modelId: json['model_id'] as String?,
        workingDirectory: json['working_directory'] as String?,
        windowTokens: (json['window_tokens'] as num?)?.toInt() ?? 0,
        hasContent: json['has_content'] as bool? ?? false,
        segments: [
          for (final s in (json['segments'] as List?) ?? const [])
            if (s is Map<String, dynamic>) ?ContextSegment.fromJson(s),
        ],
      );

  /// The workspace this reading belongs to.
  final String workspaceId;

  /// The space (conversation) inspected.
  final String spaceId;

  /// The agent whose context window this is.
  final String agentId;

  /// The agent's display name, so the explorer can title itself without a
  /// second lookup.
  final String agentName;

  /// The conversation mode the next dispatch would run under — it decides the
  /// tool surface, so a breakdown is only meaningful alongside it.
  final String mode;

  /// The agent's configured model, when set.
  final String? modelId;

  /// The directory the run would be cwd'd at — the overlay whose `AGENTS.md`
  /// and skills were read. Null when nothing has been provisioned yet.
  final String? workingDirectory;

  /// The agent's context window in tokens.
  final int windowTokens;

  /// Whether [segments] carry their parts' verbatim text.
  final bool hasContent;

  /// The persistent segments, ordered by [ContextSegmentKind].
  final List<ContextSegment> segments;

  /// Tokens the persistent context occupies before a single message is added.
  int get persistentTokens {
    var total = 0;
    for (final s in segments) {
      total += s.tokens;
    }
    return total;
  }

  /// The segment for [kind], or null when this reading has none.
  ContextSegment? segmentFor(ContextSegmentKind kind) =>
      segments.where((s) => s.kind == kind).firstOrNull;

  /// The wire map.
  Map<String, dynamic> toJson() => {
    'workspace_id': workspaceId,
    'space_id': spaceId,
    'agent_id': agentId,
    'agent_name': agentName,
    'mode': mode,
    if (modelId != null) 'model_id': modelId,
    if (workingDirectory != null) 'working_directory': workingDirectory,
    'window_tokens': windowTokens,
    'has_content': hasContent,
    'segments': [for (final s in segments) s.toJson()],
  };
}

/// Groups a [PromptSection] label into its [ContextSegmentKind].
///
/// Operator-authored prose (the agent's own instructions, persona and voice)
/// reads as RULES; the skills slug list rides the skills segment alongside the
/// scanned index; the injected memory preamble is the memory segment; the
/// injected conversation window maps to conversation (an inspection payload
/// omits it — the client owns that segment from the live messages — but a
/// dispatch-time slice still attributes it honestly). Everything else is
/// standing framing, i.e. the system prompt.
ContextSegmentKind contextSegmentKindForSection(String label) =>
    switch (label) {
      PromptBuilder.agentInstructionsLabel ||
      PromptBuilder.personaLabel ||
      PromptBuilder.strategicPostureLabel ||
      PromptBuilder.voiceAndToneLabel => ContextSegmentKind.rules,
      PromptBuilder.skillsLabel => ContextSegmentKind.skills,
      PromptBuilder.memoryLabel => ContextSegmentKind.memory,
      PromptBuilder.conversationLabel => ContextSegmentKind.conversation,
      _ => ContextSegmentKind.systemPrompt,
    };
