import 'dart:async';

import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/theme/app_fonts.dart';
import 'package:control_center/core/theme/font_settings.dart';
import 'package:control_center/features/settings/presentation/widgets/font_preview_card.dart';
import 'package:control_center/features/settings/providers/font_list_provider.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Opens a font picker dialog and returns the selected [FontSelection]
/// or `null` if cancelled.
Future<FontSelection?> showFontPicker({
  required BuildContext context,
  required FontSelection currentSelection,
  required FontContext contextType,
}) async {
  return showCcDialog<FontSelection>(
    context: context,
    builder: (_) => _FontPickerDialog(
      currentSelection: currentSelection,
      contextType: contextType,
    ),
  );
}

class _FontPickerDialog extends ConsumerStatefulWidget {
  const _FontPickerDialog({
    required this.currentSelection,
    required this.contextType,
  });

  final FontSelection currentSelection;
  final FontContext contextType;

  @override
  ConsumerState<_FontPickerDialog> createState() => _FontPickerDialogState();
}

class _FontPickerDialogState extends ConsumerState<_FontPickerDialog> {
  late FontSelection _previewSelection;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showGoogle = true;
  bool _showSystem = true;
  bool _showPopular = true;

  static const _popularFonts = [
    'Inter',
    'Roboto',
    'Open Sans',
    'Lato',
    'Poppins',
    'Montserrat',
    'Source Code Pro',
    'Fira Code',
    'Cascadia Code',
    'IBM Plex Mono',
    'Raleway',
    'Nunito',
    'Ubuntu',
    'Noto Sans',
  ];

  @override
  void initState() {
    super.initState();
    _previewSelection = widget.currentSelection;
    _searchController.addListener(() {
      if (_searchController.text != _searchQuery) {
        setState(() => _searchQuery = _searchController.text);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _setPreview(FontSelection selection) {
    setState(() => _previewSelection = selection);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final googleFonts = ref.watch(googleFontsProvider);
    final systemFontsAsync = ref.watch(systemFontsProvider);

    final filteredGoogle = _filter(googleFonts);
    final systemFonts = systemFontsAsync.value ?? [];
    final filteredSystem = _filterSystem(systemFonts);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 800, maxHeight: 700),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: t.bgPrimary,
          borderRadius: AppRadii.brLg,
          border: Border.all(color: t.borderSecondary),
          boxShadow: AppShadows.golden,
        ),
        child: ClipRRect(
          borderRadius: AppRadii.brLg,
          child: SizedBox(
            width: 800,
            height: 700,
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 16, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.contextType == FontContext.app
                              ? l10n.chooseAppFont
                              : l10n.chooseCodeFont,
                          style: theme.textTheme.titleLarge,
                        ),
                      ),
                      CcIconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: AppIcons.x,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Preview
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: FontPreviewCard(
                    font: _previewSelection,
                    context: widget.contextType,
                  ),
                ),
                const SizedBox(height: 12),

                // Search
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: CcTextField(
                    autofocus: true,
                    hintText: l10n.searchFonts,
                    prefix: const Icon(AppIcons.search, size: 16),
                    controller: _searchController,
                  ),
                ),
                const SizedBox(height: 12),

                // Font list
                Expanded(
                  child: _buildFontList(
                    theme,
                    l10n,
                    filteredGoogle,
                    filteredSystem,
                  ),
                ),

                // Bottom bar
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CcButton(
                        variant: CcButtonVariant.ghost,
                        onPressed: _pickFile,
                        icon: AppIcons.folderOpen,
                        child: Text(l10n.addFromFile),
                      ),
                      const Spacer(),
                      CcButton(
                        variant: CcButtonVariant.secondary,
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(l10n.cancel),
                      ),
                      const SizedBox(width: 12),
                      CcButton(
                        onPressed: () =>
                            Navigator.of(context).pop(_previewSelection),
                        child: Text(l10n.apply),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<String> _filter(List<String> fonts) {
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) {
      return fonts;
    }

    return fonts.where((f) => f.toLowerCase().contains(q)).toList();
  }

  List<Map<String, String>> _filterSystem(List<Map<String, String>> fonts) {
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) {
      return fonts;
    }

    return fonts
        .where((f) => (f['family'] ?? '').toLowerCase().contains(q))
        .toList();
  }

