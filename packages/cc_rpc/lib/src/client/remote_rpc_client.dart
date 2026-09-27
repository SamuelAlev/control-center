import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:cc_domain/cc_domain.dart';
import 'package:cc_rpc/src/channel/remote_rpc_channel_port.dart';
import 'package:cc_rpc/src/client/server_build.dart';

/// Thrown when a `repo/call` returns a JSON-RPC error. [code] is one of
/// [RpcErrorCodes]; clients switch on it (e.g. roll back on a conflict).
class RemoteRpcException implements Exception {
  /// Creates a [RemoteRpcException].
  RemoteRpcException(this.code, this.message, [this.data]);

  /// Stable error code (see [RpcErrorCodes]).
  final int code;

  /// Human-readable message.
  final String message;

  /// Optional structured error data.
  final Object? data;

  @override
  String toString() => 'RemoteRpcException($code): $message';
}

/// Signalled to in-flight requests when the [RemoteRpcClient] is closed
/// (e.g. the server disconnected/restarted). Not an error — a cancellation.
class RemoteRpcClientClosedException implements Exception {
  /// Creates a [RemoteRpcClientClosedException].
  const RemoteRpcClientClosedException([this.message]);

  /// Human-readable message.
  final String? message;

  @override
  String toString() => message ?? 'RPC client closed';
}

/// The client half of the cc_rpc protocol — transport-agnostic.
///
/// Drives any [RemoteRpcChannelPort] (in-process, WSS, or WebRTC): correlates
/// `id`-bearing requests to responses, routes `sub/*` pushes to subscription
/// streams and surfaces server notifications. This is what a desktop in REMOTE
/// mode and the full web build use to talk to a server; the same class is the
/// in-memory protocol-conformance harness in tests.
class RemoteRpcClient {
  /// Creates a client over the given channel. Call [start] before requests.
  RemoteRpcClient(this._channel, {Duration? timeout})
    : _timeout = timeout ?? const Duration(seconds: 30);

  final RemoteRpcChannelPort _channel;
  final Duration _timeout;
  final Map<int, Completer<Map<String, dynamic>>> _pending = {};
  final Map<String, StreamController<Map<String, dynamic>>> _subs = {};

  /// Snapshots (and stream errors) that arrived for a subscription id BEFORE
  /// the `sub/subscribe` ack was processed. The ack completes `_request` and
  /// the onListen continuation that registers `_subs[id]` runs as a microtask,
  /// so a handler that emits on listen — or a loopback transport that delivers
  /// the snapshot in the same burst as the ack — would otherwise drop the
  /// only emission and leave StreamProviders spinning in loading forever.
  /// Last snapshot wins; a buffered error is replayed after it (terminal).
  final Map<String, Map<String, dynamic>> _earlySnapshots = {};
  final Map<String, RemoteRpcException> _earlyErrors = {};

  /// Request ids of `sub/subscribe` setups abandoned before their ack arrived.
  /// A late ack names a subscription the client will never register, and a
  /// snapshot can even outrun the ack — both must be recognised and dropped
  /// instead of buffering here forever. Monotonic request ids make the newest
  /// entries the only ones whose response can still be in flight (anything
  /// older than the request timeout is dead server-side), so trimming the
  /// oldest entry is lossless in practice.
  final Map<int, String?> _cancelledSubscribes = {};

  /// Subscription ids given up on: a cancelled setup whose late ack named it,
  /// or an unsubscribed id whose trailing snapshot may still be in flight.
  /// Server ids are monotonic per session and never reused, so a bounded
  /// recent set is sufficient.
  final Set<String> _deadSubscriptions = {};

  /// Live shared subscriptions, keyed by `(query, effective-args)`. Lets
  /// several callers of [subscribe] with identical coordinates share ONE
  /// server subscription (ref-counted) instead of each opening its own. See
  /// [subscribe].
  final Map<String, _SharedSubscription> _sharedReads = {};
  final Map<String, _SharedSubscription> _shared = {};
  final StreamController<JsonRpcNotification> _notifications =
      StreamController<JsonRpcNotification>.broadcast();
  StreamSubscription<Map<String, dynamic>>? _incomingSub;
  int _nextId = 0;
  bool _closing = false;

  /// The workspace this client acts in. It is injected as `workspace_id` into
  /// every `call`/`subscribe` whose args don't already name one. The server is
  /// stateless — it holds no session workspace — so each request must carry its
  /// own. The app keeps this pointed at the active workspace (the route); a
  /// caller that targets a specific workspace passes `workspace_id` in args,
  /// which overrides this default.
  String? activeWorkspaceId;

  int? _agreedProtocolVersion;

