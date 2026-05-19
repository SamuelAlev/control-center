import 'dart:async';
import 'dart:convert';

import 'package:cc_infra/src/network/error_mapper.dart';
import 'package:cc_infra/src/network/network_constants.dart';
import 'package:dio/dio.dart';

/// A Slack Web API call that returned HTTP 200 with `ok: false`.
///
/// Slack reports application-level failures in the body, not the status code,
/// so this is the error every method raises for a refusal (bad token, missing
/// scope, unknown channel, rate limit, streaming not available on the plan).
class SlackApiException implements Exception {
  /// Creates a [SlackApiException].
  const SlackApiException(
    this.method,
    this.error, {
    this.retryAfter,
    this.needed,
    this.details = const [],
  });

  /// The Slack API method that failed (e.g. `chat.postMessage`).
  final String method;

  /// Slack's machine-readable error code (e.g. `invalid_auth`).
  final String error;

  /// How long Slack asked us to wait, when [isRateLimited].
  final Duration? retryAfter;

  /// The scope Slack says is missing, when [isMissingScope].
  final String? needed;

  /// Per-field complaints, from either place Slack puts them: an
  /// `invalid_manifest` alone is unactionable, while "features.bot_user
  /// .display_name is too long" tells the user which box to fix.
  final List<String> details;

  /// Whether the app's credentials were rejected — the connection is broken
  /// until the owner re-pastes tokens, so retrying is pointless.
  bool get isAuthFailure => const {
    'invalid_auth',
    'not_authed',
    'account_inactive',
    'token_revoked',
    'token_expired',
    'invalid_app_id',
  }.contains(error);

  /// Whether Slack throttled the call.
  bool get isRateLimited => error == 'ratelimited' || error == 'rate_limited';

  /// Whether the app's manifest is missing a scope this call needs.
  bool get isMissingScope =>
      error == 'missing_scope' || error == 'not_allowed_token_type';

  /// Whether Slack refused *streaming* specifically — the workspace is on a
  /// plan without the Agents/streaming feature, or the feature is off. The
  /// bridge answers by posting whole replies instead.
  bool get isStreamingUnavailable => const {
    'streaming_not_supported',
    'not_supported',
    'feature_not_enabled',
    'paid_only',
    'method_not_supported_for_channel_type',
  }.contains(error);

  @override
  String toString() =>
      'SlackApiException($method): $error'
      '${needed != null ? ' (needs $needed)' : ''}'
      '${details.isEmpty ? '' : ' — ${details.join('; ')}'}';
}

/// Who a bot token belongs to, from `auth.test`.
class SlackAuthIdentity {
  /// Creates a [SlackAuthIdentity].
  const SlackAuthIdentity({
    required this.teamId,
    required this.teamName,
    required this.userId,
    required this.botName,
    this.botId,
    this.appId,
  });

  /// Slack team id (`T…`).
  final String teamId;

  /// Slack team display name.
  final String teamName;

  /// The token owner's user id — for a bot token, the bot user (`U…`).
  final String userId;

  /// The bot's display name (`auth.test`'s `user`).
  final String botName;

  /// The bot id (`B…`), present for bot tokens. Inbound messages carrying it
  /// are the bot's own and are ignored.
  final String? botId;

  /// The app id (`A…`), when Slack reports it.
  final String? appId;
}

/// A Slack member as `users.info` describes them.
class SlackUserProfile {
  /// Creates a [SlackUserProfile].
  const SlackUserProfile({
    required this.id,
    required this.name,
    this.realName,
    this.displayName,
    this.email,
    this.isBot = false,
    this.teamId,
  });

  /// Slack member id (`U…`).
  final String id;

  /// Slack handle.
  final String name;

  /// Full name, when set.
  final String? realName;

  /// Display name, when set.
  final String? displayName;

  /// Verified account email — present only with the `users:read.email` scope,
  /// and the input to email auto-linking.
  final String? email;

  /// Whether this member is a bot/app user.
  final bool isBot;

  /// The member's team id.
  final String? teamId;

  /// The best human label available for this member.
  String get label {
    for (final candidate in [displayName, realName, name]) {
      if (candidate != null && candidate.isNotEmpty) {
        return candidate;
      }
    }
    return id;
  }
}

