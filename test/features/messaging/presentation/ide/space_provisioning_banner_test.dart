import 'dart:async';

import 'package:cc_domain/features/messaging/domain/entities/space.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/space_provisioning_status.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/space_provisioning_step.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/features/messaging/presentation/ide/editor/conversation_pane.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/composer/composer.dart'
    show composerHorizontalMargin;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/active_workspace.dart';
import '../../../../helpers/fake_rpc_client.dart';
import '../../../../helpers/test_wrap.dart';

const _spaceId = 'space-1';
const _bannerWidth = 600.0;

void main() {
  testWidgets('retry and stop target the displayed workspace, not RPC defaults', (
    tester,
  ) async {
    const workspaceId = 'workspace-one';
    final updates = StreamController<List<Space>>.broadcast();
    Space space(SpaceProvisioningStatus status) => Space(
      id: _spaceId,
      name: 'Guidelines',
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
      provisioningStatus: status,
    );
    final host = FakeRpcHost()
      ..onCall = (op, args) {
        if (args['workspace_id'] != workspaceId ||
            args['space_id'] != _spaceId) {
          throw StateError('Provisioning request targeted another workspace');
        }
        final next = switch (op) {
          'messaging.retrySpaceProvisioning' =>
            SpaceProvisioningStatus.provisioning,
          'messaging.cancelSpaceProvisioning' =>
            SpaceProvisioningStatus.cancelled,
          _ => throw StateError('Unexpected operation: $op'),
        };
        updates.add([space(next)]);
        return {'ok': true};
      };
    final client = host.client()..activeWorkspaceId = 'workspace-two';
    addTearDown(() async {
      await client.close();
      await host.close();
      await updates.close();
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeWorkspaceIdOverride(workspaceId),
          rpcClientProvider.overrideWithValue(client),
          workspaceSpacesProvider(workspaceId).overrideWith((ref) async* {
            yield [space(SpaceProvisioningStatus.failed)];
            yield* updates.stream;
          }),
        ],
        child: testWrap(
          const SpaceProvisioningBanner(spaceId: _spaceId),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    final retry = find.widgetWithText(CcButton, l10n.retry);
    expect(find.text(l10n.workspacePrepFailed), findsOneWidget);

    await tester.tap(retry);
    await tester.pump();
    await tester.pump();
    expect(retry, findsNothing);
    expect(find.byType(CcSpinner), findsOneWidget);

    await tester.tap(find.byType(CcIconButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.widgetWithText(CcButton, l10n.stopWorkspacePrep));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text(l10n.workspacePrepStopped), findsOneWidget);
    expect(retry, findsOneWidget);

    await tester.tap(retry);
    await tester.pump();
    await tester.pump();
    expect(find.byType(CcSpinner), findsOneWidget);
    updates.add([space(SpaceProvisioningStatus.ready)]);
    await tester.pump();
    expect(find.byType(CcSpinner), findsNothing);
    expect(retry, findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('pins the stop control to the composer trailing edge', (
    tester,
  ) async {
    await _pumpBanner(tester);
    final banner = tester.getRect(find.byType(SpaceProvisioningBanner));
    final stop = tester.getRect(find.byType(CcIconButton));
    expect(stop.right, closeTo(banner.right - composerHorizontalMargin, 0.5));
  });

  testWidgets('pins the stop control to the leading edge in RTL', (
    tester,
  ) async {
    await _pumpBanner(tester, textDirection: TextDirection.rtl);
    final banner = tester.getRect(find.byType(SpaceProvisioningBanner));
    final stop = tester.getRect(find.byType(CcIconButton));
    expect(stop.left, closeTo(banner.left + composerHorizontalMargin, 0.5));
  });

  testWidgets('demo provisioning offers no stop action', (tester) async {
    await _pumpBanner(tester, isDemo: true);
    expect(find.byType(CcIconButton), findsNothing);
  });

  testWidgets('demo failure offers no worktree retry action', (tester) async {
    await _pumpBanner(
      tester,
      isDemo: true,
      status: SpaceProvisioningStatus.failed,
    );
    expect(find.byType(CcButton), findsNothing);
  });
}

Future<void> _pumpBanner(
  WidgetTester tester, {
  TextDirection textDirection = TextDirection.ltr,
  bool isDemo = false,
  SpaceProvisioningStatus status = SpaceProvisioningStatus.provisioning,
}) async {
  await tester.pumpWidget(
    testWrap(
      ProviderScope(
        overrides: [
          spaceProvisioningStatusProvider.overrideWith((ref, _) => status),
          spaceProvisioningStepProvider.overrideWith(
            (ref, _) => const SpaceProvisioningStep(
              kind: SpaceProvisioningStepKind.prCheckout,
              subject: 'parced',
            ),
          ),
        ],
        child: const SizedBox(
          width: _bannerWidth,
          child: SpaceProvisioningBanner(spaceId: _spaceId),
        ),
      ),
      textDirection: textDirection,
      isDemo: isDemo,
    ),
  );
  await tester.pump();
}
