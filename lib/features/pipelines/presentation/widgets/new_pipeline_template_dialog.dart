import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pipelines/presentation/widgets/max_parallel_runs_field.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';

/// What [showNewPipelineTemplateDialog] collects before the editor opens.
class NewPipelineTemplateDraft {
  /// Creates a [NewPipelineTemplateDraft].
  const NewPipelineTemplateDraft({
    required this.templateId,
    this.maxParallelRuns,
  });

  /// Identifier the new template is created under.
  final String templateId;

  /// Run-concurrency cap, or null for unlimited.
  final int? maxParallelRuns;
}

/// Asks for a new template's id and run-concurrency cap. Returns null when
/// dismissed.
Future<NewPipelineTemplateDraft?> showNewPipelineTemplateDialog(
  BuildContext context,
) {
  return showCcDialog<NewPipelineTemplateDraft>(
    context: context,
    builder: (ctx) => const _NewPipelineTemplateDialog(),
  );
}

/// Collects the id and the run-concurrency cap for a brand-new template.
///
/// The cap is offered here rather than only in the editor's run settings so a
/// pipeline that must not fan out (an indexer, a deploy) can be created capped
/// instead of being capped after its first uncapped runs.
class _NewPipelineTemplateDialog extends StatefulWidget {
  const _NewPipelineTemplateDialog();

  @override
  State<_NewPipelineTemplateDialog> createState() =>
      _NewPipelineTemplateDialogState();
}

class _NewPipelineTemplateDialogState
    extends State<_NewPipelineTemplateDialog> {
  final _idCtrl = TextEditingController();
  final _maxParallelCtrl = TextEditingController();
  String? _maxParallelError;

  @override
  void dispose() {
    _idCtrl.dispose();
    _maxParallelCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final templateId = _idCtrl.text.trim();
    if (templateId.isEmpty) {
      return;
    }
    final parsed = parseMaxParallelRuns(_maxParallelCtrl.text);
    if (parsed.isInvalid) {
      setState(
        () => _maxParallelError = AppLocalizations.of(
          context,
        ).pipelineRunSettingsMaxParallelInvalid,
      );
      return;
    }
    Navigator.pop(
      context,
      NewPipelineTemplateDraft(
        templateId: templateId,
        maxParallelRuns: parsed.value,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return CcDialog(
      title: l10n.pipelineTemplatesNew,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.pipelineTemplateIdLabel),
          const SizedBox(height: 6),
          CcTextField(
            controller: _idCtrl,
            hintText: 'my_pipeline',
            autofocus: true,
          ),
          const SizedBox(height: 16),
          MaxParallelRunsField(
            controller: _maxParallelCtrl,
            errorText: _maxParallelError,
            onChanged: (_) {
              if (_maxParallelError != null) {
                setState(() => _maxParallelError = null);
              }
            },
          ),
        ],
      ),
      actions: [
        CcButton(
          onPressed: () => Navigator.pop(context),
          variant: CcButtonVariant.secondary,
          child: Text(l10n.cancel),
        ),
        CcButton(onPressed: _submit, child: Text(l10n.create)),
      ],
    );
  }
}
