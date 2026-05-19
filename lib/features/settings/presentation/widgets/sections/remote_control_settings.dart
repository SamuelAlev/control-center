/// Platform seam for the remote-control settings block (`RemoteControlSection`
/// + `PairedDevicesPanel`).
///
/// These surfaces host the desktop's in-process remote-control server, which
/// has no web equivalent (a web thin client is a remote client, not a host).
/// So the settings screen imports them through this seam: the real widgets on
/// the VM (`remote_control_settings_io.dart`), honest "not available on web"
/// placeholders on web (`remote_control_settings_web.dart`). This keeps the
/// VM-only remote-control server providers (cc_host/cc_server_core) off the web
/// compile graph.
library;

export 'remote_control_settings_io.dart'
    if (dart.library.js_interop) 'remote_control_settings_web.dart';
