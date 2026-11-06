import 'dart:async';

import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/settings/presentation/widgets/kit/settings_kit.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/markdown/markdown_editor.dart';
import 'package:control_center/shared/widgets/markdown/markdown_text_field.dart';
import 'package:control_center/shared/widgets/markdown/styled_markdown_body.dart';
import 'package:control_center/shared/widgets/page_wrapper.dart';
import 'package:flutter/widgets.dart';

/// At or above this width a record's details sit beside its text.
const double _kTwoColumnBreakpoint = 880;

/// Width of the details column.
const double _kDetailsWidth = 300;

/// Past this, a line of a record's text is too long to read comfortably.
const double _kMaxContentWidth = 1160;

/// The frame of an open fact or policy: what it says, its details beside that,
/// what it links to underneath, and a commit bar while it is being edited.
class MemoryRecordPage extends StatelessWidget {
  /// Creates a [MemoryRecordPage].
  const MemoryRecordPage({
    super.key,
    required this.title,
    required this.editing,
    required this.onBack,
    required this.onEdit,
    required this.onCancelEdit,
    required this.onDelete,
    required this.body,
    required this.details,
    this.links = const [],
    this.saveBar,
  });

  /// The record's name.
  final String title;

  /// Whether [body] is its form.
  final bool editing;

  /// Leaves the record.
  final VoidCallback onBack;

  /// Starts editing.
  final VoidCallback onEdit;

  /// Stops editing without saving.
  final VoidCallback onCancelEdit;

  /// Deletes it.
  final VoidCallback onDelete;

  /// What it says, or the form.
  final Widget body;

  /// The facts about it.
  final Widget details;

  /// Records it leads to.
  final List<Widget> links;

  /// Shown under the page while editing.
  final Widget? saveBar;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final main = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        body,
        for (final link in links) ...[
          const SizedBox(height: AppSpacing.lg),
          link,
        ],
      ],
    );
    return PageWrapper(
      title: title,
      actions: [
        CcButton(
          variant: CcButtonVariant.secondary,
          size: CcButtonSize.sm,
          icon: AppIcons.arrowLeft,
          onPressed: onBack,
          child: Text(l10n.back),
        ),
        if (editing)
          CcButton(
            variant: CcButtonVariant.secondary,
            size: CcButtonSize.sm,
            onPressed: onCancelEdit,
            child: Text(l10n.cancel),
          )
        else
          CcButton(
            variant: CcButtonVariant.secondary,
            size: CcButtonSize.sm,
            icon: AppIcons.pencil,
            onPressed: onEdit,
            child: Text(l10n.edit),
          ),
        CcButton(
          variant: CcButtonVariant.destructive,
          size: CcButtonSize.sm,
          icon: AppIcons.trash2,
          onPressed: onDelete,
          child: Text(l10n.delete),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= _kTwoColumnBreakpoint;
                return SingleChildScrollView(
                  padding: const EdgeInsetsDirectional.fromSTEB(
                    AppSpacing.xl,
                    0,
                    AppSpacing.xl,
                    AppSpacing.xl,
                  ),
                  child: Align(
                    alignment: AlignmentDirectional.topStart,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: _kMaxContentWidth,
                      ),
                      child: wide
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: main),
                                const SizedBox(width: AppSpacing.lg),
                                SizedBox(width: _kDetailsWidth, child: details),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                main,
                                const SizedBox(height: AppSpacing.lg),
                                details,
                              ],
                            ),
                    ),
                  ),
                );
              },
            ),
          ),
          ?saveBar,
        ],
      ),
    );
  }
}

/// A label and its value on a details panel.
class MemoryDetailRow extends StatelessWidget {
  /// Creates a [MemoryDetailRow].
  const MemoryDetailRow({super.key, required this.label, required this.child});

  /// What the value is.
  final String label;

  /// The value.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Text(
            label,
            style: CcTypography.caption.copyWith(color: t.textTertiary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Align(
              alignment: AlignmentDirectional.centerEnd,
              child: DefaultTextStyle.merge(
                style: CcTypography.caption.copyWith(color: t.textSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                child: child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The domain of a record being edited, offering the ones already in use.
class MemoryDomainField extends StatelessWidget {
  /// Creates a [MemoryDomainField].
  const MemoryDomainField({
    super.key,
    required this.controller,
    required this.domains,
  });

  /// The text.
  final TextEditingController controller;

  /// The domains to offer.
  final Iterable<String> domains;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SettingsField(
      label: l10n.domainLabel,
      child: CcAutocomplete<String>(
        controller: controller,
        hintText: l10n.domainHint,
        semanticLabel: l10n.domainLabel,
        options: [
          for (final domain in domains.toSet().toList()..sort())
            CcSelectOption(value: domain, label: domain),
        ],
        onSelected: (domain) => controller.text = domain,
        onCustomValue: (domain) => controller.text = domain,
      ),
    );
  }
}

/// The shared Write/Preview editor over a record's markdown.
class MemoryMarkdownField extends StatelessWidget {
  /// Creates a [MemoryMarkdownField].
  const MemoryMarkdownField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.hint,
  });

  /// The text.
  final TextEditingController controller;

  /// The field's focus.
  final FocusNode focusNode;

  /// Says what belongs here.
  final String hint;

  @override
  Widget build(BuildContext context) {
    return MarkdownEditor(
      controller: controller,
      focusNode: focusNode,
      fieldBuilder: (context) => MarkdownTextField(
        controller: controller,
        focusNode: focusNode,
        hintText: hint,
        bare: true,
      ),
      previewBuilder: (context) => StyledMarkdownBody(data: controller.text),
    );
  }
}

/// Runs [save], reporting a failure through [onError] instead of losing it.
Future<bool> runMemorySave(
  Future<void> Function() save, {
  required void Function(String message) onError,
}) async {
  try {
    await save();
    return true;
  } on Object catch (error) {
    onError('$error');
    return false;
  }
}

/// Calls [action] without waiting on it, from a button.
VoidCallback memoryAction(Future<void> Function() action) =>
    () => unawaited(action());
