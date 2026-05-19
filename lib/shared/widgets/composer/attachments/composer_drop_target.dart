import 'dart:async';

import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/infrastructure/clipboard/host_clipboard.dart';
import 'package:control_center/core/infrastructure/drag_drop/host_file_drop.dart';
import 'package:control_center/core/utils/app_log.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/attachments/local_media.dart';
import 'package:control_center/shared/widgets/composer/attachments/attachment_media.dart';
import 'package:control_center/shared/widgets/composer/composer_models.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as p;
import 'package:super_clipboard/super_clipboard.dart'
    show DataFormat, DataReader, Formats;
import 'package:super_drag_and_drop/super_drag_and_drop.dart';

/// What came out of a drop onto the composer.
@immutable
class ComposerDrop {
  /// Creates a [ComposerDrop].
  const ComposerDrop({this.attachments = const [], this.text});

  /// Files and pictures to attach.
  final List<ComposerAttachment> attachments;

  /// Plain text dropped with nothing else — inserted at the caret.
  final String? text;

  /// Whether the drop carried nothing usable.
  bool get isEmpty => attachments.isEmpty && (text == null || text!.isEmpty);
}

/// Largest picture read into memory on a drop.
///
/// Matches the clipboard's own ceiling (and the server's), because both ends of
/// the image lane have to agree: reading a 40 MB screenshot here only to have
/// `blob.put` refuse it on send would spend the memory and lose the image
/// anyway.
const int kMaxDroppedImageBytes = 16 * 1024 * 1024;

/// Accepts files and pictures dragged onto the composer from the OS, and says
/// so before the user lets go.
///
/// **Two layers, and both are load-bearing.** The [DropRegion] accepts the drop;
/// the [DropMonitor] wrapped around it reports EVERY drag anywhere over the
/// application, with `isInside` saying whether it is over this composer. That is
/// what lets the composer advertise itself as a target the moment a drag enters
/// the window rather than only once the pointer is already on top of it — a
/// target you have to find before it admits it exists is not discoverable.
///
/// **Why the read is selective.** The shared `snapshotFromReader` loads every
/// dropped file's bytes, which is right for a rig (the bytes have to cross into
/// a VM) and wrong here: a composer needs bytes only for a PICTURE, which it
/// uploads, and a path for everything else, which the agent opens itself from
/// the filesystem it already shares. Slurping indiscriminately would read a
/// four-gigabyte video into memory to put a chip on a toolbar.
///
/// A dropped picture with no file behind it (dragged out of a browser) has only
/// bytes, so that case still reads them — bounded by [kMaxDroppedImageBytes].
class ComposerDropTarget extends StatefulWidget {
  /// Creates a [ComposerDropTarget].
  const ComposerDropTarget({
    super.key,
    required this.child,
    required this.onDrop,
    this.insets = EdgeInsets.zero,
    this.enabled = true,
  });

  /// The composer box.
  final Widget child;

  /// Called with everything a completed drop produced.
  final Future<void> Function(ComposerDrop drop) onDrop;

  /// The child's own outer margin, so the affordance lands ON the composer's
  /// border instead of floating in the gutter beside it. Passed in rather than
  /// duplicated, so the two cannot drift apart.
  final EdgeInsets insets;

  /// When false the region refuses drops (and shows no affordance).
  final bool enabled;

  @override
  State<ComposerDropTarget> createState() => _ComposerDropTargetState();
}

class _ComposerDropTargetState extends State<ComposerDropTarget> {
  /// A drag is in flight somewhere over the application.
  bool _armed = false;

  /// That drag is over this composer.
  bool _inside = false;

  StreamSubscription<HostDropEvent>? _hostDrops;

  @override
  void initState() {
    super.initState();
    // The host lane (macOS). Started here rather than at boot so the channel
    // handler exists only while something is listening for a drop.
    HostFileDrop.instance
      ..start()
      ..dragging.addListener(_onHostDrag);
    _hostDrops = HostFileDrop.instance.onDrop.listen(_onHostDrop);
  }

  @override
  void dispose() {
    HostFileDrop.instance.dragging.removeListener(_onHostDrag);
    unawaited(_hostDrops?.cancel());
    super.dispose();
  }

  void _setState({bool? armed, bool? inside}) {
    final nextArmed = armed ?? _armed;
    final nextInside = inside ?? _inside;
    if (!mounted || (_armed == nextArmed && _inside == nextInside)) {
      return;
    }
    setState(() {
      _armed = nextArmed;
      _inside = nextInside;
    });
  }

  void _disarm() => _setState(armed: false, inside: false);

