import 'package:control_center/core/desktop/desktop_shell.dart';
import 'package:dbus/dbus.dart';

/// The session-bus names a StatusNotifierItem host registers under.
///
/// KDE Plasma, Cinnamon, XFCE, Budgie and GNOME's AppIndicator extension own
/// one of these; stock GNOME owns neither, and an icon exported there is
/// simply never drawn. The `com.canonical` name is what older Ubuntu
/// indicator hosts use.
const List<String> _watcherNames = [
  'org.kde.StatusNotifierWatcher',
  'com.canonical.StatusNotifierWatcher',
];

/// Whether this Linux session shows tray icons at all.
///
/// Asks the session bus whether a StatusNotifierWatcher exists. When the
/// question cannot be asked (no session bus, a sandbox that hides it) it
/// answers [TrayHostState.available]: a desktop the probe cannot inspect
/// should keep the operator's choice, not lose close-to-tray on a guess.
Future<TrayHostState> probeLinuxTrayHost() async {
  final DBusClient client;
  try {
    client = DBusClient.session();
  } on Object {
    return TrayHostState.available;
  }
  try {
    for (final name in _watcherNames) {
      if (await client.nameHasOwner(name).timeout(const Duration(seconds: 2))) {
        return TrayHostState.available;
      }
    }
    return TrayHostState.missing;
  } on Object {
    return TrayHostState.available;
  } finally {
    await client.close();
  }
}
