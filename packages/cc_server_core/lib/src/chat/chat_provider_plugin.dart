import 'package:cc_domain/cc_domain.dart' show ValidationException;
import 'package:cc_domain/features/chat_bridge/domain/value_objects/chat_app_creation.dart';
import 'package:cc_domain/features/chat_bridge/domain/value_objects/chat_bot_profile.dart';
import 'package:cc_domain/features/chat_bridge/domain/value_objects/chat_bridge_connection.dart';
import 'package:cc_domain/features/chat_bridge/domain/value_objects/chat_provider.dart';
import 'package:cc_domain/features/chat_bridge/domain/value_objects/chat_provider_descriptor.dart';
import 'package:cc_infra/cc_infra.dart' show ChatProviderAdapter;

/// What a plugin needs from the server to manage the provider-side app.
///
/// The plugin never decides *where* a credential lives (that is the workspace's
/// own credentials file, which the connector owns), only what to do with it. The
/// read/write pair exists because app-management credentials tend to rotate on
/// every use — Slack invalidates the refresh token it was given — so a rotation
/// has to be persisted through the same seam that reads it.
class ChatAppContext {
  /// Creates a [ChatAppContext].
  const ChatAppContext({
    required this.workspaceId,
    required this.readCredential,
    required this.writeCredential,
    required this.appId,
  });

  /// The workspace whose provider-side app is being managed.
  final String workspaceId;

  /// Reads the current app-management credential, or null when there is none.
  final Future<String?> Function() readCredential;

  /// Persists a rotated app-management credential. A failure here must fail the
  /// operation: the old value is already dead on the provider's side.
  final Future<void> Function(String value) writeCredential;

  /// The provider-side app id to act on. Throws a [ValidationException] when
  /// Control Center does not know which app it is.
  final Future<String> Function() appId;
}

/// Creating and reshaping the provider-side app from Control Center.
///
/// Optional by design: this is the one part of the feature that is genuinely
/// provider-shaped (Slack has an App Manifest API; a Discord bot is created in
/// the developer portal), so a plugin returns null instead of pretending.
abstract interface class ChatAppManager {
  /// Creates the provider-side app and reports what the user must still do by
  /// hand.
  Future<ChatAppCreation> createApp(ChatBotProfile profile);

  /// The live app's customizable fields.
  Future<ChatBotProfile> readProfile();

  /// Applies [profile] to the live app.
  ///
  /// Returns the step the user must still finish for the edit to take effect —
  /// typically reinstalling the app after its permissions changed — or null when
  /// the edit is fully live. A step rather than a bool because the *link* is
  /// provider-specific: the client must be able to open it without knowing which
  /// provider it is showing.
  Future<ChatSetupStep?> writeProfile(ChatBotProfile profile);
}

/// Everything the server needs in order to offer one chat provider.
///
/// This is the registration seam: adding Discord is a new implementation of this
/// interface plus one line in the registry. Nothing above it — the RPC ops, the
/// connector, the settings UI — names a provider, because all three are driven by
/// [descriptor].
abstract interface class ChatProviderPlugin {
  /// The provider's public shape: credential fields, capabilities, URLs.
  ChatProviderDescriptor get descriptor;

  /// Which provider this plugin serves.
  ChatProvider get provider;

  /// The credential field that manages the provider-side app, or null when the
  /// provider has no such credential. Also what `canManageApp` reports on.
  String? get managementCredentialField;

  /// Verifies [credentials] against the provider and returns the connection to
  /// store, with the provider-side identity (team, bot user, app id) filled in.
  ///
  /// Called before anything is persisted, so a mistyped token is reported to the
  /// person pasting it instead of becoming a socket that quietly never works.
  Future<ChatBridgeConnection> connectionFrom({
    required String workspaceId,
    required Map<String, String> credentials,
    ChatBridgeConnection? existing,
  });

  /// Builds the adapter that serves [connection]. The connector owns its
  /// lifecycle.
  ChatProviderAdapter createAdapter(ChatBridgeConnection connection);

  /// Provider-side app management for [context], or null when unsupported.
  ChatAppManager? appManager(ChatAppContext context);

  /// A link into the provider's own console that creates the app with [profile]
  /// already applied, or null when the provider offers no such entry point.
  ///
  /// Distinct from [appManager] on purpose: this needs no credential at all, so
  /// it is the one setup path available before the user has minted anything.
  /// Pure — it composes a URL and dials nothing.
  String? setupLinkFor(ChatBotProfile profile);
}

/// The chat providers this server offers, by [ChatProvider].
///
/// One registry, built at composition time, so "which providers exist" is
/// answered in exactly one place — the `chat.providers` op serializes it, the
/// connector iterates it on boot and an unknown provider on the wire is refused
/// here rather than three layers down.
class ChatProviderRegistry {
  /// Creates a registry over [plugins].
  ChatProviderRegistry(Iterable<ChatProviderPlugin> plugins)
    : _plugins = {for (final plugin in plugins) plugin.provider: plugin};

  final Map<ChatProvider, ChatProviderPlugin> _plugins;

  /// Every registered plugin, in registration order.
  Iterable<ChatProviderPlugin> get plugins => _plugins.values;

  /// Every registered provider.
  Iterable<ChatProvider> get providers => _plugins.keys;

  /// Every provider's descriptor — the payload that makes the settings UI
  /// generic.
  List<ChatProviderDescriptor> get descriptors => [
    for (final plugin in _plugins.values) plugin.descriptor,
  ];

  /// The plugin for [provider], or null when this server does not offer it.
  ChatProviderPlugin? maybeOf(ChatProvider provider) => _plugins[provider];

  /// The plugin for [provider], refusing loudly when it is not registered.
  ChatProviderPlugin of(ChatProvider provider) {
    final plugin = _plugins[provider];
    if (plugin == null) {
      throw ValidationException(
        '${provider.displayName} is not available on this server.',
      );
    }
    return plugin;
  }
}
