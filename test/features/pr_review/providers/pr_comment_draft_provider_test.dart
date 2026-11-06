import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/providers/text_draft_provider.dart';
import 'package:control_center/features/pr_review/presentation/widgets/mention_autocomplete_field.dart';
import 'package:control_center/features/pr_review/providers/pr_comment_draft_provider.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_wrap.dart';

const TextDraftKey _key = (
  workspaceId: 'ws-1',
  surface: 'pr-review-body',
  destination: 'pr-1',
);

void main() {
  test('a key keeps one draft, apart from the plain-text family', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final draft = container.read(prCommentDraftControllerProvider(_key));
    draft.text = 'kept';

    expect(container.read(prCommentDraftControllerProvider(_key)), same(draft));
    expect(container.read(textDraftControllerProvider(_key)).text, isEmpty);
  });

  testWidgets('the comment field paints the draft as it will read', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);
    final draft = container.read(prCommentDraftControllerProvider(_key))
      ..text = 'Quite `test` @[file:a.png]';

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: testWrap(
          MentionAutocompleteField(
            controller: draft,
            focusNode: focusNode,
            owner: 'owner',
            repo: 'repo',
            hintText: 'Write a comment',
          ),
        ),
      ),
    );

    final editable = tester.widget<EditableText>(find.byType(EditableText));
    final span = editable.controller.buildTextSpan(
      context: tester.element(find.byType(EditableText)),
      style: editable.style,
      withComposing: false,
    );
    expect(span.toPlainText(), draft.text);
    final runs = span.children!.cast<TextSpan>();
    final code = runs.firstWhere((run) => run.text == 'test');
    expect(code.style?.fontFamily, CcFonts.code().fontFamily);
    final reference = runs.firstWhere((run) => run.text!.contains('@[file:'));
    expect(reference.style, isNull);
  });
}
