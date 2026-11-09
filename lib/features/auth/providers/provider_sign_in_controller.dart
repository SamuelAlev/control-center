import 'dart:async';

import 'package:cc_connect_core/cc_connect_core.dart'
    show ConnectOAuthLane, normaliseConfirmCode;
import 'package:cc_data/cc_data.dart';
import 'package:cc_rpc/cc_rpc.dart' show RemoteRpcException;
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/shared/utils/open_url.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The `oauth.*` RPC surface.
final providerSignInRepositoryProvider = Provider<RemoteProviderSignIn>(
  (ref) => RemoteProviderSignIn(ref.watch(rpcClientProvider)),
);

/// Opens a URL in the system browser and says whether it could. A provider so
/// a test can watch what the sign-in flow opens without launching anything.
final externalUrlOpenerProvider = Provider<bool Function(String url)>(
  (ref) => openExternalUrl,
);

/// How often an own-mode attempt is polled while the browser is out.
const Duration kSignInPollInterval = Duration(seconds: 2);

/// Why a typed confirmation code was not accepted.
sealed class SignInCodeError {
  const SignInCodeError();
}

/// Not eight Crockford characters; nothing was sent.
final class SignInCodeMalformed extends SignInCodeError {
  /// Creates a [SignInCodeMalformed].
  const SignInCodeMalformed();
}

/// The server refused the code; [message] is its explanation.
final class SignInCodeRejected extends SignInCodeError {
  /// Creates a [SignInCodeRejected].
  const SignInCodeRejected(this.message);

  /// What the server said.
  final String message;
}

/// One attempt this client started, as the UI renders it.
class SignInSession {
  /// Creates a [SignInSession].
  const SignInSession({
    required this.attempt,
    required this.workspaceId,
    this.browserOpened = true,
    this.completing = false,
    this.codeError,
  });

  /// The server's latest word on the attempt.
  final SignInAttempt attempt;

  /// The scope it was started in; every follow-up call carries it.
  final String? workspaceId;

  /// False when no browser could be opened, so the URL must be shown.
  final bool browserOpened;

  /// Whether a confirmation code is on its way to the server.
  final bool completing;

  /// Why the last typed code was not accepted, if it was not.
  final SignInCodeError? codeError;

  /// The attempt's login id.
  String get loginId => attempt.loginId;

  /// Whether the attempt is over.
  bool get isTerminal => attempt.status.isTerminal;

  /// A copy with the given fields replaced. [codeError] is replaced as given,
  /// so passing nothing clears it.
  SignInSession copyWith({
    SignInAttempt? attempt,
    bool? browserOpened,
    bool? completing,
    SignInCodeError? codeError,
  }) => SignInSession(
    attempt: attempt ?? this.attempt,
    workspaceId: workspaceId,
    browserOpened: browserOpened ?? this.browserOpened,
    completing: completing ?? this.completing,
    codeError: codeError,
  );
}

/// Every sign-in this client has running, plus a per-lane success counter
/// that connection lists watch so they re-read the moment a grant lands —
/// wherever it was started and whether or not its dialog is still open.
class ProviderSignInState {
  /// Creates a [ProviderSignInState].
  const ProviderSignInState({
    this.sessions = const {},
    this.successes = const {},
  });

  /// Live and finished attempts, by login id.
  final Map<String, SignInSession> sessions;

  /// How many attempts have succeeded per lane in this app run.
  final Map<ConnectOAuthLane, int> successes;

  /// The success count for [lane].
  int successesFor(ConnectOAuthLane lane) => successes[lane] ?? 0;
}

/// Runs browser sign-ins for every lane (GitHub, Google, Linear, the Linear
/// app actor, Slack) and remembers which ones THIS client started.
///
/// The flow is the server's: `oauth.begin` returns a provider URL, which is
/// opened in the system browser. In own mode the provider redirects to the
/// server and this polls `oauth.status`; in Connect mode the browser shows an
/// eight-character code that comes back either typed by the person or through
/// the `control-center://oauth-done` deep link, and either way goes to
/// `oauth.complete`.
///
/// The remembered login ids are the phishing defence. A deep link carrying a
/// login id this client never started was minted by somebody else's server,
/// and completing it would hand that server the person's account; the caller
/// warns instead and nothing is sent. The set is in memory only, on purpose:
/// an attempt started before a restart cannot be completed by a link either.
final providerSignInControllerProvider =
    NotifierProvider<ProviderSignInController, ProviderSignInState>(
      ProviderSignInController.new,
    );

/// See [providerSignInControllerProvider].
class ProviderSignInController extends Notifier<ProviderSignInState> {
  /// Login id → the scope it was started in. Never shrinks during a run.
  final Map<String, String?> _started = {};
  final Map<String, Timer> _timers = {};
  final Map<String, Completer<SignInAttempt>> _results = {};
  final Set<String> _polling = {};

  @override
  ProviderSignInState build() {
    ref.onDispose(() {
      for (final timer in _timers.values) {
        timer.cancel();
      }
      _timers.clear();
    });
    return const ProviderSignInState();
  }

  RemoteProviderSignIn get _repo => ref.read(providerSignInRepositoryProvider);

  /// Whether this client started [loginId].
  bool startedHere(String loginId) => _started.containsKey(loginId);

  /// Starts [lane]'s sign-in in [workspaceId]'s scope, opens the provider in
  /// the browser and returns the login id.
  ///
  /// Throws what `oauth.begin` throws (a misconfigured own app, Connect
  /// unavailable); nothing is remembered in that case.
  Future<String> begin(ConnectOAuthLane lane, {String? workspaceId}) async {
    final attempt = await _repo.begin(lane, workspaceId: workspaceId);
    _started[attempt.loginId] = workspaceId;
    _results[attempt.loginId] = Completer<SignInAttempt>();
    final opened =
        attempt.url.isNotEmpty &&
        ref.read(externalUrlOpenerProvider)(attempt.url);
    _put(
      SignInSession(
        attempt: attempt,
        workspaceId: workspaceId,
        browserOpened: opened,
      ),
    );
    if (attempt.status.isTerminal) {
      _finish(attempt.loginId);
    } else {
      _watch(attempt);
    }
    return attempt.loginId;
  }

