import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';

/// The install / cancel / redownload / remove buttons for one on-device
/// model, driven by its lifecycle state.
class ModelActions extends StatelessWidget {
  /// Creates a [ModelActions].
  const ModelActions({
    super.key,
    required this.isInstalled,
    required this.isDownloading,
    required this.onInstall,
    required this.onCancel,
    required this.onReinstall,
    required this.onRemove,
  });

  /// Whether the model is on disk.
  final bool isInstalled;

  /// Whether a download is in flight.
  final bool isDownloading;

  /// Starts the download.
  final VoidCallback onInstall;

  /// Aborts an in-flight download.
  final VoidCallback onCancel;

  /// Removes and re-downloads.
  final VoidCallback onReinstall;

  /// Deletes the local copy.
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (isDownloading) {
      return CcButton(
        onPressed: onCancel,
        variant: CcButtonVariant.secondary,
        child: Text(l10n.cancel),
      );
    }
    if (isInstalled) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CcButton(
            onPressed: onRemove,
            variant: CcButtonVariant.destructive,
            child: Text(l10n.remove),
          ),
          const SizedBox(width: 8),
          CcButton(
            onPressed: onReinstall,
            variant: CcButtonVariant.secondary,
            icon: AppIcons.refreshCw,
            child: Text(l10n.redownload),
          ),
        ],
      );
    }
    return CcButton(
      onPressed: onInstall,
      icon: AppIcons.download,
      child: Text(l10n.install),
    );
  }
}