  // ---------------------------------------------------------------------------
  // Host lane (macOS): the OS reports a position, this widget decides whether
  // the position is its own.
  // ---------------------------------------------------------------------------

  void _onHostDrag() {
    final event = HostFileDrop.instance.dragging.value;
    if (event == null) {
      _disarm();
      return;
    }
    _setState(
      armed: widget.enabled,
      inside: _containsHostPoint(event.viewId, event.position),
    );
  }

  Future<void> _onHostDrop(HostDropEvent event) async {
    _disarm();
    if (!widget.enabled || !_containsHostPoint(event.viewId, event.position)) {
      return;
    }
    final drop = await _readHostDrop(event);
    if (!mounted || drop.isEmpty) {
      return;
    }
    await widget.onDrop(drop);
  }

  /// Whether [position], reported in view [viewId], is inside this composer.
  ///
  /// The view check is what keeps a drag over a HUD panel from lighting up the
  /// composer in the main window: both report positions in their own view's
  /// coordinates, which overlap numerically. A host that could not resolve a
  /// view id sends -1, and the check is skipped rather than failing closed —
  /// no drop at all is worse than a rare false positive on a window that has no
  /// composer in it.
  bool _containsHostPoint(int viewId, Offset position) {
    if (!mounted) {
      return false;
    }
    if (viewId >= 0 && View.of(context).viewId != viewId) {
      return false;
    }
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) {
      return false;
    }
    return box.paintBounds.contains(box.globalToLocal(position));
  }

  // ---------------------------------------------------------------------------
  // Plugin lane (everything else).
  // ---------------------------------------------------------------------------

  Future<void> _perform(PerformDropEvent event) async {
    _disarm();
    final readers = [
      for (final item in event.session.items)
        if (item.dataReader != null) item.dataReader!,
    ];
    final drop = await _readDrop(readers);
    if (!mounted) {
      return;
    }
    if (drop.isEmpty) {
      // Reaching here means the drop was accepted and produced nothing — the
      // one outcome that looks identical to a broken drop target. Named in the
      // log so it is distinguishable from "the region never fired".
      AppLog.d('composer', 'drop produced no attachments (${readers.length})');
      return;
    }
    await widget.onDrop(drop);
  }

  @override
  Widget build(BuildContext context) {
    final ds = context.designSystem ?? DesignSystemTokens.light();
    return DropMonitor(
      formats: Formats.standardFormats,
      // Opaque so the monitor answers for the composer's whole box, gutter
      // included; `deferToChild` would report "outside" over the padding
      // between the field and its border.
      hitTestBehavior: HitTestBehavior.opaque,
      onDropOver: (event) => widget.enabled
          ? _setState(
              armed: _sessionMayCarryFiles(event.session),
              inside: event.isInside,
            )
          : null,
      onDropLeave: (_) => _disarm(),
      onDropEnded: (_) => _disarm(),
      child: DropRegion(
        formats: Formats.standardFormats,
        // Opaque, matching the terminal and rig regions that already work.
        // `RenderProxyBoxWithHitTestBehavior` still hit-tests children first,
        // so the text field, its selection gestures and the toolbar buttons
        // keep receiving pointers exactly as before; opaque only additionally
        // claims the gaps between them, which is where a drop often lands.
        hitTestBehavior: HitTestBehavior.opaque,
        // Copy, never move — dropping a file into a message must not invite
        // Finder to delete the original.
        onDropOver: (_) =>
            widget.enabled ? DropOperation.copy : DropOperation.none,
        onPerformDrop: _perform,
        child: Stack(
          children: [
            widget.child,
            if (_armed && widget.enabled)
              Positioned.fill(
                // The affordance must never eat the drop it is advertising.
                child: IgnorePointer(
                  child: _DropAffordance(
                    tokens: ds,
                    insets: widget.insets,
                    over: _inside,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// The composer's "you can drop here" state, in its two strengths.
///
/// **Armed** (a drag is over the app, but not over the composer) draws a dashed
/// accent ring and a small caption, and deliberately does NOT wash the box: the
/// draft underneath stays readable while the person is still deciding where to
/// let go.
///
/// **Over** (the drag is on the composer) fills the box, because at that point
/// the only thing worth saying is that letting go now will work.
class _DropAffordance extends StatelessWidget {
  const _DropAffordance({
    required this.tokens,
    required this.insets,
    required this.over,
  });

  final DesignSystemTokens tokens;
  final EdgeInsets insets;
  final bool over;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final caption = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: over ? tokens.accent : tokens.bgPrimary,
        borderRadius: AppRadii.brSm,
        border: Border.all(color: tokens.accent),
        boxShadow: over ? null : AppShadows.soft,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            AppIcons.upload,
            size: 14,
            color: over ? tokens.accentOn : tokens.accent,
          ),
          const SizedBox(width: 6),
          Text(
            l10n.composerDropToAttach,
            style: CcTypography.bodySm.copyWith(
              color: over ? tokens.accentOn : tokens.accent,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );

    return Padding(
      padding: insets,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        decoration: BoxDecoration(
          color: over
              ? tokens.accentSoft.withValues(alpha: 0.86)
              : const Color(0x00000000),
          borderRadius: AppRadii.brMd,
          border: over ? Border.all(color: tokens.accent, width: 1.5) : null,
        ),
        child: CustomPaint(
          painter: over
              ? null
              : _DashedRingPainter(
                  color: tokens.accent,
                  radius: AppRadii.brMd.topLeft.x,
                ),
          child: Center(child: caption),
        ),
      ),
    );
  }
}

/// A dashed rounded rectangle, drawn as a dash-phase path effect on the box's
/// own outline.
///
/// Hand-rolled because the design system has no dashed border and a dashed edge
/// is the one visual convention that says "this is a drop target" without a
/// legend. Kept as a painter rather than an image so it follows the accent
/// token through a theme change.
class _DashedRingPainter extends CustomPainter {
  const _DashedRingPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  static const double _dash = 6;
  static const double _gap = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final outline = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          // Inset by half the stroke so the dashes sit ON the edge rather than
          // straddling it, which would clip their outer half.
          Rect.fromLTWH(0.75, 0.75, size.width - 1.5, size.height - 1.5),
          Radius.circular(radius),
        ),
      );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (final metric in outline.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = (distance + _dash).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance = end + _gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRingPainter old) =>
      old.color != color || old.radius != radius;
}

/// Whether a session looks like it carries something the composer can take.
///
/// Deliberately permissive — `canProvide` is documented as a best guess, and an
/// empty item list early in a session is normal on some platforms. The check
/// exists to stop the composer lighting up for a drag that obviously has
/// nothing for it (a window, a colour swatch), not to police the drop.
bool _sessionMayCarryFiles(DropSession session) {
  if (session.items.isEmpty) {
    return true;
  }
  for (final item in session.items) {
    // Explicitly typed: the entries are `DataFormat<Uri>`,
    // `DataFormat<Uint8List>` and `DataFormat<String>`, whose inferred common
    // supertype is plain `Object`.
    for (final format in const <DataFormat<Object>>[
      Formats.fileUri,
      Formats.png,
      Formats.jpeg,
      Formats.gif,
      Formats.webp,
      Formats.tiff,
      Formats.pdf,
      Formats.plainTextFile,
      Formats.csv,
      Formats.zip,
      Formats.plainText,
    ]) {
      if (item.canProvide(format)) {
        return true;
      }
    }
  }
  return false;
}

/// Turns a host drop into composer attachments.
///
/// The same rule the reader path follows, arrived at more cheaply: bytes are
/// read only for a PICTURE, because only a picture is uploaded with the
/// message. Everything else travels as the path the host already gave us, which
/// the agent opens from the filesystem it shares — no read, whatever the file
/// weighs.
Future<ComposerDrop> _readHostDrop(HostDropEvent event) async {
  final attachments = <ComposerAttachment>[];
  for (final path in event.paths) {
    final name = p.basename(path);
    final mimeType = mediaTypeForFileName(name);
    final isImage = (mimeType ?? '').startsWith('image/');
    final bytes = isImage
        ? await readLocalBytes(path, maxBytes: kMaxDroppedImageBytes)
        : null;
    attachments.add(
      ComposerAttachment(
        id: 'file:$path',
        // A picture too large to carry (readLocalBytes refuses past the
        // ceiling) degrades to a plain file reference rather than vanishing.
        kind: isImage && bytes != null ? 'image' : 'file',
        label: name,
        path: path,
        bytes: bytes,
        mimeType: mimeType,
        sizeBytes: bytes?.length ?? await localFileSize(path),
      ),
    );
  }
  // Pictures with no file behind them (a browser drag) arrive as bytes.
  for (var i = 0; i < event.images.length; i++) {
    final bytes = event.images[i];
    attachments.add(
      ComposerAttachment(
        id: 'drop:${identityHashCode(bytes)}:${bytes.length}',
        kind: 'image',
        label: 'dropped.png',
        bytes: bytes,
        mimeType: 'image/png',
        sizeBytes: bytes.length,
      ),
    );
  }
  return ComposerDrop(attachments: attachments);
}

/// Turns drop-session readers into composer attachments.
///
/// Order matters, and it is the same reason `snapshotFromReader` documents:
/// a file dragged out of Finder ALSO offers its name as plain text, so testing
/// for text first turns every file drop into a paste of the string
/// "report.pdf".
Future<ComposerDrop> _readDrop(List<DataReader> readers) async {
  final attachments = <ComposerAttachment>[];
  String? text;
  for (final item in readers) {
    final asFile = hostFileFormatFor(item);
    if (asFile.isFile) {
      final attachment = await _readFileItem(item, asFile.format);
      if (attachment != null) {
        attachments.add(attachment);
        continue;
      }
    }
    // A picture with no file behind it: dragged out of a browser or a design
    // tool, which offer bytes and nothing else.
    final image = await _readImageItem(item);
    if (image != null) {
      attachments.add(image);
      continue;
    }
    if (text == null && item.canProvide(Formats.plainText)) {
      text = await readHostValue(item, Formats.plainText);
    }
  }
  return ComposerDrop(attachments: attachments, text: text);
}

/// Reads one file item — bytes for a picture, a path for everything else.
Future<ComposerAttachment?> _readFileItem(
  DataReader item,
  FileFormat? format,
) async {
  final path = await _localPath(item);
  final name = path == null ? null : p.basename(path);
  final mimeFromName = name == null ? null : mediaTypeForFileName(name);
  final isImage = (mimeFromName ?? '').startsWith('image/');

  // Not a picture and we know where it lives: the agent shares this
  // filesystem, so the path IS the attachment. Nothing is read.
  if (path != null && !isImage) {
    return ComposerAttachment(
      id: 'file:$path',
      kind: 'file',
      label: name!,
      path: path,
      mimeType: mimeFromName,
    );
  }

  final file = await readHostFile(item, format: format);
  if (file == null) {
    // A file we could not read but DO have a path for is still a usable
    // reference — the agent opens it by path, and only the preview is lost.
    if (path != null) {
      return ComposerAttachment(
        id: 'file:$path',
        kind: 'file',
        label: name!,
        path: path,
        mimeType: mimeFromName,
      );
    }
    return null;
  }
  final resolvedName = name ?? file.name;
  final mime =
      file.mediaType ?? mimeFromName ?? mediaTypeForFileName(resolvedName);
  final isPicture = (mime ?? '').startsWith('image/');
  if (isPicture && file.bytes.length > kMaxDroppedImageBytes) {
    // Too large to carry, but not lost: with a path it is still attachable as
    // a reference the agent can open.
    AppLog.d(
      'composer',
      'dropped image ${file.bytes.length} B exceeds the attach ceiling',
    );
    if (path == null) {
      return null;
    }
    return ComposerAttachment(
      id: 'file:$path',
      kind: 'file',
      label: resolvedName,
      path: path,
      mimeType: mime,
      sizeBytes: file.bytes.length,
    );
  }
  return ComposerAttachment(
    id: path != null ? 'file:$path' : 'drop:$resolvedName:${file.bytes.length}',
    kind: isPicture ? 'image' : 'file',
    label: resolvedName,
    path: path,
    bytes: file.bytes,
    mimeType: mime,
    sizeBytes: file.bytes.length,
  );
}

/// Reads a bytes-only picture (a browser drag), or null when there is none.
Future<ComposerAttachment?> _readImageItem(DataReader item) async {
  for (final (format, mimeType) in const [
    (Formats.png, 'image/png'),
    (Formats.jpeg, 'image/jpeg'),
  ]) {
    if (!item.canProvide(format)) {
      continue;
    }
    final read = await readHostFile(item, format: format);
    if (read == null || read.bytes.isEmpty) {
      return null;
    }
    if (read.bytes.length > kMaxDroppedImageBytes) {
      AppLog.d('composer', 'dropped image exceeds the attach ceiling');
      return null;
    }
    final extension = mimeType.split('/').last;
    return ComposerAttachment(
      // Content-independent: dropping the same picture twice is two
      // deliberate attachments.
      id: 'drop:${identityHashCode(read.bytes)}:${read.bytes.length}',
      kind: 'image',
      label: read.name.contains('.') ? read.name : 'dropped.$extension',
      bytes: read.bytes,
      mimeType: mimeType,
      sizeBytes: read.bytes.length,
    );
  }
  return null;
}

/// The local filesystem path an item names, or null when it names none.
Future<String?> _localPath(DataReader item) async {
  if (!item.canProvide(Formats.fileUri)) {
    return null;
  }
  final uri = await readHostValue(item, Formats.fileUri);
  if (uri == null || !uri.isScheme('file')) {
    return null;
  }
  try {
    return uri.toFilePath();
  } on Object {
    // Well-formed as a URI, not a path on this platform. Dropping it here
    // leaves the caller to fall back to the bytes.
    return null;
  }
}
