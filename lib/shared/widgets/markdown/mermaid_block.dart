import 'package:cc_markdown/cc_markdown.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/theme/font_settings.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/markdown/markdown_style.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Renders a ```` ```mermaid ```` fence as a framed figure: a slim header
/// (diagram kind + actions) over the drawn diagram.
///
/// The chrome deliberately mirrors [buildSharedCodeBlock] — same surface,
/// border, radius, and header anatomy — because a diagram and a code block are
/// the same kind of embedded artifact, and the fence they come from is a code
/// fence. What it adds is what a diagram specifically needs: **view source**
/// (the mermaid text is often the thing a developer wants to edit), **expand**
/// (a dense flowchart outgrows a chat bubble), and **copy** of the fence.
class AppMermaidBuilder extends CcNodeBuilder {
  /// Creates an [AppMermaidBuilder].
  const AppMermaidBuilder();

  @override
  Widget build(CcNode node, CcMarkdownStyle style, CcRenderContext context) {
    return AppMermaidFigure(
      source: (node as CcMermaid).source,
      style: style.mermaid,
    );
  }
}

/// Height above which a diagram is capped and gains a "show more" affordance,
/// so one large figure can't push the rest of a message off screen.
const double _kCollapsedDiagramHeight = 340;

/// The framed diagram figure: header (kind + view source / expand / copy) over
/// the drawn diagram, height-capped with a "show more".
///
/// Public because a mermaid diagram is not only a markdown fence — an artifact
/// block carries one as typed data. Both go through this one widget, so the
/// chrome, the width fit, and the expand viewer stay identical rather than
/// drifting into two half-implementations.
class AppMermaidFigure extends ConsumerStatefulWidget {
  /// Creates an [AppMermaidFigure].
  const AppMermaidFigure({super.key, required this.source, this.style});

  /// The mermaid source (the body of a ```` ```mermaid ```` fence).
  final String source;

  /// Diagram style; defaults to [appMermaidStyle] with the operator's code font.
  final CcMermaidStyle? style;

  @override
  ConsumerState<AppMermaidFigure> createState() => _AppMermaidFigureState();
}

class _AppMermaidFigureState extends ConsumerState<AppMermaidFigure> {
  bool _showSource = false;
  bool _expandedHeight = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final codeFont = ref.watch(codeFontFamilyProvider);
    final codeLigatures = ref.watch(codeFontLigaturesProvider);
    final mermaidStyle =
        widget.style ?? appMermaidStyle(context, codeFontFamily: codeFont);

    final plan = resolveMermaidRenderPlan(
      source: widget.source,
      style: mermaidStyle,
      textScaler: MediaQuery.textScalerOf(context),
    );
    final reason = plan.reason;

