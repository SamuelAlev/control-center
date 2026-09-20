import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cc_domain/features/rigs/domain/value_objects/browser_action.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/browser_permission.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/browser_url.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_action.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_action_result.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_browser_engine.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_browser_state.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_clipboard.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_display.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_file_transfer.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';
import 'package:cc_infra/src/rigs/browser_engine_client.dart';
import 'package:cc_infra/src/rigs/browser_permission_host.dart';
import 'package:cc_infra/src/rigs/browser_permission_probe.dart';
import 'package:cc_infra/src/rigs/rig_drivers.dart';
import 'package:cc_infra/src/rigs/rig_file_transfer.dart';

/// Opens one encoded browser-audio stream from the guest.
typedef BrowserAudioStreamOpener = Future<Stream<List<int>>?> Function();

/// Forwards one browser microphone session message into the guest.
typedef BrowserAudioInputSender =
    Future<bool> Function(
      Uint8List bytes, {
      required String sessionId,
      required int sampleRate,
      required int channels,
      bool start,
      bool end,
    });

/// Releases the browser guest's microphone forwarding process.
typedef BrowserAudioInputCloser = Future<void> Function();

/// Drives the browser surface over CDP.
class BrowserRigDriver implements RigDriver {
  /// Creates a [BrowserRigDriver].
  BrowserRigDriver({
    required this.client,
    required this._viewport,
    this.onUrlChanged,
    this.audioStreamOpener,
    this.audioInputSender,
    this.audioInputCloser,
  }) {
    _bindNavigationTracking();
    _bindPermissions();
  }

  /// The connection to whichever browser this rig booted.
  ///
  /// Deliberately the engine-neutral type. The driver translates DOMAIN verbs
  /// into engine calls and nothing here is Chromium-shaped any more — three
  /// browsers answer the same twenty questions, and holding a `CdpClient`
  /// meant "a browser rig" and "Chromium" could never be told apart.
  final BrowserEngineClient client;

  /// Which browser is on the other end. Reaches the UI as a badge and the
  /// agent as part of every screenshot's text.
  RigBrowserEngine get engine => client.engine;

  /// Called each time the main frame's URL changes, however it changed — an
  /// action's navigate, a person's click on a link, a script's pushState. The
  /// service persists it onto the rig row, so watchers (the address bar) see
  /// navigations as they happen without polling.
  final void Function(String url)? onUrlChanged;

  /// Opens the browser guest's PulseAudio monitor stream.
  final BrowserAudioStreamOpener? audioStreamOpener;

  /// Forwards host microphone PCM into the browser guest's default source.
  final BrowserAudioInputSender? audioInputSender;

  /// Closes the guest microphone lane when this driver is disposed.
  final BrowserAudioInputCloser? audioInputCloser;

  RigDisplaySize _viewport;

  /// The last viewport position this driver sent the pointer to. CDP input
  /// events all carry absolute coordinates, so a bare button release needs to
  /// know where "here" is.
  (int, int)? _lastPointer;

  /// Whether the primary button is currently held (mid-drag). Moves must
  /// report it: Chromium extends a selection under a moving pointer ONLY when
  /// the move's button bitmask says the button is still down.
  bool _leftHeld = false;

  /// Press bookkeeping for click-count derivation — see [_pressPrimary].
  (DateTime, int, int, int)? _lastPress;

  /// Whether the main frame is mid-load, from the engine's own navigation
  /// lane. Drives the toolbar's reload↔stop swap.
  bool _loading = false;

  String? _currentUrl;
  StreamSubscription<BrowserPageEvent>? _navSub;
  StreamSubscription<BrowserPermissionProbe>? _permSub;

  /// One row per origin+kind. Newest last, so the flyout reads naturally.
  final List<BrowserPermissionEntry> _permissions = [];

  /// Parked interceptor asks, keyed by request id.
  final Map<String, BrowserPermissionProbe> _probes = {};

  void _bindPermissions() {
    final host = asBrowserPermissionHost(client);
    if (host == null) {
      return;
    }
    _permSub = host.permissionProbes.listen(_onPermissionProbe);
  }

  String _permissionKey(String origin, String kind) => '$origin\u0000$kind';

