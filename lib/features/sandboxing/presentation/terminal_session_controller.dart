// Terminal session state, lifted out of the widget tree.
//
// A [TerminalSessionController] owns everything that must survive a view
// unmount: the xterm [Terminal] (10k-line buffer), the server-side PTY session
// id, the output/title subscriptions and the boot/restart lifecycle. Views
// (`TerminalSessionView`) are disposable — unmounting one (e.g. on a space
// switch in the messaging IDE) leaves the controller, the PTY and the
// scrollback fully intact; a fresh view reattaches later. The companion
// `terminalRegistryProvider` owns the app-level keep-alive registry and the
// LRU cap; this class knows nothing about it.
library;

import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:cc_data/cc_data.dart' show RemoteTerminalRepository;
import 'package:cc_domain/cc_domain.dart' show RpcErrorCodes;
import 'package:cc_rpc/cc_rpc.dart' show RemoteRpcClient, RemoteRpcException;
import 'package:control_center/features/sandboxing/presentation/terminal_panel.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:xterm/xterm.dart';

/// The three localized lines this controller writes INTO the terminal buffer.
///
/// The controller has no `BuildContext` — it outlives the view, which is the
/// whole point of the keep-alive registry — so the strings are injected by
/// whichever view is currently attached rather than resolved here. The
/// defaults are English so a controller that never had a view still says
/// something intelligible.
typedef TerminalNotices = ({
  String reconnecting,
  String streamError,
  String shellExited,
});

/// The fallback notices, used until a view supplies localized ones.
const TerminalNotices kDefaultTerminalNotices = (
  reconnecting: 'stream interrupted — reconnecting…',
  streamError: 'stream error:',
  shellExited: 'shell exited',
);

/// Owns one xterm [Terminal] + one server-side PTY session for the lifetime
/// of a terminal session, independent of any mounted view.
///
/// Hidden-tab policy: keep fed. While the view sits in a hidden
/// IndexedStack tab it deliberately keeps its `terminal.output` subscription
/// alive — the server does no replay, so dropping the stream would lose
/// output; the xterm buffer is bounded (10k lines), so staying fed is cheap.
/// The only thing gated while hidden is the `terminal.resize` round trip:
/// layout passes on hidden tabs would otherwise emit spurious resize RPCs.
/// The latest geometry is remembered and synced once on reveal (see
/// [updateVisibility]).
class TerminalSessionController extends ChangeNotifier {
  /// Creates a controller for [session]. Does NOT boot: the owner calls
  /// [ensureBooted] when it wants the shell running (post-frame for views).
  TerminalSessionController({required this.session, required this._rpcClient}) {
    terminal.onTitleChange = _onOscTitle;
    terminal.onOutput = (data) {
      final repo = _repo;
      final id = _sessionId;
      if (repo == null || id == null) {
        return;
      }
      // Forward keystrokes to the server PTY (base64-framed in the repository).
      unawaited(repo.write(id, utf8.encode(data)));
    };
    terminal.onResize = (cols, rows, _, _) {
      _cols = cols;
      _rows = rows;
      if (_hiddenInTab) {
        // Hidden IndexedStack layout passes must not emit spurious
        // terminal.resize round trips; sync once on reveal instead.
        _resizePending = true;
        return;
      }
      final repo = _repo;
      final id = _sessionId;
      if (repo != null && id != null) {
        unawaited(repo.resize(id, rows, cols));
      }
    };
  }

  /// Localized buffer notices, set by the attached view (see
  /// [TerminalNotices]).
  TerminalNotices notices = kDefaultTerminalNotices;

  /// Space + mount metadata.
  final TerminalSession session;

  /// The xterm terminal (buffer, cursor, title). Outlives every view.
  final Terminal terminal = Terminal(maxLines: 10000);

  final RemoteRpcClient _rpcClient;

  RemoteTerminalRepository? _repo;
  String? _sessionId;
  StreamSubscription<String>? _outputSub;
  final Queue<Object> _pendingOutput = Queue<Object>();
  int _pendingCharacters = 0;
  int _outputOffset = 0;
  Timer? _drainTimer;
  Timer? _reattachTimer;
  int _outputGeneration = 0;

