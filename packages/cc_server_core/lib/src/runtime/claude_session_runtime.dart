import 'package:cc_domain/core/domain/value_objects/wake_context.dart';
import 'package:cc_infra/cc_infra.dart'
    show
        ClaudeIdleCompactor,
        ClaudeSessionSettingsStore,
        ClaudeUsageCache,
        SubscriptionUsageService,
        createHttpClient,
        kClaudeIdleCompactionPrompt;

/// Starts a run in a conversation, as `MessagingService.dispatchAgentRun` does.
typedef ClaudeRunDispatcher =
    Future<String?> Function({
      required String workspaceId,
      required String spaceId,
      required String agentId,
      required String prompt,
      required WakeContext wakeContext,
      required bool freshHistory,
      required bool readOnly,
      String? conversationId,
      String? requestedByUserId,
    });

/// What the server keeps about Claude Code sessions between runs.
class ClaudeSessionRuntime {
  /// Creates a [ClaudeSessionRuntime] over the server's data directory.
  ClaudeSessionRuntime({required String dataDir})
    : settings = ClaudeSessionSettingsStore(dataDir: dataDir) {
    compactor = ClaudeIdleCompactor(
      enabled: () => settings.read().compactIdleBeforeCacheExpires,
    );
  }

  /// The operator's compaction settings.
  final ClaudeSessionSettingsStore settings;

  /// Compacts idle sessions, once [compactThrough] has connected it.
  late final ClaudeIdleCompactor compactor;

  /// ONE cache in front of the usage reading, shared by every reader.
  ///
  /// A reading spawns the `claude` CLI, and the CLI asks a rate-limited
  /// endpoint (it returned 429s once this fan-out went per-account). Reading
  /// once per account instead of once per machine multiplies the traffic by the
  /// number of accounts, and two independent readers — the title-bar pill and
  /// the dispatch-time headroom check — would double it again. Going through
  /// one cache keeps the fan-out from throttling itself, which is the failure
  /// that reads to an operator as "no usage reported" on every account at once.
  final ClaudeUsageCache usageCache = ClaudeUsageCache(
    fetch: (configDir) => SubscriptionUsageService(
      httpClient: createHttpClient(),
    ).fetchClaudeForConfigDir(configDir),
  );

  /// Compactions go through the ordinary run path, not a side channel: one only
  /// hits the prompt cache when it resumes with the same tools and system
  /// prompt the turn ran with, and it is real spend the run log has to show.
  ///
  /// `/compact` is a command, and only a signed-in person's run carries one:
  /// the compaction continues that person's turn. A turn that ran for nobody
  /// (a bot run) is not compacted.
  void compactThrough(ClaudeRunDispatcher dispatch) {
    compactor.compact = (turn) async {
      final person = turn.requestedByUserId;
      if (person == null || person.isEmpty) {
        return null;
      }
      return dispatch(
        workspaceId: turn.workspaceId,
        spaceId: turn.spaceId,
        agentId: turn.agentId,
        prompt: kClaudeIdleCompactionPrompt,
        wakeContext: const WakeContext.userMessage(),
        // It continues the session's own history and may write its state.
        freshHistory: false,
        readOnly: false,
        conversationId: turn.conversationId,
        requestedByUserId: person,
      );
    };
  }
}
