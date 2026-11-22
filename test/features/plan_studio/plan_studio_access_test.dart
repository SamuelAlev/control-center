import 'package:cc_data/cc_data.dart' show RemotePlanStudioRepository;
import 'package:cc_domain/cc_domain.dart' show RpcErrorCodes;
import 'package:cc_domain/features/orchestration/domain/entities/orchestration.dart';
import 'package:cc_domain/features/orchestration/domain/entities/orchestration_proposal.dart';
import 'package:cc_domain/features/orchestration/domain/entities/orchestration_status.dart';
import 'package:cc_domain/features/plan_studio/domain/entities/orchestration_revision.dart';
import 'package:cc_rpc/cc_rpc.dart' show RemoteRpcException;
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/di/demo_providers.dart';
import 'package:control_center/features/orchestration/providers/orchestration_providers.dart';
import 'package:control_center/features/plan_studio/presentation/plan_studio_access.dart';
import 'package:control_center/features/plan_studio/presentation/screens/plan_studio_screen.dart';
import 'package:control_center/features/plan_studio/providers/plan_studio_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/l10n/app_localizations_en.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../dispatch/presentation/long_work/long_work_harness.dart';

RemoteRpcException _grant(String level) => RemoteRpcException(
  RpcErrorCodes.unauthorized,
  'no grant (server words)',
  {'kind': 'repo_grant_required', 'level': level},
);

/// Records the studio's calls and fails each with [refuse] when set.
class _FakePlanRepo implements RemotePlanStudioRepository {
  final calls = <String>[];
  Object? refuse;

  Future<void> _call(String name) async {
    calls.add(name);
    if (refuse case final e?) {
      throw e;
    }
  }

  @override
  Future<void> approve(String id, {Set<String>? approvedNodeKeys}) =>
      _call('approve:$id');

  @override
  Future<void> approveNodes(
    String id,
    Set<String> nodeKeys, {
    String? workspaceId,
  }) => _call('approveNodes:$id:${nodeKeys.join(',')}');

  @override
  Future<void> continueNode(String id, String nodeKey) =>
      _call('continueNode:$id:$nodeKey');

