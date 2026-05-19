import 'package:cc_domain/cc_domain.dart' show AuthException, RepoOpKind;
import 'package:cc_domain/core/domain/entities/sso_connection.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_host/cc_host.dart';
import 'package:cc_server_core/src/identity/sso_settings_service.dart';

/// Builds the `sso.*` repo-RPC ops (mounted via `extraOps` in
/// `runCcServer`, the same pattern as the weather/fonts/soundscape groups).
///
/// GATE — every op requires the SERVER-ADMIN role: the caller must hold
/// `owner` in at least one workspace (the bootstrap owner qualifies by
/// construction). Unlike `mcp.setToken`, which any paired device may call,
/// SSO configuration decides who may authenticate to the whole server — the
/// blast radius is every workspace — so it never rides mere pairing.
///
/// All ops are `workspaceScoped: false` by design: authentication is
/// server-wide (see `SsoConnectionsTable`) and the admin gate above is the
/// access decision.
List<RepoOp> buildSsoOps({
  required SsoSettingsService settings,
  required Future<bool> Function(String userId) isServerAdmin,
}) {
  Future<void> requireAdmin(String userId) async {
    if (!await isServerAdmin(userId)) {
      throw const AuthException(
        'Server admin role required (owner of at least one workspace)',
      );
    }
  }

  return [
    RepoOp(
      name: 'sso.getConfig',
      kind: RepoOpKind.read,
      workspaceScoped: false,
      requiredCapability: SessionCapability.fullClient,
      requiredArgs: ['kind'],
      handler: (ctx) async {
        await requireAdmin(ctx.userId);
        final kind = SsoProviderKind.fromWire(ctx.args['kind'] as String?);
        if (kind == null) {
          throw const AuthException('Unknown SSO kind');
        }
        final connection = await settings.get(kind);
        final json = _toJson(connection);
        if (connection != null && kind == SsoProviderKind.oidc) {
          // Presence only — the secret itself never crosses the wire.
          json['clientSecretPresent'] = await settings
              .oidcClientSecretPresent();
        }
        return {'connection': json};
      },
    ),
    RepoOp(
      name: 'sso.saveConfig',
      kind: RepoOpKind.mutate,
      workspaceScoped: false,
      requiredCapability: SessionCapability.fullClient,
      audited: true,
      requiredArgs: ['kind', 'enabled'],
      handler: (ctx) async {
        await requireAdmin(ctx.userId);
        final saved = await settings.save(
          _fromJson(ctx.args),
          clientSecret: ctx.args['clientSecret'] as String?,
        );
        final json = _toJson(saved);
        if (saved.kind == SsoProviderKind.oidc) {
          json['clientSecretPresent'] = await settings
              .oidcClientSecretPresent();
        }
        return {'connection': json};
      },
    ),
    RepoOp(
      name: 'sso.status',
      kind: RepoOpKind.read,
      workspaceScoped: false,
      requiredCapability: SessionCapability.fullClient,
      handler: (ctx) async {
        await requireAdmin(ctx.userId);
        return await settings.status();
      },
    ),
    RepoOp(
      name: 'sso.testConnection',
      kind: RepoOpKind.read,
      workspaceScoped: false,
      requiredCapability: SessionCapability.fullClient,
      requiredArgs: ['kind'],
      handler: (ctx) async {
        await requireAdmin(ctx.userId);
        final kind = SsoProviderKind.fromWire(ctx.args['kind'] as String?);
        if (kind == null) {
          throw const AuthException('Unknown SSO kind');
        }
        // The optional overrides let the admin test what is on screen
        // BEFORE saving; without them the saved row is tested.
        return await settings.testConnection(
          kind,
          idpMetadataXml: ctx.args['idpMetadataXml'] as String?,
          issuer: ctx.args['issuer'] as String?,
        );
      },
    ),
    RepoOp(
      name: 'sso.spMetadata',
      kind: RepoOpKind.read,
      workspaceScoped: false,
      requiredCapability: SessionCapability.fullClient,
      handler: (ctx) async {
        await requireAdmin(ctx.userId);
        // The ACS the IdP POSTs to must be the origin the USER's browser
        // reaches, hence client-supplied when known; the server's canonical
        // origin (tunnel > publicUrl > loopback) is the fallback. Content is
        // non-secret SP metadata the admin registers at the IdP; actual ACS
        // validation always re-derives the origin from the request.
        var origin = (ctx.args['origin'] as String?)?.trim();
        origin = (origin == null || origin.isEmpty)
            ? await settings.canonicalOrigin()
            : origin;
        final parsed = origin == null ? null : Uri.tryParse(origin);
        if (origin == null ||
            parsed == null ||
            !parsed.hasScheme ||
            parsed.host.isEmpty) {
          throw const AuthException(
            'origin must be an absolute URL (or the server must know its '
            'public URL / tunnel)',
          );
        }
        return {'xml': settings.saml.spMetadataXml(origin: origin)};
      },
    ),
    RepoOp(
      name: 'sso.setPairingEnabled',
      kind: RepoOpKind.mutate,
      workspaceScoped: false,
      requiredCapability: SessionCapability.fullClient,
      audited: true,
      requiredArgs: ['enabled'],
      handler: (ctx) async {
        await requireAdmin(ctx.userId);
        await settings.setPairingEnabled(ctx.args['enabled'] == true);
        return await settings.status();
      },
    ),
    RepoOp(
      name: 'sso.scimRegenerateToken',
      kind: RepoOpKind.mutate,
      workspaceScoped: false,
      requiredCapability: SessionCapability.fullClient,
      audited: true,
      handler: (ctx) async {
        await requireAdmin(ctx.userId);
        // Returned exactly once; afterwards only a constant-time check.
        return {'token': await settings.regenerateScimToken()};
      },
    ),
  ];
}

