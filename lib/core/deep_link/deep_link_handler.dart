import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Parses and dispatches incoming custom-scheme deep links.
///
/// Supports the `control-center://` scheme, currently handling PR links of the
/// form `control-center://pr/<owner>/<repo>/<number>`.
final class DeepLinkHandler {
  DeepLinkHandler._();

  static final _prPattern = RegExp(
    r'^control-center://pr/([^/]+)/([^/]+)/(\d+)$',
  );

  /// Attempts to parse [rawUrl] as a recognized deep link.
  ///
  /// Returns the parsed [Uri] if the scheme and pattern match, otherwise
  /// returns `null`. Never throws.
  static Uri? parse(String rawUrl) {
    try {
      final uri = Uri.parse(rawUrl);
      if (_prPattern.hasMatch(rawUrl)) {
        return uri;
      }
      return null;
    } on Object {
      return null;
    }
  }

  static final _validSegment = RegExp(r'^[a-zA-Z0-9_.\-]+$');

  /// Extracts the owner, repo, and PR number from a recognized PR deep-link
  /// [uri].
  ///
  /// Returns `null` if the [uri] does not match the PR pattern or if any
  /// segment fails validation (empty, invalid characters, non-numeric number).
  static ({String owner, String repo, int number})? parsePr(Uri uri) {
    final match = _prPattern.firstMatch(uri.toString());
    if (match == null) {
      return null;
    }

    final owner = match.group(1);
    final repo = match.group(2);
    final number = int.tryParse(match.group(3) ?? '');

    if (owner == null ||
        owner.isEmpty ||
        !_validSegment.hasMatch(owner) ||
        repo == null ||
        repo.isEmpty ||
        !_validSegment.hasMatch(repo) ||
        number == null) {
      return null;
    }

    return (owner: owner, repo: repo, number: number);
  }
}

/// Provides the singleton [DeepLinkHandler].
final deepLinkHandlerProvider = Provider<DeepLinkHandler>((_) => DeepLinkHandler._());
