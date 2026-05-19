import 'package:cc_domain/features/settings/domain/services/branch_template_resolver.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/settings/providers/workspace_settings_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Workspace → General: the branch-name template for ticket worktrees.
///
/// Used when an isolated worktree is provisioned for a ticket. Supports
/// `{type}`, `{ticket-key}`, `{slug}` placeholders.
///
/// **Workspace-scoped**, not per-device: it names branches in repositories every
/// member shares, so two people must not generate differently-shaped branches
/// for the same kind of work. It previously lived in device-local preferences
/// AND never reached `RepoWorkspaceProvisioner`, which hardcoded the built-in
/// default — so editing it did nothing whatsoever.
///
/// Writes are debounced rather than per-keystroke: each one is an admin-gated
/// RPC round trip that every other member's client observes.
class BranchTemplateSection extends ConsumerStatefulWidget {
  /// Creates a [BranchTemplateSection].
  const BranchTemplateSection({super.key});

  @override
  ConsumerState<BranchTemplateSection> createState() =>
      _BranchTemplateSectionState();
}

class _BranchTemplateSectionState extends ConsumerState<BranchTemplateSection> {
  final TextEditingController _controller = TextEditingController();
  String? _seededValue;
  bool _dirty = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Seeds the field from the server once and re-seeds when the stored value
  /// changes underneath an untouched field (another admin edited it). Never
  /// while the operator is mid-edit.
  void _seed(String? stored) {
    final value = stored ?? '';
    if (_dirty || _seededValue == value) {
      return;
    }
    _seededValue = value;
    _controller.text = value;
  }

  Future<void> _save() async {
    final text = _controller.text.trim();
    await setWorkspaceSetting(
      ref,
      branchTemplateSettingKey,
      // Clearing the field restores the built-in default rather than storing an
      // empty template, which would resolve to an unusable branch name.
      text.isEmpty ? null : text,
    );
    if (mounted) {
      setState(() {
        _dirty = false;
        _seededValue = text;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.designSystem;
    final workspaceId = ref.watch(activeWorkspaceIdProvider);
    final isAdmin =
        workspaceId != null &&
        (ref.watch(myWorkspaceRoleProvider(workspaceId))?.isAdmin ?? false);

    _seed(ref.watch(workspaceBranchTemplateProvider));

    final effective = _controller.text.trim().isEmpty
        ? BranchTemplateResolver.defaultTemplate
        : _controller.text;
    final preview = BranchTemplateResolver(effective).resolve(
      type: 'feature',
      ticketKey: 'PROJ-123',
      title: 'Add login button',
    );

    return SectionCard(
      label: l10n.branchTemplate,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.branchTemplateDescription,
            style: TextStyle(
              fontSize: 12,
              height: 1.45,
              color: tokens?.textTertiary,
            ),
          ),
          const SizedBox(height: 12),
          CcTextField(
            controller: _controller,
            enabled: isAdmin,
            hintText: BranchTemplateResolver.defaultTemplate,
            onChanged: (_) => setState(() => _dirty = true),
          ),
          const SizedBox(height: 10),
          Text(
            l10n.branchTemplatePreview(preview),
            style: TextStyle(
              fontSize: 12,
              height: 1.45,
              color: tokens?.textSecondary,
            ),
          ),
          if (isAdmin && _dirty) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: CcButton(onPressed: _save, child: Text(l10n.saveChanges)),
            ),
          ],
        ],
      ),
    );
  }
}
