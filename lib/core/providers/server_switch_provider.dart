import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Switches the whole app to another paired server (or `local` on desktop).
///
/// Each composition root overrides this with its own mechanism — the desktop
/// rebuilds its provider tree around a fresh backend
/// (`DesktopServerSwitcher`), the web gate reconnects and remounts. The
/// settings server list calls it; nothing else should.
final serverSwitchHandlerProvider =
    Provider<Future<void> Function(String serverId)>(
      (ref) =>
          (_) async => throw StateError(
            'Server switching is not wired on this platform',
          ),
    );