  /// Opens [loginId]'s provider page again.
  bool reopen(String loginId) {
    final session = state.sessions[loginId];
    if (session == null || session.attempt.url.isEmpty) {
      return false;
    }
    final opened = ref.read(externalUrlOpenerProvider)(session.attempt.url);
    _put(session.copyWith(browserOpened: opened, codeError: session.codeError));
    return opened;
  }

  /// Completes when [loginId] is over, with its final attempt.
  Future<SignInAttempt>? result(String loginId) => _results[loginId]?.future;

  /// Hands a confirmation code the person [typed] to the server.
  ///
  /// A malformed code is refused here and never sent; a wrong one comes back
  /// as [SignInCodeRejected] and the attempt stays open (the server fails it
  /// after five wrong codes).
  Future<void> submitCode(String loginId, String typed) async {
    final session = state.sessions[loginId];
    if (session == null || session.isTerminal || session.completing) {
      return;
    }
    final code = normaliseConfirmCode(typed);
    if (code == null) {
      _put(session.copyWith(codeError: const SignInCodeMalformed()));
      return;
    }
    await _complete(loginId, code, session.workspaceId);
  }

  /// Completes [loginId] from an `oauth-done` deep link.
  ///
  /// Returns false — and sends nothing — when this client did not start
  /// [loginId]: the caller must warn that the link may be a phishing attempt.
  Future<bool> completeFromDeepLink(String loginId, String code) async {
    if (!_started.containsKey(loginId)) {
      return false;
    }
    final session = state.sessions[loginId];
    if (session != null && (session.isTerminal || session.completing)) {
      return true;
    }
    final normalised = normaliseConfirmCode(code);
    if (normalised == null) {
      return true;
    }
    await _complete(loginId, normalised, _started[loginId]);
    return true;
  }

  Future<void> _complete(
    String loginId,
    String code,
    String? workspaceId,
  ) async {
    final before = state.sessions[loginId];
    if (before != null) {
      _put(before.copyWith(completing: true));
    }
    try {
      final attempt = await _repo.complete(
        loginId: loginId,
        code: code,
        workspaceId: workspaceId,
      );
      _update(attempt);
    } on RemoteRpcException catch (e) {
      final now = state.sessions[loginId];
      if (now != null) {
        _put(
          now.copyWith(
            completing: false,
            codeError: SignInCodeRejected(e.message),
          ),
        );
      }
    } on Object catch (e) {
      final now = state.sessions[loginId];
      if (now != null) {
        _put(
          now.copyWith(completing: false, codeError: SignInCodeRejected('$e')),
        );
      }
    }
  }

  void _watch(SignInAttempt attempt) {
    final loginId = attempt.loginId;
    _timers.remove(loginId)?.cancel();
    if (attempt.mode == SignInLaneMode.own) {
      _timers[loginId] = Timer.periodic(
        kSignInPollInterval,
        (_) => unawaited(_poll(loginId)),
      );
      return;
    }
    // Connect mode completes from the browser's code; the only thing to watch
    // for here is the attempt running out.
    final left = attempt.expiresAt.difference(DateTime.now().toUtc());
    _timers[loginId] = Timer(
      left.isNegative ? Duration.zero : left,
      () => _expire(loginId),
    );
  }

  Future<void> _poll(String loginId) async {
    final session = state.sessions[loginId];
    if (session == null || session.isTerminal || !_polling.add(loginId)) {
      return;
    }
    try {
      _update(await _repo.status(loginId, workspaceId: session.workspaceId));
    } on Object {
      // A dropped poll is not a failed sign-in; the next tick asks again and
      // the attempt's own expiry ends it if the server never answers.
      if (DateTime.now().toUtc().isAfter(session.attempt.expiresAt)) {
        _expire(loginId);
      }
    } finally {
      _polling.remove(loginId);
    }
  }

  void _expire(String loginId) {
    final session = state.sessions[loginId];
    if (session == null || session.isTerminal) {
      return;
    }
    final a = session.attempt;
    _update(
      SignInAttempt(
        loginId: a.loginId,
        lane: a.lane,
        mode: a.mode,
        url: a.url,
        expiresAt: a.expiresAt,
        status: SignInAttemptStatus.failed,
        error: SignInFailure.expired,
      ),
    );
  }

  void _update(SignInAttempt attempt) {
    final session = state.sessions[attempt.loginId];
    if (session == null) {
      return;
    }
    _put(session.copyWith(attempt: attempt, completing: false));
    if (attempt.status.isTerminal) {
      _finish(attempt.loginId);
    }
  }

  void _finish(String loginId) {
    _timers.remove(loginId)?.cancel();
    final session = state.sessions[loginId];
    if (session == null) {
      return;
    }
    if (session.attempt.status == SignInAttemptStatus.succeeded) {
      final lane = session.attempt.lane;
      state = ProviderSignInState(
        sessions: state.sessions,
        successes: {...state.successes, lane: state.successesFor(lane) + 1},
      );
    }
    final completer = _results[loginId];
    if (completer != null && !completer.isCompleted) {
      completer.complete(session.attempt);
    }
  }

  void _put(SignInSession session) {
    state = ProviderSignInState(
      sessions: {...state.sessions, session.loginId: session},
      successes: state.successes,
    );
  }
}
