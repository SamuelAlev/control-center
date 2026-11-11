import 'package:control_center/features/forge/presentation/widgets/forge_connections_card.dart';
import 'package:control_center/features/ticketing/presentation/widgets/linear_account_card.dart';
import 'package:control_center/features/ticketing/presentation/widgets/ticketing_connection_card.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The two things a fresh install has to connect: a code-hosting forge and
/// (optionally) a ticketing vendor.
///
/// The cards are the SAME widgets settings renders: the forge accounts and
/// the person's Linear sign-in from You → Profile, the ticketing
/// vendor from Workspace → Integrations. So the onboarding step and the
/// settings screens cannot drift — they were two implementations of the same
/// idea, and only one of them knew the app is multi-forge.
///
/// No credential typed here is stored on this machine. Every token goes to the
/// server, attached to the signed-in user, which is what lets the same setup
/// answer from the desktop, the web app and the phone.
class ApiKeysPanel extends ConsumerWidget {
  /// Creates an [ApiKeysPanel].
  const ApiKeysPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ForgeConnectionsCard(),
        const SizedBox(height: 24),
        const TicketingConnectionCard(),
        // The person's own Linear sign-in, once Linear is the vendor.
        if (watchLinearAccountApplies(ref)) ...[
          const SizedBox(height: 16),
          const LinearAccountCard(),
        ],
      ],
    );
  }
}
