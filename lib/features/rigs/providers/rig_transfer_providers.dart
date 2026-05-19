// The clipboard/file bridge into a rig, wired for the widget layer.
//
// The providers layer is where presentation reaches data — a rule the
// architecture ratchet enforces (`presentation layer does not import data
// layer`), and one this feature has to satisfy in an awkward shape: the
// bridge's dependency is the connection's [MediaProxyConfig], which lives in
// an InheritedWidget rather than in Riverpod. So the seam is a factory that
// takes a BuildContext instead of a `Provider`, and the types are re-exported
// here so a widget names them without importing `data/`.
library;

import 'package:control_center/features/rigs/data/rig_clipboard_bridge.dart';
import 'package:control_center/features/rigs/data/rig_transfer_client.dart';
import 'package:control_center/shared/widgets/media_proxy_scope.dart';
import 'package:flutter/widgets.dart';

export 'package:control_center/features/rigs/data/rig_clipboard_bridge.dart'
    show RigClipboardBridge, RigClipboardOutcome;
export 'package:control_center/features/rigs/data/rig_transfer_client.dart'
    show RigOutgoingFile, RigTransferAck, RigTransferClient;

/// Builds a transfer client for the currently connected server, or null when
/// there is no live connection.
///
/// The caller owns the returned client and must [RigTransferClient.close] it:
/// it holds an HTTP client whose connection pool would otherwise outlive the
/// panel that opened it. Rebuilt when the connection changes — the signed URLs
/// it mints are bound to one device pairing.
RigTransferClient? rigTransferClientFor(BuildContext context) {
  final proxy = MediaProxyScope.configOf(context);
  return proxy == null ? null : RigTransferClient(proxy: proxy);
}

/// Builds the clipboard/file bridge to [rigId] over [client].
RigClipboardBridge rigClipboardBridgeFor({
  required RigTransferClient client,
  required String workspaceId,
  required String rigId,
}) => RigClipboardBridge(
  transfer: client,
  workspaceId: workspaceId,
  rigId: rigId,
);
