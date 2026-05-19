import 'dart:async';

import 'package:control_center/core/constants/keybindings.dart';
import 'package:control_center/core/keybindings/key_stroke.dart';
import 'package:control_center/core/keybindings/stuck_keys.dart';
import 'package:control_center/core/keybindings/text_input_surface.dart';
import 'package:control_center/core/keybindings/when_clause.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

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
/// [HardwareKeyboard] handler that observes the hardware keyboard regardless
/// of widget focus — the same primitive on desktop and web, so both platforms
/// share one dispatch path and one set of quirk fixes.
///
/// The handler consumes a key when it matches a *currently active* binding —
/// a binding is active when its command has a registered handler **and** its
/// VS Code-style `when` clause holds for the current context. When a text
/// field gains focus, every binding guarded by `!textInputFocus` deactivates,
/// so the key reaches the field instead of being swallowed. Every other key
/// falls through untouched — typing, focus-tree shortcuts and (on web)
/// browser accelerators behave normally — except on macOS desktop, where an
/// unmatched key outside a text field is consumed without firing anything so
/// AppKit doesn't ring the system alert on every keypress (see
/// [_silenceUnmatchedKey]).
///
/// When several active bindings share the same first stroke (e.g. `⌘1` is both
/// `nav.inbox` and `settings.appearance`), the most specific scope wins —
/// reproducing VS Code's "more specific rule wins" semantics.
///
/// ## macOS reliability
///
/// The macOS engine frequently drops the KeyUp of a non-modifier key pressed
/// while ⌘ is held (flutter/flutter#136419), leaving the trigger logically
/// "pressed" so the next genuine press arrives misclassified as a
/// [KeyRepeatEvent]. The previous `hotkey_manager`-based dispatch silently
/// swallowed repeats, which made ⌘K/⌘F fire only every other press. This
/// handler instead treats a "repeat" of a command-modified stroke on macOS as
/// the fresh press it really is (macOS suppresses true auto-repeat while ⌘ is
/// held) and additionally clears stuck hardware-keyboard state whenever the
/// app window loses focus or a text field gains focus.
class KeybindingDispatcher with WidgetsBindingObserver {
  /// Creates a dispatcher over [bindings] (defaults to [KeybindingRegistry.all]).
  ///
  /// [_listenToHardwareKeyboard] (default `true`) attaches the
  /// [HardwareKeyboard] handler and the app-lifecycle observer. Set it to
  /// `false` in pure resolution tests (no bindings initialized) and drive the
  /// dispatcher via [debugDispatchStroke] instead.
  KeybindingDispatcher({
    List<Keybinding>? bindings,
    TargetPlatform? platform,
    this._observeFocus = true,
    this._listenToHardwareKeyboard = true,
  }) : _bindings = bindings ?? KeybindingRegistry.all,
       _platform = platform ?? defaultTargetPlatform {
    if (_observeFocus) {
      FocusManager.instance.addListener(_onFocusChanged);
      _onFocusChanged();
    }
    if (_listenToHardwareKeyboard) {
      HardwareKeyboard.instance.addHandler(_handleHardwareKey);
      WidgetsBinding.instance.addObserver(this);
    }
    _reconcile();
  }

  final List<Keybinding> _bindings;
  final TargetPlatform _platform;
  final bool _observeFocus;
  final bool _listenToHardwareKeyboard;

  /// The reactive evaluation context (`route`, `textInputFocus` and any
  /// custom keys a screen contributes).
  final Map<String, Object?> _context = {};

  /// commandId → handler, flattened from every registered scope.
  final Map<String, VoidCallback> _handlers = {};
  final Map<int, Map<String, VoidCallback>> _scopes = {};
  int _nextScopeId = 0;

  /// Active bindings grouped by their first stroke's canonical, sorted by
  /// scope specificity (most specific first).
  Map<String, List<Keybinding>> _byFirstStroke = {};

  /// Canonical → the first [KeyStroke] for currently active bindings.
  final Map<String, KeyStroke> _strokeByCanonical = {};

  // Chord state machine ----------------------------------------------------
  KeyStroke? _pendingFirst;

  /// Canonicals that complete the pending chord prefix.
  final Set<String> _pendingContinuations = {};
  Timer? _chordTimer;

  /// How long to wait for the second stroke of a chord before giving up.
  static const Duration chordTimeout = Duration(milliseconds: 1500);

  bool _disposed = false;

