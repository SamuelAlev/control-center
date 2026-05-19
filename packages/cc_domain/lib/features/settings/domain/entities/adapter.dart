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
  /// Relays an interactive CLI through an in-app PTY (e.g. Claude Code via
  /// the claude-relay). No sandbox exec.
  relay,
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
  int get hashCode =>
      Object.hash(adapter, status, version, path, capabilities);

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
/// structure via ACP or the relay, not the settings JSON-mode flag.
AdapterCapabilities? capabilitiesForAdapter(String adapterId) {
  switch (adapterId) {
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

/// Shared reasoning-level vocabularies, ported from Orca's agent specs. Each
/// model picks one (or none) via [AcpModel.thinkingLevels].
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
/// Claude Code runs through the in-app claude-relay (see
/// `features/sandboxing/data/claude_relay/`) — it NEVER uses metered
/// `claude -p`.
final List<Adapter> predefinedAdapters = [
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
    description: 'Claude Code via the in-app claude-relay '
        '(uses your Claude Code plan, never metered claude -p).',
    cliName: 'claude',
    transport: AdapterTransport.relay,
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
