import 'dart:async';
import 'dart:convert';

import 'package:cc_domain/cc_domain.dart' show ValidationException;
import 'package:cc_domain/features/chat_bridge/domain/value_objects/chat_bot_profile.dart';
import 'package:cc_infra/src/network/slack_api_client.dart';

/// What Control Center still cannot do for the user after creating the app.
///
/// Slack exposes no API for generating an app-level token or for installing an
/// app into a team, so the guided flow ends with two deep links and a paste.
/// Checked against the current manifest API docs; if Slack ever ships those,
/// this record is where the seams are.
class SlackAppCreation {
  /// Creates a [SlackAppCreation].
  const SlackAppCreation({
    required this.appId,
    required this.configRefreshToken,
  });

  /// The new app's id (`A…`).
  final String appId;

  /// The refresh token to persist — the one presented to Slack is now dead.
  final String configRefreshToken;

  /// Where the user generates the app-level (`xapp-`) token.
  String get appTokenUrl => 'https://api.slack.com/apps/$appId/general';

  /// Where the user installs the app to get the bot (`xoxb-`) token: the app's
  /// own settings page, never the `oauth_authorize_url` Slack returns from
  /// `apps.manifest.create`.
  ///
  /// That URL is the *distribution* flow and ends at a `redirect_uri` — which a
  /// Socket Mode app has no public endpoint to declare, so Slack answers
  /// "redirect_uri did not match any configured URIs". The settings page
  /// installs through Slack's own redirect and needs nothing configured.
  String get installPageUrl =>
      'https://api.slack.com/apps/$appId/install-on-team';

  /// The app's settings home, for everything Slack keeps to itself (the icon).
  String get settingsUrl => 'https://api.slack.com/apps/$appId';
}

/// Creates and reshapes the workspace's Slack app through the App Manifest API.
///
/// Two things make this more than a thin API wrapper:
///
///  * **Rotation is destructive.** Every `tooling.tokens.rotate` invalidates the
///    refresh token it was given and hands back a new one, so the new one has to
///    be persisted *before* it is used. Dropping it un-manages the app for good
///    (only a hand-made token in Slack's UI recovers it), which is why
///    [_accessToken] writes through [_writeRefreshToken] on every rotation and
///    treats a failed write as a failed operation.
///  * **Updates merge, they do not replace.** `apps.manifest.update` takes a
///    whole manifest, so the service exports the live one and overlays only the
///    fields it owns. Anything the user added in Slack's UI — an extra scope, a
///    second slash command, unfurl domains — survives an edit made here.
class SlackManifestService {
  /// Creates a [SlackManifestService].
  ///
  /// [readRefreshToken] and [writeRefreshToken] are the persistence seam: the
  /// service never decides *where* the token lives (that is the workspace's
  /// credentials file), only that a rotation is saved immediately.
  SlackManifestService({
    required SlackApiClient api,
    required Future<String?> Function() readRefreshToken,
    required Future<void> Function(String refreshToken) writeRefreshToken,
  }) : _api = api,
       _readRefreshToken = readRefreshToken,
       _writeRefreshToken = writeRefreshToken;

  final SlackApiClient _api;
  final Future<String?> Function() _readRefreshToken;
  final Future<void> Function(String refreshToken) _writeRefreshToken;

  /// Bot scopes the bridge needs. Merged into whatever the app already has —
  /// never subtracted, so a scope somebody added in Slack survives an edit.
  static const Set<String> requiredScopes = {
    'app_mentions:read',
    'assistant:write',
    'channels:history',
    'chat:write',
    'commands',
    'groups:history',
    'im:history',
    'users:read',
    'users:read.email',
  };

  /// The description Control Center writes on the slash command it owns.
  ///
  /// It doubles as the marker that identifies *our* command in an exported
  /// manifest. Slack offers nowhere to tag a command, and treating "the first
  /// one" as ours would delete a command the user added in Slack the next time
  /// the bot is edited here.
  static const String commandDescription =
      'File a ticket or link your Control Center account';

  /// Events the bridge listens for. `message.channels`/`message.groups` are what
  /// make a *reply* inside an already-bridged thread work; without them only the
  /// first mention would ever arrive.
  static const Set<String> requiredBotEvents = {
    'app_home_opened',
    'app_mention',
    'message.channels',
    'message.groups',
    'message.im',
  };

  /// Slack's app-creation page, which doubles as the pre-filled-manifest
  /// entry point (`?new_app=1&manifest_json=…`).
  static const String appsConsoleUrl = 'https://api.slack.com/apps';

  /// Slack's app-creation deep link with [profile]'s manifest pre-filled.
  ///
  /// The credential-free alternative to [createApp]: Slack accepts a whole
  /// manifest as a query parameter, so the user confirms the app in Slack's own
  /// UI instead of minting an app-configuration token for us. Same manifest, so
  /// the scopes, events and Socket Mode arrive already correct.
  ///
  /// The tradeoff is real and belongs in the UI copy: Slack reports the new app
  /// to nobody, so Control Center never learns its id and cannot edit it later
  /// until a configuration token is pasted.
  static String manifestCreateUrl(ChatBotProfile profile) {
    profile.validate();
    // Percent-encoded, not form-encoded: this value is handed to a browser
    // navigating to Slack, and a `+` standing in for a space only survives a
    // reader that form-decodes.
    final manifest = Uri.encodeComponent(
      jsonEncode(buildManifest(profile: profile)),
    );
    return '$appsConsoleUrl?new_app=1&manifest_json=$manifest';
  }

