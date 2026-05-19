import 'package:cc_domain/core/domain/value_objects/principal.dart';
import 'package:cc_domain/features/presence/domain/value_objects/participant_presence.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/messaging/providers/channel_notes_provider.dart';
import 'package:control_center/features/presence/providers/presence_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/utils/relative_time.dart';
import 'package:control_center/shared/widgets/app_timestamp.dart';
import 'package:control_center/shared/widgets/markdown/markdown_editor.dart';
import 'package:control_center/shared/widgets/markdown/markdown_text_field.dart';
import 'package:control_center/shared/widgets/markdown/styled_markdown_body.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The "Notes" IDE-sidebar panel: the shared per-channel handoff doc (PRD 16
/// §11) both humans and agents read/write. Authoritative last-write-wins —
/// Save always overwrites with this client's full content.
class NotesPanel extends ConsumerWidget {
  /// Creates a [NotesPanel].
  const NotesPanel({super.key, required this.workspaceId, this.channelId});

  /// The active workspace — scopes the "who else is editing" presence read.
  final String workspaceId;

  /// The open conversation, or null when none is selected.
  final String? channelId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final channelId = this.channelId;
    if (channelId == null) {
      return CcEmptyState(
        icon: AppIcons.notebookText,
        message: AppLocalizations.of(context).selectConversation,
      );
    }
    return _NoteEditor(workspaceId: workspaceId, channelId: channelId);
  }
}

class _NoteEditor extends ConsumerStatefulWidget {
  const _NoteEditor({required this.workspaceId, required this.channelId});

  final String workspaceId;
  final String channelId;

  @override
  ConsumerState<_NoteEditor> createState() => _NoteEditorState();
}

