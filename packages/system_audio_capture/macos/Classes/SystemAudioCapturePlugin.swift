import AVFoundation
import AudioToolbox
import CoreAudio
import Darwin
import FlutterMacOS
import Foundation

// MARK: - SystemAudioCapturePlugin
//
// Driver-free system *output* audio capture for macOS, built entirely on the
// Core Audio process-taps API (macOS 14.4+). No virtual audio driver
// (BlackHole) and no ScreenCaptureKit.
//
// ──────────────────────────────────────────────────────────────────────────
// Tap lifecycle (the heart of this plugin)
// ──────────────────────────────────────────────────────────────────────────
//
// 1. Build a `CATapDescription`.
//      • Full system mixdown -> `init(stereoGlobalTapButExcludeProcesses: [])`
//        (an empty exclude list = "tap everything").
//      • Single process       -> `init(monoMixdownOfProcesses: [pid-object])`.
//    We assign a fresh `uuid` to the description; that UUID is the link
//    between the tap and the aggregate device that consumes it.
//
// 2. `AudioHardwareCreateProcessTap(description, &tapID)` creates the tap.
//    NOTE: creating a tap SUCCEEDS even when the app lacks the audio-capture
//    TCC grant (kTCCServiceAudioCapture, "System Audio Recording Only") — that
//    grant is enforced at DELIVERY, so an unauthorized tap creates fine and
//    reports a valid format but is fed silence. `requestPermission` therefore
//    reads/obtains the grant via the TCC SPI, NOT via tap creation.
//
// 3. Read the tap's REAL stream format from `kAudioTapPropertyFormat`. We must
//    NOT assume 48 kHz stereo Float32 — a real Voice-Processing path has been
//    observed delivering 9-channel buffers. We configure the AVAudioConverter
//    from whatever ASBD the tap actually reports.
//
// 4. Create a *private* aggregate device whose `kAudioAggregateDeviceTapListKey`
//    references the tap UUID (`kAudioSubTapUIDKey`). The aggregate exposes the
//    tapped audio as an input stream.
//
// 5. `AudioDeviceCreateIOProcIDWithBlock` installs an IO proc block. The block
//    runs on a Core Audio realtime thread; we convert each buffer to
//    16 kHz / mono / Int16 LE and hand the bytes to Flutter on the main thread.
//
// 6. `AudioDeviceStart` begins delivery; `AudioDeviceStop` halts it.
//
// 7. Teardown (in reverse): `AudioDeviceStop` -> `AudioDeviceDestroyIOProcID`
//    -> `AudioHardwareDestroyAggregateDevice` -> `AudioHardwareDestroyProcessTap`.
//    Skipping any of these leaks a system-wide audio object.
//
public class SystemAudioCapturePlugin: NSObject, FlutterPlugin {
  // MARK: Channel names (the Dart side depends on these exact strings)

  private static let methodChannelName = "dev.controlcenter/system_audio_capture"
  private static let eventChannelName = "dev.controlcenter/system_audio_capture/frames"

  // MARK: Output format constants

  /// Target PCM emitted to Dart: 16 kHz, mono, signed 16-bit little-endian.
  private static let outputSampleRate: Double = 16_000
  private static let outputChannelCount: AVAudioChannelCount = 1

  // MARK: Live capture state (only touched while running)

  /// The created process tap object id.
  private var processTapID: AudioObjectID = .unknown
  /// The private aggregate device wrapping the tap.
  private var aggregateDeviceID: AudioObjectID = .unknown
  /// The installed IO proc id.
  private var ioProcID: AudioDeviceIOProcID?
  /// `true` once `AudioDeviceStart` has succeeded.
  private var isRunning = false
  /// Diagnostics: IO-proc callback counter (logged sparsely so we can see, from
  /// the console, whether the tap is actually delivering audio frames).
  private var ioCallbackCount = 0

  /// Serial queue the tap's IO proc is dispatched on. Passing `nil` here lets
  /// the HAL pick a managed thread per Apple's docs, but for a *private tap
  /// aggregate* that path was observed to silently never schedule the proc
  /// (AudioDeviceStart returns noErr, yet zero callbacks). The known-good
  /// reference (insidegui/AudioCap and Apple's "Capturing system audio with
  /// Core Audio taps" sample) always hands `…WithBlock` a real queue, so we do
  /// the same.
  private let ioQueue = DispatchQueue(
    label: "dev.controlcenter.system_audio_capture.io",
    qos: .userInitiated
  )
  /// Diagnostics: how many converted PCM frames we've forwarded to Dart.
  private var framesEmitted = 0
  /// Diagnostics: byte size of the most recent tap buffer the IO proc saw.
  private var lastBufferBytes: UInt32 = 0
  /// Diagnostics: why the most recent IO callback produced no output ("ok" when
  /// it did). Reported by the 2s watchdog so a single flutter-output paste tells
  /// us whether the proc fires AND, if it does, why no frames come through.
  private var lastDropReason = "none"