Map<String, Object?> _toJson(SsoConnection? c) => c == null
    ? <String, Object?>{}
    : {
        'id': c.id,
        'kind': c.kind.wireName,
        'enabled': c.enabled,
        'issuer': c.issuer,
        'clientId': c.clientId,
        'groupsClaim': c.groupsClaim,
        'idpMetadataXml': c.idpMetadataXml,
        'spEntityId': c.spEntityId,
        'emailAttribute': c.emailAttribute,
        'displayNameAttribute': c.displayNameAttribute,
        'groupsAttribute': c.groupsAttribute,
        'defaultRole': c.defaultRole.wireName,
        'groupRoleMap': {
          for (final e in c.groupRoleMap.entries) e.key: e.value.wireName,
        },
        'autoMember': c.autoMember,
        'allowJit': c.allowJit,
        'allowIdpInitiated': c.allowIdpInitiated,
        'wantResponseSigned': c.wantResponseSigned,
        'clockSkewSeconds': c.clockSkewSeconds,
        'updatedAt': c.updatedAt.toIso8601String(),
      };

SsoConnection _fromJson(Map<String, dynamic> args) {
  final kind =
      SsoProviderKind.fromWire(args['kind'] as String?) ?? SsoProviderKind.saml;
  Map<String, WorkspaceRole> roleMap = const {};
  final rawMap = args['groupRoleMap'];
  if (rawMap is Map) {
    roleMap = {
      for (final entry in rawMap.entries)
        if (WorkspaceRole.fromWire('${entry.value}')
            case final WorkspaceRole role)
          '${entry.key}': role,
    };
  }
  return SsoConnection(
    id: kind.wireName,
    kind: kind,
    enabled: args['enabled'] as bool? ?? false,
    issuer: args['issuer'] as String? ?? '',
    clientId: args['clientId'] as String? ?? '',
    groupsClaim: args['groupsClaim'] as String? ?? 'groups',
    idpMetadataXml: args['idpMetadataXml'] as String? ?? '',
    spEntityId: args['spEntityId'] as String? ?? '',
    emailAttribute: args['emailAttribute'] as String? ?? 'email',
    displayNameAttribute:
        args['displayNameAttribute'] as String? ?? 'displayName',
    groupsAttribute: args['groupsAttribute'] as String? ?? 'groups',
    defaultRole:
        WorkspaceRole.fromWire(args['defaultRole'] as String?) ??
        WorkspaceRole.member,
    groupRoleMap: roleMap,
    autoMember: args['autoMember'] as bool? ?? true,
    allowJit: args['allowJit'] as bool? ?? true,
    allowIdpInitiated: args['allowIdpInitiated'] as bool? ?? false,
    wantResponseSigned: args['wantResponseSigned'] as bool? ?? false,
    clockSkewSeconds: args['clockSkewSeconds'] as int? ?? 90,
    updatedAt: DateTime.now(),
  );
}
