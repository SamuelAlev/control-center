part of 'ticket_editor_screen.dart';

extension _TicketEditorState on _TicketEditorScreenState {
  void _resetForWorkspace(String? workspaceId) {
    if (_workspaceId == workspaceId) return;
    _workspaceId = workspaceId;
    _original = null;
    _title.clear();
    _description.clear();
    _labels.clear();
    _priority = 'none';
    _status = 'open';
    _assignee = null;
    _saving = false;
    _titleInvalid = false;
    _error = null;
  }

  void _load(TicketDto ticket) {
    if (_original != null) return;
    _original = ticket;
    _title.text = ticket.title;
    _description.text = ticket.description ?? '';
    _labels.text = ticket.labels.join('\n');
    _priority = ticket.priority;
  }
}
