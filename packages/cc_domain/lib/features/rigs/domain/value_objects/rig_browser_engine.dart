/// Which browser a browser rig runs, and therefore which wire protocol drives
/// it.
///
/// Not cosmetic and not a preference: the engine picks the guest image, the
/// automation protocol and what the surface can do. A page that renders in
/// Chromium and breaks in Firefox is the whole reason this exists — "it works
/// on my machine" is a claim about ONE engine, and a disposable rig per engine
/// is how it gets checked.
///
/// One rig is exactly one engine. Opening Firefox next to Chromium in the same
/// conversation is two machines, on purpose: they are the two things being
/// compared.
enum RigBrowserEngine {
  /// Headless Chromium driven over the Chrome DevTools Protocol.
  ///
  /// The default, and the only engine with a native SCREENCAST — Chromium
  /// pushes frames as the page repaints, so the live view costs nothing while
  /// a page is still. The other two are polled.
  chromium('chromium', 'Chromium'),

  /// Headless Firefox driven over WebDriver BiDi.
  ///
  /// Firefox dropped CDP (its remote agent answers BiDi only — verified: a
  /// current build 404s `/json/version`), so this is not "CDP with a different
  /// browser". BiDi has no screencast, so the live view polls
  /// `browsingContext.captureScreenshot`, which Firefox can encode as JPEG
  /// directly — the frames need no host transcode.
  firefox('firefox', 'Firefox'),

  /// WebKitGTK's MiniBrowser driven over W3C WebDriver (classic).
  ///
  /// The closest thing to Safari that runs on Linux: same WebCore/JavaScriptCore
  /// lineage, so it catches the layout and API gaps Safari users hit. WebKit
  /// speaks neither CDP nor BiDi; classic WebDriver is what its shipped driver
  /// implements. Screenshots come back as PNG, so this is the one engine whose
  /// live lane needs the host's ffmpeg (the same dependency the mobile lane
  /// already has).
  webkit('webkit', 'WebKit');

  const RigBrowserEngine(this.wire, this.label);

  /// Stable wire/storage string.
  final String wire;

  /// Human-readable name. A product name, so it is NOT sentence-cased.
  final String label;

  /// The engine every browser rig gets when a caller names none.
  ///
  /// Chromium, because it is the engine with a screencast and the smallest
  /// image, and because every rig that existed before this enum was one.
  static const RigBrowserEngine fallback = RigBrowserEngine.chromium;

  /// Whether the engine pushes frames on its own.
  ///
  /// False means the watch lane has to POLL stills, which is a real
  /// difference: a still page costs a screenshot per tick instead of nothing.
  bool get hasScreencast => this == RigBrowserEngine.chromium;

  /// Whether this engine's stills come back as JPEG.
  ///
  /// False means PNG, which the MJPEG watch lane cannot carry — the host
  /// transcodes, and says so when it has no ffmpeg to transcode with.
  bool get capturesJpeg => this != RigBrowserEngine.webkit;

  /// The media type of [capturesJpeg]'s stills.
  String get stillMediaType => capturesJpeg ? 'image/jpeg' : 'image/png';

  /// Parses [value] back into an engine, or null when unknown.
  ///
  /// Null rather than [fallback]: a caller that sent `"safari"` asked for
  /// something this build cannot boot, and silently handing back Chromium
  /// would answer a compatibility question with the wrong browser. The
  /// callers that want a default say so themselves.
  static RigBrowserEngine? fromWire(String? value) {
    for (final e in RigBrowserEngine.values) {
      if (e.wire == value) {
        return e;
      }
    }
    return null;
  }
}
