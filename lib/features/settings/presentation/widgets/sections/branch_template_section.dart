import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:control_center/features/settings/domain/services/branch_template_resolver.dart';
import 'package:control_center/features/settings/providers/branch_template_provider.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';

/// General Settings → branch-name template for ticket worktrees.
///
/// The template is used when an isolated worktree is provisioned for a ticket.
/// Supports `{type}`, `{ticket-key}`, `{slug}` placeholders.
class BranchTemplateSection extends ConsumerStatefulWidget {
  /// Creates a [BranchTemplateSection].
  const BranchTemplateSection({super.key});

  @override
  ConsumerState<BranchTemplateSection> createState() =>
      _BranchTemplateSectionState();
}

class _BranchTemplateSectionState extends ConsumerState<BranchTemplateSection> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: ref.read(branchTemplateProvider))
      ..addListener(_onChanged);
  }

  void _onChanged() {
    ref.read(branchTemplateProvider.notifier).setTemplate(_controller.text);
    setState(() {}); // refresh the live preview
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.designSystem;
    final preview = BranchTemplateResolver(_controller.text).resolve(
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
          FTextField(
            control: FTextFieldControl.managed(controller: _controller),
            hint: BranchTemplateResolver.defaultTemplate,
          ),
          const SizedBox(height: 10),
          Text(
            l10n.branchTemplatePreview(preview),
            style: TextStyle(
              fontSize: 12,
              height: 1.45,
              fontFeatures: const [FontFeature.tabularFigures()],
              color: tokens?.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
