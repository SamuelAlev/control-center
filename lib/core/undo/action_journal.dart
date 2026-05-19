import 'package:cc_domain/cc_domain.dart' show UndoClass;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Performs one direction of a reversible action (its inverse, or the re-apply).
/// Runs as a normal mutation — it rides the same idempotency + sync path as any
/// other write (PRD 19 clarification), so it must mint its OWN fresh
/// idempotency key.
typedef ActionInverse = Future<void> Function();

/// One entry in the [ActionJournal] — a mutation the local principal performed
/// that can be reversed (PRD 19 §5). Holds closures rather than data so the
/// journal stays feature-agnostic: tickets, messages, todos and plans all
/// contribute the same shape.
@immutable
class UndoableAction {
  /// Creates an [UndoableAction].
  const UndoableAction({
    required this.label,
    required this.undoClass,
    required this.undo,
    required this.redo,
  }) : assert(
         undoClass != UndoClass.irreversible,
         'irreversible actions never enter the undo stack',
       );

  /// Human label for the undo/redo toast ("Ticket priority").
  final String label;

  /// [UndoClass.reversible] or [UndoClass.compensable] (never irreversible).
  final UndoClass undoClass;

  /// Reverses the action (restore prior state, or the compensating action).
  final ActionInverse undo;

  /// Re-applies the action after an undo.
  final ActionInverse redo;
}

/// Immutable undo/redo stacks.
@immutable
class ActionJournalState {
  /// Creates an [ActionJournalState].
  const ActionJournalState({
    this.undoStack = const [],
    this.redoStack = const [],
  });

  /// Actions available to undo (most recent last).
  final List<UndoableAction> undoStack;

  /// Actions undone and available to redo (most recent last).
  final List<UndoableAction> redoStack;

  /// Whether `⌘Z` has anything to do.
  bool get canUndo => undoStack.isNotEmpty;

  /// Whether `⌘⇧Z` has anything to do.
  bool get canRedo => redoStack.isNotEmpty;

  /// The action `⌘Z` would reverse next (null when the stack is empty).
  UndoableAction? get nextUndo => undoStack.isEmpty ? null : undoStack.last;

  /// The action `⌘⇧Z` would re-apply next.
  UndoableAction? get nextRedo => redoStack.isEmpty ? null : redoStack.last;
}

/// The outcome of an [ActionJournal.undo]/[ActionJournal.redo].
class ActionJournalResult {
  /// Creates an [ActionJournalResult].
  const ActionJournalResult({required this.ok, this.label, this.error});

  /// Nothing to do — the relevant stack was empty.
  static const empty = ActionJournalResult(ok: false);

  /// Whether the inverse applied successfully.
  final bool ok;

  /// The reversed/reapplied action's label (for the toast).
  final String? label;

  /// The failure, when [ok] is false and an inverse threw.
  final Object? error;

  /// True when the stack was empty (as opposed to a failed inverse).
  bool get wasEmpty => !ok && error == null && label == null;
}

/// The workspace-wide, per-principal undo/redo journal (PRD 19 §4/§5).
///
/// The client records only the LOCAL principal's reversible actions, so `⌘Z`
/// pops *your own* most recent action by construction (multiplayer-safe; solo
/// behaviour is unchanged). Inverse ops run through the normal mutation path
/// with fresh idempotency keys — no privileged replication.
class ActionJournal extends Notifier<ActionJournalState> {
  /// Bound on the stack depth (a session signal, not durable state).
  static const int maxEntries = 100;

  @override
  ActionJournalState build() => const ActionJournalState();

  /// Records a freshly-applied reversible action, clearing the redo stack
  /// (a new action invalidates any redo history — standard undo semantics).
  void record(UndoableAction action) {
    final undo = [...state.undoStack, action];
    final capped = undo.length > maxEntries
        ? undo.sublist(undo.length - maxEntries)
        : undo;
    state = ActionJournalState(undoStack: capped);
  }

  /// Reverses the most recent action and moves it to the redo stack.
  ///
  /// The action is popped optimistically so a second `⌘Z` targets the prior
  /// action even while this inverse is in flight; on failure it is restored to
  /// the undo stack and the error is returned for the caller to surface loudly
  /// (immediacy never trades against truth — PRD 19 adversarial review).
  Future<ActionJournalResult> undo() async {
    if (state.undoStack.isEmpty) {
      return ActionJournalResult.empty;
    }
    final action = state.undoStack.last;
    state = ActionJournalState(
      undoStack: state.undoStack.sublist(0, state.undoStack.length - 1),
      redoStack: state.redoStack,
    );
    try {
      await action.undo();
      state = ActionJournalState(
        undoStack: state.undoStack,
        redoStack: [...state.redoStack, action],
      );
      return ActionJournalResult(ok: true, label: action.label);
    } catch (e) {
      state = ActionJournalState(
        undoStack: [...state.undoStack, action],
        redoStack: state.redoStack,
      );
      return ActionJournalResult(ok: false, label: action.label, error: e);
    }
  }

  /// Re-applies the most recently undone action and moves it back to undo.
  Future<ActionJournalResult> redo() async {
    if (state.redoStack.isEmpty) {
      return ActionJournalResult.empty;
    }
    final action = state.redoStack.last;
    state = ActionJournalState(
      undoStack: state.undoStack,
      redoStack: state.redoStack.sublist(0, state.redoStack.length - 1),
    );
    try {
      await action.redo();
      state = ActionJournalState(
        undoStack: [...state.undoStack, action],
        redoStack: state.redoStack,
      );
      return ActionJournalResult(ok: true, label: action.label);
    } catch (e) {
      state = ActionJournalState(
        undoStack: state.undoStack,
        redoStack: [...state.redoStack, action],
      );
      return ActionJournalResult(ok: false, label: action.label, error: e);
    }
  }

  /// Drops all history (e.g. on workspace switch — another workspace's edits
  /// are not yours to undo here).
  void clear() => state = const ActionJournalState();
}

/// The session-scoped action journal.
final actionJournalProvider =
    NotifierProvider<ActionJournal, ActionJournalState>(ActionJournal.new);
