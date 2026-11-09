import 'dart:convert';
import 'dart:io';

import 'package:cc_connect/src/context.dart';
import 'package:cc_connect/src/http_io.dart';
import 'package:cc_connect/src/provider_slack.dart';
import 'package:cc_connect/src/rate_limiter.dart';
import 'package:cc_connect_core/cc_connect_core.dart';
import 'package:crypto/crypto.dart' as crypto;

/// Largest Slack event body read (message events can carry long text and
/// blocks; the text is dropped, but the signature covers all of it).
const int slackEventMaxBytes = 256 * 1024;

/// Largest Slack slash-command body read.
const int slackCommandMaxBytes = 32 * 1024;

/// How far Slack's request timestamp may sit from the clock.
const Duration slackSignatureSkew = Duration(minutes: 5);

/// Most references one poll answer carries.
const int pollMaxItems = 100;

/// Most references queued per install.
const int queueMaxItems = 1000;

/// Event types relayed (as references). Everything else is acknowledged and
/// dropped.
const Set<String> relayedSlackEvents = {
  'app_mention',
  'message',
  'assistant_thread_started',
  'assistant_thread_context_changed',
};

/// Verifies Slack's v0 request signature: `v0=` + hex HMAC-SHA256 over
/// `v0:<timestamp>:<raw body>` under the current or previous signing secret,
/// with the timestamp within [slackSignatureSkew]. Runs before the body is
/// parsed.
bool verifySlackSignature({
  required List<String> secrets,
  required String? timestamp,
  required String? signature,
  required List<int> body,
  required DateTime now,
}) {
  if (timestamp == null || signature == null || secrets.isEmpty) {
    return false;
  }
  final ts = int.tryParse(timestamp);
  if (ts == null ||
      (ts - now.millisecondsSinceEpoch ~/ 1000).abs() >
          slackSignatureSkew.inSeconds) {
    return false;
  }
  final base = [...utf8.encode('v0:$timestamp:'), ...body];
  var ok = false;
  for (final secret in secrets) {
    final mac = crypto.Hmac(crypto.sha256, utf8.encode(secret)).convert(base);
    // Evaluate every secret: no early exit on a match.
    ok = constantTimeEquals('v0=$mac', signature) | ok;
  }
  return ok;
}

/// Slack Events API and slash-command intake, the reference long poll, the
/// Klipy proxy and the reserved chat action gateway.
final class RelayRoutes {
  /// Creates the routes.
  RelayRoutes(this.ctx)
    : _klipyLimiter = TokenBucketLimiter(
        capacity: ctx.config.rateLimits.klipyPerInstallPerMinute,
        per: const Duration(minutes: 1),
        clock: ctx.clock,
      );

  /// The shared context.
  final ConnectContext ctx;
  final TokenBucketLimiter _klipyLimiter;
  final Map<String, int> _activePolls = {};

  /// `POST /v1/hooks/slack/events`. Always 200 once the signature verified,
  /// quickly, whatever happens next: an offline server must never make Slack
  /// disable the subscription.
  Future<void> slackEvents(HttpRequest request) async {
    final response = request.response;
    final (_, creds, _) = await ctx.slackLane();
    final body = await readCappedBody(request, slackEventMaxBytes);
    if (body == null) {
      ctx.log.event('slack.event_dropped', {'reason': 'too_large'});
      return sendJson(response, 200, const <String, Object?>{});
    }
    if (!verifySlackSignature(
      secrets: creds.signingSecret.values,
      timestamp: singleHeader(request, 'x-slack-request-timestamp'),
      signature: singleHeader(request, 'x-slack-signature'),
      body: body,
      now: ctx.now(),
    )) {
      return sendError(response, ConnectErrorCode.accessDenied);
    }
    final Object? json;
    try {
      json = jsonDecode(utf8.decode(body));
    } on FormatException {
      return sendJson(response, 200, const <String, Object?>{});
    }
    if (json is! Map) {
      return sendJson(response, 200, const <String, Object?>{});
    }
    if (json['type'] == 'url_verification') {
      final challenge = json['challenge'];
      if (challenge is String &&
          RegExp(r'^[A-Za-z0-9_-]{1,128}$').hasMatch(challenge)) {
        return sendJson(response, 200, {'challenge': challenge});
      }
      return sendError(response, ConnectErrorCode.invalidRequest);
    }
    if (json['type'] == 'event_callback' && json['api_app_id'] == creds.appId) {
      await _relayEvent(json);
    }
    return sendJson(response, 200, const <String, Object?>{});
  }

