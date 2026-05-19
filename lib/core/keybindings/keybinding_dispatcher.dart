import 'dart:async';

import 'package:control_center/core/constants/keybindings.dart';
import 'package:control_center/core/keybindings/key_stroke.dart';
import 'package:control_center/core/keybindings/when_clause.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:hotkey_manager/hotkey_manager.dart';

/// A live registration of one screen's (or the app's) command handlers.
///
/// Returned by `KeybindingDispatcher.registerScope`. Call [update] when the
/// available handlers change (e.g. a screen rebuilds with new state) and
/// [dispose] when the owner unmounts.
class KeybindingScopeHandle {
  KeybindingScopeHandle._(this._dispatcher, this._id);

  final KeybindingDispatcher _dispatcher;
  final int _id;
  bool _disposed = false;

  /// Replaces this scope's command handlers with [handlers].
  void update(Map<String, VoidCallback> handlers) {
    if (_disposed) {
      return;
    }
    _dispatcher._updateScope(_id, handlers);
  }

  /// Removes this scope's handlers from the dispatcher.
  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    _dispatcher._unregisterScope(_id);
  }
}

/// The single source of truth for in-app keyboard shortcuts.
///
/// Instead of relying on the focus tree (Flutter's `Shortcuts`/`Actions` and
/// autofocusing `Focus` nodes — which only honour the first autofocus node and
/// drop key events when focus drifts), every shortcut flows through one
/// `hotkey_manager` (`HotKeyScope.inapp`) handler that observes the hardware
/// keyboard regardless of widget focus.
///
/// `hotkey_manager` matches purely on key + modifiers and *consumes* any
/// registered combination, so it has no notion of a VS Code-style `when`
/// clause. We add that here: the dispatcher keeps the registered hotkey set in
/// sync with the *currently active* bindings — a binding is active when its
/// command has a registered handler **and** its `when` clause holds for the
/// current context. When a text field gains focus, every binding guarded by
/// `!textInputFocus` deactivates and its hotkey is unregistered, so the key
/// reaches the field instead of being swallowed.
///
/// When several active bindings share the same first stroke (e.g. `⌘1` is both
/// `nav.dashboard` and `settings.appearance`), the most specific scope wins —
/// reproducing VS Code's "more specific rule wins" semantics.
class KeybindingDispatcher {
  /// Creates a dispatcher over [bindings] (defaults to [KeybindingRegistry.all]).
  ///
  /// Set [registerWithOs] to `false` in tests to exercise the resolution and
  /// chord logic without touching the global `hotkey_manager` singleton; drive
  /// it via [debugDispatchStroke].
  KeybindingDispatcher({
    List<Keybinding>? bindings,
    TargetPlatform? platform,
    bool registerWithOs = true,
    bool observeFocus = true,
  })  : _bindings = bindings ?? KeybindingRegistry.all,
        _platform = platform ?? defaultTargetPlatform,
        _registerWithOs = registerWithOs,
        _observeFocus = observeFocus {
    if (_observeFocus) {
      FocusManager.instance.addListener(_onFocusChanged);
      _onFocusChanged();
    }
    _reconcile();
  }

  final List<Keybinding> _bindings;
  final TargetPlatform _platform;
  final bool _registerWithOs;
  final bool _observeFocus;

  /// The reactive evaluation context (`route`, `textInputFocus`, and any
  /// custom keys a screen contributes).
  final Map<String, Object?> _context = {};

  /// commandId → handler, flattened from every registered scope.
  final Map<String, VoidCallback> _handlers = {};
  final Map<int, Map<String, VoidCallback>> _scopes = {};
  int _nextScopeId = 0;

  /// Hotkeys currently registered with `hotkey_manager`, keyed by canonical.
  final Map<String, HotKey> _registered = {};

  /// Active bindings grouped by their first stroke's canonical, sorted by
  /// scope specificity (most specific first).
  Map<String, List<Keybinding>> _byFirstStroke = {};

  /// Canonical → the first [KeyStroke] for currently active bindings.
  final Map<String, KeyStroke> _strokeByCanonical = {};

  // Chord state machine ----------------------------------------------------
  KeyStroke? _pendingFirst;
  final Map<String, HotKey> _pendingContinuations = {};
  Timer? _chordTimer;

  /// How long to wait for the second stroke of a chord before giving up.
  static const Duration chordTimeout = Duration(milliseconds: 1500);

