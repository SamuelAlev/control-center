import 'dart:async';

import 'package:cc_domain/features/skills/domain/scanner/skill_scan_types.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/skills/skill_scan_widgets.dart';
import 'package:control_center/features/settings/presentation/widgets/skills_settings.dart';
import 'package:control_center/features/settings/providers/skill_registry_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Settings → Skills → "Browse": search the skills.sh registry and install a
/// skill after reviewing its scan (PRD 23 §1).
///
/// Drives the `skills.registry*` ops through [RpcSkillRegistryControl], so it is
/// identical on desktop and web. The registry is UNTRUSTED: the row's author,
/// install count and "verified publisher" flag are provenance evidence only —
/// the real safety signal is the scan verdict, which the install dialog surfaces
/// prominently (never by colour alone).
class SkillBrowsePanel extends ConsumerStatefulWidget {
  /// Creates a [SkillBrowsePanel] scoped to [workspaceId] (used to refresh the
  /// installed-skills list after an install).
  const SkillBrowsePanel({super.key, required this.workspaceId});

  /// The workspace the installed skills belong to.
  final String workspaceId;

  @override
  ConsumerState<SkillBrowsePanel> createState() => _SkillBrowsePanelState();
}

class _SkillBrowsePanelState extends ConsumerState<SkillBrowsePanel> {
  final _searchCtl = TextEditingController();
  Timer? _debounce;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchCtl.addListener(_onChanged);
  }

  void _onChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      final next = _searchCtl.text.trim();
      if (mounted && next != _query) {
        setState(() => _query = next);
      }
    });
  }

  void _submit(String value) {
    _debounce?.cancel();
    final next = value.trim();
    if (next != _query) {
      setState(() => _query = next);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.designSystem;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: SectionCard(
        label: l10n.skills,
        expands: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.skillBrowseDisclaimer,
              style: TextStyle(
                fontSize: 12,
                height: 1.5,
                color: tokens?.textTertiary,
              ),
            ),
            const SizedBox(height: 12),
            CcTextField(
              controller: _searchCtl,
              hintText: l10n.skillBrowseSearchHint,
              onSubmitted: _submit,
              prefix: Icon(
                AppIcons.search,
                size: 16,
                color: tokens?.textTertiary,
              ),
            ),
            const SizedBox(height: 12),
            const CcDivider(),
            Expanded(child: _buildResults(context, l10n, tokens)),
          ],
        ),
      ),
    );
  }

  Widget _buildResults(
    BuildContext context,
    AppLocalizations l10n,
    DesignSystemTokens? tokens,
  ) {
    if (_query.isEmpty) {
      return _EmptyMessage(icon: AppIcons.search, text: l10n.skillBrowsePrompt);
    }
    final async = ref.watch(skillRegistrySearchProvider(_query));
    return async.when(
      loading: () => const Center(child: CcSpinner()),
      error: (e, _) => _EmptyMessage(
        icon: AppIcons.alertTriangle,
        text: l10n.failedWithError('$e'),
      ),
      data: (listings) {
        if (listings.isEmpty) {
          return _EmptyMessage(
            icon: AppIcons.searchX,
            text: l10n.skillBrowseNoResults,
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 6),
          itemCount: listings.length,
          separatorBuilder: (_, _) => const CcDivider(),
          itemBuilder: (context, index) => _ListingRow(
            listing: listings[index],
            onInstall: () => _openInstall(listings[index]),
          ),
        );
      },
    );
  }

  Future<void> _openInstall(RegistryListing listing) async {
    final l10n = AppLocalizations.of(context);
    final installedSlug = await showCcDialog<String>(
      context: context,
      builder: (_) => _SkillPreviewDialog(
        listing: listing,
        workspaceId: widget.workspaceId,
      ),
    );
    if (installedSlug != null && mounted) {
      ref.invalidate(skillListProvider(widget.workspaceId));
      CcToastScope.of(context).show(
        l10n.skillInstalled(installedSlug),
        variant: CcToastVariant.success,
      );
    }
  }
}

/// A single registry search hit: name + description + provenance evidence and an
/// install action.
class _ListingRow extends StatelessWidget {
  const _ListingRow({required this.listing, required this.onInstall});

  final RegistryListing listing;
  final VoidCallback onInstall;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.designSystem;

    final meta = <String>[
      if (listing.author.isNotEmpty) listing.author,
      if (listing.version.isNotEmpty) 'v${listing.version}',
      l10n.skillInstallCount(listing.installCount),
    ].join('  ·  ');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        listing.name,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: tokens?.textPrimary,
                        ),
                      ),
                    ),
                    if (listing.verifiedPublisher) ...[
                      const SizedBox(width: 8),
                      CcChip(
                        label: l10n.skillVerifiedPublisher,
                        leadingIcon: AppIcons.shieldCheck,
                      ),
                    ],
                  ],
                ),
                if (listing.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    listing.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.45,
                      color: tokens?.textTertiary,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  meta,
                  style: TextStyle(fontSize: 11, color: tokens?.textTertiary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          CcButton(
            variant: CcButtonVariant.secondary,
            size: CcButtonSize.sm,
            icon: AppIcons.download,
            onPressed: onInstall,
            child: Text(l10n.install),
          ),
        ],
      ),
    );
  }
}