  /// Converter from the tap's native ASBD to our 16 kHz mono Int16 target.
  private var converter: AVAudioConverter?
  /// Cached input format (the tap's real, validated format).
  private var inputFormat: AVAudioFormat?
  /// Cached output format (16 kHz mono Int16).
  private var outputFormat: AVAudioFormat?

  // MARK: Flutter event sink

  private let eventStreamHandler = FrameStreamHandler()

  // MARK: - Registration

  public static func register(with registrar: FlutterPluginRegistrar) {
    let messenger = registrar.messenger
    let methodChannel = FlutterMethodChannel(
      name: methodChannelName,
      binaryMessenger: messenger
    )
    // NOTE: we do NOT use a background EventChannel task queue here. The macOS
    // embedder's FlutterBinaryMessengerRelay advertises `makeBackgroundTaskQueue`
    // but forwards it to a FlutterEngine that does not implement it, so calling
    // it crashes at registration with an unrecognized-selector exception. Frames
    // are therefore delivered on the platform/main thread (see handleInputBuffer);
    // continuous background delivery relies on the App Nap assertion the recorder
    // holds for the whole recording (AppDelegate.beginBackgroundActivity), which
    // keeps the main run loop pumping while the window is unfocused/occluded.
    let eventChannel = FlutterEventChannel(
      name: eventChannelName,
      binaryMessenger: messenger
    )

    let instance = SystemAudioCapturePlugin()
    eventChannel.setStreamHandler(instance.eventStreamHandler)
    registrar.addMethodCallDelegate(instance, channel: methodChannel)
  }

  // MARK: - Method dispatch

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "isSupported":
      result(Self.isSupported())

    case "requestPermission":
      requestPermission(result: result)

    case "listSources":
      result(listSources())

    case "start":
      let args = call.arguments as? [String: Any]
      let sourceId = args?["sourceId"] as? String
      start(sourceId: sourceId, result: result)

    case "stop":
      stop()
      result(nil)

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  // MARK: - isSupported