  /// True while a deferred focus re-evaluation is queued (see [_onFocusChanged]).
  bool _focusProbeScheduled = false;

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
    if (_disposed) {
      return;
    }
    // This runs eagerly from the constructor (which is itself created lazily
    // inside a widget's `initState`) and again on every focus change. When it
    // runs while a frame is being produced — during any build/layout phase, or
    // the warm-up frame that `runApp` schedules — the current `primaryFocus`
    // can still point at a just-deactivated element. Walking its ancestors then
    // trips Flutter's "Looking up a deactivated widget's ancestor is unsafe"
    // assertion, which (when thrown out of the lazy provider's create) poisons
    // `keybindingDispatcherProvider` and takes down the app.
    // A `BuildContext.mounted` check would NOT catch this: an inactive element
    // is still mounted (`_widget != null`). Defer to after the frame, when
    // focus has settled onto a live (or null) node and the element tree is
    // stable (scheduler idle), coalescing repeated in-frame notifications into
    // a single re-evaluation.
    if (SchedulerBinding.instance.schedulerPhase != SchedulerPhase.idle) {
      if (!_focusProbeScheduled) {
        _focusProbeScheduled = true;
        SchedulerBinding.instance.addPostFrameCallback((_) {
          _focusProbeScheduled = false;
          _onFocusChanged();
        });
      }
      return;
    }

    final primary = FocusManager.instance.primaryFocus;
    final ctx = primary?.context;
    final bool inEditable;
    if (ctx == null) {
      inEditable = false;
    } else {
      // Even off the frame phases above, a focus notification can arrive while
      // the focused element is deactivated (e.g. the warm-up frame flushes
      // FocusManager microtasks with the scheduler still reading `idle`).
      // Walking a deactivated element's ancestors throws Flutter's "Looking up
      // a deactivated widget's ancestor is unsafe" assertion. Probe defensively
      // and, if the tree is not yet stable, re-evaluate after the frame.
      //
      // A [TextInputSurface] counts the same as an [EditableText]: it marks a
      // custom TextInputClient surface (the xterm terminal) that types through
      // the IME but is not built on EditableText — without it, macOS's
      // unmatched-key silencer would consume every printable key before the
      // surface's input connection sees it.
      bool? probe;
      try {
        probe =
            ctx.findAncestorWidgetOfExactType<EditableText>() != null ||
            ctx.findAncestorWidgetOfExactType<TextInputSurface>() != null;
      } on Object {
        probe = null;
      }
      if (probe == null) {
        if (!_focusProbeScheduled) {
          _focusProbeScheduled = true;
          SchedulerBinding.instance.addPostFrameCallback((_) {
            _focusProbeScheduled = false;
            _onFocusChanged();
          });
        }
        return;
      }
      inEditable = probe;
    }
    // Recover from a known Flutter macOS bug where the engine misses a KeyUp
    // event (often after Cmd+V or window focus loss while a key is held),
    // leaving HardwareKeyboard._pressedKeys out of sync. When focus enters a
    // text field, stuck keys are synthesised as repeat events and appear as
    // ghost input. See https://github.com/flutter/flutter/issues/136419.
    //
    // Recovery MUST be [releaseStuckKeys] (synthesised key-ups), NEVER
    // `HardwareKeyboard.clearState()`: clearState() also detaches every
    // registered key handler — including this dispatcher's — so the first
    // focused text field permanently killed every shortcut in the app; each
    // later press fell through unhandled and rang the macOS system alert.
    if (inEditable) {
      releaseStuckKeys();
      // Capture the terminal-undo baseline (see [_bridgeTextUndoRedo]): the
      // text the focused field held when focus entered it. Recapture on every
      // focus entry — clicking back into a field re-anchors the floor — and
      // clear the floor latch with it.
      final editable = ctx!.findAncestorWidgetOfExactType<EditableText>();
      _undoBaselineNode = primary;
      _undoBaselineText = editable?.controller.text;
      _undoFloorLatched = false;
    } else {
      _undoBaselineNode = null;
      _undoBaselineText = null;
      _undoFloorLatched = false;
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
    final previous = _scopes[id];
    if (previous == null) {
      return;
    }
    // Which commands are AVAILABLE is all [_reconcile] reads — it tests
    // `_handlers.containsKey(binding.id)` and the when-clauses, never the
    // closures. A scope pushing the same command ids with fresh callbacks (the
    // normal case: callbacks are rebuilt every build, so a chat screen does
    // this per message) therefore cannot change the active-stroke index.
    //
    // Reconciling anyway meant walking all bindings, re-parsing/evaluating
    // every when-clause and re-sorting, per parent rebuild. The comment at the
    // `didUpdateWidget` call site already claimed this was skipped; now it is.
    final sameCommands =
        previous.length == handlers.length &&
        handlers.keys.every(previous.containsKey);
    _scopes[id] = Map.of(handlers);
    if (sameCommands) {
      _rebuildHandlerMap();
      return;
    }
    _rebuildHandlers();
  }

