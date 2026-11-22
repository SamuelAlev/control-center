/// The size limit on text one agent sends another (plan section 10,
/// "Identity and guards").
///
/// A peer message is the recipient's prompt: it rides every request of the
/// run it starts. Content that does not fit belongs in a file or a ticket the
/// message points to.
library;

/// The most characters one peer message may carry: the `message` of
/// `send_to_agent` and `ask_agent`, the question of `consult_agent` and
/// `request_peer_review`, the rendered brief of `delegate_task`.
const int maxPeerMessageChars = 16384;

/// The refusal for a peer message whose [label] (what the text is, for
/// example `message` or `brief`) is [text], or null when it fits
/// [maxPeerMessageChars].
///
/// Checked before anything is posted, dispatched or counted against a rate
/// limit, so a refused message leaves nothing behind.
String? peerMessageSizeRefusal(String text, {required String label}) {
  if (text.length <= maxPeerMessageChars) {
    return null;
  }
  return 'The $label is ${text.length} characters; a message to another '
      'agent may carry at most $maxPeerMessageChars. Put the content in a '
      'file or a ticket and send its path or id instead.';
}
