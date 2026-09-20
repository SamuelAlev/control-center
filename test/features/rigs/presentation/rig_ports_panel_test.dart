import 'package:cc_data/cc_data.dart' show RigPortsView, RigPortView;
import 'package:control_center/features/rigs/presentation/rig_ports_panel.dart';
import 'package:control_center/features/rigs/providers/rig_providers.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_wrap.dart';

void main() {
  testWidgets(
    'ports button renders on a host-shell when the session has a snapshot',
    (tester) async {
      const view = RigPortsView(
        rigId: 'tty-a',
        autoForward: true,
        ports: [
          RigPortView(
            guestPort: 5173,
            hostPort: 5173,
            origin: 'auto',
            active: true,
            process: 'node',
          ),
        ],
      );
      await tester.pumpWidget(
        testWrap(
          ProviderScope(
            overrides: [
              terminalPortsProvider.overrideWith(
                (ref, key) => Stream<RigPortsView>.value(view),
              ),
            ],
            child: const RigPortsButton(
              workspaceId: 'ws1',
              conversationId: 'space-a',
              sessionId: 'tty-a',
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byIcon(AppIcons.plug), findsOneWidget);
    },
  );

  testWidgets('without a session or exec rig the plug is absent', (tester) async {
    await tester.pumpWidget(
      testWrap(
        ProviderScope(
          overrides: [
            conversationExecRigProvider.overrideWith((ref, key) => null),
          ],
          child: const RigPortsButton(
            workspaceId: 'ws1',
            conversationId: 'space-a',
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byIcon(AppIcons.plug), findsNothing);
  });
}