/// A centered icon + message used for the panel's empty / prompt / error states.
class _EmptyMessage extends StatelessWidget {
  const _EmptyMessage({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 32, color: tokens?.textTertiary),
            const SizedBox(height: 12),
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: tokens?.textTertiary),
            ),
          ],
        ),
      ),
    );
  }
}

/// The install flow for one registry skill: scans it via `skills.registryPreview`
/// and shows the verdict + capabilities + findings before letting the operator
/// install via `skills.registryInstall`. A `quarantine` verdict requires an
/// explicit override tick.
class _SkillPreviewDialog extends ConsumerStatefulWidget {
  const _SkillPreviewDialog({required this.listing, required this.workspaceId});

  final RegistryListing listing;
  final String workspaceId;

  @override
  ConsumerState<_SkillPreviewDialog> createState() =>
      _SkillPreviewDialogState();
}

class _SkillPreviewDialogState extends ConsumerState<_SkillPreviewDialog> {
  RegistryPreview? _preview;
  Object? _loadError;
  bool _loading = true;
  bool _override = false;
  bool _installing = false;
  String? _installError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final preview = await ref
          .read(skillRegistryControlProvider)
          .preview(
            widget.listing.slug,
            version: widget.listing.version.isEmpty
                ? null
                : widget.listing.version,
          );
      if (mounted) {
        setState(() {
          _preview = preview;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadError = e;
          _loading = false;
        });
      }
    }
  }

  bool get _isQuarantine => _preview?.verdict == SkillScanVerdict.quarantine;

  bool get _canInstall {
    if (_loading || _installing || _preview == null) {
      return false;
    }
    return _isQuarantine ? _override : true;
  }

  Future<void> _install() async {
    final preview = _preview;
    if (preview == null) {
      return;
    }
    setState(() {
      _installing = true;
      _installError = null;
    });
    try {
      await ref
          .read(skillRegistryControlProvider)
          .install(
            widget.listing.slug,
            version: widget.listing.version.isEmpty
                ? null
                : widget.listing.version,
            allowQuarantineOverride: _isQuarantine && _override,
          );
      if (mounted) {
        Navigator.of(context).pop(widget.listing.slug);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _installing = false;
          _installError = '$e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return CcDialog(
      title: widget.listing.name,
      onClose: () => Navigator.of(context).pop(),
      maxWidth: 560,
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 460),
        child: SingleChildScrollView(child: _buildContent(context, l10n)),
      ),
      actions: [
        CcButton(
          variant: CcButtonVariant.secondary,
          onPressed: _installing ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        CcButton(
          variant: _isQuarantine
              ? CcButtonVariant.destructive
              : CcButtonVariant.primary,
          loading: _installing,
          icon: AppIcons.download,
          onPressed: _canInstall ? _install : null,
          child: Text(l10n.install),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context, AppLocalizations l10n) {
    final tokens = context.designSystem;
    if (_loading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CcSpinner(),
            const SizedBox(width: 12),
            Text(
              l10n.skillPreviewScanning,
              style: TextStyle(fontSize: 13, color: tokens?.textSecondary),
            ),
          ],
        ),
      );
    }
    if (_loadError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(l10n.failedWithError('$_loadError')),
      );
    }
    final preview = _preview!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // The untrusted-registry disclaimer: provenance is evidence, the scan
        // verdict is the real signal.
        Text(
          l10n.skillBrowseDisclaimer,
          style: TextStyle(
            fontSize: 12,
            height: 1.5,
            color: tokens?.textTertiary,
          ),
        ),
        const SizedBox(height: 16),
        SkillFieldLabel(text: l10n.skillPreviewVerdictLabel),
        const SizedBox(height: 6),
        Row(
          children: [
            SkillVerdictBadge(verdict: preview.verdict),
            if (preview.llmReviewed) ...[
              const SizedBox(width: 10),
              Text(
                l10n.skillPreviewLlmReviewed,
                style: TextStyle(fontSize: 12, color: tokens?.textTertiary),
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),
        SkillFieldLabel(text: l10n.skillPreviewCapabilities),
        const SizedBox(height: 6),
        if (preview.capabilities.isEmpty)
          Text(
            l10n.skillPreviewNoCapabilities,
            style: TextStyle(fontSize: 12, color: tokens?.textTertiary),
          )
        else
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final cap in preview.capabilities) CcChip(label: cap),
            ],
          ),
        if (preview.requiredActionClasses.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            '${l10n.skillPreviewGuardedActions}: '
            '${preview.requiredActionClasses.join(', ')}',
            style: TextStyle(fontSize: 11, color: tokens?.textTertiary),
          ),
        ],
        const SizedBox(height: 16),
        SkillFieldLabel(text: l10n.skillPreviewFindings),
        const SizedBox(height: 6),
        if (preview.findings.isEmpty)
          Text(
            l10n.skillPreviewNoFindings,
            style: TextStyle(fontSize: 12, color: tokens?.textTertiary),
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final f in preview.findings) SkillFindingTile(finding: f),
            ],
          ),
        if (_isQuarantine) ...[
          const SizedBox(height: 16),
          SkillQuarantineOverride(
            checked: _override,
            onChanged: _installing
                ? null
                : (v) => setState(() => _override = v),
            checkboxLabel: Text(l10n.skillInstallAnywayOverride),
          ),
        ],
        if (_installError != null) ...[
          const SizedBox(height: 12),
          Text(
            l10n.failedWithError(_installError!),
            style: TextStyle(fontSize: 12, color: tokens?.danger),
          ),
        ],
      ],
    );
  }
}
