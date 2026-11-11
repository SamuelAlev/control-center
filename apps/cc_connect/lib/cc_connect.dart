/// Control Center Connect: provider OAuth for cc_server installs, credential
/// seals bound to the install that authorized them, one-repository GitHub
/// tokens, a body-stripped Slack reference relay and the Klipy proxy.
///
/// Run it standalone (`bin/server.dart`, the `cc-connect` image) or embed it:
/// build a `ConnectServiceConfig` (usually
/// `ConnectServiceConfig.fromEnvironment`), `ConnectService.start` it, and
/// forward every request whose path `ConnectService.ownsPath` accepts to
/// `ConnectService.handle`.
library;

export 'src/binding_store.dart'
    show
        BindingStore,
        BindingStoreUnavailable,
        CachedBindingStore,
        FileBindingStore,
        SlackTeamBinding,
        maxRetiredInstalls;
export 'src/connect_log.dart'
    show
        ConnectFailure,
        ConnectLog,
        ConnectLogLevel,
        ConnectLogSink,
        ConnectRequestScope,
        connectLogFields,
        githubHashedToken,
        truncateIp;
export 'src/connect_service.dart'
    show ConnectServerHandle, ConnectService, serveConnect;
export 'src/credential_seal.dart'
    show
        CredentialSealer,
        OpenedSeal,
        SealBinding,
        SealHeader,
        SealKind,
        sealDigest;
export 'src/firestore_binding_store.dart' show FirestoreBindingStore;
export 'src/gcp_auth.dart' show GcpMetadataTokenSource, GcpTokenSource;
export 'src/pages.dart'
    show
        consentScopeFor,
        formPageContentSecurityPolicy,
        pageContentSecurityPolicy,
        pageStyleHash;
export 'src/private_file.dart' show writePrivateFile;
export 'src/provider_klipy.dart' show normaliseKlipyResponse;
export 'src/redis_state_store.dart' show RedisStateStore;
export 'src/relay_routes.dart' show verifySlackSignature;
export 'src/seal_cipher.dart'
    show
        GcpKmsSealCipher,
        LocalAeadSealCipher,
        SealCipher,
        SealCiphertext,
        SealDecryptFailed,
        newSealKeyEntry,
        parseSealKeyring;
export 'src/secrets.dart' show DualSecret, SecretSource, secretRefreshInterval;
export 'src/sentry_reporter.dart' show SentryDsn, SentryReporter;
export 'src/service_config.dart';
export 'src/state_store.dart'
    show MemoryStateStore, StateLease, StateStore, StateStoreUnavailable;
export 'src/upstream_http.dart'
    show
        IoUpstreamHttp,
        UpstreamHttp,
        UpstreamRequest,
        UpstreamResponse,
        UpstreamUnavailable,
        connectUpstreamHosts;
