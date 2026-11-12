import 'dart:async';

/// [source], plus its latest event again each time [trigger] fires.
///
/// For a watch whose frames carry something the watched rows do not hold
/// (a value computed while a frame is rendered): a change of that value is
/// not a change of a row, so the source alone would keep the old answer on
/// the wire until some unrelated row moved. Nothing is sent before the
/// source's first event, and a null [trigger] is the source itself.
Stream<T> reemitOn<T>(Stream<T> source, Stream<Object?>? trigger) {
  if (trigger == null) {
    return source;
  }
  return Stream<T>.multi((controller) {
    T? latest;
    var hasLatest = false;
    late final StreamSubscription<Object?> triggers;
    final rows = source.listen(
      (event) {
        latest = event;
        hasLatest = true;
        controller.add(event);
      },
      onError: controller.addError,
      onDone: () {
        unawaited(triggers.cancel());
        controller.close();
      },
    );
    triggers = trigger.listen((_) {
      if (hasLatest) {
        controller.add(latest as T);
      }
    });
    controller.onCancel = () async {
      await rows.cancel();
      await triggers.cancel();
    };
  });
}
