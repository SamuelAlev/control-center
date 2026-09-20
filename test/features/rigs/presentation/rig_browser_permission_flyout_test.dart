import 'package:cc_data/cc_data.dart' show RigView;
import 'package:cc_domain/features/rigs/domain/value_objects/browser_permission.dart';
import 'package:control_center/features/rigs/presentation/rig_browser_permission_flyout.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_wrap.dart';

RigView _browserRig({bool unrestricted = false}) => RigView(
  id: 'browser-1',
  surface: 'browser',
  backendLabel: 'smolvm',
  phase: 'ready',
  accelerated: true,
  unrestrictedNetwork: unrestricted,
  displayWidth: 1280,
  displayHeight: 666,
);

void main() {
  testWidgets('the shield flyout lists allow-all hosts first', (tester) async {
    var network = 0;
    await tester.pumpWidget(
      testWrap(
        RigBrowserPermissionFlyout(
          rig: _browserRig(),
          permissions: const [],
          onNetworkSecurity: () => network++,
          onRespond: (_, {required allow}) {},
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.byIcon(AppIcons.shield));
    await tester.pumpAndSettle();

    expect(find.text('Allow all hosts'), findsOneWidget);
    expect(find.text('No site has asked for a permission yet'), findsOneWidget);

    await tester.tap(find.text('Allow all hosts'));
    await tester.pump();
    expect(network, 1);
  });

  testWidgets('a pending ask offers allow and block', (tester) async {
    String? answered;
    bool? allowed;
    await tester.pumpWidget(
      testWrap(
        RigBrowserPermissionFlyout(
          rig: _browserRig(),
          permissions: const [
            BrowserPermissionEntry(
              id: '1',
              origin: 'http://localhost:5173',
              kind: BrowserPermissionKind.persistentStorage,
              decision: BrowserPermissionDecision.pending,
            ),
          ],
          onNetworkSecurity: () {},
          onRespond: (id, {required allow}) {
            answered = id;
            allowed = allow;
          },
        ),
      ),
    );
    await tester.pump();
    // Pending asks open the flyout themselves.
    await tester.pump();

    expect(find.textContaining('localhost:5173'), findsOneWidget);
    expect(find.text('Allow'), findsOneWidget);
    expect(find.text('Block'), findsOneWidget);

    await tester.tap(find.text('Block'));
    await tester.pump();
    expect(answered, '1');
    expect(allowed, isFalse);
  });

  testWidgets('a decided ask shows allowed or blocked', (tester) async {
    await tester.pumpWidget(
      testWrap(
        RigBrowserPermissionFlyout(
          rig: _browserRig(),
          permissions: const [
            BrowserPermissionEntry(
              id: '1',
              origin: 'https://example.test',
              kind: BrowserPermissionKind.notifications,
              decision: BrowserPermissionDecision.granted,
            ),
            BrowserPermissionEntry(
              id: '2',
              origin: 'https://example.test',
              kind: BrowserPermissionKind.geolocation,
              decision: BrowserPermissionDecision.denied,
            ),
          ],
          onNetworkSecurity: () {},
          onRespond: (_, {required allow}) {},
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.byIcon(AppIcons.shield));
    await tester.pumpAndSettle();

    expect(find.text('Allowed'), findsOneWidget);
    expect(find.text('Blocked'), findsOneWidget);
  });
}
