import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/markdown/markdown_syntax_actions.dart';
import 'package:control_center/shared/widgets/markdown/markdown_toolbar.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// The shared GitHub-style Write/Preview markdown editing surface: ONE
/// bordered box whose header holds the Write/Preview tabs on the left and the
/// [MarkdownToolbar] on the right (Write mode only), whose body swaps the
/// editor field for a live preview and whose footer carries the "Markdown is
/// supported" hint plus the attach affordance. The whole box takes the focus
/// ring, the way a field does. Cmd/Ctrl + B/I/K formatting shortcuts work in
/// Write mode. Editing operates on raw markdown; Preview reuses the same
/// renderer as the read view, so there is no GFM round-trip loss.
///
/// This widget owns only the tab state and the shared chrome. The host
/// supplies the write-mode field via [fieldBuilder] — which must render
/// CHROMELESS (`MarkdownTextField(bare: true)` / `MentionAutocompleteField`;
/// both leave the fill, border and focus ring to this box) — and the preview
/// body via [previewBuilder]. Save/Cancel buttons, read/edit toggling,
/// template pickers and any domain-specific persistence stay in the host.
class MarkdownEditor extends StatefulWidget {
  /// Creates a [MarkdownEditor].
  const MarkdownEditor({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.fieldBuilder,
    required this.previewBuilder,
    this.toolbarTrailing = const <Widget>[],
    this.onAttach,
    this.footer,
  });

  /// Extra buttons appended to the [MarkdownToolbar] (emoji, GIF …).
  final List<Widget> toolbarTrailing;

  /// Attaches files to the draft (an image upload). Non-null adds a toolbar
  /// button and the footer's click-to-add hint, both wired to this handler;
  /// null offers no attach affordance at all. Only hosts that can actually
  /// upload (repo write access) should supply one.
  final Future<void> Function()? onAttach;

  /// Built under the box in BOTH modes — submit buttons and the like, which
  /// must not disappear when the host switches to Preview.
  final WidgetBuilder? footer;

  /// The editor's text controller (shared with [fieldBuilder] and the toolbar).
  final TextEditingController controller;

  /// The editor's focus node (shared with [fieldBuilder] and the toolbar);
  /// the whole box draws its focus ring from it.
  final FocusNode focusNode;

  /// Builds the write-mode input field, chromeless — the box owns the fill,
  /// border and focus ring. Receives the same context; reads
  /// [controller]/[focusNode] from the host's closure.
  final WidgetBuilder fieldBuilder;

  /// Builds the preview-mode rendered markdown. Called lazily only while the
  /// Preview tab is active, so it reads the live [controller] text.
  final WidgetBuilder previewBuilder;

  @override
  State<MarkdownEditor> createState() => _MarkdownEditorState();
}

class _MarkdownEditorState extends State<MarkdownEditor> {
  bool _showPreview = false;

  /// The write body's last measured height. The preview adopts it as its
  /// minimum, so flipping tabs never changes the box's height unless the
  /// rendered content genuinely needs more (an image, a big table).
  double? _writeBodyHeight;

  void _storeWriteBodyHeight(Size size) {
    if (!mounted || size.height == _writeBodyHeight) {
      return;
    }
    setState(() => _writeBodyHeight = size.height);
  }

  void _applyFormat(TextEditingValue Function(TextEditingValue) transform) {
    widget.controller.value = transform(widget.controller.value);
    widget.focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final borderRadius = BorderRadius.circular(2);

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyB, meta: true): () =>
            _applyFormat((v) => wrapSelection(v, '**', '**')),
        const SingleActivator(LogicalKeyboardKey.keyB, control: true): () =>
            _applyFormat((v) => wrapSelection(v, '**', '**')),
        const SingleActivator(LogicalKeyboardKey.keyI, meta: true): () =>
            _applyFormat((v) => wrapSelection(v, '_', '_')),
        const SingleActivator(LogicalKeyboardKey.keyI, control: true): () =>
            _applyFormat((v) => wrapSelection(v, '_', '_')),
        const SingleActivator(LogicalKeyboardKey.keyK, meta: true): () =>
            _applyFormat(insertLink),
        const SingleActivator(LogicalKeyboardKey.keyK, control: true): () =>
            _applyFormat(insertLink),
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          FocusRing(
            focusNode: widget.focusNode,
            borderRadius: borderRadius,
            child: Container(
              decoration: BoxDecoration(
                color: t.panel,
                borderRadius: borderRadius,
                border: Border.all(color: t.borderSecondary),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _HeaderRow(
                    showPreview: _showPreview,
                    onChanged: (i) => setState(() => _showPreview = i == 1),
                    toolbar: MarkdownToolbar(
                      controller: widget.controller,
                      focusNode: widget.focusNode,
                      alignment: WrapAlignment.end,
                      trailing: [
                        ...widget.toolbarTrailing,
                        if (widget.onAttach case final attach?)
                          CcIconButton(
                            variant: CcButtonVariant.ghost,
                            size: CcButtonSize.sm,
                            onPressed: attach,
                            icon: AppIcons.image,
                            tooltip: l10n.attachImage,
                          ),
                      ],
                    ),
                  ),
                  if (!_showPreview)
                    _SizeReportingWidget(
                      onSizeChange: _storeWriteBodyHeight,
                      child: widget.fieldBuilder(context),
                    )
                  else
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: _writeBodyHeight ?? 120,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                        child: widget.previewBuilder(context),
                      ),
                    ),
                  // Preview hides the hints (GitHub parity) but keeps their
                  // height, so the box does not jump between tabs.
                  Visibility(
                    visible: !_showPreview,
                    maintainState: true,
                    maintainAnimation: true,
                    maintainSize: true,
                    child: _FooterRow(onAttach: widget.onAttach),
                  ),
                ],
              ),
            ),
          ),
          if (widget.footer case final footer?) footer(context),
        ],
      ),
    );
  }
}

