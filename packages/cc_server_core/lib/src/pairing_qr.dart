import 'dart:convert';

import 'package:qr/qr.dart';

/// Builds the web-client pairing deep link `<clientUrl>/#<payload>`.
///
/// The payload is base64url-encoded JSON `{s, i, k}` (server / device id / PSK)
/// riding in the **fragment**, matching the keys `main_web.dart`'s
/// `_readUrlHints` parses (`parsed['s']`, `parsed['i']`, `parsed['k']`). The
/// fragment keeps the PSK off the static host — the web client reads it, then
/// strips it from the URL. Padding is dropped (`=`); the client re-pads before
/// decoding.
String buildWebClientDeepLink({
  required String clientUrl,
  required String serverUrl,
  required String deviceId,
  required String psk,
}) {
  final payload = base64Url
      .encode(utf8.encode(jsonEncode({'s': serverUrl, 'i': deviceId, 'k': psk})))
      .replaceAll('=', '');
  final base = clientUrl.trim().replaceAll(RegExp(r'/+$'), '');
  return '$base/#$payload';
}

/// Renders [data] as a QR code for the terminal using Unicode half-blocks.
///
/// Each printed row packs two QR rows into one `▀` cell: the upper half (the
/// glyph) takes the foreground color, the lower half the background. Dark
/// modules render black, light modules bright-white — so the QR keeps its
/// standard dark-on-light orientation regardless of the terminal's own theme
/// (we set both colors explicitly via 16-color SGR, the most widely supported).
/// [margin] is the light quiet-zone in modules (4 is the spec; 2 scans fine and
/// is more compact). [errorCorrectLevel] defaults to medium.
String renderQrToAnsi(
  String data, {
  int margin = 2,
  int errorCorrectLevel = QrErrorCorrectLevel.M,
}) {
  final qr = QrImage(
    QrCode.fromData(data: data, errorCorrectLevel: errorCorrectLevel),
  );
  final n = qr.moduleCount;
  final size = n + margin * 2;

  // True for a light (white) module; quiet-zone (out of range) is light.
  bool light(int row, int col) {
    final r = row - margin;
    final c = col - margin;
    if (r < 0 || c < 0 || r >= n || c >= n) {
      return true;
    }
    return !qr.isDark(r, c);
  }

  const reset = '\x1b[0m';
  final sb = StringBuffer();
  for (var row = 0; row < size; row += 2) {
    for (var col = 0; col < size; col++) {
      final topLight = light(row, col);
      final bottomLight = row + 1 < size ? light(row + 1, col) : true;
      // fg = upper half (top module), bg = lower half (bottom module).
      final fg = topLight ? '97' : '30'; // bright-white / black
      final bg = bottomLight ? '107' : '40';
      sb.write('\x1b[$fg;${bg}m▀');
    }
    sb
      ..write(reset)
      ..write('\n');
  }
  return sb.toString();
}
