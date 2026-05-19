/// One step the user must finish in the provider's own UI, because the provider
/// exposes no API for it (Slack: generating an app-level token, installing the
/// app).
///
/// Data, not copy-with-behavior: the client localizes by [id] and falls back to
/// [title]/[hint] — the same seam a credential field uses, so a provider added
/// later renders correctly without a UI change.
class ChatSetupStep {
  /// Creates a [ChatSetupStep].
  const ChatSetupStep({
    required this.id,
    required this.title,
    required this.url,
    this.hint,
  });

  /// Rebuilds from the wire map.
  factory ChatSetupStep.fromJson(Map<String, dynamic> json) => ChatSetupStep(
    id: json['id'] as String? ?? '',
    title: json['title'] as String? ?? '',
    url: json['url'] as String? ?? '',
    hint: json['hint'] as String?,
  );

  /// Stable step key (`appToken`, `install`, …).
  final String id;

  /// English title, used when the client cannot localize [id].
  final String title;

  /// Where the step happens.
  final String url;

  /// English hint naming where in the provider's UI to look.
  final String? hint;

  /// Serializes to the wire map.
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'url': url,
    if (hint != null) 'hint': hint,
  };
}

/// A provider-side app Control Center just created and what is left to do.
///
/// A guided create can end in the middle and saying so is the point: Slack has
/// no API for generating an app-level token or for installing an app, so
/// pretending otherwise would strand the user at the last step.
class ChatAppCreation {
  /// Creates a [ChatAppCreation].
  const ChatAppCreation({
    required this.appId,
    required this.settingsUrl,
    this.remainingSteps = const [],
  });

  /// Rebuilds from the wire map.
  factory ChatAppCreation.fromJson(Map<String, dynamic> json) =>
      ChatAppCreation(
        appId: json['appId'] as String? ?? '',
        settingsUrl: json['settingsUrl'] as String? ?? '',
        remainingSteps: ((json['remainingSteps'] as List?) ?? const [])
            .whereType<Map>()
            .map((s) => ChatSetupStep.fromJson(s.cast<String, dynamic>()))
            .toList(),
      );

  /// The new app's provider-side id.
  final String appId;

  /// The app's settings home, for everything the provider keeps to itself.
  final String settingsUrl;

  /// What the user must still do by hand, in order. Empty when the provider can
  /// be driven end to end.
  final List<ChatSetupStep> remainingSteps;

  /// The remaining step with [id], or null when this provider has no such step.
  ///
  /// Callers look steps up by id rather than by position because the set is
  /// provider-shaped: a client asking for `install` must get null rather than
  /// whatever happened to be second.
  ChatSetupStep? step(String id) {
    for (final step in remainingSteps) {
      if (step.id == id) {
        return step;
      }
    }
    return null;
  }

  /// Serializes to the wire map.
  Map<String, dynamic> toJson() => {
    'appId': appId,
    'settingsUrl': settingsUrl,
    'remainingSteps': [for (final step in remainingSteps) step.toJson()],
  };
}
