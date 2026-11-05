import 'dart:async';
import 'dart:io';

import 'package:cc_domain/features/settings/domain/entities/acp_model.dart';
import 'package:cc_domain/features/settings/domain/entities/adapter.dart'
    show claudeThinkingLevels;
import 'package:cc_infra/src/detection/claude_code_model_probe.dart';
import 'package:cc_infra/src/process/binary_resolver.dart';

/// Claude Code's model vocabulary and context windows, read live from the
/// installed CLI rather than curated, so a new model needs no app update.
///
/// The CLI is probed once per binary, account and [ttl] (see
/// [ClaudeCodeModelProbe]); a CLI upgrade changes the binary's identity and
/// so forces a fresh read. Names follow the app's convention, not the CLI's
/// labels: an alias is `Opus (latest)`, a model id is `Claude Opus 4.6`, a
/// `[1m]` id adds `(1M context)` and a dated snapshot its date.
class ClaudeCodeModelCatalog {
  /// Creates a [ClaudeCodeModelCatalog].
  ///
  /// [configDir] names the account whose view of the CLI is read (null: the
  /// operator's own Claude home).
  ClaudeCodeModelCatalog({
    ClaudeCodeModelProbe? probe,
    Future<String?> Function(String binary)? resolveBinary,
    Future<String?> Function()? configDir,
    DateTime Function()? now,
    this.ttl = const Duration(hours: 1),
    this.retryAfter = const Duration(seconds: 30),
  }) : _probe = probe ?? ClaudeCodeModelProbe(),
       _resolveBinary = resolveBinary ?? resolveBinaryPath,
       _configDir = configDir ?? _noConfigDir,
       _now = now ?? DateTime.now;

  final ClaudeCodeModelProbe _probe;
  final Future<String?> Function(String binary) _resolveBinary;
  final Future<String?> Function() _configDir;
  final DateTime Function() _now;

  /// How long one read of the CLI is trusted. The binary identity already
  /// covers upgrades; this covers a model the provider rolls out to an
  /// account without one. An expired read is still served while a fresh one
  /// runs in the background, and kept if that one fails.
  final Duration ttl;

  /// How long a failed read is remembered before the CLI is asked again, so
  /// an open picker cannot respawn a broken CLI on every rebuild.
  final Duration retryAfter;

  static Future<String?> _noConfigDir() async => null;

  /// Vocabulary the CLI accepts but does not list as models.
  static const Map<String, String> _modes = {
    'opusplan': 'Opus in plan mode, else Sonnet',
    'best': 'Best available',
  };

  /// What the picker offers when the CLI cannot be read: the family aliases,
  /// which never go stale. Window and levels stay unknown rather than
  /// guessed.
  static const List<AcpModel> fallback = [
    AcpModel(id: 'opus', name: 'Opus (latest)'),
    AcpModel(id: 'sonnet', name: 'Sonnet (latest)'),
    AcpModel(id: 'haiku', name: 'Haiku (latest)'),
    AcpModel(id: 'fable', name: 'Fable (latest)'),
  ];

  _Snapshot? _snapshot;
  ({String key, Future<_Snapshot?> future})? _inflight;
  ({String key, DateTime at})? _failure;

  /// The models the picker offers, in the CLI's order.
  Future<List<AcpModel>> models() async {
    final snapshot = await _current();
    if (snapshot == null) {
      return fallback;
    }
    return snapshot.models;
  }

  /// The window, in tokens, Claude Code runs [modelId] with — what the meter
  /// measures against when the agent sets no context size of its own. Null
  /// [modelId] is the CLI's default model.
  ///
  /// An id the list does not carry (a dated snapshot, a `[1m]` variant, an id
  /// typed into the picker) is asked about on its own, once per snapshot.
  /// Null when the CLI cannot be read or does not accept the id.
  Future<int?> contextWindowOf(String? modelId) async {
    final snapshot = await _current();
    if (snapshot == null) {
      return null;
    }
    final id = modelId?.trim() ?? '';
    if (id.isEmpty || id == 'default') {
      return snapshot.result.defaultWindow;
    }
    final known = snapshot.windowOf(id);
    if (known != null) {
      return known.window;
    }
    final asked = snapshot.adhoc[id];
    if (asked != null) {
      return asked.window;
    }
    try {
      final result = await _probe.probe(
        binaryPath: snapshot.binaryPath,
        configDir: snapshot.configDir,
        listCatalog: false,
        extraIds: [id],
      );
      final window = result.extras[id]?.contextWindow;
      snapshot.adhoc[id] = (window: window);
      return window;
    } on Object {
      return null;
    }
  }

