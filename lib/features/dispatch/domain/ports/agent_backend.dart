import 'package:control_center/features/dispatch/domain/entities/agent_process_event.dart';

/// Adapter capabilities declared by a backend. UI code gates features based
/// on these flags (e.g., hide image upload when [supportsImages] is false).
class AdapterCapabilities {
  /// Creates an [AdapterCapabilities] with the given feature flags.
  const AdapterCapabilities({
    this.supportsStreaming = true,
    this.supportsImages = false,
    this.supportsToolCalls = true,
    this.supportsResume = false,
    this.supportsCustomModel = false,
    this.promptViaStdin = true,
  });

  /// Whether the adapter streams partial output.
  final bool supportsStreaming;

  /// Whether the adapter accepts image paths.
  final bool supportsImages;

  /// Whether the adapter emits tool call / tool result events.
  final bool supportsToolCalls;

  /// Whether a previously-started session can be resumed.
  final bool supportsResume;

  /// Whether the adapter accepts a model selection.
  final bool supportsCustomModel;

  /// Whether the prompt is sent via stdin (vs command-line arg).
  final bool promptViaStdin;
}

/// Model info returned by [AgentBackend.listModels].
class AdapterModel {
  /// Creates an [AdapterModel] with the given id and optional display name.
  const AdapterModel({required this.id, this.name});

  /// Unique model identifier (e.g. 'claude-sonnet-4-20250514').
  final String id;

  /// Human-readable model name, if available.
  final String? name;
}

/// Interface for agent execution backends. Each CLI (pi, claude, codex, etc.)
/// implements this interface. A `BackendRegistry` maps CLI names to factories.
abstract interface class AgentBackend {
  /// The CLI name this backend handles (e.g. 'pi', 'claude', 'codex').
  String get cliName;

  /// Capabilities declared by this adapter.
  AdapterCapabilities get capabilities =>
      const AdapterCapabilities();

  /// Models available on this adapter. Returns null when model discovery is
  /// not supported (the adapter uses a fixed or default model).
  Future<List<AdapterModel>?> listModels() async => null;

  /// Executes the agent process and returns a stream of events.
  Stream<AgentProcessEvent> execute({
    required String prompt,
    required String workDir,
    String? modelId,
    String? systemPrompt,
    Map<String, String>? env,
    Duration? timeout,
    List<String>? imagePaths,
  });

  /// Requests the backend to stop the running process.
  Future<void> stop();
}