  /// Re-merges the scopes' handler maps WITHOUT recomputing the stroke index.
  void _rebuildHandlerMap() {
    _handlers.clear();
    for (final scope in _scopes.values) {
      _handlers.addAll(scope);
    }
  }

  void _unregisterScope(int id) {
    if (_scopes.remove(id) != null) {
      _rebuildHandlers();
    }
  }

  void _rebuildHandlers() {
    _rebuildHandlerMap();
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

    // A chord whose prefix is no longer active must be cancelled.
    if (_pendingFirst != null &&
        !byFirst.containsKey(_pendingFirst!.canonical(_platform))) {
      _cancelPending();
    }
  }

  /// Higher = more specific. Scoped bindings beat global ones; among scoped,
  /// a longer scope path (e.g. `/settings/agents`) beats a shorter one.
  int _priority(Keybinding b) =>
      (b.scope == KeybindingRegistry.globalScope ? 0 : 1000) + b.scope.length;

  // ── Stroke dispatch ─────────────────────────────────────────────────────

  /// The pure resolution logic, exposed for tests via [debugDispatchStroke].
  void _dispatchStroke(KeyStroke stroke) {
    final canon = stroke.canonical(_platform);

    // Mid-chord: try to complete the pending sequence.
    if (_pendingFirst != null) {
      final prefix = _pendingFirst!;
      final completions =
          (_byFirstStroke[prefix.canonical(_platform)] ?? const [])
              .where(
                (b) =>
                    b.chord.strokes.length == 2 && b.chord.strokes[1] == stroke,
              )
              .toList();
      _cancelPending();
      if (completions.isNotEmpty) {
        _fire(completions.first); // already sorted by priority
        return;
      }
      // No completion — fall through and treat this stroke as a fresh start.
    }

    final candidates = _byFirstStroke[canon] ?? const <Keybinding>[];
    final singles = candidates
        .where((b) => b.chord.strokes.length == 1)
        .toList();
    final prefixes = candidates
        .where((b) => b.chord.strokes.length > 1)
        .toList();

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
    for (final b in prefixBindings) {
      _pendingContinuations.add(b.chord.strokes[1].canonical(_platform));
    }
    _chordTimer?.cancel();
    _chordTimer = Timer(chordTimeout, _cancelPending);
  }

  void _cancelPending() {
    _chordTimer?.cancel();
    _chordTimer = null;
    _pendingContinuations.clear();
    _pendingFirst = null;
  }

  // ── HardwareKeyboard source ───────────────────────────────────────────────

  /// Logical keys that are themselves modifiers — a press of one alone never
  /// triggers a binding, so it is ignored as a trigger.
  static final Set<LogicalKeyboardKey> _modifierKeys = {
    LogicalKeyboardKey.metaLeft,
    LogicalKeyboardKey.metaRight,
    LogicalKeyboardKey.meta,
    LogicalKeyboardKey.controlLeft,
    LogicalKeyboardKey.controlRight,
    LogicalKeyboardKey.control,
    LogicalKeyboardKey.shiftLeft,
    LogicalKeyboardKey.shiftRight,
    LogicalKeyboardKey.shift,
    LogicalKeyboardKey.altLeft,
    LogicalKeyboardKey.altRight,
    LogicalKeyboardKey.alt,
  };

