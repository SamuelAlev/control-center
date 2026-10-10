import 'package:cc_domain/features/pr_review/domain/entities/pr_file.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/theme/font_settings.dart';
import 'package:control_center/features/pr_review/presentation/utils/diff_isolate_worker.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_diff_view/unified/pr_diff_document.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_diff_view/unified/unified_diff_view.dart';
import 'package:control_center/features/pr_review/providers/diff_view_settings_provider.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../../helpers/test_wrap.dart';

PrFile _file(String name, {int lines = 8}) => PrFile(
  filename: name,
  status: PrFileStatus.modified,
  additions: 5,
  deletions: 2,
  patch:
      '@@ -1,$lines +1,${lines + 1} @@\n'
      '${List.generate(lines, (i) => ' line $i\n').join()}'
      '+added\n',
);

Widget _host(
  GlobalKey<UnifiedDiffViewState> key, {
  bool reduceMotion = false,
  void Function({required String path, required bool viewed})? onToggleViewed,
  ScrollController? controller,
  int lines = 8,
}) {
  return ProviderScope(
    overrides: [
      codeFontFamilyProvider.overrideWithValue('Fira Code'),
      diffOverflowModeProvider.overrideWith(DiffOverflowModeNotifier.new),
    ],
    child: testWrap(
      Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(disableAnimations: reduceMotion),
          child: CustomScrollView(
            controller: controller,
            slivers: [
              UnifiedDiffView(
                key: key,
                files: [
                  _file('lib/a.dart', lines: lines),
                  _file('lib/b.dart', lines: lines),
                ],
                onToggleViewed: onToggleViewed,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Height of file 0's header plus separator — its collapsed height.
double _collapsedHeight(PrDiffDocument doc) =>
    doc.headerHeight + doc.fileSeparator;

void main() {
  // Tokenize on the main isolate: widget tests must not spawn real diff
  // workers (their fallback watchdog Timer would pend at FakeAsync teardown).
  setUpAll(() => DiffWorkerPool.debugForceInline = true);
  tearDownAll(() => DiffWorkerPool.debugForceInline = false);

  // FocusModality is a process-wide singleton whose key handler only survives
  // the test that first registers it (the binding clears keyboard handlers
  // between tests), so every keyboard case lives in this first test. Its
  // pointer route persists, so later taps still read as pointer input.
  group('file expand/collapse motion', () {
    testWidgets('keyboard toggles snap without animating', (tester) async {
      final key = GlobalKey<UnifiedDiffViewState>();
      await tester.pumpWidget(_host(key));
      await tester.pump();
      final doc = key.currentState!.debugDocument;

      // The `c` shortcut.
      await tester.sendKeyEvent(LogicalKeyboardKey.keyC);
      await tester.pump();
      expect(doc.isExpanded(0), isFalse);
      expect(doc.isRevealing(0), isFalse);
      expect(doc.heightOfFile(0), _collapsedHeight(doc));

      // Enter on a focused header button, right after a pointer interaction:
      // the button hears the Enter before the modality tracker does, so this
      // only snaps when the motion reads the modality at build time.
      await tester.tap(find.text('lib/b.dart'), warnIfMissed: false);
      await tester.pump(CcMotion.moderate);
      Focus.of(
        tester.element(find.byIcon(AppIcons.chevronDown).first),
      ).requestFocus();
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(doc.isExpanded(0), isTrue);
      expect(doc.isRevealing(0), isFalse);
    });

    testWidgets('a header click animates the collapse and the expand', (
      tester,
    ) async {
      final key = GlobalKey<UnifiedDiffViewState>();
      await tester.pumpWidget(_host(key));
      await tester.pump();
      final doc = key.currentState!.debugDocument;
      final full = doc.heightOfFile(0);
      final nextTop = doc.offsetOfFile(1);
      expect(full, greaterThan(_collapsedHeight(doc)));

      await tester.tap(find.byIcon(AppIcons.chevronUp).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Mid-collapse: the chevron already reports the target, the body is
      // part-way and the next file has moved up with it.
      expect(doc.isExpanded(0), isFalse);
      expect(doc.isRevealing(0), isTrue);
      expect(doc.heightOfFile(0), lessThan(full));
      expect(doc.heightOfFile(0), greaterThan(_collapsedHeight(doc)));
      expect(doc.offsetOfFile(1), lessThan(nextTop));

      await tester.pump(CcMotion.moderateExit);
      expect(doc.isRevealing(0), isFalse);
      expect(doc.heightOfFile(0), _collapsedHeight(doc));

      await tester.tap(find.byIcon(AppIcons.chevronDown).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));

      expect(doc.isExpanded(0), isTrue);
      expect(doc.isRevealing(0), isTrue);
      expect(doc.heightOfFile(0), greaterThan(_collapsedHeight(doc)));
      expect(doc.heightOfFile(0), lessThan(full));

      await tester.pump(CcMotion.moderate);
      expect(doc.isRevealing(0), isFalse);
      expect(doc.heightOfFile(0), full);
      expect(doc.offsetOfFile(1), nextTop);
    });

    testWidgets('marking a file viewed animates the fold', (tester) async {
      final key = GlobalKey<UnifiedDiffViewState>();
      await tester.pumpWidget(
        _host(key, onToggleViewed: ({required path, required viewed}) {}),
      );
      await tester.pump();
      final doc = key.currentState!.debugDocument;

      await tester.tap(find.byIcon(AppIcons.circle).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(doc.isExpanded(0), isFalse);
      expect(doc.isRevealing(0), isTrue);

      await tester.pump(CcMotion.moderateExit);
      expect(doc.isRevealing(0), isFalse);
      expect(doc.heightOfFile(0), _collapsedHeight(doc));
    });

    testWidgets('folding a docked file lands on the next file\'s top', (
      tester,
    ) async {
      final key = GlobalKey<UnifiedDiffViewState>();
      final controller = ScrollController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _host(
          key,
          controller: controller,
          lines: 80,
          onToggleViewed: ({required path, required viewed}) {},
        ),
      );
      await tester.pump();
      final doc = key.currentState!.debugDocument;

      // Fifteen-odd rows into file 0, its header docked at the top.
      controller.jumpTo(doc.headerHeight + 300);
      await tester.pump();

      // The docked header is laid out at its pin, but the finder judges
      // onstage by the file's own top, now scrolled away.
      await tester.tap(find.byIcon(AppIcons.circle, skipOffstage: false));
      await tester.pump();
      await tester.pump(CcMotion.moderateExit);

      expect(doc.isExpanded(0), isFalse);
      expect(doc.isRevealing(0), isFalse);
      expect(controller.offset, doc.offsetOfFile(1));
    });

    testWidgets('reduced motion snaps a click', (tester) async {
      final key = GlobalKey<UnifiedDiffViewState>();
      await tester.pumpWidget(_host(key, reduceMotion: true));
      await tester.pump();
      final doc = key.currentState!.debugDocument;

      await tester.tap(find.byIcon(AppIcons.chevronUp).first);
      await tester.pump();

      expect(doc.isExpanded(0), isFalse);
      expect(doc.isRevealing(0), isFalse);
      expect(doc.heightOfFile(0), _collapsedHeight(doc));
    });
  });
}
