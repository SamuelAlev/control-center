/// Default-deny allow-list of MCP tools a paired phone may invoke.
///
/// Phone is lower-privilege than a local agent: only the `cc_remote` read/observe
/// surface plus listed local write verbs. Unlisted tools denied. Not
/// workspace-scoped — a per-principal gate orthogonal to `workspace_id`.
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
  // `set_article_saved` used to be on this list.
  // The newsfeed is PER-USER (global tables keyed by `user_id`) and the MCP tools are bound
  // to the SERVER OWNER's identity at construction — "agents ride the owner's feed list".
  // Over the phone space that made every paired member a reader and mutator of the OWNER's
  // feeds: the `tools/call` membership gate only fires for arguments carrying a
  // `workspace_id`, and these carry none.

  /// Whether [toolName] may be invoked over the remote space.
  static bool isAllowed(String toolName) => allowed.contains(toolName);

  /// Whether [toolName] is a mutating verb (tighter rate limit).
  static bool isMutating(String toolName) => mutating.contains(toolName);
}