  /// Maps a printable key's *shift-produced* logical key back to its unshifted
  /// base key (US layout).
  ///
  /// macOS — and character-driven web/Linux layouts — derive a printable key's
  /// [KeyEvent.logicalKey] from the character it produces *with Shift applied*:
  /// pressing Shift+/ reports [LogicalKeyboardKey.question] (the `?` code point),
  /// never [LogicalKeyboardKey.slash]. Bindings are authored with the base key
  /// plus a `shift` flag (e.g. `?` == slash + shift), so without this fold the
  /// stroke never matches, the key falls through unhandled and macOS rings the
  /// system alert ("boop") for the un-consumed key. Each of these logical keys
  /// only ever arrives while Shift is held, so folding it unconditionally is
  /// safe (the `shift` flag stays in the canonical, so `/` and `?` remain
  /// distinct bindings).
  static final Map<LogicalKeyboardKey, LogicalKeyboardKey> _shiftedSymbolBase =
      {
        LogicalKeyboardKey.exclamation: LogicalKeyboardKey.digit1,
        LogicalKeyboardKey.at: LogicalKeyboardKey.digit2,
        LogicalKeyboardKey.numberSign: LogicalKeyboardKey.digit3,
        LogicalKeyboardKey.dollar: LogicalKeyboardKey.digit4,
        LogicalKeyboardKey.percent: LogicalKeyboardKey.digit5,
        LogicalKeyboardKey.caret: LogicalKeyboardKey.digit6,
        LogicalKeyboardKey.ampersand: LogicalKeyboardKey.digit7,
        LogicalKeyboardKey.asterisk: LogicalKeyboardKey.digit8,
        LogicalKeyboardKey.parenthesisLeft: LogicalKeyboardKey.digit9,
        LogicalKeyboardKey.parenthesisRight: LogicalKeyboardKey.digit0,
        LogicalKeyboardKey.underscore: LogicalKeyboardKey.minus,
        LogicalKeyboardKey.add: LogicalKeyboardKey.equal,
        LogicalKeyboardKey.braceLeft: LogicalKeyboardKey.bracketLeft,
        LogicalKeyboardKey.braceRight: LogicalKeyboardKey.bracketRight,
        LogicalKeyboardKey.bar: LogicalKeyboardKey.backslash,
        LogicalKeyboardKey.colon: LogicalKeyboardKey.semicolon,
        LogicalKeyboardKey.quote: LogicalKeyboardKey.quoteSingle,
        LogicalKeyboardKey.less: LogicalKeyboardKey.comma,
        LogicalKeyboardKey.greater: LogicalKeyboardKey.period,
        LogicalKeyboardKey.question: LogicalKeyboardKey.slash,
        LogicalKeyboardKey.tilde: LogicalKeyboardKey.backquote,
      };