  /// The repo-RPC protocol version this session agreed on during `initialize`,
  /// or null against a server too old to answer with one.
  int? get agreedProtocolVersion => _agreedProtocolVersion;

  /// Server push notifications that are not subscription snapshots
  /// (e.g. `notifications/message_received`, `notifications/ticket_*`).
  Stream<JsonRpcNotification> get notifications => _notifications.stream;

  /// The underlying transport's connection state — `open`, then `closed` when
  /// the socket drops. Web/desktop-remote clients watch this to drive
  /// auto-reconnect (the client itself does not reconnect; it correlates frames
  /// on a single channel, so a new channel needs a new client).
  Stream<RemoteChannelState> get connectionState => _channel.state;

  /// Whether the underlying transport is currently open.
  bool get isOpen => _channel.isOpen;

  /// Begins consuming inbound frames. Idempotent.
  void start() {
    _incomingSub ??= _channel.incoming.listen(_onFrame);
  }

  /// The connected server's build identity from the last `initialize`
  /// response — its advertised version, git sha and repo-RPC catalog
  /// version. Null before initialize completes or when the server predates
  /// these fields (an old server is exactly the mismatch worth surfacing).
  ServerBuild? get serverBuild => _serverBuild;
  ServerBuild? _serverBuild;

  /// Sends `initialize` and returns the result (incl. `capabilities`).
  ///
  /// The default [clientVersion] is the CI-stamped [BuildInfo.buildVersion]
  /// the client was compiled with, so every caller reports the truth without
  /// each of them threading a version string.
  Future<Map<String, dynamic>> initialize({
    String clientName = 'cc-client',
    String clientVersion = BuildInfo.buildVersion,
  }) async {
    final res = await _request('initialize', {
      'clientInfo': {'name': clientName, 'version': clientVersion},
      'protocol': {'min': RepoRpcProtocol.min, 'max': RepoRpcProtocol.max},
    });
    // The range was previously sent and then ignored by both sides. Now the
    // server answers with the agreed version (or refuses outright), so a
    // mismatch surfaces here instead of as an inexplicable frame error later.
    _throwIfError(res);
    final result = (res['result'] as Map?)?.cast<String, dynamic>() ?? {};
    final caps = result['capabilities'];
    final proto = caps is Map ? caps['protocol'] : null;
    _agreedProtocolVersion = proto is Map
        ? (proto['agreed'] as num?)?.toInt()
        : null;
    _serverBuild = ServerBuild.fromInitializeResult(result);
    return result;
  }

  /// Lists the workspaces this session may bind to (for the switcher). Each
  /// entry is `{id, name}`; the server decides what the device is allowed to see.
  Future<List<Map<String, dynamic>>> listWorkspaces() async {
    final res = await _request(RpcMethods.listWorkspaces, const {});
    _throwIfError(res);
    final result = (res['result'] as Map?)?.cast<String, dynamic>() ?? {};
    final list = (result['workspaces'] as List?) ?? const [];
    return list.whereType<Map>().map((w) => w.cast<String, dynamic>()).toList();
  }

  /// Merges [activeWorkspaceId] into [args] as `workspace_id` unless the caller
  /// already named one (an explicit per-call workspace always wins). Returns
  /// [args] unchanged when there is no active workspace.
  Map<String, dynamic> _withWorkspace(Map<String, dynamic> args) {
    final ws = activeWorkspaceId;
    if (ws == null || args.containsKey('workspace_id')) {
      return args;
    }
    return {'workspace_id': ws, ...args};
  }

  /// Invokes a declared repo operation, returning its typed `data`. Throws
  /// [RemoteRpcException] on a JSON-RPC error.
  ///
  /// [idempotencyKey] (PRD 19 §3) is a first-class field of the envelope, minted
  /// once per *logical action* and reused across every retry of that intent, so
  /// a double-click / reconnect replay / offline flush collapse to one apply.
  /// [dryRun] (PRD 19 §4) asks the server for the op's [ActionPreview] instead
  /// of applying it (only ops that declare a preview support it).
  /// [timeout] overrides the client-wide request timeout for long-running ops
  /// (e.g. a newsfeed refresh that fetches every feed host-side).
  /// [coalesce] shares an identical request that is already in flight instead
  /// of issuing a second one. Defaults to "yes for a read-shaped op name" —
  /// see [isReadShapedOp] and [_isCoalescable].
  Future<Map<String, dynamic>> call(
    String op,
    Map<String, dynamic> args, {
    int? opVersion,
    String? idempotencyKey,
    bool dryRun = false,
    Duration? timeout,
    bool? coalesce,
  }) async {
    final res = await callResult(
      op,
      args,
      opVersion: opVersion,
      idempotencyKey: idempotencyKey,
      dryRun: dryRun,
      timeout: timeout,
      coalesce: coalesce,
    );
    return (res['data'] as Map?)?.cast<String, dynamic>() ?? {};
  }

