import 'package:flutter_riverpod/flutter_riverpod.dart';

final class DeepLinkHandler {
  DeepLinkHandler._();

  static final _prPattern = RegExp(
    r'^control-center://pr/([^/]+)/([^/]+)/(\d+)$',
  );

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

final deepLinkHandlerProvider = Provider<DeepLinkHandler>((_) => DeepLinkHandler._());