  void _onPermissionProbe(BrowserPermissionProbe probe) {
    final kind = BrowserPermissionKind.fromWire(probe.kind);
    if (kind == null) {
      // An interceptor the host has not met yet must not hang the page.
      unawaited(_resolveProbe(probe, allow: false));
      return;
    }
    final key = _permissionKey(probe.origin, kind.wire);
    for (final entry in _permissions) {
      if (_permissionKey(entry.origin, entry.kind.wire) == key &&
          entry.decision != BrowserPermissionDecision.pending) {
        unawaited(
          _resolveProbe(
            probe,
            allow: entry.decision == BrowserPermissionDecision.granted,
          ),
        );
        return;
      }
    }
    _probes[probe.id] = probe;
    final alreadyPending = _permissions.any(
      (e) =>
          _permissionKey(e.origin, e.kind.wire) == key &&
          e.decision == BrowserPermissionDecision.pending,
    );
    if (!alreadyPending) {
      _permissions.add(
        BrowserPermissionEntry(
          id: probe.id,
          origin: probe.origin,
          kind: kind,
          decision: BrowserPermissionDecision.pending,
          contextId: probe.contextId,
        ),
      );
    }
  }

  Future<void> _resolveProbe(
    BrowserPermissionProbe probe, {
    required bool allow,
  }) async {
    final host = asBrowserPermissionHost(client);
    if (host == null) {
      return;
    }
    try {
      await host.resolvePermissionProbe(probe, allow: allow);
    } on Object catch (e) {
      CcInfraLog.debug('rig/browser: permission resolve failed: $e');
    }
  }

  Future<RigActionResult> _respondPermission(
    BrowserPermissionRespond action,
  ) async {
    final probe = _probes[action.requestId];
    if (probe == null) {
      // The flyout may have reused the first pending id after more asks
      // for the same origin+kind. Fall back to that row.
      BrowserPermissionEntry? entry;
      for (final e in _permissions) {
        if (e.id == action.requestId) {
          entry = e;
          break;
        }
      }
      if (entry == null) {
        return RigActionResult.error(
          'No site permission is waiting on request ${action.requestId}.',
        );
      }
      return _finishPermission(entry, allow: action.allow);
    }
    final kind =
        BrowserPermissionKind.fromWire(probe.kind) ??
        BrowserPermissionKind.notifications;
    final entry = BrowserPermissionEntry(
      id: probe.id,
      origin: probe.origin,
      kind: kind,
      decision: BrowserPermissionDecision.pending,
      contextId: probe.contextId,
    );
    return _finishPermission(entry, allow: action.allow);
  }

  Future<RigActionResult> _finishPermission(
    BrowserPermissionEntry entry, {
    required bool allow,
  }) async {
    final decision = allow
        ? BrowserPermissionDecision.granted
        : BrowserPermissionDecision.denied;
    final key = _permissionKey(entry.origin, entry.kind.wire);
    for (var i = 0; i < _permissions.length; i++) {
      final current = _permissions[i];
      if (_permissionKey(current.origin, current.kind.wire) == key) {
        _permissions[i] = current.withDecision(decision);
      }
    }
    final waiting = [
      for (final probe in _probes.values)
        if (_permissionKey(probe.origin, probe.kind) == key) probe,
    ];
    if (waiting.isEmpty) {
      waiting.add(
        BrowserPermissionProbe(
          id: entry.id,
          origin: entry.origin,
          kind: entry.kind.wire,
          contextId: entry.contextId,
        ),
      );
    }
    for (final probe in waiting) {
      _probes.remove(probe.id);
      await _resolveProbe(probe, allow: allow);
    }
    return RigActionResult.ok(
      allow
          ? 'Allowed ${entry.kind.wire} for ${entry.originLabel}.'
          : 'Blocked ${entry.kind.wire} for ${entry.originLabel}.',
    );
  }

  void _bindNavigationTracking() {
    // One normalised lane for all three engines. The per-protocol reduction
    // (which CDP frame is the main one, which BiDi context is ours, WebKit's
    // polled URL) lives in the client, because it is knowledge about that
    // protocol rather than about browsers.
    _navSub = client.pageEvents.listen((event) {
      switch (event) {
        case BrowserPageUrlChanged(:final url):
          _publishUrl(url);
        case BrowserPageLoadingChanged(:final loading):
          _loading = loading;
      }
    });
  }