  /// A one-shot read owned by its listeners, not by ordinary call coalescing.
  Stream<Map<String, dynamic>> watchCall(String op, Map<String, dynamic> args) {
    if (!offlineSafeReadOps.contains(op)) {
      throw ArgumentError.value(op, 'op', 'Not an offline-safe read operation');
    }
    return () async* {
      final effectiveArgs = _withWorkspace(args);
      final key = _callKey(op, null, effectiveArgs);
      final shared = _sharedReads.putIfAbsent(key, () {
        late final _SharedSubscription entry;
        entry = _SharedSubscription(
          _watchCallRaw(op, effectiveArgs),
          onEmpty: () {
            if (identical(_sharedReads[key], entry)) {
              _sharedReads.remove(key);
            }
          },
        );
        return entry;
      });
      yield* shared.attach();
    }();
  }

  Stream<Map<String, dynamic>> _watchCallRaw(
    String op,
    Map<String, dynamic> effectiveArgs,
  ) {
    late final StreamController<Map<String, dynamic>> controller;
    _CancelableRequest? request;
    Timer? retryTimer;
    Completer<void>? retryWaiter;
    var cancelled = false;

    Future<void> run() async {
      final params = {'op': op, 'args': effectiveArgs};
      try {
        for (var attempt = 0; !cancelled; attempt++) {
          request = _requestCancelable(RpcMethods.repoCall, params);
          final response = await request!.future;
          request = null;
          if (cancelled) {
            return;
          }
          final error = response['error'];
          if (error is Map &&
              error['code'] == RpcErrorCodes.rateLimited &&
              attempt < _retryAttempts - 1) {
            final target = _retryBaseDelay * (1 << attempt);
            final delay = Duration(
              microseconds:
                  (target.inMicroseconds * (0.5 + _jitter.nextDouble() * 0.5))
                      .round(),
            );
            final waiter = Completer<void>();
            retryWaiter = waiter;
            retryTimer = Timer(delay, waiter.complete);
            await waiter.future;
            retryTimer = null;
            retryWaiter = null;
            continue;
          }
          _throwIfError(response);
          if (cancelled) {
            return;
          }
          final result = (response['result'] as Map).cast<String, dynamic>();
          controller.add(
            (result['data'] as Map?)?.cast<String, dynamic>() ?? {},
          );
          await controller.close();
          return;
        }
      } catch (error, stack) {
        if (!cancelled && !controller.isClosed) {
          controller.addError(error, stack);
          await controller.close();
        }
      }
    }

    controller = StreamController<Map<String, dynamic>>(
      onListen: () => unawaited(run()),
      onCancel: () {
        cancelled = true;
        request?.cancel();
        retryTimer?.cancel();
        final waiter = retryWaiter;
        if (waiter != null && !waiter.isCompleted) {
          waiter.complete();
        }
      },
    );
    return controller.stream;
  }

  /// As [call], but returns the whole `result` envelope — `{op, data,
  /// deduplicated?, dry_run?}` — for callers that need to observe the
  /// idempotency/dry-run flags (bulk ops, the mutation queue, tests).
  /// [coalesce] shares an identical in-flight request; null derives it from
  /// the op name (see [isReadShapedOp]).
  Future<Map<String, dynamic>> callResult(
    String op,
    Map<String, dynamic> args, {
    int? opVersion,
    String? idempotencyKey,
    bool dryRun = false,
    Duration? timeout,
    bool? coalesce,
  }) {
    final effectiveArgs = _withWorkspace(args);
    final coalesceKey =
        _isCoalescable(
          op: op,
          coalesce: coalesce,
          idempotencyKey: idempotencyKey,
          dryRun: dryRun,
        )
        ? _callKey(op, opVersion, effectiveArgs)
        : null;
    if (coalesceKey != null) {
      final inFlight = _inFlightCalls[coalesceKey];
      // Only share a request issued in the last [_coalesceWindow]. Coalescing
      // is for callers that fire at the SAME MOMENT — two providers mounting
      // in one frame — not for deduping across time. Without the window, a
      // request that HANGS (a server that never answers, a socket attached
      // after the request went out) would be handed to every later caller
      // until it timed out, so a periodic health probe would stop probing
      // exactly when it matters most.
      if (inFlight != null &&
          DateTime.now().difference(inFlight.at) < _coalesceWindow) {
        return inFlight.future;
      }
    }
    if (coalesceKey == null) {
      return _callResultUncoalesced(
        op,
        effectiveArgs,
        opVersion: opVersion,
        idempotencyKey: idempotencyKey,
        dryRun: dryRun,
        timeout: timeout,
      );
    }
    // The entry is cleared in a `finally` INSIDE the async body, so it is gone
    // before this future completes. Clearing it from a `whenComplete` on the
    // outside would leave a microtask window in which the entry is still
    // registered but already resolved — and a caller arriving in that window
    // would be handed a STALE answer for a request that had finished. That is
    // exactly the shape of a periodic refresh probe.
    late final Future<Map<String, dynamic>> future;
    future = () async {
      try {
        return await _callResultUncoalesced(
          op,
          effectiveArgs,
          opVersion: opVersion,
          idempotencyKey: idempotencyKey,
          dryRun: dryRun,
          timeout: timeout,
        );
      } finally {
        // Cleared on BOTH outcomes: a failed call must not pin its own
        // failure for every later caller.
        if (identical(_inFlightCalls[coalesceKey]?.future, future)) {
          _inFlightCalls.remove(coalesceKey);
        }
      }
    }();
    _inFlightCalls[coalesceKey] = _InFlightCall(future, DateTime.now());
    return future;
  }

