/// Platform seam for the VM-backed messaging services named by the chat UI.
///
/// The chat widgets resolve `messagingServiceProvider` (typed as the web-safe
/// `cc_domain` [MessagingPort]) and `agentQuestionServiceProvider` and call
/// their action methods (open/delete/clear channel, send-and-dispatch, answer a
/// blocked agent's question). Those actions drive agent dispatch + live
/// streaming, which is desktop/server-only — `MessagingService` /
/// `AgentStreamProcessor` transitively pull the dispatch stack (flutter_pty,
/// embeddings). So the providers are DECLARED in `messaging_providers.dart`
/// (web-safe) and RESOLVED through the `build*` factories exported here: the
/// real cc_infra services on the VM (`messaging_bindings_io.dart`), honest "not
/// available on web" stubs on web (`messaging_bindings_web.dart`). Wiring these
/// over RPC so they work on web is a later phase.
library;

import 'package:cc_domain/features/messaging/domain/ports/messaging_port.dart' show MessagingPort;

export 'messaging_bindings_io.dart'
    if (dart.library.js_interop) 'messaging_bindings_web.dart';