  void _publishUrl(String url) {
    // about:blank / chrome-error:// are the absence of a page, not a
    // destination — a frame that never finished loading, or Chromium's
    // failed-load interstitial, must not blank out the address a person just
    // read off the bar. The interstitial re-commits on viewport resize, which
    // is what made the bar flicker between the failed URL and
    // chrome-error://chromewebdata/.
    final visible = visibleBrowserUrl(url);
    if (visible.isEmpty || visible == _currentUrl) {
      return;
    }
    _currentUrl = visible;
    onUrlChanged?.call(visible);
  }

  /// Reads and publishes the URL the page is ALREADY on.
  ///
  /// The event stream only reports CHANGES, and the home page loads before
  /// this driver exists — without the seed the address bar stays empty until
  /// the first navigation.
  Future<void> seedCurrentUrl() async {
    try {
      _publishUrl(await client.currentUrl());
    } on Object {
      // Best effort: the first real navigation publishes one anyway.
    }
  }

  /// The live navigation state, straight from the session history.
  Future<RigBrowserState> navState() async {
    final state = await client.navigationState();
    return RigBrowserState(
      url: visibleBrowserUrl(state.url),
      canGoBack: state.canGoBack,
      canGoForward: state.canGoForward,
      loading: _loading,
      permissions: List<BrowserPermissionEntry>.unmodifiable(_permissions),
    );
  }

  @override
  RigDisplaySize get display => _viewport;

  /// What the lane actually carries, which is a property of the ENGINE.
  ///
  /// Chromium and Firefox hand over JPEG; WebKit's driver has no format
  /// parameter and answers PNG. Declaring MJPEG for those bytes is exactly the
  /// bug this getter exists to prevent — the viewer would scan a PNG stream
  /// for JPEG markers forever and paint nothing, with every other signal
  /// saying the rig is healthy.
  @override
  RigStreamCodec get watchCodec =>
      engine.capturesJpeg ? RigStreamCodec.mjpeg : RigStreamCodec.mpng;

