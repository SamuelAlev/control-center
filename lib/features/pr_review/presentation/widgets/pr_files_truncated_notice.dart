import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/utils/open_url.dart';
import 'package:flutter/widgets.dart';

/// Says the diff on screen is partial: the forge capped its file listing at
/// [shownCount], so the rest of the change is only on the forge.
///
/// Shown above the files when `PrFilesLoad.truncated` is set, with a link to
/// the pull request on [forge] ([htmlUrl]).
class PrFilesTruncatedNotice extends StatelessWidget {
  /// Creates a [PrFilesTruncatedNotice].
  const PrFilesTruncatedNotice({
    super.key,
    required this.forge,
    required this.shownCount,
    required this.htmlUrl,
  });

  /// The PR's forge, named in the copy.
  final ForgeHost forge;

  /// How many files the forge listed.
  final int shownCount;

  /// The pull request on the forge; the link is hidden when empty.
  final String htmlUrl;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(24, 8, 24, 0),
      child: CcAlert(
        variant: CcAlertVariant.warning,
        title: l10n.prFilesTruncatedNotice(forge.displayName, shownCount),
        trailing: htmlUrl.isEmpty
            ? null
            : CcButton(
                variant: CcButtonVariant.ghost,
                size: CcButtonSize.sm,
                icon: AppIcons.externalLink,
                onPressed: () => openExternalUrl(htmlUrl),
                child: Text(l10n.openOnForge(forge.displayName)),
              ),
      ),
    );
  }
}