  bool _disposed = false;

  // ── Context ─────────────────────────────────────────────────────────────

  /// Sets a context key and reconciles. Passing `null` removes the key.
  void setContext(String key, Object? value) {
    if (_disposed) {
      return;
    }
    if (value == null) {
      if (!_context.containsKey(key)) {
        return;
      }
      _context.remove(key);
    } else {
      if (_context[key] == value && _context.containsKey(key)) {
        return;
      }
      _context[key] = value;
    }
    _reconcile();
  }

  /// The current route path, used by `route == '...'` guards.
  void setRoute(String location) => setContext('route', location);

  /// Read-only view of the evaluation context (for diagnostics / tests).
  Map<String, Object?> get debugContext => Map.unmodifiable(_context);

  void _onFocusChanged() {
    final primary = FocusManager.instance.primaryFocus;
    final ctx = primary?.context;
    final inEditable =
        ctx != null && ctx.findAncestorWidgetOfExactType<EditableText>() != null;
    // Recover from a known Flutter macOS bug where the engine misses a KeyUp
    // event (often after Cmd+V or window focus loss while a key is held),
    // leaving HardwareKeyboard._pressedKeys out of sync. When focus enters a
    // text field, stuck keys are synthesised as repeat events and appear as
    // ghost input. See https://github.com/flutter/flutter/issues/136419.
    if (inEditable) {
      // ignore: invalid_use_of_visible_for_testing_member
      HardwareKeyboard.instance.clearState();
    }
    setContext('textInputFocus', inEditable);
  }

  // ── Scope registration ──────────────────────────────────────────────────

  /// Registers a set of command handlers and returns a handle to update or
  /// remove them. Multiple scopes may be active at once; their handlers are
  /// merged (command ids are globally unique across the registry).
  KeybindingScopeHandle registerScope(Map<String, VoidCallback> handlers) {
    final id = _nextScopeId++;
    _scopes[id] = Map.of(handlers);
    _rebuildHandlers();
    return KeybindingScopeHandle._(this, id);
  }

  void _updateScope(int id, Map<String, VoidCallback> handlers) {
    if (!_scopes.containsKey(id)) {
      return;
    }
    _scopes[id] = Map.of(handlers);
    _rebuildHandlers();
  }

  void _unregisterScope(int id) {
    if (_scopes.remove(id) != null) {
      _rebuildHandlers();
    }
  }

  void _rebuildHandlers() {
    _handlers.clear();
    for (final scope in _scopes.values) {
      _handlers.addAll(scope);
    }
    _reconcile();
  }

  // ── Reconciliation ──────────────────────────────────────────────────────

  void _reconcile() {
    if (_disposed) {
      return;
    }

    final active = <Keybinding>[];
    for (final binding in _bindings) {
      if (!_handlers.containsKey(binding.id)) {
        continue;
      }
      if (!WhenClause.parse(binding.when).evaluate(_context)) {
        continue;
      }
      active.add(binding);
    }

    final byFirst = <String, List<Keybinding>>{};
    _strokeByCanonical.clear();
    for (final binding in active) {
      final stroke = binding.chord.first;
      final canon = stroke.canonical(_platform);
      (byFirst[canon] ??= <Keybinding>[]).add(binding);
      _strokeByCanonical[canon] = stroke;
    }
    for (final list in byFirst.values) {
      list.sort((a, b) => _priority(b).compareTo(_priority(a)));
    }
    _byFirstStroke = byFirst;

    final desired = byFirst.keys.toSet();
    // Unregister hotkeys that are no longer wanted.
    for (final canon in _registered.keys.toList()) {
      if (!desired.contains(canon)) {
        _unbind(_registered.remove(canon)!);
      }
    }
    // Register newly-active first strokes.
    for (final canon in desired) {
      if (!_registered.containsKey(canon)) {
        final stroke = _strokeByCanonical[canon]!;
        final hotKey = stroke.toHotKey(_platform);
        _registered[canon] = hotKey;
        _bind(hotKey, stroke);
      }
    }

    // A chord whose prefix is no longer active must be cancelled.
    if (_pendingFirst != null &&
        !desired.contains(_pendingFirst!.canonical(_platform))) {
      _cancelPending();
    }
  }