  /// Forgets the cached read (an account switch the caller knows about).
  void invalidate() {
    _snapshot = null;
    _failure = null;
  }

  Future<_Snapshot?> _current() async {
    final binary = await _resolveBinary('claude');
    if (binary == null) {
      return null;
    }
    final configDir = await _configDir();
    final key = '$binary|${_identityOf(binary)}|${configDir ?? ''}';
    final now = _now();
    final cached = _snapshot;
    if (cached != null && cached.key == key) {
      if (now.difference(cached.at) >= ttl &&
          _inflight?.key != key &&
          !_failedRecently(key, now)) {
        // Stale for this same binary and account: still the right answer
        // to show while the CLI is re-read (a full read takes seconds).
        final future = _read(key, binary, configDir);
        _inflight = (key: key, future: future);
        unawaited(
          future.whenComplete(() {
            if (identical(_inflight?.future, future)) {
              _inflight = null;
            }
          }),
        );
      }
      return cached;
    }
    if (_failedRecently(key, now)) {
      return null;
    }
    final inflight = _inflight;
    if (inflight != null && inflight.key == key) {
      return inflight.future;
    }
    final future = _read(key, binary, configDir);
    _inflight = (key: key, future: future);
    try {
      return await future;
    } finally {
      if (identical(_inflight?.future, future)) {
        _inflight = null;
      }
    }
  }

  bool _failedRecently(String key, DateTime now) {
    final failure = _failure;
    return failure != null &&
        failure.key == key &&
        now.difference(failure.at) < retryAfter;
  }

  Future<_Snapshot?> _read(String key, String binary, String? configDir) async {
    try {
      final result = await _probe.probe(
        binaryPath: binary,
        configDir: configDir,
        extraIds: _modes.keys.toList(),
      );
      if (result.models.isEmpty) {
        throw StateError('claude listed no models');
      }
      final snapshot = _Snapshot(
        key: key,
        at: _now(),
        binaryPath: binary,
        configDir: configDir,
        result: result,
        models: _toModels(result),
      );
      _snapshot = snapshot;
      _failure = null;
      return snapshot;
    } on Object {
      _failure = (key: key, at: _now());
      return null;
    }
  }

  static String _identityOf(String binaryPath) {
    try {
      final stat = FileStat.statSync(binaryPath);
      return '${stat.size}:${stat.modified.millisecondsSinceEpoch}';
    } on Object {
      return '';
    }
  }

  static List<AcpModel> _toModels(ClaudeCodeProbeResult result) {
    final out = <AcpModel>[];
    final seen = <String>{};
    void add(AcpModel model) {
      if (seen.add(model.id)) {
        out.add(model);
      }
    }

    // `default` is "no --model", which the agent form already expresses by
    // leaving the model empty; a disabled row cannot be run.
    final rows = result.models
        .where((m) => m.value != 'default' && !m.disabled)
        .toList();
    bool isAlias(ClaudeCodeProbedModel m) => !m.value.startsWith('claude-');

    // Aliases first: they are what people type and they never go stale.
    for (final row in rows.where(isAlias)) {
      add(_toModel(row, nameOf(row.value, row.displayName), row.effortLevels));
    }
    // Then the modes (opusplan, best) — after the aliases, before model ids.
    final modes = <AcpModel>[];
    for (final MapEntry(key: id, value: label) in _modes.entries) {
      final probed = result.extras[id];
      if (probed == null) {
        continue;
      }
      // A mode borrows the levels of the model it runs as.
      final runsAs = result.models
          .where(
            (m) =>
                m.resolvedModel != null &&
                m.resolvedModel == probed.resolvedModel,
          )
          .firstOrNull;
      modes.add(_toModel(probed, label, runsAs?.effortLevels));
    }
    modes.forEach(add);
    // The model id each alias currently runs, which the CLI lists only as the
    // alias (`opus`, never `claude-opus-5-5`) — so a pinned current model is
    // selectable, and a concrete id is what skill evaluation requires.
    for (final row in rows.where(isAlias)) {
      final id = row.resolvedModel;
      if (id == null || !id.startsWith('claude-')) {
        continue;
      }
      add(
        _toModel(
          ClaudeCodeProbedModel(value: id, contextWindow: row.contextWindow),
          nameOf(id, row.displayName),
          row.effortLevels,
        ),
      );
    }
    for (final row in rows.where((m) => !isAlias(m))) {
      add(_toModel(row, nameOf(row.value, row.displayName), row.effortLevels));
    }
    return out;
  }

