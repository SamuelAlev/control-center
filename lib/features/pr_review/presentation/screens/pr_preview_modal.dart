import 'package:control_center/di/providers.dart';
import 'package:control_center/features/pr_review/presentation/widgets/diff_summary_card.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Modal dialog for creating a new pull request draft.
class PrPreviewModal extends ConsumerStatefulWidget {
  /// Creates a PR preview modal for [workspaceId].
  const PrPreviewModal({super.key, required this.workspaceId});

  /// The workspace the PR belongs to.
  final String workspaceId;

  @override
  ConsumerState<PrPreviewModal> createState() => _PrPreviewModalState();
}

class _PrPreviewModalState extends ConsumerState<PrPreviewModal> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _titleController.text = '';
    _bodyController.text = '';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return FDialog.raw(
      constraints: const BoxConstraints(maxWidth: 640, maxHeight: 600),
      builder: (context, style) => SizedBox(
        width: 640,
        height: 600,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    LucideIcons.gitPullRequest,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Create pull request',
                    style: theme.textTheme.titleLarge,
                  ),
                  const Spacer(),
                  FButton.icon(
                    onPress: () => Navigator.of(context).pop(),
                    child: const Icon(LucideIcons.x, size: 16),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              FTextField(
                control: FTextFieldControl.managed(
                  controller: _titleController,
                ),
                label: Text(l10n.titleLabel),
                hint: l10n.prTitle,
              ),
              const SizedBox(height: 12),
              Text(l10n.titleDescription, style: theme.textTheme.labelMedium),
              const SizedBox(height: 6),
              Expanded(
                child: FTextField(
                  control: FTextFieldControl.managed(
                    controller: _bodyController,
                  ),
                  label: Text(l10n.titleDescription),
                  hint: l10n.prDescriptionPlaceholder,
                  minLines: 5,
                  maxLines: null,
                ),
              ),
              const SizedBox(height: 16),
              const DiffSummaryCard(
                filesChanged: 5,
                additions: 120,
                deletions: 30,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FButton(
                    onPress: () => Navigator.of(context).pop(),
                    variant: FButtonVariant.secondary,
                    mainAxisSize: MainAxisSize.min,
                    child: Text(l10n.cancel),
                  ),
                  const SizedBox(width: 8),
                  FButton(
                    onPress: _isCreating ? null : _createPr,
                    mainAxisSize: MainAxisSize.min,
                    prefix: _isCreating
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: FCircularProgress(),
                          )
                        : const Icon(LucideIcons.gitPullRequest),
                    child: Text(l10n.createPr),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createPr() async {
    setState(() => _isCreating = true);
    try {
      final repo = ref.read(prLifecycleRepositoryProvider);
      await repo.createDraft(
        workspaceId: widget.workspaceId,
        title: _titleController.text.trim(),
        body: _bodyController.text.trim(),
        diffSummary: '5 files changed, +120, -30',
      );
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).prDraftCreated)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).failedWithError('$e'))));
      }
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }
}
