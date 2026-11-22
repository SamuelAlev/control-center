import 'dart:async';

import 'package:cc_data/cc_data.dart' show RpcAgentGoalRunRepository;
import 'package:cc_domain/cc_domain.dart' show UserDto;
import 'package:cc_domain/core/domain/value_objects/wake_context.dart';
import 'package:cc_domain/features/dispatch/domain/repositories/conversation_peer_asks_repository.dart';
import 'package:cc_domain/features/dispatch/domain/repositories/conversation_wakes_repository.dart';
import 'package:cc_domain/features/dispatch/domain/repositories/goal_run_view.dart';
import 'package:cc_domain/features/dispatch/domain/services/wake_admission.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_values.dart';
import 'package:cc_domain/features/messaging/domain/repositories/held_steering_repository.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/di/conversation_work_providers.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/messaging/providers/conversation_work_providers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/misc.dart' show Override;

import '../../../../../helpers/active_workspace.dart';

/// A fixed instant; due times are relative to the real clock, so fixtures
/// use [future] / [past] for "due later" and "due now".
final DateTime future = DateTime.now().toUtc().add(const Duration(hours: 2));

/// An instant already past.
final DateTime past = DateTime.now().toUtc().subtract(const Duration(hours: 1));

/// A wake view for the fakes.
WakeView wakeView({
  String id = 'wk-1',
  WakeReason reason = WakeReason.goalContinuation,
  WakeState state = WakeState.pending,
  String? stateReason,
  bool canRelease = true,
  String headline = 'your goal continues, segment 3',
  String? sourceAgentId,
  DateTime? notBefore,
  DateTime? expiresAt,
  int attempt = 0,
}) => WakeView(
  id: id,
  workspaceId: kTestWorkspaceId,
  spaceId: 'sp-1',
  conversationId: 'conv-1',
  agentId: 'agent-1',
  reason: reason,
  origin: reason.wire,
  headline: headline,
  state: state,
  stateReason: stateReason,
  lane: WakeLane.followUp,
  notBefore: notBefore ?? future,
  expiresAt: expiresAt,
  createdAt: past,
  canRelease: canRelease,
  attempt: attempt,
  sourceAgentId: sourceAgentId,
);

/// Records every wake call; its watch is overridden at the provider.
class FakeWakesRepository implements ConversationWakesRepository {
  /// Calls, as `op:arg`.
  final calls = <String>[];

  /// What `cancel` answers.
  bool cancelResult = true;

  /// What `deliverNow` answers.
  WakeReceipt receipt = const WakeStarted('run-1');

  /// Thrown by the next call when set.
  Object? error;

  @override
  Stream<List<WakeView>> watchForConversation(String w, String c) =>
      const Stream.empty();

  @override
  Future<bool> cancel(String workspaceId, String wakeId) async {
    calls.add('cancel:$workspaceId:$wakeId');
    if (error case final e?) {
      throw e;
    }
    return cancelResult;
  }

  @override
  Future<int> release(
    String workspaceId, {
    String? wakeId,
    String? conversationId,
  }) async {
    calls.add('release:$workspaceId:${wakeId ?? 'conv=$conversationId'}');
    if (error case final e?) {
      throw e;
    }
    return 1;
  }

  @override
  Future<WakeReceipt> deliverNow(String workspaceId, String wakeId) async {
    calls.add('deliverNow:$workspaceId:$wakeId');
    if (error case final e?) {
      throw e;
    }
    return receipt;
  }
}

/// Records held-steering releases.
/// Records releases of the Stop-held cards (the real repository sends
/// `steering.release` with `held_by: stop`).
class FakeHeldSteeringRepository implements HeldSteeringRepository {
  /// Calls.
  final calls = <String>[];

  /// Thrown by `release` when set.
  Object? error;

  @override
  Future<int> release({
    required String workspaceId,
    required String spaceId,
    required String conversationId,
  }) async {
    calls.add('release:$workspaceId:$spaceId:$conversationId');
    if (error case final e?) {
      throw e;
    }
    return 2;
  }
}

