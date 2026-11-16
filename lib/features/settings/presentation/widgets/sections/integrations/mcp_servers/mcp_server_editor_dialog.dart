import 'package:cc_domain/features/mcp/domain/entities/mcp_server_definition.dart';
import 'package:cc_domain/features/mcp/domain/value_objects/mcp_server_draft.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/integrations/mcp_servers/mcp_secret_names_editor.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/integrations/mcp_servers/mcp_server_editor_fields.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/integrations/mcp_servers/mcp_server_editor_note.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/integrations/mcp_servers/mcp_server_form.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/integrations/mcp_servers/mcp_server_words.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Opens the MCP server editor to add a server (no [existing]) or change
/// [existing]. [onSave] sends the draft and throws when the server refuses
/// it; the editor then shows why. Resolves true once saved.
Future<bool> showMcpServerEditor(
  BuildContext context, {
  required McpServerEditorScope scope,
  required Future<void> Function(McpServerDraft draft) onSave,
  McpServerDefinition? existing,
}) async =>
    await showCcDialog<bool>(
      context: context,
      builder: (_) => McpServerEditorDialog(
        scope: scope,
        existing: existing,
        onSave: onSave,
      ),
    ) ??
    false;

/// One editor for workspace and personal MCP servers: name, transport, the
/// command or URL, write-only environment variables or headers, and whether
/// it is dialled. Checked with the server's own rules before anything is sent.
class McpServerEditorDialog extends ConsumerStatefulWidget {
  /// Creates the editor.
  const McpServerEditorDialog({
    super.key,
    required this.scope,
    required this.onSave,
    this.existing,
  });

  /// Whose server it is.
  final McpServerEditorScope scope;

  /// The server being changed, or null to add one.
  final McpServerDefinition? existing;

  /// Sends the draft.
  final Future<void> Function(McpServerDraft draft) onSave;

  @override
  ConsumerState<McpServerEditorDialog> createState() =>
      _McpServerEditorDialogState();
}

class _McpServerEditorDialogState extends ConsumerState<McpServerEditorDialog> {
  McpServerDefinition? get _existing => widget.existing;
  late final _name = TextEditingController(text: _existing?.name);
  late final _command = TextEditingController(text: _existing?.command);
  late final _args = TextEditingController(
    text: formatMcpServerArgs(_existing?.args ?? const []),
  );
  late final _url = TextEditingController(text: _existing?.url);
  late final _env = McpSecretEdits(_existing?.envNames ?? const []);
  late final _headers = McpSecretEdits(_existing?.headerNames ?? const []);
  late McpServerTransport _transport =
      _existing?.transport ?? McpServerTransport.stdio;
  late bool _enabled = _existing?.enabled ?? true;
  McpServerFormErrors _errors = const McpServerFormErrors();
  McpServerRefusalField? _refusedField;
  String? _refusal;
  bool _busy = false;

  @override
  void dispose() {
    for (final c in [_name, _command, _args, _url]) {
      c.dispose();
    }
    _env.dispose();
    _headers.dispose();
    super.dispose();
  }

  McpServerFormInput get _input => McpServerFormInput(
    name: _name.text,
    transport: _transport,
    command: _command.text,
    argsText: _args.text,
    url: _url.text,
    enabled: _enabled,
    env: _env,
    headers: _headers,
  );

  bool get _storedCarriesOver {
    final existing = _existing;
    return existing == null || existing.transport == _transport;
  }

