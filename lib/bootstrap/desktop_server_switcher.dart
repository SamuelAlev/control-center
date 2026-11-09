import 'dart:async';

import 'package:control_center/app/app_windows.dart' show runBootFailureWindow;
import 'package:control_center/bootstrap/desktop_app_host.dart';
import 'package:control_center/bootstrap/desktop_session.dart';
import 'package:control_center/bootstrap/server_backend.dart';
import 'package:control_center/bootstrap/server_connect_controller.dart';
import 'package:control_center/core/server/server_connection_config.dart';
import 'package:control_center/core/server/server_pairing.dart';
import 'package:control_center/core/server/sso_pair_link.dart';
import 'package:control_center/core/utils/app_log.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show runWidget;

/// App-global handle the settings UI uses to switch the desktop between
/// paired servers without a restart (PRD 15 §10 fast switch). The host widget
/// rebuilds the whole provider tree around the new session.
class DesktopServerSwitcher {
  DesktopServerSwitcher._();

  /// The process-wide instance.
  static final DesktopServerSwitcher instance = DesktopServerSwitcher._();

  final ServerConnectController<DesktopBackendSession> _sessions =
      ServerConnectController(retire: (session) => session.dispose());
  DesktopSessionEnv? _env;

  /// True while [returnToSetup] has the setup window up instead of the app.
  bool _inSetup = false;

  /// The live session (the host widget renders it).
  DesktopBackendSession? get current => _sessions.current;

  /// Bumped on every adopted session; the host remounts the session UI.
  ValueListenable<int> get generation => _sessions.generation;

  /// Adopts the boot session and the process-wide [env] every later session is
  /// built from.
  void start(DesktopBackendSession session, DesktopSessionEnv env) {
    _env = env;
    _sessions.adopt(session);
  }

  /// Builds a session for [backend], wired to this switcher's actions.
  Future<DesktopBackendSession> buildSession(
    ServerBackend backend,
    DesktopSessionEnv env,
  ) => DesktopBackendSession.build(
    backend: backend,
    env: env,
    switchServer: switchTo,
    returnToSignIn: returnToSetup,
  );

  /// Adopts only an expected, client-held decrypted SSO handoff. The browser
  /// deep link contains ciphertext, never the minted device credential.
  Future<void> adoptPairLink(String rawUrl) async {
    final env = _env;
    if (env == null || _inSetup) {
      // Pre-app (the server-setup window started the browser round-trip):
      // park the credential for the setup screen, which is listening.
      AppLog.w(
        'deep-link',
        'pair link arrived before backend init — parked for the setup screen',
      );
      pendingSsoPairLink.value = rawUrl;
      return;
    }
    if (isIdpInitiatedSsoPairLink(rawUrl)) {
      // A valid IdP-initiated credential is still unbidden to this running
      // session. The setup window asks for explicit server approval.
      pendingSsoPairLink.value = rawUrl;
      unawaited(returnToSetup());
      return;
    }
    final payload = await decodeSsoPairLink(rawUrl);
    if (payload == null) {
      AppLog.w('deep-link', 'ignoring invalid or unbidden SSO handoff');
      return;
    }
    final connection = await pairWithServer(
      store: ServerConnectionStore(env.prefs, env.secureStore),
      rawUrl: payload.server,
      platform: 'desktop',
      deviceId: payload.deviceId,
      psk: payload.psk,
    );
    await connection.dispose();
    await switchTo(connection.entry.serverId);
  }

  /// Switches to [serverId] (a paired server id, or `local`): resolves the new
  /// backend, remounts the app around it and only then retires the old
  /// session.
  ///
  /// Throws on connect failure — the caller surfaces the error and the current
  /// session stays live. One switch runs at a time (see
  /// [ServerConnectController.switchTo]), and a switch to `local` while the
  /// bundled server already backs this session is a no-op: a second spawn
  /// would open the same data directory twice.
  Future<void> switchTo(String serverId) async {
    final env = _env;
    if (env == null || _inSetup) {
      throw StateError('Desktop backend not initialised yet');
    }
    if (serverId == localServerId && (current?.backend.isLocal ?? false)) {
      return;
    }
    await _sessions.switchTo(serverId, () async {
      final backend = await resolveServerBackend(
        prefs: env.prefs,
        secureStore: env.secureStore,
        forceServerId: serverId,
      );
      try {
        return await buildSession(backend, env);
      } on Object {
        // `resolveServerBackend` may have SPAWNED a local cc_server child. If
        // the session build then fails we keep the old session (correct) —
        // but that child would be orphaned, holding the SQLite file open
        // against every later switch. Dispose it before surfacing the failure.
        await backend.dispose();
        rethrow;
      }
    });
  }

  /// Leaves the running app for the server setup window: the "sign in"
  /// action of the lost-connection dialog. Pairings are kept, so the user can
  /// reconnect to the same server, pick another or run locally.
  ///
  /// Unlike [switchTo], this replaces the whole native-window tree: the setup
  /// window is a separate pre-app surface with no provider container. The
  /// current session (with a bundled `cc_server`, if it spawned one) is torn
  /// down only after the frame that shows setup, once nothing mounted still
  /// reads its container, and the app remounts in a fresh primary window
  /// around the backend the user resolves there.
  Future<void> returnToSetup() async {
    final env = _env;
    if (env == null || _inSetup || _sessions.isSwitching) {
      return;
    }
    _inSetup = true;
    final old = _sessions.detach();
    final oldClosed = Completer<void>();
    final setup = showServerSetup(
      ServerConnectionStore(env.prefs, env.secureStore),
      previousSessionClosed: oldClosed.future,
    );
    retireAfterFrame(() async {
      try {
        await old?.dispose();
      } on Object catch (e) {
        AppLog.w('cc_server', 'tearing down the left session failed: $e');
      } finally {
        oldClosed.complete();
      }
    });
    final backend = await setup;
    await oldClosed.future;
    final DesktopBackendSession next;
    try {
      next = await buildSession(backend, env);
    } on Object catch (error, stack) {
      // No window is left to report into: the setup window is resolved and
      // the app tree is gone. Same last resort as a failed boot.
      await backend.dispose();
      _inSetup = false;
      AppLog.e('cc_server', 'session build after setup failed', error, stack);
      runBootFailureWindow(error, stack);
      return;
    }
    _inSetup = false;
    _sessions.adopt(next);
    runWidget(const DesktopAppHost());
  }
}
