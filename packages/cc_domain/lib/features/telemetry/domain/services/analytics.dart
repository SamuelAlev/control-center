import 'dart:collection';

import 'package:cc_domain/features/telemetry/domain/entities/analytics_envelope.dart';
import 'package:cc_domain/features/telemetry/domain/entities/analytics_event.dart';
import 'package:cc_domain/features/telemetry/domain/entities/telemetry_config.dart';
import 'package:cc_domain/features/telemetry/domain/ports/analytics_sink.dart';
import 'package:cc_domain/features/telemetry/domain/services/analytics_property_policy.dart';
import 'package:cc_domain/features/telemetry/domain/services/analytics_pseudonymizer.dart';
import 'package:cc_domain/features/telemetry/domain/value_objects/analytics_context.dart';
import 'package:cc_domain/features/telemetry/domain/value_objects/analytics_id.dart';

/// The one analytics entry point per process.
///
/// Call sites hand it events from the tracking plan (`AnalyticsEvents`) and
/// screen views; it decides whether anything is sent, and what:
///
/// 1. **Consent.** Nothing reaches a provider until the server's
///    [TelemetryConfig] has arrived and allows usage analytics. Records made
///    before then wait in a small bounded buffer; they are sent if the
///    config allows collection and discarded if it does not. Turning the
///    switch off closes the provider sink, dropping whatever it still queued.
/// 2. **Build mode.** When [collectionAllowed] is false (debug and profile
///    builds), records go to the development sink, which logs them, and
///    never to the provider, unless the server's config sets
///    [TelemetryConfig.debugBuildsAllowed] (`CC_ANALYTICS_DEBUG=1` in its
///    `.env`) to test the pipeline end to end.
/// 3. **Privacy.** Context and event properties are merged, checked by
///    [AnalyticsPropertyPolicy], and every [AnalyticsId] is replaced by its
///    pseudonym under the install's salt. Refused properties are dropped and
///    reported through `onDiagnostic` (key and reason only, never the
///    value).
///
/// It never throws into a call site and never waits on the network.
class Analytics {
  /// Creates an [Analytics].
  ///
  /// `sinkFactory` builds the provider sink once collection is allowed;
  /// swapping providers means passing a different factory.
  Analytics({
    required this._context,
    required this.collectionAllowed,
    required this._sinkFactory,
    this._developmentSink = const NoopAnalyticsSink(),
    this._onDiagnostic,
    DateTime Function()? clock,
    this.pendingLimit = 100,
  }) : _clock = clock ?? DateTime.now;

  /// Whether this build may send to the provider on its own (release
  /// builds). See [TelemetryConfig.debugBuildsAllowed] for the override.
  final bool collectionAllowed;

  /// Most records held while the server's decision is unknown.
  final int pendingLimit;

  final AnalyticsSink Function(TelemetryConfig config) _sinkFactory;
  final AnalyticsSink _developmentSink;
  final void Function(String message)? _onDiagnostic;
  final DateTime Function() _clock;

  AnalyticsContext _context;
  TelemetryConfig? _config;
  AnalyticsPseudonymizer? _pseudonymizer;
  AnalyticsSink? _sink;
  String? _userId;
  String? _deviceId;
  String? _currentPath;
  var _sequence = 0;
  var _disposed = false;
  final _pending = Queue<_PendingRecord>();

  /// The current super properties.
  AnalyticsContext get context => _context;

  /// Whether records go to the provider sink rather than the development
  /// sink.
  bool get _toProvider =>
      collectionAllowed || (_config?.debugBuildsAllowed ?? false);

  /// Whether records are currently delivered (to the provider, or to the
  /// development sink in non-release builds).
  bool get isCollecting =>
      !_disposed && (_config?.usageAnalyticsEnabled ?? false);

  /// Replaces the super properties, e.g. once the server mode or locale is
  /// known. Applies to records made from now on.
  void updateContext(AnalyticsContext Function(AnalyticsContext) update) {
    _context = update(_context);
  }

  /// Applies the server's telemetry decision.
  void configure(TelemetryConfig config) {
    if (_disposed || config == _config) {
      return;
    }
    final previous = _config;
    _config = config;
    if (previous?.pseudonymSalt != config.pseudonymSalt) {
      _pseudonymizer = AnalyticsPseudonymizer(config.pseudonymSalt);
    }
    if (!config.usageAnalyticsEnabled) {
      _pending.clear();
      _closeSink(flush: false);
      return;
    }
    if (!_toProvider) {
      _closeSink(flush: false);
    } else if (_sink == null || previous?.installId != config.installId) {
      _closeSink(flush: previous?.usageAnalyticsEnabled ?? false);
      _sink = _sinkFactory(config);
    }
    while (_pending.isNotEmpty) {
      _deliver(_pending.removeFirst());
    }
  }

