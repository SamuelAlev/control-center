import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cc_domain/features/rigs/domain/ports/rig_port.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/browser_action.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/computer_action.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/mobile_action.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_action.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_action_result.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_browser_state.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_clipboard.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_display.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_file_transfer.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';
import 'package:cc_infra/src/rigs/adb_client.dart';
import 'package:cc_infra/src/rigs/cdp_client.dart';
import 'package:cc_infra/src/rigs/guest_agent_client.dart';
import 'package:cc_infra/src/rigs/host_ffmpeg.dart';
import 'package:cc_infra/src/rigs/qemu_enclosure_backend.dart';
import 'package:cc_infra/src/rigs/qemu_keymap.dart';
import 'package:cc_infra/src/rigs/qmp_client.dart';
import 'package:cc_infra/src/rigs/rig_file_transfer.dart';

/// A surface structurally cannot do what was asked, and the message says why.
///
/// Distinct from a failure: nothing is wrong, nothing will be different on a
/// retry, and the fix is a different verb or a different surface. The message
/// reaches a model verbatim and a person through a toast, so it names the
/// constraint rather than the symptom.
class RigSurfaceUnsupported implements Exception {
  /// Creates a [RigSurfaceUnsupported].
  const RigSurfaceUnsupported(this.message);

  /// Why this surface cannot.
  final String message;

  @override
  String toString() => 'RigSurfaceUnsupported: $message';
}

/// Performs actions on one rig surface.
///
/// One implementation per surface. Each owns the translation between the
/// domain's verbs and its protocol, and each returns a [RigActionResult] with
/// text FIRST — an image with no words is unreadable to a text-only provider
/// and worthless once compaction sheds the frame.
abstract interface class RigDriver {
  /// Performs [action].
  Future<RigActionResult> perform(RigAction action);

  /// Captures a still for the agent lane, downscaled to the model ceiling.
  Future<RigActionResult> captureForAgent();

  /// The codec this driver's watch lane actually emits.
  ///
  /// Declared by the DRIVER, never read from the request: a viewer sends what
  /// it can decode (and in practice sends nothing, so the request defaults to
  /// MJPEG), while the bytes on the wire are whatever the surface produces.
  /// Echoing the request back is how the mobile lane came to serve raw H.264
  /// under an MJPEG content type — the viewer scanned it for JPEG markers
  /// forever and painted nothing.
  RigStreamCodec get watchCodec;

  /// Opens the human watch lane.
  ///
  /// Throws [RigStreamUnavailable] when this surface could serve a lane but
  /// the HOST cannot — a missing transcoder, say. Null is reserved for "this
  /// surface has no such lane"; the two need different words in front of a
  /// person.
  Future<Stream<List<int>>?> openWatchStream(RigWatchRequest request);

  /// Opens the guest's audio lane (encoded bytes), or null when this surface
  /// has none.
  Future<Stream<List<int>>?> openAudioStream();

  /// The guest's current display size.
  RigDisplaySize get display;

  /// Reads [selection] off the guest's clipboard.
  ///
  /// Returns [RigClipboardData.empty] when there is nothing on it — a normal
  /// state, and one every surface can report without an error.
  Future<RigClipboardData> readClipboard(RigClipboardSelection selection);

  /// Puts [data] on the guest's clipboard.
  ///
  /// Throws on failure rather than returning a flag: every caller has to say
  /// something to a person when a paste does not land, and a bool loses the
  /// reason ("this page is not a secure context") that makes the message
  /// useful.
  Future<void> writeClipboard(RigClipboardData data);

  /// Offers [landed] — files already written into the guest — to whatever is
  /// at the drop point.
  ///
  /// The transfer put the bytes there; this is the part that makes the guest
  /// NOTICE them, and it differs per surface in ways that matter to the
  /// person who dropped: a page gets a real drop event, a desktop gets a
  /// clipboard it can paste into a file manager. The result says which
  /// happened.
  Future<RigDropResult> offerDroppedFiles(
    List<RigGuestFile> landed,
    RigDropRequest request,
  );

  /// Releases anything the driver holds. The VM itself is not the driver's to
  /// destroy.
  Future<void> dispose();
}

/// Drives the desktop surface: input through QMP, capture through the guest
/// agent.
///
/// The split matters. Input goes through the HYPERVISOR, so the guest never
/// runs a privileged process that can synthesize keystrokes; capture goes
/// through the GUEST, so it can scale before the bytes cross the wire instead
/// of shipping a full-size framebuffer for the host to shrink.
class ComputerRigDriver implements RigDriver {
  /// Creates a [ComputerRigDriver] over [machine].
  ComputerRigDriver(this.machine);

  /// The machine being driven.
  final QemuMachine machine;

  QmpClient get _qmp => machine.qmp;
  GuestAgentClient get _agent => machine.agent;

  @override
  RigDisplaySize get display => machine.display;

  /// The guest agent's `/stream` is an ffmpeg `-f mjpeg` pipe: raw
  /// concatenated JPEGs, which it labels `video/x-motion-jpeg` itself.
  @override
  RigStreamCodec get watchCodec => RigStreamCodec.mjpeg;

