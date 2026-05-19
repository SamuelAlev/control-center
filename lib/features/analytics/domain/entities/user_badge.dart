
import 'dart:ui';

import 'package:flutter/cupertino.dart' show IconData;

import 'package:flutter/material.dart' show IconData;

import 'package:flutter/widgets.dart' show IconData;

/// Tiers a user can progress through inside a [UserBadgeCategory], inspired
/// by Google Maps Local Guides' level ladder.
enum BadgeTier {
  /// Not yet started — count is 0.
  none,

  /// Lowest tier.
  beginner,

  /// Second tier.
  intermediate,

  /// Third tier.
  advanced,

  /// Fourth tier.
  expert,

  /// Top tier.
  master,
}

/// Human-readable label for [BadgeTier].
extension BadgeTierLabel on BadgeTier {
  /// Display name like "Beginner" or "Locked".
  String get label {
    switch (this) {
      case BadgeTier.none:
        return 'Locked';
      case BadgeTier.beginner:
        return 'Beginner';
      case BadgeTier.intermediate:
        return 'Intermediate';
      case BadgeTier.advanced:
        return 'Advanced';
      case BadgeTier.expert:
        return 'Expert';
      case BadgeTier.master:
        return 'Master';
    }
  }

  /// Tier color used for icons, chips, and accents.
  Color get color {
    switch (this) {
      case BadgeTier.none:
        return const Color(0xFF6B7280);
      case BadgeTier.beginner:
        return const Color(0xFFCD7F32); // bronze
      case BadgeTier.intermediate:
        return const Color(0xFF9CA3AF); // silver
      case BadgeTier.advanced:
        return const Color(0xFFE5B100); // gold
      case BadgeTier.expert:
        return const Color(0xFF10B981); // emerald
      case BadgeTier.master:
        return const Color(0xFFA855F7); // purple
    }
  }

  /// 0-based index of the tier (none = -1, beginner = 0 .. master = 4).
  int get index0 {
    switch (this) {
      case BadgeTier.none:
        return -1;
      case BadgeTier.beginner:
        return 0;
      case BadgeTier.intermediate:
        return 1;
      case BadgeTier.advanced:
        return 2;
      case BadgeTier.expert:
        return 3;
      case BadgeTier.master:
        return 4;
    }
  }
}

/// Definition of one category the user can earn badges in.
class UserBadgeCategory {
  /// Creates a new [UserBadgeCategory].
  const UserBadgeCategory({
    required this.key,
    required this.name,
    required this.iconName,
    required this.unit,
    required this.action,
    required this.thresholds,
    required this.blurb,
  });

  /// Stable identifier (e.g., `prompter`).
  final String key;

  /// Display name (e.g., "Prompter").
  final String name;

  /// Icon identifier shown on the badge (e.g., `'messageSquareCode'`).
  /// Resolve to [IconData] in the presentation layer via
  /// `badgeIconData` from `analytics/presentation/utils/badge_icon_resolver.dart`.
  final String iconName;

  /// Singular unit name (e.g., "prompt", "review").
  final String unit;

  /// Verb-y phrase used in copy (e.g., "Prompt agents", "Review pull requests").
  final String action;

  /// Lower bounds for tiers Beginner..Master. Must have exactly 5 entries
  /// in non-decreasing order. e.g. `[1, 10, 50, 250, 1000]`.
  final List<int> thresholds;

  /// Friendly description shown in the badge detail modal.
  final String blurb;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserBadgeCategory &&
          runtimeType == other.runtimeType &&
          key == other.key &&
          name == other.name &&
          iconName == other.iconName &&
          unit == other.unit &&
          action == other.action &&
          blurb == other.blurb &&
          _listEquals(thresholds, other.thresholds);

  @override
  int get hashCode =>
      Object.hash(key, name, iconName, unit, action, blurb, Object.hashAll(thresholds));

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) {
      return false;
    }
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }
    return true;
  }

  /// Resolve the current tier for the given progress [count].
  BadgeTier tierFor(int count) {
    if (count < thresholds[0]) {
      return BadgeTier.none;
    }
    if (count >= thresholds[4]) {
      return BadgeTier.master;
    }
    if (count >= thresholds[3]) {
      return BadgeTier.expert;
    }
    if (count >= thresholds[2]) {
      return BadgeTier.advanced;
    }
    if (count >= thresholds[1]) {
      return BadgeTier.intermediate;
    }
    return BadgeTier.beginner;
  }

  /// Threshold for the named [tier], or null if [tier] has no requirement
  /// (i.e. [BadgeTier.none]).
  int? thresholdFor(BadgeTier tier) {
    if (tier == BadgeTier.none) {
      return null;
    }
    return thresholds[tier.index0];
  }
}

