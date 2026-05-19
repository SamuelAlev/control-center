import 'package:cc_ui/src/components/cc_breadcrumb.dart';
import 'package:cc_ui/src/components/cc_icons.dart';
import 'package:cc_ui/src/foundation/cc_tappable.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../cc_test_app.dart';

void main() {
  group('CcBreadcrumb', () {
    testWidgets('renders each segment separated by chevrons', (tester) async {
      await tester.pumpWidget(
        ccTestApp(
          const CcBreadcrumb(
            children: [
              CcBreadcrumbItem(child: Text('Workspace')),
              CcBreadcrumbItem(child: Text('Project')),
              CcBreadcrumbItem(child: Text('Current'), current: true),
            ],
          ),
        ),
      );

      expect(find.text('Workspace'), findsOneWidget);
      expect(find.text('Project'), findsOneWidget);
      expect(find.text('Current'), findsOneWidget);
      // Two chevrons between three segments.
      expect(find.byIcon(CcIcons.chevronRight), findsNWidgets(2));
    });

    testWidgets('a single segment renders with no chevron', (tester) async {
      await tester.pumpWidget(
        ccTestApp(
          const CcBreadcrumb(
            children: [CcBreadcrumbItem(child: Text('Only'), current: true)],
          ),
        ),
      );

      expect(find.text('Only'), findsOneWidget);
      expect(find.byIcon(CcIcons.chevronRight), findsNothing);
    });

    testWidgets('a tappable segment fires onPress when tapped', (tester) async {
      var pressed = 0;
      await tester.pumpWidget(
        ccTestApp(
          CcBreadcrumb(
            children: [
              CcBreadcrumbItem(
                child: const Text('Home'),
                onPress: () => pressed++,
              ),
              const CcBreadcrumbItem(child: Text('Here'), current: true),
            ],
          ),
        ),
      );

      // The link segment is wrapped in a CcTappable.
      expect(find.byType(CcTappable), findsOneWidget);
      await tester.tap(find.text('Home'));
      expect(pressed, 1);
    });

    testWidgets('the current segment shrinks to fit a narrow trail instead of '
        'overflowing', (tester) async {
      // Regression: a long current-page label used to hold its natural width
      // and push the trail past its bounds (overflow / trailing content in the
      // same segment clipped off the edge). The final segment now flexes.
      await tester.pumpWidget(
        ccTestApp(
          Center(
            child: SizedBox(
              width: 160,
              child: CcBreadcrumb(
                children: [
                  CcBreadcrumbItem(child: const Text('Home'), onPress: () {}),
                  const CcBreadcrumbItem(
                    child: Text(
                      'A very long current page label that would overflow a '
                      'narrow bar',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    current: true,
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('the current segment is inert even with an onPress', (
      tester,
    ) async {
      var pressed = 0;
      await tester.pumpWidget(
        ccTestApp(
          CcBreadcrumb(
            children: [
              CcBreadcrumbItem(
                child: const Text('Now'),
                onPress: () => pressed++,
                current: true,
              ),
            ],
          ),
        ),
      );

      // current segments render as plain padding (no CcTappable), so there is
      // no tappable target and onPress is never wired.
      expect(find.byType(CcTappable), findsNothing);
      expect(pressed, 0);
    });
  });
}
