import 'package:control_center/core/theme/app_radii.dart';
import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:control_center/shared/widgets/github_markdown_body.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class MarkdownEditableField extends StatefulWidget {
  const MarkdownEditableField({
    super.key,
    required this.text,
    required this.hint,
    required this.onSave,
  });

  final String text;
  final String hint;
  final ValueChanged<String> onSave;

  @override
  State<MarkdownEditableField> createState() => _MarkdownEditableFieldState();
}

class _MarkdownEditableFieldState extends State<MarkdownEditableField> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.text);
  final FocusNode _focus = FocusNode();
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (!_focus.hasFocus && _editing) {
        _commit();
      }
    });
  }

  @override
  void didUpdateWidget(MarkdownEditableField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_editing && widget.text != _controller.text) {
      _controller.text = widget.text;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _enterEdit() {
    setState(() => _editing = true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  void _commit() {
    if (_controller.text != widget.text) {
      widget.onSave(_controller.text);
    }
    if (mounted) {
      setState(() => _editing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();

    if (_editing) {
      return Container(
        decoration: BoxDecoration(
          color: t.bgSecondary,
          borderRadius: AppRadii.brSm,
          border: Border.all(color: t.borderSecondary),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: TextField(
          controller: _controller,
          focusNode: _focus,
          maxLines: null,
          minLines: 4,
          cursorColor: t.fgBrandPrimary,
          style: TextStyle(
            fontSize: 13.5,
            height: 1.5,
            color: t.textSecondary,
            fontFamilyFallback: const ['monospace'],
          ),
          decoration: InputDecoration(
            isCollapsed: true,
            border: InputBorder.none,
            hintText: widget.hint,
            hintStyle: TextStyle(color: t.textPlaceholder),
          ),
        ),
      );
    }

    if (widget.text.trim().isEmpty) {
      return FTappable(
        onPress: _enterEdit,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            widget.hint,
            style: TextStyle(
              fontSize: 14,
              color: t.textPlaceholder,
            ),
          ),
        ),
      );
    }

    return MouseRegion(
      cursor: SystemMouseCursors.text,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 28),
            child: GitHubMarkdownBody(data: widget.text),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: FTappable(
              onPress: _enterEdit,
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: Icon(
                  LucideIcons.pencil,
                  size: 14,
                  color: t.fgQuaternary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
