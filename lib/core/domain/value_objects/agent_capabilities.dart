import 'dart:convert';

/// Per-conversation capability flags that gate what an agent can do inside
/// its sandbox.
///
/// Capabilities are checked by the credential broker at launch time — if a
/// capability is off, the matching token or network access is simply not
/// injected into the sandbox.
class AgentCapabilities {
  /// Creates a new [AgentCapabilities].
  const AgentCapabilities({
    this.canPushToRepo = false,
    this.canCallGitHubApi = false,
    this.canCallTicketing = false,
    this.canAccessNetwork = true,
  });

  /// Parses from a JSON map. Reads the legacy `canCallLinear` key as a
  /// fallback so persisted capability blobs keep working without a migration.
  factory AgentCapabilities.fromJson(Map<String, dynamic> json) =>
      AgentCapabilities(
        canPushToRepo: json['canPushToRepo'] as bool? ?? false,
        canCallGitHubApi: json['canCallGitHubApi'] as bool? ?? false,
        canCallTicketing:
            (json['canCallTicketing'] ?? json['canCallLinear']) as bool? ??
                false,
        canAccessNetwork: json['canAccessNetwork'] as bool? ?? true,
      );

  /// Parses from a JSON string. Returns [safeDefault] on empty / malformed.
  factory AgentCapabilities.fromJsonString(String raw) {
    if (raw.isEmpty) {
      return AgentCapabilities.safeDefault;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return AgentCapabilities.fromJson(decoded);
      }
    } catch (_) {}
    return AgentCapabilities.safeDefault;
  }

  /// Permissive default for chats created before capabilities existed. Used
  /// by the migration only — fresh chats inherit the user's configured
  /// default.
  static const AgentCapabilities legacyDefault = AgentCapabilities(
    canPushToRepo: true,
    canCallGitHubApi: true,
    canCallTicketing: true,
    canAccessNetwork: true,
  );

  /// Conservative default for brand-new chats when no preference is set.
  static const AgentCapabilities safeDefault = AgentCapabilities();

  /// Allows `git push` operations — gates injection of the GitHub PAT.
  final bool canPushToRepo;

  /// Allows calling api.github.com — gates GH_TOKEN injection and egress.
  final bool canCallGitHubApi;

  /// Allows calling the configured ticketing provider API — gates
  /// TICKETING_API_KEY injection and egress to the provider's domains.
  final bool canCallTicketing;

  /// Allows arbitrary network egress. When false the sandbox boots with no
  /// default route; the broker's egress allowlist still applies on top.
  final bool canAccessNetwork;

  /// Returns a copy with the listed overrides.
  AgentCapabilities copyWith({
    bool? canPushToRepo,
    bool? canCallGitHubApi,
    bool? canCallTicketing,
    bool? canAccessNetwork,
  }) {
    return AgentCapabilities(
      canPushToRepo: canPushToRepo ?? this.canPushToRepo,
      canCallGitHubApi: canCallGitHubApi ?? this.canCallGitHubApi,
      canCallTicketing: canCallTicketing ?? this.canCallTicketing,
      canAccessNetwork: canAccessNetwork ?? this.canAccessNetwork,
    );
  }

  /// Serializes to a JSON map.
  Map<String, dynamic> toJson() => {
    'canPushToRepo': canPushToRepo,
    'canCallGitHubApi': canCallGitHubApi,
    'canCallTicketing': canCallTicketing,
    'canAccessNetwork': canAccessNetwork,
  };

  /// Serializes to a JSON string.
  String toJsonString() => jsonEncode(toJson());

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AgentCapabilities &&
          runtimeType == other.runtimeType &&
          canPushToRepo == other.canPushToRepo &&
          canCallGitHubApi == other.canCallGitHubApi &&
          canCallTicketing == other.canCallTicketing &&
          canAccessNetwork == other.canAccessNetwork;

  @override
  int get hashCode => Object.hash(
    canPushToRepo,
    canCallGitHubApi,
    canCallTicketing,
    canAccessNetwork,
  );
}