/// A live Slack response stream opened by `chat.startStream`.
class SlackStreamHandle {
  /// Creates a [SlackStreamHandle].
  const SlackStreamHandle({required this.channel, required this.ts});

  /// The conversation the stream is posting into.
  final String channel;

  /// The streaming message's `ts` — the append/stop key.
  final String ts;
}

/// Client for Slack's Web API (`https://slack.com/api/...`).
///
/// Patterned on the GitHub/Calendar clients: one method per endpoint, every
/// transport failure mapped through [mapDioException], and cancellations
/// re-thrown. Two Slack-specific rules shape it:
///
///  * **`ok: false` is the error channel.** Slack answers HTTP 200 for
///    application failures, so every response is checked and a refusal becomes
///    a [SlackApiException] rather than silently looking like success.
///  * **Tokens are per-call, not per-client.** A connection juggles three: the
///    bot token (`xoxb-`, most calls), the app-level token (`xapp-`, only
///    `apps.connections.open`) and a short-lived app *configuration* token (the
///    manifest methods). The bot token is the default; the others are passed
///    explicitly at the call site so a manifest edit can never accidentally
///    ride the bot's authority.
///
/// Outbound HTTPS works from anywhere, including a laptop behind NAT with no
/// public endpoint — which is the whole premise of the Socket Mode bridge.
class SlackApiClient {
  /// Creates a [SlackApiClient]. [botToken] is the default authorization for
  /// every call that does not name its own token.
  SlackApiClient({required Dio dio, required String botToken})
    : _dio = dio,
      _botToken = botToken;

  final Dio _dio;
  final String _botToken;

  /// Retries on `ratelimited`. Slack's `chat.*` tiers are per-channel and the
  /// bridge's throttle keeps well under them, so a limit here is exceptional —
  /// two retries turn a burst into a delay instead of a lost reply.
  static const int _maxRateLimitRetries = 2;

  /// Verifies a token and reports who it belongs to.
  Future<SlackAuthIdentity> authTest({String? token}) async {
    final body = await _call('auth.test', token: token);
    return SlackAuthIdentity(
      teamId: body['team_id'] as String? ?? '',
      teamName: body['team'] as String? ?? '',
      userId: body['user_id'] as String? ?? '',
      botName: body['user'] as String? ?? '',
      botId: body['bot_id'] as String?,
      appId: body['app_id'] as String?,
    );
  }

  /// Opens a Socket Mode connection and returns the one-time WebSocket URL.
  ///
  /// Requires the **app-level** token (`xapp-…`) — the bot token is refused
  /// with `not_allowed_token_type`. The URL is single-use and short-lived: it
  /// is re-requested on every (re)connect.
  Future<Uri> openConnection({
    required String appToken,
    bool debugReconnects = false,
  }) async {
    final body = await _call(
      'apps.connections.open',
      token: appToken,
      // A debug connection makes Slack send `disconnect` refreshes far more
      // often, which is how the reconnect path gets exercised on purpose.
      payload: debugReconnects ? const {'debug_reconnects': true} : null,
    );
    final url = body['url'] as String?;
    if (url == null || url.isEmpty) {
      throw const SlackApiException('apps.connections.open', 'missing_url');
    }
    return Uri.parse(url);
  }

  /// Posts a message, optionally into a thread. Returns its `ts`.
  ///
  /// With [blocks], [text] stops being the body and becomes the notification
  /// fallback (what a push notification and a screen reader read), so it is
  /// still required rather than optional.
  Future<String> postMessage({
    required String channel,
    required String text,
    String? threadTs,
    bool markdown = true,
    List<Map<String, dynamic>>? blocks,
  }) async {
    final body = await _call(
      'chat.postMessage',
      payload: {
        'channel': channel,
        'text': text,
        'thread_ts': ?threadTs,
        'mrkdwn': markdown,
        'blocks': ?blocks,
      },
    );
    return body['ts'] as String? ?? '';
  }

  /// Posts a message only the invoking user sees. The bridge's refusal path —
  /// an unlinked or non-member Slack user is told how to fix it without
  /// cluttering the channel for everyone else.
  Future<void> postEphemeral({
    required String channel,
    required String user,
    required String text,
    String? threadTs,
  }) => _call(
    'chat.postEphemeral',
    payload: {
      'channel': channel,
      'user': user,
      'text': text,
      'thread_ts': ?threadTs,
    },
  );

