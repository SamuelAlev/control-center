import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Somewhere in the app an external `control-center://` link asks for.
sealed class DeepLinkTarget {
  const DeepLinkTarget();
}

/// `control-center://pr/<owner>/<repo>/<number>` — a pull request, which names a
/// repo rather than a workspace, so the workspace has to be resolved from it.
final class PrDeepLink extends DeepLinkTarget {
  /// Creates a [PrDeepLink].
  const PrDeepLink({
    required this.owner,
    required this.repo,
    required this.number,
  });

  /// GitHub owner (user or org).
  final String owner;

  /// GitHub repository name.
  final String repo;

  /// The pull request's number.
  final int number;
}

/// `control-center://workspaces/<ws>/channels/<id>` — a conversation and the
/// target of the "View in Control Center" link on a chat task card.
final class ChannelDeepLink extends DeepLinkTarget {
  /// Creates a [ChannelDeepLink].
  const ChannelDeepLink({required this.workspaceId, required this.channelId});

  /// The workspace the channel belongs to.
  final String workspaceId;

  /// The channel to open.
  final String channelId;
}

/// `control-center://workspaces/<ws>/tickets/<id>` — one ticket.
final class TicketDeepLink extends DeepLinkTarget {
  /// Creates a [TicketDeepLink].
  const TicketDeepLink({required this.workspaceId, required this.ticketId});

  /// The workspace the ticket belongs to.
  final String workspaceId;

  /// The ticket to open.
  final String ticketId;
}

/// Parses incoming custom-scheme deep links.
///
/// Everything the OS hands the app arrives as a string from outside, so parsing
/// is total: an unrecognized shape, an id with a path separator or a stray query
/// is simply not a link and nothing here ever throws.
///
/// The workspace-prefixed forms mirror the app's own routes on purpose — the
/// server's `/open/…` bounce page rewrites its path straight into this scheme, so
/// the two only have to agree on one shape.
final class DeepLinkHandler {
  DeepLinkHandler._();

  /// The scheme the OS launches the app with.
  static const String scheme = 'control-center';

  static final _prPattern = RegExp(
    r'^control-center://pr/([^/]+)/([^/]+)/(\d+)$',
  );

  static final _validSegment = RegExp(r'^[a-zA-Z0-9_.\-]+$');

  /// Resolves [rawUrl] to the destination it names, or null when it names none.
  static DeepLinkTarget? resolve(String rawUrl) {
    final uri = Uri.tryParse(rawUrl);
    if (uri == null || uri.scheme != scheme) {
      return null;
    }
    final pr = _parsePr(rawUrl);
    if (pr != null) {
      return pr;
    }
    // `control-center://workspaces/<ws>/<kind>/<id>`. The authority carries the
    // first segment in a custom-scheme URL, so `workspaces` is the host here.
    //
    // A query or fragment is refused rather than ignored: nothing Control Center
    // writes carries one, so a link that has one was assembled by somebody else.
    if (uri.host != 'workspaces' || uri.hasQuery || uri.hasFragment) {
      return null;
    }
    final segments = uri.pathSegments;
    if (segments.length != 3 || segments.any((s) => !_isSafe(s))) {
      return null;
    }
    final workspaceId = segments[0];
    final id = segments[2];
    return switch (segments[1]) {
      'channels' => ChannelDeepLink(workspaceId: workspaceId, channelId: id),
      'tickets' => TicketDeepLink(workspaceId: workspaceId, ticketId: id),
      _ => null,
    };
  }

  static PrDeepLink? _parsePr(String rawUrl) {
    final match = _prPattern.firstMatch(rawUrl);
    if (match == null) {
      return null;
    }
    final owner = match.group(1) ?? '';
    final repo = match.group(2) ?? '';
    final number = int.tryParse(match.group(3) ?? '');
    if (!_isSafe(owner) || !_isSafe(repo) || number == null) {
      return null;
    }
    return PrDeepLink(owner: owner, repo: repo, number: number);
  }

  static bool _isSafe(String segment) =>
      segment.isNotEmpty && _validSegment.hasMatch(segment);
}

/// Provides the singleton [DeepLinkHandler].
final deepLinkHandlerProvider = Provider<DeepLinkHandler>(
  (_) => DeepLinkHandler._(),
);
