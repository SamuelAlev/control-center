import 'package:cc_data/cc_data.dart' show RigPortsView, RigPortView, RigView;
import 'package:cc_domain/cc_domain.dart' show RpcErrorCodes;
import 'package:cc_domain/features/environments/domain/entities/space_environment.dart';
import 'package:cc_domain/features/environments/domain/value_objects/environment_status.dart';
import 'package:cc_rpc/cc_rpc.dart' show RemoteRpcException;
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/environments/providers/environment_providers.dart';
import 'package:control_center/features/rigs/presentation/rig_ports_panel.dart';
import 'package:control_center/features/rigs/providers/rig_access_provider.dart';
import 'package:control_center/features/rigs/providers/rig_providers.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart' show TextDirection;
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

  testWidgets('a watch-only rig shows its ports without the controls', (
    tester,
  ) async {
    const view = RigPortsView(
      rigId: 'rig-exec',
      autoForward: true,
      ports: [
        RigPortView(
          guestPort: 3000,
          hostPort: 3000,
          origin: 'auto',
          active: true,
          process: 'node',
        ),
      ],
    );
    final container = ProviderContainer(
      overrides: [
        conversationExecRigProvider.overrideWith(
          (ref, key) => const RigView(
            id: 'rig-exec',
            surface: 'computer',
            backendLabel: 'smolvm',
            phase: 'ready',
            accelerated: true,
            isExec: true,
            conversationId: 'space-a',
          ),
        ),
        rigPortsProvider.overrideWith(
          (ref, key) => Stream<RigPortsView>.value(view),
        ),
        // The row does not say, so the space's state decides.
        rigSessionsProvider.overrideWith(
          (ref, _) => Stream.value(const <RigView>[]),
        ),
        environmentEndpointsAreRemoteProvider.overrideWithValue(false),
        spaceEnvironmentProvider.overrideWith((ref, _) => null),
      ],
    );
    addTearDown(container.dispose);
    const space = (workspaceId: 'ws1', spaceId: 'space-a');
    container.listen(rigAccessProvider(space), (_, _) {});
    container
        .read(rigAccessProvider(space).notifier)
        .noteRefusal(
          RemoteRpcException(RpcErrorCodes.unauthorized, 'no', {
            'kind': 'repo_grant_required',
            'level': 'write',
          }),
        );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: testWrap(
          const RigPortsButton(workspaceId: 'ws1', conversationId: 'space-a'),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.byIcon(AppIcons.plug));
    await tester.pumpAndSettle();

    expect(find.text('3000'), findsWidgets);
    expect(
      find.text(
        'Changing these ports needs write access to every repository in this '
        'space.',
      ),
      findsOneWidget,
    );
    expect(find.byIcon(AppIcons.plus), findsNothing);
    expect(find.byIcon(AppIcons.moreHorizontal), findsNothing);
    expect(tester.widget<CcSwitch>(find.byType(CcSwitch)).onChanged, isNull);
  });

  testWidgets('a refused ports watch says why instead of spinning', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          terminalPortsProvider.overrideWith(
            (ref, key) => Stream<RigPortsView>.error(
              RemoteRpcException(RpcErrorCodes.unauthorized, 'no', {
                'kind': 'repo_grant_required',
                'level': 'read',
              }),
            ),
          ),
          environmentEndpointsAreRemoteProvider.overrideWithValue(false),
          spaceEnvironmentProvider.overrideWith((ref, _) => null),
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

    expect(
      find.text(
        "You don't have read access to a repository this space uses. A "
        'workspace admin can grant it.',
      ),
      findsOneWidget,
    );
    expect(find.byType(CcSpinner), findsNothing);
    expect(find.byIcon(AppIcons.plus), findsNothing);
  });

  testWidgets('somebody else\'s machine says who may change its ports', (
    tester,
  ) async {
    const holderRig = RigView(
      id: 'rig-exec',
      surface: 'computer',
      backendLabel: 'smolvm',
      phase: 'ready',
      accelerated: true,
      isExec: true,
      conversationId: 'space-a',
      canDrive: false,
      holderOnly: true,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          conversationExecRigProvider.overrideWith((ref, key) => holderRig),
          rigSessionsProvider.overrideWith(
            (ref, _) => Stream.value(const [holderRig]),
          ),
          rigPortsProvider.overrideWith(
            (ref, key) => Stream<RigPortsView>.value(
              const RigPortsView(
                rigId: 'rig-exec',
                autoForward: false,
                ports: [],
              ),
            ),
          ),
          environmentEndpointsAreRemoteProvider.overrideWithValue(false),
          spaceEnvironmentProvider.overrideWith((ref, _) => null),
        ],
        child: testWrap(
          const RigPortsButton(workspaceId: 'ws1', conversationId: 'space-a'),
          textDirection: TextDirection.rtl,
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.byIcon(AppIcons.plug));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Only the person this machine was opened for can drive it. It uses '
        'their own sign-ins.',
      ),
      findsOneWidget,
    );
    expect(find.byIcon(AppIcons.plus), findsNothing);
    expect(tester.widget<CcSwitch>(find.byType(CcSwitch)).onChanged, isNull);
  });
}