  /// Opens a streaming assistant reply and returns its handle.
  ///
  /// Slack renders the message as a live "typing" card that grows with each
  /// [appendStream]. Needs the Agents feature (a paid Slack plan); on a plan
  /// without it the call fails and [SlackApiException.isStreamingUnavailable]
  /// is true, which is the bridge's cue to buffer and post once instead.
  ///
  /// [taskDisplayMode] selects how Thinking Steps task updates render
  /// (`timeline` for a row per step, `dense` to collapse them, `plan` for a
  /// checklist). Omitted, the stream carries text only.
  Future<SlackStreamHandle> startStream({
    required String channel,
    required String threadTs,
    String? recipientTeamId,
    String? recipientUserId,
    String? taskDisplayMode,
  }) async {
    final body = await _call(
      'chat.startStream',
      payload: {
        'channel': channel,
        'thread_ts': threadTs,
        'recipient_team_id': ?recipientTeamId,
        'recipient_user_id': ?recipientUserId,
        'task_display_mode': ?taskDisplayMode,
      },
    );
    final ts = body['ts'] as String?;
    if (ts == null || ts.isEmpty) {
      throw const SlackApiException('chat.startStream', 'missing_ts');
    }
    return SlackStreamHandle(
      channel: body['channel'] as String? ?? channel,
      ts: ts,
    );
  }

  /// Appends to a live stream: prose as [markdownText], or structured Thinking
  /// Steps content as [chunks] (`plan_update` / `task_update` / `markdown_text`).
  ///
  /// Slack refuses both on the same call (`cannot_provide_both_markdown_text_and_chunks`).
  /// A card and its answer are therefore two calls: task chunks, then a
  /// `markdown_text` chunk (or this field on a stream that never grew a card).
  Future<void> appendStream({
    required SlackStreamHandle handle,
    String? markdownText,
    List<Map<String, dynamic>>? chunks,
  }) {
    if (markdownText != null && chunks != null) {
      throw ArgumentError(
        'Slack refuses markdown_text and chunks on the same '
        'chat.appendStream call',
      );
    }
    if (markdownText == null && chunks == null) {
      throw ArgumentError('append markdown text or chunks');
    }
    return _call(
      'chat.appendStream',
      payload: {
        'channel': handle.channel,
        'ts': handle.ts,
        'markdown_text': ?markdownText,
        'chunks': ?chunks,
      },
    );
  }

  /// Closes a live stream, finalizing the message.
  Future<void> stopStream({required SlackStreamHandle handle}) => _call(
    'chat.stopStream',
    payload: {'channel': handle.channel, 'ts': handle.ts},
  );

  /// Sets the transient status line shown in an assistant thread
  /// ("thinking…"). Slack clears it when the reply lands.
  Future<void> setThreadStatus({
    required String channel,
    required String threadTs,
    required String status,
  }) => _call(
    'assistant.threads.setStatus',
    payload: {'channel_id': channel, 'thread_ts': threadTs, 'status': status},
  );

  /// Titles an assistant thread, so a Slack DM's history reads like the
  /// Control Center channel it drives.
  Future<void> setThreadTitle({
    required String channel,
    required String threadTs,
    required String title,
  }) => _call(
    'assistant.threads.setTitle',
    payload: {'channel_id': channel, 'thread_ts': threadTs, 'title': title},
  );

  /// Looks a Slack member up. [SlackUserProfile.email] is populated only when
  /// the app holds `users:read.email`.
  Future<SlackUserProfile?> userInfo(String userId) async {
    final body = await _call('users.info', payload: {'user': userId});
    final user = body['user'];
    if (user is! Map) {
      return null;
    }
    final map = Map<String, dynamic>.from(user);
    final profile = map['profile'] is Map
        ? Map<String, dynamic>.from(map['profile'] as Map)
        : const <String, dynamic>{};
    return SlackUserProfile(
      id: map['id'] as String? ?? userId,
      name: map['name'] as String? ?? '',
      realName: (map['real_name'] ?? profile['real_name']) as String?,
      displayName: profile['display_name'] as String?,
      email: profile['email'] as String?,
      isBot: map['is_bot'] as bool? ?? false,
      teamId: map['team_id'] as String?,
    );
  }

