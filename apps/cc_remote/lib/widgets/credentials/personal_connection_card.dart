import 'dart:async';

import 'package:cc_connect_core/cc_connect_core.dart'
    show ConnectOAuthLane, SignInAttemptStatus, normaliseConfirmCode;
import 'package:cc_data/cc_data.dart'
    show
        RemoteProviderSignIn,
        SignInAttempt,
        SignInFailure,
        SignInLaneInfo,
        SignInLaneMode,
        signInFailureOfRpcError;
import 'package:cc_domain/core/domain/value_objects/forge_connection.dart'
    show ForgeConnectionStatus, ForgeCredentialScope;
import 'package:cc_domain/core/domain/value_objects/person_token_refusal.dart';
import 'package:cc_remote/credential_providers.dart';
import 'package:cc_remote/external_link.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/providers.dart';
import 'package:cc_rpc/cc_rpc.dart' show RemoteRpcException;
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'personal_connection_actions.dart';
part 'personal_connection_flow.dart';
part 'personal_connection_forms.dart';
part 'personal_connection_view.dart';

/// A caller-owned forge or ticketing identity. GitHub and Linear sign in
/// through the server's browser sign-in [lane]; GitLab and Bitbucket take a
/// write-only personal token.
class PersonalConnectionCard extends ConsumerStatefulWidget {
  const PersonalConnectionCard({
    required this.providerId,
    required this.name,
    required this.workspaceId,
    required this.isForge,
    required this.connected,
    required this.username,
    required this.canManage,
    this.lane,
    this.laneInfo,
    this.statusError,
    this.status,
    this.scope,
    super.key,
  });

  final String providerId;
  final String name;
  final String workspaceId;
  final bool isForge;
  final bool connected;
  final String username;
  final bool canManage;

  /// The browser sign-in lane, or null for a provider that takes a token.
  final ConnectOAuthLane? lane;

  /// How this server runs [lane]'s sign-in; null while unknown.
  final SignInLaneInfo? laneInfo;
  final String? statusError;

  /// Where the sign-in stands, when the server reports it (forges); null
  /// for a provider described by [connected] alone.
  final ForgeConnectionStatus? status;

  /// Where the credential in effect lives (forges), shown so "Disconnect"
  /// never surprises; null when unknown.
  final ForgeCredentialScope? scope;

  /// Whether a grant is held at all, usable or not (a paused or
  /// unreachable one can still be disconnected).
  bool get hasGrant =>
      connected ||
      (status != null && status != ForgeConnectionStatus.notConnected);

  /// Whether starting a sign-in makes sense: never for a paused grant (it
  /// comes back with the workspace's sign-in service, and a fresh sign-in
  /// would replace it) or one that is only retrying.
  bool get offersSignIn =>
      status != ForgeConnectionStatus.paused &&
      status != ForgeConnectionStatus.unreachable;

  @override
  ConsumerState<PersonalConnectionCard> createState() =>
      _PersonalConnectionCardState();
}

class _PersonalConnectionCardState extends ConsumerState<PersonalConnectionCard>
    with
        _PersonalCredentialActions,
        _PersonalConnectionFlow,
        _PersonalConnectionView {}
