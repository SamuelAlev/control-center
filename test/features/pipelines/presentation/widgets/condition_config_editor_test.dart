import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pipelines/presentation/widgets/condition_config_editor.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

/// Wraps [child] with the minimal Material + FTheme + l10n shell.
Widget _wrap(Widget child) {
  return MaterialApp(
    localizationsDelegates: const [
      ...AppLocalizations.localizationsDelegates,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: CcTheme(
      data: CcThemeData.light(),
      child: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );
}

/// Enters text into an [CcTextField] whose label contains [labelText] by
/// finding its inner [EditableText] and using the test IME.
Future<void> _enterFTextField(
  WidgetTester tester,
  String labelText,
  String text,
) async {
  final ftf = find.ancestor(
    of: find.textContaining(labelText),
    matching: find.byType(CcTextField),
  );
  final editable = find.descendant(
    of: ftf,
    matching: find.byType(EditableText),
  );
  await tester.showKeyboard(editable);
  tester.testTextInput.updateEditingValue(
    TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    ),
  );
  await tester.pump();
}

/// Pumps a [ConditionConfigEditor] with the given [extras] and an `onChanged`
/// that records every emitted map into [captured].
Future<void> _pumpEditor(
  WidgetTester tester, {
  Map<String, dynamic> extras = const <String, dynamic>{},
  List<Map<String, dynamic>>? captured,
}) async {
  await tester.pumpWidget(_wrap(ConditionConfigEditor(
    extras: extras,
    onChanged: (e) => captured?.add(Map<String, dynamic>.from(e)),
  )));
  await tester.pump();
}

void main() {
  group('ConditionConfigEditor', () {
    // ── Default / empty extras → comparison mode ──────────────────────

    testWidgets('empty extras defaults to comparison mode', (tester) async {
      await _pumpEditor(tester);
      expect(find.textContaining('Left value'), findsOneWidget);
      expect(find.textContaining('Right value'), findsOneWidget);
      expect(find.textContaining('Operator'), findsOneWidget);
    });

    testWidgets('comparison mode has no checkboxes', (tester) async {
      await _pumpEditor(tester);
      expect(find.byType(CcCheckbox), findsNothing);
    });

    // ── FilesAny hydration ────────────────────────────────────────────

    testWidgets('filesAny renders file path and base directory fields',
        (tester) async {
      await _pumpEditor(tester, extras: {
        'predicate': {
          'type': 'fileExists',
          'paths': ['Cargo.toml'],
          'baseKey': 'repoLocalPath',
        },
      });
      expect(find.textContaining('File path'), findsOneWidget);
      expect(find.textContaining('Base directory'), findsOneWidget);
      expect(find.textContaining('Left value'), findsNothing);
    });

    testWidgets('filesAny renders two checkboxes (recursive + negate)',
        (tester) async {
      await _pumpEditor(tester, extras: {
        'predicate': {
          'type': 'fileExists',
          'paths': ['a.txt'],
          'baseKey': 'repoLocalPath',
        },
      });
      expect(find.byType(CcCheckbox), findsNWidgets(2));
    });

    testWidgets('filesAny negate flag appears in emitted predicate',
        (tester) async {
      final captured = <Map<String, dynamic>>[];
      await _pumpEditor(tester, extras: {
        'predicate': {
          'type': 'fileExists',
          'paths': ['a.txt'],
          'baseKey': 'repoLocalPath',
          'negate': true,
        },
      }, captured: captured);
      await _enterFTextField(tester, 'File path', 'b.txt');
      await tester.pump();

      expect(captured.isNotEmpty, isTrue);
      final last = captured.last;
      final p = last['predicate'] as Map;
      expect(p['negate'], true);
    });

    testWidgets('filesAny recursive flag appears in emitted predicate',
        (tester) async {
      final captured = <Map<String, dynamic>>[];
      await _pumpEditor(tester, extras: {
        'predicate': {
          'type': 'fileExists',
          'paths': ['a.txt'],
          'baseKey': 'repoLocalPath',
          'recursive': true,
        },
      }, captured: captured);
      await _enterFTextField(tester, 'File path', 'b.txt');
      await tester.pump();

      expect(captured.isNotEmpty, isTrue);
      final last = captured.last;
      final p = last['predicate'] as Map;
      expect(p['recursive'], true);
    });

    testWidgets('filesAny: negate and recursive absent when false',
        (tester) async {
      final captured = <Map<String, dynamic>>[];
      await _pumpEditor(tester, extras: {
        'predicate': {
          'type': 'fileExists',
          'paths': ['a.txt'],
          'baseKey': 'repoLocalPath',
        },
      }, captured: captured);
      await _enterFTextField(tester, 'File path', 'b.txt');
      await tester.pump();

      final last = captured.last;
      final p = last['predicate'] as Map;
      expect(p.containsKey('negate'), isFalse);
      expect(p.containsKey('recursive'), isFalse);
    });

    testWidgets('filesAny emits correct predicate shape', (tester) async {
      final captured = <Map<String, dynamic>>[];
      await _pumpEditor(tester, extras: {
        'predicate': {
          'type': 'fileExists',
          'paths': ['Cargo.toml'],
          'baseKey': 'repoLocalPath',
        },
      }, captured: captured);
      await _enterFTextField(tester, 'File path', 'new.txt');
      await tester.pump();

      final last = captured.last;
      final p = last['predicate'] as Map;
      expect(p['type'], 'fileExists');
      expect(p['paths'], isA<List>());
      expect(p['baseKey'], 'repoLocalPath');
    });

    // ── FilesAll hydration ────────────────────────────────────────────

    testWidgets('filesAll renders file path and base directory fields',
        (tester) async {
      await _pumpEditor(tester, extras: {
        'predicate': {
          'type': 'and',
          'of': [
            {
              'type': 'fileExists',
              'paths': ['Cargo.toml'],
              'baseKey': 'repoLocalPath',
            },
          ],
        },
      });
      expect(find.textContaining('File path'), findsOneWidget);
      expect(find.textContaining('Base directory'), findsOneWidget);
    });

    testWidgets('filesAll: only one checkbox (recursive, no negate)',
        (tester) async {
      await _pumpEditor(tester, extras: {
        'predicate': {
          'type': 'and',
          'of': [
            {
              'type': 'fileExists',
              'paths': ['a.txt'],
              'baseKey': 'repoLocalPath',
            },
          ],
        },
      });
      expect(find.byType(CcCheckbox), findsOneWidget);
    });

    testWidgets('filesAll emits "and" predicate shape', (tester) async {
      final captured = <Map<String, dynamic>>[];
      await _pumpEditor(tester, extras: {
        'predicate': {
          'type': 'and',
          'of': [
            {
              'type': 'fileExists',
              'paths': ['Cargo.toml'],
              'baseKey': 'repoLocalPath',
            },
          ],
        },
      }, captured: captured);
      await _enterFTextField(tester, 'File path', 'new.txt');
      await tester.pump();

      final last = captured.last;
      final p = last['predicate'] as Map;
      expect(p['type'], 'and');
      expect(p['of'], isA<List>());
      final of = p['of'] as List;
      expect(of, isNotEmpty);
      expect((of.first as Map)['type'], 'fileExists');
    });

    testWidgets('filesAll emits one fileExists per path', (tester) async {
      final captured = <Map<String, dynamic>>[];
      await _pumpEditor(tester, extras: {
        'predicate': {
          'type': 'and',
          'of': [
            {
              'type': 'fileExists',
              'paths': ['a.txt'],
              'baseKey': 'repoLocalPath',
            },
          ],
        },
      }, captured: captured);
      await _enterFTextField(tester, 'File path', 'x.txt\ny.txt');
      await tester.pump();

      final last = captured.last;
      final p = last['predicate'] as Map;
      expect(p['type'], 'and');
      final of = p['of'] as List;
      expect(of.length, 2);
      for (final entry in of) {
        expect((entry as Map)['type'], 'fileExists');
      }
    });

    // ── Or-group flattening ───────────────────────────────────────────

    testWidgets('or-group hydrates as filesAny mode', (tester) async {
      await _pumpEditor(tester, extras: {
        'predicate': {
          'type': 'or',
          'of': [
            {
              'type': 'fileExists',
              'paths': ['Cargo.toml'],
              'baseKey': 'repoLocalPath',
            },
            {
              'type': 'fileExists',
              'paths': ['Makefile'],
              'baseKey': 'repoLocalPath',
            },
          ],
        },
      });
      expect(find.textContaining('File path'), findsOneWidget);
    });

    testWidgets('or-group sets negate=false in hydrate', (tester) async {
      final captured = <Map<String, dynamic>>[];
      await _pumpEditor(tester, extras: {
        'predicate': {
          'type': 'or',
          'of': [
            {
              'type': 'fileExists',
              'paths': ['Cargo.toml'],
              'baseKey': 'repoLocalPath',
            },
          ],
        },
      }, captured: captured);
      await _enterFTextField(tester, 'File path', 'new.txt');
      await tester.pump();

      final last = captured.last;
      final p = last['predicate'] as Map;
      expect(p.containsKey('negate'), isFalse);
    });

    // ── Comparison hydration ──────────────────────────────────────────

    testWidgets('comparison renders left/op/right', (tester) async {
      await _pumpEditor(tester, extras: {
        'predicate': {
          'type': 'comparison',
          'left': '{{score}}',
          'op': 'gt',
          'right': '80',
        },
      });
      expect(find.textContaining('Left value'), findsOneWidget);
      expect(find.textContaining('Operator'), findsOneWidget);
      expect(find.textContaining('Right value'), findsOneWidget);
    });

    testWidgets('comparison emits comparison predicate', (tester) async {
      final captured = <Map<String, dynamic>>[];
      await _pumpEditor(tester, extras: {
        'predicate': {
          'type': 'comparison',
          'left': '{{score}}',
          'op': 'exists',
          'right': '',
        },
      }, captured: captured);
      await _enterFTextField(tester, 'Left value', '{{new}}');
      await tester.pump();

      final last = captured.last;
      final p = last['predicate'] as Map;
      expect(p['type'], 'comparison');
      expect(p['left'], '{{new}}');
      expect(p.containsKey('op'), isTrue);
      expect(p.containsKey('right'), isTrue);
    });

    testWidgets('legacy comparison (top-level left/op/right)', (tester) async {
      await _pumpEditor(tester, extras: {
        'left': '{{value}}',
        'op': 'lt',
        'right': '50',
      });
      expect(find.textContaining('Left value'), findsOneWidget);
      expect(find.textContaining('Right value'), findsOneWidget);
    });

    // ── SwitchOn hydration ────────────────────────────────────────────

    testWidgets('switchOn renders switch key, cases, default fields',
        (tester) async {
      await _pumpEditor(tester, extras: {
        'switchKey': 'prClass',
        'cases': ['docs', 'security'],
        'default': 'standard',
      });
      expect(find.textContaining('Switch on state'), findsOneWidget);
      expect(find.textContaining('Cases'), findsOneWidget);
      expect(find.textContaining('Default case'), findsOneWidget);
    });

    testWidgets('switchOn: no checkboxes', (tester) async {
      await _pumpEditor(tester, extras: {
        'switchKey': 'prClass',
        'cases': ['docs'],
      });
      expect(find.byType(CcCheckbox), findsNothing);
    });

    testWidgets('switchOn emits switchKey/cases/default', (tester) async {
      final captured = <Map<String, dynamic>>[];
      await _pumpEditor(tester, extras: {
        'switchKey': 'prClass',
        'cases': ['docs'],
        'default': 'standard',
      }, captured: captured);
      await _enterFTextField(tester, 'Switch on state', 'newKey');
      await tester.pump();

      final last = captured.last;
      expect(last['switchKey'], isNotNull);
      expect(last['cases'], isA<List>());
      expect(last['default'], 'standard');
    });

    testWidgets('switchOn omits default when empty', (tester) async {
      final captured = <Map<String, dynamic>>[];
      await _pumpEditor(tester, extras: {
        'switchKey': 'prClass',
        'cases': ['docs'],
      }, captured: captured);
      await _enterFTextField(tester, 'Switch on state', 'newKey');
      await tester.pump();

      final last = captured.last;
      expect(last.containsKey('default'), isFalse);
    });

    // ── Unknown predicate type ────────────────────────────────────────

    testWidgets('unknown predicate type falls back to filesAny',
        (tester) async {
      await _pumpEditor(tester, extras: {
        'predicate': {
          'type': 'bogusType',
          'paths': ['hello.txt'],
          'baseKey': 'custom',
        },
      });
      expect(find.textContaining('File path'), findsOneWidget);
    });

    // ── Extras preservation ───────────────────────────────────────────

    testWidgets('non-condition extras survive emit', (tester) async {
      final captured = <Map<String, dynamic>>[];
      await _pumpEditor(tester, extras: {
        'predicate': {'type': 'fileExists', 'paths': ['a.txt']},
        'idempotent': 'abc-123',
        'customKey': 42,
      }, captured: captured);
      await _enterFTextField(tester, 'File path', 'new.txt');
      await tester.pump();

      final last = captured.last;
      expect(last['idempotent'], 'abc-123');
      expect(last['customKey'], 42);
      expect(last['predicate'], isA<Map>());
    });

    testWidgets('old condition keys are stripped on emit', (tester) async {
      final captured = <Map<String, dynamic>>[];
      await _pumpEditor(tester, extras: {
        'predicate': {'type': 'fileExists', 'paths': ['a.txt']},
        'switchKey': 'oldKey',
        'left': 'oldLeft',
        'op': 'oldOp',
        'right': 'oldRight',
      }, captured: captured);
      await _enterFTextField(tester, 'File path', 'new.txt');
      await tester.pump();

      final last = captured.last;
      expect(last.containsKey('switchKey'), isFalse);
      expect(last.containsKey('left'), isFalse);
      expect(last.containsKey('op'), isFalse);
      expect(last.containsKey('right'), isFalse);
      expect(last.containsKey('cases'), isFalse);
      expect(last.containsKey('default'), isFalse);
      expect(last['predicate'], isA<Map>());
    });

    // ── Path parsing variants ─────────────────────────────────────────

    testWidgets('single "path" string is parsed as path list', (tester) async {
      await _pumpEditor(tester, extras: {
        'predicate': {
          'type': 'fileExists',
          'path': 'single_file.txt',
          'baseKey': 'repoLocalPath',
        },
      });
      expect(find.textContaining('File path'), findsOneWidget);
    });

    testWidgets('paths from list field are hydrated', (tester) async {
      await _pumpEditor(tester, extras: {
        'predicate': {
          'type': 'fileExists',
          'paths': ['a.dart', 'b.dart'],
          'baseKey': 'workspacePath',
          'recursive': true,
        },
      });
      expect(find.textContaining('File path'), findsOneWidget);
    });

    // ── Switch key precedence ─────────────────────────────────────────

    testWidgets('switchKey without predicate enters switchOn mode',
        (tester) async {
      await _pumpEditor(tester, extras: {
        'switchKey': 'env',
        'cases': ['dev', 'prod'],
      });
      expect(find.textContaining('Switch on state'), findsOneWidget);
    });

    // ── Recursive checkbox toggling ──────────────────────────────────

    testWidgets('toggling recursive checkbox emits updated predicate',
        (tester) async {
      final captured = <Map<String, dynamic>>[];
      await _pumpEditor(tester, extras: {
        'predicate': {
          'type': 'fileExists',
          'paths': ['a.txt'],
          'baseKey': 'repoLocalPath',
        },
      }, captured: captured);

      final checkboxes = find.byType(CcCheckbox);
      await tester.tap(checkboxes.first);
      // Let the tappable timer fire.
      await tester.pump(const Duration(milliseconds: 150));

      final last = captured.last;
      final p = last['predicate'] as Map;
      expect(p['recursive'], true);
    });

    // ── Section title ────────────────────────────────────────────────

    testWidgets('renders condition section title', (tester) async {
      await _pumpEditor(tester, extras: {
        'predicate': {
          'type': 'fileExists',
          'paths': ['a.txt'],
          'baseKey': 'repoLocalPath',
        },
      });
      expect(find.textContaining('Condition'), findsOneWidget);
    });

    // ── BaseKey empty fallback ───────────────────────────────────────

    testWidgets('empty baseKey falls back to repoLocalPath in emit',
        (tester) async {
      final captured = <Map<String, dynamic>>[];
      await _pumpEditor(tester, extras: {
        'predicate': {
          'type': 'fileExists',
          'paths': ['a.txt'],
          'baseKey': '',
        },
      }, captured: captured);
      await _enterFTextField(tester, 'File path', 'b.txt');
      await tester.pump();

      final last = captured.last;
      final p = last['predicate'] as Map;
      expect(p['baseKey'], 'repoLocalPath');
    });

    // ── Column layout ────────────────────────────────────────────────

    testWidgets('renders with column layout', (tester) async {
      await _pumpEditor(tester, extras: {
        'predicate': {
          'type': 'fileExists',
          'paths': ['a.txt'],
          'baseKey': 'repoLocalPath',
        },
      });
      expect(find.byType(Column), findsWidgets);
    });
  });
}