  /// Calls in flight, keyed by `(op, opVersion, args)`.
  final Map<String, _InFlightCall> _inFlightCalls = {};

  /// How long an in-flight request stays shareable. Generous next to the one
  /// frame in which mount-time duplicates arrive, short next to any timeout.
  static const Duration _coalesceWindow = Duration(milliseconds: 100);

  /// Whether a call may share another caller's in-flight request.
  ///
  /// The client holds no op-kind metadata, so coalescing EVERYTHING would
  /// silently collapse two genuinely separate identical mutations (a user
  /// sending the same text twice) into one. It therefore defaults to the op
  /// NAME — see [isReadShapedOp], which the server's catalog is pinned
  /// against — and a caller can always force the answer either way.
  ///
  /// A keyed mutation and a dry run are excluded even when a caller opts in:
  /// the former is a distinct logical action whose ledger entry the caller
  /// needs, and the latter must never be answered from a real call.
  static bool _isCoalescable({
    required String op,
    required bool? coalesce,
    required String? idempotencyKey,
    required bool dryRun,
  }) => (coalesce ?? isReadShapedOp(op)) && idempotencyKey == null && !dryRun;

  /// Stable coalescing key. Same canonicalization rationale as [_subKey]: a
  /// mismatch only costs a missed dedupe, never correctness.
  static String _callKey(String op, int? opVersion, Map<String, dynamic> args) {
    final keys = args.keys.toList()..sort();
    return '$op|$opVersion|'
        '${jsonEncode({for (final k in keys) k: args[k]})}';
  }

  Future<Map<String, dynamic>> _callResultUncoalesced(
    String op,
    Map<String, dynamic> effectiveArgs, {
    int? opVersion,
    String? idempotencyKey,
    bool dryRun = false,
    Duration? timeout,
  }) async {
    final params = {
      'op': op,
      'opVersion': ?opVersion,
      'idempotency_key': ?idempotencyKey,
      if (dryRun) 'dry_run': true,
      'args': effectiveArgs,
    };
    for (var attempt = 0; ; attempt++) {
      final res = await _request(RpcMethods.repoCall, params, timeout: timeout);
      final error = res['error'];
      final code = error is Map
          ? error['code'] as int? ?? RpcErrorCodes.internalError
          : null;
      // A `-32005` on `repo/call` is ALWAYS a pre-dispatch refusal — the
      // session's in-flight cap or request budget said no before the op ran —
      // so a retry can never double-apply a mutation. That is the only code
      // retried here: a timeout or a dropped connection leaves the op's side
      // effects unknown, and every other error is a terminal statement about
      // the request itself.
      if (code == RpcErrorCodes.rateLimited && attempt < _retryAttempts - 1) {
        // Full jitter (half of the exponential target, randomized) so N
        // clients refused together do not retry in lockstep.
        final target = _retryBaseDelay * (1 << attempt);
        await Future<void>.delayed(
          Duration(
            microseconds:
                (target.inMicroseconds * (0.5 + _jitter.nextDouble() * 0.5))
                    .round(),
          ),
        );
        continue;
      }
      _throwIfError(res);
      return (res['result'] as Map).cast<String, dynamic>();
    }
  }

  /// Total attempts a rate-limit-refused call may make (first try included)
  /// before the refusal surfaces to the caller. Two retries ride out a burst
  /// refusal without turning a slow caller into a self-inflicted storm.
  static const int _retryAttempts = 3;

