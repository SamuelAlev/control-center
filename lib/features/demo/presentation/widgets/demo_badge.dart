import 'package:cc_ui/cc_ui.dart';

import 'package:control_center/di/demo_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A persistent "Demo" badge for the app shell header.
///
/// Renders **nothing at all** against a real server, so it can be placed
/// unconditionally in the shell: the whole cost on a normal install is one
/// boolean read.
///
/// It is deliberately always visible in a demo rather than dismissible. The
/// first-run note and the tour can be waved away; the fact that none of this
/// data is real should not be something a visitor can accidentally forget
/// thirty minutes in.
class DemoBadge extends ConsumerWidget {
  /// Creates the badge.
  const DemoBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(isDemoServerProvider)) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);
    return CcTooltip(
      message: l10n.demoBadgeTooltip,
      child: CcBadge(
        label: l10n.demoBadgeLabel,
        variant: CcBadgeVariant.brand,
        icon: CcIcons.sparkles,
      ),
    );
  }
}
