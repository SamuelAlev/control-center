/// Built-in notification sounds.
///
/// Each value maps to an MP3 asset bundled under `assets/sounds/`.
/// The [none] variant silences the notification sound entirely.
///
/// Sounds are organized in groups for the settings UI. Use [group] to
/// build grouped dropdown menus.
enum NotificationSound {
  // ── Standard ─────────────────────────────────────────────────────────

  /// No sound.
  none('none', null, standardGroup),

  /// Short clean sine-wave ping.
  ping('ping', 'sounds/ping.mp3', standardGroup),

  /// Two-tone ascending chime.
  chime('chime', 'sounds/chime.mp3', standardGroup),

  /// Short filtered noise burst.
  pop('pop', 'sounds/pop.mp3', standardGroup),

  /// Longer sustained bell-like tone.
  ding('ding', 'sounds/ding.mp3', standardGroup),

  /// Swept tone.
  whoosh('whoosh', 'sounds/whoosh.mp3', standardGroup),

  // ── Schwiizer Tönli ──────────────────────────────────────────────────

  /// Migros jingle (soft).
  migrosSoft('migros-soft', 'sounds/migros-soft.mp3', swissGroup),

  /// Migros jingle (hard).
  migrosHard('migros-hard', 'sounds/migros-hard.mp3', swissGroup),

  /// SBB (Schweizerische Bundesbahnen) chime.
  sbb('sbb', 'sounds/sbb.mp3', swissGroup),

  /// CFF (Chemins de fer fédéraux) chime.
  cff('cff', 'sounds/cff.mp3', swissGroup),

  /// FFS (Ferrovie federali svizzere) chime.
  ffs('ffs', 'sounds/ffs.mp3', swissGroup),

  /// PostAuto horn.
  post('post', 'sounds/post.mp3', swissGroup),
  ;

  /// Creates a [NotificationSound] with the given properties.
  const NotificationSound(this.name, this.assetPath, this.group);

  /// Group label for standard notification sounds.
  static const standardGroup = 'Standard';

  /// Group label for Schwiizer Tönli.
  static const swissGroup = 'Schwiizer Tönli';

  /// Persistent storage key.
  final String name;

  /// Path to the sound asset (relative to the assets root), or `null` for [none].
  final String? assetPath;

  /// Group label for the settings dropdown.
  final String group;

  /// Returns the unique group labels in enum declaration order.
  static List<String> get groups {
    final seen = <String>[];
    for (final s in values) {
      if (!seen.contains(s.group)) {
        seen.add(s.group);
      }
    }
    return seen;
  }

  /// Returns all sounds belonging to [group].
  static List<NotificationSound> forGroup(String group) =>
      values.where((s) => s.group == group).toList();

  /// Parses a stored [name] back to a [NotificationSound].
  /// Returns [ping] for unknown values.
  static NotificationSound fromName(String? name) {
    if (name == null) {
      return NotificationSound.ping;
    }
    return NotificationSound.values.firstWhere(
      (s) => s.name == name,
      orElse: () => NotificationSound.ping,
    );
  }
}
