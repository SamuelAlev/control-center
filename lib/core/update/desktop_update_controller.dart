import 'dart:async';

import 'package:control_center/core/update/desktop_updater_port.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Lifecycle of the desktop in-app update check.
enum DesktopUpdateStatus {
  /// No check has run yet.
  idle,

  /// A check is in flight.
  checking,

  /// A newer version was found (prompt shown / showing).
  available,

  /// The last check found this build current.
  upToDate,

  /// A result exists but prompting is deferred while the app is busy.
  deferred,

  /// This platform has no in-app updater; the releases page was opened
  /// instead (the Linux path).
  openedReleasesPage,

  /// The last check failed (feed unreachable, signature rejected…).
  error,
}

/// The desktop updater's observable state (drives the Settings → About rows).
class DesktopUpdateState {
  /// Creates a [DesktopUpdateState].
  const DesktopUpdateState({
    this.status = DesktopUpdateStatus.idle,
    this.version,
    this.notes,
    this.errorMessage,
  });

  /// Where the update flow currently stands.
  final DesktopUpdateStatus status;

  /// The available version string (when [status] is available).
  final String? version;

  /// Release-notes excerpt for the available version, when the appcast
  /// carries one.
  final String? notes;

  /// The failure detail (when [status] is error).
  final String? errorMessage;

  /// Field-wise copy. Every nullable field follows the same rule — pass a
  /// value to set it, pass nothing to KEEP it — and the `clear*` flags are
  /// the only way to erase one. (The asymmetric version, where
  /// `errorMessage` silently reset on every copy while `version` persisted,
  /// left a stale version string attached to an `upToDate` state.)
  DesktopUpdateState copyWith({
    DesktopUpdateStatus? status,
    String? version,
    String? notes,
    String? errorMessage,
    bool clearVersion = false,
    bool clearError = false,
  }) => DesktopUpdateState(
    status: status ?? this.status,
    version: clearVersion ? null : (version ?? this.version),
    notes: clearVersion ? null : (notes ?? this.notes),
    errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
  );
}

/// Owns WHEN the desktop checks for updates and when it is allowed to
/// prompt, on top of the platform updater seam (Sparkle 2 / WinSparkle).
///
/// Cadence: once shortly after the shell is ready (never on the boot path),
/// then every 24h. Drain rule: a check whose result would PROMPT is deferred
/// while the busy probe says the app is mid-something-unsafe-to-quit (a
/// recording in flight); a deferred check retries on its own short timer
/// rather than waiting out the full day.
/// Source of truth is the published GitHub Release appcast — never drafts.
///
/// Linux (and any platform without a Sparkle/WinSparkle backend) degrades to
/// the notify path: "Check for updates" opens the latest release page.
final desktopUpdateProvider =
    NotifierProvider<DesktopUpdateController, DesktopUpdateState>(
      DesktopUpdateController.new,
    );

/// How long a `checking` state may persist before it is assumed lost. The
/// native updaters report every outcome through a listener, but a user who
/// dismisses Sparkle's own window can leave the check with no terminal event
/// — without this the About row reads "Checking for updates…" forever.
const Duration _kCheckWatchdog = Duration(minutes: 2);

/// Retry delay for a check deferred by the busy probe. Short enough that the
/// prompt actually arrives once the recording ends, long enough not to spin.
const Duration _kDeferredRetry = Duration(minutes: 30);

/// Owns WHEN the desktop checks for updates and when it may prompt — see
/// [desktopUpdateProvider] for the full contract.
class DesktopUpdateController extends Notifier<DesktopUpdateState> {
  Timer? _timer;
  Timer? _firstCheckTimer;
  Timer? _deferredRetryTimer;
  Timer? _watchdogTimer;
  bool _started = false;
  bool _lastCheckWasBackground = false;
  bool Function()? _busyProbe;

  /// Set once `initDesktopUpdater` has completed, so the feed URL and the
  /// outcome handlers are guaranteed to be installed before any check runs.
  Future<void>? _initFuture;

  /// This controller's outcome-handler registration, released on dispose so a
  /// disposed controller stops receiving updater callbacks.
  DesktopUpdaterHandlerRegistration? _handlers;

  DesktopUpdaterPort get _updater => ref.read(desktopUpdaterPortProvider);

  @override
  DesktopUpdateState build() {
    ref.onDispose(_cancelTimers);
    return const DesktopUpdateState();
  }

  /// Arms the updater + the check schedule. Call once from the desktop
  /// shell's first frame; no-op on web and on re-mounts. [busyProbe] is the
  /// "unsafe to prompt right now" check (a recording in flight).
  void start({bool Function()? busyProbe}) {
    if (kIsWeb || !_updater.supported) {
      return;
    }
    _busyProbe = busyProbe;
    if (_started) {
      return;
    }
    _started = true;
    unawaited(_schedule());
  }

