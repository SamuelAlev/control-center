import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/composer/composer.dart';
import 'package:control_center/shared/widgets/composer/composer_models.dart';
import 'package:control_center/shared/widgets/composer/composer_text_controller.dart';
import 'package:control_center/shared/widgets/composer/file_reference.dart';
import 'package:control_center/shared/widgets/composer/mention/mention_popup.dart';
import 'package:control_center/shared/widgets/composer/mention/mention_source.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_wrap.dart';

/// A file source that offers whatever [hit] currently returns, so a `@` query
/// can be committed without a server — and so a second pick can name a
/// different file without rebuilding the composer.
class _FileSource extends MentionSource {
  _FileSource(this.hit);

  final ({String path, String label}) Function() hit;

  @override
  String get kind => 'file';

  @override
  Set<MentionTrigger> get triggers => {MentionTrigger.at};

  @override
  Stream<List<MentionSuggestion>> suggest(MentionQuery query) {
    final current = hit();
    return Stream.value([
      MentionSuggestion(
        id: 'file:${current.path}',
        kind: 'file',
        label: current.label,
        replacement: '@${current.label} ',
        payload: {'path': current.path, 'isDirectory': false},
      ),
    ]);
  }
}

void main() {
  late ComposerTextController controller;
  late List<ComposerSubmission> submitted;
  late ({String path, String label}) nextHit;

  setUp(() {
    controller = ComposerTextController();
    submitted = [];
    nextHit = (path: '/repo/a.dart', label: 'a.dart');
  });

  tearDown(() => controller.dispose());

  Future<void> pumpComposer(WidgetTester tester) async {
    await tester.pumpWidget(
      testWrap(
        // Bottom-aligned, as it sits in a real conversation. The mention popup
        // floats ABOVE the composer, so a top-aligned composer in an 800x600
        // test surface would render its rows off-screen and nothing could be
        // tapped.
        Align(
          alignment: Alignment.bottomCenter,
          child: Composer(
            controller: controller,
            sources: [_FileSource(() => nextHit)],
            onSubmit: (s) async => submitted.add(s),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  /// Replaces the draft with [text] and lets the mention popup settle.
  Future<void> type(WidgetTester tester, String text) async {
    controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  /// Commits the single suggestion the popup is showing.
  ///
  /// Scoped to the popup: once a file is attached its name also appears on the
  /// chip strip, and a bare text finder would start matching that instead.
  Future<void> pickSuggestion(WidgetTester tester, String label) async {
    await tester.tap(
      find.descendant(
        of: find.byType(MentionPopup),
        matching: find.text(label),
      ),
    );
    await tester.pump();
  }

  /// Presses send and lets the submission complete.
  ///
  /// Deliberately NOT `pumpAndSettle`: the field's caret blinks forever, so
  /// waiting for the tree to go quiet never returns.
  Future<void> send(WidgetTester tester) async {
    await tester.tap(find.byIcon(AppIcons.arrowUp));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  testWidgets('picking a file inserts a bounded reference, not a raw path', (
    tester,
  ) async {
    nextHit = (
      path: '/repo/lib/transcript_segment_row_widget.dart',
      label: 'transcript_segment_row_widget.dart',
    );
    await pumpComposer(tester);
    await type(tester, 'look at @trans');
    await pickSuggestion(tester, 'transcript_segment_row_widget.dart');

    final refs = findFileRefs(controller.text);
    expect(refs, hasLength(1));
    // "Max width" is enforced on the NAME — the long path never lands in the
    // draft at all.
    expect(refs.single.name.length, lessThanOrEqualTo(kFileRefMaxNameChars));
    expect(controller.text, isNot(contains('/repo/lib/')));
    expect(controller.text, startsWith('look at '));
  });

  testWidgets('the reference and the attachment both reach the submission', (
    tester,
  ) async {
    await pumpComposer(tester);
    await type(tester, '@a');
    await pickSuggestion(tester, 'a.dart');
    await type(tester, '${controller.text}please review');

    await send(tester);

    expect(submitted, hasLength(1));
    final submission = submitted.single;
    expect(submission.attachments, hasLength(1));
    final attachment = submission.attachments.single;
    expect(attachment.path, '/repo/a.dart');
    // The reference name is what the host expands back to a path, so it has to
    // survive on the attachment, not just in the text.
    expect(attachment.refName, isNotNull);
    expect(submission.text, contains(fileRefToken(attachment.refName!)));
  });

  testWidgets('deleting the reference removes the attachment', (tester) async {
    nextHit = (path: '/repo/notes.md', label: 'notes.md');
    await pumpComposer(tester);
    await type(tester, '@notes');
    await pickSuggestion(tester, 'notes.md');
    expect(findFileRefs(controller.text), hasLength(1));

    // The token IS the attachment's presence in the message: editing it out
    // must take the file with it, or the send would carry a file the person
    // deleted.
    await type(tester, 'never mind');

    expect(findFileRefs(controller.text), isEmpty);
    expect(find.text('notes.md'), findsNothing);

    await send(tester);
    expect(submitted.single.attachments, isEmpty);
  });

  testWidgets('two files with the same basename get distinct references', (
    tester,
  ) async {
    nextHit = (path: '/pkg-a/index.ts', label: 'index.ts');
    await pumpComposer(tester);
    await type(tester, '@index');
    await pickSuggestion(tester, 'index.ts');

    nextHit = (path: '/pkg-b/index.ts', label: 'index.ts');
    await type(tester, '${controller.text}@index');
    await pickSuggestion(tester, 'index.ts');

    final names = findFileRefs(controller.text).map((r) => r.name).toSet();
    expect(
      names,
      hasLength(2),
      reason: 'two different files must not share one reference',
    );
  });

  testWidgets('picking the same file twice attaches it once', (tester) async {
    await pumpComposer(tester);
    await type(tester, '@a');
    await pickSuggestion(tester, 'a.dart');
    await type(tester, '${controller.text}@a');
    await pickSuggestion(tester, 'a.dart');

    await send(tester);
    expect(submitted.single.attachments, hasLength(1));
  });
}