class _NoteEditorState extends ConsumerState<_NoteEditor> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _editing = false;
  bool _saving = false;

  /// Cached presence notifier. Captured in [initState] so [dispose] can
  /// release the soft-claim without touching `ref` during unmount (which is
  /// unsafe — `ref` relies on a `BuildContext` that is already deactivated by
  /// then). [myPresenceProvider] is a non-autoDispose global, so this
  /// reference stays valid for the widget's whole lifetime.
  late final MyPresenceNotifier _presence;

  @override
  void initState() {
    super.initState();
    _presence = ref.read(myPresenceProvider.notifier);
  }

  @override
  void dispose() {
    _releaseClaim();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _claimClaim() {
    _presence.addClaim(
      SoftClaim(entityType: 'note', entityId: widget.channelId),
    );
  }

  void _releaseClaim() {
    _presence.removeClaim(entityType: 'note', entityId: widget.channelId);
  }

  void _startEdit(String currentContent) {
    setState(() {
      _controller.text = currentContent;
      _controller.selection = TextSelection.collapsed(
        offset: _controller.text.length,
      );
      _editing = true;
    });
    _claimClaim();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  Future<void> _save() async {
    if (_saving) {
      return;
    }
    setState(() => _saving = true);
    var failed = false;
    try {
      await updateChannelNote(
        ref.read(rpcClientProvider),
        channelId: widget.channelId,
        content: _controller.text,
      );
    } on Exception {
      failed = true;
    }
    if (!mounted) {
      return;
    }
    if (failed) {
      setState(() => _saving = false);
      CcToastScope.maybeOf(context)?.show(
        AppLocalizations.of(context).notesSaveFailed,
        variant: CcToastVariant.danger,
      );
      return;
    }
    setState(() {
      _saving = false;
      _editing = false;
    });
    _releaseClaim();
  }

  Future<void> _cancel(String currentContent) async {
    if (_controller.text == currentContent) {
      setState(() => _editing = false);
      _releaseClaim();
      return;
    }
    final l10n = AppLocalizations.of(context);
    final discard = await showCcDialog<bool>(
      context: context,
      builder: (ctx) => CcDialog(
        title: l10n.discardChangesConfirm,
        content: const SizedBox.shrink(),
        actions: [
          CcButton(
            onPressed: () => Navigator.pop(ctx, false),
            variant: CcButtonVariant.ghost,
            child: Text(l10n.cancel),
          ),
          CcButton(
            onPressed: () => Navigator.pop(ctx, true),
            variant: CcButtonVariant.destructive,
            child: Text(l10n.discard),
          ),
        ],
      ),
    );
    if (discard == true && mounted) {
      setState(() => _editing = false);
      _releaseClaim();
    }
  }

  /// Another participant (not me) currently holding the `note` soft-claim on
  /// this channel, or null (PRD 16 §14 — visibility, not a lock).
  ParticipantPresence? _otherEditor() {
    final roster =
        ref.watch(presenceRosterProvider(widget.workspaceId)).value ?? const [];
    final myUserId = ref.watch(currentUserIdProvider);
    for (final p in roster) {
      if (p.principal is UserPrincipal && p.principal.id == myUserId) {
        continue;
      }
      if (p.claims.any(
        (c) => c.entityType == 'note' && c.entityId == widget.channelId,
      )) {
        return p;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final noteAsync = ref.watch(channelNoteProvider(widget.channelId));
    final note = noteAsync.value;
    final content = note?.content ?? '';
    final otherEditor = _otherEditor();

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (otherEditor != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Text(
                l10n.notesEditingHint(otherEditor.displayName),
                style: TextStyle(
                  fontSize: 11,
                  color: t.textTertiary,
                  fontStyle: FontStyle.italic,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          Expanded(
            child: SingleChildScrollView(
              child: _editing
                  ? _buildEdit(context, content)
                  : content.trim().isEmpty
                  ? _buildEmpty(context)
                  : _buildView(context, note!),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    return CcTappable(
      onPressed: () => _startEdit(''),
      builder: (context, states) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Text(
          l10n.notesEmptyHint,
          style: TextStyle(
            fontSize: 13,
            color: t.textPlaceholder,
            decoration: TextDecoration.none,
          ),
        ),
      ),
    );
  }

  Widget _buildView(BuildContext context, ChannelNote note) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final updatedByName = _resolveUpdatedByName(note.updatedBy);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: CcTappable(
            onPressed: () => _startEdit(note.content),
            builder: (context, states) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(AppIcons.pencil, size: 12, color: t.textBrandPrimary),
                const SizedBox(width: 4),
                Text(
                  l10n.notesEditTooltip,
                  style: TextStyle(
                    fontSize: 11,
                    color: t.textBrandPrimary,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        StyledMarkdownBody(data: note.content),
        const SizedBox(height: AppSpacing.sm),
        if (updatedByName.isNotEmpty)
          AppTimestamp(
            dateTime: note.updatedAt,
            child: Text(
              l10n.notesUpdatedBy(
                updatedByName,
                formatRelativeTime(context, note.updatedAt),
              ),
              style: TextStyle(
                fontSize: 11,
                color: t.textTertiary,
                decoration: TextDecoration.none,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEdit(BuildContext context, String currentContent) {
    final l10n = AppLocalizations.of(context);
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () =>
            _cancel(currentContent),
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          MarkdownEditor(
            controller: _controller,
            focusNode: _focusNode,
            fieldBuilder: (context) => MarkdownTextField(
              controller: _controller,
              focusNode: _focusNode,
              hintText: l10n.notesEmptyHint,
              minLines: 8,
            ),
            previewBuilder: (context) =>
                StyledMarkdownBody(data: _controller.text),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              CcButton(
                onPressed: _saving ? null : () => _cancel(currentContent),
                variant: CcButtonVariant.secondary,
                size: CcButtonSize.sm,
                child: Text(l10n.cancel),
              ),
              const SizedBox(width: 8),
              CcButton(
                onPressed: _saving ? null : _save,
                size: CcButtonSize.sm,
                child: Text(l10n.save),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Best-effort display name for the note's last writer: try the human user
  /// directory, then the agent directory, falling back to a shortened id.
  /// Doesn't assume a wire format for `updated_by` (the server may send a
  /// bare user id or an agent id).
  String _resolveUpdatedByName(String updatedBy) {
    if (updatedBy.isEmpty) {
      return '';
    }
    final user = ref.watch(usersByIdProvider).value?[updatedBy];
    if (user != null) {
      return user.displayName;
    }
    final agent = ref.watch(agentDetailProvider(updatedBy)).value;
    if (agent != null) {
      return agent.name;
    }
    return updatedBy.length > 8 ? updatedBy.substring(0, 8) : updatedBy;
  }
}
