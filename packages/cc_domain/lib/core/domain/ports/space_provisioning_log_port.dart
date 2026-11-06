/// One line of a space's workspace preparation log.
class SpaceProvisioningLogLine {
  /// Creates a [SpaceProvisioningLogLine].
  SpaceProvisioningLogLine({required this.seq, required this.text}) {
    if (seq < 0) {
      throw ArgumentError.value(seq, 'seq', 'must not be negative');
    }
  }

  /// The line's number, which only grows, even across a server restart.
  ///
  /// A progress line that rewrites itself comes back under the same number, so
  /// a reader replaces the line with that number and appends a new one.
  final int seq;

  /// The redacted text, with no terminator.
  final String text;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SpaceProvisioningLogLine &&
          seq == other.seq &&
          text == other.text;

  @override
  int get hashCode => Object.hash(seq, text);

  @override
  String toString() => 'SpaceProvisioningLogLine($seq, $text)';
}

/// What a space's workspace preparation printed: the copy, the fetch, the
/// checkout and any `provision` tasks.
///
/// Live diagnostics, not a record: bounded per space and gone when the server
/// restarts. Every run of a space appends to the same log, so a retry keeps the
/// failure it follows in view.
abstract interface class SpaceProvisioningLogPort {
  /// Appends [text], one line per `\n`. Never throws: a log that fails must
  /// not fail the preparation it describes.
  void write(String workspaceId, String spaceId, String text);

  /// What the log holds now, then each line as it arrives. Attaches and reads
  /// only, and stays open across runs until the subscriber cancels.
  Stream<SpaceProvisioningLogLine> follow(String workspaceId, String spaceId);
}