  // One xterm.write (and thus one synchronous xterm listener notification)
  // per event-loop turn. A single decoded RPC emission can exceed the budget,
  // so split it at the drain boundary rather than monopolizing the UI isolate.
  static const _drainCharacters = 16 * 1024;
  // A decoded emission can exceed this high-water mark by one RPC chunk.
  // Pausing bounds this controller's decoded queue; the shared RPC fan-out
  // does not propagate pause to its network source, so it can buffer upstream.
  static const _pauseCharacters = 64 * 1024;

  void _queueOutput(Object item) {
    _pendingOutput.add(item);
    if (item is String) {
      _pendingCharacters += item.length;
      if (_pendingCharacters >= _pauseCharacters &&
          _outputSub?.isPaused == false) {
        _outputSub?.pause();
      }
    }
    _drainTimer ??= Timer(Duration.zero, _drainOutput);
  }

  void _drainOutput() {
    _drainTimer = null;
    String? single;
    StringBuffer? combined;
    var remaining = _drainCharacters;
    while (_pendingOutput.isNotEmpty && remaining > 0) {
      final first = _pendingOutput.first;
      if (first is! String) {
        // Write preceding bytes before displaying an error/exit notice.
        if (single != null) {
          break;
        }
        _pendingOutput.removeFirst();
        (first as void Function())();
        break;
      }
      var count = (first.length - _outputOffset).clamp(0, remaining);
      // xterm parses each write as a separate Dart string: never cut a UTF-16
      // surrogate pair when a non-BMP code point lands on the drain boundary.
      if (_outputOffset + count < first.length &&
          (first.codeUnitAt(_outputOffset + count - 1) & 0xfc00) == 0xd800 &&
          (first.codeUnitAt(_outputOffset + count) & 0xfc00) == 0xdc00) {
        count--;
      }
      if (count == 0) {
        break;
      }
      final part = count == first.length && _outputOffset == 0
          ? first
          : first.substring(_outputOffset, _outputOffset + count);
      if (single == null) {
        single = part;
      } else {
        (combined ??= StringBuffer(single)).write(part);
      }
      _outputOffset += count;
      _pendingCharacters -= count;
      remaining -= count;
      if (_outputOffset == first.length) {
        _pendingOutput.removeFirst();
        _outputOffset = 0;
      }
    }
    if (single != null) {
      terminal.write(combined?.toString() ?? single);
    }
    if (_pendingCharacters < _pauseCharacters && _outputSub?.isPaused == true) {
      _outputSub?.resume();
    }
    if (_pendingOutput.isNotEmpty) {
      _drainTimer ??= Timer(Duration.zero, _drainOutput);
    }
  }

  Future<void>? _stopOutput() {
    _outputGeneration++;
    _drainTimer?.cancel();
    _drainTimer = null;
    _reattachTimer?.cancel();
    _reattachTimer = null;
    _pendingOutput.clear();
    _pendingCharacters = 0;
    _outputOffset = 0;
    final previous = _outputSub;
    _outputSub = null;
    return previous?.cancel();
  }

  StreamSubscription<String>? _titleSub;

  /// Latest OSC 0/2 title the shell/program emitted ('' = none).
  String _oscTitle = '';

  /// Latest server-reported foreground-process title ('' = shell at prompt).
  String _processTitle = '';

  /// Last title reported to [onTitleChange], to dedupe.
  String _reportedTitle = '';

  bool _booting = false;
  String? _error;

  /// True when the connected server hosts no terminal ops — the view then
  /// renders the honest "runs on the server host" message instead of an error.
  bool _unavailable = false;

  String? _backend;

  int _rows = 40;
  int _cols = 100;

  /// Whether the view currently sits in a hidden IDE tab (mirrored from
  /// [TickerMode]/[Visibility] via [updateVisibility]). While hidden, resize
  /// RPCs are suppressed — see the class docs for the keep-fed policy.
  bool _hiddenInTab = false;

  /// Whether a resize arrived while hidden; the latest geometry is pushed to
  /// the server once on reveal.
  bool _resizePending = false;

  /// Set when the server reported the session id as unknown (`notFound`) — the
  /// PTY died with a server restart, not with a user `exit`. Suppresses the
  /// shell-exit callback (which closes the tab) while a fresh shell is spawned
  /// in its place.
  bool _sessionLost = false;

  bool _disposed = false;

