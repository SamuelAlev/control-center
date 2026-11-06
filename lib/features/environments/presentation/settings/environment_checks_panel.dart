import 'package:cc_domain/features/environments/domain/ports/environment_port.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/environments/presentation/settings/environment_form_fields.dart';
import 'package:control_center/features/environments/presentation/widgets/environment_command_box.dart';
import 'package:control_center/features/environments/presentation/widgets/environment_feedback.dart';
import 'package:control_center/features/environments/providers/environment_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Host readiness for a saved definition, with the commands that fix it.
class EnvironmentChecksPanel extends ConsumerWidget {
  /// Creates an [EnvironmentChecksPanel].
  const EnvironmentChecksPanel({super.key, required this.form});

  /// The draft.
  final EnvironmentForm form;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final record = form.state.record;
    if (record == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Text(
          l10n.environmentsTestSaveFirst,
          style: CcTypography.caption.copyWith(color: t.textTertiary),
        ),
      );
    }
    final key = (workspaceId: form.workspaceId, definitionId: record.id);
    final checks = ref.watch(environmentChecksProvider(key));
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: CcButton(
              variant: CcButtonVariant.secondary,
              size: CcButtonSize.sm,
              icon: AppIcons.refreshCw,
              loading: checks.isLoading,
              onPressed: () => ref.invalidate(environmentChecksProvider(key)),
              child: Text(l10n.environmentsRunChecks),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          checks.when(
            skipLoadingOnRefresh: true,
            loading: () => const SizedBox.shrink(),
            error: (error, _) => CcAlert(
              variant: CcAlertVariant.danger,
              title: environmentFailureMessage(error),
            ),
            data: (results) => results.isEmpty
                ? Text(
                    l10n.environmentsNoChecks,
                    style: CcTypography.caption.copyWith(color: t.textTertiary),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final result in results) _CheckRow(result: result),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _CheckRow extends StatelessWidget {
  const _CheckRow({required this.result});

  final EnvironmentCheckResult result;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final hint = result.hint;
    final fix = result.fix;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  result.label,
                  style: CcTypography.bodySm.copyWith(color: t.textPrimary),
                ),
              ),
              CcStatusTag(
                label: result.ok ? l10n.passed : l10n.failed,
                tone: result.ok ? CcStatusTone.positive : CcStatusTone.negative,
              ),
            ],
          ),
          if (!result.ok && hint != null)
            Text(
              hint,
              style: CcTypography.caption.copyWith(color: t.textTertiary),
            ),
          if (!result.ok && fix != null) ...[
            const SizedBox(height: AppSpacing.xxs),
            EnvironmentCommandBox(command: fix),
          ],
        ],
      ),
    );
  }
}
