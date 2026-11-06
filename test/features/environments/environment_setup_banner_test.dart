import 'package:cc_domain/features/environments/domain/entities/space_environment.dart';
import 'package:cc_domain/features/environments/domain/value_objects/environment_status.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/environments/presentation/widgets/environment_terminal_banner.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/test_wrap.dart';
import 'environment_test_support.dart';

const _reason = 'This terminal opened because the start needs you';

const _hostSetup = EnvironmentError(
  code: 'hosts',
  message: 'Adding the hostnames needs sudo',
  exitCode: 3,
);

Future<void> _pump(
  WidgetTester tester,
  List<SpaceEnvironment> environments, {
  TextDirection? textDirection,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        environmentRepositoryProvider.overrideWithValue(
          FakeEnvironmentRepository(environments: environments),
        ),
      ],
      child: testWrap(
        const EnvironmentSetupBanner(workspaceId: kWorkspace, spaceId: kSpace),
        textDirection: textDirection,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('EnvironmentSetupBanner', () {
    testWidgets('says why the tab opened and what the tool wants', (
      tester,
    ) async {
      await _pump(tester, [
        environment(status: EnvironmentStatus.failed, lastError: _hostSetup),
      ]);

      expect(find.text(_reason), findsOneWidget);
      expect(
        find.textContaining('Adding the hostnames needs sudo'),
        findsOneWidget,
      );
    });

    testWidgets('goes once the start has carried on', (tester) async {
      // The row keeps its last error until the start lands.
      await _pump(tester, [
        environment(status: EnvironmentStatus.starting, lastError: _hostSetup),
      ]);

      expect(find.text(_reason), findsNothing);
    });

    testWidgets('stays away from any other failure', (tester) async {
      await _pump(tester, [
        environment(
          status: EnvironmentStatus.failed,
          lastError: const EnvironmentError(code: 'boom', message: 'Broke'),
        ),
      ]);

      expect(find.text(_reason), findsNothing);
    });

    testWidgets('lays out right to left', (tester) async {
      await _pump(tester, [
        environment(status: EnvironmentStatus.failed, lastError: _hostSetup),
      ], textDirection: TextDirection.rtl);

      expect(tester.takeException(), isNull);
      expect(find.text(_reason), findsOneWidget);
    });
  });
}