  /// Whether a boot (spawn + attach) is currently in flight.
  bool get booting => _booting;

  /// The last boot's error message, if any.
  String? get error => _error;

  /// Whether the connected server hosts no terminal ops.
  bool get unavailable => _unavailable;

  /// The `SandboxBackend` name this shell ACTUALLY runs under, or null when
  /// the server did not say (a build predating the field).
  ///
  /// Reported by the server rather than inferred from what was requested: a
  /// default backend can step down, and a terminal that claims to be an
  /// enclosed VM while running on the host is the one label this feature
  /// cannot get wrong.
  String? get backend => _backend;

  /// The server-side PTY session id, once the shell has booted.
  ///
  /// Distinct from [TerminalSession.sessionId], which is the client tab id.
  /// Host-shell ports are keyed on this.
  String? get ptySessionId => _sessionId;

  /// The last reported effective title ('' = none).
  String get title => _reportedTitle;

  /// Whether a command currently holds the PTY's foreground — a build, a dev
  /// server, an editor — as opposed to a shell sitting at its prompt.
  ///
  /// Read from the server-polled foreground process rather than the effective
  /// title, which a shell can set at the prompt: "the tab is called something"
  /// and "something is running in it" are different claims, and only the second
  /// is worth stopping someone to ask about before closing the tab.
  bool get isRunningCommand => _processTitle.isNotEmpty;

  /// Called when the terminal's effective title changes. Two sources feed it,
  /// ghostty-style: OSC 0/2 escapes the shell (or the running program) emits,
  /// and the server-polled *foreground process* of the PTY — so a plain
  /// `pnpm dev serve` retitles the tab even when nothing emits OSC. A title
  /// the program sets during a run (vim, claude) wins over the process name;
  /// a prompt-time title is dropped once a new command takes the foreground.
  /// Fired with an empty string when the shell is restarted, so the host can
  /// fall back to its default label until the fresh shell titles itself.
  ValueChanged<String>? onTitleChange;

  /// Called when the server-side shell session ends.
  VoidCallback? onShellExit;

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  /// Spawns the server-side shell and attaches its streams. Idempotent: a
  /// no-op while a boot is in flight or a session is already attached.
  Future<void> ensureBooted() async {
    if (_booting || _sessionId != null) {
      return;
    }
    _booting = true;
    _error = null;
    _unavailable = false;
    _notify();
    try {
      final repo = RemoteTerminalRepository(_rpcClient);
      // Pass the conversation id so the server opens the terminal at the
      // conversation root, not a per-tab folder named after this session id.
      final spawned = await repo.spawnSession(
        rows: _rows,
        cols: _cols,
        spaceId: session.spaceId,
        backend: session.backend,
      );
      final sessionId = spawned.sessionId;
      if (_disposed) {
        unawaited(repo.kill(sessionId));
        return;
      }
      _repo = repo;
      _sessionId = sessionId;
      _backend = spawned.backend;
      _attach(repo, sessionId);
    } on RemoteRpcException catch (e) {
      // The connected server doesn't host the terminal ops — degrade honestly.
      if (e.code == RpcErrorCodes.opUnknown) {
        if (!_disposed) {
          _unavailable = true;
        }
      } else if (!_disposed) {
        _error = e.message;
      }
    } catch (e) {
      if (!_disposed) {
        _error = '$e';
      }
    } finally {
      if (!_disposed) {
        _booting = false;
        _notify();
      }
    }
  }

