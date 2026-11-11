import 'package:cc_domain/core/domain/value_objects/forge_host.dart';

/// Where a GitLab or Bitbucket automation token applies.
enum ForgeAutomationTokenScope {
  /// One linked repository.
  repo('repo'),

  /// Every linked repository on that forge in the workspace without a token
  /// of its own.
  workspace('workspace');

  const ForgeAutomationTokenScope(this.wire);

  /// The wire spelling.
  final String wire;
}

/// A stored GitLab or Bitbucket automation token as the server describes it
/// (`forge.listAutomationTokens`): never the token itself, only that one is
/// there, the bot it acts as, where it applies and whether it still works.
///
/// Work with no person behind it on those forges (the pull request poller,
/// AI review comments, unrequested agent pushes) uses only this token and
/// shows as that bot.
class ForgeAutomationToken {
  /// Creates a [ForgeAutomationToken].
  ForgeAutomationToken({
    required this.forge,
    required this.scope,
    this.repoId,
    this.botName = '',
    this.botLogin = '',
    this.rejected = false,
    this.verifiedAt,
  }) {
    if (forge != ForgeHost.gitlab && forge != ForgeHost.bitbucket) {
      throw ArgumentError.value(forge, 'forge', 'GitLab or Bitbucket only');
    }
    if ((scope == ForgeAutomationTokenScope.repo) !=
        (repoId != null && repoId!.isNotEmpty)) {
      throw ArgumentError('A repository token names its repository');
    }
  }

  /// Reads one `tokens` entry; null when it is malformed.
  static ForgeAutomationToken? tryParse(Map<String, dynamic> json) {
    final forge = ForgeHost.fromWire(json['forge'] as String?);
    final scope = json['scope'] == ForgeAutomationTokenScope.repo.wire
        ? ForgeAutomationTokenScope.repo
        : ForgeAutomationTokenScope.workspace;
    final repoId = json['repo_id'] as String?;
    try {
      return ForgeAutomationToken(
        forge: forge,
        scope: scope,
        repoId: repoId == null || repoId.isEmpty ? null : repoId,
        botName: json['bot_name'] as String? ?? '',
        botLogin: json['bot_login'] as String? ?? '',
        rejected: json['status'] == 'rejected',
        verifiedAt: DateTime.tryParse(
          json['verified_at'] as String? ?? '',
        )?.toUtc(),
      );
    } on ArgumentError {
      return null;
    }
  }

  /// Reads a list answer's `tokens` (absent = none).
  static List<ForgeAutomationToken> listOf(Object? raw) => [
    for (final entry in raw is List ? raw : const [])
      if (entry is Map) ?tryParse(entry.cast<String, dynamic>()),
  ];

  /// GitLab or Bitbucket.
  final ForgeHost forge;

  /// Where it applies.
  final ForgeAutomationTokenScope scope;

  /// The repository, for [ForgeAutomationTokenScope.repo].
  final String? repoId;

  /// The bot's display name; empty when the forge did not say.
  final String botName;

  /// The bot's account name; empty when the forge did not say.
  final String botLogin;

  /// Whether the forge has refused it since it was saved.
  final bool rejected;

  /// When it was last verified.
  final DateTime? verifiedAt;

  /// The bot's name to show: its display name, else its account name;
  /// empty when the forge named neither.
  String get botLabel => botName.isNotEmpty ? botName : botLogin;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ForgeAutomationToken &&
          forge == other.forge &&
          scope == other.scope &&
          repoId == other.repoId &&
          botName == other.botName &&
          botLogin == other.botLogin &&
          rejected == other.rejected &&
          verifiedAt == other.verifiedAt;

  @override
  int get hashCode => Object.hash(
    forge,
    scope,
    repoId,
    botName,
    botLogin,
    rejected,
    verifiedAt,
  );
}
