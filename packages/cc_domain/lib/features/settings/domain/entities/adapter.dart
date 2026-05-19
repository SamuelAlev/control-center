import 'package:cc_domain/features/settings/domain/entities/acp_model.dart'
    show ThinkingLevel, AcpModel;

/// How an [Adapter]'s CLI is driven by a dispatch backend.
enum AdapterTransport {
  /// Speaks the Agent Client Protocol (JSON-RPC 2.0 over stdio) — one
  /// `AcpBackend` drives every such agent with uniform structured events.
  acp,

  /// Runs a CLI that emits Control Center's NDJSON event stream (e.g.
  /// `pi --mode json`).
  structuredCli,

  /// Drives Claude Code directly via `claude -p --output-format stream-json`,
  /// spawned inside the OS sandbox like [structuredCli] but parsed as Claude's
  /// stream-json schema.
  claudeCli,

  /// Control Center's built-in agent loop — talks to an LLM provider directly
  /// and executes tools in-process, with no external CLI. The dispatch session
  /// runs the harness instead of spawning a binary.
  harness,
}

/// Adapter.
class Adapter {
  /// Creates a new [Adapter].
  const Adapter({
    required this.id,
    required this.name,
    required this.description,
    required this.cliName,
    this.transport = AdapterTransport.structuredCli,
    this.acpArgs,
  });

  /// Unique adapter identifier.
  final String id;

  /// Human-readable adapter name.
  final String name;

  /// Brief description of the adapter.
  final String description;

  /// CLI binary name used for detection (e.g. 'opencode').
  final String cliName;

  /// How the dispatch backend drives this adapter's CLI.
  final AdapterTransport transport;

  /// Extra argv appended after [cliName] to enter the adapter's ACP mode
  /// (e.g. `'acp'`, `'--acp'`). Null for non-ACP adapters.
  final String? acpArgs;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Adapter && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Result of probing the filesystem for an adapter CLI.
enum DetectionStatus {
  /// Detection is in progress.
  checking,

  /// CLI was found on the system.
  found,

  /// CLI was not found on the system.
  notFound,
}

/// Result of detecting a specific adapter CLI on the local machine.
/// What an adapter's CLI supports, surfaced in Settings → Adapters and the
/// agent doctor. Drives dispatch decisions (e.g. only append `--mode json`
/// when the adapter supports it).
class AdapterCapabilities {
  /// Creates an [AdapterCapabilities].
  const AdapterCapabilities({
    required this.supportsJsonMode,
    required this.supportsModelSelection,
  });

  /// Whether the CLI emits structured JSON events (e.g. `pi --mode json`).
  final bool supportsJsonMode;

  /// Whether the CLI accepts an explicit `--model`.
  final bool supportsModelSelection;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdapterCapabilities &&
          supportsJsonMode == other.supportsJsonMode &&
          supportsModelSelection == other.supportsModelSelection;

  @override
  int get hashCode => Object.hash(supportsJsonMode, supportsModelSelection);
}

/// A single honest limitation of a transport's mode enforcement.
///
/// Typed rather than a prose string so the presentation layer can localize each
/// one; the domain declares only *which* caveats hold. [AdapterEnforcement.
/// modeMappingNote] carries the prose that cannot be reduced to a flag.
enum AdapterEnforcementCaveat {
  /// Control Center cannot decide which tools the agent has, so a mode's
  /// read-only guarantee is not structural for this transport.
  toolSurfaceNotFiltered,

  /// No call is gated before it executes: approvals and the action guard can
  /// only see the subset that arrives as an MCP request.
  toolCallsNotIntercepted,

  /// The runner's own file/shell tools never surface to Control Center as
  /// gateable calls — the OS sandbox is the only floor under them.
  nativeToolsBypassControlCenter,

  /// Tools that execute in-process are outside every sandbox profile, so the
  /// tool surface itself is the only filesystem boundary.
  inProcessToolsUnsandboxed,

