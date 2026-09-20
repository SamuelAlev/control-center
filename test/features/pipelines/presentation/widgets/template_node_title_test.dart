import 'package:control_center/features/pipelines/presentation/widgets/template_node_title.dart';
import 'package:control_center/shared/widgets/graph_node_card.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_wrap.dart';

void main() {
  testWidgets('plain labels render as text with no badge', (tester) async {
    await tester.pumpWidget(testWrap(const TemplateNodeTitle('Review')));

    expect(find.text('Review'), findsOneWidget);
    expect(find.byType(TemplateVarBadge), findsNothing);
  });

  testWidgets('a placeholder becomes a variable badge, not braces', (
    tester,
  ) async {
    await tester.pumpWidget(
      testWrap(
        const SizedBox(
          width: 220,
          child: TemplateNodeTitle('Cross-review #{{pr_number}}'),
        ),
      ),
    );

    expect(find.byType(TemplateVarBadge), findsOneWidget);
    expect(find.text('#pr_number'), findsOneWidget);
    expect(find.text('pr_number'), findsNothing);
    expect(find.text('{{pr_number}}'), findsNothing);
    expect(find.textContaining('Cross-review'), findsOneWidget);
  });

  testWidgets('multiple placeholders each get a badge', (tester) async {
    await tester.pumpWidget(
      testWrap(
        const SizedBox(
          width: 280,
          child: TemplateNodeTitle(r'PR #{{pr_number}} by {{$trigger.author}}'),
        ),
      ),
    );

    expect(find.byType(TemplateVarBadge), findsNWidgets(2));
    expect(find.text('#pr_number'), findsOneWidget);
    expect(find.text(r'$trigger.author'), findsOneWidget);
  });

  testWidgets('a spaced placeholder is not given a hash prefix', (
    tester,
  ) async {
    await tester.pumpWidget(
      testWrap(
        const SizedBox(
          width: 280,
          child: TemplateNodeTitle('Create space for ticket {{ticket_id}}'),
        ),
      ),
    );

    expect(find.byType(TemplateVarBadge), findsOneWidget);
    expect(find.text('ticket_id'), findsOneWidget);
    expect(find.text('#ticket_id'), findsNothing);
  });

  testWidgets('titleChild on GraphNodeCard replaces the plain title text', (
    tester,
  ) async {
    await tester.pumpWidget(
      testWrap(
        const GraphNodeCard(
          glyph: SizedBox(width: 14, height: 14),
          title: 'Cross-review #{{pr_number}}',
          titleChild: TemplateNodeTitle('Cross-review #{{pr_number}}'),
          selected: false,
        ),
      ),
    );

    expect(find.text('Cross-review #{{pr_number}}'), findsNothing);
    expect(find.byType(TemplateVarBadge), findsOneWidget);
  });
}
