#
# Flutter macOS plugin podspec for `system_audio_capture`.
#
# Captures system *output* audio (loopback) driver-free using Core Audio
# process taps (available on macOS 14.4+). No virtual audio driver
# (BlackHole etc.) and no ScreenCaptureKit are involved.
#
# The deployment target is intentionally low (10.14) so the plugin links into
# host apps that target older macOS versions. All Core Audio tap entry points
# are runtime-gated behind `if #available(macOS 14.4, *)` in the Swift code,
# so the binary loads everywhere and simply reports `isSupported == false`
# on systems older than 14.4.
#
Pod::Spec.new do |s|
  s.name             = 'system_audio_capture'
  s.version          = '0.0.1'
  s.summary          = 'Driver-free system audio (loopback) capture via Core Audio process taps.'
  s.description      = <<-DESC
Captures the macOS system output mixdown (or a single process) as raw PCM using
the Core Audio taps API introduced in macOS 14.4. Downmixes/resamples to
16 kHz mono signed 16-bit PCM and streams frames to Flutter over an EventChannel.
                       DESC
  s.homepage         = 'https://controlcenter.dev'
  s.license          = { :type => 'MIT' }
  s.author           = { 'Control Center' => 'dev@controlcenter.dev' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'FlutterMacOS'

  s.platform = :osx, '10.14'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'

  # Core Audio taps live in CoreAudio/AudioToolbox; AVAudioConverter (used for
  # the format conversion) lives in AVFoundation.
  s.frameworks = 'AVFoundation', 'CoreAudio', 'AudioToolbox'
end
