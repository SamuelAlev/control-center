import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_priority.dart';
import 'package:uuid/uuid.dart';

/// The fields entered by the operator, independent of the server's current row.
/// Field patches never round-trip an entire stale ticket over a concurrent edit.
class TicketDraft {
  const TicketDraft({
    required this.title,
    required this.description,
    required this.priority,
    required this.labels,
    required this.status,
    required this.assignee,
  });

  final String title;
  final String description;
  final String priority;
  final List<String> labels;
  final String status;
  final String? assignee;

  /// Creates a new workspace ticket using the provider configured there.
  Future<String> insert(
    RemoteTicketRepository repository, {
    required String workspaceId,
    required String provider,
  }) async {
    final id = const Uuid().v4();
    final now = DateTime.now().toUtc().toIso8601String();
    await repository.insert(
      TicketDto(
        id: id,
        key: provider == 'local' ? const Uuid().v4() : '',
        title: title,
        description: description.trim().isEmpty ? null : description,
        status: status,
        priority: priority,
        provider: provider,
        labels: labels,
        assignee: assignee,
        assigneeType: assignee == null ? null : 'agent',
        workspaceId: workspaceId,
        createdAt: now,
        updatedAt: now,
      ),
    );
    return id;
  }

  /// Patches changed fields only. Status, assignment and provider are untouched.
  Future<TicketDto?> patch(
    RemoteTicketRepository repository,
    TicketDto original, {
    required String workspaceId,
    required bool labelsEdited,
  }) async {
    final fields = <String, dynamic>{};
    if (title != original.title) fields['title'] = title;
    if (description != (original.description ?? '')) {
      fields['description'] = description.isEmpty ? null : description;
    }
    if (priority != original.priority) {
      fields['priority'] = TicketPriority.values
          .asNameMap()[priority]!
          .toStorageInt();
    }
    if (labelsEdited) fields['labels'] = labels;
    if (fields.isEmpty) return original;
    return repository.patchFields(workspaceId, original.id, fields);
  }
}
