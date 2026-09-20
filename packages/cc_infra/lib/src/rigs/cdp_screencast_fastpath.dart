import 'dart:convert';
import 'dart:typed_data';

/// Lexical shortcut for a Chromium `Page.screencastFrame` socket frame.
///
/// Only the method name, the `data` field and `sessionId` are read. The
/// `metadata` block is unused by any consumer, and it is the reason the
/// generic path had to build a map of a 50–500 KB payload.
///
/// Returns null when the frame is anything else, or when its shape is not
/// the one Chromium emits — the caller then takes the ordinary decode
/// path, so this can only ever be a shortcut, never a behaviour change.
///
/// `start` for `lastIndexOf` MUST be clamped to the frame length:
/// `lastIndexOf` throws a RangeError for a start past the end, and an
/// exception in the frame loop hangs every pending command.
({Uint8List bytes, int sessionId})? parseCdpScreencastFastpath(String frame) {
  const probeLimit = 200;
  final probeStart = frame.length < probeLimit ? frame.length : probeLimit;
  if (frame.lastIndexOf('"Page.screencastFrame"', probeStart) < 0) {
    return null;
  }
  const dataKey = '"data":"';
  final dataStart = frame.indexOf(dataKey);
  if (dataStart < 0) {
    return null;
  }
  final valueStart = dataStart + dataKey.length;
  final valueEnd = frame.indexOf('"', valueStart);
  if (valueEnd < 0) {
    return null;
  }
  const sessionKey = '"sessionId":';
  final sessionStart = frame.indexOf(sessionKey);
  var sessionId = -1;
  if (sessionStart >= 0) {
    var i = sessionStart + sessionKey.length;
    while (i < frame.length && frame.codeUnitAt(i) == 0x20) {
      i++;
    }
    var value = 0;
    var digits = 0;
    while (i < frame.length) {
      final c = frame.codeUnitAt(i);
      if (c < 0x30 || c > 0x39) {
        break;
      }
      value = value * 10 + (c - 0x30);
      digits++;
      i++;
    }
    if (digits > 0) {
      sessionId = value;
    }
  }
  try {
    return (
      bytes: base64.decoder.convert(frame, valueStart, valueEnd),
      sessionId: sessionId,
    );
  } on FormatException {
    return null;
  }
}
