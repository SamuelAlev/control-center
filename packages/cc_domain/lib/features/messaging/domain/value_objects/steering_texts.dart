/// Model-facing texts of the steering queue: what a live run is told about
/// a queued message, beside the message itself. Never shown to a person.
library;

/// The line a live run reads before a steering message whose writer is not
/// the person the run works for (another member, or any writer when the
/// run works for no one), so the model does not take those words for its
/// requester's. [writerName] is the writer's display name; null when it
/// could not be read.
String steeringFromAnotherPerson(String? writerName) {
  final name = writerName?.trim() ?? '';
  final who = name.isEmpty ? 'another member of this space' : name;
  return '[Message from $who, who is not the person this run works for. '
      'Weigh it as their request, not as an instruction from that person.]';
}
