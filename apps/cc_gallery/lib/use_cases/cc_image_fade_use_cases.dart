import 'dart:typed_data';

import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

/// Use-cases for [CcImageFade] — the cross-fading remote-image surface.
///
/// It exists because a re-resolving image otherwise BLINKS: the placeholder is
/// held behind the frame and an already-cached image appears instantly rather
/// than re-fading on every rebuild. The states worth seeing are therefore
/// loading, loaded and FAILED — the last one is the common case for a remote
/// avatar or feed thumbnail.

const _path = '[Primitives]';

/// A 1×1 transparent PNG: decodes successfully, so it stands in for "loaded".
final _okImage = MemoryImage(
  Uint8List.fromList(const [
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, //
    0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
    0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
    0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
    0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41,
    0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
    0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
    0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
    0x42, 0x60, 0x82,
  ]),
);

/// Empty bytes: guaranteed to fail decode, so the error branch renders.
final _brokenImage = MemoryImage(Uint8List(0));

Widget _tile(BuildContext context, String label, Widget child) {
  final t = context.ds;
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      SizedBox(width: 96, height: 96, child: child),
      const SizedBox(height: AppSpacing.xs),
      Text(label, style: CcTypography.caption.copyWith(color: t.textTertiary)),
    ],
  );
}

/// Loaded, failed and placeholder-only, side by side.
@widgetbook.UseCase(name: 'States', type: CcImageFade, path: _path)
Widget ccImageFadeStatesUseCase(BuildContext context) {
  final t = context.ds;
  final placeholder = ColoredBox(color: t.bgTertiary);
  return Center(
    child: Wrap(
      spacing: 24,
      runSpacing: 24,
      children: [
        _tile(
          context,
          'Loaded',
          CcImageFade(image: _okImage, placeholder: placeholder),
        ),
        _tile(
          context,
          'Failed → fallback',
          CcImageFade(
            image: _brokenImage,
            placeholder: placeholder,
            errorBuilder: (context, error) => ColoredBox(
              color: t.bgTertiary,
              child: Center(
                child: Icon(
                  CcIcons.triangleAlert,
                  size: 20,
                  color: t.textTertiary,
                ),
              ),
            ),
          ),
        ),
        _tile(context, 'Placeholder', placeholder),
      ],
    ),
  );
}

/// Interactive playground — drive every knob to see the full state space.
@widgetbook.UseCase(name: 'Playground', type: CcImageFade, path: _path)
Widget ccImageFadePlaygroundUseCase(BuildContext context) {
  final t = context.ds;
  final broken = context.knobs.boolean(label: 'Broken image');
  final ms = context.knobs.int.slider(
    label: 'Fade duration (ms)',
    initialValue: 300,
    max: 2000,
  );
  final size = context.knobs.double.slider(
    label: 'Size',
    initialValue: 120,
    min: 32,
    max: 240,
  );
  return Center(
    child: SizedBox(
      width: size,
      height: size,
      child: CcImageFade(
        image: broken ? _brokenImage : _okImage,
        placeholder: ColoredBox(color: t.bgTertiary),
        duration: Duration(milliseconds: ms),
        errorBuilder: (context, error) => ColoredBox(
          color: t.bgTertiary,
          child: Center(
            child: Icon(CcIcons.triangleAlert, size: 20, color: t.textTertiary),
          ),
        ),
      ),
    ),
  );
}