  static AcpModel _toModel(
    ClaudeCodeProbedModel row,
    String name,
    List<String>? effort,
  ) {
    final levels = effort == null || effort.isEmpty
        ? null
        : [
            for (final id in effort)
              claudeThinkingLevels.where((l) => l.id == id).firstOrNull ??
                  ThinkingLevel(id: id, label: _capitalize(id)),
          ];
    return AcpModel(
      id: row.value,
      name: name,
      contextWindow: row.contextWindow,
      thinkingLevels: levels,
      defaultThinkingLevel: levels == null
          ? null
          : (levels.any((l) => l.id == 'medium') ? 'medium' : levels.first.id),
    );
  }

  static final RegExp _dated = RegExp(r'-(\d{4})(\d{2})(\d{2})$');
  static const String _longSuffix = '[1m]';

  /// The app's name for [value]: `Opus (latest)` for an alias, `Claude Opus
  /// 4.6` for a model id (from the CLI's [displayName] when it has one), plus
  /// `(1M context)` for a `[1m]` id and the date of a dated snapshot.
  static String nameOf(String value, [String? displayName]) {
    final long = value.endsWith(_longSuffix);
    final base = long
        ? value.substring(0, value.length - _longSuffix.length)
        : value;
    if (!base.startsWith('claude-')) {
      return '${_capitalize(base)} ${long ? '(1M context)' : '(latest)'}';
    }
    final date = _dated.firstMatch(base);
    final undated = date == null ? base : base.substring(0, date.start);
    var name = _stripQualifiers(displayName) ?? _nameFromId(undated);
    if (!name.startsWith('Claude ')) {
      name = 'Claude $name';
    }
    if (date != null) {
      name = '$name (${date[1]}-${date[2]}-${date[3]})';
    }
    if (long) {
      name = '$name (1M context)';
    }
    return name;
  }

  /// The CLI's label without a trailing parenthetical (`(1M context)`, a
  /// date), which [nameOf] adds back in the app's own wording.
  static String? _stripQualifiers(String? label) {
    if (label == null) {
      return null;
    }
    final stripped = label.replaceAll(RegExp(r'\s*\([^)]*\)\s*$'), '').trim();
    return stripped.isEmpty ? null : stripped;
  }

  /// `claude-opus-4-6` → `Claude Opus 4.6`; `claude-3-5-haiku` → `Claude
  /// Haiku 3.5`.
  static String _nameFromId(String id) {
    final parts = id.substring('claude-'.length).split('-');
    final words = [
      for (final p in parts)
        if (int.tryParse(p) == null) _capitalize(p),
    ];
    final version = [
      for (final p in parts)
        if (int.tryParse(p) != null) p,
    ].join('.');
    return ['Claude', ...words, if (version.isNotEmpty) version].join(' ');
  }

  static String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}

class _Snapshot {
  _Snapshot({
    required this.key,
    required this.at,
    required this.binaryPath,
    required this.configDir,
    required this.result,
    required this.models,
  });

  final String key;
  final DateTime at;
  final String binaryPath;
  final String? configDir;
  final ClaudeCodeProbeResult result;
  final List<AcpModel> models;

  /// Windows learned for ids outside the list, by id.
  final Map<String, ({int? window})> adhoc = {};

  /// The window of [id] when the read already covers it: a listed value, a
  /// probed mode, or the model id an alias row resolves to.
  ({int? window})? windowOf(String id) {
    for (final m in result.models) {
      if (m.value == id) {
        return (window: m.contextWindow);
      }
    }
    final extra = result.extras[id];
    if (extra != null) {
      return (window: extra.contextWindow);
    }
    for (final m in result.models) {
      if (m.resolvedModel == id && m.contextWindow != null) {
        return (window: m.contextWindow);
      }
    }
    return null;
  }
}