  @override
  Future<RigActionResult> perform(RigAction action) async {
    if (action is! BrowserAction) {
      return RigActionResult.error(
        'A ${action.surface.wire} action cannot be sent to a browser rig.',
      );
    }
    try {
      switch (action) {
        case BrowserNavigate(:final url):
          final loaded = await client.navigate(
            guestLoopbackUrl(url.toString()),
          );
          final where = sanitizeGuestUrl(await client.currentUrl());
          return RigActionResult.ok(
            loaded
                ? 'Loaded $where.'
                : 'Navigated to $where but the load event never fired — the '
                      'page may still be fetching. What has rendered is '
                      'usable; take a screenshot or extract to see it.',
          );

        case BrowserReload(:final hard):
          await client.reload(ignoreCache: hard);
          return RigActionResult.ok(
            '${action.summary} — ${sanitizeGuestUrl(await client.currentUrl())}.',
          );

        case BrowserStopLoading():
          await client.stopLoading();
          _loading = false;
          return RigActionResult.ok('${action.summary}.');

        case BrowserClick(
          :final selector,
          :final x,
          :final y,
          :final button,
          :final clicks,
        ):
          if (selector != null) {
            final center = await client.centerOf(selector);
            if (center == null) {
              return RigActionResult.error(
                'No element matches "$selector", or it has no layout box. '
                'Extract the accessibility tree to see what is on the page.',
              );
            }
            await _move(center.$1, center.$2);
            await client.clickAt(
              center.$1,
              center.$2,
              button: button.wire,
              clickCount: clicks,
            );
            return RigActionResult.ok('${action.summary}.');
          }
          await _move(x!, y!);
          await client.clickAt(x, y, button: button.wire, clickCount: clicks);
          return RigActionResult.ok('${action.summary}.');

        case BrowserMouseMove(:final x, :final y):
          await _move(x, y);
          return RigActionResult.ok('Moved the pointer to ($x, $y).');

        case BrowserMouseButtonHold(:final pressed, :final x, :final y):
          final at = (x != null && y != null) ? (x, y) : _lastPointer;
          if (at == null) {
            return RigActionResult.error(
              'No coordinate given and the pointer has not been placed yet — '
              'send a mouse_move or a coordinate first.',
            );
          }
          await _move(at.$1, at.$2);
          if (pressed) {
            await _pressPrimary(at.$1, at.$2);
          } else {
            _leftHeld = false;
            // The release repeats the press's count: Chromium takes the DOM
            // click/dblclick `detail` from the RELEASE, so a count-1 release
            // after a count-2 press is two single clicks to the page's own
            // handlers even though Blink selected the word.
            await client.mouseUp(at.$1, at.$2, clickCount: _lastPress?.$4 ?? 1);
          }
          return RigActionResult.ok('${action.summary}.');

        case BrowserDrag(:final fromX, :final fromY, :final toX, :final toY):
          final startX = fromX ?? _lastPointer?.$1;
          final startY = fromY ?? _lastPointer?.$2;
          if (startX == null || startY == null) {
            return RigActionResult.error(
              'No start_coordinate given and the pointer has not been placed '
              'yet — send a mouse_move first.',
            );
          }
          await _move(startX, startY);
          await _pressPrimary(startX, startY);
          // Intermediate points, because a single jump reads as a teleport to
          // most drag handlers and the selection never starts.
          const steps = 8;
          for (var i = 1; i <= steps; i++) {
            await _move(
              startX + ((toX - startX) * i / steps).round(),
              startY + ((toY - startY) * i / steps).round(),
            );
            await Future<void>.delayed(const Duration(milliseconds: 16));
          }
          _leftHeld = false;
          await client.mouseUp(toX, toY, clickCount: _lastPress?.$4 ?? 1);
          return RigActionResult.ok('${action.summary}.');

        case BrowserType(:final text):
          if (text.isEmpty) {
            return RigActionResult.ok(
              'Nothing to type — the text was empty, so nothing was sent.',
            );
          }
          await client.typeText(text);
          return RigActionResult.ok('${action.summary}.');

        case BrowserFill(:final selector, :final text, :final submit):
          final ok = await client.fill(selector, text, submit: submit);
          if (!ok) {
            return RigActionResult.error(
              'No element matches "$selector", so nothing was filled.',
            );
          }
          return RigActionResult.ok('${action.summary}.');

        case BrowserKey(:final key, :final modifiers):
          final pressed = await client.pressKey(key, modifiers: modifiers);
          if (!pressed) {
            return RigActionResult.error(
              'Unknown key "$key". Use a DOM key name such as "Enter", "Tab", '
              '"Escape", "ArrowDown", "PageDown" or "F5", or a single '
              'character to insert it.',
            );
          }
          return RigActionResult.ok('${action.summary}.');

        case BrowserScroll(:final dx, :final dy, :final selector):
          if (selector != null) {
            // A wheel event scrolls what is under the POINTER, so a named
            // container is scrolled by aiming at it. Silently scrolling the
            // page instead would look identical in the log and move the wrong
            // thing.
            final scrolled = await client.scrollAt(selector, dx, dy);
            if (!scrolled) {
              return RigActionResult.error(
                'No element matches "$selector", or it has no layout box, so '
                'nothing was scrolled.',
              );
            }
            return RigActionResult.ok('${action.summary} over $selector.');
          }
          await client.scrollBy(dx, dy);
          return RigActionResult.ok('${action.summary}.');

        case BrowserExtract(:final kind, :final selector):
          final body = switch (kind) {
            BrowserExtractKind.a11y => await client.accessibilitySnapshot(
              selector: selector,
            ),
            BrowserExtractKind.dom => await client.domSnapshot(
              selector: selector,
            ),
            BrowserExtractKind.console => client.drainConsole().join('\n'),
          };
          if (body == null) {
            return RigActionResult.error(
              'No element matches "$selector", so there is no subtree to '
              'extract. Extract without a selector to see the whole page.',
            );
          }
          // What this engine's console cannot see, when it cannot see
          // everything. OUTSIDE the untrusted fence on purpose: it is the
          // host talking about the engine, not content that came out of the
          // page, and putting it inside would mark our own caveat as
          // something the page might have written.
          final caveat = kind == BrowserExtractKind.console
              ? client.consoleCaveat
              : null;
          final note = caveat == null ? '' : '$caveat\n\n';
          if (body.trim().isEmpty) {
            return RigActionResult.ok(
              kind == BrowserExtractKind.console
                  ? '${note}No console output since the last extraction.'
                  : 'The ${kind.name} tree is empty.',
            );
          }
          // Everything that came out of the page is fenced as untrusted: it is
          // content to reason about, not instructions to follow, whatever it
          // claims about who wrote it.
          return RigActionResult.ok(
            note +
                wrapUntrustedRigContent(
                  body,
                  source:
                      'browser ${kind.name} — '
                      '${sanitizeGuestUrl(await client.currentUrl())}',
                ),
          );

        case BrowserScreenshot(:final fullPage):
          return await _capture(fullPage: fullPage);

        case BrowserSetViewport(
          :final size,
          :final mobile,
          :final deviceScaleFactor,
        ):
          await client.setViewport(
            width: size.width,
            height: size.height,
            mobile: mobile,
            deviceScaleFactor: deviceScaleFactor,
          );
          _viewport = size;
          return RigActionResult.ok('${action.summary}.');

        case BrowserHistory(:final delta):
          final moved = await client.goHistory(delta);
          if (!moved) {
            return RigActionResult.error(
              'There is no history entry ${delta < 0 ? 'back' : 'forward'} '
              'from here.',
            );
          }
          return RigActionResult.ok(
            '${action.summary} to '
            '${sanitizeGuestUrl(await client.currentUrl())}.',
          );

        case BrowserWaitFor(:final selector, :final timeout):
          final appeared = await client.waitFor(selector, timeout);
          return appeared
              ? RigActionResult.ok('"$selector" appeared.')
              : RigActionResult.error(
                  '"$selector" did not appear within '
                  '${timeout.inMilliseconds}ms.',
                );

        case BrowserClipboardRead():
          final clip = await client.readClipboard();
          if (clip.ok) {
            final data = RigClipboardData(
              text: clip.text,
              imageBase64: clip.imageBase64,
              imageMediaType: clip.imageMediaType,
            );
            return RigActionResult(
              text: data.toUntrustedText(),
              imageBase64: data.imageBase64,
              imageMediaType: data.imageMediaType,
            );
          }
          // The clipboard is unreachable — almost always because the page is
          // not a secure context. The SELECTION is still readable and is
          // usually what was wanted, so offer it and SAY it is a different
          // thing. Substituting silently would report the selection as the
          // clipboard, which is a false claim about the page's state.
          final selected = await client.readSelectionText();
          if (selected.isEmpty) {
            return RigActionResult.error(
              'This page\'s clipboard cannot be read (${clip.unavailable}), '
              'and nothing is selected on it either.',
            );
          }
          return RigActionResult.ok(
            'This page\'s clipboard cannot be read (${clip.unavailable}). '
            'What follows is the current SELECTION instead, which is not the '
            'same thing.\n'
            '${wrapUntrustedRigContent(selected, source: "browser selection")}',
          );

        case BrowserClipboardWrite(:final text):
          final failure = await client.writeClipboard(text: text);
          if (failure != null) {
            return RigActionResult.error(
              'Could not put text on this page\'s clipboard ($failure). Use '
              '"type" to insert it at the caret instead — that does not go '
              'through the clipboard.',
            );
          }
          return RigActionResult.ok(
            '${action.summary}. A paste in the page will find it.',
          );

        case BrowserPermissionRespond():
          return _respondPermission(action);
      }
    } on Object catch (e) {
      return rigDriverFailure(action.verb, e);
    }
  }