  @override
  Future<void> cancel(String id, {String? workspaceId}) => _call('cancel:$id');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _proposal = OrchestrationProposal(
  goal: 'Ship the release notes',
  roles: [
    ProposedRole(roleKey: 'lead', title: 'Lead', existingAgentId: 'agent-1'),
  ],
  subTickets: [
    ProposedSubTicket(
      key: 'draft',
      title: 'Draft the notes',
      roleKey: 'lead',
      expectedOutputSchema: {
        'type': 'object',
        'required': ['summary'],
        'properties': {
          'summary': {'type': 'string'},
        },
      },
    ),
  ],
  synthesis: SynthesisSpec(
    roleKey: 'lead',
    prompt: 'Merge the drafts',
    outputSchema: {
      'type': 'object',
      'required': ['deliverable', 'gaps'],
      'properties': {
        'deliverable': {'type': 'string'},
        'gaps': {
          'type': 'array',
          'items': {'type': 'string'},
        },
      },
    },
  ),
);

void main() {
  final AppLocalizations en = AppLocalizationsEn();

  group('messages and access', () {
    test('a write refusal names write access and stops writing', () {
      final access = const PlanStudioAccess().after(_grant('write'));
      expect(planActionFailureMessage(en, _grant('write')), en.planNeedsWrite);
      expect(access.mayWrite, isFalse);
      expect(access.mayWiden, isFalse);
      expect(access.reason(en, executing: false), en.planNeedsWrite);
    });

    test('a read refusal uses the space wording and lowers nothing', () {
      expect(
        planActionFailureMessage(en, _grant('read')),
        en.spaceAccessNoGrant,
      );
      expect(
        const PlanStudioAccess().after(_grant('read')),
        const PlanStudioAccess(),
      );
    });

    test('not yours maps by kind and stops widening only', () {
      final e = refusal('orchestration_not_yours');
      expect(planActionFailureMessage(en, e), en.orchestrationRefusalNotYours);
      expect(en.orchestrationRefusalNotYours, isNot(contains('cap')));
      final access = const PlanStudioAccess().after(e);
      expect(access.mayWrite, isTrue);
      expect(access.mayWiden, isFalse);
      expect(access.reason(en, executing: false), isNull);
      expect(
        access.reason(en, executing: true),
        en.orchestrationRefusalNotYours,
      );
    });

    test('an unknown kind shows the lead-in and the kind, not the message', () {
      final message = planActionFailureMessage(en, refusal('mystery_kind'));
      expect(message, contains('mystery_kind'));
      expect(message, isNot(contains('server words')));
    });
  });

  group('screen', () {
    late _FakePlanRepo repo;

    setUp(() => repo = _FakePlanRepo());

    Future<void> pumpStudio(
      WidgetTester tester,
      OrchestrationStatus status, {
      TextDirection? dir,
    }) => pumpLongWork(
      tester,
      const PlanStudioScreen(
        workspaceId: kTestWorkspaceId,
        kind: 'orchestration',
        id: 'orch-1',
        showPageHeader: false,
      ),
      overrides: [
        ...longWorkOverrides(),
        orchestrationProvider.overrideWith(
          (ref, args) => Stream.value(
            Orchestration(
              id: 'orch-1',
              workspaceId: kTestWorkspaceId,
              proposal: _proposal,
              status: status,
              createdAt: t0,
              updatedAt: t0,
            ),
          ),
        ),
        orchestrationRevisionsProvider.overrideWith(
          (ref, id) => Stream.value(const <OrchestrationRevision>[]),
        ),
        planDivergenceProvider.overrideWith(
          (ref, id) => Stream.value(const <String, dynamic>{}),
        ),
        isDemoServerProvider.overrideWithValue(false),
        planStudioRepositoryProvider.overrideWithValue(repo),
      ],
      textDirection: dir,
    );

    AppLocalizations l10n(WidgetTester tester) =>
        AppLocalizations.of(tester.element(find.byType(PlanStudioScreen)));

    CcButton button(WidgetTester tester, String label) =>
        tester.widget<CcButton>(
          find.ancestor(of: find.text(label), matching: find.byType(CcButton)),
        );

    testWidgets('approve refused for want of write access stays off', (
      tester,
    ) async {
      repo.refuse = _grant('write');
      await pumpStudio(tester, OrchestrationStatus.proposed);
      final l = l10n(tester);
      await tester.tap(find.text(l.planApprove));
      await tester.pumpAndSettle();
      expect(repo.calls, ['approve:orch-1']);
      expect(find.text(l.planNeedsWrite), findsOneWidget);
      expect(find.textContaining('server words'), findsNothing);
      expect(button(tester, l.planApprove).onPressed, isNull);
      // Reject stays: the brake is open to anyone who may read the space.
      expect(button(tester, l.planReject).onPressed, isNotNull);

      // The reason stays after another action clears the error.
      repo.refuse = null;
      await tester.tap(find.text(l.planReject));
      await tester.pumpAndSettle();
      expect(find.text(l.planNeedsWrite), findsOneWidget);
      expect(button(tester, l.planApprove).onPressed, isNull);
    });

    testWidgets('widening refused as not yours drops the widen action', (
      tester,
    ) async {
      repo.refuse = refusal('orchestration_not_yours');
      await pumpStudio(tester, OrchestrationStatus.executing);
      final l = l10n(tester);
      await tester.tap(find.text('Draft the notes').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text(l.planApproveSelectedNodes));
      await tester.pumpAndSettle();
      expect(repo.calls, ['approveNodes:orch-1:draft']);
      expect(find.text(l.orchestrationRefusalNotYours), findsOneWidget);
      expect(find.text(l.planApproveSelectedNodes), findsNothing);
      expect(button(tester, l.planCancel).onPressed, isNotNull);
    });

    testWidgets('the lowered bar lays out right to left', (tester) async {
      repo.refuse = _grant('write');
      await pumpStudio(
        tester,
        OrchestrationStatus.proposed,
        dir: TextDirection.rtl,
      );
      await tester.tap(find.text(l10n(tester).planApprove));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text(l10n(tester).planNeedsWrite), findsOneWidget);
    });
  });
}
