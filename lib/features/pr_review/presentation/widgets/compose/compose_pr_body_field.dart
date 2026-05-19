import 'package:control_center/core/theme/app_radii.dart';
import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:control_center/features/pr_review/presentation/screens/pull_request_detail/pr_header_section.dart';
import 'package:control_center/features/pr_review/presentation/widgets/mention_autocomplete_field.dart';
import 'package:control_center/features/pr_review/providers/compose_pr_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/markdown/markdown_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The always-editable PR description for the compose screen: the same shared
/// Write/Preview [MarkdownEditor] as the detail page's `PrBodyEditor` (markdown
/// toolbar + `@`/`#` autocomplete + a live preview), but it stages text into
/// [composePrProvider] instead of saving to an existing PR.
class ComposePrBodyField extends ConsumerStatefulWidget {
  /// Creates a [ComposePrBodyField] for [repoFullName] (owner/repo).
  const ComposePrBodyField({
    super.key,
    required this.repoFullName,
    required this.githubToken,
  });

  /// owner/repo, for the preview renderer and `#` autocomplete.
  final String repoFullName;

  /// GitHub token forwarded to authenticated image fetches in the preview.
  final String githubToken;

  @override
  ConsumerState<ComposePrBodyField> createState() => _ComposePrBodyFieldState();
}

class _ComposePrBodyFieldState extends ConsumerState<ComposePrBodyField> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  /// The exact body text this widget last seeded from a template (auto-applied
  /// or chosen via the picker). Lets us tell a pristine, template-derived body
  /// from one the user edited — so we can re-seed on a repo switch without
  /// clobbering their writing.
  String? _appliedBody;

  /// Guards against scheduling more than one auto-apply post-frame callback
  /// while the sole template settles.
  bool _autoApplyPending = false;

  /// The repo we've already auto-seeded a sole template for. Prevents re-seeding
  /// the same repo (e.g. after the user deliberately clears the body) while
  /// still allowing a fresh seed once the active repo changes.
  String? _seededForRepo;

  String get _owner => widget.repoFullName.contains('/')
      ? widget.repoFullName.split('/')[0]
      : '';
  String get _repo => widget.repoFullName.contains('/')
      ? widget.repoFullName.split('/')[1]
      : '';

  @override
  void initState() {
    super.initState();
    _controller.addListener(_sync);
  }

  @override
  void didUpdateWidget(covariant ComposePrBodyField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The active repo changed underneath us. Discard a still-pristine,
    // template-seeded (or empty) body so the new repo's template can re-seed
    // it; preserve anything the user actually typed.
    if (oldWidget.repoFullName != widget.repoFullName) {
      if (_controller.text == (_appliedBody ?? '')) {
        _appliedBody = null;
        _autoApplyPending = false;
        if (_controller.text.isNotEmpty) {
          _controller.clear();
        }
      }
    }
  }

  void _sync() =>
      ref.read(composePrProvider.notifier).setBody(_controller.text);

  /// Seeds the body with [body] and remembers it as template-derived.
  void _applyTemplate(String body) {
    setState(() {
      _controller.text = body;
      _appliedBody = body;
    });
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _controller.removeListener(_sync);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final templatesAsync = ref.watch(prTemplatesProvider);
    final templates = templatesAsync.value ?? const <PrTemplateOption>[];

    // Mirror GitHub: when the repo has exactly one template, seed an untouched
    // body with it. With several templates we leave the body blank and let the
    // user pick from the rail below. Wait for fresh data (`!isLoading`) so a
    // repo switch never seeds the outgoing repo's lingering template.
    if (!templatesAsync.isLoading &&
        templates.length == 1 &&
        _seededForRepo != widget.repoFullName &&
        _appliedBody == null &&
        !_autoApplyPending &&
        _controller.text.isEmpty) {
      _autoApplyPending = true;
      final repoAtSchedule = widget.repoFullName;
      final body = templates.first.body;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _autoApplyPending = false;
        if (mounted &&
            widget.repoFullName == repoAtSchedule &&
            _appliedBody == null &&
            _controller.text.isEmpty) {
          _seededForRepo = repoAtSchedule;
          _applyTemplate(body);
        }
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (templates.isNotEmpty) ...[
          _TemplatePicker(
            templates: templates,
            activeBody: _controller.text,
            onSelect: (tpl) => _applyTemplate(tpl.body),
          ),
          const SizedBox(height: 12),
        ],
        MarkdownEditor(
          controller: _controller,
          focusNode: _focusNode,
          fieldBuilder: (context) => MentionAutocompleteField(
            controller: _controller,
            focusNode: _focusNode,
            owner: _owner,
            repo: _repo,
            hintText: l10n.prBodyPlaceholder,
            minLines: 6,
          ),
          previewBuilder: (context) => PrBodyMarkdown(
            body: _controller.text,
            repoFullName: widget.repoFullName,
            githubToken: widget.githubToken,
          ),
        ),
      ],
    );
  }
}

/// The template chooser shown above the description editor when the active repo
/// ships one or more PR templates. Tapping a chip seeds the body with that
/// template. The chip whose template currently fills the body reads as active.
class _TemplatePicker extends StatelessWidget {
  const _TemplatePicker({
    required this.templates,
    required this.activeBody,
    required this.onSelect,
  });

  final List<PrTemplateOption> templates;
  final String activeBody;
  final ValueChanged<PrTemplateOption> onSelect;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Text(
            l10n.prTemplateLabel,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: t.textTertiary,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final tpl in templates)
                _TemplateChip(
                  label: tpl.isDefault ? l10n.prTemplateDefault : tpl.name,
                  selected: tpl.body == activeBody && activeBody.isNotEmpty,
                  tokens: t,
                  onTap: () => onSelect(tpl),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TemplateChip extends StatefulWidget {
  const _TemplateChip({
    required this.label,
    required this.selected,
    required this.tokens,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final DesignSystemTokens tokens;
  final VoidCallback onTap;

  @override
  State<_TemplateChip> createState() => _TemplateChipState();
}

class _TemplateChipState extends State<_TemplateChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.tokens;
    final Color background;
    final Color border;
    final Color foreground;
    if (widget.selected) {
      background = t.accentSoft;
      border = t.borderBrand;
      foreground = t.accent;
    } else if (_hovered) {
      background = t.bgPrimaryHover;
      border = t.borderSecondary;
      foreground = t.textSecondary;
    } else {
      background = Colors.transparent;
      border = t.borderSecondary;
      foreground = t.textTertiary;
    }
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: background,
            borderRadius: AppRadii.brSm,
            border: Border.all(color: border),
          ),
          child: Text(
            widget.label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: foreground,
            ),
          ),
        ),
      ),
    );
  }
}
