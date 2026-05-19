import 'package:collection/collection.dart';

/// Whether a provider's live subscription usage could be read.
enum SubscriptionStatus {
  /// Usage was fetched successfully.
  ok,

  /// No credentials / the provider isn't set up on this machine.
  unconfigured,

  /// The provider answered, and the answer is that the plan has nothing left —
  /// credits spent, quota exhausted.
  ///
  /// Deliberately distinct from [error]: nothing is broken and nothing is worth
  /// retrying, so telling the operator "usage unavailable" would send them
  /// looking for a fault that isn't there. What they need to know is that the
  /// plan is spent and they have to top up or wait for the reset.
  exhausted,

  /// The account's access token lapsed but a live refresh token sits beside it,
  /// so the CLI renews it on the next run. Usage is unreadable until something
  /// does — the endpoint takes the bearer as-is and refreshes nothing.
  ///
  /// Informational, NOT a call to action, and that distinction is the whole
  /// reason it is not folded into [signInRequired]: every account nobody used
  /// overnight is in this state by morning, so asking the operator to sign in
  /// each time would train them to ignore the row that genuinely needs it.
  signInExpired,

  /// The account cannot authenticate and nothing on the host can repair it: it
  /// is signed out, a run already observed a 401 on it, or its credential
  /// expired carrying nothing to renew itself with. A human has to sign in
  /// again.
  signInRequired,

  /// A fetch was attempted but failed (network, parse, or CLI error).
  error;