  /// Control Center cannot nudge or fail a run that never produced its
  /// deliverable, because it does not own the loop that would stop.
  completionContractUnobservable,
}

/// What Control Center can actually *enforce* for a given [AdapterTransport] —
/// as opposed to what a `Mode` claims to guarantee.
///
/// ## Why this exists
///
/// `ModeCapabilityProfile` declares that plan and review modes are read-only.
/// That declaration is only as strong as the transport underneath it, and the
/// four transports differ enormously: one of them has no permission protocol at
/// all. Nothing used to say so, so the UI presented "plan mode is read-only" as
/// a uniform fact while three of four transports could only approximate it.
/// This type is that missing declaration — an honesty matrix, surfaced to the
/// operator in Settings → Adapters and as a degraded badge next to the mode
/// selector.
///
/// ## Why it is static, not probed
///
/// These are properties of *our integration*, not of the vendor's binary. They
/// change when we write code (add a permission handler, sandbox the in-process
/// tools), never when the user upgrades their CLI. Probing would be a lie
/// dressed as a measurement. Contrast [AdapterCapabilities], which genuinely is
/// probed because it describes the binary.
///
/// ## The asymmetry worth internalizing
///
/// The harness and the CLI transports fail in *opposite* directions, and both
/// failures are real:
///
///  * the harness intercepts every call but its in-process file tools are
///    outside the sandbox, so its tool surface is the only filesystem net;
///  * a CLI runs inside the sandbox but Control Center never sees its native
///    tool calls, so the sandbox is the only filesystem net.
///
/// Neither has both belts. Declaring which one is missing is the point.
final class AdapterEnforcement {
  /// Creates an enforcement declaration.
  const AdapterEnforcement({
    required this.filtersToolSurface,
    required this.interceptsToolCalls,
    required this.observesCompletionContract,
    required this.nativeToolsInterceptable,
    required this.inProcessToolsSandboxed,
    required this.modeMappingNote,
  }) : assert(
         modeMappingNote.length > 0,
         'Every transport owes the operator one honest sentence',
       );

  /// Whether Control Center decides which tools exist for the run.
  ///
  /// True only when the tool registry is ours: the harness materializes
  /// `ModeCapabilityProfile.toToolSurfaceSpec()` into the registry it hands the
  /// model, so a filtered-out tool is not merely denied — the model never learns
  /// it exists. For every external runner we can curate only the `mcp__*` tools
  /// we serve; the runner's built-in tools are outside our reach, so a mode's
  /// read-only guarantee stops being structural.
  final bool filtersToolSurface;

  /// Whether every tool call passes a Control Center gate *before* it executes.
  ///
  /// True only for the harness, whose loop invokes the approval callback and the
  /// action guard between the model's request and the tool's execution. For an
  /// external runner the only chokepoint is the MCP dispatcher, which sees the
  /// `mcp__*` subset and nothing else — by the time a native call appears in the
  /// event stream it has already run.
  final bool interceptsToolCalls;

  /// Whether Control Center can evaluate the run's `CompletionContract` and act
  /// on it (inject the nudge, end with `LoopDoneReason.contractUnmet`).
  ///
  /// True only for the harness, because the contract is a property of the loop
  /// and the harness is the only transport whose loop we own. Note what this is
  /// *not*: for a CLI we do observe the output verb when it arrives as an MCP
  /// call, but observing a call after the fact is not holding a contract — we
  /// have no hook to nudge a turn that is about to end empty, and the runner
  /// decides when it is done.
  final bool observesCompletionContract;

  /// Whether the runner's own filesystem/shell tools are visible to Control
  /// Center as gateable calls.
  ///
  /// False for every external CLI: its Read/Write/Edit/Bash equivalents are
  /// internal to that process. Claude Code makes this concrete — it is launched
  /// with `--dangerously-skip-permissions`, so even its own prompt gate is off,
  /// and `--permission-mode plan` is the entire mode signal we get to send.
  /// Vacuously true for the harness, where there is no separate runner: every
  /// tool is one of ours.
  final bool nativeToolsInterceptable;

  /// Whether tools that execute inside the Control Center process are covered by
  /// a sandbox profile.
  ///
  /// **False for the harness, and this is the single most important entry in the
  /// matrix.** `ReadTool`/`WriteTool`/`EditTool` are Dart running in the server
  /// process; only `bash` is routed through `SandboxedHarnessCommandRunner`, so
  /// the Seatbelt/bwrap profile (including its `readOnlyMounts`) constrains
  /// spawned commands and nothing else. The tool surface and the action guard
  /// are therefore the *only* filesystem boundary a harness run has.
  ///
  /// Vacuously true for the CLI transports: they own no in-process tools, and
  /// the process itself is spawned inside the sandbox.
  ///
  /// If someone flips this to true, `adapter_enforcement_test.dart` fails —
  /// deliberately. It may only become true once the in-process file tools are
  /// themselves confined.
  final bool inProcessToolsSandboxed;

  /// One honest sentence about how a conversation `Mode` reaches this transport.
  ///
  /// English source text, like [Adapter.description]: this is authored
  /// engineering prose about our own integration, it has no `BuildContext`, and
  /// it changes whenever the integration changes. The localized surfaces are the
  /// capability labels and [caveats].
  final String modeMappingNote;