  @override
  Future<RigClipboardData> readClipboard(
    RigClipboardSelection selection,
  ) async {
    // A browser has ONE clipboard: no X server behind it, so no PRIMARY and
    // no XdndSelection.
    //
    // Both come back EMPTY rather than being approximated. The tempting
    // approximation for `xdnd` is the page's current text selection, and it
    // is wrong in a way that breaks the page: a selection is not evidence of
    // a drag, so any click-drag over a page that happened to have something
    // selected would be read as "the guest is dragging this" and hijacked
    // into a drag out of the app. Copying out of a browser rig is what the
    // copy chord is for.
    if (selection != RigClipboardSelection.clipboard) {
      return RigClipboardData.empty;
    }
    final clip = await client.readClipboard();
    if (clip.ok) {
      return RigClipboardData(
        text: clip.text,
        imageBase64: clip.imageBase64,
        imageMediaType: clip.imageMediaType,
      );
    }
    // Same substitution as the verb above makes, minus the ability to say so:
    // this path feeds a person's ctrl+C, where an empty clipboard reads as
    // "the copy did not work" and the selection is what they meant.
    final selected = await client.readSelectionText();
    return selected.isEmpty
        ? RigClipboardData.empty
        : RigClipboardData.ofText(selected);
  }

  @override
  Future<void> writeClipboard(RigClipboardData data) async {
    final failure = await client.writeClipboard(
      text: data.text,
      imageBase64: data.imageBase64,
      imageMediaType: data.imageMediaType,
    );
    if (failure != null) {
      throw BrowserEngineException(
        'This page has no writable clipboard ($failure). It is served over '
        'plain http, and browsers only expose a clipboard to a secure '
        'context.',
      );
    }
  }

