import 'dart:async';

import 'package:cc_domain/features/model_routing/model_routing.dart';

/// Owns the in-memory model catalog: assembles it from a [ModelsDevSource],
/// resolves provider enablement from host signals, applies governance policy,
/// and refreshes in the background. The desktop wires this in-process; the
/// cc_server wires it behind the `models.catalog` RPC op.
///
/// [catalog] returns the finalized catalog (enablement + policy applied);
/// [refresh] re-pulls models.dev; [watch] streams the raw catalog on each load.
class ModelCatalogService {
  /// Creates a [ModelCatalogService].
  ///
  /// [presentEnvKeys] returns the env var names that are currently set (used to
  /// resolve `enabled: via env`). [accountProviders] maps providerId → an
  /// auth-service name for providers backed by a logged-in account / detected
  /// adapter (resolved as `enabled: via account`).
  ModelCatalogService({
    required ModelsDevSource source,
    Set<String> Function()? presentEnvKeys,
    Map<String, String> Function()? accountProviders,
    Duration backgroundRefreshInterval = const Duration(hours: 1),
  }) : _source = source,
       _presentEnvKeys = presentEnvKeys ?? (() => const <String>{}),
       _accountProviders = accountProviders ?? (() => const <String, String>{}),
       _backgroundRefreshInterval = backgroundRefreshInterval;

  final ModelsDevSource _source;
  final Set<String> Function() _presentEnvKeys;
  final Map<String, String> Function() _accountProviders;
  final Duration _backgroundRefreshInterval;

  final StreamController<ModelCatalog> _controller =
      StreamController<ModelCatalog>.broadcast();
  Timer? _timer;
  ModelCatalog _raw = ModelCatalog.empty;
  bool _loaded = false;
  Future<void>? _inFlight;

  /// Emits the raw catalog whenever it is (re)loaded.
  Stream<ModelCatalog> watch() => _controller.stream;

  /// Whether a non-empty catalog has been assembled.
  bool get isLoaded => _loaded;

  /// Loads the catalog once (idempotent; concurrent callers share the fetch).
  Future<void> ensureLoaded() {
    if (_loaded) {
      return Future.value();
    }
    return _inFlight ??= _load().whenComplete(() => _inFlight = null);
  }

  Future<void> _load() async {
    final json = await _source.load();
    if (json != null && json.isNotEmpty) {
      _raw = ModelCatalog.fromModelsDev(json);
      _loaded = true;
      if (!_controller.isClosed) {
        _controller.add(_raw);
      }
    }
  }

  /// The finalized catalog: provider enablement resolved, [policy]-denied
  /// providers removed. Loads on first call.
  Future<ModelCatalog> catalog({ProviderPolicyEngine? policy}) async {
    await ensureLoaded();
    return _finalize(policy);
  }

  /// The finalized catalog from already-loaded data (synchronous; empty until
  /// [ensureLoaded] / [catalog] has run).
  ModelCatalog catalogSync({ProviderPolicyEngine? policy}) => _finalize(policy);

  ModelCatalog _finalize(ProviderPolicyEngine? policy) {
    final checker = ProviderEnablementChecker(
      presentEnvKeys: _presentEnvKeys(),
      accountProviders: _accountProviders(),
    );
    return _raw.finalize(enablement: checker.resolve, policy: policy);
  }

  /// Forces a refresh from models.dev (past the TTL when `force`).
  Future<ModelCatalog> refresh({bool force = true}) async {
    final json = await _source.refresh(force: force);
    if (json != null && json.isNotEmpty) {
      _raw = ModelCatalog.fromModelsDev(json);
      _loaded = true;
      if (!_controller.isClosed) {
        _controller.add(_raw);
      }
    }
    return _finalize(null);
  }

  /// Starts the hourly background refresh. Safe to call once; subsequent calls are ignored.
  void startBackgroundRefresh() {
    _timer ??= Timer.periodic(_backgroundRefreshInterval, (_) {
      // Best-effort; failures fall back to cache/snapshot inside the source.
      unawaited(refresh(force: true));
    });
    // Kick an initial load without blocking the caller.
    unawaited(ensureLoaded());
  }

  /// Releases the timer and stream.
  void dispose() {
    _timer?.cancel();
    _timer = null;
    unawaited(_controller.close());
  }
}
