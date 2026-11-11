export 'package:cc_connect_core/src/wire_errors.dart';
export 'package:cc_connect_core/src/wire_github.dart';
export 'package:cc_connect_core/src/wire_oauth.dart';

/// `POST /v1/{github,google,slack}/refresh`, `/v1/slack/revoke` and
/// `/v1/install/retire`.
final class SealRequest {
  /// Creates the request.
  const SealRequest({required this.seal, required this.workspaceId});

  /// Parses the body; throws [FormatException].
  factory SealRequest.fromJson(Map<String, Object?> json) {
    final seal = json['seal'];
    final workspace = json['workspace_id'];
    if (seal is! String ||
        seal.isEmpty ||
        workspace is! String ||
        !isWorkspaceScope(workspace)) {
      throw const FormatException('seal request');
    }
    return SealRequest(seal: seal, workspaceId: workspace);
  }

  /// The seal.
  final String seal;

  /// The workspace the seal belongs to.
  final String workspaceId;

  /// The wire body.
  Map<String, Object?> toJson() => {'seal': seal, 'workspace_id': workspaceId};
}

/// A body-stripped Slack event reference. Carries ids and timestamps only:
/// the bound server re-reads the message from Slack itself.
final class SlackEventRef {
  /// Creates the reference.
  const SlackEventRef({
    required this.eventId,
    required this.teamId,
    required this.eventType,
    this.channelId = '',
    this.threadTs = '',
    this.messageTs = '',
  });

  /// Parses one reference; null when malformed.
  static SlackEventRef? tryParse(Object? json) {
    if (json is! Map) {
      return null;
    }
    final id = json['event_id'];
    final team = json['team_id'];
    final type = json['event_type'];
    if (id is! String || team is! String || type is! String) {
      return null;
    }
    String text(String key) {
      final value = json[key];
      return value is String ? value : '';
    }

    return SlackEventRef(
      eventId: id,
      teamId: team,
      eventType: type,
      channelId: text('channel_id'),
      threadTs: text('thread_ts'),
      messageTs: text('message_ts'),
    );
  }

  /// Slack's event id, the dedupe key.
  final String eventId;

  /// The team the event belongs to.
  final String teamId;

  /// `app_mention`, `message.im`, `assistant_thread_started`, …
  final String eventType;

  /// The channel.
  final String channelId;

  /// The thread root, when in a thread.
  final String threadTs;

  /// The message timestamp.
  final String messageTs;

  /// The wire body.
  Map<String, Object?> toJson() => {
    'kind': 'event',
    'event_id': eventId,
    'team_id': teamId,
    'event_type': eventType,
    if (channelId.isNotEmpty) 'channel_id': channelId,
    if (threadTs.isNotEmpty) 'thread_ts': threadTs,
    if (messageTs.isNotEmpty) 'message_ts': messageTs,
  };
}

/// A Slack slash command reference. A command cannot be re-read from Slack,
/// so its argument text travels — bounded — and only ever creates a draft
/// the person confirms inside Control Center.
final class SlackCommandRef {
  /// Creates the reference.
  const SlackCommandRef({
    required this.commandId,
    required this.teamId,
    required this.userId,
    required this.channelId,
    required this.command,
    required this.text,
    required this.responseUrl,
  });

  /// Parses one reference; null when malformed.
  static SlackCommandRef? tryParse(Object? json) {
    if (json is! Map) {
      return null;
    }
    final fields = [
      'command_id',
      'team_id',
      'user_id',
      'channel_id',
      'command',
      'text',
      'response_url',
    ];
    for (final field in fields) {
      if (json[field] is! String) {
        return null;
      }
    }
    return SlackCommandRef(
      commandId: json['command_id']! as String,
      teamId: json['team_id']! as String,
      userId: json['user_id']! as String,
      channelId: json['channel_id']! as String,
      command: json['command']! as String,
      text: json['text']! as String,
      responseUrl: json['response_url']! as String,
    );
  }

  /// Longest command argument relayed.
  static const int maxText = 500;

  /// Unique id assigned by Connect (Slack sends none).
  final String commandId;

  /// The team.
  final String teamId;

  /// Who ran it.
  final String userId;

  /// Where.
  final String channelId;

  /// The command (`/cc`).
  final String command;

  /// Its argument text, at most [maxText] characters.
  final String text;

  /// Slack's response URL (only `https://hooks.slack.com/` is honoured).
  final String responseUrl;

  /// The wire body.
  Map<String, Object?> toJson() => {
    'kind': 'command',
    'command_id': commandId,
    'team_id': teamId,
    'user_id': userId,
    'channel_id': channelId,
    'command': command,
    'text': text,
    'response_url': responseUrl,
  };
}

/// Whether [url] is a Slack response URL a server may post to.
bool isSlackResponseUrl(String url) {
  final uri = Uri.tryParse(url);
  return uri != null &&
      uri.scheme == 'https' &&
      uri.host == 'hooks.slack.com' &&
      !uri.hasPort &&
      uri.userInfo.isEmpty;
}

/// One normalised GIF from the Klipy proxy.
final class KlipyGif {
  /// Creates the item.
  const KlipyGif({
    required this.id,
    required this.title,
    required this.width,
    required this.height,
    required this.previewUrl,
    required this.gifUrl,
  });

  /// Parses one item; null when malformed or when a URL is off Klipy's CDN.
  static KlipyGif? tryParse(Object? json) {
    if (json is! Map) {
      return null;
    }
    final id = json['id'];
    final title = json['title'];
    final width = json['width'];
    final height = json['height'];
    final preview = json['preview_url'];
    final gif = json['gif_url'];
    if (id is! String ||
        title is! String ||
        width is! int ||
        height is! int ||
        preview is! String ||
        gif is! String ||
        !isKlipyCdnUrl(preview) ||
        !isKlipyCdnUrl(gif)) {
      return null;
    }
    return KlipyGif(
      id: id,
      title: title,
      width: width,
      height: height,
      previewUrl: preview,
      gifUrl: gif,
    );
  }

  /// Klipy's id.
  final String id;

  /// Its title.
  final String title;

  /// Pixel width.
  final int width;

  /// Pixel height.
  final int height;

  /// A small preview, on Klipy's CDN.
  final String previewUrl;

  /// The full GIF, on Klipy's CDN.
  final String gifUrl;

  /// The wire body.
  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'width': width,
    'height': height,
    'preview_url': previewUrl,
    'gif_url': gifUrl,
  };
}

/// Klipy's API host. It carries the app key in its paths, so it is never a
/// media host.
const String klipyApiHost = 'api.klipy.com';

/// Whether [url] is an HTTPS URL on Klipy's media CDN (a `klipy.com`
/// subdomain other than [klipyApiHost]). GIF bytes load straight from there
/// in the client; any other host in a search answer is dropped.
bool isKlipyCdnUrl(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null ||
      uri.scheme != 'https' ||
      uri.userInfo.isNotEmpty ||
      (uri.hasPort && uri.port != 443)) {
    return false;
  }
  final host = uri.host.toLowerCase();
  return host.endsWith('.klipy.com') && host != klipyApiHost;
}

/// The workspace scope of a grant that belongs to no single workspace.
const String globalWorkspaceScope = 'global';

/// Whether [value] is a workspace id or [globalWorkspaceScope].
bool isWorkspaceScope(String value) =>
    value.isNotEmpty &&
    value.length <= 64 &&
    RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(value);