  @override
  Future<RigDropResult> offerDroppedFiles(
    List<RigGuestFile> landed,
    RigDropRequest request,
  ) async {
    if (landed.isEmpty) {
      return RigDropResult.error('Nothing landed in the machine.');
    }
    final paths = [for (final f in landed) f.guestPath];
    final names = landed.length == 1
        ? '"${landed.single.name}"'
        : '${landed.length} files';
    // A page's real drop handler, at the point the person let go. This is the
    // one surface where a genuine drop is possible, because Chromium will
    // synthesize the DataTransfer for us — everything else has to settle for
    // a folder and a clipboard.
    if (request.hasPoint) {
      final dropped = await client.dropFiles(
        guestPaths: paths,
        x: request.x!,
        y: request.y!,
      );
      if (dropped) {
        return RigDropResult(
          files: landed,
          deliveredAsDrop: true,
          summary:
              'Dropped $names onto the page at '
              '(${request.x}, ${request.y}).',
        );
      }
    }
    // No point, or the page had nothing there that accepts a drop. The files
    // are still inside the browser's machine, so a file input can be pointed
    // at them — which is what the fallback below is for.
    return RigDropResult(
      files: landed,
      summary:
          'Copied $names into ${guestDirectoryOf(paths.first)} in the '
          'browser\'s machine, but nothing at that point accepted a drop. '
          'A file input can still be pointed at these paths.',
    );
  }

  /// Points the file input matching [selector] at [guestPaths].
  ///
  /// Exposed for the upload case a drop cannot serve: a hidden
  /// `<input type=file>` behind a styled button has no drop target at all.
  Future<bool> attachToFileInput({
    required String selector,
    required List<String> guestPaths,
  }) => client.setFileInputFiles(selector: selector, guestPaths: guestPaths);

  @override
  Future<RigActionResult> captureForAgent() => _capture(fullPage: false);

  Future<RigActionResult> _capture({required bool fullPage}) async {
    try {
      // Clamped to the SAME agent ceiling the computer and mobile lanes
      // apply. Those two downscale in the guest; this one shipped whatever
      // Chromium encoded at up to the 2560×1600 negotiation ceiling — four
      // times the pixels — and `fullPage: true` made an infinite-scroll page
      // an arbitrarily large image. `capToolImages` caps the COUNT of images
      // a result may carry, never their size.
      const ceiling = RigDisplaySize.agentCeiling;
      final data = await client.captureScreenshot(
        fullPage: fullPage,
        maxWidth: ceiling.width,
        maxHeight: ceiling.height,
      );
      return RigActionResult(
        text:
            'Screenshot of ${sanitizeGuestUrl(await client.currentUrl())} '
            '(viewport $_viewport${fullPage ? ', full page' : ''}, '
            'scaled to fit $ceiling). Coordinates in actions are in VIEWPORT '
            'pixels ($_viewport), not screenshot pixels.',
        imageBase64: data,
        // Declared from the ENGINE, never assumed. WebKit's driver has no
        // format parameter and answers PNG; a result that labelled those
        // bytes JPEG would reach a provider as an image it cannot decode.
        imageMediaType: engine.stillMediaType,
        displaySize: _viewport.toString(),
      );
    } on Object catch (e) {
      return RigActionResult.error('Screenshot failed: $e');
    }
  }

