import 'dart:async';

import 'package:control_center/core/update/deployed_version.dart';
import 'package:control_center/core/update/service_worker_probe.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

/// State of the "a new version is live on this origin" notice (web only).
class WebUpdateState {
  /// Creates a [WebUpdateState].
  const WebUpdateState({
    this.available,
    this.serviceWorkerWaiting = false,
    this.checking = false,
    this.pendingRefresh = false,
  });

  /// The newly deployed build per `/deploy.json`, or null when the origin
  /// reported nothing newer than the running build.
  final DeployedVersion? available;

  /// The Flutter service worker has a new version installed and waiting —
  /// the second, browser-side signal. Shown with the same banner.
  final bool serviceWorkerWaiting;

  /// A poll is in flight (the banner shows a subtle checking state; no UI
  /// churn otherwise).
  final bool checking;

  /// The user pressed Refresh while the app was busy with something unsafe
  /// to interrupt; the reload runs as soon as the busy condition clears.
  final bool pendingRefresh;

  /// Whether any signal says a newer build exists.
  bool get updateAvailable => available != null || serviceWorkerWaiting;

  /// Field-wise copy (null keeps the current value).
  WebUpdateState copyWith({
    DeployedVersion? available,
    bool? serviceWorkerWaiting,
    bool? checking,
    bool? pendingRefresh,
    bool clearAvailable = false,
  }) => WebUpdateState(
    available: clearAvailable ? null : (available ?? this.available),
    serviceWorkerWaiting: serviceWorkerWaiting ?? this.serviceWorkerWaiting,
    checking: checking ?? this.checking,
    pendingRefresh: pendingRefresh ?? this.pendingRefresh,
  );
}

/// Polls the origin for a newer deploy and holds the consent-driven refresh
/// state (web only; the controller's start is a no-op everywhere else).
///
/// Cadence: once shortly after load, then every 15 minutes, plus a check on
/// tab focus (driven by the banner host's lifecycle observer). A deploy is
/// detected when `/deploy.json`'s git sha differs from the running build's,
/// or when the service worker has a waiting installer. The response to a
/// detection is ALWAYS the non-blocking banner — the app never reloads
/// itself; the user clicks Refresh.
final webUpdateProvider = NotifierProvider<WebUpdateController, WebUpdateState>(
  WebUpdateController.new,
);

/// Signature of the manifest fetch (injectable for tests).
typedef VersionManifestFetcher = Future<String?> Function(Uri uri);

/// The notifier behind [webUpdateProvider]: arms the polls, tracks the
/// deployed manifest and owns the consent-gated reload queue.
class WebUpdateController extends Notifier<WebUpdateState> {
  Timer? _timer;
  Timer? _firstCheckTimer;
  String? _dismissedSha;
  VersionManifestFetcher? _fetcher;

  /// Test-only override for the platform gate.
  ///
  /// Everything this controller decides — sha comparison, sha-keyed
  /// dismissal, the consent queue — is pure Dart over an injected fetcher and
  /// a service-worker probe that stubs to `false` off-web. Only `kIsWeb`
  /// stands between that logic and a plain VM test and a browser-only suite
  /// for it would not be run by the normal `flutter test` pass.
  @visibleForTesting
  bool debugForceEnabled = false;

  bool get _enabled => kIsWeb || debugForceEnabled;

  @override
  WebUpdateState build() {
    ref.onDispose(_cancelTimers);
    return const WebUpdateState();
  }

  /// Arms the periodic check. Call once from the connected app's first frame;
  /// no-op off-web or when already armed.
  void start({VersionManifestFetcher? fetcher}) {
    if (!_enabled) {
      return;
    }
    _fetcher = fetcher;
    if (_timer != null) {
      return;
    }
    // First check off the boot path, then a slow cadence forever. Deploys
    // happen on every main push, but a refresh prompt is never urgent. Both
    // timers are held so dispose cancels them — a fire-and-forget one-shot
    // would still run against a disposed notifier.
    _firstCheckTimer = Timer(const Duration(seconds: 30), _pollQuietly);
    _timer = Timer.periodic(const Duration(minutes: 15), (_) => _pollQuietly());
  }

