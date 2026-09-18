import 'package:cc_domain/core/domain/value_objects/code_symbol_kind.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_file.dart';
import 'package:cc_domain/features/pr_review/domain/services/diff_parser.dart';
import 'package:control_center/features/pr_review/presentation/utils/diff_isolate_worker.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_diff_view/unified/diff_goto.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_diff_view/unified/pr_diff_document.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../../helpers/test_wrap.dart';

PrDiffDocument _docWith(String filename, String patch) {
  return PrDiffDocument(lineHeight: 18, headerHeight: 28)..setFiles([
    PrFile(
      filename: filename,
      status: PrFileStatus.added,
      additions: 1,
      deletions: 0,
      patch: patch,
    ),
  ]);
}

DiffRawLines _ensure(PrDiffDocument doc, int i) {
  final existing = doc.structureOf(i);
  if (existing != null) {
    return existing;
  }
  final raw = buildDiffRawLines(doc.files[i].patch);
  doc.setStructure(i, raw);
  return raw;
}

void main() {
  group('parseJsRegexLiteral', () {
    test('returns null when the text is not slash-delimited', () {
      expect(parseJsRegexLiteral('abc'), isNull);
      expect(parseJsRegexLiteral('r"foo"'), isNull);
      expect(parseJsRegexLiteral('/unterminated'), isNull);
    });

    test('strips delimiters and maps flags onto Dart RegExp options', () {
      final parsed = parseJsRegexLiteral(r'/foo.bar/imsug');
      expect(parsed, isNotNull);
      expect(parsed!.pattern, 'foo.bar');
      expect(parsed.flags, 'imsug');
      expect(parsed.caseSensitive, isFalse);
      expect(parsed.multiLine, isTrue);
      expect(parsed.dotAll, isTrue);
      expect(parsed.unicode, isTrue);
      expect(parsed.global, isTrue);
      final re = parsed.toRegExp();
      expect(re.hasMatch('FOO\nBAR'), isTrue);
    });

    test('treats escaped slashes as part of the pattern', () {
      final parsed = parseJsRegexLiteral(r'/a\/b/g');
      expect(parsed, isNotNull);
      expect(parsed!.pattern, r'a\/b');
      expect(parsed.global, isTrue);
      expect(parsed.toRegExp().hasMatch('a/b'), isTrue);
    });
  });

  group('interactiveSpanAt', () {
    test('returns null without symbol or regexp tokens', () {
      const line = '  fooBar(x)';
      expect(
        interactiveSpanAt(
          lineText: line,
          displayCol: 4,
          fileIndex: 0,
          displayLine: 3,
        ),
        isNull,
      );
      expect(
        interactiveSpanAt(
          lineText: line,
          displayCol: 4,
          fileIndex: 0,
          displayLine: 3,
          tokens: const [
            DiffToken('  ', null),
            DiffToken('fooBar', null),
            DiffToken('(x)', null),
          ],
        ),
        isNull,
      );
    });

    test('returns the symbol token under the cursor', () {
      const line = '  fooBar(x)';
      final span = interactiveSpanAt(
        lineText: line,
        displayCol: 4,
        fileIndex: 0,
        displayLine: 3,
        tokens: const [
          DiffToken('  ', null),
          DiffToken('fooBar', null, kind: DiffTokenKind.symbol),
          DiffToken('(', null),
          DiffToken('x', null),
          DiffToken(')', null),
        ],
      );
      expect(span, isNotNull);
      expect(span!.kind, DiffGotoKind.identifier);
      expect(span.text, 'fooBar');
      expect(span.startCol, 2);
      expect(span.endCol, 8);
    });

    test('returns null on punctuation', () {
      expect(
        interactiveSpanAt(
          lineText: '  = 1;',
          displayCol: 2,
          fileIndex: 0,
          displayLine: 0,
          tokens: const [
            DiffToken('  ', null),
            DiffToken('=', null),
            DiffToken(' 1;', null),
          ],
        ),
        isNull,
      );
    });

    test('merges adjacent regexp tokens and prefers them over identifiers', () {
      const line = 'const re = /abc/g;';
      final tokens = [
        const DiffToken('const', null),
        const DiffToken(' ', null),
        const DiffToken('re', null, kind: DiffTokenKind.symbol),
        const DiffToken(' ', null),
        const DiffToken('=', null),
        const DiffToken(' ', null),
        const DiffToken('/', null, kind: DiffTokenKind.regexp),
        const DiffToken('abc', null, kind: DiffTokenKind.regexp),
        const DiffToken('/g', null, kind: DiffTokenKind.regexp),
        const DiffToken(';', null),
      ];
      final span = interactiveSpanAt(
        lineText: line,
        displayCol: 13,
        fileIndex: 1,
        displayLine: 2,
        tokens: tokens,
      );
      expect(span, isNotNull);
      expect(span!.kind, DiffGotoKind.regexp);
      expect(span.text, '/abc/g');
      expect(span.startCol, 11);
      expect(span.endCol, 17);
    });

    test('maps tab-expanded display columns back to raw symbol bounds', () {
      const line = '\tfoo';
      final span = interactiveSpanAt(
        lineText: line,
        displayCol: 5,
        fileIndex: 0,
        displayLine: 0,
        tokens: const [
          DiffToken('\t', null),
          DiffToken('foo', null, kind: DiffTokenKind.symbol),
        ],
      );
      expect(span, isNotNull);
      expect(span!.text, 'foo');
      expect(span.startCol, 4);
      expect(span.endCol, 7);
    });

    test('skips reserved names even when tokenized as symbols', () {
      expect(
        interactiveSpanAt(
          lineText: 'z.null()',
          displayCol: 3,
          fileIndex: 0,
          displayLine: 0,
          tokens: const [
            DiffToken('z', null),
            DiffToken('.', null),
            DiffToken('null', null, kind: DiffTokenKind.symbol),
            DiffToken('()', null),
          ],
        ),
        isNull,
      );
    });
  });

  group('diffGotoNameDisplayRange', () {
    test('places a whole-identifier name in display columns', () {
      expect(
        diffGotoNameDisplayRange('export function fetchUser() {', 'fetchUser'),
        (16, 25),
      );
    });

    test('prefers the first symbol token of that name', () {
      const line = 'Animal animal = Animal();';
      expect(
        diffGotoNameDisplayRange(
          line,
          'Animal',
          tokens: const [
            DiffToken('Animal', null, kind: DiffTokenKind.symbol),
            DiffToken(' animal = ', null),
            DiffToken('Animal', null, kind: DiffTokenKind.symbol),
            DiffToken('();', null),
          ],
        ),
        (0, 6),
      );
    });

    test('does not attach through a preceding dot', () {
      expect(diffGotoNameDisplayRange('z.null()', 'null'), isNull);
    });

    test('maps tab-expanded columns', () {
      expect(diffGotoNameDisplayRange('\tfoo() {', 'foo'), (4, 7));
    });
  });

  group('diffDefinitionsNamed', () {
    test('finds an exported function in the loaded patch', () {
      final doc = _docWith(
        'src/user.ts',
        '@@ -0,0 +1,3 @@\n'
            '+export function fetchUser() {\n'
            '+  return 1;\n'
            '+}\n',
      );
      final hits = diffDefinitionsNamed(
        name: 'fetchUser',
        document: doc,
        ensureStructure: (i) => _ensure(doc, i),
      );
      expect(hits, hasLength(1));
      expect(hits.single.filePath, 'src/user.ts');
      expect(hits.single.startLine, 1);
      expect(hits.single.kind, CodeSymbolKind.function);
    });

    test('does not treat a call inside if as a definition', () {
      final doc = _docWith(
        'src/user.ts',
        '@@ -0,0 +1,3 @@\n'
            '+if (fetchUser()) {\n'
            '+  return 1;\n'
            '+}\n',
      );
      expect(
        diffDefinitionsNamed(
          name: 'fetchUser',
          document: doc,
          ensureStructure: (i) => _ensure(doc, i),
        ),
        isEmpty,
      );
    });

    test('skips deletion lines', () {
      final doc = _docWith(
        'src/user.ts',
        '@@ -1,1 +1,1 @@\n'
            '-export function fetchUser() {\n'
            '+export function other() {\n',
      );
      expect(
        diffDefinitionsNamed(
          name: 'fetchUser',
          document: doc,
          ensureStructure: (i) => _ensure(doc, i),
        ),
        isEmpty,
      );
    });

    test('finds a Dart class', () {
      final doc = _docWith(
        'lib/animal.dart',
        '@@ -0,0 +1,3 @@\n'
            '+class Animal {\n'
            '+  Animal();\n'
            '+}\n',
      );
      final hits = diffDefinitionsNamed(
        name: 'Animal',
        document: doc,
        ensureStructure: (i) => _ensure(doc, i),
      );
      expect(hits, hasLength(1));
      expect(hits.single.kind, CodeSymbolKind.classKind);
      expect(hits.single.startLine, 1);
    });

    test('ignores reserved names', () {
      final doc = _docWith('src/z.ts', '@@ -0,0 +1,1 @@\n+function null() {\n');
      expect(
        diffDefinitionsNamed(
          name: 'null',
          document: doc,
          ensureStructure: (i) => _ensure(doc, i),
        ),
        isEmpty,
      );
    });
  });

  group('diffFilePathsMatch', () {
    test('normalizes slashes and accepts a suffix', () {
      expect(diffFilePathsMatch('lib/foo.dart', 'lib/foo.dart'), isTrue);
      expect(diffFilePathsMatch(r'lib\foo.dart', 'lib/foo.dart'), isTrue);
      expect(diffFilePathsMatch('pkg/lib/foo.dart', 'lib/foo.dart'), isTrue);
      expect(diffFilePathsMatch('lib/foo.dart', 'lib/bar.dart'), isFalse);
    });
  });

  group('gotoPopoverOrigin', () {
    const child = Size(320, 120);
    const viewport = Size(800, 600);

    test('sits just below the trigger when there is room', () {
      const anchor = Rect.fromLTWH(40, 80, 100, 18);
      expect(
        gotoPopoverOrigin(anchor: anchor, childSize: child, viewport: viewport),
        const Offset(40, 80 + 18 + kGotoPopoverGap),
      );
    });

    test('flips just above using the real child height, not a guessed 280', () {
      const anchor = Rect.fromLTWH(40, 500, 100, 18);
      final origin = gotoPopoverOrigin(
        anchor: anchor,
        childSize: child,
        viewport: viewport,
      );
      expect(origin.dy, 500 - 120 - kGotoPopoverGap);
      expect(origin.dy, isNot(500 - 280 - kGotoPopoverGap));
      expect(origin.dx, 40);
    });

    test('clamps horizontally so a wide panel stays on-screen', () {
      const anchor = Rect.fromLTWH(700, 80, 80, 18);
      final origin = gotoPopoverOrigin(
        anchor: anchor,
        childSize: child,
        viewport: viewport,
      );
      expect(origin.dx, viewport.width - child.width - kGotoPopoverMargin);
    });
  });

  group('DiffGotoHitTarget', () {
    testWidgets('fires on tap only while the go-to modifier is held', (
      tester,
    ) async {
      // Reset inline: the binding verifies foundation debug variables
      // before tearDowns run.
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      var taps = 0;
      try {
        await tester.pumpWidget(
          testWrap(
            DiffGotoHitTarget(
              onActivate: () => taps++,
              child: const SizedBox(width: 40, height: 40),
            ),
          ),
        );

        await tester.tap(find.byType(DiffGotoHitTarget));
        await tester.pump();
        expect(taps, 0);

        await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
        await tester.tap(find.byType(DiffGotoHitTarget));
        await tester.pump();
        expect(taps, 1);

        await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
        await tester.tap(find.byType(DiffGotoHitTarget));
        await tester.pump();
        expect(taps, 1);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets('uses Ctrl on Windows', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      var taps = 0;
      try {
        await tester.pumpWidget(
          testWrap(
            DiffGotoHitTarget(
              onActivate: () => taps++,
              child: const SizedBox(width: 40, height: 40),
            ),
          ),
        );

        await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
        await tester.tap(find.byType(DiffGotoHitTarget));
        await tester.pump();
        expect(taps, 0);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);

        await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
        await tester.tap(find.byType(DiffGotoHitTarget));
        await tester.pump();
        expect(taps, 1);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });
  });

  group('GotoPopoverLayout', () {
    testWidgets('lays a short panel just below the trigger', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const anchor = Rect.fromLTWH(40, 80, 100, 18);
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox.expand(
            child: CustomSingleChildLayout(
              delegate: GotoPopoverLayout(anchor: anchor),
              child: SizedBox(width: 320, height: 120, key: Key('panel')),
            ),
          ),
        ),
      );
      await tester.pump();
      final box = tester.renderObject<RenderBox>(
        find.byKey(const Key('panel')),
      );
      expect(box.localToGlobal(Offset.zero), const Offset(40, 104));
    });

    testWidgets('flips a short panel just above a low trigger', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const anchor = Rect.fromLTWH(40, 500, 100, 18);
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox.expand(
            child: CustomSingleChildLayout(
              delegate: GotoPopoverLayout(anchor: anchor),
              child: SizedBox(width: 320, height: 120, key: Key('panel')),
            ),
          ),
        ),
      );
      await tester.pump();
      final box = tester.renderObject<RenderBox>(
        find.byKey(const Key('panel')),
      );
      expect(box.localToGlobal(Offset.zero).dy, 500 - 120 - kGotoPopoverGap);
    });
  });
}
