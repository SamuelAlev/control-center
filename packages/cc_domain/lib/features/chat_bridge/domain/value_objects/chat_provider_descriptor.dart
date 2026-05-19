import 'package:cc_domain/features/chat_bridge/domain/value_objects/chat_provider.dart';
import 'package:cc_domain/features/chat_bridge/domain/value_objects/chat_provider_capabilities.dart';
import 'package:cc_domain/src/errors/app_exceptions.dart';

/// One secret a provider needs before it can be connected.
///
/// The connect dialog is generated from these, which is what keeps adding a
/// provider from touching the UI: a new adapter declares its fields and the
/// dialog grows the boxes.
///
/// [id] is the stable key the credential is stored under **and** the seam the
/// client localizes through: it maps a known id to a translated label and only
/// falls back to [label] for a field it has never heard of. So [label]/[hint]
/// are authored in English on purpose, like an MCP tool description.
class ChatCredentialField {
  /// Creates a [ChatCredentialField].
  const ChatCredentialField({
    required this.id,
    required this.label,
    this.hint,
    this.secret = true,
    this.required = true,
    this.expectedPrefix,
    this.prefixError,
  });

  /// Rebuilds from the wire map.
  factory ChatCredentialField.fromJson(Map<String, dynamic> json) =>
      ChatCredentialField(
        id: json['id'] as String? ?? '',
        label: json['label'] as String? ?? '',
        hint: json['hint'] as String?,
        secret: json['secret'] as bool? ?? true,
        required: json['required'] as bool? ?? true,
        expectedPrefix: json['expectedPrefix'] as String?,
        prefixError: json['prefixError'] as String?,
      );

  /// Stable storage key (`botToken`, `appToken`, …).
  final String id;

  /// English label, used when the client cannot localize [id].
  final String label;

  /// English one-line hint, used the same way.
  final String? hint;

  /// Whether the value is a secret (obscured in the UI, never read back).
  final bool secret;

  /// Whether connecting requires it.
  final bool required;

  /// The prefix the provider's own token format guarantees (`xoxb-`), when it
  /// has one. Cheap client- and server-side typo detection.
  final String? expectedPrefix;

  /// What to tell the user when [expectedPrefix] does not match. Names where
  /// the right value lives, which a generic "invalid token" cannot.
  final String? prefixError;

  /// Serializes to the wire map.
  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    if (hint != null) 'hint': hint,
    'secret': secret,
    'required': required,
    if (expectedPrefix != null) 'expectedPrefix': expectedPrefix,
    if (prefixError != null) 'prefixError': prefixError,
  };
}

/// Everything a client needs to render and a server needs to validate, one
/// chat provider — without either of them knowing which provider it is.
///
/// This is the payload that makes "add Discord" a server-only change: the
/// settings card, the connect dialog and the argument validation are all
/// generated from a descriptor, so a new adapter ships its own UI by declaring
/// its credentials.
class ChatProviderDescriptor {
  /// Creates a [ChatProviderDescriptor].
  const ChatProviderDescriptor({
    required this.provider,
    required this.credentialFields,
    this.capabilities = const ChatProviderCapabilities(),
    this.consoleUrl,
    this.docsUrl,
    this.commandName = 'cc',
    this.managementCredentialField,
    this.supportsGuidedSetup = false,
    this.supportsBotCustomization = false,
    this.supportsSetupLink = false,
  });

  /// Rebuilds from the wire map.
  factory ChatProviderDescriptor.fromJson(Map<String, dynamic> json) =>
      ChatProviderDescriptor(
        provider: ChatProvider.fromWire(json['provider'] as String?),
        credentialFields: ((json['credentialFields'] as List?) ?? const [])
            .whereType<Map>()
            .map((f) => ChatCredentialField.fromJson(f.cast<String, dynamic>()))
            .toList(),
        capabilities: ChatProviderCapabilities.fromJson(
          (json['capabilities'] as Map?)?.cast<String, dynamic>() ?? const {},
        ),
        consoleUrl: json['consoleUrl'] as String?,
        docsUrl: json['docsUrl'] as String?,
        commandName: json['commandName'] as String? ?? 'cc',
        managementCredentialField: json['managementCredentialField'] as String?,
        supportsGuidedSetup: json['supportsGuidedSetup'] as bool? ?? false,
        supportsBotCustomization:
            json['supportsBotCustomization'] as bool? ?? false,
        supportsSetupLink: json['supportsSetupLink'] as bool? ?? false,
      );