  @override
  Future<RigActionResult> perform(RigAction action) async {
    if (action is! ComputerAction) {
      return RigActionResult.error(
        'A ${action.surface.wire} action cannot be sent to a computer rig.',
      );
    }
    try {
      switch (action) {
        case ComputerScreenshot():
          return await captureForAgent();

        case ComputerCursorPosition():
          // QEMU's input layer is write-only: it never reports where the
          // guest's pointer ended up. But this driver injects ALL pointer
          // input, so the last coordinate it sent is the answer — as long as
          // the result says that is what it is, rather than implying the guest
          // was asked.
          final at = _lastPointer;
          if (at == null) {
            return RigActionResult.ok(
              'The pointer has not been moved by this rig yet, and its '
              'position cannot be read back from the hypervisor. Move it, or '
              'take a screenshot to see where it sits.',
            );
          }
          return RigActionResult.ok(
            'The pointer was last moved to (${at.$1}, ${at.$2}) in guest '
            'pixels. That is the last position injected, not a reading from '
            'the guest — a program inside the VM can have warped it since.',
          );

        case ComputerMouseMove(:final x, :final y):
          await _move(x, y);
          return RigActionResult.ok('Moved the pointer to ($x, $y).');

        case ComputerClick(
          :final button,
          :final clicks,
          :final x,
          :final y,
          :final modifiers,
        ):
          final modifierKeys = <String>[];
          for (final m in modifiers) {
            final keys = qemuKeysFor(m);
            if (keys == null) {
              // Dropping it would turn a ctrl-click into a plain click and
              // report success, which is indistinguishable from working.
              return RigActionResult.error(
                'Unknown modifier "$m". Use "ctrl", "shift", "alt" or '
                '"super".',
              );
            }
            modifierKeys.addAll(keys);
          }
          if (x != null && y != null) {
            await _move(x, y);
          }
          await _qmp.clickWithModifiers(
            button,
            modifierKeys: modifierKeys,
            clicks: clicks,
          );
          return RigActionResult.ok('${action.summary}.');

        case ComputerButtonHold(:final button, :final pressed):
          await _qmp.mouseButton(button, down: pressed);
          return RigActionResult.ok('${action.summary}.');

        case ComputerDrag(:final fromX, :final fromY, :final toX, :final toY):
          if (fromX != null && fromY != null) {
            await _move(fromX, fromY);
          }
          await _qmp.mouseButton(RigMouseButton.left, down: true);
          // Intermediate points, because a single jump reads as a teleport to
          // most drag handlers and the drag never starts.
          const steps = 8;
          final startX = fromX ?? toX;
          final startY = fromY ?? toY;
          for (var i = 1; i <= steps; i++) {
            await _move(
              startX + ((toX - startX) * i / steps).round(),
              startY + ((toY - startY) * i / steps).round(),
            );
            await Future<void>.delayed(const Duration(milliseconds: 16));
          }
          await _qmp.mouseButton(RigMouseButton.left, down: false);
          return RigActionResult.ok('${action.summary}.');

        case ComputerScroll(
          :final direction,
          :final amount,
          :final x,
          :final y,
        ):
          if (x != null && y != null) {
            await _move(x, y);
          }
          await _qmp.scroll(direction, amount: amount);
          return RigActionResult.ok('${action.summary}.');

        case ComputerKey(:final combo, :final hold):
          final keys = qemuComboFor(combo);
          if (keys == null) {
            return RigActionResult.error(
              'Unknown key combination "$combo". Use X11-style names such as '
              '"ctrl+s", "alt+Tab", "Return" or "Escape".',
            );
          }
          await _qmp.sendKeys(keys, holdMs: hold?.inMilliseconds);
          return RigActionResult.ok('${action.summary}.');

        case ComputerType(:final text):
          return await _typeText(text, summary: action.summary);

        case ComputerWait(:final duration):
          await Future<void>.delayed(duration);
          return RigActionResult.ok('${action.summary}.');

        case ComputerSetDisplay(:final size):
          final settled = await _agent.setDisplay(size);
          machine.display = settled;
          return RigActionResult.ok(
            settled == size
                ? 'Display is now $settled.'
                : 'The guest settled on $settled rather than $size.',
          );

        case ComputerClipboardRead(:final selection):
          final data = await readClipboard(selection);
          return RigActionResult(
            text: data.toUntrustedText(),
            imageBase64: data.imageBase64,
            imageMediaType: data.imageMediaType,
          );

        case ComputerClipboardWrite(:final text):
          await writeClipboard(RigClipboardData.ofText(text));
          return RigActionResult.ok(
            '${action.summary}. Press ctrl+v in the guest to paste it.',
          );
      }
    } on Object catch (e) {
      return rigDriverFailure(action.verb, e);
    }
  }

  @override
  Future<RigClipboardData> readClipboard(RigClipboardSelection selection) =>
      _agent.readClipboard(selection);

  @override
  Future<void> writeClipboard(RigClipboardData data) =>
      _agent.writeClipboard(data);

