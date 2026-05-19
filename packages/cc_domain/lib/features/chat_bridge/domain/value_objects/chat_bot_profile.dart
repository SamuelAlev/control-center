import 'package:cc_domain/src/errors/app_exceptions.dart';

/// The parts of a workspace's provider-side bot app Control Center is willing to
/// shape.
///
/// Deliberately small: a name, two descriptions and the command. Everything
/// structural (the transport, scopes, event subscriptions) is decided by the
/// adapter and is not offered as a choice — an app that can be misconfigured
/// into silence from a settings screen is a support ticket, not a feature.
///
/// This lives in the shared kernel because both halves need it: the settings
/// screen edits one and the server turns it into whatever shape the provider
/// wants (a Slack manifest, a Discord application patch).
class ChatBotProfile {
  /// Creates a [ChatBotProfile].
  const ChatBotProfile({
    required this.appName,
    required this.botDisplayName,
    required this.description,
    required this.agentDescription,
    required this.command,
    this.agentEnabled = true,
  });

  /// The profile a freshly created Control Center bot starts from.
  factory ChatBotProfile.initial({String? workspaceName}) {
    final suffix = (workspaceName ?? '').trim();
    return ChatBotProfile(
      appName: suffix.isEmpty ? 'Control Center' : 'Control Center · $suffix',
      botDisplayName: 'control-center',
      description: 'Put your Control Center agents to work from chat.',
      agentDescription:
          'Mention me or send me a message and I will put a Control Center '
          'agent on it, then stream the answer back here.',
      command: 'cc',
    );
  }

  /// Parses from the wire map.
  factory ChatBotProfile.fromJson(Map<String, dynamic> json) => ChatBotProfile(
    appName: (json['appName'] as String? ?? '').trim(),
    botDisplayName: (json['botDisplayName'] as String? ?? '').trim(),
    description: (json['description'] as String? ?? '').trim(),
    agentDescription: (json['agentDescription'] as String? ?? '').trim(),
    command: normalizeCommand(json['command'] as String? ?? 'cc'),
    agentEnabled: json['agentEnabled'] as bool? ?? true,
  );

  /// The app's name, as the provider lists it for the team.
  final String appName;

  /// The bot user's display name — what members type after `@`.
  final String botDisplayName;

  /// One-line description shown by the provider.
  final String description;

  /// What the agent experience promises, shown above a DM with the bot.
  final String agentDescription;

  /// The command, without its leading slash (`cc` → `/cc`).
  final String command;

  /// Whether the app exposes the provider's agent (DM) experience.
  final bool agentEnabled;

  /// The command as the provider spells it.
  String get slashCommand => '/$command';

  /// Strips a leading slash and the characters providers refuse in a command.
  static String normalizeCommand(String raw) {
    final cleaned = raw
        .trim()
        .replaceFirst(RegExp('^/+'), '')
        .toLowerCase()
        .replaceAll(RegExp('[^a-z0-9_-]'), '');
    if (cleaned.isEmpty) {
      return 'cc';
    }
    return cleaned.length <= 32 ? cleaned : cleaned.substring(0, 32);
  }

  /// Returns a copy with the given fields replaced.
  ChatBotProfile copyWith({
    String? appName,
    String? botDisplayName,
    String? description,
    String? agentDescription,
    String? command,
    bool? agentEnabled,
  }) => ChatBotProfile(
    appName: appName ?? this.appName,
    botDisplayName: botDisplayName ?? this.botDisplayName,
    description: description ?? this.description,
    agentDescription: agentDescription ?? this.agentDescription,
    command: command ?? this.command,
    agentEnabled: agentEnabled ?? this.agentEnabled,
  );

  /// Serializes to the wire map.
  Map<String, dynamic> toJson() => {
    'appName': appName,
    'botDisplayName': botDisplayName,
    'description': description,
    'agentDescription': agentDescription,
    'command': command,
    'agentEnabled': agentEnabled,
  };

  /// Throws a [ValidationException] naming the first field a provider would
  /// refuse.
  ///
  /// The provider validates too, but a limit reported as "which box is wrong"
  /// beats `invalid_manifest` arriving from a server the user cannot see. The
  /// ceilings are Slack's, which are the tightest of the products modelled here.
  void validate() {
    if (appName.isEmpty || appName.length > 35) {
      throw const ValidationException(
        'The app name must be between 1 and 35 characters.',
      );
    }
    if (botDisplayName.isEmpty || botDisplayName.length > 80) {
      throw const ValidationException(
        'The bot display name must be between 1 and 80 characters.',
      );
    }
    if (description.length > 140) {
      throw const ValidationException(
        'The description must be 140 characters or fewer.',
      );
    }
    if (agentDescription.length > 300) {
      throw const ValidationException(
        'The agent description must be 300 characters or fewer.',
      );
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatBotProfile &&
          runtimeType == other.runtimeType &&
          appName == other.appName &&
          botDisplayName == other.botDisplayName &&
          description == other.description &&
          agentDescription == other.agentDescription &&
          command == other.command &&
          agentEnabled == other.agentEnabled;

  @override
  int get hashCode => Object.hash(
    appName,
    botDisplayName,
    description,
    agentDescription,
    command,
    agentEnabled,
  );
}
