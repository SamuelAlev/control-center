/// Adapter.
class Adapter {
  /// Creates a new [Adapter].
  const Adapter({
    required this.id,
    required this.name,
    required this.description,
    required this.cliName,
  });

  /// Unique adapter identifier.
  final String id;
  /// Human-readable adapter name.
  final String name;
  /// Brief description of the adapter.
  final String description;
  /// CLI binary name used for detection (e.g. 'opencode').
  final String cliName;

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

/// Static capability declarations for the built-in adapters. (Pi's are also
/// what `pi --help` would report; the relay's are fixed by the relay contract.)
AdapterCapabilities? capabilitiesForAdapter(String adapterId) {
  switch (adapterId) {
    case 'pi-dev':
      return const AdapterCapabilities(
        supportsJsonMode: true,
        supportsModelSelection: true,
      );
    case 'claude-code':
      return const AdapterCapabilities(
        supportsJsonMode: false,
        supportsModelSelection: true,
      );
    default:
      return null;
  }
}

/// Built-in adapter definitions shipped with the app.
///
/// OpenCode was removed for now while we stabilise the container-execution
/// path. Claude Code runs through the in-app claude-relay (see
/// `features/sandboxing/data/claude_relay/`) — it NEVER uses metered `claude -p`.
final List<Adapter> predefinedAdapters = [
  const Adapter(
    id: 'pi-dev',
    name: 'Pi',
    description: 'pi.dev CLI runner inside the agent container.',
    cliName: 'pi',
  ),
  const Adapter(
    id: 'claude-code',
    name: 'Claude Code',
    description: 'Claude Code via the in-app claude-relay '
        '(uses your Claude Code plan, never metered claude -p).',
    cliName: 'claude',
  ),
];