  @override
  Future<RigDropResult> offerDroppedFiles(
    List<RigGuestFile> landed,
    RigDropRequest request,
  ) async {
    // A desktop drop is where the honest answer and the obvious one differ.
    //
    // There is no way for a host to synthesize an XDND drag into an arbitrary
    // X toolkit: the protocol makes the SOURCE window own the transfer, and
    // the source here would have to be a real client inside the guest,
    // holding the pointer, negotiating targets with whatever it is over. That
    // is a guest-side drag daemon — precisely the privileged in-guest process
    // this design refuses to have.
    //
    // So the files land in a folder and their URIs go on the clipboard, which
    // is what a file manager's "paste" and a browser's file input both read.
    // [RigDropResult.deliveredAsDrop] stays FALSE, and the caller says so:
    // someone who dropped a CSV expecting an upload needs to know it is a
    // file in a folder, not an upload that happened.
    final files = landed.length == 1
        ? '"${landed.single.name}"'
        : '${landed.length} files';
    if (landed.isEmpty) {
      return RigDropResult.error('Nothing landed in the machine.');
    }
    var clipboardNote = '';
    try {
      await _agent.writeClipboard(RigClipboardData(files: landed));
      clipboardNote =
          ' Their paths are on the guest clipboard, so ctrl+v pastes them '
          'into a file manager or an upload field.';
    } on Object catch (e) {
      // The copy SUCCEEDED and only the convenience failed. Reporting the
      // whole drop as an error here would be wrong — the files are there.
      CcInfraLog.warning('rig/${machine.rigId}: drop clipboard failed: $e');
    }
    return RigDropResult(
      files: landed,
      summary:
          'Copied $files into ${guestDirectoryOf(landed.first.guestPath)} '
          'in the machine.$clipboardNote',
    );
  }

  @override
  Future<RigActionResult> captureForAgent() async {
    try {
      final target = machine.display.fitInside(RigDisplaySize.agentCeiling);
      final bytes = await _agent.capture(size: target);
      return RigActionResult(
        text:
            'Screenshot of the ${machine.display} desktop, scaled to $target. '
            'Coordinates in actions are in GUEST pixels '
            '(${machine.display}), not screenshot pixels.',
        imageBase64: base64Encode(bytes),
        imageMediaType: 'image/jpeg',
        displaySize: machine.display.toString(),
      );
    } on Object catch (e) {
      return RigActionResult.error('Screenshot failed: $e');
    }
  }

  @override
  Future<Stream<List<int>>?> openWatchStream(RigWatchRequest request) =>
      _agent.openStream(request);

  @override
  Future<Stream<List<int>>?> openAudioStream() => _agent.openAudio();

  @override
  Future<void> dispose() async {
    // The QMP client and the agent belong to the machine, which the backend
    // tears down. Nothing driver-owned to release.
  }

  /// The last coordinate this driver injected, in guest pixels.
  ///
  /// The hypervisor cannot be asked where the pointer is, and the driver is
  /// the only thing that moves it, so remembering is the only honest answer
  /// `cursor_position` can have.
  (int, int)? _lastPointer;

  Future<void> _move(int x, int y) async {
    await _qmp.moveTo(
      x: x,
      y: y,
      displayWidth: machine.display.width,
      displayHeight: machine.display.height,
    );
    _lastPointer = (x, y);
  }

  /// Types [text] one key at a time through QMP, or types NOTHING.
  ///
  /// Validated whole before a single key is sent: typing the representable
  /// prefix and then reporting failure leaves half the string in the field
  /// while the model reads "it failed", retries, and doubles what did land.
  Future<RigActionResult> _typeText(
    String text, {
    required String summary,
  }) async {
    final plan = planQemuTyping(text);
    if (!plan.isTypeable) {
      final listed = plan.unsupported.map((c) => "'$c'").join(', ');
      return RigActionResult.error(
        'Nothing was typed: cannot type ${plan.unsupported.length} '
        'character(s): $listed — no qcode mapping on the guest keyboard '
        'layout. The field is unchanged; retype without them, or paste them '
        'another way.',
      );
    }
    for (final chord in plan.chords) {
      await _qmp.sendKeys(chord);
    }
    return RigActionResult.ok('$summary.');
  }
}

/// Turns a thrown object into a result the model can act on.
///
/// The distinction is the whole point: a control channel that is down is a rig
/// problem no argument change fixes, and a bug on the host side is neither.
/// Flattening all three into `<verb> failed: <toString>` left the model
/// retrying the same call against a dead VM.
RigActionResult rigDriverFailure(String verb, Object error) {
  final hint = switch (error) {
    QmpException() =>
      'The hypervisor control channel (QMP) rejected or lost the command. The '
          'VM may be paused or gone — take a screenshot to see whether it is '
          'still alive.',
    GuestAgentException() =>
      'The in-guest agent did not answer. It may still be starting; wait and '
          'retry.',
    CdpException() =>
      'The browser DevTools channel (CDP) rejected or lost the command. The '
          'page or the browser may have gone away.',
    // Before the AdbException arm below, which it extends: "this device is
    // gone" is not "this command failed", and only one of them is worth
    // retrying.
    AdbDeviceGoneException(:final serial) =>
      'Device $serial is not usable. This rig is pinned to that serial and '
          'will not move to another device on its own — nothing here will '
          'work until it is back, so open a new rig instead of retrying.',
    AdbException() =>
      'The device channel (ADB) failed. The emulator may have disconnected.',
    TimeoutException() =>
      'The guest did not answer in time. It may be busy rather than broken; '
          'wait and retry.',
    _ => null,
  };
  if (hint == null) {
    // Deliberately shaped differently: this is our bug, and dressing it up as
    // a channel failure would send the model into a retry loop over it.
    return RigActionResult.error(
      '$verb failed with an internal error in the rig driver '
      '(${error.runtimeType}): $error. This is a host-side defect, not '
      'something to retry with different arguments.',
    );
  }
  return RigActionResult.error('$verb failed — $error. $hint');
}

