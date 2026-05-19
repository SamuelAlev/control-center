import 'package:cc_domain/cc_domain.dart' show UndoClass;
import 'package:control_center/core/undo/action_journal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// PRD 19 §4/§5: the workspace-wide, per-principal undo/redo journal.
void main() {
  late ProviderContainer container;
  ActionJournal journal() => container.read(actionJournalProvider.notifier);
  ActionJournalState state() => container.read(actionJournalProvider);

  setUp(() => container = ProviderContainer());
  tearDown(() => container.dispose());

  UndoableAction action(
    String label,
    List<String> log, {
    bool failUndo = false,
  }) => UndoableAction(
    label: label,
    undoClass: UndoClass.reversible,
    undo: () async {
      if (failUndo) {
        throw StateError('inverse failed');
      }
      log.add('undo:$label');
    },
    redo: () async => log.add('redo:$label'),
  );

  test('record pushes onto the undo stack', () {
    final log = <String>[];
    expect(state().canUndo, isFalse);
    journal().record(action('a', log));
    expect(state().canUndo, isTrue);
    expect(state().nextUndo?.label, 'a');
  });

  test('undo runs the inverse and moves the action to redo', () async {
    final log = <String>[];
    journal().record(action('a', log));
    final result = await journal().undo();
    expect(result.ok, isTrue);
    expect(result.label, 'a');
    expect(log, ['undo:a']);
    expect(state().canUndo, isFalse);
    expect(state().canRedo, isTrue);
  });

  test('redo re-applies and moves the action back to undo', () async {
    final log = <String>[];
    journal().record(action('a', log));
    await journal().undo();
    final result = await journal().redo();
    expect(result.ok, isTrue);
    expect(log, ['undo:a', 'redo:a']);
    expect(state().canUndo, isTrue);
    expect(state().canRedo, isFalse);
  });

  test('recording a new action clears the redo stack', () async {
    final log = <String>[];
    journal().record(action('a', log));
    await journal().undo();
    expect(state().canRedo, isTrue);
    journal().record(action('b', log));
    expect(state().canRedo, isFalse);
  });

  test('undo pops LIFO across actions', () async {
    final log = <String>[];
    journal()
      ..record(action('a', log))
      ..record(action('b', log));
    await journal().undo();
    await journal().undo();
    expect(log, ['undo:b', 'undo:a']);
  });

  test('a failed inverse restores the action and returns the error', () async {
    final log = <String>[];
    journal().record(action('a', log, failUndo: true));
    final result = await journal().undo();
    expect(result.ok, isFalse);
    expect(result.error, isA<StateError>());
    // The action stays undoable — nothing silently vanished.
    expect(state().canUndo, isTrue);
    expect(state().canRedo, isFalse);
  });

  test('undo on an empty stack is a quiet no-op', () async {
    final result = await journal().undo();
    expect(result.ok, isFalse);
    expect(result.wasEmpty, isTrue);
  });

  test('the stack is bounded to maxEntries', () {
    final log = <String>[];
    for (var i = 0; i < ActionJournal.maxEntries + 25; i++) {
      journal().record(action('a$i', log));
    }
    expect(state().undoStack.length, ActionJournal.maxEntries);
    // The oldest entries were dropped; the newest is on top.
    expect(state().nextUndo?.label, 'a${ActionJournal.maxEntries + 24}');
  });
}
