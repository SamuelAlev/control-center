import 'package:cc_harness/tools.dart';
import 'package:test/test.dart';

StagedFileEdit file(String path, String before, String after, [int n = 1]) =>
    StagedFileEdit(
      path: path,
      before: before,
      after: after,
      replacements: n,
    );

void main() {
  group('StagedEditStore', () {
    test('staging returns a stable, monotonic id', () {
      // Replayed sessions have to produce the same ids: the id goes into a
      // tool result the model reads back and later names.
      final a = StagedEditStore();
      final b = StagedEditStore();
      final first = a.stage(tool: 't', summary: 's', files: [file('/a', '1', '2')]);
      final second = a.stage(tool: 't', summary: 's', files: [file('/b', '1', '2')]);
      expect(first.id, 'edit_1');
      expect(second.id, 'edit_2');
      expect(
        b.stage(tool: 't', summary: 's', files: [file('/a', '1', '2')]).id,
        'edit_1',
      );
    });

    test('take removes, so a change cannot be committed twice', () {
      final store = StagedEditStore();
      final staged = store.stage(
        tool: 't',
        summary: 's',
        files: [file('/a', '1', '2')],
      );
      expect(store.take(staged.id), isNotNull);
      expect(store.take(staged.id), isNull);
    });

    test('evicts the oldest past capacity', () {
      final store = StagedEditStore(capacity: 2);
      final first = store.stage(tool: 't', summary: 's', files: []);
      store.stage(tool: 't', summary: 's', files: []);
      store.stage(tool: 't', summary: 's', files: []);
      expect(store.peek(first.id), isNull);
      expect(store.pending, hasLength(2));
    });

    test('validate accepts an untouched change', () {
      final store = StagedEditStore();
      final staged = store.stage(
        tool: 't',
        summary: 's',
        files: [file('/a', 'old', 'new')],
      );
      expect(store.validate(staged.id, (_) => 'old'), isNull);
    });

    test('validate refuses when a file moved underneath', () {
      // The bug this prevents: a staged rewrite committed after the agent
      // hand-edited one of its files silently discards the hand edit.
      final store = StagedEditStore();
      final staged = store.stage(
        tool: 't',
        summary: 's',
        files: [file('/a', 'old', 'new')],
      );
      expect(
        store.validate(staged.id, (_) => 'somebody else wrote this'),
        StagedEditRejection.stale,
      );
    });

    test('validate refuses when a file was deleted', () {
      final store = StagedEditStore();
      final staged = store.stage(
        tool: 't',
        summary: 's',
        files: [file('/a', 'old', 'new')],
      );
      expect(store.validate(staged.id, (_) => null), StagedEditRejection.stale);
    });

    test('validate reports an unknown id distinctly from a stale one', () {
      expect(
        StagedEditStore().validate('nope', (_) => 'x'),
        StagedEditRejection.unknown,
      );
    });

    test('counts replacements across files', () {
      final store = StagedEditStore();
      final staged = store.stage(
        tool: 't',
        summary: 's',
        files: [file('/a', '1', '2', 3), file('/b', '1', '2', 4)],
      );
      expect(staged.replacements, 7);
    });
  });

  group('describeStagedEdit', () {
    test('says nothing was written and names the commit call', () {
      final store = StagedEditStore();
      final staged = store.stage(
        tool: 'ast_edit',
        summary: 'replace print with log',
        files: [file('/a.dart', '1', '2', 2)],
      );
      final text = describeStagedEdit(staged);
      expect(text, startsWith('(proposed) replace print with log'));
      expect(text, contains('2 replacements in 1 file'));
      expect(text, contains('/a.dart (2)'));
      expect(text, contains('Nothing has been written'));
      expect(text, contains('edit_1'));
    });

    test('truncates a long file list rather than dumping it', () {
      final store = StagedEditStore();
      final staged = store.stage(
        tool: 't',
        summary: 's',
        files: [for (var i = 0; i < 30; i++) file('/f$i', '1', '2')],
      );
      final text = describeStagedEdit(staged, maxFiles: 5);
      expect(text, contains('… 25 more'));
      expect('\n'.allMatches(text).length, lessThan(12));
    });

    test('singularizes one replacement in one file', () {
      final store = StagedEditStore();
      final staged = store.stage(
        tool: 't',
        summary: 's',
        files: [file('/a', '1', '2')],
      );
      expect(describeStagedEdit(staged), contains('1 replacement in 1 file:'));
    });
  });
}
