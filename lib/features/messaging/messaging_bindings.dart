/// Platform seam for the server-backed messaging services named by the chat UI.
///
/// The providers in `messaging_providers.dart` expose the web-safe
/// [MessagingPort] and agent-question service. Both desktop and web bindings
/// forward actions to the connected server over RPC; dispatch, native PTYs
/// and embeddings remain server-owned.
library;

import 'package:cc_domain/features/messaging/domain/ports/messaging_port.dart'
    show MessagingPort;

export 'messaging_bindings_io.dart'
    if (dart.library.js_interop) 'messaging_bindings_web.dart';
