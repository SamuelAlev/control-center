import 'package:cc_domain/core/domain/entities/agent_working_memory.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/memory/presentation/widgets/memory_error_view.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

/// Editable private scratch-memory for a single agent.
class AgentWorkingMemoryPanel extends ConsumerStatefulWidget {
  /// Creates an [AgentWorkingMemoryPanel].
  const AgentWorkingMemoryPanel({
    super.key,
    required this.workspaceId,
    required this.agentId,
  });

  /// Workspace the agent belongs to.
  final String workspaceId;

  /// Agent whose working memory is shown.
  final String agentId;

  @override
  ConsumerState<AgentWorkingMemoryPanel> createState() =>
      _AgentWorkingMemoryPanelState();
}

class _AgentWorkingMemoryPanelState
    extends ConsumerState<AgentWorkingMemoryPanel> {
  final _controller = TextEditingController();
  bool _isEditing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AgentWorkingMemory?>(
      future: ref
          .read(agentWorkingMemoryRepositoryProvider)
          .getByAgent(widget.workspaceId, widget.agentId),
      builder: (context, snapshot) {
        final memory = snapshot.data;
        final l10n = AppLocalizations.of(context);
        final tokens = context.designSystem ?? DesignSystemTokens.light();

        if (snapshot.hasError) {
          return MemoryErrorView(
            error: snapshot.error!,
            onRetry: () => setState(() {}),
          );
        }

        if (!_isEditing && memory != null) {
          _controller.text = memory.content;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  Icon(AppIcons.notebook,
                      size: 16, color: tokens.fgBrandPrimary),
                  const SizedBox(width: AppSpacing.sm),
                  Text(l10n.workingMemory,
                      style: CcTypography.body.copyWith(
                        color: tokens.textPrimary,
                        fontWeight: FontWeight.w700,
                      )),
                  const Spacer(),
                  if (!_isEditing)
                    CcButton(
                      onPressed: () => setState(() => _isEditing = true),
                      variant: CcButtonVariant.secondary,
                      size: CcButtonSize.sm,
                      icon: AppIcons.pencil,
                      child: Text(l10n.edit),
                    ),
                ],
              ),
            ),
            Expanded(
              child: _isEditing
                  ? _buildEditor(context)
                  : _buildViewer(context, memory?.content ?? ''),
            ),
          ],
        );
      },
    );
  }

  Widget _buildViewer(BuildContext context, String content) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    if (content.isEmpty) {
      return EmptyState(
        icon: AppIcons.notebookPen,
        iconSize: 36,
        message: AppLocalizations.of(context).noWorkingMemory,
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Text(
        content,
        style: CcTypography.body.copyWith(
          color: tokens.textSecondary,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildEditor(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.notes),
                const SizedBox(height: 6),
                Expanded(
                  child: CcTextArea(
                    controller: _controller,
                    hintText: l10n.writePrivateNotes,
                    minLines: 8,
                    maxLines: null,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              CcButton(
                onPressed: () => setState(() => _isEditing = false),
                variant: CcButtonVariant.secondary,
                size: CcButtonSize.sm,
                child: Text(l10n.cancel),
              ),
              const SizedBox(width: 8),
              CcButton(
                onPressed: _save,
                size: CcButtonSize.sm,
                child: Text(l10n.save),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final repo = ref.read(agentWorkingMemoryRepositoryProvider);
    final existing = await repo.getByAgent(widget.workspaceId, widget.agentId);

    final memory = AgentWorkingMemory(
      id: existing?.id ?? const Uuid().v4(),
      workspaceId: widget.workspaceId,
      agentId: widget.agentId,
      content: _controller.text,
      updatedAt: DateTime.now(),
    );

    await repo.upsert(memory);
    if (mounted) {
      setState(() => _isEditing = false);
    }
  }
}
