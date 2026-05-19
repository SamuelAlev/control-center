import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/newsfeed/providers/site_allowlist_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Settings → You → Newsfeed: trusted sites exempt from content blocking.
/// Only shown while content blocking is on.
class NewsfeedTrustedSitesSection extends ConsumerWidget {
  /// Creates a [NewsfeedTrustedSitesSection].
  const NewsfeedTrustedSitesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tokens = context.designSystem;
    final l10n = AppLocalizations.of(context);
    final allowedAsync = ref.watch(siteAllowlistProvider);

    return SectionCard(
      label: l10n.trustedSitesSectionTitle,
      padding: const EdgeInsets.fromLTRB(0, 14, 0, 8),
      headerPadding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
      trailing: CcButton(
        variant: CcButtonVariant.secondary,
        onPressed: () => _showAddTrustedSiteDialog(context, ref),
        icon: AppIcons.plus,
        child: Text(l10n.addTrustedSite),
      ),
      child: allowedAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CcSpinner()),
        ),
        error: (e, _) => Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            '$e',
            style: CcTypography.caption.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ),
        data: (domains) {
          final sorted = domains.toList()..sort();
          if (sorted.isEmpty) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                l10n.trustedSitesEmpty,
                style: CcTypography.caption.copyWith(
                  color:
                      tokens?.textTertiary ??
                      theme.colorScheme.onSurfaceVariant,
                ),
              ),
            );
          }
          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sorted.length,
            separatorBuilder: (_, _) => const CcDivider(),
            itemBuilder: (_, i) => _TrustedSiteRow(domain: sorted[i]),
          );
        },
      ),
    );
  }
}

class _TrustedSiteRow extends ConsumerWidget {
  const _TrustedSiteRow({required this.domain});

  final String domain;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tokens = context.designSystem;
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
      child: Row(
        children: [
          Icon(
            AppIcons.shieldOff,
            size: 18,
            color: tokens?.fgTertiary ?? theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              domain,
              style: CcTypography.body.copyWith(
                color: tokens?.textPrimary ?? theme.colorScheme.onSurface,
              ),
            ),
          ),
          CcTooltip(
            message: l10n.removeTrustedSite,
            child: CcIconButton(
              icon: AppIcons.trash2,
              semanticLabel: l10n.remove,
              onPressed: () =>
                  ref.read(siteAllowlistRepositoryProvider).remove(domain),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _showAddTrustedSiteDialog(
  BuildContext context,
  WidgetRef ref,
) async {
  final l10n = AppLocalizations.of(context);
  final controller = TextEditingController();
  String? error;
  await showCcDialog<String?>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (sbContext, setState) {
          Future<void> submit() async {
            final raw = controller.text.trim();
            if (raw.isEmpty) {
              setState(() => error = l10n.invalidDomain);
              return;
            }
            final repo = ref.read(siteAllowlistRepositoryProvider);
            final normalised = repo.normalizeDomain(raw);
            if (normalised.isEmpty) {
              setState(() => error = l10n.invalidDomain);
              return;
            }
            await repo.add(normalised);
            if (sbContext.mounted) {
              Navigator.pop(dialogContext, normalised);
            }
          }

          return CcDialog(
            title: l10n.addTrustedSite,
            content: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.trustedSitesSectionTitle),
                      const SizedBox(height: 6),
                      CcTextField(
                        autofocus: true,
                        hintText: l10n.enterDomainHint,
                        controller: controller,
                        onSubmitted: (_) => submit(),
                      ),
                    ],
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      error!,
                      style: TextStyle(
                        color: Theme.of(sbContext).colorScheme.error,
                        fontSize: 13,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      CcButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        variant: CcButtonVariant.ghost,
                        child: Text(l10n.cancel),
                      ),
                      const SizedBox(width: 12),
                      CcButton(
                        onPressed: submit,
                        child: Text(l10n.addTrustedSite),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