  Future<void> _relayEvent(Map<Object?, Object?> json) async {
    final team = json['team_id'];
    final eventId = json['event_id'];
    final event = json['event'];
    if (team is! String ||
        !isSlackId(team) ||
        eventId is! String ||
        eventId.length > 64 ||
        event is! Map) {
      return;
    }
    final type = event['type'];
    if (type == 'app_uninstalled' ||
        (type == 'tokens_revoked' && _revokesBot(event['tokens']))) {
      // Slack reports the app gone from the workspace (an admin uninstall
      // or a revoked bot token): the team is free to bind again. Only once
      // per event, and only for the binding that existed when it happened:
      // a retry or replay inside the signature window must not free a team
      // that has been connected again since.
      if (!await ctx.state.putIfAbsent(
        'slackev:$eventId',
        '1',
        slackQueueTtl,
      )) {
        return;
      }
      final bound = await ctx.bindings.slack(team, fresh: true);
      final at = json['event_time'];
      if (bound == null ||
          at is! int ||
          at < bound.boundAt.millisecondsSinceEpoch ~/ 1000) {
        if (bound != null) {
          ctx.log.event('slack.release_ignored', {
            'team': ctx.log.tag(team),
            'reason': type is String ? type : '',
          });
        }
        return;
      }
      final released = await ctx.bindings.releaseSlack(
        team,
        installId: bound.installId,
      );
      if (released) {
        ctx.log.event('slack.released', {
          'team': ctx.log.tag(team),
          'reason': type is String ? type : '',
        });
      }
      return;
    }
    if (type is! String || !relayedSlackEvents.contains(type)) {
      return;
    }
    final binding = await ctx.bindings.slack(team);
    if (binding == null) {
      return;
    }
    if (binding.botId.isNotEmpty && event['bot_id'] == binding.botId) {
      return; // Our own bot's messages.
    }
    final minute = ctx.now().millisecondsSinceEpoch ~/ 60000;
    final count = await ctx.state.increment(
      'slackrate:$team:$minute',
      const Duration(minutes: 2),
    );
    if (count > ctx.config.rateLimits.slackEventsPerTeamPerMinute) {
      if (count == ctx.config.rateLimits.slackEventsPerTeamPerMinute + 1) {
        ctx.log.event('slack.team_over_budget', {'team': ctx.log.tag(team)});
      }
      return;
    }
    if (!await ctx.state.putIfAbsent('slackev:$eventId', '1', slackQueueTtl)) {
      return; // A Slack retry of an event already queued.
    }
    String text(Object? value) =>
        value is String && value.length <= 64 ? value : '';
    final edited = event['subtype'] == 'message_changed'
        ? event['message']
        : null;
    final thread = event['assistant_thread'];
    final channelType = event['channel_type'];
    final ref = SlackEventRef(
      eventId: eventId,
      teamId: team,
      eventType: type == 'message'
          ? 'message.${channelType is String && RegExp(r'^[a-z]{1,16}$').hasMatch(channelType) ? channelType : 'unknown'}'
          : type,
      channelId: text(event['channel']).isNotEmpty
          ? text(event['channel'])
          : (thread is Map ? text(thread['channel_id']) : ''),
      threadTs: text(
        edited is Map
            ? edited['thread_ts']
            : (event['thread_ts'] ??
                  (thread is Map ? thread['thread_ts'] : null)),
      ),
      messageTs: text(edited is Map ? edited['ts'] : event['ts']),
    );
    await ctx.state.push(
      'slackq:${binding.installId}',
      jsonEncode(ref.toJson()),
      slackQueueTtl,
      maxLength: queueMaxItems,
    );
    ctx.signal.notify(binding.installId);
  }

  static bool _revokesBot(Object? tokens) {
    if (tokens is! Map) {
      return false;
    }
    final bot = tokens['bot'];
    return bot is List && bot.isNotEmpty;
  }

