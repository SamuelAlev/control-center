import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tracks the most-recently-run ⌘K commands (PRD 19 §1: results ranked by
/// recency + context). In-memory and bounded — recency is a session signal,
/// not durable state, so it never touches the server or disk. The omnibox
/// reads [rankOf] to float recents to the top of an empty query and to break
/// score ties on a search.
class CommandRecency extends Notifier<List<String>> {
  /// How many recent command ids to remember.
  static const int maxEntries = 40;

  @override
  List<String> build() => const [];

  /// Records that command [id] was just executed, moving it to the front.
  void touch(String id) {
    final next = [id, ...state.where((e) => e != id)];
    state = next.length > maxEntries ? next.sublist(0, maxEntries) : next;
  }

  /// Recency rank of [id]: `0` = most recent, larger = older,
  /// [double.infinity] = never used (sorts last).
  double rankOf(String id) {
    final i = state.indexOf(id);
    return i < 0 ? double.infinity : i.toDouble();
  }
}

/// The session-scoped command-recency tracker.
final commandRecencyProvider = NotifierProvider<CommandRecency, List<String>>(
  CommandRecency.new,
);
