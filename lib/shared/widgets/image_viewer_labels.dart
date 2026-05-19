import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';

/// The localized strings for [CcExpandableImage] / [CcImageViewer].
///
/// cc_ui carries no localizations, so every surface that offers "expand this
/// image" has to hand it the same five strings. Resolving them in ONE place is
/// what keeps the affordance identical everywhere: a per-call-site literal is
/// how one surface ends up saying "Expand" and the next "View full size" for
/// the same control.
CcImageViewerLabels appImageViewerLabels(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  return CcImageViewerLabels(
    expand: l10n.expand,
    zoomIn: l10n.zoomIn,
    zoomOut: l10n.zoomOut,
    resetZoom: l10n.resetZoom,
    close: l10n.close,
  );
}
