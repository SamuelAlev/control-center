// Desktop (thin-client) bindings for the messaging services declared in
// `messaging_providers.dart`.
//
// The desktop opens no local database and runs no in-process dispatch engine —
// it is a thin client; `databaseProvider` throws and `rpcClientProvider` is the
// connected (spawned) `cc_server`. So both services run SERVER-SIDE over RPC,
// identical to the web client:
//
//   * `buildMessagingService` returns an `RpcMessagingPort` — every action
//     (open/delete/clear channel, send-and-dispatch, dispatch agent, retry,
//     refine, create group, …) forwards to the host's `dispatch.*` ops and
//     executes on the server that runs the dispatch engine. The agent reply
//     streams back through the conversation view's existing
//     `messaging.watchMessages` subscription (the server-side
//     `AgentStreamProcessor` persists transcript segments to the message rows).
//   * `buildAgentQuestionService` returns a REAL `AgentQuestionService` over the
//     RPC messaging repository — submitting an answer marks the persisted
//     question message answered server-side (the asking agent resumes there).
library;

import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/features/messaging/domain/ports/messaging_port.dart';
import 'package:cc_infra/src/messaging/agent_question_service.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Agent dispatch + channel lifecycle over RPC: every action executes on the
/// server host; the reply streams back via the existing `messaging.watchMessages`
/// subscription.
MessagingPort buildMessagingService(Ref ref) =>
    RpcMessagingPort(ref.watch(rpcClientProvider));

/// Real ask-the-user service over RPC: answering marks the persisted question
/// message answered server-side (the asking agent resumes server-side).
AgentQuestionService buildAgentQuestionService(Ref ref) =>
    AgentQuestionService(RpcMessagingRepository(ref.watch(rpcClientProvider)));
