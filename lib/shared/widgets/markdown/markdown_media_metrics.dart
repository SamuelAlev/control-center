import 'dart:convert';
import 'dart:ui' show Size;

import 'package:flutter/foundation.dart';

/// Aspect (height ÷ width) reserved for a GitHub attachment nothing has
/// measured yet.
///
/// A guess, and deliberately a fixed one: what it buys is not accuracy but
/// STABILITY. Every state of a block-level attachment — deferred, loading,
/// failed, loaded — lays out through the same box function, so a body with
/// three screenshots reflows AT MOST once per screenshot (when its real size
/// lands) instead of four times. 16:9 is the modal shape of a screen recording
/// and sits between a wide window capture and a 4:3 screenshot.
const double kDefaultAttachmentAspect = 9 / 16;

/// Hosts whose media is CONTENT — a screenshot, a recording, a diagram — never
/// a badge inline with a sentence.
///
/// The distinction matters because reserving a column-filling box is right for
/// the first and catastrophic for the second: a 20px shields.io check would
/// hold a 450px hole open until its bytes landed. Everything not on this list
/// keeps the small inline spinner it had.
const Set<String> _attachmentHosts = {
  'private-user-images.githubusercontent.com',
  'user-images.githubusercontent.com',
};

final RegExp _uuidRe = RegExp(
  r'[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}',
  caseSensitive: false,
);

/// Whether [uri] points at GitHub-hosted attachment media (either the raw
/// `github.com/user-attachments/*` reference or the pre-signed
/// `private-user-images.*` URL the `body_html` splice rewrites it to).
bool isGitHubAttachmentMedia(Uri uri) {
  final host = uri.host.toLowerCase();
  if (_attachmentHosts.contains(host)) {
    return true;
  }
  return host == 'github.com' && uri.path.startsWith('/user-attachments/');
}

/// True while [uri] is still the raw `github.com/user-attachments/*` form.
///
/// That URL resolves only against a browser session cookie; fetched with a
/// token (or anonymously through the media proxy) it returns 200 `text/html` —
/// GitHub's sign-in page. It is unfetchable BY CONSTRUCTION, so the renderer
/// treats it as "credentials pending" rather than firing the request and
/// rendering the failure.
bool isUnsplicedUserAttachment(Uri uri) =>
    uri.host.toLowerCase() == 'github.com' &&
    uri.path.startsWith('/user-attachments/');

/// True when [uri] is a pre-signed attachment URL whose JWT has already
/// expired, so fetching it can only 403.
///
/// The dominant case in practice, and the one the un-spliced check misses: a
/// cached PR row usually HAS a `body_html`, and the splice happily rewrites
/// every attachment to a pre-signed URL — but those JWTs live about five
/// minutes, so any row older than that yields URLs that are already dead. The
/// renderer used to discover this by requesting one, and only then ask for the
/// refresh that fixes it. The token says so up front, for free.
///
/// Unverified on purpose: this is not an authorization decision (the server
/// makes that), it is a "don't bother asking" decision, and the payload's `exp`
/// is enough for it. Fails OPEN — anything unparseable is treated as live, so a
/// token shape this doesn't understand still gets its fetch.
bool hasExpiredAttachmentJwt(Uri uri, {DateTime? now}) {
  // Only GitHub's pre-signed attachment host. This decodes ONE vendor's token
  // shape, and an arbitrary CDN that happens to sign with a `?jwt=` parameter
  // must not be judged by it: outside a PR body there is no `body_html` refresh
  // lane, so a wrong "expired" verdict is an image that never loads and never
  // recovers.
  if (uri.host.toLowerCase() != 'private-user-images.githubusercontent.com') {
    return false;
  }
  try {
    // INSIDE the try. `Uri.queryParameters` percent-decodes the whole query
    // eagerly and throws `FormatException` on a truncated multibyte escape, so
    // reading it outside turned a malformed URL anywhere in a document into an
    // exception thrown from `initState`.
    final jwt = uri.queryParameters['jwt'];
    if (jwt == null || jwt.isEmpty) {
      return false;
    }
    final parts = jwt.split('.');
    if (parts.length < 2) {
      return false;
    }
    final payload = jsonDecode(
      utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
    );
    if (payload is! Map) {
      return false;
    }
    final exp = payload['exp'];
    if (exp is! num) {
      return false;
    }
    final expiresAt = DateTime.fromMillisecondsSinceEpoch(
      exp.toInt() * 1000,
      isUtc: true,
    );
    // Judged against the CLIENT's clock, which is the one thing here we do not
    // control. A machine running fast would otherwise call every freshly-minted
    // token expired and never fetch a private attachment again. So the verdict
    // needs the token to be expired by more than any plausible skew, not merely
    // expired — [kAttachmentClockSkewAllowance] is wide enough that a
    // moderately wrong clock falls back to the old behaviour (fetch, discover,
    // refresh) instead of locking the image out.
    return (now ?? DateTime.now().toUtc()).isAfter(
      expiresAt.add(kAttachmentClockSkewAllowance),
    );
  } on Object {
    return false;
  }
}