  /// Core Audio process taps require macOS 14.4 or later.
  private static func isSupported() -> Bool {
    if #available(macOS 14.4, *) {
      return true
    }
    return false
  }

  // MARK: - Audio-capture TCC authorization (kTCCServiceAudioCapture)
  //
  // System-audio recording is gated by its OWN TCC service — shown in System
  // Settings as "System Audio Recording Only" — which is DISTINCT from the
  // microphone grant. It is enforced at audio DELIVERY: an unauthorized process
  // tap still creates successfully and reports a valid format, but is fed
  // silence, so the aggregate is never clocked and the IO proc never fires (the
  // "every call returns noErr, zero callbacks" symptom). There is no public API
  // for this status, so — like insidegui/AudioCap — we read/obtain it via the
  // private TCC SPI.
  //
  // NOTE on dev launches: TCC attributes the grant to the RESPONSIBLE process.
  // Launching under `flutter run` from an editor makes the EDITOR the
  // responsible process; if it already holds the grant, the system treats the
  // request as satisfied and never prompts (or records) the app. Launch the
  // built .app directly to grant against the app's own bundle id.
  private typealias TCCPreflightFn = @convention(c) (CFString, CFDictionary?) -> Int
  private typealias TCCRequestFn =
    @convention(c) (CFString, CFDictionary?, @escaping (Bool) -> Void) -> Void
  private static let tccAudioCaptureService = "kTCCServiceAudioCapture" as CFString
  private static let tccFrameworkPath =
    "/System/Library/PrivateFrameworks/TCC.framework/TCC"

  /// Current audio-capture authorization: 0 = authorized, 1 = denied, anything
  /// else = undetermined (never prompted).
  private func audioCaptureAuthStatus() -> Int {
    guard let handle = dlopen(Self.tccFrameworkPath, RTLD_NOW),
      let sym = dlsym(handle, "TCCAccessPreflight")
    else { return -1 }
    let preflight = unsafeBitCast(sym, to: TCCPreflightFn.self)
    return preflight(Self.tccAudioCaptureService, nil)
  }

  /// Prompts for the audio-capture grant (the system "System Audio Recording
  /// Only" dialog) and reports whether it was granted.
  private func requestAudioCaptureGrant(_ done: @escaping (Bool) -> Void) {
    guard let handle = dlopen(Self.tccFrameworkPath, RTLD_NOW),
      let sym = dlsym(handle, "TCCAccessRequest")
    else { return done(false) }
    let request = unsafeBitCast(sym, to: TCCRequestFn.self)
    request(Self.tccAudioCaptureService, nil) { granted in
      DispatchQueue.main.async { done(granted) }
    }
  }

  // MARK: - requestPermission

  /// Reads the audio-capture TCC status and, if undetermined, prompts for it;
  /// reports whether the app may record system audio. Unlike the old heuristic
  /// (create-a-tap-and-assume-success-means-granted), this reads the ACTUAL
  /// grant — tap creation succeeds even when unauthorized.
  private func requestPermission(result: @escaping FlutterResult) {
    guard #available(macOS 14.4, *) else { result(false); return }
    let status = audioCaptureAuthStatus()
    NSLog(
      "[SystemAudioCapture] kTCCServiceAudioCapture preflight = \(status) "
        + "(0=authorized, 1=denied, other=undetermined)")
    if status == 0 { result(true); return }
    if status == 1 { result(false); return }
    requestAudioCaptureGrant { granted in
      NSLog("[SystemAudioCapture] kTCCServiceAudioCapture request granted = \(granted)")
      result(granted)
    }
  }

  // MARK: - listSources

  /// Returns the full-system entry plus one entry per process that is
  /// currently producing output audio.
  private func listSources() -> [[String: String]] {
    var sources: [[String: String]] = [
      ["id": "system", "name": "System audio", "kind": "system"]
    ]

    guard #available(macOS 14.4, *) else { return sources }

    let processes: [AudioObjectID]
    do {
      processes = try AudioObjectID.readProcessList()
    } catch {
      return sources
    }

    for processID in processes where processID.isValid {
      // Only surface processes that are actively running audio. We accept a
      // process if it is running output (producing sound) — falling back to
      // the generic "is running" flag when the output-specific flag is
      // unavailable.
      let runningOutput = processID.readProcessIsRunningOutput()
      let running = processID.readProcessIsRunning()
      guard runningOutput || running else { continue }

      let name = processID.readProcessDisplayName()
      sources.append([
        "id": String(processID),
        "name": name,
        "kind": "process",
      ])
    }

    return sources
  }

  // MARK: - start

  private func start(sourceId: String?, result: @escaping FlutterResult) {
    guard #available(macOS 14.4, *) else {
      result(
        FlutterError(
          code: "unsupported",
          message: "System audio capture requires macOS 14.4 or later.",
          details: nil
        )
      )
      return
    }

    // Idempotent: a second start with an active session is a no-op success.
    if isRunning {
      result(nil)
      return
    }

    do {
      try startCapture(sourceId: sourceId)
      result(nil)
    } catch let captureError as CaptureError {
      // Roll back any partial setup so we never leak a half-built session.
      teardown()
      result(
        FlutterError(
          code: captureError.code,
          message: captureError.message,
          details: nil
        )
      )
    } catch {
      teardown()
      result(
        FlutterError(
          code: "start_failed",
          message: "Failed to start system audio capture: \(error)",
          details: nil
        )
      )
    }
  }

  @available(macOS 14.4, *)
  private func startCapture(sourceId: String?) throws {
    // 0. Refuse to start without the audio-capture TCC grant. An unauthorized
    // tap creates fine but is fed silence (zero IO callbacks), so without this
    // guard the failure is silent and indistinguishable from a clock bug.
    let authStatus = audioCaptureAuthStatus()
    NSLog("[SystemAudioCapture] kTCCServiceAudioCapture preflight at start = \(authStatus)")
    guard authStatus == 0 else {
      throw CaptureError(
        code: "capture_not_authorized",
        message:
          "System-audio recording is not authorized (kTCCServiceAudioCapture / "
          + "\"System Audio Recording Only\"). Grant it in System Settings ▸ "
          + "Privacy & Security, and launch the app directly — not via `flutter "
          + "run` from an editor, whose process owns the grant.")
    }

    // 1. Build the tap description.
    let description: CATapDescription
    if sourceId == nil || sourceId == "system" {
      // Full system mixdown: tap every process (empty exclude list).
      description = CATapDescription(stereoGlobalTapButExcludeProcesses: [])
    } else {
      guard let objectID = AudioObjectID(sourceId!) else {
        throw CaptureError(code: "invalid_source", message: "Invalid sourceId: \(sourceId!)")
      }
      // Single process: a mono mixdown is fine because we downmix to mono
      // anyway, and it sidesteps the global-tap channel-scaling quirk.
      description = CATapDescription(monoMixdownOfProcesses: [objectID])
    }
    description.uuid = UUID()
    description.name = "ControlCenterSystemAudioTap"
    description.muteBehavior = .unmuted  // capture without muting playback
    description.isPrivate = true
    // DO NOT set `isExclusive` here. The `stereoGlobalTapButExcludeProcesses:`
    // initializer already configures a global tap (exclusive over an empty
    // exclude-list ⇒ "tap everything"). Overwriting `isExclusive = false` flips
    // the semantics to "tap ONLY the listed processes" — and that list is empty,
    // so the tap captures nothing and the aggregate never gets clocked
    // (kAudioDevicePropertyDeviceIsRunning stays 0, IO proc never fires). The
    // self-test bisection proved the bare global tap clocks in-process while this
    // line was the sole difference that broke the real capture.

    // 2. Create the tap (this is the call that prompts for TCC authorization).
    var tapID: AudioObjectID = .unknown
    let tapErr = AudioHardwareCreateProcessTap(description, &tapID)
    guard tapErr == noErr, tapID.isValid else {
      throw CaptureError(
        code: "tap_creation_failed",
        message:
          "AudioHardwareCreateProcessTap failed (\(tapErr)). Audio capture permission may be denied."
      )
    }
    processTapID = tapID

    // 3. Read the tap's REAL stream format. Never assume 48 kHz/stereo/Float32.
    // `var` (not `let`) because AVAudioFormat(streamDescription:) needs a
    // mutable lvalue to form the `&` pointer.
    var tapASBD = try readValidatedTapFormat(tapID: tapID)

    guard let nativeFormat = AVAudioFormat(streamDescription: &tapASBD) else {
      throw CaptureError(
        code: "format_unsupported",
        message: "Could not build AVAudioFormat from tap ASBD (\(tapASBD.mChannelsPerFrame) ch)."
      )
    }
    inputFormat = nativeFormat
    NSLog(
      "[SystemAudioCapture] tap format: \(Int(tapASBD.mSampleRate)) Hz, "
        + "\(tapASBD.mChannelsPerFrame) ch (sourceId=\(sourceId ?? "system"))")

    guard
      let target = AVAudioFormat(
        commonFormat: .pcmFormatInt16,
        sampleRate: Self.outputSampleRate,
        channels: Self.outputChannelCount,
        interleaved: true
      )
    else {
      throw CaptureError(
        code: "output_format_failed",
        message: "Could not build the 16 kHz mono Int16 output format."
      )
    }
    outputFormat = target

    guard let avConverter = AVAudioConverter(from: nativeFormat, to: target) else {
      throw CaptureError(
        code: "converter_failed",
        message:
          "AVAudioConverter could not bridge \(Int(nativeFormat.sampleRate)) Hz / "
          + "\(nativeFormat.channelCount) ch to 16 kHz mono Int16."
      )
    }
    converter = avConverter

    // 4. Create a private aggregate device CLOCKED BY A REAL OUTPUT DEVICE.
    //
    // A tap-only aggregate (the tap as its own clock source) does NOT get
    // clocked on this setup: with the audio-capture grant confirmed in place,
    // the tap-only aggregate's kAudioDevicePropertyDeviceIsRunning stayed 0 and
    // the IO proc never fired (macOS 26 / USB output device). So we follow the
    // AudioCap-canonical recipe — anchor to the current default output device as
    // the aggregate's main sub-device — AND additionally pin it as the explicit
    // clock device (kAudioAggregateDeviceClockDeviceKey) so a USB output
    // device's sample-rate renegotiation can't stall the aggregate's clock. The
    // tap still captures the whole-system mix regardless of output routing; the
    // output device is used only as a clock, not as a playback path.
    let outputUID = try Self.defaultOutputDeviceUID()
    let aggregateUID = "ControlCenter-Tap-\(description.uuid.uuidString)"
    let aggregateDescription: [String: Any] = [
      kAudioAggregateDeviceNameKey: "ControlCenterSystemAudioAggregate",
      kAudioAggregateDeviceUIDKey: aggregateUID,
      // Private: don't expose this aggregate in system-wide device lists.
      kAudioAggregateDeviceIsPrivateKey: true,
      kAudioAggregateDeviceIsStackedKey: false,
      // Auto-start the tap as soon as the aggregate's IO begins.
      kAudioAggregateDeviceTapAutoStartKey: true,
      // Real hardware clock master so the IO proc is actually driven.
      kAudioAggregateDeviceMainSubDeviceKey: outputUID,
      kAudioAggregateDeviceClockDeviceKey: outputUID,
      kAudioAggregateDeviceSubDeviceListKey: [
        [kAudioSubDeviceUIDKey: outputUID]
      ],
      kAudioAggregateDeviceTapListKey: [
        [
          kAudioSubTapDriftCompensationKey: true,
          kAudioSubTapUIDKey: description.uuid.uuidString,
        ]
      ],
    ]
    NSLog("[SystemAudioCapture] aggregate clocked by output device \(outputUID)")

    var aggregateID: AudioObjectID = .unknown
    let aggErr = AudioHardwareCreateAggregateDevice(
      aggregateDescription as CFDictionary,
      &aggregateID
    )
    guard aggErr == noErr, aggregateID.isValid else {
      throw CaptureError(
        code: "aggregate_creation_failed",
        message: "AudioHardwareCreateAggregateDevice failed (\(aggErr))."
      )
    }
    aggregateDeviceID = aggregateID

    // 5. Install the IO proc block. It is dispatched on `ioQueue` (NOT nil —
    // see the property's doc comment: the nil/HAL-thread path never scheduled
    // the proc for this private tap aggregate).
    let block: AudioDeviceIOBlock = { [weak self] _, inputData, _, _, _ in
      guard let self = self else { return }
      self.handleInputBuffer(inputData)
    }

    var procID: AudioDeviceIOProcID?
    let procErr = AudioDeviceCreateIOProcIDWithBlock(
      &procID,
      aggregateID,
      ioQueue,
      block
    )
    guard procErr == noErr, let installedProc = procID else {
      throw CaptureError(
        code: "ioproc_creation_failed",
        message: "AudioDeviceCreateIOProcIDWithBlock failed (\(procErr))."
      )
    }
    ioProcID = installedProc

    // 6. Start delivery.
    let startErr = AudioDeviceStart(aggregateID, installedProc)
    guard startErr == noErr else {
      throw CaptureError(
        code: "device_start_failed",
        message: "AudioDeviceStart failed (\(startErr))."
      )
    }

    isRunning = true
    ioCallbackCount = 0
    NSLog(
      "[SystemAudioCapture] started (aggregate \(aggregateID), tap \(tapID)) "
        + "— awaiting IO frames")

    // Watchdog: if no IO callback has landed 2s after a successful start, the
    // aggregate isn't being clocked (sub-device/clock problem). Emit a verdict
    // BOTH to the native log AND — via a stream error — back to Dart, so the
    // diagnosis is visible in the normal `flutter:` output without fishing the
    // unified log. The error is non-fatal: capture keeps running (the Dart
    // side only logs it), it just tells us the tap is producing nothing.
    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
      guard let self = self, self.isRunning else { return }
      NSLog(
        "[SystemAudioCapture] aggregate kAudioDevicePropertyDeviceIsRunning = "
          + "\(self.aggregateIsRunning()) (1 ⇒ HAL is clocking it)")
      if self.ioCallbackCount == 0 {
        NSLog(
          "[SystemAudioCapture] VERDICT: IO proc has NOT fired 2s after start "
            + "— the aggregate is not being driven (clock/sub-device issue).")
        self.eventStreamHandler.sendError(
          code: "no_io_frames",
          message:
            "System-audio tap started but its IO proc never fired (no frames 2s "
            + "after AudioDeviceStart). The aggregate device is not being clocked.")
      } else if self.framesEmitted == 0 {
        // Proc fires but nothing gets through — surface the exact drop reason.
        let verdict =
          "io_no_output: IO proc fired \(self.ioCallbackCount)× in 2s but emitted "
          + "0 frames (lastBuffer=\(self.lastBufferBytes) bytes, "
          + "lastReason=\(self.lastDropReason))"
        NSLog("[SystemAudioCapture] VERDICT: \(verdict)")
        self.eventStreamHandler.sendError(code: "io_no_output", message: verdict)
      } else {
        NSLog(
          "[SystemAudioCapture] VERDICT: IO proc firing & emitting "
            + "(\(self.ioCallbackCount) callbacks, \(self.framesEmitted) frames in ~2s).")
      }
    }
  }

  /// The UID of the system's current default output device. The aggregate uses
  /// it as both its main sub-device and its explicit clock device so the IO
  /// proc is driven by real hardware (a tap-only aggregate was observed NOT to
  /// clock here — kAudioDevicePropertyDeviceIsRunning stayed 0 — on macOS 26
  /// with a USB output device, even with the audio-capture grant in place).
  private static func defaultOutputDeviceUID() throws -> String {
    var deviceAddress = AudioObjectPropertyAddress(
      mSelector: kAudioHardwarePropertyDefaultOutputDevice,
      mScope: kAudioObjectPropertyScopeGlobal,
      mElement: kAudioObjectPropertyElementMain
    )
    var deviceID = AudioObjectID.unknown
    var size = UInt32(MemoryLayout<AudioObjectID>.size)
    guard
      AudioObjectGetPropertyData(
        AudioObjectID.system, &deviceAddress, 0, nil, &size, &deviceID) == noErr,
      deviceID.isValid
    else {
      throw CaptureError(code: "no_default_output", message: "No default output device.")
    }

    var uidAddress = AudioObjectPropertyAddress(
      mSelector: kAudioDevicePropertyDeviceUID,
      mScope: kAudioObjectPropertyScopeGlobal,
      mElement: kAudioObjectPropertyElementMain
    )
    var cfUID: Unmanaged<CFString>?
    var uidSize = UInt32(MemoryLayout<Unmanaged<CFString>?>.size)
    guard
      AudioObjectGetPropertyData(deviceID, &uidAddress, 0, nil, &uidSize, &cfUID) == noErr,
      let uid = cfUID?.takeRetainedValue()
    else {
      throw CaptureError(code: "no_output_uid", message: "Could not read output device UID.")
    }
    return uid as String
  }

  /// Diagnostics: reads `kAudioDevicePropertyDeviceIsRunning` on the aggregate.
  /// 1 ⇒ the HAL is actually clocking the device; 0 ⇒ it never started — the
  /// hallmark of an unauthorized/silent tap that can't clock the aggregate.
  private func aggregateIsRunning() -> UInt32 {
    guard aggregateDeviceID.isValid else { return 0 }
    var address = AudioObjectPropertyAddress(
      mSelector: kAudioDevicePropertyDeviceIsRunning,
      mScope: kAudioObjectPropertyScopeGlobal,
      mElement: kAudioObjectPropertyElementMain
    )
    var value: UInt32 = 0
    var size = UInt32(MemoryLayout<UInt32>.size)
    let err = AudioObjectGetPropertyData(
      aggregateDeviceID, &address, 0, nil, &size, &value)
    return err == noErr ? value : 0
  }

  /// Reads `kAudioTapPropertyFormat` and validates the result is something we
  /// can actually convert (PCM, non-zero sample rate, at least one channel).
  @available(macOS 14.4, *)
  private func readValidatedTapFormat(tapID: AudioObjectID) throws -> AudioStreamBasicDescription {
    let asbd: AudioStreamBasicDescription
    do {
      asbd = try tapID.readAudioTapStreamBasicDescription()
    } catch {
      throw CaptureError(
        code: "format_read_failed",
        message: "Could not read tap stream format (kAudioTapPropertyFormat): \(error)"
      )
    }

    guard asbd.mSampleRate > 0, asbd.mChannelsPerFrame > 0 else {
      throw CaptureError(
        code: "format_invalid",
        message:
          "Tap reported an unusable format: \(asbd.mSampleRate) Hz, "
          + "\(asbd.mChannelsPerFrame) ch."
      )
    }
    return asbd
  }

  // MARK: - IO proc handling (realtime thread)

  /// Converts one tap buffer to 16 kHz mono Int16 and forwards the bytes to
  /// Flutter. Dispatched on `ioQueue` by Core Audio, so this must stay lean and
  /// must never touch the Flutter sink directly (we hop to main).
  private func handleInputBuffer(_ inputData: UnsafePointer<AudioBufferList>) {
    // Delivery diagnostic: log only the FIRST callback to confirm the tap's IO
    // proc actually fired (the 2s watchdog reports the no-frames failure case).
    ioCallbackCount += 1
    let isFirstCallback = ioCallbackCount == 1
    if isFirstCallback {
      NSLog("[SystemAudioCapture] IO proc fired (callback #1)")
    }

    guard isRunning,
      let converter = converter,
      let inputFormat = inputFormat,
      let outputFormat = outputFormat
    else {
      lastDropReason = "not ready (running/converter/format missing)"
      if isFirstCallback { NSLog("[SystemAudioCapture] drop: \(lastDropReason)") }
      return
    }

    let ablPointer = UnsafeMutableAudioBufferListPointer(
      UnsafeMutablePointer(mutating: inputData)
    )
    guard let firstBuffer = ablPointer.first, firstBuffer.mData != nil else {
      lastDropReason = "empty buffer list (\(ablPointer.count) buffers)"
      if isFirstCallback { NSLog("[SystemAudioCapture] drop: \(lastDropReason)") }
      return
    }
    lastBufferBytes = firstBuffer.mDataByteSize

    // Derive the frame count from the actual delivered byte count and the
    // tap's real bytes-per-frame (do NOT assume a fixed stride).
    let bytesPerFrame = inputFormat.streamDescription.pointee.mBytesPerFrame
    if isFirstCallback {
      NSLog(
        "[SystemAudioCapture] first buffer: \(ablPointer.count) buffer(s), "
          + "\(firstBuffer.mDataByteSize) bytes, bytesPerFrame=\(bytesPerFrame)")
    }
    guard bytesPerFrame > 0 else {
      lastDropReason = "bytesPerFrame == 0"
      if isFirstCallback { NSLog("[SystemAudioCapture] drop: \(lastDropReason)") }
      return
    }
    let frameCount = AVAudioFrameCount(firstBuffer.mDataByteSize / bytesPerFrame)
    guard frameCount > 0 else {
      lastDropReason = "frameCount == 0 (\(firstBuffer.mDataByteSize) bytes)"
      if isFirstCallback { NSLog("[SystemAudioCapture] drop: \(lastDropReason)") }
      return
    }

    // Wrap the incoming buffer list in an AVAudioPCMBuffer without copying.
    guard
      let inputBuffer = AVAudioPCMBuffer(
        pcmFormat: inputFormat,
        bufferListNoCopy: inputData
      )
    else {
      lastDropReason = "AVAudioPCMBuffer(bufferListNoCopy:) returned nil"
      if isFirstCallback { NSLog("[SystemAudioCapture] drop: \(lastDropReason)") }
      return
    }
    inputBuffer.frameLength = frameCount

    // Estimate the output capacity from the sample-rate ratio (round up + pad).
    let ratio = outputFormat.sampleRate / inputFormat.sampleRate
    let outCapacity = AVAudioFrameCount(
      (Double(frameCount) * ratio).rounded(.up)
    ) + 16
    guard
      let outputBuffer = AVAudioPCMBuffer(
        pcmFormat: outputFormat,
        frameCapacity: max(outCapacity, 1)
      )
    else {
      lastDropReason = "output AVAudioPCMBuffer alloc failed"
      if isFirstCallback { NSLog("[SystemAudioCapture] drop: \(lastDropReason)") }
      return
    }

    var consumed = false
    var conversionError: NSError?
    let status = converter.convert(to: outputBuffer, error: &conversionError) {
      _, outStatus in
      if consumed {
        outStatus.pointee = .noDataNow
        return nil
      }
      consumed = true
      outStatus.pointee = .haveData
      return inputBuffer
    }

    guard status != .error, conversionError == nil, outputBuffer.frameLength > 0 else {
      lastDropReason =
        "convert failed (status=\(status.rawValue), "
        + "err=\(conversionError?.code ?? -1), outFrames=\(outputBuffer.frameLength))"
      if isFirstCallback { NSLog("[SystemAudioCapture] drop: \(lastDropReason)") }
      return
    }

    // Int16, interleaved mono -> contiguous LE bytes.
    guard let channelData = outputBuffer.int16ChannelData else {
      lastDropReason = "no int16ChannelData"
      if isFirstCallback { NSLog("[SystemAudioCapture] drop: \(lastDropReason)") }
      return
    }
    let sampleCount = Int(outputBuffer.frameLength) * Int(outputFormat.channelCount)
    let byteCount = sampleCount * MemoryLayout<Int16>.size
    let data = Data(bytes: channelData[0], count: byteCount)

    lastDropReason = "ok"
    framesEmitted += 1

    // Flutter platform channels are not thread-safe off the platform thread:
    // hop to main before touching the event sink. While the window is unfocused
    // this main-queue block only drains if the main run loop keeps running —
    // which the recorder's App Nap assertion guarantees for the recording's
    // duration (otherwise frames batch up until refocus).
    DispatchQueue.main.async { [weak self] in
      self?.eventStreamHandler.send(data)
    }
  }

  // MARK: - stop / teardown

  private func stop() {
    teardown()
  }

  /// Full, ordered cleanup. Safe to call multiple times and from any partial
  /// state — each step guards on validity so a half-built session unwinds
  /// without leaking Core Audio objects.
  private func teardown() {
    isRunning = false

    if #available(macOS 14.4, *) {
      if aggregateDeviceID.isValid, let proc = ioProcID {
        AudioDeviceStop(aggregateDeviceID, proc)
        AudioDeviceDestroyIOProcID(aggregateDeviceID, proc)
      }
      ioProcID = nil

      if aggregateDeviceID.isValid {
        AudioHardwareDestroyAggregateDevice(aggregateDeviceID)
        aggregateDeviceID = .unknown
      }

      if processTapID.isValid {
        AudioHardwareDestroyProcessTap(processTapID)
        processTapID = .unknown
      }
    } else {
      ioProcID = nil
      aggregateDeviceID = .unknown
      processTapID = .unknown
    }

    converter = nil
    inputFormat = nil
    outputFormat = nil
  }
}

