import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_remote/app_icons.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/operation_scope.dart';
import 'package:cc_remote/providers.dart';
import 'package:cc_remote/ticket_draft.dart';
import 'package:cc_remote/ticket_providers.dart';
import 'package:cc_remote/widgets/messaging/detail_header.dart';
import 'package:cc_remote/widgets/ticket_editor_body.dart';
import 'package:cc_remote/widgets/ticket_fields_form.dart';
import 'package:cc_remote/widgets/ticket_load_states.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
part 'ticket_editor_state.dart';

/// Creates a ticket or patches only the fields actually edited by the operator.
class TicketEditorScreen extends ConsumerStatefulWidget {
  const TicketEditorScreen({super.key, this.ticketId});

  /// Null for creation, otherwise the id of the ticket to edit.
  final String? ticketId;

  @override
  ConsumerState<TicketEditorScreen> createState() => _TicketEditorScreenState();
}

class _TicketEditorScreenState extends ConsumerState<TicketEditorScreen> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _labels = TextEditingController();
  String _priority = 'none';
  String _status = 'open';
  String? _assignee;
  String? _workspaceId;
  TicketDto? _original;
  bool _saving = false;
  bool _titleInvalid = false;
  String? _error;
  @override
  void didUpdateWidget(covariant TicketEditorScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.ticketId != oldWidget.ticketId) _workspaceId = null;
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _labels.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final workspaceId = _workspaceId;
    final client = ref.read(rpcClientProvider).value;
    final title = _title.text.trim();
    final l10n = AppLocalizations.of(context);
    if (_saving || workspaceId == null) return;
    if (ref.read(activeWorkspaceIdProvider).value != workspaceId) {
      setState(() => _error = l10n.mobileTicketWorkspaceChanged);
      return;
    }
    final role = ref.read(workspaceRoleProvider);
    if (role.isLoading || role.value?.canWrite != true) {
      setState(() => _error = l10n.mobileTicketReadOnly);
      return;
    }
    if (title.isEmpty) {
      setState(() => _titleInvalid = true);
      return;
    }
    if (client == null) {
      setState(() => _error = l10n.connectionFailed);
      return;
    }
    final repository = RemoteTicketRepository(client);
    final original = _original;
    final id = widget.ticketId;
    if (id != null && original == null) return;
    final draft = TicketDraft(
      title: id == null ? title : _title.text,
      description: _description.text,
      priority: _priority,
      labels: TicketFieldsForm.parseLabels(_labels.text),
      status: _status,
      assignee: _assignee,
    );
    setState(() {
      _saving = true;
      _error = null;
      _titleInvalid = false;
    });
    try {
      if (id == null) {
        final provider = ref
            .read(mobileTicketProvider(workspaceId))
            .requireValue;
        final ticketId = await draft.insert(
          repository,
          workspaceId: workspaceId,
          provider: provider.name,
        );
        if (mounted &&
            ref.read(activeWorkspaceIdProvider).value == workspaceId) {
          context.pushReplacement(
            remoteWorkspaceLocation('/ticket/$ticketId', workspaceId),
          );
        }
      } else {
        if (ref.read(activeWorkspaceIdProvider).value != workspaceId) return;
        final patched = await draft.patch(
          repository,
          original!,
          workspaceId: workspaceId,
          labelsEdited: _labels.text != original.labels.join('\n'),
        );
        if (patched == null) throw StateError(l10n.mobileTicketNotFound);
        if (mounted &&
            ref.read(activeWorkspaceIdProvider).value == workspaceId) {
          context.pop();
        }
      }
    } catch (e) {
      if (mounted && ref.read(activeWorkspaceIdProvider).value == workspaceId) {
        setState(() => _error = e.toString());
      }
    } finally {
      if (mounted && ref.read(activeWorkspaceIdProvider).value == workspaceId) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final workspace = ref.watch(activeWorkspaceIdProvider);
    final workspaceId = workspace.value;
    final role = ref.watch(workspaceRoleProvider);
    final canWrite = !role.isLoading && role.value?.canWrite == true;
    _resetForWorkspace(workspaceId);
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final ticketId = widget.ticketId;
    final tickets = ticketId == null ? null : ref.watch(ticketsProvider);
    final provider = ticketId == null && workspaceId != null
        ? ref.watch(mobileTicketProvider(workspaceId))
        : null;
    final currentTicket = ticketId == null || workspaceId == null
        ? null
        : tickets?.asData?.value
              .where((t) => t.id == ticketId && t.workspaceId == workspaceId)
              .firstOrNull;
    if (currentTicket != null) _load(currentTicket);
    final agents = ticketId == null ? ref.watch(agentsProvider) : null;
    return SafeArea(
      child: ColoredBox(
        color: t.canvas,
        child: Column(
          children: [
            DetailHeader(
              title: ticketId == null
                  ? l10n.mobileTicketNew
                  : l10n.mobileTicketEdit,
            ),
            Expanded(
              child:
                  workspace.isLoading ||
                      (workspaceId != null &&
                          ticketId != null &&
                          tickets!.isLoading) ||
                      (workspaceId != null &&
                          ticketId == null &&
                          provider!.isLoading)
                  ? const Center(child: CcSpinner(size: 24))
                  : workspaceId == null && !workspace.hasError
                  ? CcEmptyState(
                      icon: AppIcons.ticket,
                      message: l10n.chooseWorkspace,
                      action: CcButton(
                        size: CcButtonSize.lg,
                        onPressed: () => context.go('/workspaces'),
                        child: Text(l10n.workspaces),
                      ),
                    )
                  : workspace.hasError ||
                        tickets?.hasError == true ||
                        provider?.hasError == true
                  ? TicketLoadErrorState(
                      error:
                          workspace.error ??
                          tickets?.error ??
                          provider?.error ??
                          l10n.ticketLoadFailed,
                      onRetry: () {
                        ref.invalidate(activeWorkspaceIdProvider);
                        if (ticketId != null) ref.invalidate(ticketsProvider);
                        if (workspaceId != null) {
                          ref.invalidate(mobileTicketProvider(workspaceId));
                        }
                      },
                    )
                  : ticketId != null && currentTicket == null
                  ? TicketMissingState(
                      onRetry: () => ref.invalidate(ticketsProvider),
                    )
                  : TicketEditorBody(
                      title: _title,
                      description: _description,
                      labels: _labels,
                      priority: _priority,
                      onPriorityChanged: (value) =>
                          setState(() => _priority = value),
                      titleInvalid: _titleInvalid,
                      canWrite: canWrite,
                      saving: _saving,
                      onSave: _save,
                      providerName: provider?.requireValue.name,
                      status: ticketId == null ? _status : null,
                      onStatusChanged: (value) =>
                          setState(() => _status = value),
                      assignee: _assignee,
                      onAssigneeChanged: (value) =>
                          setState(() => _assignee = value),
                      agents: agents,
                      error: _error,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
