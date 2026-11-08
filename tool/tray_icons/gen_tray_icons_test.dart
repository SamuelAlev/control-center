// Generator for assets/tray/*.png, the tray (menu bar) glyphs that
// lib/app/tray/tray_icon_host.dart loads. Run from the repo root after the
// figure in assets/logo_white.svg changes:
//
//   fvm flutter test --concurrency=1 tool/tray_icons/gen_tray_icons_test.dart
//
// A test only because it needs Flutter's renderer for the SVG; it lives
// outside test/ so the suite never runs it.
//
// The glyph is assets/logo_white.svg traced as it is, drop shadow stripped:
// one template image in black, which every platform recolors to its bar's
// ink (AppKit for the menu bar, nativeapi for the Windows taskbar and the
// StatusNotifierItem host), so only the alpha matters. Three tones: plain,
// with the attention dot, and dimmed for offline.
//
// Preview sheets at real tray sizes (16-36px, blown up 4x) go to
// build/tray_icons/, on a dark and a light bar, plus compare.png with the
// figure at a few stroke weights for judging how far the suspension lines
// may thin before they melt.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

const _source = 'assets/logo_white.svg';
const _assetDir = 'assets/tray';
const _previewDir = 'build/tray_icons';

/// The PNGs' edge. macOS shows them at 18pt, so 36px on a Retina bar; the
/// Windows taskbar at 16-24px; StatusNotifierItem hosts at 16-32px.
const int _px = 64;

/// Stroke, in the logo's 810-unit viewBox, the shipped glyph is traced with:
/// a hair, in the fill's own ink, that keeps the suspension lines whole at
/// 16px without thickening the figure.
const double _stroke = 3;

/// Alpha of the offline glyph: present, but plainly not live.
const double _offlineAlpha = 0.4;

Future<ui.Picture> _glyph({double stroke = _stroke}) async {
  var svg = File(_source).readAsStringSync();
  // The shadow's definition and its uses: a template is alpha only.
  svg = svg
      .replaceAll(RegExp(r'<defs>.*?</defs>', dotAll: true), '')
      .replaceAll('filter="url(#personShadow)"', '');
  svg = svg.replaceAll(
    'fill="#ffffff"',
    stroke == 0
        ? 'fill="#000000"'
        : 'fill="#000000" stroke="#000000" stroke-width="$stroke" '
              'stroke-linejoin="round"',
  );
  final info = await vg.loadPicture(SvgStringLoader(svg), null);
  return info.picture;
}

void _drawGlyph(Canvas canvas, ui.Picture glyph, Rect rect) {
  canvas
    ..save()
    ..translate(rect.left, rect.top)
    ..scale(rect.width / 810, rect.height / 810)
    ..drawPicture(glyph)
    ..restore();
}

/// A dot in the bottom-end corner (the empty one beside the pilot's legs,
/// where it cuts nothing of the canopy), entirely inside the canvas, with a
/// clear ring punched into the glyph around it so it reads at 16px.
void _attentionDot(Canvas canvas, Size size) {
  final r = size.width * 0.14;
  final c = Offset(size.width - r - 1, size.height - r - 1);
  canvas
    ..drawCircle(c, r + size.width * 0.07, Paint()..blendMode = BlendMode.clear)
    ..drawCircle(c, r, Paint()..color = const Color(0xFF000000));
}

Future<ui.Image> _render({
  double stroke = _stroke,
  bool dot = false,
  double alpha = 1,
}) async {
  final recorder = ui.PictureRecorder();
  const size = Size(_px * 1.0, _px * 1.0);
  final canvas = Canvas(recorder, Offset.zero & size)
    // Dimming the whole layer, dot included, keeps the punched ring clear.
    ..saveLayer(
      Offset.zero & size,
      Paint()..color = Color.fromRGBO(0, 0, 0, alpha),
    );
  final glyph = await _glyph(stroke: stroke);
  // The figure fills its viewBox edge to edge; a pixel of inset keeps the
  // canopy's anti-aliasing off the image edge.
  _drawGlyph(canvas, glyph, const Rect.fromLTWH(1, 1, _px - 2.0, _px - 2.0));
  if (dot) {
    _attentionDot(canvas, size);
  }
  canvas.restore();
  return recorder.endRecording().toImage(_px, _px);
}

Future<void> _save(String dir, String name, ui.Image image) async {
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  File('$dir/$name.png')
    ..createSync(recursive: true)
    ..writeAsBytesSync(bytes!.buffer.asUint8List());
}

/// Each icon at the platforms' sizes, recolored to [ink] as a template
/// would be, on a [bar], blown up 4x (nearest neighbour) so single pixels
/// are inspectable.
Future<void> _preview(
  String name,
  List<ui.Image> icons,
  Color bar,
  Color ink,
) async {
  const sizes = [16, 18, 22, 32, 36];
  const scale = 4.0;
  const pad = 8.0;
  const cell = 36.0;
  final width = (sizes.fold<double>(0, (a, s) => a + s + pad) + pad) * scale;
  final height = (icons.length * (cell + pad) + pad) * scale;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder)
    ..drawRect(Rect.fromLTWH(0, 0, width, height), Paint()..color = bar);
  for (var row = 0; row < icons.length; row++) {
    var x = pad;
    for (final s in sizes) {
      // Downscale smoothly first, as the platforms do, then enlarge crisply.
      final small = ui.PictureRecorder();
      Canvas(small).drawImageRect(
        icons[row],
        const Rect.fromLTWH(0, 0, _px * 1.0, _px * 1.0),
        Rect.fromLTWH(0, 0, s.toDouble(), s.toDouble()),
        Paint()
          ..filterQuality = FilterQuality.medium
          ..colorFilter = ColorFilter.mode(ink, BlendMode.srcIn),
      );
      final img = await small.endRecording().toImage(s, s);
      final y = pad + row * (cell + pad) + (cell - s) / 2;
      canvas.drawImageRect(
        img,
        Rect.fromLTWH(0, 0, s.toDouble(), s.toDouble()),
        Rect.fromLTWH(x * scale, y * scale, s * scale, s * scale),
        Paint()..filterQuality = FilterQuality.none,
      );
      x += s + pad;
    }
  }
  final image = await recorder.endRecording().toImage(
    width.round(),
    height.round(),
  );
  await _save(_previewDir, name, image);
}

void main() {
  test('renders the tray glyphs', () async {
    final tones = {
      'tray': await _render(),
      'tray_attention': await _render(dot: true),
      'tray_offline': await _render(alpha: _offlineAlpha),
    };
    for (final MapEntry(:key, :value) in tones.entries) {
      await _save(_assetDir, key, value);
    }
    const white = Color(0xFFFFFFFF);
    const black = Color(0xFF000000);
    final icons = tones.values.toList();
    await _preview('preview_on_dark', icons, const Color(0xFF1F1F1F), white);
    await _preview('preview_on_light', icons, const Color(0xFFF0F0F0), black);
    await _preview(
      'compare',
      [
        for (final stroke in const [0.0, 3.0, 6.0, 10.0])
          await _render(stroke: stroke),
      ],
      const Color(0xFF1F1F1F),
      white,
    );
  });
}
