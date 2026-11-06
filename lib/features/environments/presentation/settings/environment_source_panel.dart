import 'dart:async';
import 'dart:convert';

import 'package:cc_data/cc_data.dart' show EnvironmentSourceUpdate;
import 'package:cc_domain/features/environments/domain/entities/environment_definition_record.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/environments/presentation/settings/environment_editor_state.dart';
import 'package:control_center/features/environments/presentation/settings/environment_form_fields.dart';
import 'package:control_center/features/environments/presentation/widgets/environment_feedback.dart';
import 'package:control_center/features/environments/providers/environment_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/transcript/widgets/inline_diff_view.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The approved blob next to what the default branch holds now.
///
/// Merging is not approval: nothing runs until an admin approves this diff.
class EnvironmentSourcePanel extends ConsumerStatefulWidget {
  /// Creates an [EnvironmentSourcePanel].
  const EnvironmentSourcePanel({super.key, required this.form});

  /// The draft.
  final EnvironmentForm form;

  @override
  ConsumerState<EnvironmentSourcePanel> createState() =>
      _EnvironmentSourcePanelState();
}

class _EnvironmentSourcePanelState
    extends ConsumerState<EnvironmentSourcePanel> {
  bool _approving = false;

  Future<void> _approve(EnvironmentDefinitionRecord record) async {
    final toasts = CcToastScope.maybeOf(context);
    final overrides = record.overridesJson;
    setState(() => _approving = true);
    try {
      await ref
          .read(environmentRepositoryProvider)
          .approveSource(
            record.workspaceId,
            definitionId: record.id,
            repoId: record.sourceRepoId!,
            path: record.sourcePath!,
            overrides: overrides == null
                ? null
                : Map<String, dynamic>.from(jsonDecode(overrides) as Map),
          );
      ref
        ..invalidate(environmentDefinitionsProvider(record.workspaceId))
        ..invalidate(
          environmentSourceUpdateProvider((
            workspaceId: record.workspaceId,
            definitionId: record.id,
          )),
        );
    } on Object catch (error) {
      toasts?.show(
        environmentFailureMessage(error),
        variant: CcToastVariant.danger,
      );
    } finally {
      if (mounted) {
        setState(() => _approving = false);
      }
    }
  }

  /// The approved side, pretty-printed the same way as the current one.
  String _approvedText(
    EnvironmentDefinitionRecord record,
    EnvironmentSourceUpdate update,
  ) {
    final text = update.approvedContent ?? record.definitionJson;
    try {
      return environmentPrettyJson(jsonDecode(text));
    } on FormatException {
      return text;
    }
  }

  /// The file's text, pretty-printed like the approved side when it parses, so
  /// the diff shows content changes rather than formatting.
  String _currentText(EnvironmentSourceUpdate update) {
    try {
      return environmentPrettyJson(jsonDecode(update.content));
    } on FormatException {
      return update.content;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final record = widget.form.state.record;
    if (record == null || !record.hasSource) {
      return const SizedBox.shrink();
    }
    final update = ref.watch(
      environmentSourceUpdateProvider((
        workspaceId: record.workspaceId,
        definitionId: record.id,
      )),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: update.when(
        loading: () => const Center(child: CcSpinner()),
        error: (error, _) => CcAlert(
          variant: CcAlertVariant.danger,
          title: environmentFailureMessage(error),
        ),
        data: (source) {
          final caption = CcTypography.caption.copyWith(color: t.textTertiary);
          if (source == null || !source.hasUpdate) {
            return Text(
              l10n.environmentsSourceCurrent(record.sourcePath ?? ''),
              style: caption,
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.environmentsSourceNotice, style: caption),
              const SizedBox(height: AppSpacing.sm),
              // RTL carve-out: a diff reads left to right in every locale.
              Directionality(
                textDirection: TextDirection.ltr,
                child: InlineDiffView(
                  oldText: _approvedText(record, source),
                  newText: _currentText(source),
                  codeFont: CcFonts.codeFamily,
                  tokens: t,
                  maxHeight: 420,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: CcButton(
                  size: CcButtonSize.sm,
                  loading: _approving,
                  onPressed: _approving || !widget.form.enabled
                      ? null
                      : () => unawaited(_approve(record)),
                  child: Text(l10n.environmentsSourceApprove),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
