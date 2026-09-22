import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cc_domain/features/rigs/domain/ports/rig_port.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/computer_action.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/mobile_action.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_action.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_action_result.dart';
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

export 'package:cc_infra/src/rigs/browser_rig_driver.dart';

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

  /// Sends one PCM16 microphone chunk into the guest, or returns false when
  /// this surface has no microphone lane.
  Future<bool> sendAudioInput(
    Uint8List bytes, {
    required String sessionId,
    required int sampleRate,
    required int channels,
    bool start = false,
    bool end = false,
  });

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
    // No host-synthesized XDND into an arbitrary toolkit (needs an in-guest
    // source holding the pointer). Files land in a folder; URIs go on the
    // clipboard. [RigDropResult.deliveredAsDrop] stays false.
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
  Future<bool> sendAudioInput(
    Uint8List bytes, {
    required String sessionId,
    required int sampleRate,
    required int channels,
    bool start = false,
    bool end = false,
  }) async {
    await _agent.sendMicrophone(
      bytes,
      sessionId: sessionId,
      sampleRate: sampleRate,
      channels: channels,
      start: start,
      end: end,
    );
    return true;
  }

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
/// The distinction is the whole point: a control space that is down is a rig
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
    // a space failure would send the model into a retry loop over it.
    return RigActionResult.error(
      '$verb failed with an internal error in the rig driver '
      '(${error.runtimeType}): $error. This is a host-side defect, not '
      'something to retry with different arguments.',
    );
  }
  return RigActionResult.error('$verb failed — $error. $hint');
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
  /// [_ffmpeg] resolves the host transcoder; it is injectable so the
  /// missing-ffmpeg branch can be exercised on a host that has one.
  MobileRigDriver({
    required this.adb,
    required this._size,
    this.onDisplayChanged,
    this._ffmpeg = HostFfmpeg.locate,
  });

  /// The device connection.
  final AdbClient adb;

  /// Persists a changed device display after rotation.
  final void Function(RigDisplaySize display)? onDisplayChanged;

  final FfmpegResolver _ffmpeg;

  RigDisplaySize _size;

  @override
  RigDisplaySize get display => _size;

  /// H.264 goes in, concatenated JPEG comes out: what leaves this host is
  /// MJPEG, whatever the device produced.
  @override
  RigStreamCodec get watchCodec => RigStreamCodec.mjpeg;

  // Since Android 10 the clipboard is focus-app-only; no ADB path exists.
  // Throws rather than returning empty (empty would claim "nothing copied").

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

        case MobileRotate(:final direction):
          await _rotate(direction);
          return RigActionResult.ok('${action.summary}.');

        case MobileScreenshot(:final fullResolution):
          return await _captureStill(fullResolution: fullResolution);

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

        case MobileStopApp(:final package):
          await adb.stopApp(package);
          return RigActionResult.ok('${action.summary}.');

        case MobileClearAppData(:final package):
          await adb.clearAppData(package);
          return RigActionResult.ok('${action.summary}.');

        case MobileUninstallApp(:final package):
          await adb.uninstallApp(package);
          return RigActionResult.ok('${action.summary}.');

        case MobileOpenUrl(:final url):
          await adb.openUrl(url);
          return RigActionResult.ok('${action.summary}.');

        case MobileShell(:final argv):
          final output = await adb.shell(argv);
          return RigActionResult.ok(
            output.isEmpty
                ? '${action.summary}; the command produced no output.'
                : wrapUntrustedRigContent(
                    output,
                    source: 'android device command',
                  ),
          );
      }
    } on Object catch (e) {
      return rigDriverFailure(action.verb, e);
    }
  }

  @override
  Future<RigActionResult> captureForAgent() => _captureStill();

  Future<RigActionResult> _captureStill({bool fullResolution = false}) async {
    try {
      // A phone rotates. The cached size comes from boot, and a stale one
      // means every coordinate the model derives from this screenshot lands
      // somewhere else. One `wm size` per screenshot is cheap; screenshots are
      // not taken in a tight loop.
      await refreshSize();
      final png = await adb.screencap();
      if (fullResolution) {
        return RigActionResult(
          text:
              'Screenshot of the $_size device at full resolution as PNG. '
              'Coordinates in actions are in DEVICE pixels ($_size), not '
              'screenshot pixels.',
          imageBase64: base64Encode(png),
          imageMediaType: 'image/png',
          displaySize: _size.toString(),
        );
      }
      final target = _size.fitInside(RigDisplaySize.agentCeiling);
      final ffmpeg = await _ffmpeg();
      if (ffmpeg != null) {
        final jpeg = await transcodePngStillToJpeg(
          ffmpeg,
          png,
          target.width,
          target.height,
          logContext: 'rig/mobile',
        );
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
    if (size == null) {
      return;
    }
    var next = RigDisplaySize(size.$1, size.$2);
    final rotation = await adb.userRotation();
    if (rotation != null) {
      final landscape = rotation % 2 == 1;
      if (landscape && next.width < next.height) {
        next = RigDisplaySize(next.height, next.width);
      } else if (!landscape && next.width > next.height) {
        next = RigDisplaySize(next.height, next.width);
      }
    }
    if (next == _size) {
      return;
    }
    _size = next;
    onDisplayChanged?.call(next);
  }

  Future<void> _rotate(RigRotateDirection direction) async {
    final current = await adb.userRotation() ?? 0;
    final next = direction == RigRotateDirection.clockwise
        ? (current + 1) % 4
        : (current + 3) % 4;
    await adb.setUserRotation(next);
    // The compositor needs a beat to swap the framebuffer; reading `wm size`
    // immediately still reports the previous orientation.
    await Future<void>.delayed(const Duration(milliseconds: 400));
    await refreshSize();
  }

  @override
  Future<Stream<List<int>>?> openAudioStream() async =>
      // Emulator audio needs an adb capture lane that does not exist yet.
      null;

  @override
  Future<bool> sendAudioInput(
    Uint8List bytes, {
    required String sessionId,
    required int sampleRate,
    required int channels,
    bool start = false,
    bool end = false,
  }) async => false;

  @override
  Future<void> dispose() async {
    // The device outlives the driver; nothing to release.
  }
}
