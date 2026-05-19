/// The shared media-width ladder every remote-image request snaps to.
///
/// Cache keys — the server media cache's `(url, w)`, the browser's HTTP cache,
/// and Flutter's in-memory `ImageCache` — all key on the EXACT requested
/// width. Left unbucketed, the same avatar rendered at 14px, 24px, and 44px
/// (times the device pixel ratio) mints a distinct URL per size and misses
/// every cache for what is visually the same image. Rounding UP to the next
/// rung makes nearby display sizes share one fetch and one cache entry;
/// rounding up (never down) keeps the served pixels at or above the requested
/// density.
const _rungs = <int>[
  32,
  48,
  64,
  96,
  128,
  192,
  256,
  384,
  512,
  768,
  1024,
  1536,
  2048,
];

/// Rounds [px] UP to the next ladder rung, never exceeding [max] (the cap the
/// upstream or proxy applies — e.g. 460 for GitHub avatars, 2048 for the
/// media proxy). A [px] above [max] returns [max].
int bucketMediaWidth(int px, {int max = 2048}) {
  for (final rung in _rungs) {
    if (rung >= px) {
      return rung > max ? max : rung;
    }
  }
  return max;
}
