/// Suppresses value-identical re-emissions of a drift watch.
///
/// Drift invalidation is TABLE-granular: any write to a table re-runs EVERY watch that
/// reads it and re-emits the (unchanged) result, which then costs entity mapping, JSON
/// encoding, a socket push and a client decode per subscription.
/// A write for agent B re-emits agent A's 200 run logs; a segment written for meeting X
/// re-emits meeting Y's transcript; a pipeline step transition re-emits every other
/// workspace's run list.
Stream<List<T>> distinctRows<T>(Stream<List<T>> source) {
  List<T>? previous;
  return source.where((rows) {
    final prev = previous;
    if (prev != null && prev.length == rows.length) {
      var equal = true;
      for (var i = 0; i < rows.length; i++) {
        if (prev[i] != rows[i]) {
          equal = false;
          break;
        }
      }
      if (equal) {
        return false;
      }
    }
    previous = rows;
    return true;
  });
}
