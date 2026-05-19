/// A transcribed window emitted by a `MeetingTranscriptionPort`.
///
/// A pure value carrying the recognized text and its offsets (ms) from the
/// first sample of the channel's stream. Lives in the domain so the recorder
/// controller and the echo filter can name it without reaching into the data
/// layer that produces it.
class TranscribedWindow {
  /// Creates a [TranscribedWindow].
  const TranscribedWindow({
    required this.text,
    required this.startMs,
    required this.endMs,
  });

  /// Recognized text for this window.
  final String text;

  /// Start offset (ms) from the first sample of the stream.
  final int startMs;

  /// End offset (ms) from the first sample of the stream.
  final int endMs;
}
