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
    this.commentId,
  });

  /// GitHub owner (user or org).
  final String owner;

  /// GitHub repository name.
  final String repo;

  /// The pull request's number.
  final int number;

  /// A specific comment to reveal on arrival (its REST id), or null for the
  /// pull request as a whole.
  final int? commentId;
}

/// `control-center://workspaces/<ws>/spaces/<id>` — a conversation and the
/// target of the "View in Control Center" link on a chat task card.
final class SpaceDeepLink extends DeepLinkTarget {
  /// Creates a [SpaceDeepLink].
  const SpaceDeepLink({required this.workspaceId, required this.spaceId});

  /// The workspace the space belongs to.
  final String workspaceId;

  /// The space to open.
  final String spaceId;
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

  /// `control-center://pr/<owner>/<repo>/<n>/comments/<id>` — a comment
  /// permalink.
  ///
  /// Extends the PATH grammar rather than allowing `?comment=`: the refusal of
  /// any query or fragment is a deliberate anti-smuggling invariant on
  /// everything the OS hands us, and one exception would be the end of it.
  static final _prCommentPattern = RegExp(
    r'^control-center://pr/([^/]+)/([^/]+)/(\d+)/comments/(\d+)$',
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
      'spaces' => SpaceDeepLink(workspaceId: workspaceId, spaceId: id),
      'tickets' => TicketDeepLink(workspaceId: workspaceId, ticketId: id),
      _ => null,
    };
  }

  static PrDeepLink? _parsePr(String rawUrl) {
    // The longer form first: the bare pattern is anchored, so it cannot match
    // a URL carrying a `/comments/<id>` tail — but ordering it this way keeps
    // that a property of the code rather than of the two regexes agreeing.
    final withComment = _prCommentPattern.firstMatch(rawUrl);
    if (withComment != null) {
      final link = _prFrom(withComment);
      final commentId = int.tryParse(withComment.group(4) ?? '');
      return (link == null || commentId == null)
          ? null
          : PrDeepLink(
              owner: link.owner,
              repo: link.repo,
              number: link.number,
              commentId: commentId,
            );
    }
    final match = _prPattern.firstMatch(rawUrl);
    return match == null ? null : _prFrom(match);
  }

  static PrDeepLink? _prFrom(RegExpMatch match) {
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
