import 'package:cc_data/cc_data.dart' show RigPortsView, RigPortView;
import 'package:cc_domain/features/environments/domain/entities/space_environment.dart';
import 'package:cc_domain/features/environments/domain/value_objects/environment_status.dart';
import 'package:control_center/features/environments/providers/environment_providers.dart';
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

  testWidgets('the popover lists the environment\'s endpoints', (tester) async {
    const view = RigPortsView(rigId: 'tty-a', autoForward: true, ports: []);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          terminalPortsProvider.overrideWith(
            (ref, key) => Stream<RigPortsView>.value(view),
          ),
          environmentEndpointsAreRemoteProvider.overrideWithValue(false),
          spaceEnvironmentProvider.overrideWith(
            (ref, _) => SpaceEnvironment(
              id: 'env-1',
              workspaceId: 'ws1',
              spaceId: 'space-a',
              definitionId: 'def-1',
              name: 'fix-login',
              status: EnvironmentStatus.ready,
              endpoints: [
                EnvironmentEndpoint(
                  role: 'web',
                  label: 'Web',
                  url: 'http://web.localhost:4100',
                ),
              ],
              createdBy: 'user-1',
              createdAt: DateTime.utc(2026),
              lastUsedAt: DateTime.utc(2026),
            ),
          ),
        ],
        child: testWrap(
          const RigPortsButton(
            workspaceId: 'ws1',
            conversationId: 'space-a',
            sessionId: 'tty-a',
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.byIcon(AppIcons.plug));
    await tester.pumpAndSettle();
    expect(find.text('web.localhost:4100'), findsOneWidget);
  });

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
