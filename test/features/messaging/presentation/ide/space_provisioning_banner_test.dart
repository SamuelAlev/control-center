import 'package:cc_domain/features/messaging/domain/value_objects/space_provisioning_status.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/space_provisioning_step.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/presentation/ide/editor/conversation_pane.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/shared/widgets/composer/composer.dart'
    show composerHorizontalMargin;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_wrap.dart';

const _spaceId = 'space-1';
const _bannerWidth = 600.0;

void main() {
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
