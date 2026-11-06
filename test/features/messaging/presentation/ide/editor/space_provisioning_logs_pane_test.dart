import 'package:cc_domain/features/messaging/domain/value_objects/space_provisioning_status.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/space_provisioning_step.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/presentation/ide/editor/space_provisioning_logs_pane.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/messaging/providers/space_provisioning_log_provider.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../helpers/test_wrap.dart';

const _spaceId = 'space-1';

void main() {
  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  testWidgets('narrates the step above the output while it runs', (
    tester,
  ) async {
    await _pump(tester, lines: ['Fetching main']);

    expect(find.text(l10n.provisioningCloningRepo('shop-ui')), findsOneWidget);
    expect(find.byType(CcSpinner), findsOneWidget);
    expect(find.text('Fetching main'), findsOneWidget);
  });

  testWidgets('says the workspace failed, with the output kept', (
    tester,
  ) async {
    await _pump(
      tester,
      status: SpaceProvisioningStatus.failed,
      lines: ['fatal: no network'],
    );

    expect(find.text(l10n.workspacePrepFailed), findsOneWidget);
    expect(find.byType(CcSpinner), findsNothing);
    expect(find.text('fatal: no network'), findsOneWidget);
  });

  testWidgets('waits for output only while something can still print it', (
    tester,
  ) async {
    await _pump(tester);
    expect(find.text(l10n.environmentLogsWaiting), findsOneWidget);

    await _pump(tester, status: SpaceProvisioningStatus.ready);
    expect(find.text(l10n.noExecutionLogsYet), findsOneWidget);
  });

  testWidgets('copying has nothing to do until there is output', (
    tester,
  ) async {
    await _pump(tester);

    final copy = tester.widget<CcIconButton>(
      find.byWidgetPredicate(
        (widget) => widget is CcIconButton && widget.tooltip == l10n.copyLogs,
      ),
    );
    expect(copy.onPressed, isNull);
  });

  testWidgets('output stays left to right under an RTL locale', (tester) async {
    await _pump(
      tester,
      lines: ['Fetching main'],
      textDirection: TextDirection.rtl,
    );

    expect(
      Directionality.of(tester.element(find.text('Fetching main'))),
      TextDirection.ltr,
    );
  });

  testWidgets('a tab from another workspace shows nothing', (tester) async {
    await tester.pumpWidget(
      testWrap(
        spaceProvisioningLogsTabBody(const {
          'workspaceId': 'ws-other',
          'spaceId': _spaceId,
        }, 'ws-1'),
      ),
    );

    expect(find.byType(SpaceProvisioningLogsPane), findsNothing);
  });
}

Future<void> _pump(
  WidgetTester tester, {
  SpaceProvisioningStatus status = SpaceProvisioningStatus.provisioning,
  List<String> lines = const [],
  TextDirection textDirection = TextDirection.ltr,
}) async {
  await tester.pumpWidget(
    // A fresh scope per pump: the overrides differ between calls.
    ProviderScope(
      key: UniqueKey(),
      overrides: [
        spaceProvisioningStatusProvider.overrideWith((ref, _) => status),
        spaceProvisioningStepProvider.overrideWith(
          (ref, _) => const SpaceProvisioningStep(
            kind: SpaceProvisioningStepKind.repo,
            subject: 'shop-ui',
          ),
        ),
        spaceProvisioningLogLinesProvider.overrideWith(
          (ref, _) => Stream.value(lines),
        ),
      ],
      child: testWrap(
        const SpaceProvisioningLogsPane(workspaceId: 'ws-1', spaceId: _spaceId),
        textDirection: textDirection,
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}