  /// Hardware character input for macOS desktop, hooked into
  /// [TerminalView.onKeyEvent] (which runs before the keytab and is skipped
  /// while an IME composition is active).
  ///
  /// On macOS the terminal's IME path is unreliable: xterm's `CustomTextEdit`
  /// is a bare [TextInputClient] and the engine-side `NSTextInputContext`
  /// intermittently declines its key events — printable keys then insert
  /// nothing and fall off the responder chain (the system alert "boop").
  /// Feeding plain printable characters straight from the key event and
  /// reporting them handled makes typing independent of the native IME state
  /// and stops the fall-through. Command/control/alt strokes and control
  /// characters (enter, tab, backspace, escape) stay ignored here so the
  /// keytab, xterm's copy/paste shortcuts and app keybindings keep handling
  /// them. Known tradeoff: IME composition (CJK, dead keys) doesn't reach the
  /// PTY on macOS — it didn't through the broken IME path either.
  KeyEventResult onKeyEvent(FocusNode node, KeyEvent event) {
    if (kIsWeb ||
        defaultTargetPlatform != TargetPlatform.macOS ||
        event is KeyUpEvent) {
      return KeyEventResult.ignored;
    }
    final keyboard = HardwareKeyboard.instance;
    if (keyboard.isMetaPressed ||
        keyboard.isControlPressed ||
        keyboard.isAltPressed) {
      return KeyEventResult.ignored;
    }
    final character = event.character;
    if (character == null || character.isEmpty) {
      return KeyEventResult.ignored;
    }
    if (character.codeUnits.every((u) => u < 0x20 || u == 0x7f)) {
      return KeyEventResult.ignored;
    }
    terminal.textInput(character);
    return KeyEventResult.handled;
  }

  /// Mirrors the view's IndexedStack-tab visibility. While hidden,
  /// terminal.resize RPCs are suppressed (layout passes still fire onResize)
  /// and the latest geometry is flushed once on reveal.
  ///
  /// Build-safe: mutates fields only, never notifies (mirrors the in-build
  /// field mutation this replaces).
  void updateVisibility(bool visible) {
    if (visible && _hiddenInTab && _resizePending) {
      _resizePending = false;
      final repo = _repo;
      final id = _sessionId;
      if (repo != null && id != null) {
        unawaited(repo.resize(id, _rows, _cols));
      }
    }
    _hiddenInTab = !visible;
  }

  /// The shell (or the running program) retitled the terminal via OSC 0/2.
  void _onOscTitle(String title) {
    _oscTitle = title.trim();
    _reportTitle();
  }

  /// The server reported a foreground change on the PTY: [title] is the
  /// command now running, or '' when the shell is back at its prompt.
  void _onProcessTitle(String title) {
    final next = title.trim();
    if (next == _processTitle) {
      return;
    }
    _processTitle = next;
    if (next.isNotEmpty) {
      // A new command took the foreground: any OSC title on record predates
      // it (a prompt-time title), so drop it — this is exactly the stale
      // state the process poll exists to fix. The command's own OSC (vim,
      // claude) arrives after this event and wins again.
      _oscTitle = '';
    }
    // On '' (back at the prompt) the OSC title is kept: shells that title at
    // the prompt already re-emitted it and terminals conventionally keep the
    // last program-set title otherwise.
    _reportTitle();
  }

  /// Reports the effective title — the freshest OSC one, else the foreground
  /// process — deduped, to the host tab.
  void _reportTitle() {
    final effective = _oscTitle.isNotEmpty ? _oscTitle : _processTitle;
    if (effective == _reportedTitle) {
      return;
    }
    _reportedTitle = effective;
    onTitleChange?.call(effective);
  }

  /// Transient stream-attach failures burned so far (reset on live bytes).
  int _attachRetries = 0;

  /// True while a re-attach is scheduled, so the dying stream's `onDone`
  /// does not read as "the shell exited" and close the tab mid-retry.
  bool _reattaching = false;

