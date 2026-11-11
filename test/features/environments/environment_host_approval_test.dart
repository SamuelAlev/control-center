import 'dart:convert';

import 'package:cc_domain/cc_domain.dart' show RpcErrorCodes;
import 'package:cc_domain/features/environments/domain/entities/environment_definition_record.dart';
import 'package:cc_domain/features/environments/domain/value_objects/environment_host_approval.dart';
import 'package:cc_domain/features/environments/domain/value_objects/environment_status.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/environments/presentation/widgets/environment_feedback.dart';
import 'package:control_center/features/environments/presentation/widgets/environment_host.dart';
import 'package:control_center/features/environments/presentation/widgets/environment_host_approval.dart';
import 'package:control_center/features/environments/presentation/widgets/environment_section.dart';
import 'package:control_center/features/environments/providers/environment_providers.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/l10n/app_localizations_en.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/test_wrap.dart';
import 'environment_test_support.dart';

const _ownerNotice = 'Runs on this server. Approve it to let it start.';
const _memberNotice =
    'Runs on this server. The server owner has to approve it before it can '
    'start.';
const _serverWords = 'definition def-1 runs on the host and is not approved';

Future<void> _pumpNotice(
  WidgetTester tester,
  FakeEnvironmentRepository repository,
  EnvironmentDefinitionRecord record, {
  required bool owner,
  TextDirection? textDirection,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        environmentRepositoryProvider.overrideWithValue(repository),
        canUseHostProvider.overrideWithValue(owner),
      ],
      child: testWrap(
        EnvironmentHostApprovalNotice(record: record),
        textDirection: textDirection,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpSection(
  WidgetTester tester,
  FakeEnvironmentRepository repository, {
  required bool owner,
}) async {
  tester.view.physicalSize = const Size(420, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        environmentRepositoryProvider.overrideWithValue(repository),
        environmentEndpointsAreRemoteProvider.overrideWithValue(false),
        canUseHostProvider.overrideWithValue(owner),
      ],
      child: testWrap(
        EnvironmentHostScope(
          host: RecordingHost().host,
          child: const SingleChildScrollView(
            child: EnvironmentSection(workspaceId: kWorkspace, spaceId: kSpace),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  final held = definitionRecord(runsOnHost: true);

  group('definition notice', () {
    testWidgets('the owner approves by saving the definition unchanged', (
      tester,
    ) async {
      final repository = FakeEnvironmentRepository(definitions: [held]);
      await _pumpNotice(tester, repository, held, owner: true);

      expect(find.text(_ownerNotice), findsOneWidget);
      expect(find.text(_memberNotice), findsNothing);

      await tester.tap(find.text('Approve'));
      await tester.pumpAndSettle();
      expect(repository.calls, contains('setDefinition'));
      expect(repository.savedDefinition, jsonDecode(held.definitionJson));
    });

    testWidgets('anyone else is told the owner must approve, with no button', (
      tester,
    ) async {
      final repository = FakeEnvironmentRepository(definitions: [held]);
      await _pumpNotice(tester, repository, held, owner: false);

      expect(find.text(_memberNotice), findsOneWidget);
      expect(find.text(_ownerNotice), findsNothing);
      expect(find.text('Approve'), findsNothing);
      expect(repository.calls, isNot(contains('setDefinition')));
    });

    testWidgets('an approved or rig definition shows nothing', (tester) async {
      final repository = FakeEnvironmentRepository();
      final approved = definitionRecord(runsOnHost: true, hostApproved: true);
      await _pumpNotice(tester, repository, approved, owner: true);
      expect(find.text(_ownerNotice), findsNothing);

      await _pumpNotice(tester, repository, definitionRecord(), owner: true);
      expect(find.text(_ownerNotice), findsNothing);
    });

    testWidgets('lays out under RTL', (tester) async {
      final repository = FakeEnvironmentRepository(definitions: [held]);
      await _pumpNotice(
        tester,
        repository,
        held,
        owner: true,
        textDirection: TextDirection.rtl,
      );
      expect(find.text(_ownerNotice), findsOneWidget);
      expect(find.text('Approve'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('held by kind', () {
    final heldEnvironment = environment(
      status: EnvironmentStatus.failed,
      lastError: const EnvironmentError(
        code: environmentHostUnapprovedKind,
        message: _serverWords,
      ),
    );

    testWidgets('a member sees the app words, never the server sentence', (
      tester,
    ) async {
      final repository = FakeEnvironmentRepository(
        eligibleDefinitions: [held],
        definitions: [held],
        environments: [heldEnvironment],
      );
      await _pumpSection(tester, repository, owner: false);

      expect(
        find.text(
          "The server owner hasn't approved this environment yet, so it "
          "can't run on this server.",
        ),
        findsOneWidget,
      );
      expect(find.textContaining(_serverWords), findsNothing);
      expect(find.text('Review and approve'), findsNothing);
    });

    testWidgets('the owner is told it waits on them and led to it', (
      tester,
    ) async {
      final repository = FakeEnvironmentRepository(
        eligibleDefinitions: [held],
        definitions: [held],
        environments: [heldEnvironment],
      );
      await _pumpSection(tester, repository, owner: true);

      expect(
        find.text(
          "You haven't approved this environment yet. It runs on this "
          'server, so it starts once you approve its definition.',
        ),
        findsOneWidget,
      );
      expect(find.textContaining(_serverWords), findsNothing);
      expect(find.text('Review and approve'), findsOneWidget);
    });

    test('an RPC refusal is worded by its kind, anything else as sent', () {
      final l10n = AppLocalizationsEn();
      final refusal = RemoteRpcException(
        RpcErrorCodes.unauthorized,
        _serverWords,
        {'kind': environmentHostUnapprovedKind},
      );
      expect(
        environmentRefusalMessage(l10n, refusal, owner: false),
        l10n.environmentHostUnapproved,
      );
      expect(
        environmentRefusalMessage(l10n, refusal, owner: true),
        l10n.environmentHostUnapprovedOwner,
      );
      final other = RemoteRpcException(
        RpcErrorCodes.unauthorized,
        'something else',
        {'kind': 'environment.other'},
      );
      expect(
        environmentRefusalMessage(l10n, other, owner: true),
        isNot(l10n.environmentHostUnapprovedOwner),
      );
    });
  });
}