  /// `POST /v1/hooks/slack/commands`: queue a bounded reference and answer
  /// immediately with a fixed ephemeral message.
  Future<void> slackCommands(HttpRequest request) async {
    final response = request.response;
    final (_, creds, _) = await ctx.slackLane();
    final body = await readCappedBody(request, slackCommandMaxBytes);
    if (body == null) {
      return sendError(response, ConnectErrorCode.invalidRequest);
    }
    if (!verifySlackSignature(
      secrets: creds.signingSecret.values,
      timestamp: singleHeader(request, 'x-slack-request-timestamp'),
      signature: singleHeader(request, 'x-slack-signature'),
      body: body,
      now: ctx.now(),
    )) {
      return sendError(response, ConnectErrorCode.accessDenied);
    }
    final Map<String, String> form;
    try {
      form = Uri.splitQueryString(utf8.decode(body));
    } on FormatException {
      return sendError(response, ConnectErrorCode.invalidRequest);
    }
    final appId = form['api_app_id'];
    final team = form['team_id'] ?? '';
    if ((appId != null && appId != creds.appId) || !isSlackId(team)) {
      return sendError(response, ConnectErrorCode.invalidRequest);
    }
    final binding = await ctx.bindings.slack(team);
    if (binding == null) {
      return sendJson(response, 200, {
        'response_type': 'ephemeral',
        'text':
            'This Slack workspace is not connected to Control Center. Add the '
            'app from Control Center first.',
      });
    }
    final minute = ctx.now().millisecondsSinceEpoch ~/ 60000;
    final count = await ctx.state.increment(
      'slackrate:$team:$minute',
      const Duration(minutes: 2),
    );
    if (count > ctx.config.rateLimits.slackEventsPerTeamPerMinute) {
      return sendJson(response, 200, {
        'response_type': 'ephemeral',
        'text': 'Control Center is busy. Try again in a minute.',
      });
    }
    String id(String key) {
      final value = form[key] ?? '';
      return value.length <= 64 ? value : '';
    }

    final rawText = form['text'] ?? '';
    final responseUrl = form['response_url'] ?? '';
    final ref = SlackCommandRef(
      commandId: b64url(randomBytes(16)),
      teamId: team,
      userId: id('user_id'),
      channelId: id('channel_id'),
      command: id('command'),
      text: String.fromCharCodes(rawText.runes.take(SlackCommandRef.maxText)),
      responseUrl: isSlackResponseUrl(responseUrl) && responseUrl.length <= 512
          ? responseUrl
          : '',
    );
    await ctx.state.push(
      'slackq:${binding.installId}',
      jsonEncode(ref.toJson()),
      slackQueueTtl,
      maxLength: queueMaxItems,
    );
    ctx.signal.notify(binding.installId);
    return sendJson(response, 200, {
      'response_type': 'ephemeral',
      'text': 'Got it. Confirm the draft in Control Center.',
    });
  }

  /// `POST /v1/events/poll`: up to 25 s, then whatever is queued for the
  /// caller's install (possibly nothing).
  Future<Object?> poll(ConnectCaller caller, Map<String, Object?> body) async {
    final active = _activePolls[caller.installId] ?? 0;
    if (active >= 2) {
      throw const ConnectException(ConnectErrorCode.rateLimited);
    }
    _activePolls[caller.installId] = active + 1;
    try {
      final deadline = ctx.now().add(ctx.pollTimeout);
      while (true) {
        final items = await ctx.state.drain(
          'slackq:${caller.installId}',
          max: pollMaxItems,
        );
        if (items.isNotEmpty) {
          return {
            'events': [for (final item in items) ?_decode(item)],
          };
        }
        final remaining = deadline.difference(ctx.now());
        if (remaining <= Duration.zero) {
          return const {'events': <Object?>[]};
        }
        // Wake on a local push, or tick to pick up another instance's.
        await ctx.signal.wait(
          caller.installId,
          remaining < const Duration(seconds: 1)
              ? remaining
              : const Duration(seconds: 1),
        );
      }
    } finally {
      final left = (_activePolls[caller.installId] ?? 1) - 1;
      if (left <= 0) {
        _activePolls.remove(caller.installId);
      } else {
        _activePolls[caller.installId] = left;
      }
    }
  }

  static Map<String, Object?>? _decode(String item) {
    try {
      final decoded = jsonDecode(item);
      return decoded is Map<String, Object?> ? decoded : null;
    } on FormatException {
      return null;
    }
  }

  /// `POST /v1/klipy/search` and `/v1/klipy/trending`.
  Future<Object?> klipy(
    ConnectCaller caller,
    Map<String, Object?> body, {
    required bool search,
  }) async {
    final api = await ctx.klipyProxy();
    final KlipyQuery query;
    try {
      query = KlipyQuery.fromJson(body, requireQuery: search);
    } on FormatException {
      throw const ConnectException(ConnectErrorCode.invalidRequest);
    }
    if (!_klipyLimiter.tryTake(caller.installId)) {
      throw const ConnectException(ConnectErrorCode.rateLimited);
    }
    final gifs = await api.gifs(query);
    return KlipyGifsResponse(gifs: gifs).toJson();
  }

  /// `POST /v1/chat/{provider}/act`: reserved for future unscoped chat bots
  /// (Discord, Telegram). Always `provider_unavailable` today.
  Future<Object?> chatAct(ConnectCaller caller, Map<String, Object?> body) =>
      Future.error(
        const ConnectException(ConnectErrorCode.providerUnavailable),
      );
}
