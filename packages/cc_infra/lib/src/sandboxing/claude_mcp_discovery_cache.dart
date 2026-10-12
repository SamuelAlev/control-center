/// Opt-in policy for Claude Code's own MCP discovery cache.
///
/// `claude` defers MCP tool definitions by default (tool search): only tool
/// names and server instructions load at session start, and a remote HTTP/SSE
/// server whose tool list is already in the discovery cache connects lazily on
/// its first tool call instead of at startup. That is a real startup win, but
/// it is Claude Code's cache, keyed and invalidated on Claude Code's terms —
/// so the only safe way to use it is deliberately and always with a fresh-list
/// check against `system/init`.
///
/// This policy therefore:
///
/// * is DISABLED unless a host opts in ([disabled] is the default), so nothing
///   changes for a run that never asked;
/// * bounds staleness itself rather than trusting the CLI default: an entry
///   older than [maxStaleSeconds] or not refreshed within [ttlSeconds] is
///   dropped by the CLI and the server connects at startup, which is exactly
///   the "changing tool availability" case;
/// * lets the caller withhold trust for one run (`trustCache: false`) after the
///   launch policy — model, effort, permission mode, MCP config — changed, so a
///   stale entry can never describe a tool surface the new policy does not
///   have.
///
/// It is an env recipe, not a cache of our own: the CLI owns the storage and
/// the invalidation; we only decide whether to let it use it this run.
class ClaudeMcpDiscoveryCachePolicy {
  /// Creates a [ClaudeMcpDiscoveryCachePolicy].
  const ClaudeMcpDiscoveryCachePolicy({
    required this.enabled,
    this.ttlSeconds = 900,
    this.maxStaleSeconds = 3600,
  });

  /// The default: the CLI's own behaviour, untouched.
  static const disabled = ClaudeMcpDiscoveryCachePolicy(enabled: false);

  /// Whether the discovery cache may be used at all.
  final bool enabled;

  /// How long a cache entry is used without a background refresh. The CLI
  /// default is 900s; kept explicitly so the policy is visible.
  final int ttlSeconds;

  /// Max age before an entry is discarded and the server connects at startup.
  /// The CLI default is 14400s (4h) and it caps at 7 days; 1h is deliberately
  /// far below that — a stale tool list is worse than a slow start.
  final int maxStaleSeconds;

  /// Environment variables for one run.
  ///
  /// `MCP_DISCOVERY_CACHE=1` turns the cache on; `0` keeps it OFF even when a
  /// server-side rollout enabled it — which is what [trustCache] false
  /// produces after a policy change, forcing the CLI to connect every server
  /// at startup and learn the real list.
  ///
  /// Returns an empty map when [enabled] is false, so a run that did not opt
  /// in is byte-for-byte the pre-policy behaviour.
  Map<String, String> envFor({required bool trustCache}) {
    if (!enabled) {
      return const {};
    }
    if (!trustCache) {
      return const {'MCP_DISCOVERY_CACHE': '0'};
    }
    return {
      'MCP_DISCOVERY_CACHE': '1',
      'MCP_DISCOVERY_CACHE_TTL_S': '$ttlSeconds',
      'MCP_DISCOVERY_CACHE_MAX_STALE_S': '$maxStaleSeconds',
      // One failed refresh discards the entry rather than retrying in the
      // background forever: prefer a startup connect over an entry that may
      // describe a server that has since changed its tool list.
      'MCP_DISCOVERY_CACHE_STRIKES': '1',
    };
  }
}