    // Undrawable: hand the source to the shared code block (highlighting, copy,
    // collapse) and say why in one muted line — never a blank frame.
    if (reason != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          buildSharedCodeBlock(
            context,
            widget.source,
            'mermaid',
            codeFontFamily: codeFont,
            codeLigatures: codeLigatures,
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 2),
            child: Text(
              l10n.diagramPreviewUnavailable(reason),
              style: TextStyle(color: tokens.textQuaternary, fontSize: 11),
            ),
          ),
        ],
      );
    }

    final kindLabel = plan.diagram?.kindLabel ?? 'mermaid';
    return LayoutBuilder(
      builder: (context, constraints) {
        // Measure the height the diagram will ACTUALLY have: a wide flowchart
        // scaled down to the bubble width is far shorter than its logical size,
        // and collapsing one that already fits would be pure friction.
        final scene = plan.scene!;
        final available = constraints.maxWidth.isFinite
            ? constraints.maxWidth - 20
            : scene.size.width;
        final scale = scene.size.width <= 0
            ? 1.0
            : (available / scene.size.width)
                  .clamp(mermaidStyle.minScale, mermaidStyle.maxScale)
                  .toDouble();
        final tall = scene.size.height * scale > _kCollapsedDiagramHeight;
        return _frame(
          context,
          l10n,
          tokens,
          mermaidStyle,
          kindLabel,
          tall: tall,
        );
      },
    );
  }

  Widget _frame(
    BuildContext context,
    AppLocalizations l10n,
    DesignSystemTokens tokens,
    CcMermaidStyle mermaidStyle,
    String kindLabel, {
    required bool tall,
  }) {
    final codeFont = ref.watch(codeFontFamilyProvider);
    final codeLigatures = ref.watch(codeFontLigaturesProvider);
    return Container(
      decoration: BoxDecoration(
        color: tokens.bgSecondary,
        borderRadius: AppRadii.brLg,
        border: Border.all(color: tokens.borderSecondary),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header(context, l10n, tokens, kindLabel),
          if (_showSource)
            Padding(
              padding: const EdgeInsets.all(8),
              child: buildSharedCodeBlock(
                context,
                widget.source,
                'mermaid',
                codeFontFamily: codeFont,
                codeLigatures: codeLigatures,
              ),
            )
          else
            _diagram(context, mermaidStyle, tall: tall),
          if (!_showSource && tall)
            Container(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: tokens.borderSecondary)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Align(
                alignment: Alignment.centerLeft,
                child: CcButton(
                  variant: CcButtonVariant.ghost,
                  size: CcButtonSize.sm,
                  icon: _expandedHeight
                      ? AppIcons.chevronUp
                      : AppIcons.chevronDown,
                  onPressed: () =>
                      setState(() => _expandedHeight = !_expandedHeight),
                  child: Text(_expandedHeight ? l10n.showLess : l10n.showMore),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _header(
    BuildContext context,
    AppLocalizations l10n,
    DesignSystemTokens tokens,
    String kindLabel,
  ) {
    return Container(
      padding: kCodeBlockHeaderPadding,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: tokens.borderSecondary)),
      ),
      child: Row(
        children: [
          Icon(AppIcons.workflow, size: 13, color: tokens.textQuaternary),
          const SizedBox(width: 6),
          Text(
            kindLabel,
            style: TextStyle(color: tokens.textTertiary, fontSize: 12),
          ),
          const Spacer(),
          CcIconButton(
            icon: _showSource ? AppIcons.image : AppIcons.code,
            size: CcButtonSize.sm,
            color: tokens.textTertiary,
            tooltip: _showSource
                ? l10n.diagramHideSource
                : l10n.diagramViewSource,
            onPressed: () => setState(() => _showSource = !_showSource),
          ),
          CcIconButton(
            icon: AppIcons.maximize2,
            size: CcButtonSize.sm,
            color: tokens.textTertiary,
            tooltip: l10n.expand,
            onPressed: () => _openViewer(context),
          ),
          _CopyDiagramButton(source: widget.source),
        ],
      ),
    );
  }

  Widget _diagram(
    BuildContext context,
    CcMermaidStyle mermaidStyle, {
    required bool tall,
  }) {
    final diagram = Padding(
      padding: const EdgeInsets.all(10),
      child: CcMermaidView(source: widget.source, style: mermaidStyle),
    );
    if (!tall || _expandedHeight) {
      return diagram;
    }
    // Clip rather than scroll: a nested vertical scroll inside a feed steals the
    // feed's gesture. The full diagram is one tap away (show more / expand).
    return ClipRect(
      child: SizedBox(
        height: _kCollapsedDiagramHeight,
        child: OverflowBox(
          alignment: Alignment.topCenter,
          maxHeight: double.infinity,
          child: diagram,
        ),
      ),
    );
  }

  Future<void> _openViewer(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final codeFont = ref.read(codeFontFamilyProvider);
    await showCcDialog<void>(
      context: context,
      builder: (dialogContext) => CcDialog(
        title: l10n.diagram,
        maxWidth: 1100,
        onClose: () => Navigator.of(dialogContext).pop(),
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(dialogContext).height * 0.75,
          ),
          child: CcMermaidView(
            source: widget.source,
            style: appMermaidStyle(dialogContext, codeFontFamily: codeFont),
            interactive: true,
          ),
        ),
      ),
    );
  }
}

/// Copies the diagram back as a fenced mermaid block, so a paste round-trips
/// into any markdown surface (a bare body would render as prose).
class _CopyDiagramButton extends StatefulWidget {
  const _CopyDiagramButton({required this.source});

  final String source;

  @override
  State<_CopyDiagramButton> createState() => _CopyDiagramButtonState();
}

class _CopyDiagramButtonState extends State<_CopyDiagramButton> {
  bool _copied = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    return CcIconButton(
      icon: _copied ? AppIcons.check : AppIcons.copy,
      size: CcButtonSize.sm,
      color: tokens.textTertiary,
      tooltip: _copied ? l10n.copied : l10n.copy,
      onPressed: () {
        Clipboard.setData(
          ClipboardData(text: '```mermaid\n${widget.source}\n```'),
        );
        setState(() => _copied = true);
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() => _copied = false);
          }
        });
      },
    );
  }
}
