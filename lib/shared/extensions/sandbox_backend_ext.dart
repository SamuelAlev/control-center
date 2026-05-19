import 'package:control_center/core/domain/value_objects/sandbox_backend.dart';
import 'package:control_center/l10n/app_localizations.dart';

/// Presentation-layer extension for [SandboxBackend] providing localized
/// labels. Kept out of the domain value object so [SandboxBackend] stays
/// free of `AppLocalizations`.
extension SandboxBackendLabel on SandboxBackend {
  /// Localized label for UI contexts where [AppLocalizations] is available.
  String resolvedLabel(AppLocalizations l10n) {
    switch (this) {
      case SandboxBackend.native:
        return l10n.sandboxBackendNativeLabel;
      case SandboxBackend.none:
        return l10n.sandboxBackendNoneLabel;
    }
  }
}