  /// Whether a read-only `Mode` is structurally guaranteed on this transport.
  ///
  /// Requires both halves: deciding which tools exist *and* gating each call. A
  /// transport with neither can only be asked nicely (the prompt) and walled in
  /// (the sandbox), which is exactly what the degraded badge reports.
  bool get enforcesModeGuarantees => filtersToolSurface && interceptsToolCalls;

  /// Whether the OS sandbox is the only thing standing between this transport
  /// and the filesystem.
  bool get sandboxIsOnlyFilesystemFloor => !nativeToolsInterceptable;

  /// The honest caveats implied by these flags, in the order an operator should
  /// read them: what is unenforced first, what is unconfined last.
  List<AdapterEnforcementCaveat> get caveats => [
    if (!filtersToolSurface) AdapterEnforcementCaveat.toolSurfaceNotFiltered,
    if (!interceptsToolCalls) AdapterEnforcementCaveat.toolCallsNotIntercepted,
    if (!nativeToolsInterceptable)
      AdapterEnforcementCaveat.nativeToolsBypassControlCenter,
    if (!observesCompletionContract)
      AdapterEnforcementCaveat.completionContractUnobservable,
    if (!inProcessToolsSandboxed)
      AdapterEnforcementCaveat.inProcessToolsUnsandboxed,
  ];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdapterEnforcement &&
          filtersToolSurface == other.filtersToolSurface &&
          interceptsToolCalls == other.interceptsToolCalls &&
          observesCompletionContract == other.observesCompletionContract &&
          nativeToolsInterceptable == other.nativeToolsInterceptable &&
          inProcessToolsSandboxed == other.inProcessToolsSandboxed &&
          modeMappingNote == other.modeMappingNote;

  @override
  int get hashCode => Object.hash(
    filtersToolSurface,
    interceptsToolCalls,
    observesCompletionContract,
    nativeToolsInterceptable,
    inProcessToolsSandboxed,
    modeMappingNote,
  );
}

/// The enforcement matrix, one entry per [AdapterTransport].
///
/// Total by construction — [enforcementForTransport] switches exhaustively, so
/// adding a transport without declaring what it enforces will not compile.
const AdapterEnforcement _harnessEnforcement = AdapterEnforcement(
  // Ours end to end: the harness builds the registry from the mode's
  // ToolSurfaceSpec, so a removed tool is invisible rather than merely denied,
  // and every call stops at the approval callback plus the action guard before
  // it runs. The loop is ours, so the completion contract can nudge a turn that
  // is about to end without a deliverable and fail it as `contractUnmet`.
  filtersToolSurface: true,
  interceptsToolCalls: true,
  observesCompletionContract: true,
  // There is no second process holding tools we cannot see.
  nativeToolsInterceptable: true,
  // The honest one. Only `bash` goes through the sandboxed command runner; the
  // Dart file tools run in-process, outside every sandbox profile.
  inProcessToolsSandboxed: false,
  modeMappingNote:
      'Full enforcement: Control Center builds the tool surface from the mode '
      'itself and gates every call before it runs. Its in-process file tools '
      'are not sandboxed, so that tool surface is the only thing keeping a '
      'read-only mode read-only — the sandbox only ever sees shell commands.',
);

const AdapterEnforcement _claudeCliEnforcement = AdapterEnforcement(
  // `--permission-mode plan` is a request to Claude, not a filter we apply: its
  // Read/Write/Edit/Bash are registered inside its own process. We curate only
  // the `mcp__*` tools we serve over `--mcp-config`.
  filtersToolSurface: false,
  // `--dangerously-skip-permissions` is on by default (non-interactive
  // `claude -p` would otherwise block forever on its own prompt), so nothing
  // gates a native call. Our approval path sees `mcp__*` requests only.
  interceptsToolCalls: false,
  // Claude's turn ends when Claude decides; we have no hook to nudge it.
  observesCompletionContract: false,
  nativeToolsInterceptable: false,
  // No in-process tools — the CLI itself is spawned inside the OS sandbox, so
  // its file access is confined even though we never see the individual calls.
  inProcessToolsSandboxed: true,
  modeMappingNote:
      'Partial: non-chat modes are passed to Claude Code as '
      '`--permission-mode plan`, which Claude honors by convention rather than '
      'by our enforcement. Control Center sees only its `mcp__*` calls; '
      "Claude's own read, write, edit, and shell tools run unseen inside the OS "
      'sandbox, which is the only floor under them.',
);

const AdapterEnforcement _structuredCliEnforcement = AdapterEnforcement(
  filtersToolSurface: false,
  interceptsToolCalls: false,
  observesCompletionContract: false,
  nativeToolsInterceptable: false,
  inProcessToolsSandboxed: true,
  modeMappingNote:
      'Prompt and sandbox only: there is no flag or protocol message that tells '
      'a structured-JSON CLI it is in a read-only mode, so the mode reaches it '
      'as prompt text. Only its `mcp__*` calls pass a Control Center gate; '
      'everything else is bounded by the OS sandbox alone.',
);

const AdapterEnforcement _acpEnforcement = AdapterEnforcement(
  filtersToolSurface: false,
  // The weakest entry in the matrix. ACP defines `session/request_permission`
  // for exactly this, and Control Center implements no handler for it — so
  // there is no negotiation at all, not even a declined one. `session/new`
  // carries cwd, model, and an MCP config path; nothing about mode or
  // permissions.
  interceptsToolCalls: false,
  observesCompletionContract: false,
  nativeToolsInterceptable: false,
  inProcessToolsSandboxed: true,
  modeMappingNote:
      'Sandbox only: Control Center negotiates no permissions over ACP — '
      '`session/new` carries the working directory, the model, and an MCP '
      'config path, and nothing about mode. The agent decides what its own '
      'tools may do; the OS sandbox is the only enforcement.',
);

/// What Control Center enforces for [transport]. Total — every transport has an
/// entry, and the switch is exhaustive so a new transport must declare one.
AdapterEnforcement enforcementForTransport(AdapterTransport transport) {
  switch (transport) {
    case AdapterTransport.harness:
      return _harnessEnforcement;
    case AdapterTransport.claudeCli:
      return _claudeCliEnforcement;
    case AdapterTransport.structuredCli:
      return _structuredCliEnforcement;
    case AdapterTransport.acp:
      return _acpEnforcement;
  }
}

/// What Control Center enforces for [adapter] — a convenience over
/// [enforcementForTransport], since enforcement is a property of the transport
/// and never of the individual CLI.
AdapterEnforcement enforcementForAdapter(Adapter adapter) =>
    enforcementForTransport(adapter.transport);

/// The result of probing an [Adapter]: its detection status, version, path,
/// and (when known) its [AdapterCapabilities].
class DetectedAdapter {
  /// Creates a new [DetectedAdapter].
  const DetectedAdapter({
    required this.adapter,
    required this.status,
    this.version,
    this.path,
    this.capabilities,
  });