  /// Sets the signed-in user and paired device. Both are pseudonymized;
  /// pass null on sign-out.
  void identify({String? userId, String? deviceId}) {
    _userId = userId == null || userId.isEmpty ? null : userId;
    _deviceId = deviceId == null || deviceId.isEmpty ? null : deviceId;
  }

  /// Records a screen view and remembers its template as the location of
  /// later events.
  void screen(AnalyticsScreenView view) {
    _currentPath = view.path;
    _record(view);
  }

  /// Records a product event.
  void track(AnalyticsEvent event) => _record(event);

  /// Attempts delivery of everything the provider sink queued.
  Future<void> flush() async {
    try {
      await _sink?.flush();
    } on Object catch (e) {
      _diagnose('flush failed: $e');
    }
  }

  /// Flushes and releases the sinks. Later records are dropped.
  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    _disposed = true;
    _pending.clear();
    final sink = _sink;
    _sink = null;
    try {
      await sink?.close();
      await _developmentSink.close();
    } on Object catch (e) {
      _diagnose('close failed: $e');
    }
  }

  void _record(AnalyticsRecord record) {
    if (_disposed) {
      return;
    }
    final pending = _PendingRecord(
      record: record,
      occurredAt: _clock().toUtc(),
      context: _context,
      path: _currentPath,
      sequence: ++_sequence,
      userId: _userId,
      deviceId: _deviceId,
    );
    final config = _config;
    if (config == null) {
      if (_pending.length >= pendingLimit) {
        _pending.removeFirst();
      }
      _pending.add(pending);
      return;
    }
    if (config.usageAnalyticsEnabled) {
      _deliver(pending);
    }
  }

  void _deliver(_PendingRecord pending) {
    final config = _config;
    final pseudonymizer = _pseudonymizer;
    if (config == null || pseudonymizer == null) {
      return;
    }
    final record = pending.record;
    final name = switch (record) {
      AnalyticsEvent(:final name) => name,
      AnalyticsScreenView(:final screen) => screen,
    };
    final merged = <String, Object>{
      ...pending.context.toProperties(),
      'install_id': AnalyticsId(config.installId),
      'event_seq': pending.sequence,
      'user_id': ?AnalyticsId.maybe(pending.userId),
      'device_id': ?AnalyticsId.maybe(pending.deviceId),
      ...record.properties,
    };
    final (:accepted, :refused) = AnalyticsPropertyPolicy.apply(merged);
    for (final violation in refused) {
      _diagnose('dropped property on $name: $violation');
    }
    final properties = <String, Object>{
      for (final MapEntry(:key, :value) in accepted.entries)
        key: value is AnalyticsId ? pseudonymizer.pseudonym(value.raw) : value,
    };
    final distinctRaw = pending.deviceId ?? pending.userId;
    final envelope = AnalyticsEnvelope(
      kind: record is AnalyticsScreenView
          ? AnalyticsEnvelopeKind.screenView
          : AnalyticsEnvelopeKind.event,
      name: name,
      path: switch (record) {
        AnalyticsScreenView(:final path) => path,
        AnalyticsEvent() => pending.path,
      },
      appType: pending.context.appType,
      occurredAt: pending.occurredAt,
      properties: properties,
      distinctId: distinctRaw == null
          ? pseudonymizer.pseudonym(config.installId)
          : pseudonymizer.pseudonym(distinctRaw),
      locale: pending.context.locale,
      screen: pending.context.screen,
    );
    final sink = _toProvider ? _sink : _developmentSink;
    try {
      sink?.record(envelope);
    } on Object catch (e) {
      _diagnose('sink rejected $name: $e');
    }
  }

  void _closeSink({required bool flush}) {
    final sink = _sink;
    _sink = null;
    if (sink == null) {
      return;
    }
    sink
        .close(flush: flush)
        .catchError((Object e) => _diagnose('close failed: $e'));
  }

  void _diagnose(String message) => _onDiagnostic?.call('analytics: $message');
}

class _PendingRecord {
  const _PendingRecord({
    required this.record,
    required this.occurredAt,
    required this.context,
    required this.path,
    required this.sequence,
    required this.userId,
    required this.deviceId,
  });

  final AnalyticsRecord record;
  final DateTime occurredAt;
  final AnalyticsContext context;
  final String? path;
  final int sequence;
  final String? userId;
  final String? deviceId;
}
