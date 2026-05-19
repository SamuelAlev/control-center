import 'dart:async';

import 'package:control_center/app/focus_primary_window.dart';
import 'package:control_center/core/utils/app_log.dart';
import 'package:control_center/features/meetings/presentation/notifiers/meeting_recorder_controller.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/router/app_router.dart';
import 'package:control_center/router/routes.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Owns the floating meeting-recording toolbar window from the main isolate.
///
/// The toolbar (see `MeetingToolbarWindow`) is now a sibling window in the same
/// isolate, so it reads recorder state directly and there is no cross-engine
/// IPC, snapshot mirroring, or launch token. This controller's entire job is the
/// single bool — whether the toolbar is floating — plus the policy around it:
/// auto-pop when the user switches to another app mid-recording, auto-retire
/// when the recording ends, and orchestrate stop.
class MeetingToolbarController extends Notifier<bool> {
  /// Guards against two concurrent [open] calls (e.g. a blur event racing a
  /// pop-out tap) flipping state inconsistently.
  bool _opening = false;

  @override
  bool build() {
    // Tear the toolbar down when the recording ends from anywhere (record
    // screen, in-app HUD, stop).
    ref.listen(meetingRecorderControllerProvider, (prev, next) {
      if (prev?.status != next.status) {
        AppLog.i(
          'MeetingToolbar',
          'recorder status → ${next.status} (meetingId=${next.meetingId})',
        );
      }
      if (state && !next.isRecording) {
        close();
      }
    });

    // Auto-pop the toolbar out when the user switches away from the app
    // mid-recording — that's exactly when they need floating controls over the
    // meeting app they just moved to. AppLifecycleState goes inactive/hidden
    // only when the *whole app* loses focus to another application; switching
    // between this app's own windows (e.g. main ↔ toolbar) keeps it resumed, so
    // the toolbar's own window won't trigger this.
    final lifecycleObserver = _AppDeactivatedObserver(_handleUnfocus);
    WidgetsBinding.instance.addObserver(lifecycleObserver);
    ref.onDispose(() {
      WidgetsBinding.instance.removeObserver(lifecycleObserver);
    });

    return false;
  }

  /// The app lost focus. If a recording is in progress and the toolbar isn't
  /// already out, pop it so the controls follow the user.
  void _handleUnfocus() {
    final recorder = ref.read(meetingRecorderControllerProvider);
    if (state) {
      return;
    }
    if (recorder.isRecording) {
      open();
    }
  }

  /// Pops the toolbar out into its own always-on-top window. No-op unless a
  /// recording is in progress and the toolbar isn't already floating.
  void open() {
    if (state || _opening) {
      return;
    }
    if (!ref.read(meetingRecorderControllerProvider).isRecording) {
      return;
    }
    _opening = true;
    try {
      state = true;
      AppLog.i('MeetingToolbar', 'toolbar window opened');
    } finally {
      _opening = false;
    }
  }

  /// Closes the toolbar window (if open) and returns to in-window controls.
  void close() {
    state = false;
  }

  /// Stops the recording from the toolbar: kicks off processing in the
  /// background, retires the toolbar, surfaces the meeting detail, and brings
  /// the main window forward.
  Future<void> requestStop() async {
    final meetingId = ref.read(meetingRecorderControllerProvider).meetingId;
    // Fire-and-forget: stop() drives the meeting through processing → done in
    // the background while we surface its detail (mirrors the in-app HUD).
    unawaited(ref.read(meetingRecorderControllerProvider.notifier).stop());
    close();
    final wsId = ref.read(activeWorkspaceIdProvider);
    if (meetingId != null && wsId != null) {
      ref.read(routerProvider).go(meetingDetailRoute(wsId, meetingId));
    }
    focusPrimaryWindow();
  }
}

/// Whether the floating meeting toolbar window is currently open, and the
/// controller that manages it.
final meetingToolbarControllerProvider =
    NotifierProvider<MeetingToolbarController, bool>(
      MeetingToolbarController.new,
    );

/// Fires when the app is no longer the foreground app (the user switched to
/// another application). Switching between this app's own windows keeps it
/// `resumed`, so the toolbar's own window won't trigger this.
class _AppDeactivatedObserver with WidgetsBindingObserver {
  _AppDeactivatedObserver(this._onDeactivated);

  final void Function() _onDeactivated;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused) {
      _onDeactivated();
    }
  }
}