/// Drives the browser surface over CDP.
class BrowserRigDriver implements RigDriver {
  /// Creates a [BrowserRigDriver].
  BrowserRigDriver({
    required this.cdp,
    required RigDisplaySize viewport,
    this.onUrlChanged,
  }) : _viewport = viewport {
    _bindNavigationTracking();
  }

  /// The DevTools connection.
  final CdpClient cdp;

  /// Called each time the main frame's URL changes, however it changed — an
  /// action's navigate, a person's click on a link, a script's pushState. The
  /// service persists it onto the rig row, so watchers (the address bar) see
  /// navigations as they happen without polling.
  final void Function(String url)? onUrlChanged;

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

  /// The main frame's id, learned from `Page.frameNavigated`, so a SUBFRAME's
  /// same-document navigation is not mistaken for the page's.
  String? _mainFrameId;

  /// Whether the main frame is mid-load, from `Page.frameStartedLoading` /
  /// `Page.frameStoppedLoading`. Drives the toolbar's reload↔stop swap.
  bool _loading = false;

  String? _currentUrl;
  StreamSubscription<CdpEvent>? _navSub;

  void _bindNavigationTracking() {
    _navSub = cdp.events.listen((event) {
      switch (event.method) {
        case 'Page.frameNavigated':
          final frame = event.params['frame'];
          if (frame is Map && frame['parentId'] == null) {
            _mainFrameId = frame['id'] as String?;
            // A committed navigation IS a load starting; the matching
            // frameStartedLoading may already have fired before this frame's
            // id was known (first navigation after attach), so commit is the
            // catch-all and frameStoppedLoading the release.
            _loading = true;
            final url = frame['url'];
            if (url is String) {
              _publishUrl(url);
            }
          }
        case 'Page.navigatedWithinDocument':
          // pushState/hash navigations fire per frame; only the main frame's
          // is the address bar's business.
          if (_mainFrameId != null && event.params['frameId'] == _mainFrameId) {
            final url = event.params['url'];
            if (url is String) {
              _publishUrl(url);
            }
          }
        case 'Page.frameStartedLoading':
          if (event.params['frameId'] == _mainFrameId) {
            _loading = true;
          }
        case 'Page.frameStoppedLoading':
          if (event.params['frameId'] == _mainFrameId) {
            _loading = false;
          }
      }
    });
  }

  void _publishUrl(String url) {
    // about:blank is the absence of a page, not a destination — a frame that
    // never finished loading must not blank out the address a person just
    // read off the bar.
    if (url.isEmpty || url == 'about:blank' || url == _currentUrl) {
      return;
    }
    _currentUrl = url;
    onUrlChanged?.call(url);
  }

  /// Reads and publishes the URL the page is ALREADY on.
  ///
  /// The event stream only reports CHANGES, and the home page loads before
  /// this driver exists — without the seed the address bar stays empty until
  /// the first navigation.
  Future<void> seedCurrentUrl() async {
    try {
      _publishUrl(await cdp.currentUrl());
    } on Object {
      // Best effort: the first real navigation publishes one anyway.
    }
  }

  /// The live navigation state, straight from the session history.
  Future<RigBrowserState> navState() async {
    final state = await cdp.navigationState();
    return RigBrowserState(
      url: state.url,
      canGoBack: state.canGoBack,
      canGoForward: state.canGoForward,
      loading: _loading,
    );
  }

  @override
  RigDisplaySize get display => _viewport;

  /// Chromium hands over base64 JPEGs, which this driver concatenates — the
  /// same shape the other two surfaces emit.
  @override
  RigStreamCodec get watchCodec => RigStreamCodec.mjpeg;

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
          final loaded = await cdp.navigate(url.toString());
          final where = sanitizeGuestUrl(await cdp.currentUrl());
          return RigActionResult.ok(
            loaded
                ? 'Loaded $where.'
                : 'Navigated to $where but the load event never fired — the '
                      'page may still be fetching. What has rendered is '
                      'usable; take a screenshot or extract to see it.',
          );

        case BrowserReload(:final hard):
          await cdp.reload(ignoreCache: hard);
          return RigActionResult.ok(
            '${action.summary} — ${sanitizeGuestUrl(await cdp.currentUrl())}.',
          );