  Widget _buildFontList(
    ThemeData theme,
    AppLocalizations l10n,
    List<String> googleFonts,
    List<Map<String, String>> systemFonts,
  ) {
    final showPopular = _searchQuery.trim().isEmpty;
    final popular = showPopular
        ? _popularFonts.where((f) => googleFonts.contains(f)).toList()
        : <String>[];

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        if (popular.isNotEmpty) ...[
          _SectionHeader(
            title: l10n.popular,
            count: popular.length,
            expanded: _showPopular,
            onToggle: () => setState(() => _showPopular = !_showPopular),
          ),
          if (_showPopular)
            ...popular.map(
              (family) => _FontRow(
                family: family,
                source: FontSource.google,
                isSelected:
                    _previewSelection.family == family &&
                    _previewSelection.source == FontSource.google,
                onTap: () => _setPreview(
                  FontSelection(family: family, source: FontSource.google),
                ),
              ),
            ),
        ],

        // Google Fonts section
        _SectionHeader(
          title: l10n.googleFonts,
          count: googleFonts.length,
          expanded: _showGoogle,
          onToggle: () => setState(() => _showGoogle = !_showGoogle),
        ),
        if (_showGoogle) ...[
          if (googleFonts.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(l10n.noMatchingGoogleFonts),
            )
          else
            ...googleFonts.map(
              (family) => _FontRow(
                family: family,
                source: FontSource.google,
                isSelected:
                    _previewSelection.family == family &&
                    _previewSelection.source == FontSource.google,
                onTap: () => _setPreview(
                  FontSelection(family: family, source: FontSource.google),
                ),
              ),
            ),
        ],
        const SizedBox(height: 8),

        // System Fonts section
        _SectionHeader(
          title: l10n.systemFonts,
          count: systemFonts.length,
          expanded: _showSystem,
          onToggle: () => setState(() => _showSystem = !_showSystem),
        ),
        if (_showSystem) ...[
          if (systemFonts.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(l10n.noSystemFonts),
            )
          else
            ...systemFonts.map((font) {
              final family = font['family']!;
              final path = font['path']!;
              return _FontRow(
                family: family,
                source: FontSource.system,
                isSelected:
                    _previewSelection.family == family &&
                    _previewSelection.source == FontSource.system,
                onTap: () => _setPreview(
                  FontSelection(
                    family: family,
                    source: FontSource.system,
                    filePath: path,
                  ),
                ),
              );
            }),
        ],
      ],
    );
  }

  Future<void> _pickFile() async {
    const typeGroup = XTypeGroup(
      label: 'fonts',
      extensions: ['ttf', 'otf', 'TTF', 'OTF'],
    );
    final file = await openFile(acceptedTypeGroups: [typeGroup]);
    if (file == null) {
      return;
    }

    // Use the file basename (without extension) as the family name.
    final name = file.name.replaceAll(RegExp(r'\.(ttf|otf|TTF|OTF)$'), '');
    final selection = FontSelection(
      family: name,
      source: FontSource.system,
      filePath: file.path,
    );
    _setPreview(selection);
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.count,
    required this.expanded,
    required this.onToggle,
  });

  final String title;
  final int count;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onToggle,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Icon(
              expanded ? AppIcons.chevronUp : AppIcons.chevronDown,
              size: 18,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '($count)',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FontRow extends StatelessWidget {
  const _FontRow({
    required this.family,
    required this.source,
    required this.isSelected,
    required this.onTap,
  });

  final String family;
  final FontSource source;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = isSelected
        ? theme.colorScheme.primaryContainer.withValues(alpha: 0.4)
        : null;

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      family,
                      style: source == FontSource.google
                          ? AppFonts.uiDynamic(
                              family,
                              textStyle: const TextStyle(fontSize: 15),
                            )
                          : const TextStyle(fontSize: 15),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (source == FontSource.system)
                      Text(
                        'System',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.5,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(Icons.check, size: 18, color: theme.colorScheme.primary),
            ],
          ),
        ),
      ),
    );
  }
}
