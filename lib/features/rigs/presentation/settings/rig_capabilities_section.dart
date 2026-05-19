import 'dart:async';

import 'package:cc_data/cc_data.dart' show RigBackendView;
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/rigs/providers/rig_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// What this host can boot, and what would make it able to.
class CapabilitiesSection extends ConsumerWidget {
  /// Creates a [CapabilitiesSection].
  const CapabilitiesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final capabilities = ref.watch(rigCapabilitiesProvider);

    return SectionCard(
      label: l10n.rigsCapabilitiesTitle,
      child: capabilities.when(
        loading: () => const Center(child: CcSpinner()),
        error: (e, _) => Text(
          l10n.failedWithError('$e'),
          style: CcTypography.caption.copyWith(color: t.danger),
        ),
        data: (backends) {
          if (backends.isEmpty) {
            return Text(
              l10n.rigsUnsupportedServer,
              style: CcTypography.caption.copyWith(color: t.textTertiary),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final backend in backends) ...[
                if (backend != backends.first)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    child: CcDivider(),
                  ),
                BackendRow(backend: backend),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// One backend: whether it can boot, what it can host, and what would
/// make it able to.
class BackendRow extends StatelessWidget {
  /// Creates a [BackendRow].
  const BackendRow({super.key, required this.backend});

  /// The backend this row describes.
  final RigBackendView backend;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                backend.label,
                style: CcTypography.bodySm.copyWith(
                  color: t.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            CcStatusTag(
              label: backend.available
                  ? l10n.rigBackendAvailable
                  : l10n.rigBackendUnavailable,
              tone: backend.available
                  ? CcStatusTone.positive
                  : CcStatusTone.neutral,
            ),
          ],
        ),
        if (backend.version != null) ...[
          const SizedBox(height: AppSpacing.xxs),
          Text(
            backend.version!,
            style: CcTypography.caption.copyWith(color: t.textQuaternary),
          ),
        ],
        if (backend.note != null) ...[
          const SizedBox(height: AppSpacing.xxs),
          Text(
            backend.note!,
            style: CcTypography.caption.copyWith(color: t.textTertiary),
          ),
        ],
        // The install command verbatim and selectable — a hint that
        // paraphrases the command is a hint you have to translate.
        if (backend.installHint != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Mono(text: backend.installHint!),
        ],
        if (!backend.enforcedEgress) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.rigEgressNotEnforced,
            style: CcTypography.caption.copyWith(color: t.warn),
          ),
        ],
        if (backend.surfaces.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final surface in backend.surfaces) CcChip(label: surface),
            ],
          ),
        ],
      ],
    );
  }
}

/// A monospaced command line with a copy button.
///
/// Copyable rather than merely readable: this is a command someone is about to
/// run, and retyping a path from a screenshot is how typos get made.
/// `SelectableText` is a Material widget, so a copy affordance is both more
/// reliable here and a better fit for one short line.
class Mono extends StatelessWidget {
  /// Creates a [Mono].
  const Mono({super.key, required this.text});

  /// The command line, shown verbatim.
  final String text;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(
          child: Text(
            text,
            style: CcFonts.code().copyWith(color: t.accent, fontSize: 12),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        CcIconButton(
          icon: AppIcons.copy,
          size: CcButtonSize.sm,
          tooltip: l10n.copy,
          onPressed: () => unawaited(
            Clipboard.setData(ClipboardData(text: text)),
          ),
        ),
      ],
    );
  }
}