  /// The adapter that was probed.
  final Adapter adapter;

  /// Detection result status.
  final DetectionStatus status;

  /// Detected CLI version string, if available.
  final String? version;

  /// Absolute path to the detected CLI binary, if found.
  final String? path;

  /// Probed capabilities, if known.
  final AdapterCapabilities? capabilities;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DetectedAdapter &&
          runtimeType == other.runtimeType &&
          adapter == other.adapter &&
          status == other.status &&
          version == other.version &&
          path == other.path &&
          capabilities == other.capabilities;

  @override
  int get hashCode => Object.hash(adapter, status, version, path, capabilities);

  /// Whether the detection has completed (found or not found).
  bool get isResolved => status != DetectionStatus.checking;

  /// Whether the adapter CLI was found on the system.
  bool get isFound => status == DetectionStatus.found;

  /// Returns a copy with optional overrides and optional clearing of nullable fields.
  DetectedAdapter copyWith({
    DetectionStatus? status,
    String? version,
    bool clearVersion = false,
    String? path,
    bool clearPath = false,
    AdapterCapabilities? capabilities,
  }) {
    return DetectedAdapter(
      adapter: adapter,
      status: status ?? this.status,
      version: clearVersion ? null : (version ?? this.version),
      path: clearPath ? null : (path ?? this.path),
      capabilities: capabilities ?? this.capabilities,
    );
  }
}

/// Static capability declarations for the built-in adapters.
///
/// `supportsModelSelection` is true for every adapter — all accept a model,
/// either via ACP `session/new` or `--model`. `supportsJsonMode` is true ONLY
/// for `pi-dev` (the `--mode json` contract); the other adapters deliver their
/// structure via ACP or Claude's `stream-json` CLI, not the settings
/// JSON-mode flag.
AdapterCapabilities? capabilitiesForAdapter(String adapterId) {
  switch (adapterId) {
    case 'cc-harness':
      return const AdapterCapabilities(
        supportsJsonMode: true,
        supportsModelSelection: true,
      );
    case 'pi-dev':
      return const AdapterCapabilities(
        supportsJsonMode: true,
        supportsModelSelection: true,
      );
    case 'claude-code':
    case 'opencode':
    case 'gemini':
    case 'goose':
    case 'cursor':
    case 'codex':
      return const AdapterCapabilities(
        supportsJsonMode: false,
        supportsModelSelection: true,
      );
    default:
      return null;
  }
}

/// Shared reasoning-level vocabularies. Each model picks one (or none) via [AcpModel.thinkingLevels].
const List<ThinkingLevel> basicThinkingLevels = [
  ThinkingLevel(id: 'low', label: 'Low'),
  ThinkingLevel(id: 'medium', label: 'Medium'),
  ThinkingLevel(id: 'high', label: 'High'),
];

/// OpenAI-style levels (gpt-5.x / codex). Adds an "Extra High" tier.
const List<ThinkingLevel> openaiThinkingLevels = [
  ThinkingLevel(id: 'low', label: 'Low'),
  ThinkingLevel(id: 'medium', label: 'Medium'),
  ThinkingLevel(id: 'high', label: 'High'),
  ThinkingLevel(id: 'xhigh', label: 'Extra High'),
];

/// Claude-style levels. Adds `xhigh` and `max`.
const List<ThinkingLevel> claudeThinkingLevels = [
  ThinkingLevel(id: 'low', label: 'Low'),
  ThinkingLevel(id: 'medium', label: 'Medium'),
  ThinkingLevel(id: 'high', label: 'High'),
  ThinkingLevel(id: 'xhigh', label: 'Extra High'),
  ThinkingLevel(id: 'max', label: 'Max'),
];

/// Built-in adapter definitions shipped with the app.
///
/// Scope: only adapters that offer an ACP mode or a structured JSON mode are
/// in the catalog — interactive/unstructured CLIs are excluded (no text-
/// passthrough backend). Each ACP adapter launches `<cliName> <acpArgs> …` and
/// speaks JSON-RPC 2.0 over stdio via the shared `AcpBackend`.
///
/// ACP invocation notes (confirmed per agent):
/// - OpenCode: `opencode acp` (native ACP subcommand).
/// - Gemini CLI: `gemini --acp`.
/// - Goose: `goose acp` (native ACP).
/// - Cursor: `cursor-agent --acp`.
/// - Codex: spoken via the `acpx` ACP bridge (the launched process is the
///   bridge, which in turn drives `codex`).
/// Claude Code is driven directly via `claude -p --output-format stream-json`
/// (see `ClaudeCliBackend` / `ClaudeStreamJsonParser`) — it uses your Claude
/// Code subscription, the same as interactive mode.
final List<Adapter> predefinedAdapters = [
  const Adapter(
    id: 'cc-harness',
    name: 'Control Center (built-in)',
    description:
        "Control Center's built-in agent loop — talks to Anthropic, OpenAI, "
        'or a local model directly and runs tools in-process (no external '
        'CLI).',
    cliName: 'cc-harness',
    transport: AdapterTransport.harness,
  ),
  const Adapter(
    id: 'pi-dev',
    name: 'Pi',
    description: 'pi.dev CLI runner inside the agent container.',
    cliName: 'pi',
    transport: AdapterTransport.structuredCli,
  ),
  const Adapter(
    id: 'claude-code',
    name: 'Claude Code',
    description:
        'Claude Code via `claude -p --output-format stream-json` '
        '(uses your Claude Code plan, same as interactive mode).',
    cliName: 'claude',
    transport: AdapterTransport.claudeCli,
  ),
  const Adapter(
    id: 'opencode',
    name: 'OpenCode',
    description: 'OpenCode CLI over the Agent Client Protocol.',
    cliName: 'opencode',
    transport: AdapterTransport.acp,
    acpArgs: 'acp',
  ),
  const Adapter(
    id: 'gemini',
    name: 'Gemini CLI',
    description: 'Gemini CLI over the Agent Client Protocol.',
    cliName: 'gemini',
    transport: AdapterTransport.acp,
    acpArgs: '--acp',
  ),
  const Adapter(
    id: 'goose',
    name: 'Goose',
    description: 'Goose over the Agent Client Protocol.',
    cliName: 'goose',
    transport: AdapterTransport.acp,
    acpArgs: 'acp',
  ),
  const Adapter(
    id: 'cursor',
    name: 'Cursor',
    description: 'Cursor agent over the Agent Client Protocol.',
    cliName: 'cursor-agent',
    transport: AdapterTransport.acp,
    acpArgs: '--acp',
  ),
  const Adapter(
    id: 'codex',
    name: 'Codex',
    description: 'Codex over the Agent Client Protocol (via the acpx bridge).',
    cliName: 'codex',
    transport: AdapterTransport.acp,
  ),
];