/// The box's header: Write/Preview tabs flush left, the formatting toolbar
/// flush right. Preview hides the toolbar the way GitHub does (nothing in it
/// would act) but reserves its height, so the row — and with it the whole
/// box — stays put when the tab flips.
///
/// The row's divider is drawn in TWO pieces on purpose: [CcTabs] already owns
/// a bottom rule across the strip, so the header contributes one only for the
/// remaining width. A rule spanning the whole row would sit directly under the
/// strip's, and the two 1px lines read as a single 2px one under the tabs and
/// 1px everywhere else — a doubled border. Both halves use the same color and,
/// because the row aligns its children's bottoms, land on the same y.
class _HeaderRow extends StatelessWidget {
  const _HeaderRow({
    required this.showPreview,
    required this.onChanged,
    required this.toolbar,
  });

  final bool showPreview;
  final ValueChanged<int> onChanged;
  final Widget toolbar;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    return Row(
      // Bottoms align so the tabs' rule and this row's continue each other on
      // one y, even when a narrow surface wraps the toolbar onto two rows.
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        CcTabs(
          tabs: [CcTab(l10n.write), CcTab(l10n.preview)],
          selectedIndex: showPreview ? 1 : 0,
          onChanged: onChanged,
        ),
        Expanded(
          child: Container(
            // The strip's rule stops where the tabs do; this carries it the
            // rest of the way. See the class doc for why it is not one rule.
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: t.borderPrimary)),
            ),
            padding: const EdgeInsets.fromLTRB(8, 4, 6, 4),
            child: Align(
              alignment: AlignmentDirectional.centerEnd,
              // Preview hides the toolbar (GitHub parity — nothing in it
              // would act) but reserves its exact height, wrapped rows
              // included, so the header does not jump between tabs.
              child: Visibility(
                visible: !showPreview,
                maintainState: true,
                maintainAnimation: true,
                maintainSize: true,
                child: toolbar,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The box's footer: what the format support is, and — when the host can
/// upload — how to attach. Hints, not actions; the attach hint doubles as a
/// second way into the same handler the toolbar button carries.
class _FooterRow extends StatelessWidget {
  const _FooterRow({this.onAttach});

  final Future<void> Function()? onAttach;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: t.borderSecondary)),
      ),
      padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
      child: Row(
        // spaceBetween, not a Spacer: a Spacer between two loose Flexibles
        // claims a full flex share, so the attach hint's unused allotment
        // ended up trailing the row and left the hint floating mid-row.
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Both hints ellipsize under pressure: translated strings and wide
          // test fonts must never overflow the box.
          Flexible(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                l10n.markdownSupported,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: CcTypography.caption.copyWith(color: t.textTertiary),
              ),
            ),
          ),
          if (onAttach case final attach?)
            Flexible(
              child: CcTappable(
                onPressed: attach,
                semanticLabel: l10n.markdownAttachImages,
                builder: (context, states) {
                  final active =
                      states.contains(WidgetState.hovered) ||
                      states.contains(WidgetState.focused);
                  final color = active ? t.textSecondary : t.textTertiary;
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Icon(AppIcons.image, size: 13, color: color),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            l10n.markdownAttachImages,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: CcTypography.caption.copyWith(color: color),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

/// Reports its child's laid-out size after any layout that changes it.
///
/// The pinned SDK predates the framework's own `SizeReportingWidget`; this is
/// the same pattern (a proxy render object observing `performLayout`).
class _SizeReportingWidget extends SingleChildRenderObjectWidget {
  const _SizeReportingWidget({required this.onSizeChange, super.child});

  final ValueChanged<Size> onSizeChange;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderSizeReporter(onSizeChange);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderSizeReporter renderObject,
  ) {
    renderObject.onSizeChange = onSizeChange;
  }
}

class _RenderSizeReporter extends RenderProxyBox {
  _RenderSizeReporter(this.onSizeChange);

  ValueChanged<Size> onSizeChange;
  Size? _oldSize;

  @override
  void performLayout() {
    super.performLayout();
    final newSize = size;
    if (_oldSize == newSize) {
      return;
    }
    _oldSize = newSize;
    // setState mid-layout is illegal — hand the new size back after the frame.
    WidgetsBinding.instance.addPostFrameCallback((_) => onSizeChange(newSize));
  }
}
