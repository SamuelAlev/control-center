import 'package:cc_domain/features/code_mode/domain/services/script_identifiers.dart';
import 'package:test/test.dart';

void main() {
  group('baseIdentifier', () {
    test('keeps valid identifiers', () {
      expect(ScriptIdentifierMap.baseIdentifier('search'), 'search');
      expect(ScriptIdentifierMap.baseIdentifier(r'$x_1'), r'$x_1');
      expect(
        ScriptIdentifierMap.baseIdentifier('mcp__github__list_issues'),
        'mcp__github__list_issues',
      );
    });

    test('replaces invalid characters with underscores', () {
      expect(ScriptIdentifierMap.baseIdentifier('list-issues'), 'list_issues');
      expect(ScriptIdentifierMap.baseIdentifier('a.b c'), 'a_b_c');
    });

    test('replaces non-ASCII letters too', () {
      expect(ScriptIdentifierMap.baseIdentifier('café'), 'caf_');
      expect(ScriptIdentifierMap.baseIdentifier('工具'), '__');
      expect(ScriptIdentifierMap.baseIdentifier('😀'), '__');
    });

    test('an empty name becomes an underscore', () {
      expect(ScriptIdentifierMap.baseIdentifier(''), '_');
    });

    test('guards a leading digit, reserved words and prototype names', () {
      expect(ScriptIdentifierMap.baseIdentifier('2fa'), '_2fa');
      for (final word in ['class', 'delete', 'await', 'yield', 'let']) {
        expect(ScriptIdentifierMap.baseIdentifier(word), '_$word');
      }
      for (final name in [
        '__proto__',
        'constructor',
        'prototype',
        'then',
        'toString',
        'toJSON',
        'hasOwnProperty',
      ]) {
        expect(ScriptIdentifierMap.baseIdentifier(name), '_$name');
      }
      expect(ScriptIdentifierMap.isSafeIdentifier('class'), isFalse);
      expect(ScriptIdentifierMap.isSafeIdentifier('read'), isTrue);
    });
  });

  group('ScriptIdentifierMap.build', () {
    test('an exact identifier keeps its spelling over a sanitised twin', () {
      final m = ScriptIdentifierMap.build(['a-b', 'a_b']);
      expect(m.idFor('a_b'), 'a_b');
      expect(m.idFor('a-b'), 'a_b_2');
    });

    test('collisions get numeric suffixes by sorted raw name', () {
      final m = ScriptIdentifierMap.build(['x.y', 'x-y', 'x y']);
      // Sorted: 'x y' (0x20) < 'x-y' (0x2D) < 'x.y' (0x2E).
      expect(m.idFor('x y'), 'x_y');
      expect(m.idFor('x-y'), 'x_y_2');
      expect(m.idFor('x.y'), 'x_y_3');
    });

    test('a suffix never takes a name that is already an identifier', () {
      final m = ScriptIdentifierMap.build(['x-y', 'x_y', 'x_y_2']);
      expect(m.idFor('x_y'), 'x_y');
      expect(m.idFor('x_y_2'), 'x_y_2');
      expect(m.idFor('x-y'), 'x_y_3');
    });

    test('is independent of input order', () {
      final names = [
        'a-b',
        'a_b',
        '__proto__',
        '_proto',
        'class',
        '_class',
        '2fa',
        '',
        'x.y',
        'x_y',
        'café',
        'caf_',
      ];
      final forward = ScriptIdentifierMap.build(names).idByName;
      final backward = ScriptIdentifierMap.build(names.reversed).idByName;
      final shuffled = ScriptIdentifierMap.build([
        ...names.skip(5),
        ...names.take(5),
      ]).idByName;
      expect(backward, forward);
      expect(shuffled, forward);
    });

    test('a guarded name never collides with its underscored spelling', () {
      final m = ScriptIdentifierMap.build(['class', '_class']);
      expect(m.idFor('_class'), '_class');
      expect(m.idFor('class'), '_class_2');
    });

    test('keeps both directions and resolves either spelling', () {
      final m = ScriptIdentifierMap.build(['list-issues', 'read', 'read']);
      expect(m.length, 2);
      expect(m.nameFor('list_issues'), 'list-issues');
      expect(m.resolve('list-issues'), 'list-issues');
      expect(m.resolve('list_issues'), 'list-issues');
      expect(m.resolve('read'), 'read');
      expect(m.resolve('nope'), isNull);
      expect(m.names, ['list-issues', 'read']);
      expect(m.identifiers, ['list_issues', 'read']);
    });

    test('every identifier is unique and safe', () {
      final names = [
        for (var i = 0; i < 50; i++) 'tool-$i',
        for (var i = 0; i < 50; i++) 'tool_$i',
        'constructor',
        '_constructor',
        '__proto__',
        'then',
      ];
      final m = ScriptIdentifierMap.build(names);
      expect(m.identifiers.toSet().length, names.length);
      for (final id in m.identifiers) {
        expect(ScriptIdentifierMap.isSafeIdentifier(id), isTrue, reason: id);
      }
    });
  });
}
