import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/code_mode/presentation/code_mode_copy.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';

/// Why a script that did not complete ended: a sentence for the person,
/// then the record's `error_kind` as the machine value it is, for searching
/// logs and for support.
///
/// For a script that threw, the sentence names the error the script raised
/// ([errorName], from the record's payload). A kind this client has no
/// sentence for shows as its value alone.
class CodeExecutionEndReason extends StatelessWidget {
  /// Creates the line for [errorKind].
  const CodeExecutionEndReason({
    super.key,
    required this.errorKind,
    this.errorName,
  });

  /// The record's `error_kind`.
  final String errorKind;

  /// The name of the error the script threw, when it threw one.
  final String? errorName;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final reason = codeExecutionEndReason(
      l10n,
      errorKind,
      errorName: errorName,
    );
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xxs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (reason != null)
          Text(
            reason,
            style: CcTypography.bodySm.copyWith(color: t.textSecondary),
          ),
        // RTL carve-out: the error kind is a machine value.
        Directionality(
          textDirection: TextDirection.ltr,
          child: Text(
            errorKind,
            style: CcTypography.monoNum.copyWith(
              fontSize: 12,
              color: t.textTertiary,
            ),
          ),
        ),
      ],
    );
  }
}