  /// Parses the wire string; an unrecognised value maps to [error].
  ///
  /// The fallback is what keeps a NEW server safe in front of an OLD client:
  /// every value it does not know degrades to [error], which every surface
  /// already renders as "usage unavailable" — a less specific reading, never a
  /// wrong one.
  static SubscriptionStatus fromWire(String? raw) => switch (raw) {
    'ok' => SubscriptionStatus.ok,
    'unconfigured' => SubscriptionStatus.unconfigured,
    'exhausted' => SubscriptionStatus.exhausted,
    'signInExpired' => SubscriptionStatus.signInExpired,
    'signInRequired' => SubscriptionStatus.signInRequired,
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

/// Money spent against a credit cap, for an account billed per token rather
/// than on a plan.
///
/// An enterprise/API seat reports no rolling windows at all — `five_hour` and
/// `seven_day` come back null — and instead reports a dollar balance. Without
/// this the flyout truthfully but uselessly said "no usage reported" for an
/// account that was very much being used; the number the operator wants is
/// "$1.41 of $600".
class SubscriptionSpend {
  /// Creates a [SubscriptionSpend].
  const SubscriptionSpend({
    required this.usedMinor,
    required this.limitMinor,
    required this.currency,
    this.exponent = 2,
  });

  /// Parses the `spend` block, or null when it carries no amounts.
  ///
  /// A PLAN account also has a `spend` key, with null `used`/`limit` — that is
  /// not a zero balance, it is the absence of one, and rendering it as "$0.00
  /// of $0.00" would invent a cap the account does not have.
  static SubscriptionSpend? fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    final used = json['used'];
    final limit = json['limit'];
    if (used is! Map || limit is! Map) {
      return null;
    }
    final usedMinor = (used['amount_minor'] as num?)?.toInt();
    final limitMinor = (limit['amount_minor'] as num?)?.toInt();
    if (usedMinor == null || limitMinor == null) {
      return null;
    }
    return SubscriptionSpend(
      usedMinor: usedMinor,
      limitMinor: limitMinor,
      currency: used['currency'] as String? ?? 'USD',
      exponent: (used['exponent'] as num?)?.toInt() ?? 2,
    );
  }

  /// Amount spent, in the currency's minor unit (cents).
  final int usedMinor;

  /// The cap, in the same minor unit. Zero means "no cap reported".
  final int limitMinor;

  /// ISO currency code, e.g. `USD`.
  final String currency;

  /// Digits after the decimal point for [currency].
  final int exponent;

  /// Spent fraction of the cap, clamped to `[0, 1]`. Zero when there is no cap
  /// — an uncapped balance has no "fraction used" to report.
  double get usedFraction =>
      limitMinor <= 0 ? 0 : (usedMinor / limitMinor).clamp(0.0, 1.0);

  /// Whether there is a cap to be measured against.
  bool get hasLimit => limitMinor > 0;

  /// The amount spent in major units (dollars).
  double get used => usedMinor / _scale;

  /// The cap in major units.
  double get limit => limitMinor / _scale;

  double get _scale {
    var scale = 1.0;
    for (var i = 0; i < exponent; i++) {
      scale *= 10;
    }
    return scale;
  }

  /// The wire shape.
  Map<String, dynamic> toJson() => {
    'used_minor': usedMinor,
    'limit_minor': limitMinor,
    'currency': currency,
    'exponent': exponent,
  };

  /// Reads the wire shape produced by [toJson].
  static SubscriptionSpend? fromWire(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    final used = (json['used_minor'] as num?)?.toInt();
    final limit = (json['limit_minor'] as num?)?.toInt();
    if (used == null || limit == null) {
      return null;
    }
    return SubscriptionSpend(
      usedMinor: used,
      limitMinor: limit,
      currency: json['currency'] as String? ?? 'USD',
      exponent: (json['exponent'] as num?)?.toInt() ?? 2,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubscriptionSpend &&
          usedMinor == other.usedMinor &&
          limitMinor == other.limitMinor &&
          currency == other.currency &&
          exponent == other.exponent;

  @override
  int get hashCode => Object.hash(usedMinor, limitMinor, currency, exponent);
}

/// A live subscription-usage snapshot for one AI coding provider — the
/// "X% used, resets in Y" data behind the title-bar usage pill.
///
/// Built server-side (where the provider CLIs and their credentials live) and
/// relayed to the client over the `subscriptions.usage` RPC op. Each provider
/// degrades independently: a missing credential yields
/// [SubscriptionStatus.unconfigured], a spent plan yields
/// [SubscriptionStatus.exhausted], a failed fetch yields
/// [SubscriptionStatus.error] and none of them blanks out the others.
class SubscriptionUsage {
  /// Creates a [SubscriptionUsage].
  const SubscriptionUsage({
    required this.providerId,
    required this.displayName,
    required this.status,
    this.windows = const [],
    this.error,
    this.fetchedAt,
    this.accountId,
    this.accountLabel,
    this.spend,
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
        accountId: json['account_id'] as String?,
        accountLabel: json['account_label'] as String?,
        spend: SubscriptionSpend.fromWire(
          (json['spend'] as Map?)?.cast<String, dynamic>(),
        ),
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

  /// Which account this snapshot is for, when the provider has more than one.
  ///
  /// Null for a provider whose quota is not per-account (or an install that
  /// manages none), which is what keeps a single-account setup rendering
  /// exactly one block with no account chrome.
  final String? accountId;

  /// Money spent against a credit cap, for an account billed per token rather
  /// than on a plan. Null for a plan account, which reports windows instead.
  final SubscriptionSpend? spend;

  /// How to name that account in one line — its address, plan and org.
  ///
  /// Assembled server-side from what the provider itself reports, so it is not
  /// localized: every part of it is a value handed back verbatim.
  final String? accountLabel;

  /// The most-consumed window's fraction — drives the pill's headline %.
  double? get peakUsedFraction => windows.isEmpty
      ? null
      : windows.map((w) => w.usedFraction).reduce((a, b) => a > b ? a : b);

  /// The window driving [peakUsedFraction], if any.
  SubscriptionWindow? get peakWindow => windows.isEmpty
      ? null
      : windows.reduce((a, b) => a.usedFraction >= b.usedFraction ? a : b);

  /// Returns a copy with the given overrides.
  SubscriptionUsage copyWith({String? accountId, String? accountLabel}) =>
      SubscriptionUsage(
        providerId: providerId,
        displayName: displayName,
        status: status,
        windows: windows,
        error: error,
        fetchedAt: fetchedAt,
        accountId: accountId ?? this.accountId,
        accountLabel: accountLabel ?? this.accountLabel,
        spend: spend,
      );

  /// Whether this snapshot has anything to show — windows, or a spend balance.
  bool get hasReading => windows.isNotEmpty || spend != null;

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
    if (accountId != null) 'account_id': accountId,
    if (accountLabel != null) 'account_label': accountLabel,
    if (spend != null) 'spend': spend!.toJson(),
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
          accountId == other.accountId &&
          accountLabel == other.accountLabel &&
          spend == other.spend &&
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
    accountId,
    accountLabel,
    spend,
    const ListEquality<SubscriptionWindow>().hash(windows),
  );
}