/// User progress within a single [UserBadgeCategory] at a point in time.
class UserBadge {
  /// Creates a new [UserBadge].
  const UserBadge({required this.category, required this.count});

  /// The category this progress belongs to.
  final UserBadgeCategory category;

  /// Current count of the tracked action.
  final int count;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserBadge &&
          runtimeType == other.runtimeType &&
          category == other.category &&
          count == other.count;

  @override
  int get hashCode => Object.hash(category, count);

  /// The current tier — derived from [count].
  BadgeTier get tier => category.tierFor(count);

  /// The next tier up from [tier], or null if already at master.
  BadgeTier? get nextTier {
    switch (tier) {
      case BadgeTier.none:
        return BadgeTier.beginner;
      case BadgeTier.beginner:
        return BadgeTier.intermediate;
      case BadgeTier.intermediate:
        return BadgeTier.advanced;
      case BadgeTier.advanced:
        return BadgeTier.expert;
      case BadgeTier.expert:
        return BadgeTier.master;
      case BadgeTier.master:
        return null;
    }
  }

  /// How many more actions needed to reach the next tier (0 if maxed).
  int get countToNext {
    final next = nextTier;
    if (next == null) {
      return 0;
    }
    return (category.thresholdFor(next)! - count).clamp(0, 1 << 31);
  }

  /// Linear progress within the current tier (0..1). Returns 1.0 at master.
  double get progressToNext {
    final next = nextTier;
    if (next == null) {
      return 1.0;
    }
    final start = category.thresholdFor(tier) ?? 0;
    final end = category.thresholdFor(next)!;
    if (end <= start) {
      return 1.0;
    }
    final p = (count - start) / (end - start);
    return p.clamp(0.0, 1.0);
  }
}

/// All categories the user can earn badges in. Tier thresholds are tuned
/// to feel rewarding early (so a fresh install gets at least one badge)
/// while still leaving room to grow for power users.
const userBadgeCategories = <UserBadgeCategory>[
  UserBadgeCategory(
    key: 'prompter',
    name: 'Prompter',
    iconName: 'messageSquareCode',
    unit: 'prompt',
    action: 'Prompt your agents',
    thresholds: [1, 25, 100, 500, 2500],
    blurb:
        'Every time you send an agent off to work, you climb the Prompter ladder. '
        'Power users live here.',
  ),
  UserBadgeCategory(
    key: 'reviewer',
    name: 'Reviewer',
    iconName: 'scanEye',
    unit: 'review',
    action: 'Review pull requests',
    thresholds: [1, 5, 25, 100, 500],
    blurb:
        'Reviews keep the codebase honest. Every PR you sign off — or push back '
        'on — counts toward your Reviewer rank.',
  ),
  UserBadgeCategory(
    key: 'shipper',
    name: 'Shipper',
    iconName: 'rocket',
    unit: 'merge',
    action: 'Merge pull requests',
    thresholds: [1, 10, 50, 200, 1000],
    blurb:
        'Code that ships is the only code that matters. Track every PR that '
        'made it to main.',
  ),
  UserBadgeCategory(
    key: 'mentor',
    name: 'Mentor',
    iconName: 'lightbulb',
    unit: 'callout',
    action: 'Leave blocking review feedback',
    thresholds: [1, 5, 25, 100, 500],
    blurb:
        'Catch the bug before it ships. Every blocking comment you leave on a '
        'review counts as a teaching moment.',
  ),
  UserBadgeCategory(
    key: 'explorer',
    name: 'Explorer',
    iconName: 'compass',
    unit: 'workspace',
    action: 'Spin up new workspaces',
    thresholds: [1, 3, 7, 15, 30],
    blurb:
        'Different projects, different contexts. Climb the Explorer ladder by '
        'managing more workspaces.',
  ),
];
