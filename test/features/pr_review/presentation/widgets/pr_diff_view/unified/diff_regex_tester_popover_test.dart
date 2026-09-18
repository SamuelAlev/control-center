import 'package:control_center/features/pr_review/presentation/widgets/pr_diff_view/unified/diff_regex_tester_popover.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../../helpers/test_wrap.dart';

void main() {
  testWidgets('live-evaluates a JS regexp literal against the sample', (
    tester,
  ) async {
    await tester.pumpWidget(
      testWrap(const DiffRegexTesterPopover(literal: r'/hello/i')),
    );
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(l10n.regexTesterTitle), findsOneWidget);
    expect(find.text('hello'), findsOneWidget);

    await tester.enterText(find.byType(EditableText), 'HELLO world');
    await tester.pump();
    expect(find.text(l10n.regexMatch), findsOneWidget);
    expect(find.text(l10n.regexNoMatch), findsNothing);

    await tester.enterText(find.byType(EditableText), 'xyz');
    await tester.pump();
    expect(find.text(l10n.regexNoMatch), findsOneWidget);
    expect(find.text(l10n.regexMatch), findsNothing);
  });

  testWidgets('shows an invalid-pattern state for a broken literal', (
    tester,
  ) async {
    await tester.pumpWidget(
      testWrap(const DiffRegexTesterPopover(literal: '/(/')),
    );
    await tester.enterText(find.byType(EditableText), 'abc');
    await tester.pump();
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(l10n.regexInvalidPattern), findsOneWidget);
    expect(find.text(l10n.regexMatch), findsNothing);
  });
}