  Future<void> _save() async {
    final errors = validateMcpServerForm(_input);
    setState(() {
      _errors = errors;
      _refusal = null;
      _refusedField = null;
    });
    if (!errors.isEmpty) {
      return;
    }
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      await widget.onSave(buildMcpServerDraft(_input, existing: _existing));
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } on Object catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _refusedField = mcpServerRefusalField(e);
          _refusal = mcpServerRefusalMessage(l10n, e);
        });
      }
    }
  }

  String? _refusedAt(McpServerRefusalField field) =>
      _refusedField == field ? _refusal : null;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final existing = _existing;
    final stdio = _transport == McpServerTransport.stdio;
    final storedNames = stdio ? existing?.envNames : existing?.headerNames;
    final droppingStored =
        !_storedCarriesOver &&
        existing != null &&
        (existing.envNames.isNotEmpty || existing.headerNames.isNotEmpty);
    final generalRefusal = _refusedField == null ? _refusal : null;
    return CcDialog(
      title: existing == null
          ? l10n.mcpServerEditorAddTitle
          : l10n.mcpServerEditorEditTitle(existing.name),
      maxWidth: 560,
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.65,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              CcTextField(
                controller: _name,
                label: l10n.nameLabel,
                hintText: 'github',
                helperText: l10n.mcpServerNameHelper,
                errorText: _errors.name
                    ? l10n.mcpServerNameInvalid
                    : _refusedAt(McpServerRefusalField.name),
                enabled: !_busy,
                autofocus: existing == null,
              ),
              const SizedBox(height: AppSpacing.lg),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: McpServerTransportPicker(
                  value: _transport,
                  onChanged: _busy
                      ? null
                      : (value) => setState(() => _transport = value),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              McpServerEditorNote(
                scope: widget.scope,
                transport: _transport,
                owner: ref.watch(canUseHostProvider),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (stdio) ...[
                CcTextField(
                  controller: _command,
                  label: l10n.mcpServerCommandLabel,
                  hintText: 'npx',
                  errorText: _errors.command
                      ? l10n.mcpServerCommandRequired
                      : _refusedAt(McpServerRefusalField.command),
                  enabled: !_busy,
                ),
                const SizedBox(height: AppSpacing.md),
                CcTextArea(
                  controller: _args,
                  label: l10n.mcpServerArgsLabel,
                  hintText: '-y\n@modelcontextprotocol/server-github',
                  helperText: l10n.mcpServerArgsHelper,
                  minLines: 2,
                  maxLines: 6,
                  enabled: !_busy,
                ),
              ] else
                CcTextField(
                  controller: _url,
                  label: l10n.mcpServerUrlLabel,
                  hintText: 'https://mcp.example.com/mcp',
                  keyboardType: TextInputType.url,
                  errorText: _errors.url
                      ? l10n.mcpServerUrlInvalid
                      : _refusedAt(McpServerRefusalField.url),
                  enabled: !_busy,
                ),
              const SizedBox(height: AppSpacing.lg),
              if (droppingStored) ...[
                McpServerNoteLine(text: l10n.mcpServerTransportDropsValues),
                const SizedBox(height: AppSpacing.sm),
              ],
              McpSecretNamesEditor(
                key: ValueKey(stdio),
                edits: stdio ? _env : _headers,
                title: stdio
                    ? l10n.mcpServerEnvLabel
                    : l10n.mcpServerHeadersLabel,
                addLabel: stdio
                    ? l10n.mcpServerEnvAdd
                    : l10n.mcpServerHeaderAdd,
                keyHint: stdio ? 'API_TOKEN' : 'Authorization',
                example: stdio ? null : l10n.mcpServerHeadersExample,
                showStored:
                    _storedCarriesOver && (storedNames?.isNotEmpty ?? false),
                enabled: !_busy,
                errorText: _secretError(l10n, stdio: stdio),
              ),
              const SizedBox(height: AppSpacing.lg),
              McpServerEnabledField(
                value: _enabled,
                onChanged: _busy
                    ? null
                    : (value) => setState(() => _enabled = value),
              ),
              if (generalRefusal != null) ...[
                const SizedBox(height: AppSpacing.md),
                CcAlert(variant: CcAlertVariant.danger, title: generalRefusal),
              ],
            ],
          ),
        ),
      ),
      actions: [
        CcButton(
          variant: CcButtonVariant.ghost,
          onPressed: _busy ? null : () => Navigator.of(context).pop(false),
          child: Text(l10n.cancel),
        ),
        CcButton(
          variant: CcButtonVariant.accent,
          loading: _busy,
          onPressed: _busy ? null : _save,
          child: Text(l10n.save),
        ),
      ],
    );
  }

  String? _secretError(AppLocalizations l10n, {required bool stdio}) {
    final bad = stdio ? _errors.envName : _errors.headerName;
    if (bad != null) {
      return stdio
          ? l10n.mcpServerEnvNameInvalid(bad)
          : l10n.mcpServerHeaderNameInvalid(bad);
    }
    return _refusedAt(
      stdio ? McpServerRefusalField.env : McpServerRefusalField.header,
    );
  }
}
