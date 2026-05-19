import 'package:cc_domain/features/ticketing/domain/entities/ticket.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/ticketing/presentation/widgets/markdown_editable_field.dart';
import 'package:control_center/features/ticketing/presentation/widgets/ticket_properties_rail.dart';
import 'package:control_center/features/ticketing/providers/ticket_patch_provider.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The "Issue" tab: the ticket's editable title and description, followed by
/// its properties (status, priority, assignee, collaborators). Title and
/// description autosave on blur via `patchTicketOptimistic`.
class TicketIssueTab extends ConsumerStatefulWidget {
  /// Creates a [TicketIssueTab].
  const TicketIssueTab({super.key, required this.ticket});

  /// The ticket being viewed.
  final Ticket ticket;

  @override
  ConsumerState<TicketIssueTab> createState() => _TicketIssueTabState();
}

class _TicketIssueTabState extends ConsumerState<TicketIssueTab> {
  final _titleController = TextEditingController();
  final _titleFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.ticket.title;
    _titleFocus.addListener(() {
      if (!_titleFocus.hasFocus) {
        _saveTitle();
      }
    });
  }

  @override
  void didUpdateWidget(TicketIssueTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    final switched = oldWidget.ticket.id != widget.ticket.id;
    if (switched || !_titleFocus.hasFocus) {
      if (_titleController.text != widget.ticket.title) {
        _titleController.text = widget.ticket.title;
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _titleFocus.dispose();
    super.dispose();
  }

  void _saveTitle() {
    final text = _titleController.text.trim();
    if (text.isEmpty) {
      _titleController.text = widget.ticket.title;
      return;
    }
    if (text == widget.ticket.title) {
      return;
    }
    patchTicketOptimistic(
      ref,
      workspaceId: widget.ticket.workspaceId,
      ticketId: widget.ticket.id,
      fields: {'title': text},
      previousFields: {'title': widget.ticket.title},
      undoLabel: AppLocalizations.of(context).undoLabelTicketEdit,
    );
  }

  void _saveDescription(String text) {
    if (text == (widget.ticket.description ?? '')) {
      return;
    }
    patchTicketOptimistic(
      ref,
      workspaceId: widget.ticket.workspaceId,
      ticketId: widget.ticket.id,
      fields: {'description': text},
      previousFields: {'description': widget.ticket.description ?? ''},
      undoLabel: AppLocalizations.of(context).undoLabelTicketEdit,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final ticket = widget.ticket;

    final content = Padding(
      padding: const EdgeInsets.fromLTRB(28, 22, 28, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CcTextField(
            controller: _titleController,
            focusNode: _titleFocus,
            maxLines: null,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) {
              _saveTitle();
              _titleFocus.unfocus();
            },
            textStyle: TextStyle(
              fontSize: 22,
              height: 1.3,
              fontWeight: FontWeight.w600,
              color: t.textPrimary,
            ),
            hintText: l10n.ticketsTitle,
            chromeless: true,
          ),
          const SizedBox(height: 10),
          MarkdownEditableField(
            key: ValueKey('desc-${ticket.id}'),
            text: ticket.description ?? '',
            hint: l10n.ticketDescription,
            onSave: _saveDescription,
          ),
        ],
      ),
    );

    final sidebar = TicketPropertiesRail(
      ticket: ticket,
      workspaceId: ticket.workspaceId,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        // Wide enough to fit the title/description beside a 288px sidebar with
        // breathing room — otherwise stack the sidebar under the description.
        final wide = constraints.maxWidth >= 640;
        if (!wide) {
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                content,
                Container(height: 1, color: t.borderSecondary),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                  child: sidebar,
                ),
              ],
            ),
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: SingleChildScrollView(child: content)),
            Container(width: 1, color: t.borderSecondary),
            SizedBox(
              width: 288,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                child: sidebar,
              ),
            ),
          ],
        );
      },
    );
  }
}