  void _attach(RemoteTerminalRepository repo, String sessionId) {
    _reattaching = false;
    unawaited(_stopOutput());
    final generation = _outputGeneration;
    _titleSub?.cancel();
    // Foreground-process titles ride a separate lane from the byte stream. A
    // server that predates `terminal.titles` errors the stream — swallowed:
    // the panel then simply keeps the OSC-only behaviour.
    _titleSub = repo
        .titles(sessionId)
        .listen(_onProcessTitle, onError: (Object _) {});
    // One decoder per stream preserves split UTF-8 code points and replaces
    // an incomplete tail on completion without carrying it into a reconnect.
    var lostSession = false;
    _outputSub = repo
        .output(sessionId)
        .map((bytes) {
          if (!_disposed && generation == _outputGeneration) {
            _attachRetries = 0;
          }
          return bytes;
        })
        .transform(const Utf8Decoder(allowMalformed: true))
        .listen(
          (text) {
            if (_disposed || generation != _outputGeneration) {
              return;
            }
            if (text.isNotEmpty) {
              _queueOutput(text);
            }
          },
          onError: (Object e) {
            if (_disposed || generation != _outputGeneration) {
              return;
            }
            // The RPC client closes a notFound subscription after its error.
            // Wait for decoder completion so a truncated final code point is
            // delivered before the notice and before the fresh shell starts.
            if (e is RemoteRpcException && e.code == RpcErrorCodes.notFound) {
              lostSession = true;
              return;
            }
            _queueOutput(() {
              if (_disposed || generation != _outputGeneration) {
                return;
              }
              // A TIMEOUT establishing the stream is transient — typically the
              // reconnect window after a server restart, when every pending
              // sub/subscribe expires at once. The session may be perfectly
              // alive; re-attach rather than dead-ending the tab on a race.
              if (e is TimeoutException && _attachRetries < 3) {
                _attachRetries++;
                _reattaching = true;
                terminal.write('\r\n[${notices.reconnecting}]\r\n');
                final id = _sessionId;
                final currentRepo = _repo;
                _reattachTimer = Timer(const Duration(seconds: 3), () {
                  _reattachTimer = null;
                  // Complete decoded output from the old subscription before
                  // replacing its decoder, even if a large burst is draining.
                  _queueOutput(() {
                    if (!_disposed &&
                        generation == _outputGeneration &&
                        currentRepo != null &&
                        id == _sessionId) {
                      _attach(currentRepo, id!);
                    }
                  });
                });
                return;
              }
              terminal.write('\r\n[${notices.streamError} $e]\r\n');
            });
          },
          onDone: () {
            if (_disposed || generation != _outputGeneration) {
              return;
            }
            _queueOutput(() {
              if (_disposed || generation != _outputGeneration) {
                return;
              }
              if (lostSession) {
                _sessionLost = true;
                terminal.write(
                  '\r\n[session ended with the server — starting a fresh shell]\r\n',
                );
                unawaited(_respawn());
                return;
              }
              if (_sessionLost || _reattaching) {
                // A scheduled re-attach means this stream died of a transient
                // failure; reporting shell exit would close a live tab.
                return;
              }
              terminal.write('\r\n[${notices.shellExited}]\r\n');
              onShellExit?.call();
            });
          },
        );
  }

  /// Replaces a server-side session that no longer exists with a fresh one,
  /// keeping this tab (and its scrollback) alive. Unlike [restart] it does not
  /// kill or clear anything: there is nothing left to kill and the buffer is
  /// the user's history.
  Future<void> _respawn() async {
    // Never await cancellation inside output delivery: it can depend on the
    // callback completing. The old subscription has already ended, so
    // cancelling asynchronously does not interrupt live output.
    unawaited(_stopOutput());
    unawaited(_titleSub?.cancel());
    _titleSub = null;
    _repo = null;
    _sessionId = null;
    if (_disposed) {
      return;
    }
    // The dead shell's title dies with it; the fresh one sets its own.
    _oscTitle = '';
    _processTitle = '';
    _reportedTitle = '';
    onTitleChange?.call('');
    await ensureBooted();
    _sessionLost = false;
  }

  /// Kills the server session, clears the buffer + cursor + titles and boots
  /// a fresh shell — the old header button's "Restart shell".
  Future<void> restart() async {
    await _stopOutput();
    await _titleSub?.cancel();
    _titleSub = null;
    final repo = _repo;
    final id = _sessionId;
    _repo = null;
    _sessionId = null;
    if (repo != null && id != null) {
      try {
        await repo.kill(id);
      } catch (_) {
        // Session may already be gone; disposal is best-effort.
      }
    }
    if (_disposed) {
      return;
    }
    terminal.buffer.clear();
    terminal.buffer.setCursor(0, 0);
    // The old shell's title dies with it; the fresh one will set its own.
    _oscTitle = '';
    _processTitle = '';
    _reportedTitle = '';
    onTitleChange?.call('');
    await ensureBooted();
  }

  @override
  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    _disposed = true;
    await _stopOutput();
    await _titleSub?.cancel();
    _titleSub = null;
    final repo = _repo;
    final id = _sessionId;
    _repo = null;
    _sessionId = null;
    if (repo != null && id != null) {
      try {
        // Best-effort: tell the server to tear the PTY down.
        await repo.kill(id);
      } catch (_) {
        // Session may already be gone; disposal is best-effort.
      }
    }
    super.dispose();
  }
}
