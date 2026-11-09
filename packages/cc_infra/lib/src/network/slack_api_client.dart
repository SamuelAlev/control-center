import 'dart:async';
import 'dart:convert';

import 'package:cc_infra/src/network/error_mapper.dart';
import 'package:cc_infra/src/network/network_constants.dart';
import 'package:rhttp/rhttp.dart';

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

  /// Whether the bot token aged out. A rotating (`xoxe.xoxb-`) token lives 12
  /// hours; renewing it is the token source's job, not the caller's.
  bool get isTokenExpired => error == 'token_expired';

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

  /// The app id (`A…`). `auth.test` never reports it; it is filled from
  /// `bots.info` by [SlackApiClient.identify].
  final String? appId;

  /// Returns a copy with [appId] set.
  SlackAuthIdentity withAppId(String? appId) => SlackAuthIdentity(
    teamId: teamId,
    teamName: teamName,
    userId: userId,
    botName: botName,
    botId: botId,
    appId: appId,
  );
}

/// A bot integration as `bots.info` describes it.
class SlackBotInfo {
  /// Creates a [SlackBotInfo].
  const SlackBotInfo({required this.id, this.appId, this.userId, this.name});

  /// The bot id (`B…`).
  final String id;

  /// The app the bot belongs to (`A…`).
  final String? appId;

  /// The bot's user id (`U…`).
  final String? userId;

  /// The bot's name.
  final String? name;
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
    this.deleted = false,
    this.isRestricted = false,
    this.isUltraRestricted = false,
    this.isStranger = false,
    this.emailConfirmed = false,
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

  /// Whether the account was deactivated.
  final bool deleted;

  /// A multi-channel guest.
  final bool isRestricted;

  /// A single-channel guest.
  final bool isUltraRestricted;

  /// A person from another organization, seen through a Slack Connect
  /// channel.
  final bool isStranger;

  /// Whether Slack reports [email] as confirmed by its owner.
  final bool emailConfirmed;

  /// Whether this is an active, non-bot, non-guest member of [teamId] itself —
  /// not someone visiting from another organization.
  bool isFullMemberOf(String teamId) =>
      teamId.isNotEmpty &&
      this.teamId == teamId &&
      !deleted &&
      !isBot &&
      !isRestricted &&
      !isUltraRestricted &&
      !isStranger;

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

  /// The Slack channel id the stream is posting into.
  final String channel;

  /// The streaming message's `ts` — the append/stop key.
  final String ts;
}

/// Where a [SlackApiClient] gets the bot token for a call. [renew] asks for a
/// fresh token because Slack just refused the last one as expired.
typedef SlackBotTokenSource = Future<String> Function({bool renew});

/// Whether [url] is a Slack slash-command `response_url` this server may post
/// to: `https://hooks.slack.com/` and nothing else, so a forged command cannot
/// turn the reply path into a request to an arbitrary host.
bool isSlackHooksUrl(String url) {
  final uri = Uri.tryParse(url);
  return uri != null &&
      uri.scheme == 'https' &&
      uri.host == 'hooks.slack.com' &&
      !uri.hasPort &&
      uri.userInfo.isEmpty;
}

/// Client for Slack's Web API (`https://slack.com/api/...`).
///
/// `ok: false` is the error channel (HTTP 200 for app failures →
/// [SlackApiException]). Tokens are per-call: bot default, app-level
/// (`apps.connections.open`), and config tokens passed explicitly so manifest
/// edits never ride the bot token.
class SlackApiClient {
  /// Creates a [SlackApiClient] whose default authorization is the fixed
  /// [botToken] (an own app's pasted token).
  SlackApiClient({required this._httpClient, required String botToken})
    : _tokenSource = (({bool renew = false}) async => botToken),
      _renewable = false;

  /// Creates a [SlackApiClient] whose bot token comes from the token source on
  /// every call — the short-lived rotating token a Connect grant mints. A call
  /// Slack refuses as `token_expired` is retried once with a renewed token.
  SlackApiClient.withTokenSource({
    required this._httpClient,
    required this._tokenSource,
  }) : _renewable = true;

  final RhttpClient _httpClient;
  final SlackBotTokenSource _tokenSource;
  final bool _renewable;