  /// How many viewers are attached to this page's screencast.
  ///
  /// Chromium has ONE screencast per page, so a second viewer must not restart
  /// it and the first viewer leaving must not stop it out from under the
  /// second. Counting is what keeps two people watching one rig from cutting
  /// each other off.
  int _viewers = 0;

  @override
  Future<Stream<List<int>>?> openWatchStream(RigWatchRequest request) async {
    // Two lanes, chosen by what the engine can actually do. Chromium PUSHES
    // frames as the page repaints, which costs nothing while a page is
    // static; the other two have no screencast in their protocol at all, so
    // the host polls stills. Pretending otherwise would mean a Firefox rig
    // that connects and never paints.
    if (!client.supportsScreencast) {
      return _openPolledWatchStream(request);
    }
    return _openScreencastStream(request);
  }

  /// The polled lane, for an engine with no screencast.
  ///
  /// Deliberately slower than the pushed one and capped below what a viewer
  /// asks for: every frame here is a full capture command plus a base64 round
  /// trip, so a 30 fps request would keep the browser busy encoding instead of
  /// rendering the page the lane is supposed to show. The cap is a property of
  /// the mechanism, not a preference — see [_polledFpsCeiling].
  ///
  /// The engine's own bytes are relayed as they are, whichever format they
  /// are in ([watchCodec] declares it). No host transcode: demanding an
  /// ffmpeg to WATCH A BROWSER would make the live view fail on a machine
  /// where everything else about the rig works.
  Future<Stream<List<int>>?> _openPolledWatchStream(
    RigWatchRequest request,
  ) async {
    final controller = StreamController<List<int>>();
    final fps = request.fps.clamp(1, _polledFpsCeiling);
    final interval = Duration(milliseconds: (1000 / fps).round());
    var stopped = false;

    Future<void> shutdown() async {
      if (stopped) {
        return;
      }
      stopped = true;
      if (!controller.isClosed) {
        await controller.close();
      }
    }

    controller.onCancel = shutdown;

    unawaited(() async {
      var consecutiveFailures = 0;
      while (!stopped && !controller.isClosed) {
        final started = DateTime.now();
        try {
          final data = await client.captureScreenshot(quality: request.quality);
          if (!controller.isClosed) {
            controller.add(base64Decode(data));
          }
          consecutiveFailures = 0;
        } on Object catch (e) {
          // A capture fails while the page is mid-navigation, which is normal
          // and self-healing. A browser that has GONE fails every time, and a
          // poll loop that retries that forever is a busy loop against a dead
          // socket.
          consecutiveFailures++;
          if (consecutiveFailures >= _polledFailureLimit) {
            CcInfraLog.warning(
              'rig/browser: ${engine.label} stopped answering the watch lane '
              '($e); closing it',
            );
            await shutdown();
            return;
          }
        }
        final elapsed = DateTime.now().difference(started);
        final remaining = interval - elapsed;
        if (remaining > Duration.zero) {
          await Future<void>.delayed(remaining);
        }
      }
    }());

    return controller.stream;
  }

  /// The polled lane's frame-rate ceiling.
  ///
  /// A capture command, a base64 encode in the guest and a decode on the host
  /// is tens of milliseconds of real work per frame on both sides. Above this
  /// the browser spends its time serving the watch lane rather than rendering
  /// the page the lane is supposed to show.
  static const int _polledFpsCeiling = 6;

  /// How many captures in a row may fail before the lane gives up.
  static const int _polledFailureLimit = 10;

