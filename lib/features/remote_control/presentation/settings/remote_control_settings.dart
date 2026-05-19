/// Platform seam for the remote-control settings block (`PairedDevicesPanel`).
///
/// This surface drives the server-owned pairing flow over the connected RPC
/// client. The settings screen imports it through this seam: the real widget
/// on the VM (`remote_control_settings_io.dart`), the same widget over the
/// web-safe providers on web (`remote_control_settings_web.dart`). This keeps
/// the VM-only remote-control server providers (cc_host/cc_server_core) off
/// the web compile graph.
library;

export 'remote_control_settings_io.dart'
    if (dart.library.js_interop) 'remote_control_settings_web.dart';
