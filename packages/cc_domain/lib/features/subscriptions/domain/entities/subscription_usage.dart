import 'package:collection/collection.dart';

/// Whether a provider's live subscription usage could be read.
enum SubscriptionStatus {
  /// Usage was fetched successfully.
  ok,

  /// No credentials / the provider isn't set up on this machine.
  unconfigured,

  /// A fetch was attempted but failed (network, parse, or CLI error).
  error;

  /// Parses the wire string; an unrecognised value maps to [error].
  static SubscriptionStatus fromWire(String? raw) => switch (raw) {
    'ok' => SubscriptionStatus.ok,
    'unconfigured' => SubscriptionStatus.unconfigured,
    _ => SubscriptionStatus.error,
  };

  /// The wire string.
  String get wire => name;
}

/// One rolling usage window for a subscription (e.g. the 5-hour session window
/// or the weekly window).
class SubscriptionWindow {
  /// Creates a [SubscriptionWindow].
  const SubscriptionWindow({
    required this.id,
    required this.label,
    required this.usedFraction,
    this.resetsAt,
  });

  /// Parses a [SubscriptionWindow] from its wire shape.
  factory SubscriptionWindow.fromJson(Map<String, dynamic> json) =>
      SubscriptionWindow(
        id: json['id'] as String? ?? '',
        label: json['label'] as String? ?? '',
        usedFraction: ((json['used_fraction'] as num?)?.toDouble() ?? 0).clamp(
          0.0,
          1.0,
        ),
        resetsAt: switch (json['resets_at']) {
          final String s => DateTime.tryParse(s),
          _ => null,
        },
      );

  /// Stable window id (`5h`, `7d`, `monthly`).
  final String id;

  /// Display label (e.g. `Session`, `Weekly`).
  final String label;

  /// Fraction of the window consumed, clamped to `[0, 1]`.
  final double usedFraction;

  /// When the window next resets, if known.
  final DateTime? resetsAt;

  /// The wire shape.
  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'used_fraction': usedFraction,
    if (resetsAt != null) 'resets_at': resetsAt!.toIso8601String(),
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubscriptionWindow &&
          id == other.id &&
          label == other.label &&
          usedFraction == other.usedFraction &&
          resetsAt == other.resetsAt;

  @override
  int get hashCode => Object.hash(id, label, usedFraction, resetsAt);
}

/// A live subscription-usage snapshot for one AI coding provider — the
/// "X% used, resets in Y" data behind the title-bar usage pill.
///
/// Built server-side (where the provider CLIs and their credentials live) and
/// relayed to the client over the `subscriptions.usage` RPC op. Each provider
/// degrades independently: a missing credential yields
/// [SubscriptionStatus.unconfigured], a failed fetch yields
/// [SubscriptionStatus.error] and neither blanks out the others.
class SubscriptionUsage {
  /// Creates a [SubscriptionUsage].
  const SubscriptionUsage({
    required this.providerId,
    required this.displayName,
    required this.status,
    this.windows = const [],
    this.error,
    this.fetchedAt,
  });

  /// Parses a [SubscriptionUsage] from its wire shape.
  factory SubscriptionUsage.fromJson(Map<String, dynamic> json) =>
      SubscriptionUsage(
        providerId: json['provider_id'] as String? ?? '',
        displayName: json['display_name'] as String? ?? '',
        status: SubscriptionStatus.fromWire(json['status'] as String?),
        windows: [
          for (final w in (json['windows'] as List? ?? const []))
            SubscriptionWindow.fromJson((w as Map).cast<String, dynamic>()),
        ],
        error: json['error'] as String?,
        fetchedAt: switch (json['fetched_at']) {
          final String s => DateTime.tryParse(s),
          _ => null,
        },
      );

  /// Provider id (`claude`, `codex`, `zai`).
  final String providerId;

  /// Human display name (`Claude`, `Codex`, `z.ai`).
  final String displayName;

  /// Whether usage could be read.
  final SubscriptionStatus status;

  /// The rolling windows reported by the provider (may be empty).
  final List<SubscriptionWindow> windows;

  /// A human-readable failure reason when [status] is not
  /// [SubscriptionStatus.ok].
  final String? error;

  /// When this snapshot was produced.
  final DateTime? fetchedAt;

  /// The most-consumed window's fraction — drives the pill's headline %.
  double? get peakUsedFraction => windows.isEmpty
      ? null
      : windows.map((w) => w.usedFraction).reduce((a, b) => a > b ? a : b);

  /// The window driving [peakUsedFraction], if any.
  SubscriptionWindow? get peakWindow => windows.isEmpty
      ? null
      : windows.reduce((a, b) => a.usedFraction >= b.usedFraction ? a : b);

  /// The earliest reset across all windows, if any.
  DateTime? get earliestReset {
    DateTime? best;
    for (final w in windows) {
      final r = w.resetsAt;
      if (r != null && (best == null || r.isBefore(best))) {
        best = r;
      }
    }
    return best;
  }

  /// The wire shape.
  Map<String, dynamic> toJson() => {
    'provider_id': providerId,
    'display_name': displayName,
    'status': status.wire,
    'windows': [for (final w in windows) w.toJson()],
    if (error != null) 'error': error,
    if (fetchedAt != null) 'fetched_at': fetchedAt!.toIso8601String(),
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubscriptionUsage &&
          providerId == other.providerId &&
          displayName == other.displayName &&
          status == other.status &&
          error == other.error &&
          fetchedAt == other.fetchedAt &&
          const ListEquality<SubscriptionWindow>().equals(
            windows,
            other.windows,
          );

  @override
  int get hashCode => Object.hash(
    providerId,
    displayName,
    status,
    error,
    fetchedAt,
    const ListEquality<SubscriptionWindow>().hash(windows),
  );
}