  /// Retries on `ratelimited`. Slack's `chat.*` tiers are per-channel and the
  /// bridge's throttle keeps well under them, so a limit here is exceptional —
  /// two retries turn a burst into a delay instead of a lost reply.
  static const int _maxRateLimitRetries = 2;

  /// Verifies a token and reports who it belongs to.
  Future<SlackAuthIdentity> authTest({String? token}) async {
    final body = await _call('auth.test', token: token, form: true);
    return SlackAuthIdentity(
      teamId: body['team_id'] as String? ?? '',
      teamName: body['team'] as String? ?? '',
      userId: body['user_id'] as String? ?? '',
      botName: body['user'] as String? ?? '',
      botId: body['bot_id'] as String?,
      appId: body['app_id'] as String?,
    );
  }

  /// [authTest] plus the app id, which only `bots.info` reports. The proof a
  /// bot token is who it claims to be, recorded when a token is saved so every
  /// later token can be checked against it.
  Future<SlackAuthIdentity> identify({String? token}) async {
    final identity = await authTest(token: token);
    final botId = identity.botId ?? '';
    if (botId.isEmpty) {
      throw const SlackApiException('auth.test', 'not_a_bot_token');
    }
    final bot = await botsInfo(botId, token: token);
    if (bot.userId != null &&
        bot.userId!.isNotEmpty &&
        bot.userId != identity.userId) {
      throw const SlackApiException('bots.info', 'bot_user_mismatch');
    }
    return identity.withAppId(bot.appId);
  }

  /// Looks a bot integration up (`bots.info`, `users:read`).
  Future<SlackBotInfo> botsInfo(String botId, {String? token}) async {
    final body = await _call(
      'bots.info',
      payload: {'bot': botId},
      token: token,
      form: true,
    );
    final bot = body['bot'];
    if (bot is! Map) {
      throw const SlackApiException('bots.info', 'missing_bot');
    }
    return SlackBotInfo(
      id: bot['id'] as String? ?? botId,
      appId: bot['app_id'] as String?,
      userId: bot['user_id'] as String?,
      name: bot['name'] as String?,
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
  /// Control Center space it drives.
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
    final body = await _call(
      'users.info',
      payload: {'user': userId},
      form: true,
    );
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
      deleted: map['deleted'] as bool? ?? false,
      isRestricted: map['is_restricted'] as bool? ?? false,
      isUltraRestricted: map['is_ultra_restricted'] as bool? ?? false,
      isStranger: map['is_stranger'] as bool? ?? false,
      emailConfirmed: map['is_email_confirmed'] as bool? ?? false,
    );
  }

  /// Re-reads one message from Slack, or null when it is gone.
  ///
  /// The Connect relay carries ids only, never text, so this is where a
  /// relayed event becomes a message: `conversations.replies` inside a thread,
  /// `conversations.history` otherwise, pinned to exactly [ts].
  Future<Map<String, dynamic>?> readMessage({
    required String channel,
    required String ts,
    String? threadTs,
  }) async {
    final inThread = threadTs != null && threadTs.isNotEmpty && threadTs != ts;
    final body = await _call(
      inThread ? 'conversations.replies' : 'conversations.history',
      payload: {
        'channel': channel,
        if (inThread) 'ts': threadTs,
        'oldest': ts,
        'latest': ts,
        'inclusive': true,
        'limit': inThread ? 2 : 1,
      },
      form: true,
    );
    final messages = body['messages'];
    if (messages is! List) {
      return null;
    }
    for (final message in messages.whereType<Map>()) {
      if (message['ts'] == ts) {
        return Map<String, dynamic>.from(message);
      }
    }
    return null;
  }

