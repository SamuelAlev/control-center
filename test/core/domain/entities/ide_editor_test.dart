import 'package:cc_domain/core/domain/entities/ide_editor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  IdeEditor createEditor({
    String id = 'vscode',
    String displayName = 'VS Code',
    bool installed = true,
  }) {
    return IdeEditor(
      id: id,
      displayName: displayName,
      installed: installed,
    );
  }

  group('IdeEditor', () {

    group('constructor', () {
      test('creates with all required fields', () {
        final editor = createEditor();
        expect(editor.id, 'vscode');
        expect(editor.displayName, 'VS Code');
        expect(editor.installed, isTrue);
      });

      test('creates with not-installed state', () {
        final editor = createEditor(installed: false);
        expect(editor.installed, isFalse);
      });

      test('asserts id must not be empty', () {
        expect(
          () => IdeEditor(id: '', displayName: 'Empty', installed: false),
          throwsA(isA<AssertionError>()),
        );
      });
    });

    group('== and hashCode', () {
      test('== returns true for identical values', () {
        final a = createEditor();
        final b = createEditor();
        expect(a, equals(b));
      });

      test('== returns true for same instance', () {
        final editor = createEditor();
        expect(editor, equals(editor));
      });

      test('== returns false for different id', () {
        final a = createEditor(id: 'vscode');
        final b = createEditor(id: 'cursor');
        expect(a, isNot(equals(b)));
      });

      test('== returns false for different displayName', () {
        final a = createEditor(displayName: 'VS Code');
        final b = createEditor(displayName: 'Cursor');
        expect(a, isNot(equals(b)));
      });

      test('== returns false for different installed', () {
        final a = createEditor(installed: true);
        final b = createEditor(installed: false);
        expect(a, isNot(equals(b)));
      });

      test('== returns false for non-IdeEditor', () {
        final editor = createEditor();
        expect(editor, isNot(equals('not an editor')));
      });

      test('hashCode matches for equal instances', () {
        final a = createEditor();
        final b = createEditor();
        expect(a.hashCode, equals(b.hashCode));
      });

      test('hashCode differs for different instances', () {
        final a = createEditor(id: 'vscode');
        final b = createEditor(id: 'cursor');
        expect(a.hashCode, isNot(equals(b.hashCode)));
      });
    });

    group('copyWith', () {
      test('returns identical copy with no arguments', () {
        final editor = createEditor();
        final copy = editor.copyWith();
        expect(copy, equals(editor));
        expect(copy.hashCode, equals(editor.hashCode));
      });

      test('updates id', () {
        final editor = createEditor();
        final copy = editor.copyWith(id: 'cursor');
        expect(copy.id, 'cursor');
        expect(copy.displayName, editor.displayName);
      });

      test('updates displayName', () {
        final editor = createEditor();
        final copy = editor.copyWith(displayName: 'Cursor');
        expect(copy.displayName, 'Cursor');
      });

      test('updates installed', () {
        final editor = createEditor(installed: true);
        final copy = editor.copyWith(installed: false);
        expect(copy.installed, isFalse);
      });

      test('does not mutate original', () {
        final editor = createEditor();
        editor.copyWith(displayName: 'Changed');
        expect(editor.displayName, 'VS Code');
      });

      test('chaining copyWith calls', () {
        final editor = createEditor();
        final copy = editor
            .copyWith(id: 'zed')
            .copyWith(installed: false);
        expect(copy.id, 'zed');
        expect(copy.installed, isFalse);
      });
    });

    group('toString', () {
      test('includes all fields', () {
        const editor = IdeEditor(id: 'vscode', displayName: 'VS Code', installed: true);
        final str = editor.toString();
        expect(str, contains('vscode'));
        expect(str, contains('VS Code'));
        expect(str, contains('true'));
        expect(str, startsWith('IdeEditor('));
      });
    });
  });
}
