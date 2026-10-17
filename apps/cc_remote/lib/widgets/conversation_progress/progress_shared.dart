import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';

Widget progressHeading(DesignSystemTokens t, String text) => Padding(
  padding: const EdgeInsets.only(bottom: 10),
  child: Text(text, style: CcTypography.title.copyWith(color: t.textPrimary)),
);

Widget progressError(AppLocalizations l, Object error, VoidCallback retry) =>
    CcAlert(
      title: l.progressLoadFailed,
      description: Text('$error'),
      variant: CcAlertVariant.danger,
      action: CcButton(
        size: CcButtonSize.lg,
        onPressed: retry,
        child: Text(l.retry),
      ),
    );

String progressPreview(String source) =>
    source.length > 6000 ? '${source.substring(0, 6000)}…' : source;
