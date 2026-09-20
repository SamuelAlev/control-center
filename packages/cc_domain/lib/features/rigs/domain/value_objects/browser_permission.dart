/// Site permissions a page asked the enclosed browser for.
///
/// The guest cannot show its own prompt (headless, or a doorhanger the
/// human never sees). The host chrome is the prompt: the shield flyout
/// records each decision for the life of the rig.
library;

/// What the page asked for. Wire-stable names match the Permissions API
/// (`persistent-storage`, `geolocation`, …) so the in-page interceptor and
/// this type stay one vocabulary.
enum BrowserPermissionKind {
  /// `getUserMedia({video})`.
  camera,

  /// `getUserMedia({audio})`.
  microphone,

  /// `Notification.requestPermission`.
  notifications,

  /// `navigator.geolocation`.
  geolocation,

  /// `navigator.storage.persist()`.
  persistentStorage,

  /// `navigator.clipboard.read` / `readText`.
  clipboard,

  /// `getDisplayMedia`.
  displayCapture,

  /// `navigator.requestMIDIAccess`.
  midi;

  /// Permissions-API / interceptor spelling.
  String get wire => switch (this) {
    camera => 'camera',
    microphone => 'microphone',
    notifications => 'notifications',
    geolocation => 'geolocation',
    persistentStorage => 'persistent-storage',
    clipboard => 'clipboard-read',
    displayCapture => 'display-capture',
    midi => 'midi',
  };

  /// Parses [value], or null when unknown — an interceptor the host has not
  /// met yet must not become a fake kind.
  static BrowserPermissionKind? fromWire(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    for (final k in BrowserPermissionKind.values) {
      if (k.wire == value) {
        return k;
      }
    }
    return null;
  }
}

/// Whether the human allowed or blocked the request, or has not answered.
enum BrowserPermissionDecision {
  /// The flyout is waiting for Allow / Block.
  pending,

  /// The page may use the capability.
  granted,

  /// The page's request was refused.
  denied;

  /// Stable wire string.
  String get wire => name;

  /// Parses [value], defaulting to [pending] so an older payload still
  /// surfaces as something the flyout can show.
  static BrowserPermissionDecision fromWire(String? value) {
    for (final d in BrowserPermissionDecision.values) {
      if (d.wire == value) {
        return d;
      }
    }
    return BrowserPermissionDecision.pending;
  }
}

/// One origin + kind the page asked for, and what was decided.
class BrowserPermissionEntry {
  /// Creates a [BrowserPermissionEntry].
  const BrowserPermissionEntry({
    required this.id,
    required this.origin,
    required this.kind,
    required this.decision,
    this.contextId,
  });

  /// Builds from the `rig.browserState` / act wire map.
  factory BrowserPermissionEntry.fromJson(Map<String, dynamic> json) {
    final kind =
        BrowserPermissionKind.fromWire(json['kind'] as String?) ??
        BrowserPermissionKind.notifications;
    return BrowserPermissionEntry(
      id: json['id'] as String? ?? '',
      origin: json['origin'] as String? ?? '',
      kind: kind,
      decision: BrowserPermissionDecision.fromWire(json['decision'] as String?),
      contextId: json['context_id'] as int?,
    );
  }

  /// Opaque id the in-page interceptor is waiting on.
  final String id;

  /// The page origin that asked (`http://localhost:5173`).
  final String origin;

  /// What was asked.
  final BrowserPermissionKind kind;

  /// Pending, granted, or denied.
  final BrowserPermissionDecision decision;

  /// Chromium execution context, when the probe came from CDP. Needed so
  /// the resolve runs in the frame that asked, not the main world.
  final int? contextId;

  /// Host[:port] shown in the flyout, matching the browser's own prompt.
  String get originLabel {
    final uri = Uri.tryParse(origin);
    if (uri == null || uri.host.isEmpty) {
      return origin;
    }
    if (uri.hasPort && uri.port != 80 && uri.port != 443) {
      return '${uri.host}:${uri.port}';
    }
    return uri.host;
  }

  /// Wire form.
  Map<String, dynamic> toJson() => {
    'id': id,
    'origin': origin,
    'kind': kind.wire,
    'decision': decision.wire,
    if (contextId != null) 'context_id': contextId,
  };

  /// Copy with a later decision.
  BrowserPermissionEntry withDecision(BrowserPermissionDecision next) =>
      BrowserPermissionEntry(
        id: id,
        origin: origin,
        kind: kind,
        decision: next,
        contextId: contextId,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BrowserPermissionEntry &&
          other.id == id &&
          other.origin == origin &&
          other.kind == kind &&
          other.decision == decision &&
          other.contextId == contextId;

  @override
  int get hashCode => Object.hash(id, origin, kind, decision, contextId);
}