  /// Base backoff between refused-call retries, doubled per attempt. A
  /// refusal answers immediately, so the cost of a retry is the backoff, not
  /// the round-trip.
  static const Duration _retryBaseDelay = Duration(milliseconds: 250);

  static final Random _jitter = Random();

  /// Opens a reactive subscription. Each emission is a full snapshot map. The
  /// `sub/unsubscribe` is sent automatically when the returned stream is
  /// cancelled; the last listener of a shared entry cancels the underlying
  /// request/subscription, which is what navigation-driven teardown rides.
  ///
  /// Deduplicates identical live subscriptions: several callers with the same
  /// `(query, effective-args)` share ONE server subscription, ref-counted so
  /// one consumer leaving never cancels another's read. Late joiners are
  /// replayed the last snapshot so their stream still gets an immediate first
  /// emission.
  ///
  /// Returned SYNCHRONOUSLY (no async* wrapper): the subscribe request must
  /// leave on the listener's first microtask chain. An extra generator hop
  /// delays `sub/subscribe` past a caller's event boundary, and a server
  /// that pushes its first snapshot on subscribe then races that dispatch —
  /// the seed frame lands for an id the host never issued and is dropped.
  Stream<Map<String, dynamic>> subscribe(
    String query,
    Map<String, dynamic> args,
  ) {
    final effectiveArgs = _withWorkspace(args);
    final key = _subKey(query, effectiveArgs);
    late final _SharedSubscription shared;
    shared = _shared.putIfAbsent(
      key,
      () => _SharedSubscription(
        _subscribeRaw(query, effectiveArgs),
        onEmpty: () {
          if (identical(_shared[key], shared)) {
            _shared.remove(key);
          }
        },
      ),
    );
    return shared.attach();
  }

  /// Stable dedupe key for a subscription. Sorts the top-level args so callers
  /// that build the map in a different order still collide (subscription args
  /// are flat coordinate maps). A mismatch only costs a missed dedupe, never
  /// correctness.
  static String _subKey(String query, Map<String, dynamic> args) {
    final keys = args.keys.toList()..sort();
    return '$query${jsonEncode({for (final k in keys) k: args[k]})}';
  }

  /// The undeduped single subscription — one server subscription per call.
  /// [subscribe] layers ref-counted sharing over this.
  Stream<Map<String, dynamic>> _subscribeRaw(
    String query,
    Map<String, dynamic> args,
  ) {
    late final StreamController<Map<String, dynamic>> controller;
    String? subId;
    _CancelableRequest? request;
    // A response already accepted before cancellation is unsubscribed below;
    // a late response is cleaned up by the server's request-id cancellation.
    var cancelled = false;
    controller = StreamController<Map<String, dynamic>>(
      onListen: () async {
        try {
          final req = _requestCancelable(RpcMethods.subscribe, {
            'query': query,
            'args': _withWorkspace(args),
          });
          request = req;
          final res = await req.future;
          request = null;
          if (cancelled && res.containsKey('error')) {
            return;
          }
          if (res.containsKey('error')) {
            // The server created NO subscription on an error — nothing to
            // unsubscribe. This branch MUST return before the id block below so a
            // racing cancel (which set `cancelled`) can't trigger a spurious
            // unsubscribe for an id the server never issued.
            final err = (res['error'] as Map).cast<String, dynamic>();
            controller.addError(
              RemoteRpcException(
                err['code'] as int? ?? RpcErrorCodes.internalError,
                err['message'] as String? ?? 'subscribe failed',
              ),
            );
            await controller.close();
            return;
          }
          final id = ((res['result'] as Map)['subscriptionId']) as String?;
          if (id == null) {
            return;
          }
          if (cancelled) {
            // The ack was accepted just before cancellation; its newly known
            // subscription still needs an ordinary unsubscribe, and a trailing
            // snapshot for it must be ignored rather than buffered.
            _dropEarly(id);
            _markDeadSubscription(id);
            unawaited(_unsubscribe(id));
            return;
          }
          subId = id;
          _subs[id] = controller;
          _replayEarly(id, controller);
        } catch (e, s) {
          if (!cancelled && !controller.isClosed) {
            controller.addError(e, s);
            await controller.close();
          }
        }
      },
      onCancel: () async {
        cancelled = true;
        final req = request;
        if (req != null) {
          req.cancel();
          _cancelledSubscribes[req.id] = null;
          _trimCancelledSubscribes();
        }
        final id = subId;
        if (id == null) {
          // The round-trip is still in flight; a late ack is handled in
          // [_onFrame] via [_cancelledSubscribes] (the server also tears the
          // subscription down from the cancellation notification).
          return;
        }
        _subs.remove(id);
        _dropEarly(id);
        _markDeadSubscription(id);
        await _unsubscribe(id);
      },
    );
    return controller.stream;
  }