  /// Which provider this describes.
  final ChatProvider provider;

  /// The secrets the connect dialog collects, in the order it shows them.
  final List<ChatCredentialField> credentialFields;

  /// What the provider's API can do (drives the bridge's degradations).
  final ChatProviderCapabilities capabilities;

  /// Where the user manages their apps for this provider.
  final String? consoleUrl;

  /// Where the setup is documented.
  final String? docsUrl;

  /// The bot command's name without its slash, so the link instruction reads
  /// `/cc link CODE` for a provider that spells it that way.
  final String commandName;

  /// Which credential field manages the provider-side app, when the provider has
  /// one. Named rather than positional so the guided-setup dialog can ask for
  /// exactly that box without knowing the provider.
  final String? managementCredentialField;

  /// Whether Control Center can create the provider-side app itself.
  final bool supportsGuidedSetup;

  /// Whether the provider-side app's name/description can be edited from here.
  final bool supportsBotCustomization;

  /// Whether the provider offers a credential-free link that creates the app
  /// with our configuration pre-filled. Independent of [supportsGuidedSetup]:
  /// guided setup needs an app-management credential first, this needs nothing,
  /// so a provider can offer either, both, or neither.
  final bool supportsSetupLink;

  /// The product's name, for user-facing copy.
  String get displayName => provider.displayName;

  /// The command a member sends to redeem a link code.
  String linkCommand(String code) => '/$commandName link $code';

  /// The spec of [managementCredentialField], or null when the provider has no
  /// app-management credential (or declares one it does not collect).
  ChatCredentialField? get managementField {
    for (final field in credentialFields) {
      if (field.id == managementCredentialField) {
        return field;
      }
    }
    return null;
  }

  /// Reads [field] out of [credentials], throwing a [ValidationException] that
  /// names the offending box when a required field is missing or malformed.
  ///
  /// The single validation chokepoint for a connect attempt: prefix rules live
  /// on the descriptor, so a provider's token format is stated once instead of
  /// being re-hardcoded in an RPC op.
  String? validated(
    Map<String, String> credentials,
    ChatCredentialField field,
  ) {
    final raw = credentials[field.id]?.trim() ?? '';
    if (raw.isEmpty) {
      if (field.required) {
        throw ValidationException('${field.label} is required.');
      }
      return null;
    }
    final prefix = field.expectedPrefix;
    if (prefix != null && !raw.startsWith(prefix)) {
      throw ValidationException(
        field.prefixError ?? '${field.label} must start with `$prefix`.',
      );
    }
    return raw;
  }

  /// Validates every declared field, returning the credentials to store.
  ///
  /// Fields the descriptor does not declare are dropped rather than stored: a
  /// client cannot smuggle an extra secret into the credentials file.
  Map<String, String> validate(Map<String, String> credentials) {
    final clean = <String, String>{};
    for (final field in credentialFields) {
      final value = validated(credentials, field);
      if (value != null) {
        clean[field.id] = value;
      }
    }
    return clean;
  }

  /// Serializes to the wire map.
  Map<String, dynamic> toJson() => {
    'provider': provider.wire,
    'displayName': displayName,
    'credentialFields': [for (final f in credentialFields) f.toJson()],
    'capabilities': capabilities.toJson(),
    if (consoleUrl != null) 'consoleUrl': consoleUrl,
    if (docsUrl != null) 'docsUrl': docsUrl,
    'commandName': commandName,
    if (managementCredentialField != null)
      'managementCredentialField': managementCredentialField,
    'supportsGuidedSetup': supportsGuidedSetup,
    'supportsBotCustomization': supportsBotCustomization,
    'supportsSetupLink': supportsSetupLink,
  };
}
