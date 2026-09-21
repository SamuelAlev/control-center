// Web bindings for the messaging services declared in `messaging_providers.dart`.
// A web thin client has no in-process agent dispatch / live streaming (and the cc_infra
// `MessagingService` / `AgentStreamProcessor` would drag the dispatch stack into the web
// compile), so both services run SERVER-SIDE over RPC:
// `buildMessagingService` returns an `RpcMessagingPort` over the RPC client.
// Agent DISPATCH (send-and-dispatch, dispatch agent, retry, refine, …) forwards to
// `dispatch.*` ops that only a `cc_server` running the dispatch engine registers; the
// agent reply streams back through the conversation view's existing
library;

import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/features/messaging/domain/ports/messaging_port.dart';
import 'package:cc_domain/features/messaging/domain/services/agent_question_service.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Agent dispatch + space lifecycle over RPC: every action executes on the
/// connected `cc_server` (spawned locally by desktop self-serve, or a remote
/// instance); the reply streams back via the existing `messaging.watchMessages`
/// subscription.
MessagingPort buildMessagingService(Ref ref) =>
    RpcMessagingPort(ref.watch(rpcClientProvider));

/// Real ask-the-user service over RPC: answering marks the persisted question
/// message answered server-side (the asking agent resumes server-side).
AgentQuestionService buildAgentQuestionService(Ref ref) =>
    AgentQuestionService(RpcMessagingRepository(ref.watch(rpcClientProvider)));