// MARK: - CaptureError

/// Internal error type carrying a Flutter-friendly code + message.
private struct CaptureError: Error {
  let code: String
  let message: String
}

// MARK: - FrameStreamHandler

/// Bridges the EventChannel. The sink is only ever read/written on the main
/// thread (Flutter calls `onListen`/`onCancel` on the platform thread, and we
/// always `send` from `DispatchQueue.main`).
private class FrameStreamHandler: NSObject, FlutterStreamHandler {
  private var sink: FlutterEventSink?

  func onListen(
    withArguments arguments: Any?,
    eventSink events: @escaping FlutterEventSink
  ) -> FlutterError? {
    sink = events
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    sink = nil
    return nil
  }

  /// Emits one PCM buffer as raw bytes. Must be called on the main thread.
  func send(_ data: Data) {
    guard let sink = sink else { return }
    sink(FlutterStandardTypedData(bytes: data))
  }

  /// Emits a diagnostic error onto the stream (delivered to Dart's `onError`).
  /// Non-fatal: it does not end the stream. Must be called on the main thread.
  func sendError(code: String, message: String) {
    guard let sink = sink else { return }
    sink(FlutterError(code: code, message: message, details: nil))
  }
}

// MARK: - AudioObjectID Core Audio helpers
//
// These mirror the property-access patterns from Apple's "Capturing system
// audio with Core Audio taps" sample and the insidegui/AudioCap project,
// adapted to the exact selectors this plugin needs.