  /// Replays a snapshot / stream error that landed before [_subs] knew [id].
  void _replayEarly(
    String id,
    StreamController<Map<String, dynamic>> controller,
  ) {
    final snapshot = _earlySnapshots.remove(id);
    if (snapshot != null && !controller.isClosed) {
      controller.add(snapshot);
    }
    final error = _earlyErrors.remove(id);
    if (error != null && !controller.isClosed) {
      controller.addError(error);
      unawaited(controller.close());
      _subs.remove(id);
    }
  }

  void _dropEarly(String id) {
    _earlySnapshots.remove(id);
    _earlyErrors.remove(id);
  }

  /// Best-effort `sub/unsubscribe` for [subscriptionId]. Skips during [close]
  /// and on a dead channel: a request there never gets a response and would
  /// block for the full RPC timeout — once per live subscription, so close()
  /// on a dropped socket would hang ~timeout × N. The server drops a session's
  /// subscriptions when the connection ends anyway.
  Future<void> _unsubscribe(String subscriptionId) async {
    if (_closing || !_channel.isOpen) {
      return;
    }
    try {
      await _request(RpcMethods.unsubscribe, {
        'subscriptionId': subscriptionId,
      });
    } catch (_) {}
  }

  Future<Map<String, dynamic>> _request(
    String method,
    Map<String, dynamic> params, {
    Duration? timeout,
  }) async {
    final id = ++_nextId;
    final completer = Completer<Map<String, dynamic>>();
    _pending[id] = completer;
    try {
      await _channel.send({
        'jsonrpc': '2.0',
        'id': id,
        'method': method,
        'params': params,
      });
    } on Object {
      // The frame never left: drop the entry instead of orphaning it in
      // `_pending` for the client's lifetime (a dropped socket makes
      // `send` throw, and this is exactly when it happens).
      _pending.remove(id);
      rethrow;
    }
    final effectiveTimeout = timeout ?? _timeout;
    return completer.future.timeout(
      effectiveTimeout,
      onTimeout: () {
        _pending.remove(id);
        throw TimeoutException('RPC $method timed out', effectiveTimeout);
      },
    );
  }

  _CancelableRequest _requestCancelable(
    String method,
    Map<String, dynamic> params,
  ) {
    final id = ++_nextId;
    final completer = Completer<Map<String, dynamic>>();
    _pending[id] = completer;
    final sent = Future<void>.sync(
      () => _channel.send({
        'jsonrpc': '2.0',
        'id': id,
        'method': method,
        'params': params,
      }),
    );
    // Attach to the response before awaiting send: a listener may cancel
    // while an asynchronous transport is still flushing the outgoing frame.
    final future =
        Future.wait<Object?>([
              sent.then<Object?>((_) => null),
              completer.future,
            ], eagerError: true)
            .then((values) => values[1] as Map<String, dynamic>)
            .timeout(
              _timeout,
              onTimeout: () {
                _pending.remove(id);
                throw TimeoutException('RPC $method timed out', _timeout);
              },
            );
    unawaited(
      sent.then<void>(
        (_) {},
        onError: (Object _) {
          _pending.remove(id);
        },
      ),
    );
    return _CancelableRequest(id, future, () {
      if (!identical(_pending[id], completer)) {
        return;
      }
      _pending.remove(id);
      completer.completeError(const RemoteRpcClientClosedException());
      // A channel can buffer send asynchronously: keep the cancel behind the
      // original frame so request-id cleanup cannot overtake setup.
      unawaited(
        sent
            .then((_) async {
              if (!_closing && _channel.isOpen) {
                await _channel.send({
                  'jsonrpc': '2.0',
                  'method': RpcMethods.cancelRequest,
                  'params': {'id': id},
                });
              }
            })
            .catchError((Object _) {}),
      );
    });
  }

  /// Bounds [_deadSubscriptions]; see there for why trimming is safe.
  void _markDeadSubscription(String id) {
    _deadSubscriptions.add(id);
    while (_deadSubscriptions.length > 128) {
      _deadSubscriptions.remove(_deadSubscriptions.first);
    }
  }

  void _trimCancelledSubscribes() {
    while (_cancelledSubscribes.length > 32) {
      _cancelledSubscribes.remove(_cancelledSubscribes.keys.first);
    }
  }

