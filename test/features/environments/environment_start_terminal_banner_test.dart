import 'dart:async';

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
const _done = 'Done here. The environment is still starting';
const _session = 'session-1';

/// A start that waits for someone on terminal [sessionId].
SpaceEnvironment _waiting([String sessionId = _session]) => environment(
  status: EnvironmentStatus.creating,
  components: [
    EnvironmentComponentState(
      id: 'tool',
      kind: 'cli',
      state: 'interactive',
      sessionId: sessionId,
      detail: 'Adding the hostnames needs sudo',
    ),
  ],
);

Future<void> _pump(
  WidgetTester tester,
  FakeEnvironmentRepository repository, {
  String? sessionId = _session,
  TextDirection? textDirection,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [environmentRepositoryProvider.overrideWithValue(repository)],
      child: testWrap(
        EnvironmentStartTerminalBanner(
          workspaceId: kWorkspace,
          spaceId: kSpace,
          sessionId: sessionId,
        ),
        textDirection: textDirection,
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

FakeEnvironmentRepository _showing(SpaceEnvironment row) =>
    FakeEnvironmentRepository(environments: [row]);

void main() {
  group('EnvironmentStartTerminalBanner', () {
    testWidgets('says why the tab opened and what the tool wants', (
      tester,
    ) async {
      await _pump(tester, _showing(_waiting()));

      expect(find.text(_reason), findsOneWidget);
      expect(
        find.textContaining('Adding the hostnames needs sudo'),
        findsOneWidget,
      );
    });

    testWidgets('says the start carries on once the tool is done here', (
      tester,
    ) async {
      final rows = StreamController<List<SpaceEnvironment>>();
      addTearDown(rows.close);
      rows.add([_waiting()]);
      await _pump(tester, FakeEnvironmentRepository()..liveRows = rows.stream);
      expect(find.text(_reason), findsOneWidget);

      rows.add([environment(status: EnvironmentStatus.creating)]);
      await tester.pump();
      await tester.pump();
      expect(find.text(_reason), findsNothing);
      expect(find.text(_done), findsOneWidget);

      rows.add([environment()]);
      await tester.pump();
      await tester.pump();
      expect(find.text(_done), findsNothing);
    });

    testWidgets('a tab restored later says nothing', (tester) async {
      for (final row in [
        environment(status: EnvironmentStatus.starting),
        environment(),
        environment(
          status: EnvironmentStatus.blocked,
          lastError: const EnvironmentError(
            code: 'hosts',
            message: 'Adding the hostnames needs sudo',
            exitCode: 3,
          ),
        ),
      ]) {
        await _pump(tester, _showing(row));

        expect(find.text(_reason), findsNothing, reason: row.status.wire);
        expect(find.text(_done), findsNothing, reason: row.status.wire);
        await tester.pumpWidget(const SizedBox.shrink());
      }
    });

    testWidgets('a wait on another terminal is not this tab\'s', (
      tester,
    ) async {
      await _pump(tester, _showing(_waiting('session-2')));

      expect(find.text(_reason), findsNothing);
    });

    testWidgets('a tab that does not know its session shows the wait', (
      tester,
    ) async {
      await _pump(tester, _showing(_waiting()), sessionId: null);

      expect(find.text(_reason), findsOneWidget);
    });

    testWidgets('lays out right to left', (tester) async {
      await _pump(
        tester,
        _showing(_waiting()),
        textDirection: TextDirection.rtl,
      );

      expect(tester.takeException(), isNull);
      expect(find.text(_reason), findsOneWidget);
    });
  });
}