extension AudioObjectID {
  /// Convenience for `kAudioObjectSystemObject`.
  fileprivate static let system = AudioObjectID(kAudioObjectSystemObject)
  /// Convenience for `kAudioObjectUnknown`.
  fileprivate static let unknown = kAudioObjectUnknown

  /// `true` unless this is `kAudioObjectUnknown`.
  fileprivate var isValid: Bool { self != AudioObjectID.unknown }

  /// Reads `kAudioHardwarePropertyProcessObjectList` from the system object.
  fileprivate static func readProcessList() throws -> [AudioObjectID] {
    var address = AudioObjectPropertyAddress(
      mSelector: kAudioHardwarePropertyProcessObjectList,
      mScope: kAudioObjectPropertyScopeGlobal,
      mElement: kAudioObjectPropertyElementMain
    )

    var dataSize: UInt32 = 0
    var err = AudioObjectGetPropertyDataSize(
      AudioObjectID.system, &address, 0, nil, &dataSize
    )
    guard err == noErr else {
      throw CaptureError(code: "process_list_size", message: "size error \(err)")
    }

    let count = Int(dataSize) / MemoryLayout<AudioObjectID>.size
    var ids = [AudioObjectID](repeating: AudioObjectID.unknown, count: count)
    err = AudioObjectGetPropertyData(
      AudioObjectID.system, &address, 0, nil, &dataSize, &ids
    )
    guard err == noErr else {
      throw CaptureError(code: "process_list_read", message: "read error \(err)")
    }
    return ids
  }