  Future<Stream<List<int>>?> _openScreencastStream(
    RigWatchRequest request,
  ) async {
    // Chromium encodes and paces the frames itself; the host relays them
    // without decoding anything.
    //
    // Concatenated JPEGs with NO multipart boundary, because that is what the
    // other two surfaces emit and what `RigStreamCodec.mjpeg` declares. This
    // lane used to write `--ccrigframe` part headers that no declared content
    // type ever mentioned and no viewer ever read — the viewer resynchronises
    // on SOI/EOI, so the headers were bytes it had to skip past.
    //
    // `sync: false` and no buffering before a listener attaches: the stream is
    // returned and the HTTP route subscribes a moment later, and an aborted
    // request would otherwise pile up JPEGs with nothing to drain them.
    final controller = StreamController<List<int>>();
    StreamSubscription<BrowserFrame>? sub;
    var closed = false;

    Future<void> shutdown() async {
      if (closed) {
        return;
      }
      closed = true;
      await sub?.cancel();
      _viewers--;
      if (_viewers <= 0) {
        _viewers = 0;
        try {
          await client.stopScreencast();
        } on Object {
          // The page may already be gone.
        }
      }
      if (!controller.isClosed) {
        await controller.close();
      }
    }

    controller.onCancel = shutdown;

    // The dedicated lane, not the generic event stream: the frame is decoded
    // once inside the client without a full `jsonDecode` of the base64 payload
    // and the metadata block nobody reads.
    sub = client.screencastFrames.listen((frame) {
      if (!controller.isClosed) {
        controller.add(frame.bytes);
      }
      if (frame.sessionId >= 0) {
        // Acking is what lets the next frame be sent, so it is also the
        // backpressure: a slow consumer simply gets fewer frames.
        unawaited(client.ackScreencastFrame(frame.sessionId));
      }
      // Without this the controller is never closed when the browser goes away,
      // and the viewer's response body hangs open until its own timeout instead
      // of ending cleanly.
    }, onDone: () => unawaited(shutdown()));

    _viewers++;
    try {
      await client.startScreencast(
        maxWidth: request.size.width,
        maxHeight: request.size.height,
        quality: request.quality,
        // CDP has no fps dial; it throttles by dropping frames. 60 is the
        // practical ceiling of a screencast, so this maps a requested rate onto
        // "take every Nth".
        everyNthFrame: (60 / request.fps).round().clamp(1, 10),
      );
    } on Object {
      // The subscription and the viewer count were taken above; a screencast
      // that never started must hand both back or the page's ONE screencast
      // is considered watched forever and never stopped.
      await shutdown();
      rethrow;
    }
    // Prime the lane with one direct screenshot. A screencast emits frames
    // only when the page REPAINTS, and a page that never does (about:blank,
    // any static site) produces no frames at all — the multipart body then
    // stays empty, the response headers are never flushed, and the viewer
    // hangs on "connecting" forever with nothing wrong anywhere else.
    unawaited(() async {
      try {
        final first = await client.captureScreenshot(quality: request.quality);
        if (!closed && !controller.isClosed) {
          controller.add(base64Decode(first));
        }
      } on Object {
        // The screencast will paint as soon as the page does; the primer is
        // best-effort.
      }
    }());
    return controller.stream;
  }

  @override
  Future<Stream<List<int>>?> openAudioStream() async =>
      audioStreamOpener?.call();

  @override
  Future<bool> sendAudioInput(
    Uint8List bytes, {
    required String sessionId,
    required int sampleRate,
    required int channels,
    bool start = false,
    bool end = false,
  }) async =>
      await audioInputSender?.call(
        bytes,
        sessionId: sessionId,
        sampleRate: sampleRate,
        channels: channels,
        start: start,
        end: end,
      ) ??
      false;

  Future<void> _move(int x, int y) async {
    await client.moveMouse(x, y, dragging: _leftHeld);
    _lastPointer = (x, y);
  }

  /// Presses the primary button, deriving the click count from timing.
  ///
  /// Chromium derives double/triple clicks from the `clickCount` on the press
  /// event, NOT from the wall clock — two press/release pairs with count 1
  /// are two clicks forever, and the word/paragraph selection a person
  /// expects from rapid clicking never happens. The driver is where the
  /// presses arrive, so the timing lives here.
  Future<void> _pressPrimary(int x, int y) async {
    final now = DateTime.now();
    final last = _lastPress;
    final count =
        last != null &&
            now.difference(last.$1) < const Duration(milliseconds: 500) &&
            (x - last.$2).abs() <= 4 &&
            (y - last.$3).abs() <= 4
        ? (last.$4 + 1).clamp(1, 3)
        : 1;
    _lastPress = (now, x, y, count);
    _leftHeld = true;
    await client.mouseDown(x, y, clickCount: count);
  }

  @override
  Future<void> dispose() async {
    await _navSub?.cancel();
    _navSub = null;
    await _permSub?.cancel();
    _permSub = null;
    await audioInputCloser?.call();
    await client.close();
  }
}