  /// Polls now. Failures are silent (a missing/unreachable manifest is not a
  /// user problem); a fetch that reports the SAME build clears any stale
  /// banner.
  Future<void> checkForUpdate() async {
    if (!_enabled) {
      return;
    }
    state = state.copyWith(checking: true);
    DeployedVersion? deployed;
    try {
      final body = await (_fetcher ?? _fetch)(originVersionUri);
      deployed = body == null ? null : DeployedVersion.parse(body);
    } on Object {
      // Network error mid-session: keep whatever we knew.
    }
    final waiting = await hasWaitingServiceWorker();
    final known = deployed;
    if (known != null && !known.differsFromRunningBuild()) {
      // Same build deployed — clear any stale banner.
      state = state.copyWith(
        clearAvailable: true,
        serviceWorkerWaiting: false,
        checking: false,
      );
      return;
    }
    // A dismissed deploy stays dismissed until a DIFFERENT sha lands (or the
    // service worker installs yet another build); `sw` is the sentinel for a
    // service-worker-only dismissal.
    final dismissed = _dismissedSha;
    final showable = known != null
        ? known.gitSha != dismissed
        : dismissed != 'sw';
    state = state.copyWith(
      available: (known != null && showable) ? known : null,
      serviceWorkerWaiting: waiting && showable,
      checking: false,
    );
  }

  /// The user dismissed the banner for THIS deploy; it stays hidden until a
  /// different sha is deployed.
  void dismiss() {
    _dismissedSha = state.available?.gitSha ?? 'sw';
    state = state.copyWith(
      clearAvailable: true,
      serviceWorkerWaiting: false,
      pendingRefresh: false,
    );
  }

  /// The Refresh action. [busy] is the "unsafe to reload right now" probe
  /// (a recording in flight, unsent messages); when busy, the reload is
  /// QUEUED and fires from [onBusyConditionCleared] instead.
  void requestRefresh({required bool busy}) {
    if (busy) {
      state = state.copyWith(pendingRefresh: true);
      return;
    }
    reloadPage();
  }

  /// Called by the banner host when the busy condition clears: a queued
  /// refresh executes now (the user already consented).
  void onBusyConditionCleared() {
    if (state.pendingRefresh && state.updateAvailable) {
      reloadPage();
    }
  }

  Future<void> _pollQuietly() async {
    try {
      await checkForUpdate();
    } on Object {
      // Polling must never surface as an error.
    }
  }

  void _cancelTimers() {
    _timer?.cancel();
    _timer = null;
    _firstCheckTimer?.cancel();
    _firstCheckTimer = null;
  }

  /// `/deploy.json` at the origin root. The app uses path-based URLs
  /// (`/workspaces/<id>/…`), so a relative fetch would resolve against the
  /// current route — rebuild the URI from the origin instead and cache-bust
  /// with a timestamp so an intermediary cannot serve a stale manifest.
  ///
  /// NOT `version.json`: `flutter build web` generates its own file by that
  /// name (`{"app_name": …, "build_number": …}`, no git sha) and would
  /// overwrite ours in `build/web`, leaving the banner permanently dead.
  static Uri get originVersionUri {
    final base = Uri.base;
    return base.replace(
      path: '/deploy.json',
      query: 't=${DateTime.now().millisecondsSinceEpoch}',
      fragment: '',
    );
  }

  static Future<String?> _fetch(Uri uri) async {
    final client = http.Client();
    try {
      final response = await client
          .get(uri)
          .timeout(const Duration(seconds: 5));
      if (response.statusCode != 200) {
        return null;
      }
      return response.body;
    } finally {
      client.close();
    }
  }
}