  /// Replies to a slash command through the `response_url` Slack sent with it.
  ///
  /// The robust answer path for a command: the URL is pre-authorized (no token,
  /// no scope) and works in a conversation the bot is not a member of, where
  /// `chat.postEphemeral` would fail with `channel_not_found`.
  Future<void> respondToCommand(
    String responseUrl, {
    required String text,
    bool visibleToChannel = false,
    List<Map<String, dynamic>>? blocks,
  }) async {
    try {
      await _dio.post<dynamic>(
        responseUrl,
        data: {
          'response_type': visibleToChannel ? 'in_channel' : 'ephemeral',
          'text': text,
          'blocks': ?blocks,
        },
        options: Options(
          headers: {'Content-Type': 'application/json; charset=utf-8'},
        ),
      );
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        rethrow;
      }
      throw mapDioException(e);
    }
  }

  /// Reads a conversation's metadata (name, whether it is a DM).
  Future<Map<String, dynamic>?> conversationInfo(String channel) async {
    final body = await _call(
      'conversations.info',
      payload: {'channel': channel},
    );
    final info = body['channel'];
    return info is Map ? Map<String, dynamic>.from(info) : null;
  }

  // ── App configuration (manifest) ──
  //
  // These take an app *configuration access* token, which is minted from a
  // refresh token by [rotateConfigToken] and lives 12 hours.

  /// The manifest as Slack's `manifest` argument is declared: a JSON document
  /// **encoded as a string**, not a nested object.
  ///
  /// Posting the object instead is refused before the manifest schema is ever
  /// consulted, with `invalid_arguments` and an empty `errors` array — which
  /// reads like "your manifest is wrong" and is not.
  static String _manifestArg(Map<String, dynamic> manifest) =>
      jsonEncode(manifest);

  /// Exchanges an app configuration refresh token for a fresh access token.
  ///
  /// Slack returns a NEW refresh token on every rotation and invalidates the
  /// presented one, so the caller MUST persist both halves of the result
  /// immediately — dropping the new refresh token permanently un-manages the
  /// app (only a hand-made token in Slack's UI recovers it).
  Future<({String accessToken, String refreshToken, DateTime expiresAt})>
  rotateConfigToken(String refreshToken) async {
    final body = await _call(
      'tooling.tokens.rotate',
      // Deliberately unauthenticated: the refresh token IS the credential.
      token: '',
      payload: {'refresh_token': refreshToken},
    );
    final access = body['token'] as String?;
    final refresh = body['refresh_token'] as String?;
    if (access == null || refresh == null) {
      throw const SlackApiException('tooling.tokens.rotate', 'missing_token');
    }
    final exp = body['exp'];
    return (
      accessToken: access,
      refreshToken: refresh,
      expiresAt: exp is int
          ? DateTime.fromMillisecondsSinceEpoch(exp * 1000)
          : DateTime.now().add(const Duration(hours: 12)),
    );
  }

  /// Creates a Slack app from [manifest] and returns its id.
  ///
  /// Slack also returns an `oauth_authorize_url`, deliberately not surfaced: it
  /// is the distribution flow and requires a configured `redirect_uri`, which a
  /// Socket Mode app has no public endpoint to declare. Installing happens on
  /// the app's own settings page instead.
  Future<String> createApp({
    required String configAccessToken,
    required Map<String, dynamic> manifest,
  }) async {
    final body = await _call(
      'apps.manifest.create',
      token: configAccessToken,
      payload: {'manifest': _manifestArg(manifest)},
    );
    final appId = body['app_id'] as String?;
    if (appId == null) {
      throw const SlackApiException('apps.manifest.create', 'missing_app_id');
    }
    return appId;
  }

  /// Exports an existing app's manifest, the read half of "customize the bot".
  Future<Map<String, dynamic>> exportManifest({
    required String configAccessToken,
    required String appId,
  }) async {
    final body = await _call(
      'apps.manifest.export',
      token: configAccessToken,
      payload: {'app_id': appId},
    );
    final manifest = body['manifest'];
    if (manifest is! Map) {
      throw const SlackApiException('apps.manifest.export', 'missing_manifest');
    }
    return Map<String, dynamic>.from(manifest);
  }

  /// Replaces an app's manifest. `permissionsUpdated` true means Slack changed
  /// the app's scopes, which only take effect after a reinstall.
  Future<({bool permissionsUpdated})> updateManifest({
    required String configAccessToken,
    required String appId,
    required Map<String, dynamic> manifest,
  }) async {
    final body = await _call(
      'apps.manifest.update',
      token: configAccessToken,
      payload: {'app_id': appId, 'manifest': _manifestArg(manifest)},
    );
    return (permissionsUpdated: body['permissions_updated'] as bool? ?? false);
  }

  /// Validates a manifest without applying it.
  Future<void> validateManifest({
    required String configAccessToken,
    required Map<String, dynamic> manifest,
    String? appId,
  }) => _call(
    'apps.manifest.validate',
    token: configAccessToken,
    payload: {'manifest': _manifestArg(manifest), 'app_id': ?appId},
  );

  /// Everything Slack said about *why*, from both places it says it.
  ///
  /// A manifest that fails the schema comes back with an `errors` array of
  /// `message`/`pointer` pairs; a call rejected before the schema is reached
  /// (`invalid_arguments`) explains itself only in `response_metadata.messages`.
  /// Reading one and not the other turns a fixable mistake into a bare error
  /// code, so both are collected.
  static List<String> _complaints(Map<String, dynamic> body) {
    final complaints = <String>[];
    final errors = body['errors'];
    if (errors is List) {
      for (final error in errors.whereType<Map>()) {
        final message = error['message'] as String? ?? 'invalid';
        final pointer = error['pointer'] as String?;
        complaints.add(
          pointer == null || pointer.isEmpty ? message : '$pointer: $message',
        );
      }
    }
    final metadata = body['response_metadata'];
    if (metadata is Map) {
      final messages = metadata['messages'];
      if (messages is List) {
        complaints.addAll(messages.whereType<String>());
      }
    }
    return complaints;
  }

  /// POSTs [method] with a JSON [payload], unwrapping Slack's `ok` envelope.
  Future<Map<String, dynamic>> _call(
    String method, {
    Map<String, dynamic>? payload,
    String? token,
    int attempt = 0,
  }) async {
    final auth = token ?? _botToken;
    // Slack reads a JSON body only when the call authenticates through the
    // Authorization header. `tooling.tokens.rotate` deliberately sends no token
    // (the refresh token IS the credential), so posting its arguments as JSON
    // delivers no arguments at all and Slack answers "missing required field:
    // refresh_token" — a message that reads like the caller forgot to pass one.
    final unauthenticated = auth.isEmpty;
    try {
      final response = await _dio.post<dynamic>(
        '$slackApiBaseUrl/$method',
        data: payload ?? const <String, dynamic>{},
        options: Options(
          contentType: unauthenticated
              ? Headers.formUrlEncodedContentType
              : 'application/json; charset=utf-8',
          headers: {if (!unauthenticated) 'Authorization': 'Bearer $auth'},
        ),
      );
      final data = response.data;
      if (data is! Map) {
        throw SlackApiException(method, 'malformed_response');
      }
      final body = Map<String, dynamic>.from(data);
      if (body['ok'] == true) {
        return body;
      }
      throw SlackApiException(
        method,
        body['error'] as String? ?? 'unknown_error',
        needed: body['needed'] as String?,
        details: _complaints(body),
      );
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        rethrow;
      }
      // Slack signals throttling with HTTP 429 + `Retry-After` (seconds).
      if (e.response?.statusCode == 429 && attempt < _maxRateLimitRetries) {
        final seconds =
            int.tryParse(e.response?.headers.value('retry-after') ?? '') ?? 1;
        await Future<void>.delayed(Duration(seconds: seconds));
        return _call(
          method,
          payload: payload,
          token: token,
          attempt: attempt + 1,
        );
      }
      if (e.response?.statusCode == 429) {
        final seconds =
            int.tryParse(e.response?.headers.value('retry-after') ?? '') ?? 1;
        throw SlackApiException(
          method,
          'ratelimited',
          retryAfter: Duration(seconds: seconds),
        );
      }
      throw mapDioException(e);
    }
  }
}
