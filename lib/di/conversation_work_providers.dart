// Bindings of the long-running-work client repositories: wakes, held
// steering, questions between agents, schedules and improvement proposals.
// Each resolves to a `cc_data` adapter over the active RPC client; the
// server owns every decision and every write behind them.
library;

import 'package:cc_data/cc_data.dart'
    show
        RpcConversationPeerAsksRepository,
        RpcConversationWakesRepository,
        RpcHeldSteeringRepository,
        RpcImprovementInboxRepository,
        RpcWakeRuleScheduleRepository;
import 'package:cc_domain/features/dispatch/domain/repositories/conversation_peer_asks_repository.dart';
import 'package:cc_domain/features/dispatch/domain/repositories/conversation_wakes_repository.dart';
import 'package:cc_domain/features/dispatch/domain/repositories/improvement_inbox_repository.dart';
import 'package:cc_domain/features/dispatch/domain/repositories/wake_rule_schedule_repository.dart';
import 'package:cc_domain/features/messaging/domain/repositories/held_steering_repository.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A conversation's waiting wakes and a person's controls over them
/// (`wakes.*`).
final conversationWakesRepositoryProvider =
    Provider<ConversationWakesRepository>(
      (ref) => RpcConversationWakesRepository(ref.watch(rpcClientProvider)),
    );

/// Releasing the steering cards a person's Stop held (`steering.release`
/// with `held_by: stop`). A usage-limit pause's cards are never released by
/// hand: they go out when the pause resumes.
final heldSteeringRepositoryProvider = Provider<HeldSteeringRepository>(
  (ref) => RpcHeldSteeringRepository(ref.watch(rpcClientProvider)),
);

/// A conversation's questions to other agents (`peerAsks.*`).
final conversationPeerAsksRepositoryProvider =
    Provider<ConversationPeerAsksRepository>(
      (ref) => RpcConversationPeerAsksRepository(ref.watch(rpcClientProvider)),
    );

/// Schedules, loops and watches (`wakeRules.*`).
final wakeRuleScheduleRepositoryProvider = Provider<WakeRuleScheduleRepository>(
  (ref) => RpcWakeRuleScheduleRepository(ref.watch(rpcClientProvider)),
);

/// Improvement proposals (`improvements.*`).
final improvementInboxRepositoryProvider = Provider<ImprovementInboxRepository>(
  (ref) => RpcImprovementInboxRepository(ref.watch(rpcClientProvider)),
);