  void _onFrame(Map<String, dynamic> frame) {
    final id = frame['id'];
    if (id is int && _pending.containsKey(id)) {
      _pending.remove(id)!.complete(frame);
      return;
    }
    if (id is int && _cancelledSubscribes.containsKey(id)) {
      // A late ack for an abandoned setup: the server already tore the
      // subscription down (or will, from the cancellation notification).
      // Record the id only so trailing frames for it are ignored, then stop
      // tracking the request.
      final result = frame['result'];
      final subId = result is Map ? result['subscriptionId'] : null;
      if (subId is String) {
        _dropEarly(subId);
        _markDeadSubscription(subId);
      }
      _cancelledSubscribes.remove(id);
      return;
    }
    final method = frame['method'];
    if (method is! String) {
      return;
    }
    final params = (frame['params'] as Map?)?.cast<String, dynamic>() ?? {};
    switch (method) {
      case RpcMethods.subSnapshot:
        final subId = params['subscriptionId'] as String?;
        final data = (params['data'] as Map?)?.cast<String, dynamic>() ?? {};
        if (subId == null) {
          return;
        }
        // Not lifted into a local: `_subs` owns the controller (it is closed
        // on unsubscribe/dispose) and a local Sink here reads to the analyzer
        // as one this function forgot to close.
        if (_subs.containsKey(subId)) {
          _subs[subId]!.add(data);
        } else if (_deadSubscriptions.contains(subId)) {
          return; // Abandoned setup / unsubscribed id: never buffer dead data.
        } else {
          _earlySnapshots[subId] = data;
        }
      case RpcMethods.subError:
        final subId = params['subscriptionId'] as String?;
        if (subId == null) {
          return;
        }
        final kind = (params['data'] as Map?)?['kind'];
        final exception = RemoteRpcException(
          params['code'] as int? ?? RpcErrorCodes.internalError,
          kind is String ? 'subscription error: $kind' : 'subscription error',
        );
        final controller = _subs.remove(subId);
        if (controller != null && !controller.isClosed) {
          // Surface the server-side stream failure so the consumer's
          // StreamProvider transitions to AsyncError (retry UI) instead of
          // hanging in loading forever — a silent close here previously masked
          // any host-side subscription error as an infinite spinner.
          controller.addError(exception);
          unawaited(controller.close());
        } else if (_deadSubscriptions.contains(subId)) {
          return;
        } else {
          _earlyErrors[subId] = exception;
        }
      default:
        _notifications.add(JsonRpcNotification(method: method, params: params));
    }
  }

  void _throwIfError(Map<String, dynamic> res) {
    final error = res['error'];
    if (error is Map) {
      throw RemoteRpcException(
        error['code'] as int? ?? RpcErrorCodes.internalError,
        error['message'] as String? ?? 'error',
        error['data'],
      );
    }
  }

  /// Closes the client (cancels inbound, fails pending, closes subscriptions).
  Future<void> close() async {
    _closing = true;
    await _incomingSub?.cancel();
    for (final c in _pending.values) {
      if (!c.isCompleted) {
        c.completeError(
          const RemoteRpcClientClosedException(
            'RPC client closed; pending requests cancelled.',
          ),
        );
      }
    }
    _pending.clear();
    // Snapshot the controllers and clear the map *before* closing them.
    // Closing a subscription controller drives its onCancel callback (set in
    // [subscribe]), which calls `_subs.remove(...)` — mutating `_subs` while
    // iterating its values would throw a ConcurrentModificationError. Clearing
    // first turns those removes into no-ops and we iterate the snapshot.
    final subs = _subs.values.toList();
    _subs.clear();
    _earlySnapshots.clear();
    _earlyErrors.clear();
    for (final s in subs) {
      await s.close();
    }
    _cancelledSubscribes.clear();
    _deadSubscriptions.clear();
    // The shared subscriptions wrap those `_subs` streams; closing the sources
    // drives each shared layer's onDone → it closes its listeners and removes
    // itself from [_shared]. Clear defensively in case any had not yet started.
    _shared.clear();
    _sharedReads.clear();
    await _notifications.close();
  }
}

class _CancelableRequest {
  _CancelableRequest(this.id, this.future, this.cancel);

  /// The JSON-RPC request id this request travels under.
  final int id;

  final Future<Map<String, dynamic>> future;
  final void Function() cancel;
}

/// Operations explicitly reviewed for render-only snapshot persistence.
/// This is deliberately stricter than the naming-based call coalescing rule.
const offlineSafeReadOps = <String>{
  'messaging.getMessageById',
  'pr.searchReviewedByForWorkspace',
  'pr.closedByAuthorForWorkspace',
  'pr_review.getJobRunDetail',
  'meeting.getByWorkspace',
  'meeting.getById',
  'meeting.getSegments',
  'meeting.getSpeakers',
  'calendar.getAccounts',
  'calendar.getEventForMeeting',
  'calendar.getMeetingIdForEvent',
};

