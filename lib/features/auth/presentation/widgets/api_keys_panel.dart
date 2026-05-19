import 'package:control_center/features/forge/presentation/widgets/forge_connections_card.dart';
import 'package:control_center/features/ticketing/presentation/widgets/ticketing_connection_card.dart';
import 'package:flutter/widgets.dart';

/// The two things a fresh install has to connect: a code-hosting forge and
/// (optionally) a ticketing vendor.
///
/// Both cards are the SAME widgets Settings → Integrations renders, so the
/// onboarding step and the settings screen cannot drift — they were two
/// implementations of the same idea, and only one of them knew the app is
/// multi-forge.
///
/// No credential typed here is stored on this machine. Every token goes to the
/// server, attached to the signed-in user, which is what lets the same setup
/// answer from the desktop, the web app and the phone.
class ApiKeysPanel extends StatelessWidget {
  /// Creates an [ApiKeysPanel].
  const ApiKeysPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ForgeConnectionsCard(),
        SizedBox(height: 24),
        TicketingConnectionCard(),
      ],
    );
  }
}