  /// Reads `kAudioTapPropertyFormat` (the tap's real delivered ASBD).
  fileprivate func readAudioTapStreamBasicDescription() throws -> AudioStreamBasicDescription {
    var address = AudioObjectPropertyAddress(
      mSelector: kAudioTapPropertyFormat,
      mScope: kAudioObjectPropertyScopeGlobal,
      mElement: kAudioObjectPropertyElementMain
    )

    var dataSize = UInt32(MemoryLayout<AudioStreamBasicDescription>.size)
    var asbd = AudioStreamBasicDescription()
    let err = AudioObjectGetPropertyData(
      self, &address, 0, nil, &dataSize, &asbd
    )
    guard err == noErr else {
      throw CaptureError(code: "tap_format_read", message: "read error \(err)")
    }
    return asbd
  }

  /// `kAudioProcessPropertyIsRunning` — process has any active audio I/O.
  fileprivate func readProcessIsRunning() -> Bool {
    (try? readBool(kAudioProcessPropertyIsRunning)) ?? false
  }

  /// `kAudioProcessPropertyIsRunningOutput` — process is actively producing
  /// output audio (the signal we most want for a loopback recorder).
  fileprivate func readProcessIsRunningOutput() -> Bool {
    (try? readBool(kAudioProcessPropertyIsRunningOutput)) ?? false
  }