  /// The [HardwareKeyboard] handler feeding the dispatcher on every platform.
  ///
  /// Returns `true` (consuming the event, which stops focus-tree shortcut
  /// dispatch and — on web — `preventDefault`s the browser key event) when the
  /// stroke matches a currently active first stroke or a live chord
  /// continuation. When a text field is focused the dispatcher has already
  /// deactivated `!textInputFocus` bindings, so their strokes are not in the
  /// active set and reach the field.
  ///
  /// Unmatched keys fall through untouched — so text input, the focus tree,
  /// and browser shortcuts behave normally — with one exception: on macOS
  /// desktop, an unmatched key outside a text field is consumed *without
  /// firing anything* (see [_silenceUnmatchedKey]), because a key-down the app
  /// reports unhandled makes AppKit ring the system alert ("boop") on every
  /// keypress.
  bool _handleHardwareKey(KeyEvent event) {
    if (_disposed || event is KeyUpEvent) {
      return false;
    }
    final stroke = _strokeFromEvent(event);
    if (stroke == null) {
      return false;
    }
    final canon = stroke.canonical(_platform);
    final matches =
        _byFirstStroke.containsKey(canon) ||
        _pendingContinuations.contains(canon);
    if (!matches) {
      // While a text field holds focus, the platform's undo/redo strokes are
      // bridged to that field's own undo history (see [_bridgeTextUndoRedo])
      // instead of falling through. The focus-tree `Shortcuts` layer that
      // `DefaultTextEditingShortcuts` uses to deliver them is exactly the
      // dispatch path this dispatcher exists to replace, and under the
      // experimental native-windowing runtime it never fires for keys pressed
      // while a text input connection is live — so without the bridge ⌘Z/⌘⇧Z
      // die in every field of the app.
      if (_bridgeTextUndoRedo(stroke)) {
        return true;
      }
      // Nothing fires, but decide whether the key may fall through: on macOS
      // an unhandled key-down rings the system alert. Consuming it here is
      // side-effect-free for everyone else — focus-tree Shortcuts and other
      // HardwareKeyboard handlers still receive the event (all handlers always
      // run; results are OR'd) — it only silences the noise.
      return _silenceUnmatchedKey(stroke);
    }
    // Normally fire only on the initial press and swallow OS auto-repeats. But
    // macOS drops the KeyUp for a non-modifier key while ⌘ is held (Flutter
    // issue #136419), so the trigger key stays logically "pressed" and the next
    // genuine ⌘-press arrives misclassified as a KeyRepeatEvent. macOS also
    // suppresses real auto-repeat while ⌘ is held, so a "repeat" of a
    // command-modified stroke is in fact a fresh press — dispatch it too, or a
    // shortcut like ⌘K only fires every other time (the classic "works
    // randomly" symptom). Bare-key strokes keep the down-only rule so a held
    // key never machine-guns its action.
    final isCommandModified = stroke.cmd || stroke.ctrl || stroke.alt;
    final isMacRepeatPress =
        event is KeyRepeatEvent &&
        _platform == TargetPlatform.macOS &&
        isCommandModified;
    if (event is KeyDownEvent || isMacRepeatPress) {
      // A stroke that matched an active binding is *always* reported handled
      // (return true) so the key is consumed. Guard the handler so a throwing
      // command can never let the exception escape this callback: an escaped
      // exception is caught by Flutter's key dispatch, which then reports the
      // event as unhandled — ringing the macOS system alert ("boop") for a key
      // the user did bind. Log the failure instead and still consume the key.
      try {
        _dispatchStroke(stroke);
      } catch (error, stack) {
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: error,
            stack: stack,
            library: 'keybindings',
            context: ErrorDescription('while running the handler for $canon'),
          ),
        );
      }
    }
    return true;
  }

  /// Reconstructs the [KeyStroke] for [event] from its trigger key and the
  /// modifiers currently held, resolving the primary command modifier the same
  /// way [KeyStroke] does (⌘ on macOS, Ctrl elsewhere). The trigger is folded
  /// through [_shiftedSymbolBase] so a shift-produced symbol (macOS reports
  /// Shift+/ as [LogicalKeyboardKey.question]) matches a binding authored with
  /// the base key + shift. Returns `null` for a bare modifier press.
  KeyStroke? _strokeFromEvent(KeyEvent event) {
    final key = event.logicalKey;
    if (_modifierKeys.contains(key)) {
      return null;
    }
    final keyboard = HardwareKeyboard.instance;
    final isMac = _platform == TargetPlatform.macOS;
    return KeyStroke(
      _shiftedSymbolBase[key] ?? key,
      cmd: isMac ? keyboard.isMetaPressed : keyboard.isControlPressed,
      ctrl: isMac && keyboard.isControlPressed,
      shift: keyboard.isShiftPressed,
      alt: keyboard.isAltPressed,
    );
  }

  /// While a text field holds focus, delivers the platform's undo/redo stroke
  /// to that field's own [UndoHistory] by invoking the exact intents
  /// `DefaultTextEditingShortcuts` would have dispatched for the same keys.
  ///
  /// The framework's own delivery of these strokes rides the focus tree:
  /// `DefaultTextEditingShortcuts` (installed by `WidgetsApp`) matches the key
  /// and invokes `UndoTextIntent`/`RedoTextIntent` against
  /// `primaryFocus.context`. Under the app's native-windowing runtime that
  /// focus-tree dispatch never fires for keystrokes made while a text input
  /// connection is live, which killed ⌘Z/⌘⇧Z in every input of the app
  /// (typing and IME still worked — they ride the text-input channel, not the
  /// key-event focus tree). Re-issuing the same `Actions.maybeInvoke` from the
  /// hardware-keyboard path — the one key pipeline this app trusts — restores
  /// the behaviour without reimplementing any undo logic: the stack,
  /// throttling and `canUndo` semantics all stay the framework's.
  ///
  /// Two hard-won details:
  ///
  /// - **Do not read `Actions.maybeInvoke`'s return value.** It returns the
  ///   *action's* result, and `UndoHistory`'s undo/redo actions return void —
  ///   so a successful undo is indistinguishable from "no action found" by
  ///   return value. Find the action first (`Actions.maybeFind`), invoke it,
  ///   and consume the hardware event whenever an action was found. Returning
  ///   `false` after a successful undo left the event "unhandled" for the
  ///   engine, which redispatched it into AppKit and rang the system alert
  ///   ("boop") on every working ⌘Z.
  ///
  /// - **Terminal undo restores the focus-entry baseline.** `UndoHistory`
  ///   records values on a 500ms throttled push whose pending argument is
  ///   OVERWRITTEN by each new value, so when typing starts within 500ms of
  ///   the previous push (a fresh composer: mount or the post-send `clear()`
  ///   arms the timer, the first keystrokes overwrite its argument), the empty
  ///   baseline is coalesced away and the stack's lowest entry is the first
  ///   typed snapshot — ⌘Z could never remove the first inputted word. When an
  ///   undo press reaches that floor without changing the value, the bridge
  ///   restores the text the field had when it gained focus (captured in
  ///   [_onFocusChanged]). The restore goes through the controller, so it
  ///   becomes a normal stack entry and ⇧⌘Z can redo back into the typed text.
  ///
  ///   The restore arms a fresh throttled push, and `undo()` reacts to an
  ///   active pending push by cancelling it and jumping to the stack's current
  ///   value — so a *subsequent* ⌘Z would bounce the text back to the stack
  ///   top, the next press would re-restore, and holding the key looped
  ///   forever. [_undoFloorLatched] breaks that cycle: once the restore has
  ///   fired, undo presses while the text still equals the baseline are
  ///   consumed as no-ops BEFORE the framework's `undo()` runs. Typing again
  ///   (text leaves the baseline) or redoing re-arms the terminal restore.
  bool _bridgeTextUndoRedo(KeyStroke stroke) {
    if (_context['textInputFocus'] != true) {
      return false; // `sys.undo` / `sys.redo` own the no-field case.
    }
    final isMac = _platform == TargetPlatform.macOS;
    // Mirror DefaultTextEditingShortcuts' own platform maps: ⌘Z / ⇧⌘Z on
    // Apple platforms, Ctrl+Z / Ctrl+Shift+Z (plus Ctrl+Y) elsewhere. `cmd` is
    // the primary command modifier, so ⌃Z on macOS (literal control) is
    // deliberately NOT bridged — macOS text editing gives it no undo meaning.
    final isUndo =
        stroke.cmd &&
        !stroke.shift &&
        stroke.trigger == LogicalKeyboardKey.keyZ;
    final isRedo =
        stroke.cmd &&
        ((stroke.shift && stroke.trigger == LogicalKeyboardKey.keyZ) ||
            (!isMac &&
                !stroke.shift &&
                stroke.trigger == LogicalKeyboardKey.keyY));
    if (!isUndo && !isRedo) {
      return false;
    }
    final node = FocusManager.instance.primaryFocus;
    final ctx = node?.context;
    if (ctx == null || !ctx.mounted) {
      return false;
    }
    final intent = isRedo
        ? const RedoTextIntent(SelectionChangedCause.keyboard)
        : const UndoTextIntent(SelectionChangedCause.keyboard);
    final action = Actions.maybeFind<Intent>(ctx, intent: intent);
    if (action == null || !action.isEnabled(intent)) {
      return false; // Not an UndoHistory-backed surface (e.g. the terminal).
    }
    final field = ctx.findAncestorWidgetOfExactType<EditableText>();
    final controller = field?.controller;
    final baseline = _undoBaselineText;
    final ownsBaseline =
        identical(node, _undoBaselineNode) &&
        baseline != null &&
        controller != null;
    final atBaseline = ownsBaseline && controller.text == baseline;
    if (isUndo && _undoFloorLatched && atBaseline) {
      // The floor was already restored on an earlier press; running the
      // framework's undo() again would cancel its pending baseline push and
      // bounce the text back to the stack top (the held-key loop).
      return true;
    }
    _undoFloorLatched = false;
    final before = controller?.value;
    Actions.maybeInvoke(ctx, intent);
    if (isUndo &&
        ownsBaseline &&
        controller.value == before &&
        controller.text != baseline) {
      // Floor reached: the stack had nothing older to restore. Fall through to
      // the focus-entry baseline so the first inputted word is removable.
      controller.value = TextEditingValue(
        text: baseline,
        selection: TextSelection.collapsed(offset: baseline.length),
      );
      _undoFloorLatched = true;
    }
    return true;
  }

  /// The focused [EditableText]'s text at the moment it gained focus — the
  /// terminal-undo baseline (see [_bridgeTextUndoRedo]).
  FocusNode? _undoBaselineNode;
  String? _undoBaselineText;

  /// Whether the terminal-undo baseline has already been restored for the
  /// current editing session (see [_bridgeTextUndoRedo]). Reset whenever focus
  /// re-enters a field or the text leaves the baseline.
  bool _undoFloorLatched = false;

  /// ⌘-equivalents the main menu (MainMenu.xib) handles when the app leaves
  /// them unhandled: Quit ⌘Q, Hide ⌘H / Hide Others ⌥⌘H, Minimize ⌘M.
  /// Consuming these would disable system window management. Every other menu
  /// equivalent either only acts on a focused text field (the Edit/Find items
  /// target first-responder text actions and are disabled otherwise — pressing
  /// them outside a field beeps today) or is bound in-app and never reaches
  /// the silencer.
  static final Set<LogicalKeyboardKey> _macSystemEquivalentTriggers = {
    LogicalKeyboardKey.keyQ,
    LogicalKeyboardKey.keyH,
    LogicalKeyboardKey.keyM,
  };

  /// Whether an *unmatched* [stroke] should be consumed purely to keep macOS
  /// quiet ("do nothing" instead of the system alert).
  ///
  /// AppKit rings the alert (`NSBeep` via `NSWindow.noResponderFor:`) for any
  /// key-down that falls off the responder chain — which, in a Flutter app, is
  /// every key the framework reports unhandled. Outside a text field that
  /// means every ordinary keypress boops. Consuming the event suppresses the
  /// redispatch and therefore the noise; it does NOT hide the event from
  /// focus-tree `Shortcuts` or other [HardwareKeyboard] handlers, which run
  /// regardless of this handler's result.
  ///
  /// Never consumes:
  /// - off macOS desktop — other platforms don't beep and on web `true`
  ///   would `preventDefault` genuine browser shortcuts;
  /// - while a text field is focused — the native text-input plugin (typing,
  ///   IME, press-and-hold accents) only receives events the framework leaves
  ///   unhandled;
  /// - the system menu equivalents in [_macSystemEquivalentTriggers] and
  ///   ⌃⌘F (Enter Full Screen) — the menu bar acts on those after redispatch.
  bool _silenceUnmatchedKey(KeyStroke stroke) {
    if (kIsWeb || _platform != TargetPlatform.macOS) {
      return false;
    }
    if (_context['textInputFocus'] == true) {
      return false;
    }
    if (stroke.cmd) {
      if (_macSystemEquivalentTriggers.contains(stroke.trigger)) {
        return false;
      }
      if (stroke.ctrl && stroke.trigger == LogicalKeyboardKey.keyF) {
        return false; // ⌃⌘F — Enter Full Screen.
      }
    }
    return true;
  }

  // ── Lifecycle / testing ─────────────────────────────────────────────────

  /// When the app window loses focus (⌘Tab, another window, screen lock), any
  /// key held at that moment never gets its KeyUp delivered to Flutter, so
  /// [HardwareKeyboard] believes it is still pressed. Stale modifiers then
  /// corrupt every subsequent stroke ("j" reads as "⌘J") until the key is
  /// physically pressed again. Release the framework's pressed-key state on
  /// the way out via [releaseStuckKeys] — synthesised key-ups, NEVER
  /// `HardwareKeyboard.clearState()`, which also detaches every registered key
  /// handler and killed all shortcuts on the first ⌘Tab — modifiers resync
  /// from the OS flags of the next real event — and abandon any half-entered
  /// chord.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_disposed || state == AppLifecycleState.resumed) {
      return;
    }
    releaseStuckKeys();
    _cancelPending();
  }

  /// Drives the resolver directly, bypassing the hardware keyboard. Test-only.
  @visibleForTesting
  void debugDispatchStroke(KeyStroke stroke) => _dispatchStroke(stroke);

  /// The first-stroke canonicals of currently active bindings. Test-only.
  @visibleForTesting
  Set<String> get debugRegisteredCanonicals => _byFirstStroke.keys.toSet();

  /// Whether a chord is mid-sequence. Test-only.
  @visibleForTesting
  bool get debugChordPending => _pendingFirst != null;

  /// Releases the focus listener and the hardware-keyboard handler.
  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    if (_observeFocus) {
      FocusManager.instance.removeListener(_onFocusChanged);
    }
    if (_listenToHardwareKeyboard) {
      HardwareKeyboard.instance.removeHandler(_handleHardwareKey);
      WidgetsBinding.instance.removeObserver(this);
    }
    _cancelPending();
  }
}
