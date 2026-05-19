// Web bindings for the messaging services declared in `messaging_providers.dart`.
//
// A web thin client has no in-process agent dispatch / live streaming (and the
// cc_infra `MessagingService` / `AgentStreamProcessor` would drag the dispatch
// stack into the web compile), so both services run SERVER-SIDE over RPC:
//
//   * `buildMessagingService` returns an `RpcMessagingPort` over the RPC client.
//     Channel LIFECYCLE (open DM, create/delete/clear channel, remove
//     participant) forwards to the DB-backed `messaging.*` ops, which EVERY host
//     registers — so those actions work even against a pure-Dart headless server.
//     Agent DISPATCH (send-and-dispatch, dispatch agent, retry, refine, …)
//     forwards to `dispatch.*` ops that only a host running the dispatch engine
//     registers (the desktop in-process host); the agent reply streams back
//     through the conversation view's existing `messaging.watchMessages`
//     subscription (the server-side `AgentStreamProcessor` persists transcript
//     segments to the message rows), so the web UI sees the live reply with no
//     extra wiring. Against a HEADLESS server (which omits the `dispatch.*` ops)
//     only the dispatch actions degrade loudly to "agent dispatch runs on the
//     server host".
//   * `buildAgentQuestionService` returns a REAL `AgentQuestionService` over the
//     RPC messaging repository — submitting an answer marks the persisted
//     question message answered server-side (a genuine, not faked, action). The
//     local completer-unblock is inert on web (the agent is blocked
//     server-side and resumes there).
library;

import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/features/messaging/domain/ports/messaging_port.dart';
import 'package:cc_infra/src/messaging/agent_question_service.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Agent dispatch + channel lifecycle over RPC: every action executes on the
/// server host (the desktop in-process host runs the dispatch engine); the reply
/// streams back via the existing `messaging.watchMessages` subscription.
MessagingPort buildMessagingService(Ref ref) =>
    RpcMessagingPort(ref.watch(rpcClientProvider));

/// Real ask-the-user service over RPC: answering marks the persisted question
/// message answered server-side (the asking agent resumes server-side).
AgentQuestionService buildAgentQuestionService(Ref ref) =>
    AgentQuestionService(RpcMessagingRepository(ref.watch(rpcClientProvider)));
