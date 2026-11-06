import 'package:cc_markdown/cc_markdown.dart' show CcSelectionRegion;
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';

const _followThreshold = 48.0;

/// Read-only output that grows while someone watches it.
///
/// Follows the tail until the reader scrolls away and picks it up again when
/// they return to the bottom.
class LiveLogView extends StatefulWidget {
  /// Creates a [LiveLogView].
  const LiveLogView({
    super.key,
    required this.title,
    required this.lines,
    required this.emptyMessage,
    required this.onCopy,
  });

  /// What the output belongs to, in the header row.
  final Widget title;

  /// The output so far. A new list means new output.
  final List<String> lines;

  /// Shown while [lines] is empty.
  final String emptyMessage;

  /// Copies the whole output.
  final ValueChanged<String> onCopy;

  @override
  State<LiveLogView> createState() => _LiveLogViewState();
}

class _LiveLogViewState extends State<LiveLogView> {
  final _scroll = ScrollController();
  bool _follow = true;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_trackFollow);
    _stickToEnd();
  }

  @override
  void didUpdateWidget(covariant LiveLogView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.lines, oldWidget.lines)) {
      _stickToEnd();
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _trackFollow() {
    if (!_scroll.hasClients) {
      return;
    }
    final position = _scroll.position;
    _follow = position.maxScrollExtent - position.pixels <= _followThreshold;
  }

  void _stickToEnd() {
    if (!_follow) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final lines = widget.lines;
    return ColoredBox(
      color: t.bgPrimary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xxs,
            ),
            child: Row(
              children: [
                Expanded(child: widget.title),
                CcIconButton(
                  icon: AppIcons.copy,
                  size: CcButtonSize.sm,
                  tooltip: l10n.copyLogs,
                  onPressed: lines.isEmpty
                      ? null
                      : () => widget.onCopy(lines.join('\n')),
                ),
              ],
            ),
          ),
          const CcDivider(),
          Expanded(
            child: lines.isEmpty
                ? CcEmptyState(
                    icon: AppIcons.scrollText,
                    size: CcEmptyStateSize.sm,
                    message: widget.emptyMessage,
                  )
                // RTL carve-out: logs read left to right in every locale.
                : Directionality(
                    textDirection: TextDirection.ltr,
                    child: CcSelectionRegion(
                      child: ListView.builder(
                        controller: _scroll,
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        itemCount: lines.length,
                        itemBuilder: (context, index) => Text(
                          lines[index],
                          style: CcFonts.code(
                            textStyle: CcTypography.caption.copyWith(
                              color: t.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
