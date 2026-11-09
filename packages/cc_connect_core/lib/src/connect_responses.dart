import 'package:cc_connect_core/src/wire.dart';

/// The answer to `POST /v1/github/installations` (body: [SealRequest]): the
/// shared app's installations the signed-in person can see.
final class GitHubInstallationsResponse {
  /// Creates the response.
  const GitHubInstallationsResponse({
    required this.installations,
    this.updatedSeal = '',
  });

  /// Parses the body; throws [FormatException].
  factory GitHubInstallationsResponse.fromJson(Map<String, Object?> json) {
    final items = json['installations'];
    if (items is! List) {
      throw const FormatException('github installations');
    }
    final updated = json['updated_seal'];
    return GitHubInstallationsResponse(
      installations: [
        for (final item in items) ?GitHubInstallationView.tryParse(item),
      ],
      updatedSeal: updated is String ? updated : '',
    );
  }

  /// The installations, at most one per account.
  final List<GitHubInstallationView> installations;

  /// A rotated seal the server must persist, when the parent token was
  /// refreshed on the way.
  final String updatedSeal;

  /// The wire body.
  Map<String, Object?> toJson() => {
    'installations': [for (final view in installations) view.toJson()],
    if (updatedSeal.isNotEmpty) 'updated_seal': updatedSeal,
  };
}

/// A bare success from a route with nothing else to say
/// (`/v1/github/authorize_server`, `/v1/github/revoke`, `/v1/slack/revoke`).
final class ConnectAck {
  /// Creates the acknowledgement.
  const ConnectAck({this.updatedSeal = ''});

  /// Parses the body; throws [FormatException].
  factory ConnectAck.fromJson(Map<String, Object?> json) {
    if (json['ok'] != true) {
      throw const FormatException('connect ack');
    }
    final updated = json['updated_seal'];
    return ConnectAck(updatedSeal: updated is String ? updated : '');
  }

  /// A rotated seal the server must persist, when one was issued on the way.
  final String updatedSeal;

  /// The wire body.
  Map<String, Object?> toJson() => {
    'ok': true,
    if (updatedSeal.isNotEmpty) 'updated_seal': updatedSeal,
  };
}

/// Longest Klipy search query relayed.
const int klipyMaxQueryLength = 100;

/// Most GIFs one Klipy page may ask for.
const int klipyMaxPerPage = 50;

/// `POST /v1/klipy/search` and `POST /v1/klipy/trending`.
final class KlipyQuery {
  /// Creates the query.
  const KlipyQuery({
    this.query = '',
    this.page = 1,
    this.perPage = 24,
    this.locale = '',
  });

  /// Parses the body; throws [FormatException]. [requireQuery] is true for
  /// search (a non-empty `q`) and false for trending (no `q` at all).
  factory KlipyQuery.fromJson(
    Map<String, Object?> json, {
    required bool requireQuery,
  }) {
    final q = json['q'];
    final page = json['page'] ?? 1;
    final perPage = json['per_page'] ?? 24;
    final locale = json['locale'] ?? '';
    if (requireQuery) {
      if (q is! String || q.trim().isEmpty || q.length > klipyMaxQueryLength) {
        throw const FormatException('klipy query');
      }
    } else if (q != null) {
      throw const FormatException('klipy query');
    }
    if (page is! int ||
        page < 1 ||
        page > 100 ||
        perPage is! int ||
        perPage < 1 ||
        perPage > klipyMaxPerPage ||
        locale is! String ||
        (locale.isNotEmpty && !isKlipyLocale(locale))) {
      throw const FormatException('klipy query');
    }
    return KlipyQuery(
      query: requireQuery ? (q! as String).trim() : '',
      page: page,
      perPage: perPage,
      locale: locale,
    );
  }

  /// The search text (empty for trending).
  final String query;

  /// 1-based page.
  final int page;

  /// Items per page.
  final int perPage;

  /// A BCP 47-ish locale (`en`, `pt-BR`, `zh_TW`), or empty.
  final String locale;

  /// The wire body.
  Map<String, Object?> toJson() => {
    if (query.isNotEmpty) 'q': query,
    'page': page,
    'per_page': perPage,
    if (locale.isNotEmpty) 'locale': locale,
  };
}

/// Whether [value] is a locale Connect forwards to Klipy.
bool isKlipyLocale(String value) =>
    RegExp(r'^[a-z]{2,3}([_-][A-Za-z]{2,4})?$').hasMatch(value);

/// The answer to a [KlipyQuery].
final class KlipyGifsResponse {
  /// Creates the response.
  const KlipyGifsResponse({required this.gifs});

  /// Parses the body; throws [FormatException]. Items whose URLs are off
  /// Klipy's CDN are dropped, not trusted.
  factory KlipyGifsResponse.fromJson(Map<String, Object?> json) {
    final items = json['gifs'];
    if (items is! List) {
      throw const FormatException('klipy gifs');
    }
    return KlipyGifsResponse(
      gifs: [for (final item in items) ?KlipyGif.tryParse(item)],
    );
  }

  /// The GIFs.
  final List<KlipyGif> gifs;

  /// The wire body.
  Map<String, Object?> toJson() => {
    'gifs': [for (final gif in gifs) gif.toJson()],
  };
}

/// The answer to `POST /v1/events/poll`: queued Slack references for the
/// caller's bound teams, oldest first. Each wire item carries a `kind`
/// (`event` or `command`); unknown kinds are skipped.
final class ConnectEventsPollResponse {
  /// Creates the response.
  const ConnectEventsPollResponse({
    this.events = const [],
    this.commands = const [],
  });

  /// Parses the body; throws [FormatException].
  factory ConnectEventsPollResponse.fromJson(Map<String, Object?> json) {
    final items = json['events'];
    if (items is! List) {
      throw const FormatException('events poll');
    }
    final events = <SlackEventRef>[];
    final commands = <SlackCommandRef>[];
    for (final item in items) {
      if (item is! Map) {
        continue;
      }
      switch (item['kind']) {
        case 'event':
          final ref = SlackEventRef.tryParse(item);
          if (ref != null) {
            events.add(ref);
          }
        case 'command':
          final ref = SlackCommandRef.tryParse(item);
          if (ref != null) {
            commands.add(ref);
          }
      }
    }
    return ConnectEventsPollResponse(events: events, commands: commands);
  }

  /// Event references.
  final List<SlackEventRef> events;

  /// Slash command references.
  final List<SlackCommandRef> commands;
}