  /// Creates the Slack app from [profile] and returns what the user must still
  /// do by hand (generate an app-level token, install the app).
  ///
  /// The refresh token in the result is already the *rotated* one and must be
  /// stored — [createApp] persists it through the write seam as well, so a
  /// caller that drops the result still keeps a usable token.
  Future<SlackAppCreation> createApp(ChatBotProfile profile) async {
    profile.validate();
    final manifest = buildManifest(profile: profile);
    final token = await _accessToken();
    await _guard(
      () => _api.validateManifest(configAccessToken: token, manifest: manifest),
    );
    final created = await _guard(
      () => _api.createApp(configAccessToken: token, manifest: manifest),
    );
    final refreshToken = await _readRefreshToken();
    return SlackAppCreation(
      appId: created,
      configRefreshToken: refreshToken ?? '',
    );
  }

  /// The live app's customizable fields, for the customize dialog.
  Future<ChatBotProfile> profile(String appId) async {
    final token = await _accessToken();
    final manifest = await _guard(
      () => _api.exportManifest(configAccessToken: token, appId: appId),
    );
    return profileFromManifest(manifest);
  }

  /// Reads the customizable fields back out of a Slack manifest.
  ///
  /// Tolerant by design: a hand-made app (the documented starting point) has no
  /// reason to look like ours, and the customize dialog must still show it
  /// something sensible rather than refusing to open.
  static ChatBotProfile profileFromManifest(Map<String, dynamic> manifest) {
    final display = _map(manifest['display_information']);
    final features = _map(manifest['features']);
    final botUser = _map(features['bot_user']);
    final agentView = _map(features['agent_view']);
    final assistantView = _map(features['assistant_view']);
    final agent = agentView.isNotEmpty ? agentView : assistantView;
    final commands = ((features['slash_commands'] as List?) ?? const [])
        .whereType<Map>()
        .map(_map)
        .toList();
    // Ours if it carries our marker; otherwise the app's only/first command is
    // the one the user means us to answer on.
    final ours =
        commands.firstWhere(
              (c) => c['description'] == commandDescription,
              orElse: () => commands.isEmpty ? const {} : commands.first,
            )['command']
            as String?;
    return ChatBotProfile(
      appName: display['name'] as String? ?? '',
      botDisplayName: botUser['display_name'] as String? ?? '',
      description: display['description'] as String? ?? '',
      agentDescription:
          (agent['agent_description'] ?? agent['assistant_description'])
              as String? ??
          '',
      command: ChatBotProfile.normalizeCommand(ours ?? 'cc'),
      agentEnabled: agent.isNotEmpty,
    );
  }

  static Map<String, dynamic> _map(Object? value) =>
      value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

  /// Applies [profile] to the live app.
  ///
  /// `permissionsUpdated` true means Slack changed the app's scopes, which only
  /// take effect once somebody reinstalls the app — the caller has to say so,
  /// because until then the bridge keeps running with the old grant.
  Future<({bool permissionsUpdated})> updateProfile({
    required String appId,
    required ChatBotProfile profile,
  }) async {
    profile.validate();
    final token = await _accessToken();
    final base = await _guard(
      () => _api.exportManifest(configAccessToken: token, appId: appId),
    );
    final manifest = buildManifest(profile: profile, base: base);
    await _guard(
      () => _api.validateManifest(
        configAccessToken: token,
        manifest: manifest,
        appId: appId,
      ),
    );
    return _guard(
      () => _api.updateManifest(
        configAccessToken: token,
        appId: appId,
        manifest: manifest,
      ),
    );
  }

