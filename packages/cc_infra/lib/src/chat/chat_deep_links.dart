/// Builds the links a chat message uses to hand a reader back to Control Center.
///
/// Chat products only accept `http(s)` in a link, so the desktop's
/// `control-center://` scheme can never be linked directly from a message. Every
/// call to action therefore points at a small page **this server** serves
/// ([pathPrefix]), which bounces the browser to the deep link — one hop, no
/// third party, and it degrades to a readable page when no app is installed.
///
/// The origin comes from the server's configured public URL, so a workspace
/// reachable only on loopback still gets a working button for the operator
/// sitting at that machine, and a tunnelled or LAN-reachable server gets one that
/// works from a phone.
class ChatDeepLinks {
  /// Creates a [ChatDeepLinks] rooted at [origin] (`https://host[:port]`, no
  /// trailing slash).
  const ChatDeepLinks({required this.origin});

  /// Derives the links from a server URL as `cc_server` advertises it
  /// (`ws://…/rpc`, `wss://…`, `http://…`), or null when it names no host.
  ///
  /// The RPC scheme is what the server publishes, and it is not linkable: `ws`
  /// becomes `http` and `wss` becomes `https`, which is the same endpoint —
  /// the WebSocket upgrade rides the HTTP listener.
  static ChatDeepLinks? fromServerUrl(String serverUrl) {
    final uri = Uri.tryParse(serverUrl.trim());
    if (uri == null || uri.host.isEmpty) {
      return null;
    }
    final scheme = switch (uri.scheme) {
      'ws' || 'http' => 'http',
      'wss' || 'https' => 'https',
      _ => '',
    };
    if (scheme.isEmpty) {
      return null;
    }
    final port = uri.hasPort ? ':${uri.port}' : '';
    return ChatDeepLinks(origin: '$scheme://${uri.host}$port');
  }

  /// Where the bounce pages live, shared with the server that serves them so the
  /// two halves cannot drift apart.
  static const String pathPrefix = '/open';

  /// Ids that may appear in a bounce URL. Everything Control Center generates is
  /// a uuid or a slug; anything else is refused rather than reflected into a
  /// page or a deep link.
  static final RegExp _safeId = RegExp(r'^[A-Za-z0-9_.\-]{1,128}$');

  /// Whether [value] is safe to place in a bounce URL and in the deep link it
  /// redirects to.
  static bool isSafeId(String value) => _safeId.hasMatch(value);

  /// The server origin every link is built on.
  final String origin;

  /// Opens a channel's transcript — the full record behind a relayed reply.
  String? channel(String workspaceId, String channelId) =>
      _url('workspaces/$workspaceId/channels/$channelId', [
        workspaceId,
        channelId,
      ]);

  /// Opens a ticket.
  String? ticket(String workspaceId, String ticketId) =>
      _url('workspaces/$workspaceId/tickets/$ticketId', [
        workspaceId,
        ticketId,
      ]);

  String? _url(String path, List<String> ids) {
    if (ids.any((id) => !isSafeId(id))) {
      return null;
    }
    return '$origin$pathPrefix/$path';
  }
}