        case BrowserStopLoading():
          await cdp.stopLoading();
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
            final center = await cdp.centerOf(selector);
            if (center == null) {
              return RigActionResult.error(
                'No element matches "$selector", or it has no layout box. '
                'Extract the accessibility tree to see what is on the page.',
              );
            }
            await _move(center.$1, center.$2);
            await cdp.clickAt(
              center.$1,
              center.$2,
              button: button.wire,
              clickCount: clicks,
            );
            return RigActionResult.ok('${action.summary}.');
          }
          await _move(x!, y!);
          await cdp.clickAt(x, y, button: button.wire, clickCount: clicks);
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
            await cdp.mouseUp(at.$1, at.$2, clickCount: _lastPress?.$4 ?? 1);
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
          await cdp.mouseUp(toX, toY, clickCount: _lastPress?.$4 ?? 1);
          return RigActionResult.ok('${action.summary}.');

        case BrowserType(:final text):
          if (text.isEmpty) {
            return RigActionResult.ok(
              'Nothing to type — the text was empty, so nothing was sent.',
            );
          }
          await cdp.typeText(text);
          return RigActionResult.ok('${action.summary}.');

        case BrowserFill(:final selector, :final text, :final submit):
          final ok = await cdp.fill(selector, text, submit: submit);
          if (!ok) {
            return RigActionResult.error(
              'No element matches "$selector", so nothing was filled.',
            );
          }
          return RigActionResult.ok('${action.summary}.');

        case BrowserKey(:final key, :final modifiers):
          final pressed = await cdp.pressKey(key, modifiers: modifiers);
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
            final scrolled = await cdp.scrollAt(selector, dx, dy);
            if (!scrolled) {
              return RigActionResult.error(
                'No element matches "$selector", or it has no layout box, so '
                'nothing was scrolled.',
              );
            }
            return RigActionResult.ok('${action.summary} over $selector.');
          }
          await cdp.scrollBy(dx, dy);
          return RigActionResult.ok('${action.summary}.');

        case BrowserExtract(:final kind, :final selector):
          final body = switch (kind) {
            BrowserExtractKind.a11y => await cdp.accessibilitySnapshot(
              selector: selector,
            ),
            BrowserExtractKind.dom => await cdp.domSnapshot(selector: selector),
            BrowserExtractKind.console => cdp.drainConsole().join('\n'),
          };
          if (body == null) {
            return RigActionResult.error(
              'No element matches "$selector", so there is no subtree to '
              'extract. Extract without a selector to see the whole page.',
            );
          }
          if (body.trim().isEmpty) {
            return RigActionResult.ok(
              kind == BrowserExtractKind.console
                  ? 'No console output since the last extraction.'
                  : 'The ${kind.name} tree is empty.',
            );
          }
          // Everything that came out of the page is fenced as untrusted: it is
          // content to reason about, not instructions to follow, whatever it
          // claims about who wrote it.
          return RigActionResult.ok(
            wrapUntrustedRigContent(
              body,
              source:
                  'browser ${kind.name} — '
                  '${sanitizeGuestUrl(await cdp.currentUrl())}',
            ),
          );

        case BrowserScreenshot(:final fullPage):
          return await _capture(fullPage: fullPage);

        case BrowserSetViewport(:final size, :final mobile):
          await cdp.setViewport(
            width: size.width,
            height: size.height,
            mobile: mobile,
          );
          _viewport = size;
          return RigActionResult.ok('${action.summary}.');

        case BrowserHistory(:final delta):
          final moved = await cdp.goHistory(delta);
          if (!moved) {
            return RigActionResult.error(
              'There is no history entry ${delta < 0 ? 'back' : 'forward'} '
              'from here.',
            );
          }
          return RigActionResult.ok(
            '${action.summary} to '
            '${sanitizeGuestUrl(await cdp.currentUrl())}.',
          );

        case BrowserWaitFor(:final selector, :final timeout):
          final appeared = await cdp.waitFor(selector, timeout);
          return appeared
              ? RigActionResult.ok('"$selector" appeared.')
              : RigActionResult.error(
                  '"$selector" did not appear within '
                  '${timeout.inMilliseconds}ms.',
                );

        case BrowserClipboardRead():
          final clip = await cdp.readClipboard();
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
          final selected = await cdp.readSelectionText();
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
          final failure = await cdp.writeClipboard(text: text);
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
    final clip = await cdp.readClipboard();
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
    final selected = await cdp.readSelectionText();
    return selected.isEmpty
        ? RigClipboardData.empty
        : RigClipboardData.ofText(selected);
  }

  @override
  Future<void> writeClipboard(RigClipboardData data) async {
    final failure = await cdp.writeClipboard(
      text: data.text,
      imageBase64: data.imageBase64,
      imageMediaType: data.imageMediaType,
    );
    if (failure != null) {
      throw CdpException(
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
      final dropped = await cdp.dropFiles(
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
  }) => cdp.setFileInputFiles(selector: selector, guestPaths: guestPaths);

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
      final data = await cdp.captureScreenshot(
        fullPage: fullPage,
        maxWidth: ceiling.width,
        maxHeight: ceiling.height,
      );
      return RigActionResult(
        text:
            'Screenshot of ${sanitizeGuestUrl(await cdp.currentUrl())} '
            '(viewport $_viewport${fullPage ? ', full page' : ''}, '
            'scaled to fit $ceiling). Coordinates in actions are in VIEWPORT '
            'pixels ($_viewport), not screenshot pixels.',
        imageBase64: data,
        imageMediaType: 'image/jpeg',
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
    StreamSubscription<CdpScreencastFrame>? sub;
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
          await cdp.stopScreencast();
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
    sub = cdp.screencastFrames.listen((frame) {
      if (!controller.isClosed) {
        controller.add(frame.bytes);
      }
      if (frame.sessionId >= 0) {
        // Acking is what lets the next frame be sent, so it is also the
        // backpressure: a slow consumer simply gets fewer frames.
        unawaited(cdp.ackScreencastFrame(frame.sessionId));
      }
      // Without this the controller is never closed when the browser goes away,
      // and the viewer's response body hangs open until its own timeout instead
      // of ending cleanly.
    }, onDone: () => unawaited(shutdown()));

    _viewers++;
    try {
      await cdp.startScreencast(
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
        final first = await cdp.captureScreenshot(quality: request.quality);
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
      // Headless Chromium plays into nothing; page audio arrives with the
      // roadmap's audio-capable browser lane, not this surface revision.
      null;

  Future<void> _move(int x, int y) async {
    await cdp.moveMouse(x, y, dragging: _leftHeld);
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
    await cdp.mouseDown(x, y, clickCount: count);
  }

  @override
  Future<void> dispose() async {
    await _navSub?.cancel();
    _navSub = null;
    await cdp.close();
  }
}

/// Drives the mobile surface over ADB.
///
/// The one surface whose two lanes need a HOST-side transcode. Android emits
/// H.264 from `screenrecord` and full-resolution PNG from `screencap`, while
/// the viewer decodes JPEG and the agent lane is capped at
/// [RigDisplaySize.agentCeiling]. Both gaps are closed by an ffmpeg CHILD
/// PROCESS — never in-isolate — and an absent ffmpeg is reported rather than
/// worked around.
class MobileRigDriver implements RigDriver {
  /// Creates a [MobileRigDriver].
  ///
  /// [ffmpeg] resolves the host transcoder; it is injectable so the
  /// missing-ffmpeg branch can be exercised on a host that has one.
  MobileRigDriver({
    required this.adb,
    required RigDisplaySize size,
    FfmpegResolver ffmpeg = HostFfmpeg.locate,
  }) : _size = size,
       _ffmpeg = ffmpeg;

  /// The device connection.
  final AdbClient adb;

  final FfmpegResolver _ffmpeg;

  RigDisplaySize _size;

  @override
  RigDisplaySize get display => _size;

  /// H.264 goes in, concatenated JPEG comes out: what leaves this host is
  /// MJPEG, whatever the device produced.
  @override
  RigStreamCodec get watchCodec => RigStreamCodec.mjpeg;

  // ── No clipboard, and that is a property of Android ─────────────────────
  //
  // Since Android 10, the clipboard is readable only by the app that has
  // focus. There is no ADB command, no shell service call and no permission
  // that changes it — reading it needs an app installed in the guest that
  // volunteers to relay it, which is a component this product does not ship
  // into someone's device.
  //
  // So the mobile surface throws instead of answering. An empty clipboard is
  // a claim ("nothing has been copied") and this cannot make that claim; the
  // capability note in the UI says the same thing, so the affordance is
  // hidden rather than offered and failing.

  @override
  Future<RigClipboardData> readClipboard(RigClipboardSelection selection) =>
      throw const RigSurfaceUnsupported(
        'Android only lets the focused app read the clipboard, so a rig '
        'cannot read this device\'s.',
      );

  @override
  Future<void> writeClipboard(RigClipboardData data) =>
      throw const RigSurfaceUnsupported(
        'Android only lets the focused app write the clipboard, so a rig '
        'cannot write this device\'s. Use "type" to enter text instead.',
      );

  @override
  Future<RigDropResult> offerDroppedFiles(
    List<RigGuestFile> landed,
    RigDropRequest request,
  ) async => RigDropResult.error(
    'Dropping files onto a phone is not supported: an Android device has no '
    'drop target a host can address. Install an APK with "install_apk", or '
    'push files with adb.',
  );

  @override
  Future<RigActionResult> perform(RigAction action) async {
    if (action is! MobileAction) {
      return RigActionResult.error(
        'A ${action.surface.wire} action cannot be sent to a mobile rig.',
      );
    }
    try {
      // The device is re-checked before EVERY action, not once at boot. A
      // serial is chosen when the rig opens and nothing re-validated it: pull
      // the cable and the next tap failed with a raw transport error that
      // reads like a bad argument.
      await adb.ensureReady();
      switch (action) {
        case MobileTap(:final x, :final y):
          await adb.tap(x, y);
          return RigActionResult.ok('${action.summary}.');

        case MobileSwipe(
          :final fromX,
          :final fromY,
          :final toX,
          :final toY,
          :final duration,
        ):
          await adb.swipe(fromX, fromY, toX, toY, duration);
          return RigActionResult.ok('${action.summary}.');

        case MobileType(:final text):
          await adb.typeText(text);
          return RigActionResult.ok('${action.summary}.');

        case MobileKey(:final keycode):
          await adb.keyEvent(keycode);
          return RigActionResult.ok('${action.summary}.');

        case MobileScreenshot():
          return await captureForAgent();

        case MobileUiDump():
          final dump = await adb.uiDump();
          if (dump.trim().isEmpty) {
            return RigActionResult.ok('The view hierarchy is empty.');
          }
          return RigActionResult.ok(
            wrapUntrustedRigContent(dump, source: 'android ui dump'),
          );

        case MobileInstallApk(:final path):
          await adb.installApk(path);
          return RigActionResult.ok('${action.summary}.');

        case MobileStartApp(:final package, :final activity):
          await adb.startApp(package, activity: activity);
          return RigActionResult.ok('${action.summary}.');
      }
    } on Object catch (e) {
      return rigDriverFailure(action.verb, e);
    }
  }

  @override
  Future<RigActionResult> captureForAgent() async {
    try {
      // A phone rotates. The cached size comes from boot, and a stale one
      // means every coordinate the model derives from this screenshot lands
      // somewhere else. One `wm size` per screenshot is cheap; screenshots are
      // not taken in a tight loop.
      await refreshSize();
      final png = await adb.screencap();
      final target = _size.fitInside(RigDisplaySize.agentCeiling);
      final ffmpeg = await _ffmpeg();
      if (ffmpeg != null) {
        final jpeg = await _stillToJpeg(ffmpeg, png, target);
        if (jpeg != null) {
          return RigActionResult(
            // Same shape as the computer surface's wording, and for the same
            // reason: the model clicks in GUEST pixels, so a downscaled frame
            // whose text does not say so turns every coordinate it derives
            // into a miss.
            text:
                'Screenshot of the $_size device, scaled to $target. '
                'Coordinates in actions are in DEVICE pixels ($_size), not '
                'screenshot pixels.',
            imageBase64: base64Encode(jpeg),
            imageMediaType: 'image/jpeg',
            displaySize: _size.toString(),
          );
        }
      }
      // A full-resolution PNG is roughly four times the pixel budget in the
      // worst codec — but a frame that says why it is oversized beats no
      // screenshot at all, and it names the fix instead of quietly costing
      // more on every turn.
      return RigActionResult(
        text:
            'Screenshot of the $_size device at FULL resolution as PNG: this '
            'host has no working ffmpeg, so it could not be downscaled to the '
            '$target agent ceiling or encoded as JPEG. Install ffmpeg to make '
            'these frames cheaper. Coordinates in actions are in DEVICE '
            'pixels ($_size).',
        imageBase64: base64Encode(png),
        imageMediaType: 'image/png',
        displaySize: _size.toString(),
      );
    } on Object catch (e) {
      return RigActionResult.error('Screenshot failed: $e');
    }
  }

  /// Downscales one PNG still to [target] and re-encodes it as JPEG, or null
  /// when ffmpeg could not do it (the caller then ships the PNG and says so).
  Future<Uint8List?> _stillToJpeg(
    HostFfmpeg ffmpeg,
    Uint8List png,
    RigDisplaySize target,
  ) async {
    HostProcess? process;
    try {
      process = await ffmpeg.start([
        '-loglevel',
        'error',
        '-f',
        'png_pipe',
        '-i',
        'pipe:0',
        '-vf',
        ffmpegFitFilter(target.width, target.height),
        '-frames:v',
        '1',
        '-q:v',
        '${mjpegQualityFlag(_stillQuality)}',
        '-f',
        'mjpeg',
        'pipe:1',
      ]);
      final out = BytesBuilder(copy: false);
      // Drained BEFORE stdin is fed: a child whose stdout nobody reads blocks
      // on its first flush and then never drains its stdin either.
      final collected = process.stdout.forEach(out.add);
      // Caught here and not at the await: on the success path nothing awaits
      // this future, and an un-awaited stream error becomes an unhandled
      // async error that takes the isolate with it.
      final diagnostics = process.stderr
          .transform(utf8.decoder)
          .join()
          .catchError((Object _) => '');
      process.stdin.add(png);
      await process.stdin.close();
      await collected.timeout(const Duration(seconds: 20));
      final code = await process.exitCode.timeout(const Duration(seconds: 5));
      if (code != 0 || out.isEmpty) {
        CcInfraLog.warning(
          'rig/mobile: ffmpeg could not transcode the still (exit $code): '
          '${(await diagnostics).trim()}',
        );
        return null;
      }
      return out.takeBytes();
    } on Object catch (e) {
      CcInfraLog.warning('rig/mobile: still transcode failed: $e');
      process?.kill();
      return null;
    }
  }

  /// JPEG quality for an agent still. High enough that small text survives
  /// the downscale, which is the whole point of showing a phone to a model.
  static const int _stillQuality = 80;

  @override
  Future<Stream<List<int>>?> openWatchStream(RigWatchRequest request) async {
    final ffmpeg = await _ffmpeg();
    if (ffmpeg == null) {
      // Loud, and named. The alternative is what shipped: raw H.264 relayed
      // under an MJPEG content type, into a viewer that scanned it for JPEG
      // markers forever while filling and clearing a 32 MB buffer — a live
      // view that hangs on "connecting" with nothing anywhere saying why.
      throw const RigStreamUnavailable(
        code: 'ffmpeg-missing',
        message:
            'The mobile live view needs ffmpeg on the host: Android records '
            'H.264 and the viewer decodes JPEG, so the frames are transcoded '
            'here. Install ffmpeg and reopen the view.',
      );
    }
    // Scale on the DEVICE, keeping the phone's aspect ratio inside whatever
    // the viewer asked for: encoding at the source is cheaper than encoding
    // full-size and shrinking on the host, and a letterboxed 16:10 request
    // would otherwise decide a portrait phone's frame shape.
    final target = _size.fitInside(request.size);
    final controller = StreamController<List<int>>();
    var stopped = false;
    HostProcess? transcoder;
    AdbScreenSegment? segment;
    // The frames of the CURRENT segment. Held so the viewer's pause reaches
    // ffmpeg (and through it screenrecord) rather than piling frames up in
    // the host's memory; it is replaced on every segment restart, which is why
    // it cannot be a plain local.
    // ignore: cancel_subscriptions
    StreamSubscription<List<int>>? frames;

    // How many segments in a row ended the moment they started. A device that
    // has gone away ends every recording instantly, and a loop that restarts
    // on that as fast as processes can spawn is a fork bomb with a viewer
    // attached.
    var instantEnds = 0;

    Future<void> pump() async {
      // One ffmpeg per screenrecord SEGMENT. The device ends a recording after
      // 180s and re-emits its SPS/PPS on the next one; feeding two segments
      // into one decoder is how a viewer froze at the three-minute mark while
      // every other signal still said healthy.
      while (!stopped && !controller.isClosed) {
        HostProcess? child;
        AdbScreenSegment? seg;
        final startedAt = DateTime.now();
        final filters =
            '${ffmpegFitFilter(target.width, target.height)},'
            'fps=${request.fps}';
        try {
          child = await ffmpeg.start([
            '-loglevel', 'error',
            '-f', 'h264',
            '-i', 'pipe:0',
            '-vf', filters,
            '-q:v', '${mjpegQualityFlag(request.quality)}',
            '-f', 'mjpeg',
            // Frames must leave as they are made; without this ffmpeg buffers
            // several and the lane arrives in bursts.
            '-flush_packets', '1',
            'pipe:1',
          ]);
          transcoder = child;
          unawaited(
            child.stderr
                .transform(utf8.decoder)
                .forEach((e) => CcInfraLog.debug('rig/mobile ffmpeg: $e'))
                .catchError((Object _) {}),
          );
          final relayed = Completer<void>();
          frames = child.stdout.listen(
            (chunk) {
              if (!controller.isClosed) {
                controller.add(chunk);
              }
            },
            onDone: () {
              if (!relayed.isCompleted) {
                relayed.complete();
              }
            },
            onError: (Object e) {
              CcInfraLog.warning('rig/mobile: transcoder stream failed: $e');
              if (!relayed.isCompleted) {
                relayed.complete();
              }
            },
          );
          seg = await adb.startScreenSegment(
            bitRate: request.bitrateCeiling,
            width: target.width,
            height: target.height,
          );
          segment = seg;
          try {
            await child.stdin.addStream(seg.bytes);
            await child.stdin.close();
          } on Object {
            // The transcoder died mid-segment; the loop restarts both halves
            // rather than leaving the viewer on a frozen frame.
          }
          await relayed.future;
          await child.exitCode;
        } on Object catch (e) {
          if (!controller.isClosed) {
            controller.addError(
              AdbException('The mobile watch lane failed: $e'),
            );
          }
          return;
        } finally {
          await frames?.cancel();
          frames = null;
          await seg?.stop();
          child?.kill();
        }
        if (DateTime.now().difference(startedAt) > const Duration(seconds: 2)) {
          instantEnds = 0;
          continue;
        }
        instantEnds++;
        if (instantEnds >= 5) {
          if (!controller.isClosed) {
            controller.addError(
              const AdbException(
                'The mobile watch lane could not stay open: the recording '
                'ended immediately five times in a row. The device is '
                'probably gone.',
              ),
            );
          }
          return;
        }
        if (instantEnds >= 2) {
          // The FIRST restart stays immediate — a healthy 180s segment
          // boundary must not cost the viewer a second of black.
          await Future<void>.delayed(const Duration(seconds: 1));
        }
      }
    }

    // Forwarded per segment: the subscription is replaced every restart, so a
    // viewer's pause has to reach whichever one is current.
    controller
      ..onPause = () {
        frames?.pause();
      }
      ..onResume = () {
        frames?.resume();
      }
      ..onCancel = () async {
        stopped = true;
        // Both directions, or the pair outlives the viewer: killing only the
        // transcoder leaves screenrecord writing into a closed pipe, and
        // killing only screenrecord leaves ffmpeg waiting on a stdin nothing
        // will close. The pump closes the controller on its way out.
        await segment?.stop();
        transcoder?.kill();
      };
    unawaited(
      pump().whenComplete(() async {
        if (!controller.isClosed) {
          await controller.close();
        }
      }),
    );
    return controller.stream;
  }

  /// Refreshes the cached device size (after a rotation).
  Future<void> refreshSize() async {
    final size = await adb.screenSize();
    if (size != null) {
      _size = RigDisplaySize(size.$1, size.$2);
    }
  }

  @override
  Future<Stream<List<int>>?> openAudioStream() async =>
      // Emulator audio needs an adb capture lane that does not exist yet.
      null;

  @override
  Future<void> dispose() async {
    // The device outlives the driver; nothing to release.
  }
}