/// Records ask cancels.
class FakePeerAsksRepository implements ConversationPeerAsksRepository {
  /// Calls.
  final calls = <String>[];

  /// What `cancel` answers.
  bool cancelResult = true;

  @override
  Stream<List<PeerAskView>> watchForConversation(String w, String c) =>
      const Stream.empty();

  @override
  Future<bool> cancel(String workspaceId, String askId) async {
    calls.add('cancel:$workspaceId:$askId');
    return cancelResult;
  }
}

/// Records goal controls; its watches are overridden at the provider.
class FakeGoalRepository extends RpcAgentGoalRunRepository {
  /// Creates the fake over a channel nobody answers.
  FakeGoalRepository() : super(RemoteRpcClient(InProcessRpcChannel.pair().$2));

  /// Calls.
  final calls = <String>[];

  /// Thrown by the next call when set.
  Object? error;

  void _record(String call) {
    calls.add(call);
    if (error case final e?) {
      throw e;
    }
  }

  @override
  Future<void> pauseGoal(String workspaceId, String goalId) async =>
      _record('pause:$workspaceId:$goalId');

  @override
  Future<void> resumeGoal(
    String workspaceId,
    String goalId, {
    int? raiseCostCapMicros,
  }) async => _record('resume:$workspaceId:$goalId:$raiseCostCapMicros');

  @override
  Future<void> cancelGoal(String workspaceId, String goalId) async =>
      _record('cancel:$workspaceId:$goalId');

  @override
  Future<GoalRunView> approveCompletion(String workspaceId, String goalId) {
    _record('approve:$workspaceId:$goalId');
    return Completer<GoalRunView>().future;
  }
}

/// A server refusal carrying [kind].
RemoteRpcException refusal(String kind) =>
    RemoteRpcException(-32001, 'refused (server words)', {'kind': kind});

/// The overrides every work-surface test shares: the workspace, the fakes,
/// and agent names (`agent-2` is Ada, `agent-3` is Ben).
List<Override> workOverrides({
  FakeWakesRepository? wakes,
  FakeHeldSteeringRepository? held,
  FakePeerAsksRepository? asks,
  FakeGoalRepository? goals,
  List<WakeView> wakeList = const [],
  List<PeerAskView> askList = const [],
}) => [
  activeWorkspaceIdOverride(),
  conversationWakesRepositoryProvider.overrideWithValue(
    wakes ?? FakeWakesRepository(),
  ),
  heldSteeringRepositoryProvider.overrideWithValue(
    held ?? FakeHeldSteeringRepository(),
  ),
  conversationPeerAsksRepositoryProvider.overrideWithValue(
    asks ?? FakePeerAsksRepository(),
  ),
  agentGoalRunRepositoryProvider.overrideWithValue(
    goals ?? FakeGoalRepository(),
  ),
  conversationWakesProvider.overrideWith((ref, key) => Stream.value(wakeList)),
  conversationPeerAsksProvider.overrideWith(
    (ref, key) => Stream.value(askList),
  ),
  // The viewer is u-1; u-2 is a member the client knows by name.
  currentUserIdProvider.overrideWithValue('u-1'),
  usersByIdProvider.overrideWith(
    (ref) => Stream.value({
      'u-2': UserDto(id: 'u-2', handle: 'grace', displayName: 'Grace'),
    }),
  ),
  workAgentNameProvider.overrideWith(
    (ref, key) => const {'agent-2': 'Ada', 'agent-3': 'Ben'}[key.agentId],
  ),
];

/// The icon button whose tooltip is [tooltip] (`CcTooltip` is not a
/// `Tooltip`, so `find.byTooltip` never sees it).
Finder tip(String tooltip) =>
    find.byWidgetPredicate((w) => w is CcIconButton && w.tooltip == tooltip);
