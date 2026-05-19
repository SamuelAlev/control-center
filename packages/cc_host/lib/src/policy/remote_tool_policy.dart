/// Default-deny allow-list governing which MCP tools a paired **phone** may
/// invoke over the remote-control space.
///
/// The remote space shares the app-wide `McpToolDispatcher`/registry with the
/// local MCP server, which exposes ~60 tools — including ones that spend LLM
/// budget (`consult_agent`, `start_ai_review`), drive processes (`kill_agent`),
/// post under the user's GitHub identity (`publish_review_to_github`), or mutate
/// org-wide state (hiring, agent lifecycle, workspace creation). A phone is a
/// **lower-privilege principal** than a local agent: it must reach only the
/// read/observe surface the `cc_remote` PWA actually uses, plus a small set of
/// intentional, local-only write verbs.
///
/// This policy enforces that distinction. It is the security boundary that keeps
/// an approved (or leaked) pairing from becoming a full remote-control of the
/// desktop. Anything not listed here is denied — adding a tool to the phone UI
/// requires consciously adding it to [allowed] (and, if it writes, to
/// [mutating]).
///
/// Not workspace-scoped: this is a per-*principal* capability gate, orthogonal
/// to the per-call `workspace_id` scoping the session already enforces.
class RemoteToolPolicy {
  RemoteToolPolicy._();

  /// Read/observe tools the phone reads lists and detail views from. Safe to
  /// call unconfirmed; rate-limited only as a flood guard.
  static const Set<String> readOnly = {
    'list_tickets',
    'get_ticket',
    'list_agents',
    'list_spaces',
    'get_messages',
  };

  /// Mutating verbs the phone is intentionally allowed to perform. Each is a
  /// **local-only** write (no LLM spend, no spawned process, no external system
  /// such as GitHub). They are rate-limited more tightly than reads.
  static const Set<String> mutating = {
    'update_ticket',
    'assign_ticket',
    'send_message',
  };

  /// The complete set of tools a remote phone may invoke. Default-deny: a tool
  /// absent from this set is rejected before it reaches the dispatcher.
  static final Set<String> allowed = {...readOnly, ...mutating};

  // NEWSFEED TOOLS ARE DELIBERATELY ABSENT.
  //
  // `list_feeds` / `list_articles` / `get_article` / `set_article_read` /
  // `set_article_saved` used to be on this list. The newsfeed is PER-USER
  // (global tables keyed by `user_id`) and the MCP tools are bound to the
  // SERVER OWNER's identity at construction — "agents ride the owner's feed
  // list". Over the phone space that made every paired member a reader and
  // mutator of the OWNER's feeds: the `tools/call` membership gate only fires
  // for arguments carrying a `workspace_id`, and these carry none.
  //
  // Nothing is lost: `cc_remote`'s newsfeed screen reads through
  // `RemoteNewsfeedRepository` — the `newsfeed.*` repo-RPC ops, which scope by
  // `ctx.userId` (the session's own user), never the owner's.

  /// Whether [toolName] may be invoked over the remote space.
  static bool isAllowed(String toolName) => allowed.contains(toolName);

  /// Whether [toolName] is a mutating verb (tighter rate limit).
  static bool isMutating(String toolName) => mutating.contains(toolName);
}