  /// Composes the manifest for [profile], overlaying [base] when the app already
  /// exists so nothing the user configured in Slack is silently dropped.
  ///
  /// The structural settings are asserted rather than offered: Socket Mode on
  /// (the whole premise — no public endpoint), the required scopes and events
  /// merged in, and any `request_url` removed, because Slack refuses a manifest
  /// that asks for both Socket Mode and webhook delivery.
  static Map<String, dynamic> buildManifest({
    required ChatBotProfile profile,
    Map<String, dynamic>? base,
  }) {
    final manifest = _clone(base ?? const {});

    final display = _child(manifest, 'display_information');
    display['name'] = profile.appName;
    if (profile.description.isNotEmpty) {
      display['description'] = profile.description;
    }

    final features = _child(manifest, 'features');
    final botUser = _child(features, 'bot_user');
    botUser['display_name'] = profile.botDisplayName;
    botUser['always_online'] = true;

    final appHome = _child(features, 'app_home');
    // The agent experience *is* the Messages tab, so a bot the user can DM has
    // to have it enabled and writable.
    appHome['messages_tab_enabled'] = true;
    appHome['messages_tab_read_only_enabled'] = false;

    // `assistant_view` is the legacy shape of the same feature and the switch to
    // `agent_view` is irreversible, so an app already on the old one keeps it:
    // this dialog edits a description, it does not migrate a Slack app.
    final legacyView = features['assistant_view'];
    if (profile.agentEnabled) {
      if (legacyView is Map) {
        _child(features, 'assistant_view')['assistant_description'] =
            profile.agentDescription;
      } else {
        _child(features, 'agent_view')['agent_description'] =
            profile.agentDescription;
      }
    } else {
      features.remove('agent_view');
      features.remove('assistant_view');
    }

    // Everything except our own command (identified by its marker description,
    // so a rename replaces it rather than accumulating) is carried over.
    final commands = ((features['slash_commands'] as List?) ?? const [])
        .whereType<Map>()
        .map(Map<String, dynamic>.from)
        .where(
          (c) =>
              c['command'] != profile.slashCommand &&
              c['description'] != commandDescription,
        )
        .toList();
    features['slash_commands'] = [
      ...commands,
      {
        'command': profile.slashCommand,
        'description': commandDescription,
        'usage_hint': 'ticket Fix the flaky login test | it fails on CI',
        'should_escape': false,
      },
    ];

    final oauth = _child(manifest, 'oauth_config');
    final scopes = _child(oauth, 'scopes');
    scopes['bot'] = _merged(scopes['bot'], requiredScopes);

    final settings = _child(manifest, 'settings');
    settings['socket_mode_enabled'] = true;
    final events = _child(settings, 'event_subscriptions');
    events['bot_events'] = _merged(events['bot_events'], requiredBotEvents);
    events.remove('request_url');
    final interactivity = _child(settings, 'interactivity');
    interactivity['is_enabled'] = true;
    interactivity.remove('request_url');
    interactivity.remove('message_menu_options_url');

    return manifest;
  }

  /// A fresh app-configuration access token, rotating the stored refresh token
  /// and persisting the replacement Slack hands back **before** using it.
  Future<String> _accessToken() async {
    final refreshToken = await _readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      throw const ValidationException(
        'Managing the Slack app needs an app configuration token. Generate one '
        'at api.slack.com/apps (Your Apps → “Manage app configuration '
        'tokens”) and paste the refresh token when connecting.',
      );
    }
    final rotated = await _guard(() => _api.rotateConfigToken(refreshToken));
    // Slack has already invalidated the token we presented: if this write fails
    // the app becomes unmanageable, so the failure has to be the operation's.
    await _writeRefreshToken(rotated.refreshToken);
    return rotated.accessToken;
  }

  /// Turns Slack's refusals into messages the person in the settings dialog can
  /// act on. Anything else propagates untouched.
  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on SlackApiException catch (e) {
      throw ValidationException(_explain(e));
    }
  }

  static String _explain(SlackApiException e) {
    // Naming the raw code when Slack sent no detail keeps the message a lead
    // rather than a dead end.
    final detail = e.details.isEmpty
        ? ' (${e.error})'
        : ': ${e.details.join('; ')}';
    return switch (e.error) {
      'invalid_refresh_token' || 'token_expired' =>
        'Slack rejected the app configuration token. Generate a new one at '
            'api.slack.com/apps and reconnect.',
      'invalid_manifest' ||
      'invalid_app' => 'Slack refused the app manifest$detail.',
      // `invalid_arguments` is Slack refusing the *call*, not a verdict on the
      // manifest — the token rotation raises it too, and calling that "the app
      // manifest" sends the reader to the wrong screen.
      'invalid_arguments' when e.method.startsWith('apps.manifest') =>
        'Slack refused the app manifest$detail.',
      'app_not_found' || 'invalid_app_id' =>
        'Slack does not know this app any more. It may have been deleted; '
            'disconnect and connect again.',
      'not_allowed_token_type' =>
        'That token cannot manage apps. App configuration tokens start with '
            '`xoxe-`.',
      'ratelimited' =>
        'Slack is rate limiting app configuration changes. Try again shortly.',
      _ => 'Slack refused ${e.method}$detail.',
    };
  }

  static Map<String, dynamic> _clone(Map<String, dynamic> source) {
    final copy = <String, dynamic>{};
    for (final entry in source.entries) {
      final value = entry.value;
      copy[entry.key] = switch (value) {
        Map() => _clone(Map<String, dynamic>.from(value)),
        List() => List<dynamic>.from(value),
        _ => value,
      };
    }
    return copy;
  }

  static Map<String, dynamic> _child(Map<String, dynamic> parent, String key) {
    final existing = parent[key];
    final child = existing is Map
        ? Map<String, dynamic>.from(existing)
        : <String, dynamic>{};
    parent[key] = child;
    return child;
  }

  static List<String> _merged(Object? existing, Set<String> required) {
    final merged = <String>{
      ...((existing as List?) ?? const []).whereType<String>(),
      ...required,
    }.toList()..sort();
    return merged;
  }
}