  /// Higher = more specific. Scoped bindings beat global ones; among scoped,
  /// a longer scope path (e.g. `/settings/agents`) beats a shorter one.
  int _priority(Keybinding b) =>
      (b.scope == KeybindingRegistry.globalScope ? 0 : 1000) + b.scope.length;

  // ── Stroke dispatch ─────────────────────────────────────────────────────

  void _onStrokeFired(KeyStroke stroke) {
    if (_disposed) {
      return;
    }
    _dispatchStroke(stroke);
  }

  /// The pure resolution logic, exposed for tests via [debugDispatchStroke].
  void _dispatchStroke(KeyStroke stroke) {
    final canon = stroke.canonical(_platform);

    // Mid-chord: try to complete the pending sequence.
    if (_pendingFirst != null) {
      final prefix = _pendingFirst!;
      final completions = (_byFirstStroke[prefix.canonical(_platform)] ?? const [])
          .where((b) =>
              b.chord.strokes.length == 2 && b.chord.strokes[1] == stroke)
          .toList();
      _cancelPending();
      if (completions.isNotEmpty) {
        _fire(completions.first); // already sorted by priority
        return;
      }
      // No completion — fall through and treat this stroke as a fresh start.
    }

    final candidates = _byFirstStroke[canon] ?? const <Keybinding>[];
    final singles = candidates.where((b) => b.chord.strokes.length == 1).toList();
    final prefixes = candidates.where((b) => b.chord.strokes.length > 1).toList();

    // A chord prefix shadows nothing only when there is no single-stroke
    // binding on the same key; otherwise the single binding fires immediately.
    if (prefixes.isNotEmpty && singles.isEmpty) {
      _beginPending(stroke, prefixes);
      return;
    }
    if (singles.isNotEmpty) {
      _fire(singles.first);
    }
  }

  void _fire(Keybinding binding) {
    _handlers[binding.id]?.call();
  }

  void _beginPending(KeyStroke prefix, List<Keybinding> prefixBindings) {
    _pendingFirst = prefix;
    final continuations = <String, KeyStroke>{};
    for (final b in prefixBindings) {
      final cont = b.chord.strokes[1];
      continuations[cont.canonical(_platform)] = cont;
    }
    for (final entry in continuations.entries) {
      // Only temp-register continuation strokes that aren't already live; the
      // already-registered ones route through their existing handler, which
      // also funnels into [_dispatchStroke] and completes the chord.
      if (!_registered.containsKey(entry.key)) {
        final hotKey = entry.value.toHotKey(_platform);
        _pendingContinuations[entry.key] = hotKey;
        _bind(hotKey, entry.value);
      }
    }
    _chordTimer?.cancel();
    _chordTimer = Timer(chordTimeout, _cancelPending);
  }

  void _cancelPending() {
    _chordTimer?.cancel();
    _chordTimer = null;
    for (final hotKey in _pendingContinuations.values) {
      _unbind(hotKey);
    }
    _pendingContinuations.clear();
    _pendingFirst = null;
  }

  // ── hotkey_manager binding ──────────────────────────────────────────────

  void _bind(HotKey hotKey, KeyStroke stroke) {
    if (!_registerWithOs) {
      return;
    }
    unawaited(
      hotKeyManager.register(
        hotKey,
        keyDownHandler: (_) => _onStrokeFired(stroke),
      ),
    );
  }

  void _unbind(HotKey hotKey) {
    if (!_registerWithOs) {
      return;
    }
    unawaited(hotKeyManager.unregister(hotKey));
  }

  // ── Lifecycle / testing ─────────────────────────────────────────────────

  /// Drives the resolver directly, bypassing `hotkey_manager`. Test-only.
  @visibleForTesting
  void debugDispatchStroke(KeyStroke stroke) => _dispatchStroke(stroke);

  /// The canonicals currently registered with `hotkey_manager`. Test-only.
  @visibleForTesting
  Set<String> get debugRegisteredCanonicals => _registered.keys.toSet();

  /// Whether a chord is mid-sequence. Test-only.
  @visibleForTesting
  bool get debugChordPending => _pendingFirst != null;

  /// Releases the focus listener and unregisters every hotkey.
  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    if (_observeFocus) {
      FocusManager.instance.removeListener(_onFocusChanged);
    }
    _cancelPending();
    for (final hotKey in _registered.values) {
      _unbind(hotKey);
    }
    _registered.clear();
  }
}