/// How far past a token's stated expiry the clock has to be before the client
/// trusts its own reading of it.
///
/// GitHub's attachment tokens live about five minutes. A skew smaller than that
/// only ever costs one wasted request (the fetch fails, the host refreshes,
/// exactly as before this check existed); a skew larger than it would, without
/// this margin, make every token look dead on arrival.
const Duration kAttachmentClockSkewAllowance = Duration(minutes: 2);

/// True when fetching [uri] cannot succeed until the host re-fetches
/// `body_html` — either because the URL was never spliced, or because the JWT
/// the splice produced has since expired.
bool needsAttachmentCredentials(Uri uri, {DateTime? now}) =>
    isUnsplicedUserAttachment(uri) || hasExpiredAttachmentJwt(uri, now: now);

/// A stable identity for a piece of remote markdown media.
///
/// **Not the URL.** A pre-signed attachment URL carries a JWT that expires
/// after five minutes, so refreshing `body_html` mints a DIFFERENT URL for the
/// same bytes — and a URL-keyed memo would miss on exactly the refresh that
/// causes the visible jump. Both GitHub forms carry the attachment's UUID
/// (`/user-attachments/assets/<uuid>` and `…-<uuid>.<ext>?jwt=…`), so that is
/// the key when one is present.
///
/// Everything else keys on the WHOLE URL, query included. Dropping the query
/// there looked like it would absorb other signed URLs the same way, but for
/// most hosts the query IS the identity: `img.shields.io/static/v1?label=build`
/// and `?label=coverage` are two different badges at one path, and collapsing
/// them serves whichever loaded first for both.
String markdownMediaKey(Uri uri) {
  if (isGitHubAttachmentMedia(uri)) {
    final match = _uuidRe.firstMatch(uri.toString());
    if (match != null) {
      return 'gh-attachment:${match.group(0)!.toLowerCase()}';
    }
  }
  return uri.toString();
}

/// Remembers the intrinsic pixel size of media the app has already measured,
/// so the box can be reserved BEFORE the bytes arrive on every subsequent
/// render.
///
/// This is what turns "one settle per image, forever" into "one settle per
/// image, once": a JWT refresh, a scroll that recycles the widget, a tab
/// switch and a revisit all hit the memo and lay out at the final size from
/// the first frame. Keyed by [markdownMediaKey], so the refresh case — the one
/// that used to reset the widget to a 20px spinner mid-read — is a hit.
///
/// Intrinsic SIZE, not aspect ratio: the box resolver clamps an un-hinted
/// image to its natural width (a 300px diagram in an 800px column stays
/// 300px), so an aspect alone could not reproduce the box it is reserving for.
class MarkdownMediaMetrics {
  MarkdownMediaMetrics._();

  static const int _maxEntries = 512;
  static final Map<String, Size> _sizes = {};

  /// The measured intrinsic size for [uri], or null when nothing has decoded
  /// it yet in this session.
  static Size? sizeOf(Uri uri) {
    final key = markdownMediaKey(uri);
    final hit = _sizes.remove(key);
    if (hit != null) {
      _sizes[key] = hit; // refresh recency
    }
    return hit;
  }

  /// Records [size] as the intrinsic size of [uri]. Ignores a degenerate size
  /// so a failed probe can't poison the reserve with a zero-height box.
  static void record(Uri uri, Size size) {
    if (!size.width.isFinite ||
        !size.height.isFinite ||
        size.width <= 0 ||
        size.height <= 0) {
      return;
    }
    final key = markdownMediaKey(uri);
    _sizes
      ..remove(key)
      ..[key] = size;
    while (_sizes.length > _maxEntries) {
      _sizes.remove(_sizes.keys.first);
    }
  }

  /// Drops every remembered size.
  @visibleForTesting
  static void reset() => _sizes.clear();
}

/// The intrinsic size to lay a not-yet-loaded piece of media out at, or null
/// when nothing knows enough and the caller should fall back to its small
/// inline placeholder.
///
/// [columnWidth] only matters for the default branch: the synthesized size has
/// to be at least as wide as the column, because the box resolver reads an
/// un-hinted intrinsic width as "render at natural size, capped to the
/// column" — a narrower guess would reserve a narrower box than the screenshot
/// eventually fills.
Size? reservedMediaIntrinsic({
  required Uri uri,
  required double columnWidth,
  bool hasDimensionHint = false,
}) {
  final measured = MarkdownMediaMetrics.sizeOf(uri);
  if (measured != null) {
    return measured;
  }
  // The author declared width/height: the resolver derives the box from the
  // hint alone, and a synthetic intrinsic would only fight it.
  if (hasDimensionHint) {
    return null;
  }
  if (!isGitHubAttachmentMedia(uri)) {
    return null;
  }
  final width = columnWidth.isFinite && columnWidth > 0 ? columnWidth : 800.0;
  return Size(width, width * kDefaultAttachmentAspect);
}