/// Ref-counted fan-out over one underlying [RemoteRpcClient._subscribeRaw]
/// stream, so N callers requesting the same subscription coordinates share a
/// single server subscription.
///
/// The source is a single-subscription stream; this listens to it exactly once
/// and forwards every event to all attached per-listener controllers. The last
/// snapshot is cached and replayed to a late joiner so its stream still gets an
/// immediate first emission (the SWR reconciliation contract). When the last
/// listener cancels — or the source ends/errors — the shared entry tears down
/// and removes itself via [onEmpty], so a subsequent request re-establishes a
/// fresh subscription.
class _SharedSubscription {
  _SharedSubscription(this._source, {required this.onEmpty});

  final Stream<Map<String, dynamic>> _source;

  /// Invoked exactly once when this shared subscription is finished with (last
  /// listener gone, or the source completed). Removes it from the owner's map.
  final void Function() onEmpty;

  final Set<StreamController<Map<String, dynamic>>> _listeners =
      <StreamController<Map<String, dynamic>>>{};
  StreamSubscription<Map<String, dynamic>>? _sub;
  Map<String, dynamic>? _last;
  bool _started = false;
  bool _dead = false;

  /// Returns a per-listener stream attached to this shared subscription.
  Stream<Map<String, dynamic>> attach() {
    late final StreamController<Map<String, dynamic>> controller;
    controller = StreamController<Map<String, dynamic>>(
      onListen: () {
        _listeners.add(controller);
        _start();
        // Replay the latest snapshot to a late joiner so it does not wait for
        // the next server push to leave its loading state.
        final last = _last;
        if (last != null && !controller.isClosed) {
          controller.add(last);
        }
      },
      onCancel: () {
        _listeners.remove(controller);
        if (_listeners.isEmpty) {
          _teardown();
        }
      },
    );
    return controller.stream;
  }

  void _start() {
    if (_started || _dead) {
      return;
    }
    _started = true;
    _sub = _source.listen(
      (data) {
        _last = data;
        for (final l in _listeners.toList()) {
          if (!l.isClosed) {
            l.add(data);
          }
        }
      },
      onError: (Object e, StackTrace st) {
        for (final l in _listeners.toList()) {
          if (!l.isClosed) {
            l.addError(e, st);
          }
        }
      },
      onDone: () {
        // The source ended (server `sub/error` close, or the channel dropped).
        // Close every listener and drop this entry so the next request opens a
        // fresh subscription.
        _dead = true;
        final listeners = _listeners.toList();
        _listeners.clear();
        for (final l in listeners) {
          if (!l.isClosed) {
            unawaited(l.close());
          }
        }
        onEmpty();
      },
    );
  }

  void _teardown() {
    if (_dead) {
      return;
    }
    _dead = true;
    unawaited(_sub?.cancel());
    _sub = null;
    onEmpty();
  }
}

/// Whether [op]'s NAME marks it as a read.
///
/// The client cannot see the server's `RepoOpKind`, so in-flight coalescing
/// keys off this naming convention instead. It is not a guess: the catalog is
/// pinned against it by `read_shaped_op_names_test.dart`, which fails if any
/// op with one of these segments is registered as a mutation. Getting it
/// wrong in that direction would let two separate identical writes collapse
/// into one, which is why the convention is enforced rather than assumed.
bool isReadShapedOp(String op) {
  final dot = op.indexOf('.');
  if (dot < 0) {
    return false;
  }
  final verb = op.substring(dot + 1);
  for (final prefix in kReadOpVerbPrefixes) {
    if (verb.startsWith(prefix)) {
      return true;
    }
  }
  return false;
}

/// Verb prefixes (after the `namespace.`) that mark a read-only op.
/// Deliberately conservative: a verb is here only because the catalog
/// actually uses it for reads. `read_shaped_op_names_test.dart` fails both
/// ways — if a mutation ever takes one of these names, AND if a name here
/// matches nothing (a prefix protecting nothing is a typo waiting to be
/// trusted).
const List<String> kReadOpVerbPrefixes = [
  'list',
  'get',
  'search',
  'describe',
  'export',
  'status',
  'capabilities',
];

/// One shareable in-flight request and when it was issued.
class _InFlightCall {
  const _InFlightCall(this.future, this.at);

  final Future<Map<String, dynamic>> future;
  final DateTime at;
}
