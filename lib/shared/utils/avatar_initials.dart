// `characters` (grapheme-cluster safe indexing) comes from flutter/widgets.
import 'package:flutter/widgets.dart';

/// Initials for an avatar fallback: `Samuel Alev` → `SA`, `Google` → `Go`,
/// empty/whitespace → `?`.
///
/// One helper for every surface that renders an avatar from a name (roster,
/// presence, attendees, team pickers, tickets, feeds). Five hand-rolled copies
/// used to disagree on the edge cases — one letter vs two, `?` vs an empty
/// string, `substring(0, 1)` (which splits a grapheme cluster and can render a
/// broken glyph for an emoji or combining accent) vs `characters`.
///
/// [maxLetters] caps the result (pass 1 for very small avatars).
String avatarInitials(String name, {int maxLetters = 2}) {
  assert(maxLetters >= 1, 'maxLetters must be at least 1');
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((p) => p.isNotEmpty)
      .toList();
  if (parts.isEmpty) {
    return '?';
  }
  if (parts.length == 1 || maxLetters == 1) {
    return parts.first.characters.take(maxLetters).toString().toUpperCase();
  }
  return (parts.first.characters.first + parts.last.characters.first)
      .toUpperCase();
}
