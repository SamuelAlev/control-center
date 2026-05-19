import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../cc_test_app.dart';

void main() {
  testWidgets('SourceBadge shows the built-in label by default', (
    tester,
  ) async {
    await tester.pumpWidget(
      ccTestApp(const CcSourceBadge(source: CcConfigSource.project)),
    );

    expect(find.text('PROJECT'), findsOneWidget);
  });

  testWidgets('SourceBadge honors a localized label override', (tester) async {
    await tester.pumpWidget(
      ccTestApp(
        const CcSourceBadge(
          source: CcConfigSource.global,
          label: 'Globalement',
        ),
      ),
    );

    expect(find.text('Globalement'), findsOneWidget);
  });

  testWidgets('ConfigRow renders title, subtitle and source badge', (
    tester,
  ) async {
    await tester.pumpWidget(
      ccTestApp(
        const CcConfigRow(
          title: Text('git push'),
          subtitle: Text('Allowed without confirmation'),
          source: CcConfigSource.project,
        ),
      ),
    );

    expect(find.text('git push'), findsOneWidget);
    expect(find.text('Allowed without confirmation'), findsOneWidget);
    expect(find.byType(CcSourceBadge), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ConfigRow invokes onTap', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      ccTestApp(
        CcConfigRow(
          title: const Text('rule'),
          source: CcConfigSource.defaultValue,
          onTap: () => tapped = true,
        ),
      ),
    );

    await tester.tap(find.text('rule'));
    expect(tapped, isTrue);
  });

  testWidgets('SourceBadge labels the local-override source', (tester) async {
    await tester.pumpWidget(
      ccTestApp(const CcSourceBadge(source: CcConfigSource.localOverride)),
    );
    await tester.pumpAndSettle();
    expect(find.text('LOCAL OVERRIDE'), findsOneWidget);
  });

  testWidgets('SourceBadge labels the default source', (tester) async {
    await tester.pumpWidget(
      ccTestApp(const CcSourceBadge(source: CcConfigSource.defaultValue)),
    );
    await tester.pumpAndSettle();
    expect(find.text('DEFAULT'), findsOneWidget);
  });

  testWidgets('SourceBadge labels the inherited source', (tester) async {
    await tester.pumpWidget(
      ccTestApp(const CcSourceBadge(source: CcConfigSource.inherited)),
    );
    await tester.pumpAndSettle();
    expect(find.text('INHERITED'), findsOneWidget);
  });

  testWidgets('SourceBadge labels the system source', (tester) async {
    await tester.pumpWidget(
      ccTestApp(const CcSourceBadge(source: CcConfigSource.system)),
    );
    await tester.pumpAndSettle();
    expect(find.text('SYSTEM'), findsOneWidget);
  });

  testWidgets('ConfigRow renders leading, status and actions slots', (
    tester,
  ) async {
    await tester.pumpWidget(
      ccTestApp(
        const CcConfigRow(
          title: Text('rule'),
          leading: Text('lead'),
          status: Text('ok'),
          actions: Text('edit'),
        ),
      ),
    );
    expect(find.text('rule'), findsOneWidget);
    expect(find.text('lead'), findsOneWidget);
    expect(find.text('ok'), findsOneWidget);
    expect(find.text('edit'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
