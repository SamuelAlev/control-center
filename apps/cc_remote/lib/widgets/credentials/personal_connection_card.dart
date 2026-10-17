import 'dart:async';

import 'package:cc_remote/credential_providers.dart';
import 'package:cc_remote/external_link.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/providers.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'personal_connection_actions.dart';
part 'personal_connection_flow.dart';
part 'personal_connection_forms.dart';
part 'personal_connection_view.dart';

/// A caller-owned forge or ticketing identity, using the server's advertised
/// device-code/redirect sign-in or a write-only personal access token.
class PersonalConnectionCard extends ConsumerStatefulWidget {
  const PersonalConnectionCard({
    required this.providerId,
    required this.name,
    required this.workspaceId,
    required this.isForge,
    required this.connected,
    required this.username,
    required this.canManage,
    required this.signInFlow,
    required this.redirectUri,
    this.statusError,
    this.hostManaged = false,
    super.key,
  });

  final String providerId;
  final String name;
  final String workspaceId;
  final bool isForge;
  final bool connected;
  final String username;
  final bool canManage;
  final String? signInFlow;
  final String redirectUri;
  final String? statusError;
  final bool hostManaged;

  @override
  ConsumerState<PersonalConnectionCard> createState() =>
      _PersonalConnectionCardState();
}

class _PersonalConnectionCardState extends ConsumerState<PersonalConnectionCard>
    with
        _PersonalCredentialActions,
        _PersonalConnectionFlow,
        _PersonalConnectionView {}
