import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/settings/presentation/widgets/kit/settings_key_value_editor.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/integrations/mcp_servers/mcp_server_form.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/focus_on_mount.dart';
import 'package:flutter/widgets.dart';

/// The write-only values of an MCP server (environment variables or headers).
///
/// A stored value is never sent back, so a stored name shows only that it
/// has one: it can be given a new value or removed, and both can be undone
/// until the editor saves. New names are typed as pairs below.
class McpSecretNamesEditor extends StatelessWidget {
  /// Creates the editor over [edits].
  const McpSecretNamesEditor({
    super.key,
    required this.edits,
    required this.title,
    required this.addLabel,
    required this.keyHint,
    this.example,
    this.errorText,
    this.showStored = true,
    this.enabled = true,
  });

  /// The edits this editor changes.
  final McpSecretEdits edits;

  /// The heading ("Environment variables", "Headers").
  final String title;

  /// The add button's label.
  final String addLabel;

  /// The new name field's placeholder.
  final String keyHint;

  /// An optional line saying what goes here.
  final String? example;

  /// What is wrong with a new name, if anything.
  final String? errorText;

  /// Whether the stored names carry over (false once the transport changed).
  final bool showStored;

  /// Whether the controls accept input.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final caption = CcTypography.caption.copyWith(color: t.textTertiary);
    final error = errorText;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: CcTypography.bodySm.copyWith(
            color: t.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(l10n.mcpServerSecretsDescription, style: caption),
        if (example != null) Text(example!, style: caption),
        const SizedBox(height: AppSpacing.sm),
        if (showStored)
          ListenableBuilder(
            listenable: edits,
            builder: (context, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final name in edits.stored)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(
                      bottom: AppSpacing.sm,
                    ),
                    child: _StoredRow(
                      key: ValueKey('mcp-secret-$name'),
                      name: name,
                      edits: edits,
                      enabled: enabled,
                    ),
                  ),
              ],
            ),
          ),
        SettingsKeyValueEditor(
          entries: edits.added,
          onChanged: edits.setAdded,
          keyHint: keyHint,
          valueHint: l10n.mcpServerSecretValueHint,
          addLabel: addLabel,
          emptyLabel: showStored && edits.stored.isNotEmpty ? '' : null,
          obscureValues: true,
          enabled: enabled,
        ),
        if (error != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            error,
            style: CcTypography.caption.copyWith(color: t.textErrorPrimary),
          ),
        ],
      ],
    );
  }
}

/// One stored name: kept (with Replace value / Remove), being replaced (a
/// masked field for the new value) or removed on save.
class _StoredRow extends StatelessWidget {
  const _StoredRow({
    super.key,
    required this.name,
    required this.edits,
    required this.enabled,
  });

  final String name;
  final McpSecretEdits edits;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final removed = edits.isRemoved(name);
    final replacing = edits.isReplacing(name);
    final label = Text(
      name,
      // RTL carve-out: a variable or header name is a machine token.
      textDirection: TextDirection.ltr,
      overflow: TextOverflow.ellipsis,
      style: CcFonts.code(
        textStyle: CcTypography.bodySm.copyWith(
          color: removed ? t.textTertiary : t.textPrimary,
          decoration: removed ? TextDecoration.lineThrough : null,
        ),
      ),
    );
    final Widget middle;
    if (replacing) {
      // Replace becomes Undo in the same slot and keeps focus, so the field
      // asks for focus itself.
      middle = FocusOnMount(
        builder: (context, focusNode) => CcTextField(
          hintText: l10n.mcpServerSecretNewValueHint,
          size: CcTextFieldSize.sm,
          obscureText: true,
          focusNode: focusNode,
          enabled: enabled,
          onChanged: (value) => edits.setReplacement(name, value),
        ),
      );
    } else if (removed) {
      middle = Text(
        l10n.mcpServerSecretRemovedOnSave,
        style: CcTypography.caption.copyWith(color: t.textTertiary),
      );
    } else {
      // A stored value is never read back: a fixed mask says one exists.
      middle = Text(
        '••••••••',
        style: CcTypography.bodySm.copyWith(color: t.textTertiary),
      );
    }
    return Row(
      children: [
        Expanded(flex: 5, child: label),
        const SizedBox(width: AppSpacing.sm),
        Expanded(flex: 4, child: middle),
        const SizedBox(width: AppSpacing.sm),
        if (removed || replacing)
          CcButton(
            variant: CcButtonVariant.ghost,
            size: CcButtonSize.sm,
            onPressed: enabled ? () => edits.keep(name) : null,
            child: Text(l10n.mcpServerSecretUndo),
          )
        else ...[
          CcButton(
            variant: CcButtonVariant.ghost,
            size: CcButtonSize.sm,
            onPressed: enabled ? () => edits.replace(name) : null,
            child: Text(l10n.mcpServerSecretReplace),
          ),
          CcButton(
            variant: CcButtonVariant.ghost,
            size: CcButtonSize.sm,
            onPressed: enabled ? () => edits.remove(name) : null,
            child: Text(l10n.remove),
          ),
        ],
      ],
    );
  }
}