  /// Best-effort human-readable name for a process audio object: bundle id,
  /// falling back to the localized app name, falling back to the object id.
  fileprivate func readProcessDisplayName() -> String {
    if let bundleID = try? readString(kAudioProcessPropertyBundleID),
      !bundleID.isEmpty
    {
      // Resolve the bundle id to a localized app name when possible.
      if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID),
        let bundle = Bundle(url: url)
      {
        let displayName =
          (bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String)
          ?? (bundle.object(forInfoDictionaryKey: "CFBundleName") as? String)
        if let displayName = displayName, !displayName.isEmpty {
          return displayName
        }
      }
      return bundleID
    }
    return "Process \(self)"
  }

  // MARK: Generic typed reads

  private func readBool(_ selector: AudioObjectPropertySelector) throws -> Bool {
    var address = AudioObjectPropertyAddress(
      mSelector: selector,
      mScope: kAudioObjectPropertyScopeGlobal,
      mElement: kAudioObjectPropertyElementMain
    )
    var value: UInt32 = 0
    var dataSize = UInt32(MemoryLayout<UInt32>.size)
    let err = AudioObjectGetPropertyData(self, &address, 0, nil, &dataSize, &value)
    guard err == noErr else {
      throw CaptureError(code: "bool_read", message: "read error \(err)")
    }
    return value != 0
  }

  private func readString(_ selector: AudioObjectPropertySelector) throws -> String {
    var address = AudioObjectPropertyAddress(
      mSelector: selector,
      mScope: kAudioObjectPropertyScopeGlobal,
      mElement: kAudioObjectPropertyElementMain
    )
    // String-valued Core Audio properties return a single, +1-retained
    // CFStringRef (Create rule). Read it into an `Unmanaged<CFString>?` — a
    // trivial pointer wrapper, so forming `&` to it is safe — and take
    // ownership with `takeRetainedValue()` to balance the retain.
    var dataSize = UInt32(MemoryLayout<Unmanaged<CFString>?>.size)
    var cfString: Unmanaged<CFString>?
    let err = AudioObjectGetPropertyData(self, &address, 0, nil, &dataSize, &cfString)
    guard err == noErr, let result = cfString?.takeRetainedValue() else {
      throw CaptureError(code: "string_read", message: "read error \(err)")
    }
    return result as String
  }
}
