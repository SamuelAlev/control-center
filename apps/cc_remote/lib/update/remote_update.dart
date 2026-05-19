import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';

import 'package:cc_domain/cc_domain.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web/web.dart' as web;

/// State of the PWA's "a new version is live on this origin" notice.
class RemoteUpdateState {
  /// Creates a [RemoteUpdateState].
  const RemoteUpdateState({this.available = false, this.checking = false});

  /// A deploy with a different git sha than this build is live at the
  /// origin. Shows the consent banner — the PWA never reloads on its own.
  final bool available;

  final bool checking;

  RemoteUpdateState copyWith({bool? available, bool? checking}) =>
      RemoteUpdateState(
        available: available ?? this.available,
        checking: checking ?? this.checking,
      );
}

/// Polls the PWA origin's `/deploy.json` (written by deploy-remote.yml on
/// every push to main) and compares the deployed git sha against this build's
/// [BuildInfo]. Same model as the web client's banner: detect quietly, show a
/// non-blocking banner, reload only when the user taps Refresh.
final remoteUpdateProvider =
    NotifierProvider<RemoteUpdateController, RemoteUpdateState>(
      RemoteUpdateController.new,
    );

class RemoteUpdateController extends Notifier<RemoteUpdateState> {
  Timer? _timer;
  Timer? _firstCheckTimer;

  /// The sha the user dismissed, if any. Keyed on the SHA — not a plain
  /// boolean latch — so dismissing today's deploy does not hide every future
  /// one for the rest of the session (the web client behaves the same way).
  String? _dismissedSha;

  @override
  RemoteUpdateState build() {
    ref.onDispose(_cancelTimers);
    return const RemoteUpdateState();
  }

  /// Arms the periodic check. Call once from the app root's first frame; safe
  /// to call again (no double timers).
  void start() {
    if (_timer != null) {
      return;
    }
    _firstCheckTimer = Timer(const Duration(seconds: 20), checkForUpdate);
    _timer = Timer.periodic(
      const Duration(minutes: 15),
      (_) => checkForUpdate(),
    );
  }

  /// Checks now. Any failure is silent — a missing manifest is not a phone
  /// user's problem.
  Future<void> checkForUpdate() async {
    state = state.copyWith(checking: true);
    try {
      final base = Uri.base;
      final uri = base.replace(
        path: '/deploy.json',
        query: 't=${DateTime.now().millisecondsSinceEpoch}',
        fragment: '',
      );
      final response = await web.window.fetch(uri.toString().toJS).toDart;
      if (response.status != 200) {
        state = state.copyWith(checking: false);
        return;
      }
      final body = (await (response.text().toDart)).toDart;
      final json = jsonDecode(body);
      final sha = json is Map ? json['gitSha'] as String? : null;
      if (sha == null || sha.isEmpty) {
        state = state.copyWith(checking: false);
        return;
      }
      final newer = sha != BuildInfo.buildGitSha && sha != _dismissedSha;
      _latestSha = sha;
      state = RemoteUpdateState(available: newer);
    } on Object {
      state = state.copyWith(checking: false);
    }
  }

  /// The sha most recently reported by the origin — what [dismiss] records.
  String? _latestSha;

  /// The user tapped Refresh. Reloads the page (explicit consent; the PWA
  /// has no in-flight recording or draft worth draining — the server owns
  /// all state).
  void refresh() {
    web.window.location.reload();
  }

  /// The user dismissed the banner for THIS deploy; it stays hidden until a
  /// different sha is deployed.
  void dismiss() {
    _dismissedSha = _latestSha;
    state = state.copyWith(available: false);
  }

  void _cancelTimers() {
    _timer?.cancel();
    _timer = null;
    _firstCheckTimer?.cancel();
    _firstCheckTimer = null;
  }
}

/// The banner strip shown at the top of the cc_remote shell while a newer
/// deploy is live. Non-blocking, dismissible, consent-driven.
class RemoteUpdateBanner extends ConsumerWidget {
  /// Creates a [RemoteUpdateBanner].
  const RemoteUpdateBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final update = ref.watch(remoteUpdateProvider);
    if (!update.available) {
      return const SizedBox.shrink();
    }
    final controller = ref.read(remoteUpdateProvider.notifier);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: CcBanner(
        title: 'A new Control Center is available',
        variant: CcBannerVariant.info,
        actions: [
          CcBannerAction(
            label: 'Refresh',
            primary: true,
            onPressed: controller.refresh,
          ),
        ],
        onDismiss: controller.dismiss,
      ),
    );
  }
}
