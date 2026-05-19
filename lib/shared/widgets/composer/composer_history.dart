import 'package:flutter/services.dart';

/// Terminal-style prompt recall for the composer: ArrowUp walks backwards
/// through previously sent prompts, ArrowDown forwards, and stepping past the
/// newest restores the draft parked on the first ArrowUp — a shell's up/down
/// history, over a chat draft.
///
/// Pure state machine on purpose: the widget supplies the entry list and the
/// field state at keypress time, so the list is always read live (a prompt
/// landing in the conversation mid-browse is seen without any sync) and the
/// whole behaviour is unit-testable with no widget tree.
///
/// The list is oldest-first; recall starts at its newest entry. Indices are
/// clamped at use time, so a list that grows or shrinks between keypresses
/// can never go out of range.
class ComposerHistory {
  int? _index;
  String? _draft;

  /// Whether an ArrowUp/ArrowDown browse is in progress.
  bool get isBrowsing => _index != null;

  /// Handles ArrowUp. Returns the text the field should now show, or null
  /// when the key belongs to the field — which happens exactly once: entering
  /// a browse while the caret sits BELOW the draft's first line, where
  /// ArrowUp still means "caret up a line" and a multiline draft needs it to.
  ///
  /// On the first line (the common single-line draft included) ArrowUp is
  /// otherwise a no-op, so nothing is lost by making it recall. While
  /// browsing there is no such ambiguity — a shell takes ↑ wherever the
  /// cursor sits.
  String? up(
    List<String> entries, {
    required String text,
    required TextSelection selection,
  }) {
    if (entries.isEmpty) {
      return null;
    }
    if (_index == null) {
      final onFirstLine =
          !selection.isValid ||
          (selection.isCollapsed &&
              !text
                  .substring(0, selection.baseOffset.clamp(0, text.length))
                  .contains('\n'));
      if (!onFirstLine) {
        return null;
      }
      _draft = text;
      _index = entries.length - 1;
    } else if (_index! > 0) {
      _index = _index! - 1;
    }
    return entries[_index!.clamp(0, entries.length - 1)];
  }

  /// Handles ArrowDown. Returns the text the field should now show — the next
  /// entry towards the present, or the parked draft once past the newest —
  /// or null when not browsing (a plain caret-down is never stolen).
  String? down(List<String> entries) {
    final index = _index;
    if (index == null) {
      return null;
    }
    if (index + 1 >= entries.length) {
      return abandon();
    }
    _index = index + 1;
    return entries[index + 1];
  }

  /// Leaves browsing, returning the draft parked on entry (what was being
  /// composed before the first ArrowUp). Null when not browsing.
  String? abandon() {
    final draft = _draft;
    reset();
    return draft;
  }

  /// Drops the browsing position without restoring anything — a sent prompt
  /// is history, not a draft position, so submitting resets to "not
  /// browsing" and the next recall starts from the newest entry again.
  void reset() {
    _index = null;
    _draft = null;
  }
}