  Future<void> _schedule() async {
    await _ensureInit();
    // First check well after ready (boot pays nothing), then daily.
    _firstCheckTimer = Timer(const Duration(seconds: 60), _scheduledCheck);
    _timer = Timer.periodic(
      const Duration(hours: 24),
      (_) => _scheduledCheck(),
    );
  }

  /// Arms the native updater exactly once and is safe to await from every
  /// entry point. The macOS app-menu item reaches [checkNow] through a method
  /// space that can fire before the shell has mounted; without this the
  /// check would run with no outcome handlers registered and the UI would sit
  /// on `checking` forever.
  Future<void> _ensureInit() {
    return _initFuture ??= _init();
  }

  Future<void> _init() async {
    await _updater.init();
    // Hold the registration so a rebuilt controller (server switch) releases
    // its own handlers instead of leaving a dead closure wired to the updater.
    _handlers?.release();
    _handlers = _updater.setHandlers(
      onAvailable: _onAvailable,
      onNotAvailable: () => _settle(
        state.copyWith(
          status: DesktopUpdateStatus.upToDate,
          clearVersion: true,
          clearError: true,
        ),
      ),
      onError: (message) => _settle(
        state.copyWith(
          status: DesktopUpdateStatus.error,
          errorMessage: message,
        ),
      ),
    );
  }

  void _scheduledCheck() {
    if (_isBusy()) {
      // Mid-recording (or whatever the probe guards): a prompt now would
      // either interrupt it or be buried. Retry on a short timer instead of
      // waiting out the full 24h cycle.
      state = state.copyWith(status: DesktopUpdateStatus.deferred);
      _deferredRetryTimer?.cancel();
      _deferredRetryTimer = Timer(_kDeferredRetry, _scheduledCheck);
      return;
    }
    _lastCheckWasBackground = true;
    _beginChecking();
    unawaited(
      _ensureInit()
          .then((_) => _updater.check(background: true))
          .catchError(_reportError),
    );
  }

  /// The Settings → About button. On a platform with a native updater this
  /// opens the updater's own prompt (release notes + confirm); everywhere
  /// else it opens the latest release page (the notify-only path).
  Future<void> checkNow() async {
    if (!_updater.supported) {
      _updater.openReleasesPage();
      // Report it: silently opening a browser and leaving the About row blank
      // reads as "the button did nothing".
      state = state.copyWith(
        status: DesktopUpdateStatus.openedReleasesPage,
        clearVersion: true,
        clearError: true,
      );
      return;
    }
    if (_isBusy()) {
      state = state.copyWith(status: DesktopUpdateStatus.deferred);
      return;
    }
    _lastCheckWasBackground = false;
    _beginChecking();
    try {
      await _ensureInit();
      await _updater.check(background: false);
    } on Object catch (e) {
      _reportError(e);
    }
  }

  void _onAvailable(String? version, String? notes) {
    _settle(
      state.copyWith(
        status: DesktopUpdateStatus.available,
        version: version,
        notes: notes,
        clearError: true,
      ),
    );
    // A background check that found something: escalate to the interactive
    // prompt now that we know it exists (the foreground check's own
    // onAvailable already shows the UI — don't double-prompt). The native
    // updaters expose no "show the prompt for the result you already have",
    // so this necessarily re-runs the check.
    if (_lastCheckWasBackground && !_isBusy()) {
      _lastCheckWasBackground = false;
      unawaited(_updater.check(background: false).catchError(_reportError));
    }
  }

  /// Enters `checking` and arms the watchdog that guarantees the state is
  /// left again even if no native outcome event ever arrives.
  void _beginChecking() {
    state = state.copyWith(
      status: DesktopUpdateStatus.checking,
      clearError: true,
    );
    _watchdogTimer?.cancel();
    _watchdogTimer = Timer(_kCheckWatchdog, () {
      if (state.status == DesktopUpdateStatus.checking) {
        state = state.copyWith(status: DesktopUpdateStatus.idle);
      }
    });
  }

  /// Applies a terminal outcome and disarms the watchdog.
  void _settle(DesktopUpdateState next) {
    _watchdogTimer?.cancel();
    _watchdogTimer = null;
    state = next;
  }

  void _reportError(Object e) {
    _settle(
      state.copyWith(
        status: DesktopUpdateStatus.error,
        errorMessage: e.toString(),
      ),
    );
  }

  void _cancelTimers() {
    _handlers?.release();
    _handlers = null;
    _timer?.cancel();
    _timer = null;
    _firstCheckTimer?.cancel();
    _firstCheckTimer = null;
    _deferredRetryTimer?.cancel();
    _deferredRetryTimer = null;
    _watchdogTimer?.cancel();
    _watchdogTimer = null;
    _started = false;
  }

  bool _isBusy() => _busyProbe?.call() ?? false;
}