  /// Replies to a slash command through the `response_url` Slack sent with it.
  ///
  /// The robust answer path for a command: the URL is pre-authorized (no token,
  /// no scope) and works in a conversation the bot is not a member of, where
  /// `chat.postEphemeral` would fail with `channel_not_found`. Only
  /// `https://hooks.slack.com/` is ever posted to.
  Future<void> respondToCommand(
    String responseUrl, {
    required String text,
    bool visibleToChannel = false,
    List<Map<String, dynamic>>? blocks,
  }) async {
    if (!isSlackHooksUrl(responseUrl)) {
      throw const SlackApiException('response_url', 'invalid_response_url');
    }
    try {
      await _httpClient.post(
        responseUrl,
        headers: const HttpHeaders.rawMap({
          'Content-Type': 'application/json; charset=utf-8',
        }),
        body: HttpBody.json({
          'response_type': visibleToChannel ? 'in_channel' : 'ephemeral',
          'text': text,
          'blocks': ?blocks,
        }),
      );
    } on RhttpException catch (e) {
      if (e is RhttpCancelException) {
        rethrow;
      }
      throw mapHttpException(e);
    }
  }

  /// Reads a conversation's metadata (name, whether it is a DM).
  Future<Map<String, dynamic>?> conversationInfo(String channel) async {
    final body = await _call(
      'conversations.info',
      payload: {'channel': channel},
      form: true,
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

  /// POSTs [method], unwrapping Slack's `ok` envelope.
  ///
  /// [payload] travels as JSON unless [form] is set. Slack's read methods
  /// (`users.info`, `conversations.history`, …) ignore a JSON body, so they
  /// post form-encoded arguments instead.
  Future<Map<String, dynamic>> _call(
    String method, {
    Map<String, dynamic>? payload,
    String? token,
    bool form = false,
    int attempt = 0,
    bool renewed = false,
  }) async {
    final auth = token ?? await _tokenSource(renew: renewed);
    try {
      return await _post(
        method,
        payload: payload,
        auth: auth,
        form: form,
        attempt: attempt,
      );
    } on SlackApiException catch (e) {
      // A rotating bot token aged out between the source's last check and
      // this call: renew once and retry. Only the default (source) token
      // renews; an explicit token is the caller's to manage.
      if (token == null && _renewable && !renewed && e.isTokenExpired) {
        return _call(method, payload: payload, form: form, renewed: true);
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _post(
    String method, {
    required Map<String, dynamic>? payload,
    required String auth,
    required bool form,
    required int attempt,
  }) async {
    // Slack reads a JSON body only when the call authenticates through the
    // Authorization header. `tooling.tokens.rotate` deliberately sends no token
    // (the refresh token IS the credential), so posting its arguments as JSON
    // delivers no arguments at all and Slack answers "missing required field:
    // refresh_token" — a message that reads like the caller forgot to pass one.
    final unauthenticated = auth.isEmpty;
    final asForm = unauthenticated || form;
    try {
      final response = await _httpClient.post(
        '$slackApiBaseUrl/$method',
        headers: HttpHeaders.rawMap({
          if (!unauthenticated) 'Authorization': 'Bearer $auth',
          'Content-Type': asForm
              ? 'application/x-www-form-urlencoded'
              : 'application/json; charset=utf-8',
        }),
        body: asForm
            ? HttpBody.form({
                for (final entry
                    in (payload ?? const <String, dynamic>{}).entries)
                  entry.key: '${entry.value}',
              })
            : HttpBody.json(payload ?? const <String, dynamic>{}),
      );
      final data = httpJsonBody(response);
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
    } on RhttpException catch (e) {
      if (e is RhttpCancelException) {
        rethrow;
      }
      // Slack signals throttling with HTTP 429 + `Retry-After` (seconds).
      if (e is RhttpStatusCodeException && e.statusCode == 429) {
        final seconds = int.tryParse(_header(e, 'retry-after') ?? '') ?? 1;
        if (attempt < _maxRateLimitRetries) {
          await Future<void>.delayed(Duration(seconds: seconds));
          return _post(
            method,
            payload: payload,
            auth: auth,
            form: form,
            attempt: attempt + 1,
          );
        }
        throw SlackApiException(
          method,
          'ratelimited',
          retryAfter: Duration(seconds: seconds),
        );
      }
      throw mapHttpException(e);
    }
  }

  /// Case-insensitive lookup of [name] in a status failure's headers (reqwest
  /// lower-cases them; a canned test response may not).
  static String? _header(RhttpStatusCodeException e, String name) {
    final direct = e.headerMap[name];
    if (direct != null) {
      return direct;
    }
    for (final entry in e.headerMap.entries) {
      if (entry.key.toLowerCase() == name) {
        return entry.value;
      }
    }
    return null;
  }
}
