// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get succeeded => 'Completato';

  @override
  String agentRunRetryLabel(int number, String time) {
    return 'Nuovo tentativo n. $number · $time';
  }

  @override
  String agentRunStarting(String time) {
    return 'Avvio · $time';
  }

  @override
  String get agentActivityFollowingLive => 'Attività in diretta';

  @override
  String get agentActivityJumpToLatest => 'Vai al più recente';

  @override
  String get agentActivityLoadFailed =>
      'Impossibile caricare l\'attività di questa esecuzione';

  @override
  String get agentActivityNotRecorded =>
      'Nessuna attività registrata per questa esecuzione';

  @override
  String get agentActivityNotRecordedHint =>
      'Le esecuzioni concluse prima dell\'attivazione della cattura delle attività non hanno una cronologia.';

  @override
  String get agentActivityRunUnavailable =>
      'Questa esecuzione non è più disponibile';

  @override
  String agentActivitySubagentOf(String agent) {
    return 'Sottoagente di $agent';
  }

  @override
  String get agentActivityUnsupported =>
      'La cattura delle attività non è disponibile sul server connesso';

  @override
  String get agentActivityUnsupportedHint =>
      'Riavvia l\'app così userà l\'ultima build del server.';

  @override
  String get agentActivityWaiting => 'In attesa di attività…';

  @override
  String get created => 'Creato';

  @override
  String get dictationStart => 'Avvia dettatura';

  @override
  String get dictationListening => 'In ascolto…';

  @override
  String get dictationUnavailable =>
      'La dettatura richiede un modello vocale sul server host. Configuralo nelle impostazioni vocali.';

  @override
  String get dictationFailedToStart => 'Impossibile avviare la dettatura';

  @override
  String get dictationHoldToTalkTitle => 'Tieni premuto per parlare';

  @override
  String get dictationHoldToTalkDescription =>
      'Tieni premuto il pulsante del microfono o la scorciatoia per dettare e rilascia per interrompere. Se disattivato, premi una volta per avviare e di nuovo per interrompere.';

  @override
  String get focusConversation => 'Vai alla conversazione';

  @override
  String get ideAgentActivity => 'Attività dell\'agente';

  @override
  String get keybindingPushToTalk => 'Premi per parlare';

  @override
  String get keybindingPushToTalkDescription =>
      'Tieni premuto o attiva/disattiva la dettatura vocale nell\'editor dei messaggi';

  @override
  String get agentPermissions => 'Autorizzazioni degli agenti';

  @override
  String get agentPermissionsSettingsDescription =>
      'Decidi cosa gli agenti possono fare da soli, cosa devono chiedere prima o cosa non possono mai fare, per spazio di lavoro, agente o canale.';

  @override
  String get agentPermissionsMatrixDescription =>
      'Imposta una decisione per ogni tipo di effetto. Le regole si sovrappongono: il canale prevale sull\'agente, che prevale sullo spazio di lavoro.';

  @override
  String get guardrailLoading => 'Caricamento delle regole…';

  @override
  String get guardrailRulesLoadFailed =>
      'Impossibile caricare le regole delle autorizzazioni.';

  @override
  String get guardrailScopeWorkspace => 'Spazio di lavoro';

  @override
  String get guardrailScopeAgent => 'Agente';

  @override
  String get guardrailScopeChannel => 'Canale';

  @override
  String get guardrailSelectAgent => 'Seleziona un agente';

  @override
  String get guardrailSelectChannel => 'Seleziona un canale';

  @override
  String get guardrailNoAgents =>
      'Ancora nessun agente in questo spazio di lavoro.';

  @override
  String get guardrailNoChannels =>
      'Ancora nessun canale in questo spazio di lavoro.';

  @override
  String get guardrailClassFileDelete => 'Eliminare un file';

  @override
  String get guardrailClassFileWriteOutsideWorktree =>
      'Scrivere fuori dal worktree';

  @override
  String get guardrailClassGitCommit => 'Creare un commit';

  @override
  String get guardrailClassGitPush => 'Eseguire il push a un remoto';

  @override
  String get guardrailClassPrCreate => 'Aprire una pull request';

  @override
  String get guardrailClassPrPublish => 'Pubblicare una revisione o unire';

  @override
  String get guardrailClassVendorSyncWrite => 'Scrivere su un tracker esterno';

  @override
  String get guardrailClassNetworkEgress => 'Accedere alla rete';

  @override
  String get guardrailClassSecretAccess => 'Leggere un segreto';

  @override
  String get guardrailClassPackageInstall => 'Installare un pacchetto';

  @override
  String get guardrailClassProcessSpawn => 'Eseguire un processo';

  @override
  String get guardrailClassWorkspaceMutation =>
      'Modificare la struttura dello spazio di lavoro';

  @override
  String get guardrailClassEnclosureControl => 'Pilotare un recinto (rig)';

  @override
  String get navRigs => 'Rig';

  @override
  String get rigsUnsupportedServer =>
      'Questo server non può ospitare VM isolate. I rig richiedono un hypervisor sulla macchina che esegue cc_server.';

  @override
  String get rigSurfaceComputer => 'Computer';

  @override
  String get rigSurfaceBrowser => 'Browser';

  @override
  String get rigSurfaceMobile => 'Mobile';

  @override
  String get rigPhaseReady => 'Pronto';

  @override
  String get rigPhaseStarting => 'Avvio';

  @override
  String get rigPhaseParked => 'In pausa';

  @override
  String get rigPhaseClosing => 'Chiusura';

  @override
  String get rigPhaseClosed => 'Chiuso';

  @override
  String get rigPhaseFailed => 'Non riuscito';

  @override
  String get rigPhaseUnknown => 'Sconosciuto';

  @override
  String get rigNotAccelerated => 'Emulato';

  @override
  String get rigTakeControl => 'Prendi il controllo';

  @override
  String get rigAudioListen => 'Ascolta la macchina';

  @override
  String get rigAudioMute => 'Silenzia la macchina';

  @override
  String get rigHandBack => 'Restituisci il controllo';

  @override
  String get rigYouHaveControl => 'Hai il controllo';

  @override
  String get rigBackendAvailable => 'Disponibile';

  @override
  String get rigBackendUnavailable => 'Non disponibile';

  @override
  String get rigEgressNotEnforced =>
      'La rete non è isolata su questo backend — gestisce la propria connettività.';

  @override
  String get rigStartMachine => 'Avvia la macchina';

  @override
  String get rigStartHint =>
      'Avvia una VM usa e getta condivisa con i tuoi agenti per questa conversazione. Viene distrutta alla chiusura e nulla di ciò che accade al suo interno tocca il tuo computer.';

  @override
  String get rigStopMachine => 'Ferma la macchina';

  @override
  String get rigSurfaceUnavailable =>
      'Questo server non può ospitare questo tipo di macchina.';

  @override
  String get rigTabNeedsConversation =>
      'Apri prima una conversazione: una macchina appartiene a una di esse, così tu e i tuoi agenti guardate lo stesso schermo.';

  @override
  String get rigTabComputer => 'Computer (VM)';

  @override
  String get rigTabBrowser => 'Browser (VM)';

  @override
  String get rigTabMobile => 'Telefono (VM)';

  @override
  String get rigsSettingsSubtitle =>
      'Cosa può avviare questo server, le immagini di base che servono e le macchine in esecuzione';

  @override
  String get rigsCapabilitiesTitle => 'Questo server';

  @override
  String get rigsImagesTitle => 'Immagini di base';

  @override
  String get rigsImagesHint =>
      'Ogni rig si avvia da una di queste immagini in sola lettura. Ogni sessione scrive su uno strato usa e getta, così un rig non può mai cambiare il punto di partenza del successivo.';

  @override
  String get rigsRunningTitle => 'In esecuzione';

  @override
  String get rigsNoneRunning => 'Nessuna macchina in esecuzione.';

  @override
  String get rigsCustomImagesTitle =>
      'Immagini personalizzate (questo spazio di lavoro)';

  @override
  String get rigsCustomImagesHint =>
      'Punta il Terminale (VM) o il Browser (VM) alla tua immagine — estendi quelle predefinite con gli strumenti del tuo progetto, o usane una compatibile da un registry. Le nuove macchine la usano; quelle in esecuzione mantengono la loro. Vedi la guida ai rig per cosa deve fornire un\'immagine.';

  @override
  String get rigsCustomTerminalImageLabel => 'Immagine del Terminale (VM)';

  @override
  String get rigsCustomBrowserImageLabel => 'Immagine del Browser (VM)';

  @override
  String get rigsCustomImagePlaceholder =>
      'es. ghcr.io/acme/dev-shell:1.2 — vuoto per la predefinita';

  @override
  String get rigsCustomImageInvalid =>
      'Inserisci un riferimento di registry come repo/nome:tag. Percorsi locali e archivi non sono consentiti.';

  @override
  String get rigsCustomImageSaved =>
      'Salvato. Le nuove macchine avviano questa immagine; quelle in esecuzione mantengono la loro.';

  @override
  String get rigsEgressTitle => 'Uscita del browser (questo workspace)';

  @override
  String get rigsEgressHint =>
      'Host aggiuntivi raggiungibili dal browser isolato — uno per riga: un host esatto (api.example.com) o un carattere jolly per i suoi sottodomini (*.example.com). Il sito del prodotto resta sempre consentito. Le nuove macchine usano l\'elenco; quelle in esecuzione mantengono la loro.';

  @override
  String rigsEgressInvalid(String host) {
    return '\"$host\" non è un host valido.';
  }

  @override
  String get rigsEgressSaved =>
      'Salvato. Le nuove macchine browser ammettono questi host; quelle in esecuzione mantengono i loro.';

  @override
  String get rigImageInstalled => 'Installata';

  @override
  String get rigImageNotDownloaded => 'Non scaricata';

  @override
  String get rigImageNotPublished => 'Non pubblicata';

  @override
  String get rigImageNotPublishedHint =>
      'Non è ancora stata pubblicata un\'immagine per questo, quindi non c\'è nulla da scaricare. Importa un\'immagine disco compatibile per abilitarlo.';

  @override
  String get rigImageDownload => 'Scarica';

  @override
  String get rigImageDownloading => 'Download in corso…';

  @override
  String get rigImageImport => 'Importa';

  @override
  String get rigImageImportMessage =>
      'Percorso di un\'immagine disco qcow2 sul filesystem del server. Viene copiata nell\'archivio immagini, quindi il file può essere spostato dopo.';

  @override
  String get rigConnectingStream => 'Connessione al rig';

  @override
  String get rigStreamNotAllowed => 'Non hai accesso a questo rig.';

  @override
  String get rigStreamNotRunning => 'Questo rig non è più in esecuzione.';

  @override
  String get rigStreamNeedsFfmpeg =>
      'La vista dal vivo richiede ffmpeg su questo host. Installa ffmpeg e riapri la scheda.';

  @override
  String get rigStreamEnded => 'La vista dal vivo è terminata.';

  @override
  String get rigStreamFailed => 'Impossibile aprire la vista dal vivo.';

  @override
  String get rigStreamDisconnected => 'Nessuna connessione a un server.';

  @override
  String get rigClipboardUnreadable =>
      'La macchina non ha risposto quando le sono stati chiesti gli appunti.';

  @override
  String rigDropSendingOne(String name) {
    return 'Copia di «$name» nella macchina…';
  }

  @override
  String rigDropSendingMany(int count) {
    return 'Copia di $count file nella macchina…';
  }

  @override
  String get rigTerminalDropSending => 'Copia nella macchina…';

  @override
  String get rigTerminalPasteImage =>
      'Immagine incollata salvata nella macchina';

  @override
  String get rigPortsTitle => 'Porte inoltrate';

  @override
  String get rigPortsTooltip => 'Porte aperte in questa macchina';

  @override
  String get rigPortsEmpty =>
      'Nulla è in ascolto ancora. Avvia un server nel terminale — un dev server sulla porta 3000 appare qui.';

  @override
  String get rigPortsAdd => 'Aggiungi porta';

  @override
  String get rigPortsAddHint => 'Porta guest da inoltrare (es. 3000)';

  @override
  String get rigPortsAutoForward => 'Inoltro automatico delle porte';

  @override
  String get rigPortsCopyUrl => 'Copia URL locale';

  @override
  String rigPortsCopiedUrl(String url) {
    return '$url copiato';
  }

  @override
  String get rigPortsStopForward => 'Interrompi l\'inoltro';

  @override
  String get rigPortsExposeLan => 'Condividi sulla rete locale';

  @override
  String get rigPortsLanPrivate => 'Solo locale';

  @override
  String get rigPortsLanShared => 'Sulla rete';

  @override
  String get rigPortsSetDomain => 'Imposta un dominio browser (.test)';

  @override
  String get rigPortsDomainHint =>
      'Dominio per il Browser (VM), es. myapp.test — raggiungibile lì, non sull\'host';

  @override
  String get rigPortsProcessUnknown => 'processo sconosciuto';

  @override
  String get rigPortsInactive => 'non in ascolto';

  @override
  String rigImagesMissing(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count immagini di base da scaricare',
      one: '1 immagine di base da scaricare',
    );
    return '$_temp0';
  }

  @override
  String get guardrailDecisionAllow => 'Consenti';

  @override
  String get guardrailDecisionPrompt => 'Chiedi prima';

  @override
  String get guardrailDecisionDeny => 'Nega';

  @override
  String get guardrailSourceThisScope => 'Questo ambito';

  @override
  String get guardrailSourceDefault => 'Predefinito';

  @override
  String get guardrailSourcePreset => 'Preimpostazione della modalità';

  @override
  String get guardrailSourceInherited => 'Ereditato';

  @override
  String get guardrailClearToInherited => 'Ripristina al valore ereditato';

  @override
  String get guardrailWhatIf => 'E se?';

  @override
  String get guardrailWhatIfDescription =>
      'Scopri come le regole attuali risolverebbero un\'azione, con la stessa logica applicata agli agenti.';

  @override
  String get guardrailProbeActionLabel => 'Azione';

  @override
  String get guardrailProbeCommandLabel => 'Comando (facoltativo)';

  @override
  String get guardrailProbeCommandHint => 'es. git push origin main';

  @override
  String get guardrailProbeAgentLabel => 'Agente (facoltativo)';

  @override
  String get guardrailProbeChannelLabel => 'Canale (facoltativo)';

  @override
  String get guardrailProbeNone => 'Nessuno';

  @override
  String get guardrailProbeModeLabel => 'Modalità';

  @override
  String get guardrailProbeResult => 'Risultato';

  @override
  String get guardrailProbeSource => 'Origine:';

  @override
  String get guardrailAdapterMatrix => 'Dove vengono applicate le regole';

  @override
  String get guardrailAdapterMatrixDescription =>
      'Riferimento onesto: dove ogni effetto viene realmente intercettato, in base all\'esecutore dell\'agente. Documenta la realtà, non una garanzia: gli effetti che un esecutore produce fuori banda non possono essere intercettati.';

  @override
  String get guardrailEffectColumn => 'Effetto';

  @override
  String get guardrailAdapterHarness => 'Harness integrato';

  @override
  String get guardrailAdapterClaudeCli => 'Claude CLI';

  @override
  String get guardrailAdapterMcpHttp => 'MCP (HTTP)';

  @override
  String get guardrailAdapterSandbox => 'Base della sandbox';

  @override
  String get guardrailEnforcementPolicyGate => 'Controllo tramite criterio';

  @override
  String get guardrailEnforcementSandbox => 'Solo sandbox';

  @override
  String get guardrailEnforcementNone => 'Non applicabile';

  @override
  String get guardrailEnforcementPolicyGateHelp =>
      'La decisione sull\'autorizzazione viene verificata prima che l\'effetto venga eseguito e può bloccarlo.';

  @override
  String get guardrailEnforcementSandboxHelp =>
      'Solo la sandbox lo limita; la regola di autorizzazione non viene consultata.';

  @override
  String get guardrailEnforcementNoneHelp =>
      'La decisione è solo indicativa: non può essere intercettata qui.';

  @override
  String get obsStatCost => 'costo';

  @override
  String obsStatDelegatedCost(String amount) {
    return '+$amount delegato';
  }

  @override
  String get obsStatDuration => 'durata';

  @override
  String get obsStatTokens => 'token';

  @override
  String get obsStatTools => 'strumenti';

  @override
  String get openAgentActivity => 'Apri attività';

  @override
  String get orgChart => 'Organigramma';

  @override
  String get orgChartEmpty => 'Nessun agente ancora';

  @override
  String get navCalendar => 'Calendario';

  @override
  String get serverConnection => 'Connessione al server';

  @override
  String get serverConnectionMode => 'Modalità';

  @override
  String get serverModeLocal => 'Esegui in questa app';

  @override
  String get serverModeLocalDescription =>
      'Control Center esegue il proprio server su questo computer e mantiene i tuoi dati in locale.';

  @override
  String get serverModeRemote => 'Connetti a un\'istanza remota';

  @override
  String get serverModeRemoteDescription =>
      'Connettiti a un server Control Center in esecuzione altrove. I tuoi dati risiedono su quel server.';

  @override
  String get serverRemoteUrl => 'URL del server';

  @override
  String get serverRemoteDeviceId => 'ID dispositivo';

  @override
  String get serverRemotePairingKey => 'Chiave di abbinamento';

  @override
  String get serverRemotePairingKeyHint =>
      'Incolla la chiave di abbinamento dal server remoto';

  @override
  String get serverSetupInviteCode => 'Codice di invito';

  @override
  String get serverSetupInviteCodeHint =>
      'Incolla un codice di invito monouso (lascia vuoto per usare una chiave di associazione)';

  @override
  String get serverDiscoveryTooltip => 'Trova server sulla tua rete';

  @override
  String get serverDiscoveryTitle => 'Server sulla tua rete';

  @override
  String get serverDiscoverySearching => 'Ricerca dei server…';

  @override
  String get serverDiscoveryEmpty =>
      'Nessun server trovato. Verifica che il server sia in esecuzione e che questo dispositivo possa raggiungerlo, quindi riprova la ricerca.';

  @override
  String get serverDiscoveryRefresh => 'Cerca di nuovo';

  @override
  String get serverListActive => 'Attivo';

  @override
  String get serverListSwitch => 'Passa';

  @override
  String get serverListAddTitle => 'Aggiungi server';

  @override
  String get serverListRemoveActiveHint =>
      'Passa a un altro server prima di rimuovere questo.';

  @override
  String get serverSwitchFailedTitle => 'Impossibile cambiare server';

  @override
  String get serverListInsecureBadge => 'Non sicuro';

  @override
  String get connectionPathLocal => 'Locale';

  @override
  String get connectionPathLan => 'LAN';

  @override
  String get connectionPathTailnet => 'Tailnet';

  @override
  String get shutdownTitle => 'Arresto in corso';

  @override
  String get shutdownSubtitle => 'Chiusura del server locale';

  @override
  String get shutdownServiceApprovals => 'Approvazioni';

  @override
  String get shutdownServiceBackgroundJobs => 'Attività in background';

  @override
  String get shutdownServiceScheduler => 'Pianificatore di attività';

  @override
  String get shutdownServiceCalendar => 'Sincronizzazione calendario';

  @override
  String get shutdownServiceWeather => 'Meteo';

  @override
  String get shutdownServiceSoundscape => 'Paesaggio sonoro';

  @override
  String get shutdownServiceMeetings => 'Riunioni';

  @override
  String get shutdownServiceVoiceModels => 'Modelli vocali';

  @override
  String get shutdownServiceNetworking => 'Rete';

  @override
  String get shutdownServicePresence => 'Presenza';

  @override
  String get shutdownServiceDataSync => 'Sincronizzazione dati';

  @override
  String get shutdownServiceDeviceRelay => 'Relay dispositivi';

  @override
  String get shutdownServiceMcpConnections => 'Connessioni MCP';

  @override
  String get shutdownServiceCodeEditors => 'Editor di codice';

  @override
  String get serverSharingTitle => 'Condividi questo server';

  @override
  String get serverSharingDescription =>
      'Rendi questo server raggiungibile dagli altri tuoi dispositivi. Nulla viene esposto pubblicamente finché non attivi un tunnel qui sotto. Gli inviti di abbinamento includono automaticamente gli indirizzi attuali del server; creali nelle impostazioni dell\'area di lavoro.';

  @override
  String get serverSharingUnavailable =>
      'I controlli di condivisione non sono disponibili su questo server.';

  @override
  String get serverSharingMdnsLabel => 'Rilevamento LAN';

  @override
  String get serverSharingMdnsOn =>
      'Questo server viene annunciato sulla rete locale (mDNS)';

  @override
  String get serverSharingMdnsOff =>
      'Questo server non viene annunciato sulla rete locale (mDNS)';

  @override
  String get serverSharingTunnelLabel => 'Tunnel';

  @override
  String get serverSharingTunnelHelper =>
      'Attivare un tunnel rende questo server raggiungibile da internet. L\'esposizione pubblica è facoltativa e disattivata per impostazione predefinita.';

  @override
  String get serverSharingProviderOff => 'Disattivato';

  @override
  String get serverSharingProviderCloudflared => 'Cloudflared';

  @override
  String get serverSharingProviderNgrok => 'ngrok';

  @override
  String get serverSharingProviderTailscale => 'Tailscale';

  @override
  String get serverSharingPublicUrlLabel => 'URL pubblico';

  @override
  String get serverSharingTunnelStarting => 'Avvio del tunnel…';

  @override
  String serverSharingTunnelError(String error) {
    return 'Errore del tunnel: $error';
  }

  @override
  String get serverSharingTunnelUpNoUrl =>
      'Il tunnel è attivo. Raggiungilo tramite il nome host DNS configurato.';

  @override
  String get serverSharingRelayLabel => 'Inoltro';

  @override
  String serverSharingRelayUsage(String amount) {
    return 'Inoltrato questo mese: $amount';
  }

  @override
  String serverSharingRelaySessions(int count) {
    return 'Sessioni di inoltro attive: $count';
  }

  @override
  String get serverSharingUpdateFailedTitle =>
      'Impossibile aggiornare la condivisione';

  @override
  String get serverConnectionRestartHint =>
      'Riavvia Control Center per applicare le modifiche alla connessione.';

  @override
  String get serverConnectionReloadHint =>
      'Ricarica la pagina per riconnetterti con queste modifiche.';

  @override
  String get pairNewClient => 'Associa un nuovo client';

  @override
  String get pairClientNameHint =>
      'Assegna un nome a questo client (es. Portatile di lavoro)';

  @override
  String get pairClientTypeWeb => 'Browser web';

  @override
  String get pairClientTypeDesktop => 'App desktop';

  @override
  String get pairClientTypePhone => 'Telefono';

  @override
  String get pairAction => 'Associa';

  @override
  String get revoke => 'Revoca';

  @override
  String get pairCredentialsIntro =>
      'Collega il nuovo client con questi dati, o apri il link su di esso.';

  @override
  String get pairLinkLabel => 'Link';

  @override
  String get pairScanQr =>
      'Inquadra questo codice QR con la fotocamera del telefono per associarlo.';

  @override
  String get pairServerUnreachableTitle => 'Non raggiungibile';

  @override
  String get pairServerUnreachable =>
      'Gli altri dispositivi non possono raggiungere questo server direttamente, quindi un nuovo client non può connettersi. Imposta l\'URL pubblico del server per associare altri client.';

  @override
  String get serverSetupTitle => 'Come eseguire Control Center?';

  @override
  String get serverSetupSubtitle =>
      'Control Center ha bisogno di un server che possieda i tuoi dati. Eseguine uno in questa app o connettiti a un\'istanza in esecuzione altrove.';

  @override
  String get serverSetupRunLocal => 'Esegui in questa app';

  @override
  String get serverSetupConnect => 'Connetti';

  @override
  String get serverSetupInvalidUrl =>
      'Inserisci un URL del server ws:// o wss:// valido.';

  @override
  String get serverSetupCouldNotConnect => 'Impossibile connettersi';

  @override
  String get serverSetupErrorUnreachable =>
      'Impossibile raggiungere il server. Verifica che sia in esecuzione e che questo dispositivo possa contattarlo (stessa rete o relay).';

  @override
  String get serverSetupErrorIdentityMismatch =>
      'L\'identità del server non corrisponde a quella salvata su questo dispositivo. Se il server è stato reinstallato o reimpostato, rimuovi il server salvato ed esegui di nuovo l\'associazione.';

  @override
  String get serverSetupErrorAuthRejected =>
      'Il server ha rifiutato questo dispositivo. Verifica che la chiave di associazione e l\'id del dispositivo corrispondano a quelli emessi dal server.';

  @override
  String get serverSetupErrorInviteRejected =>
      'Questo codice invito non è valido o è scaduto. Chiedine uno nuovo.';

  @override
  String get serverSetupErrorGeneric =>
      'Si è verificato un problema durante la connessione. Espandi i dettagli tecnici qui sotto per maggiori informazioni.';

  @override
  String get serverSetupErrorDetails => 'Dettagli tecnici';

  @override
  String calendarMoreEvents(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count altri',
      one: '1 altro',
    );
    return '$_temp0';
  }

  @override
  String get calendarViewMonth => 'Mese';

  @override
  String get calendarViewWeek => 'Settimana';

  @override
  String get calendarViewAgenda => 'Agenda';

  @override
  String get calendarConnectGoogle => 'Collega Google Calendar';

  @override
  String get calendarConnectDescription =>
      'Sincronizza il tuo Google Calendar per vedere gli eventi qui e ricevere avvisi prima dell\'inizio delle riunioni.';

  @override
  String get calendarDisconnect => 'Disconnetti';

  @override
  String get calendarReconnect => 'Riconnetti';

  @override
  String get calendarEmptyNoEvents => 'Nessun evento in questo intervallo';

  @override
  String get calendarStartRecording => 'Avvia registrazione';

  @override
  String get calendarStartRecordingAndLink => 'Registra e collega';

  @override
  String get calendarJoinMeet => 'Partecipa alla riunione';

  @override
  String get calendarFromCalendar => 'Dal calendario';

  @override
  String get calendarLinkedMeeting => 'Riunione collegata';

  @override
  String get calendarToday => 'Oggi';

  @override
  String get calendarAllDay => 'Tutto il giorno';

  @override
  String calendarWeekNumber(int number) {
    return 'Settimana $number';
  }

  @override
  String get calendarPreviousPeriod => 'Precedente';

  @override
  String get calendarNextPeriod => 'Successivo';

  @override
  String calendarLastSynced(String time) {
    return 'Sincronizzato $time';
  }

  @override
  String get calendarNeverSynced => 'Non ancora sincronizzato';

  @override
  String get calendarSyncing => 'Sincronizzazione…';

  @override
  String get calendarViewDay => 'Giorno';

  @override
  String get calendarSectionCalendars => 'Calendari';

  @override
  String get calendarShow => 'Mostra';

  @override
  String get calendarHide => 'Nascondi';

  @override
  String get calendarRsvpGoing => 'Parteciperai?';

  @override
  String get calendarRsvpYes => 'Sì';

  @override
  String get calendarRsvpNo => 'No';

  @override
  String get calendarRsvpMaybe => 'Forse';

  @override
  String get calendarRsvpFailed => 'Impossibile aggiornare la tua risposta';

  @override
  String get calendarAddAccount => 'Aggiungi account calendario';

  @override
  String get calendarSettingsTitle => 'Google Calendar';

  @override
  String get calendarSettingsDescription =>
      'Collega un account Google per sincronizzare gli eventi in questo spazio di lavoro.';

  @override
  String get calendarNotConnected => 'Nessun account Google collegato';

  @override
  String get calendarConnecting => 'Connessione…';

  @override
  String get calendarSyncNow => 'Sincronizza ora';

  @override
  String get calendarNoWorkspace =>
      'Seleziona uno spazio di lavoro per vedere il suo calendario';

  @override
  String get calendarConnectError => 'Impossibile collegare Google Calendar';

  @override
  String get calendarClientIdLabel => 'ID client';

  @override
  String get calendarClientSecretLabel => 'Secret client';

  @override
  String get calendarConnectCredsHint =>
      'Inserisci l\'ID client e il secret OAuth (device-code) del tuo progetto Google. Il server gestisce la connessione e la sincronizzazione: il browser non conserva mai i token.';

  @override
  String get calendarConnectApproveInstruction =>
      'Apri la pagina di verifica su qualsiasi dispositivo, accedi e inserisci questo codice:';

  @override
  String get calendarConnectOpenPage => 'Apri pagina di verifica';

  @override
  String get calendarConnectWaiting => 'In attesa di approvazione…';

  @override
  String get calendarConnectDenied => 'Autorizzazione negata. Riprova.';

  @override
  String get calendarConnectExpired => 'Il codice è scaduto. Riprova.';

  @override
  String get calendarNotConfigured =>
      'Google Calendar non è configurato. Imposta GOOGLE_OAUTH_CLIENT_ID per collegare un account.';

  @override
  String get notificationMeetingStartsSoon => 'Riunione in arrivo';

  @override
  String get notifyMeetingStartsSoon =>
      'Quando una riunione del calendario sta per iniziare';

  @override
  String get notificationCalendarAuthExpiredTitle => 'Calendario disconnesso';

  @override
  String notificationCalendarAuthExpiredBody(String email) {
    return 'Riconnetti $email per riprendere la sincronizzazione';
  }

  @override
  String get notificationCalendarAuthExpiredBodyNoEmail =>
      'Riconnetti il tuo calendario per riprendere la sincronizzazione';

  @override
  String get notifyCalendarAuthExpired =>
      'Quando un account del calendario deve essere riconnesso';

  @override
  String get notificationRigStatusChanged => 'Aggiornamenti sui recinti';

  @override
  String get notifyRigStatusChanged =>
      'Quando un recinto viene preso in carico, recuperato o fallisce';

  @override
  String get notificationRigTakenOver => 'Recinto preso in carico';

  @override
  String get notificationRigTakenOverBody =>
      'Una persona sta guidando la macchina; l\'agente può osservare ma non agire.';

  @override
  String get notificationRigReleased => 'Controllo del recinto rilasciato';

  @override
  String get notificationRigReleasedBody =>
      'L\'agente ha di nuovo la macchina.';

  @override
  String get notificationRigReclaimed => 'Recinto recuperato';

  @override
  String get notificationRigReclaimedBodyIdle =>
      'È rimasta inattiva, quindi la macchina è stata chiusa per liberare memoria.';

  @override
  String get notificationRigReclaimedBodyTtl =>
      'Ha raggiunto il suo limite di tempo ed è stata chiusa.';

  @override
  String get notificationRigFailed => 'Recinto non riuscito';

  @override
  String get notificationRigFailedBody =>
      'L\'hypervisor è morto sotto di essa. Riapri la macchina per continuare.';

  @override
  String get calendarAlertLeadTime => 'Anticipo dell\'avviso';

  @override
  String get calendarAlertLeadTimeSubtitle =>
      'Quanto tempo prima di una riunione avvisarti';

  @override
  String calendarConnectedAs(String email) {
    return 'Connesso come $email';
  }

  @override
  String calendarAttendeesCount(int count) {
    return '$count partecipanti';
  }

  @override
  String get calendarEventLabel => 'Evento';

  @override
  String get calendarRecurring => 'Evento ricorrente';

  @override
  String get calendarGoogleMeet => 'Google Meet';

  @override
  String get calendarOrganizer => 'Organizzatore';

  @override
  String get calendarYou => 'Tu';

  @override
  String get calendarShowFewer => 'Mostra meno';

  @override
  String get calendarRsvpAwaiting => 'In attesa';

  @override
  String calendarParticipantsCount(int count) {
    return '$count partecipanti';
  }

  @override
  String calendarSeeAllParticipants(int count) {
    return 'Vedi tutti i $count partecipanti';
  }

  @override
  String calendarRsvpCountYes(int count) {
    return '$count sì';
  }

  @override
  String calendarRsvpCountNo(int count) {
    return '$count no';
  }

  @override
  String calendarRsvpCountMaybe(int count) {
    return '$count forse';
  }

  @override
  String calendarRsvpCountAwaiting(int count) {
    return '$count in attesa';
  }

  @override
  String calendarLeadMinutesOption(int count) {
    return '$count minuti';
  }

  @override
  String get openInEditorPrompt => 'In quale editor aprire?';

  @override
  String get ideNotInstalled => 'Non installato';

  @override
  String openInIde(String editor) {
    return 'Apri in $editor';
  }

  @override
  String failedToOpenInIde(String editor, String error) {
    return 'Impossibile aprire $editor: $error';
  }

  @override
  String get profileSearchHint => 'Cerca pull request…';

  @override
  String get profileClickToLoad => 'Clicca per caricare';

  @override
  String get byAuthorPrefix => 'di';

  @override
  String get stopAgentRun => 'Interrompi esecuzione';

  @override
  String get stopAgentRunConfirm =>
      'Interrompere questa esecuzione? Il lavoro in corso andrà perso.';

  @override
  String get youLabel => 'tu';

  @override
  String get readyToMerge => 'Pronto per il merge';

  @override
  String get inProgress => 'In corso';

  @override
  String get needsAttention => 'Richiede attenzione';

  @override
  String get drafts => 'Bozze';

  @override
  String get allOpenPrs => 'Tutte le PR aperte';

  @override
  String showAllCount(int count) {
    return 'Mostra tutte ($count)';
  }

  @override
  String get sortOldest => 'Meno recenti';

  @override
  String get sortLargest => 'Più grandi';

  @override
  String get prFilterTooltip => 'Filtra';

  @override
  String prFilterActiveCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count filtri attivi',
      one: '1 filtro attivo',
    );
    return '$_temp0';
  }

  @override
  String get prFilterAddFilter => 'Aggiungi filtro…';

  @override
  String get prFilterFieldHint => 'Filtra…';

  @override
  String get prFilterCategoryStatus => 'Stato';

  @override
  String get prFilterCategoryAuthor => 'Autore';

  @override
  String get prFilterCategoryReviewer => 'Revisori';

  @override
  String get prFilterCategoryContent => 'Contenuto';

  @override
  String get prFilterCategoryRepoOwner => 'Proprietario della repository';

  @override
  String get prFilterCategoryRepoName => 'Nome della repository';

  @override
  String get prFilterCategoryOpenedDate => 'Data di apertura';

  @override
  String get prFilterCategoryUpdatedDate => 'Data di aggiornamento';

  @override
  String get prFilterQuickToReview => 'Rapida da revisionare';

  @override
  String get prFilterClearAll => 'Cancella filtri';

  @override
  String prFilterMatchCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pull request',
      one: '1 pull request',
    );
    return '$_temp0';
  }

  @override
  String prFilterHiddenOptions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count opzioni che non corrispondono ad alcuna pull request',
      one: '1 opzione che non corrisponde ad alcuna pull request',
    );
    return '$_temp0';
  }

  @override
  String get prFilterContentHint => 'Il titolo o il corpo contiene…';

  @override
  String get prFilterNoOptions => 'Nessuna opzione corrispondente';

  @override
  String get prFilterChipIs => 'è';

  @override
  String get prFilterChipIsAnyOf => 'è uno di';

  @override
  String get prFilterChipContains => 'contiene';

  @override
  String get prFilterChipSince => 'da';

  @override
  String get prFilterAddFilterButton => 'Aggiungi filtro';

  @override
  String prFilterClearCategory(String category) {
    return 'Cancella filtro $category';
  }

  @override
  String get prFilterCurrentUser => 'Utente corrente';

  @override
  String get prStatusDraft => 'Bozza';

  @override
  String get prStatusOpen => 'Aperta';

  @override
  String get prStatusInReview => 'In revisione';

  @override
  String get prStatusChangesRequested => 'Modifiche richieste';

  @override
  String get prStatusApproved => 'Approvato';

  @override
  String get prStatusMerged => 'Unita';

  @override
  String get prStatusClosed => 'Chiuso';

  @override
  String get prDateWindowDay => '1 giorno fa';

  @override
  String get prDateWindowThreeDays => '3 giorni fa';

  @override
  String get prDateWindowWeek => '1 settimana fa';

  @override
  String get prDateWindowMonth => '1 mese fa';

  @override
  String get prDateWindowThreeMonths => '3 mesi fa';

  @override
  String get prDateWindowSixMonths => '6 mesi fa';

  @override
  String get prDateWindowYear => '1 anno fa';

  @override
  String get prDisplayOptions => 'Opzioni di visualizzazione';

  @override
  String get prDisplayGrouping => 'Raggruppamento';

  @override
  String get prDisplayOrdering => 'Ordinamento';

  @override
  String get prDisplayShowDrafts => 'Mostra bozze';

  @override
  String get prDisplayMergedWindow => 'Finestra di fusione';

  @override
  String get prDisplayMergedWindowDay => 'Ultimo giorno';

  @override
  String get prDisplayMergedWindowWeek => 'Ultima settimana';

  @override
  String get prDisplayMergedWindowMonth => 'Ultimo mese';

  @override
  String get prDisplayProperties => 'Proprietà di visualizzazione';

  @override
  String get prGroupingRepository => 'Repository';

  @override
  String get prGroupingAuthor => 'Autore';

  @override
  String get prGroupingStatus => 'Stato';

  @override
  String get prGroupingNone => 'Nessun raggruppamento';

  @override
  String get prPropertyRepository => 'Repository';

  @override
  String get prPropertyId => 'ID';

  @override
  String get prPropertyBranch => 'Branch';

  @override
  String get prPropertyUpdated => 'Aggiornato';

  @override
  String get prPropertyAuthor => 'Autore';

  @override
  String get prPropertyChecks => 'Controlli';

  @override
  String get prPropertyDiff => 'Diff';

  @override
  String get prPropertyComments => 'Commenti';

  @override
  String get prGroupUnknownAuthor => 'Autore sconosciuto';

  @override
  String get keybindingOpenFilterMenu => 'Apri il menu dei filtri';

  @override
  String get keybindingOpenThePullRequestFilterMenuDescription =>
      'Apri il menu dei filtri delle PR';

  @override
  String get selectAction => 'Seleziona';

  @override
  String mergeCountReady(int count) {
    return 'Unisci $count pronte';
  }

  @override
  String countSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count selezionate',
      one: '1 selezionata',
    );
    return '$_temp0';
  }

  @override
  String get summary => 'Riepilogo';

  @override
  String get openFullDiff => 'Apri diff completo';

  @override
  String get viewFiles => 'Visualizza file';

  @override
  String get checksLabel => 'Controlli';

  @override
  String get commentsLabel => 'Commenti';

  @override
  String get keybindingSelectPr => 'Seleziona PR';

  @override
  String get keybindingMergePr => 'Unisci PR';

  @override
  String get keybindingPeekPr => 'Anteprima PR';

  @override
  String get keybindingToggleSelectionOfTheFocusedPullRequestDescription =>
      'Attiva/disattiva la selezione della PR a fuoco';

  @override
  String get keybindingMergeTheFocusedPullRequestDescription =>
      'Unire la PR a fuoco se è pronta';

  @override
  String get keybindingExpandOrCollapseTheFocusedPullRequestPeekDescription =>
      'Espandere o comprimere il pannello di anteprima della PR a fuoco';

  @override
  String get kbMove => 'muovi';

  @override
  String get kbTabs => 'schede';

  @override
  String get kbSearch => 'cerca';

  @override
  String get kbViewed => 'visto';

  @override
  String get kbCollapse => 'comprimi';

  @override
  String get appearance => 'Aspetto';

  @override
  String get appearanceSettingsDescription => 'Tema, lingua e tipografia.';

  @override
  String get notificationsSettingsDescription =>
      'Scegli quali eventi degli agenti e degli spazi di lavoro ti notificano.';

  @override
  String get integrationsSettingsDescription =>
      'Collega GitHub, la gestione dei ticket e il server MCP.';

  @override
  String get advanced => 'Avanzate';

  @override
  String get advancedSettingsDescription =>
      'Denominazione dei branch, ricerca semantica, connessione al server, comportamento di sistema e registrazione.';

  @override
  String get agentRegistry => 'Registro degli agenti';

  @override
  String get settingsGroupGeneral => 'Generale';

  @override
  String get settingsGroupAgents => 'Agenti';

  @override
  String get settingsGroupResources => 'Risorse';

  @override
  String get settingsGroupWorkspace => 'Spazio di lavoro';

  @override
  String get settingsGroupSystem => 'Sistema';

  @override
  String get settingsGroupIntegrations => 'Integrazioni';

  @override
  String get accounts => 'Account';

  @override
  String get accountsSettingsDescription =>
      'Account GitHub, ticketing, calendario e chat.';

  @override
  String get mcpServers => 'Server MCP';

  @override
  String get mcpServersSettingsDescription =>
      'Server MCP integrato e server MCP esterni.';

  @override
  String get remoteControlAndDevices => 'Controllo remoto e dispositivi';

  @override
  String get remoteControlAndDevicesSettingsDescription =>
      'Associa telefoni e configura il server di controllo remoto.';

  @override
  String get voiceAndMeetings => 'Voce e riunioni';

  @override
  String get voiceAndMeetingsSettingsDescription =>
      'I modelli di voce e diarizzazione ospitati da questo server.';

  @override
  String get securityAndPrivacy => 'Sicurezza e privacy';

  @override
  String get securityAndPrivacySettingsDescription =>
      'Sandboxing, regole dei comandi e privacy.';

  @override
  String get filterSettingsHint => 'Filtra le impostazioni';

  @override
  String get needsSetupLabel => 'Configurazione necessaria';

  @override
  String noSettingsMatch(String query) {
    return 'Nessuna impostazione corrisponde a «$query»';
  }

  @override
  String get collapseSidebar => 'Comprimi la barra laterale';

  @override
  String get expandSidebar => 'Espandi la barra laterale';

  @override
  String get filterChannelsHint => 'Filtra i canali';

  @override
  String noChannelsMatch(String query) {
    return 'Nessun canale corrisponde a «$query»';
  }

  @override
  String get privacy => 'Privacy';

  @override
  String get sendDiffContentTitle =>
      'Invia il contenuto del diff all\'adattatore IA';

  @override
  String get diffSharingOnSubtitle =>
      'Le righe di diff non elaborate sono incluse nei prompt degli agenti per una revisione più approfondita.';

  @override
  String get diffSharingOffSubtitle =>
      'Gli agenti usano solo metadati strutturati (percorsi dei file, numeri di riga, descrizione della PR); nessun codice non elaborato lascia l\'app.';

  @override
  String get errorReportingTitle => 'Condividi i rapporti di arresto anomalo';

  @override
  String get errorReportingOnSubtitle =>
      'I diagnostici di arresto anomalo, errore e prestazioni vengono inviati per aiutare a correggere i bug (solo nelle versioni di produzione).';

  @override
  String get errorReportingOffSubtitle =>
      'I diagnostici sono disattivati. Non viene inviato alcun rapporto di arresto anomalo o di errore.';

  @override
  String get onboardingDiagnosticsTitle => 'Aiuta a migliorare Control Center';

  @override
  String get onboardingDiagnosticsSubtitle =>
      'Invia diagnostici di arresto anomalo, errore e prestazioni per aiutarci a risolvere i problemi più velocemente (solo nelle versioni di produzione). Puoi modificare questa impostazione in qualsiasi momento in Impostazioni → Privacy.';

  @override
  String get blocked => 'Bloccato';

  @override
  String get idle => 'Inattivo';

  @override
  String get noRunsYet => 'Nessuna esecuzione';

  @override
  String runsInLastSixMonths(String count) {
    return '$count esecuzioni negli ultimi 6 mesi';
  }

  @override
  String lastActiveAgo(String duration) {
    return 'Attivo $duration fa';
  }

  @override
  String get reportsToNobody => 'Nessun responsabile';

  @override
  String get copyPath => 'Copia percorso';

  @override
  String get copyRelativePath => 'Copia percorso relativo';

  @override
  String get pathCopied => 'Percorso copiato negli appunti';

  @override
  String get editAgent => 'Modifica agente';

  @override
  String get nameRequired => 'Il nome è obbligatorio';

  @override
  String get titleRequired => 'Il titolo è obbligatorio';

  @override
  String get import => 'Importa';

  @override
  String discoverAgentsFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count definizioni di agente trovate',
      one: '1 definizione di agente trovata',
    );
    return '$_temp0';
  }

  @override
  String get noAgentsToDiscover => 'Nessun nuovo agente da importare';

  @override
  String get noAgentsToDiscoverHint =>
      'Le definizioni di agente in questo spazio di lavoro sono già importate.';

  @override
  String get sortByStatus => 'Stato';

  @override
  String get sortByName => 'Nome';

  @override
  String get noMatchingAgents => 'Nessun agente corrisponde al filtro';

  @override
  String get selectAnAgentHint =>
      'Scegli un agente per vederne stato, attività e dettagli.';

  @override
  String watchVideoOn(String provider) {
    return 'Guarda il video su $provider';
  }

  @override
  String get branchTemplate => 'Modello di nome del branch';

  @override
  String get branchTemplateDescription =>
      'Schema del branch creato quando un ticket viene avviato in un worktree isolato.';

  @override
  String branchTemplatePreview(String example) {
    return 'Esempio: $example';
  }

  @override
  String get deletePipelineRun => 'Elimina esecuzione della pipeline';

  @override
  String deletePipelineRunConfirm(String template) {
    return 'Eliminare questa esecuzione di «$template»? Questa azione non può essere annullata.';
  }

  @override
  String errorDeletingPipelineRun(String error) {
    return 'Errore durante l\'eliminazione dell\'esecuzione della pipeline: $error';
  }

  @override
  String get deleteTicket => 'Elimina ticket';

  @override
  String deleteTicketConfirm(String title) {
    return 'Eliminare «$title»? Questa azione non può essere annullata.';
  }

  @override
  String errorDeletingTicket(String error) {
    return 'Errore durante l\'eliminazione del ticket: $error';
  }

  @override
  String deleteWorkspaceConfirm(String name) {
    return 'Eliminare «$name»? I repository collegati sul disco non vengono toccati.';
  }

  @override
  String errorDeletingWorkspace(String error) {
    return 'Errore durante l\'eliminazione dell\'area di lavoro: $error';
  }

  @override
  String get indexCode => 'Indicizza codice';

  @override
  String get indexing => 'Indicizzazione…';

  @override
  String get indexNoGrammars => 'Grammatiche del codice non installate';

  @override
  String get indexFailed => 'Indicizzazione non riuscita';

  @override
  String indexedSymbolsCount(int count) {
    return '$count simboli indicizzati';
  }

  @override
  String get nodeConfigAdvanced => 'Avanzate';

  @override
  String get nodeConfigReducer => 'Riduttore';

  @override
  String get nodeConfigReducerHelp =>
      'Come unire quando questa chiave di output ha già un valore';

  @override
  String get nodeConfigTimeoutMs => 'Timeout (ms)';

  @override
  String get nodeConfigRetryAttempts => 'Tentativi di riprova';

  @override
  String get nodeConfigContinueOnFail =>
      'Continua se questo passaggio fallisce';

  @override
  String get nodeConfigTeamId => 'ID team';

  @override
  String get nodeConfigDispatchMode => 'Modalità di invio';

  @override
  String get nodeConfigOutputSchema => 'Schema di output (JSON)';

  @override
  String get nodeConfigOutputSchemaHelp =>
      'Schema JSON che l\'output del passaggio deve rispettare';

  @override
  String get diffLineDisplay => 'Righe lunghe nei diff';

  @override
  String get diffLineDisplayDescription =>
      'Manda a capo le righe lunghe o falle scorrere orizzontalmente';

  @override
  String get diffLineWrap => 'A capo';

  @override
  String get diffLineScroll => 'Scorrimento orizzontale';

  @override
  String get actions => 'Azioni';

  @override
  String get activate => 'Attiva';

  @override
  String get activity => 'Attività';

  @override
  String get activityLabel => 'ATTIVITÀ';

  @override
  String get activitySearchHint => 'Cerca nell\'attività';

  @override
  String get activityNoMatches => 'Nessuna attività corrisponde ai tuoi filtri';

  @override
  String activityPageRange(int start, int end, int total) {
    return '$start–$end di $total';
  }

  @override
  String get activityPreviousPage => 'Pagina precedente';

  @override
  String get activityNextPage => 'Pagina successiva';

  @override
  String get activityNetworkLocal => 'Localhost';

  @override
  String get activityClearFilter => 'Cancella filtro';

  @override
  String activityFilterIp(String ip) {
    return 'IP $ip';
  }

  @override
  String activityFilterCountry(String country) {
    return 'Paese $country';
  }

  @override
  String get activitySavedWorkspaceLogo =>
      'Ha salvato il logo dell\'area di lavoro';

  @override
  String activityVerbCreated(String target) {
    return 'Ha creato $target';
  }

  @override
  String activityVerbUpdated(String target) {
    return 'Ha aggiornato $target';
  }

  @override
  String activityVerbDeleted(String target) {
    return 'Ha eliminato $target';
  }

  @override
  String activityVerbAdded(String target) {
    return 'Ha aggiunto $target';
  }

  @override
  String activityVerbRemoved(String target) {
    return 'Ha rimosso $target';
  }

  @override
  String activityVerbInvited(String target) {
    return 'Ha invitato $target';
  }

  @override
  String activityVerbRevoked(String target) {
    return 'Ha revocato $target';
  }

  @override
  String activityVerbChanged(String target) {
    return 'Ha modificato $target';
  }

  @override
  String activityVerbStarted(String target) {
    return 'Ha avviato $target';
  }

  @override
  String activityVerbStopped(String target) {
    return 'Ha arrestato $target';
  }

  @override
  String activityVerbWrote(String target) {
    return 'Ha scritto $target';
  }

  @override
  String get activityTargetAgent => 'un agente';

  @override
  String get activityTargetTicket => 'un ticket';

  @override
  String get activityTargetWorkspace => 'un\'area di lavoro';

  @override
  String get activityTargetRepository => 'un repository';

  @override
  String get activityTargetMember => 'un membro';

  @override
  String get activityTargetInvite => 'un invito';

  @override
  String get activityTargetChannel => 'un canale';

  @override
  String get activityTargetMessage => 'un messaggio';

  @override
  String get activityTargetCache => 'una cache';

  @override
  String get activityTargetFile => 'un file';

  @override
  String get activityTargetPipeline => 'una pipeline';

  @override
  String get activityTargetTemplate => 'un template';

  @override
  String get activityTargetProvider => 'un provider';

  @override
  String get activityTargetModel => 'un modello';

  @override
  String get activityTargetSkill => 'una competenza';

  @override
  String get activityTargetTodo => 'un todo';

  @override
  String get activityTargetMeeting => 'una riunione';

  @override
  String get activityTargetProject => 'un progetto';

  @override
  String get activityTargetTeam => 'un team';

  @override
  String get activityTargetDevice => 'un dispositivo';

  @override
  String get activityTargetPreference => 'una preferenza';

  @override
  String get activityTargetBudget => 'un budget';

  @override
  String activityVerbApproved(String target) {
    return 'Ha approvato $target';
  }

  @override
  String activityVerbArchived(String target) {
    return 'Ha archiviato $target';
  }

  @override
  String activityVerbAssigned(String target) {
    return 'Ha assegnato $target';
  }

  @override
  String activityVerbBackedUp(String target) {
    return 'Ha eseguito il backup di $target';
  }

  @override
  String activityVerbCancelled(String target) {
    return 'Ha annullato $target';
  }

  @override
  String activityVerbCleared(String target) {
    return 'Ha cancellato $target';
  }

  @override
  String activityVerbClosed(String target) {
    return 'Ha chiuso $target';
  }

  @override
  String activityVerbCommitted(String target) {
    return 'Ha fatto commit di $target';
  }

  @override
  String activityVerbCompacted(String target) {
    return 'Ha compattato $target';
  }

  @override
  String activityVerbCompleted(String target) {
    return 'Ha completato $target';
  }

  @override
  String activityVerbConnected(String target) {
    return 'Ha connesso $target';
  }

  @override
  String activityVerbContinued(String target) {
    return 'Ha continuato $target';
  }

  @override
  String activityVerbDisconnected(String target) {
    return 'Ha disconnesso $target';
  }

  @override
  String activityVerbDispatched(String target) {
    return 'Ha smistato $target';
  }

  @override
  String activityVerbDrained(String target) {
    return 'Ha svuotato $target';
  }

  @override
  String activityVerbEnrolled(String target) {
    return 'Ha iscritto $target';
  }

  @override
  String activityVerbEstimated(String target) {
    return 'Ha stimato $target';
  }

  @override
  String activityVerbImported(String target) {
    return 'Ha importato $target';
  }

  @override
  String activityVerbInstalled(String target) {
    return 'Ha installato $target';
  }

  @override
  String activityVerbKilled(String target) {
    return 'Ha terminato $target';
  }

  @override
  String activityVerbMarked(String target) {
    return 'Ha contrassegnato $target';
  }

  @override
  String activityVerbMerged(String target) {
    return 'Ha eseguito il merge di $target';
  }

  @override
  String activityVerbOpened(String target) {
    return 'Ha aperto $target';
  }

  @override
  String activityVerbPaused(String target) {
    return 'Ha messo in pausa $target';
  }

  @override
  String activityVerbPolled(String target) {
    return 'Ha interrogato $target';
  }

  @override
  String activityVerbPrepared(String target) {
    return 'Ha preparato $target';
  }

  @override
  String activityVerbProcessed(String target) {
    return 'Ha elaborato $target';
  }

  @override
  String activityVerbPublished(String target) {
    return 'Ha pubblicato $target';
  }

  @override
  String activityVerbRefined(String target) {
    return 'Ha raffinato $target';
  }

  @override
  String activityVerbRefreshed(String target) {
    return 'Ha ricaricato $target';
  }

  @override
  String activityVerbRegistered(String target) {
    return 'Ha registrato $target';
  }

  @override
  String activityVerbRenamed(String target) {
    return 'Ha rinominato $target';
  }

  @override
  String activityVerbReordered(String target) {
    return 'Ha riordinato $target';
  }

  @override
  String activityVerbResponded(String target) {
    return 'Ha risposto a $target';
  }

  @override
  String activityVerbRestored(String target) {
    return 'Ha ripristinato $target';
  }

  @override
  String activityVerbResumed(String target) {
    return 'Ha ripreso $target';
  }

  @override
  String activityVerbRetried(String target) {
    return 'Ha ritentato $target';
  }

  @override
  String activityVerbReverted(String target) {
    return 'Ha eseguito il revert di $target';
  }

  @override
  String activityVerbReviewed(String target) {
    return 'Ha revisionato $target';
  }

  @override
  String activityVerbRan(String target) {
    return 'Ha eseguito $target';
  }

  @override
  String activityVerbSelected(String target) {
    return 'Ha selezionato $target';
  }

  @override
  String activityVerbSent(String target) {
    return 'Ha inviato $target';
  }

  @override
  String activityVerbStaged(String target) {
    return 'Ha aggiunto $target allo stage';
  }

  @override
  String activityVerbSteered(String target) {
    return 'Ha guidato $target';
  }

  @override
  String activityVerbSubmitted(String target) {
    return 'Ha inoltrato $target';
  }

  @override
  String activityVerbSynced(String target) {
    return 'Ha sincronizzato $target';
  }

  @override
  String activityVerbToggled(String target) {
    return 'Ha commutato $target';
  }

  @override
  String activityVerbUninstalled(String target) {
    return 'Ha disinstallato $target';
  }

  @override
  String activityVerbUnstaged(String target) {
    return 'Ha rimosso $target dallo stage';
  }

  @override
  String get activityTargetActionPolicy => 'una policy delle azioni';

  @override
  String get activityTargetGoalRun => 'un\'esecuzione di obiettivo';

  @override
  String get activityTargetRunLog => 'un log di esecuzione';

  @override
  String get activityTargetWorkingMemory => 'una memoria di lavoro';

  @override
  String get activityTargetRoutingPolicy => 'una policy di routing';

  @override
  String get activityTargetAutonomy => 'un\'autonomia';

  @override
  String get activityTargetCalendar => 'un calendario';

  @override
  String get activityTargetChecker => 'un checker';

  @override
  String get activityTargetEditor => 'un editor';

  @override
  String get activityTargetConfirmation => 'una conferma';

  @override
  String get activityTargetTunnel => 'un tunnel';

  @override
  String get activityTargetConversation => 'una conversazione';

  @override
  String get activityTargetCredentials => 'delle credenziali';

  @override
  String get activityTargetDictation => 'una dettatura';

  @override
  String get activityTargetAgentRun => 'un\'esecuzione di agente';

  @override
  String get activityTargetEvalSuite => 'una suite di valutazione';

  @override
  String get activityTargetWorker => 'un worker';

  @override
  String get activityTargetWorktree => 'un worktree';

  @override
  String get activityTargetMcpServer => 'un server MCP';

  @override
  String get activityTargetMemoryAccessGrant =>
      'un\'autorizzazione di accesso alla memoria';

  @override
  String get activityTargetMemoryDomain => 'un dominio di memoria';

  @override
  String get activityTargetMemoryFact => 'un fatto di memoria';

  @override
  String get activityTargetMemoryPolicy => 'una policy di memoria';

  @override
  String get activityTargetFeed => 'un feed';

  @override
  String get activityTargetNote => 'una nota';

  @override
  String get activityTargetOrchestration => 'un\'orchestrazione';

  @override
  String get activityTargetPipelineRun => 'un\'esecuzione di pipeline';

  @override
  String get activityTargetPipelineTrigger => 'un trigger di pipeline';

  @override
  String get activityTargetPlan => 'un piano';

  @override
  String get activityTargetPlaybook => 'un playbook';

  @override
  String get activityTargetPullRequest => 'una pull request';

  @override
  String get activityTargetReview => 'una review';

  @override
  String get activityTargetProcess => 'un processo';

  @override
  String get activityTargetProviderPolicy => 'una policy del provider';

  @override
  String get activityTargetReaction => 'una reazione';

  @override
  String get activityTargetReviewChannel => 'un canale di review';

  @override
  String get activityTargetReviewStudio => 'uno studio di review';

  @override
  String get activityTargetServerData => 'dei dati del server';

  @override
  String get activityTargetSoundscape => 'un paesaggio sonoro';

  @override
  String get activityTargetSession => 'una sessione';

  @override
  String get activityTargetTerminal => 'un terminale';

  @override
  String get activityTargetTicketLink => 'un link di ticket';

  @override
  String get activityTargetTicketSync => 'una sincronizzazione dei ticket';

  @override
  String get activityTargetProfile => 'un profilo';

  @override
  String get activityTargetVoiceProfile => 'un profilo vocale';

  @override
  String get activityTargetWeather => 'una previsione meteo';

  @override
  String get activityTargetWorkProduct => 'un prodotto di lavoro';

  @override
  String get activityChangedMemberRole => 'Ha modificato il ruolo di un membro';

  @override
  String get activityChangedMemberRepoAccess =>
      'Ha modificato l\'accesso di un membro ai repository';

  @override
  String get activityUpdatedGitHubToken => 'Ha aggiornato il token di GitHub';

  @override
  String get activityRefreshedWeather => 'Ha ricaricato la previsione meteo';

  @override
  String get activitySetWeatherLocation => 'Ha impostato la località meteo';

  @override
  String get activityClearedWeatherLocation =>
      'Ha cancellato la località meteo';

  @override
  String get activityMarkedAllArticlesRead =>
      'Ha contrassegnato tutti gli articoli come letti';

  @override
  String get activityMarkedArticleRead =>
      'Ha contrassegnato un articolo come letto';

  @override
  String get activityUpdatedSavedArticle => 'Ha aggiornato un articolo salvato';

  @override
  String get activityTookOverSession => 'Ha preso il controllo della sessione';

  @override
  String get activityHandedBackSession => 'Ha restituito la sessione';

  @override
  String get activityCommittedAndPushed => 'Ha fatto commit e push';

  @override
  String get activityBackedUpServer =>
      'Ha eseguito il backup dei dati del server';

  @override
  String get activityMarkedChannelRead =>
      'Ha contrassegnato il canale come letto';

  @override
  String get activityRespondedToInvitation =>
      'Ha risposto all\'invito all\'evento';

  @override
  String get activityStartedCalendarConnect =>
      'Ha avviato la connessione del calendario';

  @override
  String get activityDisconnectedCalendar => 'Ha disconnesso il calendario';

  @override
  String get activityMarkedFileViewed =>
      'Ha contrassegnato un file come visualizzato';

  @override
  String get activityRespondedToApproval =>
      'Ha risposto a una richiesta di approvazione';

  @override
  String get activityChangedTunnel =>
      'Ha modificato l\'impostazione del tunnel';

  @override
  String get activitySentMessageToAgent =>
      'Ha inviato un messaggio all\'agente';

  @override
  String get activityOpenedReviewChannel => 'Ha aperto il canale di review';

  @override
  String get activityOpenedMainConversation =>
      'Ha aperto la conversazione principale';

  @override
  String get activityStartedRecording => 'Ha avviato la registrazione';

  @override
  String get activityStoppedRecording => 'Ha arrestato la registrazione';

  @override
  String get activityToggledMcpServer => 'Ha commutato il server MCP';

  @override
  String get activityUpdatedMcpToken => 'Ha aggiornato il token MCP';

  @override
  String get activitySavedApiKey => 'Ha salvato una chiave API';

  @override
  String get activityRemovedProviderCredential =>
      'Ha rimosso una credenziale del provider';

  @override
  String get activityUpdatedLinkedRepos =>
      'Ha aggiornato i repository collegati';

  @override
  String get activityUnlinkedRepo => 'Ha scollegato un repository';

  @override
  String get activityUpdatedActionItem => 'Ha aggiornato un\'azione';

  @override
  String adRulesCount(int count) {
    return '$count regole pubblicitarie';
  }

  @override
  String get adapter => 'Adattatore';

  @override
  String get adapterLabel => 'Adattatore';

  @override
  String get adapters => 'Adattatori';

  @override
  String get adaptersAutoDetected =>
      'Runner degli agenti rilevati automaticamente su questa macchina. Installa eventuali strumenti CLI mancanti per abilitare runner aggiuntivi.';

  @override
  String get add => 'Aggiungi';

  @override
  String get addAComment => 'Aggiungi un commento';

  @override
  String get addAReaction => 'Aggiungi una reazione';

  @override
  String get addASuggestion => 'Aggiungi un suggerimento';

  @override
  String get addAgent => 'Aggiungi agente';

  @override
  String get addAgents => 'Aggiungi agenti';

  @override
  String get addAgentsToEnable =>
      'Aggiungi agenti per abilitare l\'orchestrazione multi-agente';

  @override
  String get addEmoji => 'Aggiungi emoji';

  @override
  String get addFeed => 'Aggiungi feed';

  @override
  String get addressBarHint => 'Inserisci un URL';

  @override
  String get addFromFile => 'Aggiungi da file';

  @override
  String get addGif => 'Aggiungi GIF';

  @override
  String get addGithubRepoPrompt =>
      'Aggiungi almeno una repository GitHub per vedere le pull request';

  @override
  String get addLocalCheckoutDescription =>
      'Aggiungi un checkout locale per iniziare a puntarlo da questo spazio di lavoro.';

  @override
  String get addRepository => 'Aggiungi repository';

  @override
  String addSelectedRepositories(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Aggiungi # repository',
      one: 'Aggiungi repository',
    );
    return '$_temp0';
  }

  @override
  String get addRepoBrowseIntro =>
      'Sfoglia le cartelle sulla macchina che esegue il server e seleziona i checkout git da registrare.';

  @override
  String get selectThisFolder => 'Seleziona questa cartella';

  @override
  String get deselectThisFolder => 'Deseleziona questa cartella';

  @override
  String get goUp => 'Su';

  @override
  String get noSubfoldersHere => 'Nessuna sottocartella qui';

  @override
  String get notAGitRepository => 'Questa cartella non è un repository git.';

  @override
  String get addToken => 'Aggiungi token';

  @override
  String get addWorkspace => 'Aggiungi spazio di lavoro';

  @override
  String get addWorkspaceEllipsis => 'Aggiungi spazio di lavoro…';

  @override
  String get added => 'Aggiunto';

  @override
  String get addingEllipsis => 'Aggiunta in corso...';

  @override
  String get advancedLabel => 'Avanzate';

  @override
  String get agent => 'Agente';

  @override
  String agentCount(int count, int plural) {
    String _temp0 = intl.Intl.pluralLogic(
      plural,
      locale: localeName,
      other: 'i',
      one: 'e',
    );
    return '$count agent$_temp0';
  }

  @override
  String get agentMdPath => 'Percorso MD dell\'agente';

  @override
  String get agentName => 'Nome dell\'agente';

  @override
  String get agentTitle => 'Titolo dell\'agente';

  @override
  String get agentUpdated => 'Agente aggiornato.';

  @override
  String get agents => 'Agenti';

  @override
  String agentsCount(int count, num plural) {
    return 'Agenti ($count)';
  }

  @override
  String get agentsMentionSection => 'Agenti';

  @override
  String get usersMentionSection => 'Persone';

  @override
  String get ticketsMentionSection => 'Ticket';

  @override
  String get pullRequestsMentionSection => 'Pull request';

  @override
  String get meetingsMentionSection => 'Riunioni';

  @override
  String get entityRefTicketFallback => 'Ticket';

  @override
  String get entityRefPrFallback => 'Pull request';

  @override
  String get entityRefMeetingFallback => 'Riunione';

  @override
  String get aiReview => 'Revisione IA';

  @override
  String get all => 'Tutto';

  @override
  String get allAgentsAlreadyInChannel =>
      'Tutti gli agenti sono già in questo canale.';

  @override
  String get allCommits => 'Tutti i commit';

  @override
  String get allSessionsReset =>
      'Tutte le sessioni sandbox sono state ripristinate.';

  @override
  String get allSources => 'Tutte le fonti';

  @override
  String get allow => 'Consenti';

  @override
  String get allowGitPush => 'Consenti git push';

  @override
  String get allowGithubApi => 'Consenti chiamate API GitHub';

  @override
  String get allowNetwork => 'Consenti accesso di rete generale';

  @override
  String get apiKeys => 'Chiavi API';

  @override
  String get appFont => 'Font dell\'app';

  @override
  String get appLogLevelDebugDescription =>
      'Aggiunge tracce dettagliate - per sviluppo.';

  @override
  String get appLogLevelDebugLabel => 'Debug';

  @override
  String get appLogLevelErrorDescription =>
      'Solo errori ed eccezioni inattese.';

  @override
  String get appLogLevelErrorLabel => 'Errore';

  @override
  String get appLogLevelInfoDescription =>
      'Aggiunge messaggi di ciclo di vita e stato.';

  @override
  String get appLogLevelInfoLabel => 'Info';

  @override
  String get appLogLevelNoneDescription => 'Nessun output console.';

  @override
  String get appLogLevelNoneLabel => 'Nessuno';

  @override
  String get appLogLevelVerboseDescription =>
      'Tutto. Estremamente verboso - usare solo per debug.';

  @override
  String get appLogLevelVerboseLabel => 'Verboso';

  @override
  String get appLogLevelWarningDescription =>
      'Aggiunge avvisi e problemi recuperabili.';

  @override
  String get appLogLevelWarningLabel => 'Avviso';

  @override
  String get appTitle => 'Control Center';

  @override
  String get appearanceLanguage => 'Aspetto e lingua';

  @override
  String get apply => 'Applica';

  @override
  String get approve => 'Approva';

  @override
  String get agentApprovalRequired => 'Approvazione richiesta';

  @override
  String get approveAndCompact => 'Approva e comprimi contesto';

  @override
  String get approveAndExecute => 'Approva ed esegui';

  @override
  String get approveAndHire => 'Approva e assumi';

  @override
  String get approved => 'Approvato';

  @override
  String get articlesSubscribed => 'Articoli dai feed a cui sei iscritto.';

  @override
  String get askAi => 'Ask AI';

  @override
  String get askAiReview => 'Richiedi revisione IA';

  @override
  String get askAiReviewDescription =>
      'Chiedi all\'IA di revisionare questa PR';

  @override
  String get askAnything =>
      'Chiedi qualsiasi cosa… (@ per menzionare agenti, / per comandi)';

  @override
  String get assignees => 'ASSEGNATARI';

  @override
  String get attachFiles => 'Allega file';

  @override
  String get attachImage => 'Allega immagine';

  @override
  String get attachedAgents => 'Agenti collegati';

  @override
  String get audioInput => 'Ingresso audio';

  @override
  String get authentication => 'Autenticazione';

  @override
  String get authenticationToken => 'Token di autenticazione';

  @override
  String authoredByLabel(String role) {
    return 'Di: $role';
  }

  @override
  String get authorsLabel => 'Autori';

  @override
  String authorsWithCount(int count) {
    return 'Autori · $count';
  }

  @override
  String get autoRecommended => 'Automatico (consigliato)';

  @override
  String get available => 'Disponibile';

  @override
  String get awaitingYourApproval => 'In attesa della tua approvazione';

  @override
  String get awaitingYourReview => 'In attesa della tua revisione';

  @override
  String get back => 'Indietro';

  @override
  String get backLabel => 'Indietro';

  @override
  String get backend => 'Backend';

  @override
  String get blockAdsDescription =>
      'Blocca pubblicità, tracker e banner per i cookie';

  @override
  String get blockAdsTrackers =>
      'Blocca pubblicità, tracker e banner per i cookie';

  @override
  String get blocking => 'Bloccante';

  @override
  String get bookmarkLabel => 'Segnalibro';

  @override
  String get briefDescription => 'Breve descrizione';

  @override
  String get bugLabel => 'BUG';

  @override
  String get bundledDefaultsNeverUpdated =>
      'Predefiniti inclusi - mai aggiornati';

  @override
  String get cached => 'In cache';

  @override
  String get cancel => 'Cancel';

  @override
  String get cancelEdit => 'Annulla modifica';

  @override
  String get categoryCreation => 'Creazione';

  @override
  String get categoryDeletion => 'Eliminazione';

  @override
  String get categoryEditing => 'Modifica';

  @override
  String get categoryNavigation => 'Navigazione';

  @override
  String get categorySystem => 'Sistema';

  @override
  String get categoryView => 'Vista';

  @override
  String get change => 'Cambia';

  @override
  String get changesRequested => 'Modifiche richieste';

  @override
  String get changesSummary => 'Riepilogo delle modifiche';

  @override
  String get channelsMentionSection => 'Canali';

  @override
  String get checkForUpdates => 'Cerca aggiornamenti';

  @override
  String get checking => 'Verifica in corso';

  @override
  String get checkingEllipsis => 'Verifica…';

  @override
  String get checkingGhCli => 'Verifica gh CLI in corso…';

  @override
  String get chooseAppFont => 'Scegli il font dell\'app';

  @override
  String get chooseCodeFont => 'Scegli il font del codice';

  @override
  String get chooseRunner => 'Scegli il tuo runner per gli agenti.';

  @override
  String get clear => 'Cancella';

  @override
  String get clickToRetry => 'Clicca per riprovare';

  @override
  String get close => 'Chiudi';

  @override
  String get closeEsc => 'Chiudi (Esc)';

  @override
  String get closeKeyboardHint => 'Chiudi tasti rapidi';

  @override
  String get closePanel => 'Chiudi pannello';

  @override
  String get closeReader => 'Chiudi lettore';

  @override
  String get closed => 'Chiuso';

  @override
  String get codeFont => 'Font del codice';

  @override
  String get codeFontLigatures => 'Legature del font del codice';

  @override
  String get codeFontLigaturesDescription =>
      'Mostra le legature di programmazione (=>, !=, ->) come glifi combinati nel codice e nei diff';

  @override
  String get collapse => 'Comprimi';

  @override
  String get commandPalette => 'Palette dei comandi';

  @override
  String get commandPaletteOrgMembers => 'Organization members';

  @override
  String get commandPaletteBrowseTeam => 'Browse team';

  @override
  String get commandPaletteBrowseTeamDesc => 'View all organization members';

  @override
  String get compactDone =>
      'Conversazione compattata. La cronologia precedente è stata riassunta.';

  @override
  String get compactNothing =>
      'Niente da compattare per ora. La conversazione è ancora breve.';

  @override
  String get compactBusy =>
      'Un agente sta ancora lavorando. Compatta al termine del turno.';

  @override
  String get compactUnavailable =>
      'La compattazione non è disponibile su questo server.';

  @override
  String get commandsMentionSection => 'Comandi';

  @override
  String get comment => 'Commento';

  @override
  String get commentOnFile => 'Commenta questo file';

  @override
  String get commentOnThisFile => 'Commenta questo file';

  @override
  String get commentSelected => 'Commenta selezione';

  @override
  String get commented => 'Ha commentato';

  @override
  String get commits => 'Commit';

  @override
  String commitsShowingLatest(int loaded, int total) {
    return 'Visualizzazione degli ultimi $loaded di $total commit';
  }

  @override
  String get prCloneProgressCloningTitle => 'Clonazione del repository';

  @override
  String prCloneProgressCloningSubtitle(int fileCount) {
    return 'Questa PR modifica $fileCount file, superando il limite dell\'API di GitHub. Clonazione del repository in locale…';
  }

  @override
  String get prCloneProgressCloningSubtitleNoCount =>
      'Questa PR supera il limite di file dell\'API di GitHub. Clonazione del repository in locale…';

  @override
  String get prCloneProgressFetchingTitle => 'Recupero dei refs';

  @override
  String get prCloneProgressFetchingSubtitle =>
      'Recupero del branch base e della ref della PR…';

  @override
  String get prCloneProgressComputingTitle => 'Calcolo del diff';

  @override
  String get prCloneProgressComputingSubtitle =>
      'Esecuzione di git diff in locale…';

  @override
  String get prCloneProgressErrorTitle => 'Caricamento del diff non riuscito';

  @override
  String get prCloneProgressErrorSubtitle =>
      'Si è verificato un errore durante la clonazione o il calcolo del diff.';

  @override
  String prCloneProgressElapsed(String elapsed) {
    return 'Ancora in corso… $elapsed trascorsi';
  }

  @override
  String confidenceLabel(int percent) {
    return 'Confidenza: $percent%';
  }

  @override
  String get configureAgentIdentities =>
      'Configura identità degli agenti, prompt, competenze e visualizza le esecuzioni.';

  @override
  String get configureDefaultRunners =>
      'Configura quale adattatore e modello sono usati per le nuove conversazioni e la generazione dei titoli.';

  @override
  String get configuredLabel => 'Configurato.';

  @override
  String get confirmedBy => 'Confermato da';

  @override
  String get consensus => 'Consenso';

  @override
  String get contentBlockingDescription =>
      'Blocca pubblicità, tracker e banner per i cookie';

  @override
  String get contentHint => 'Cosa dovrebbe essere ricordato';

  @override
  String get contentLabel => 'Contenuto';

  @override
  String get contentMarkdown => 'Contenuto (Markdown)';

  @override
  String get contextWindowSize => 'Dimensione della finestra di contesto';

  @override
  String modelContextChip(String size) {
    return 'Modello · $size';
  }

  @override
  String get continueLabel => 'Continua';

  @override
  String get conversationMode => 'Modalità';

  @override
  String cookieRulesCount(int count) {
    return '$count regole cookie';
  }

  @override
  String get copied => 'Copiato!';

  @override
  String get copy => 'Copia';

  @override
  String get copyAddress => 'Copia indirizzo';

  @override
  String get copyBaseBranchTooltip =>
      'Copia il nome del branch di destinazione';

  @override
  String get copyHeadBranchTooltip => 'Copia il nome del branch di origine';

  @override
  String get couldNotCheckGhCli => 'Impossibile verificare gh CLI.';

  @override
  String couldNotListDevices(String error) {
    return 'Impossibile elencare i dispositivi: $error';
  }

  @override
  String get create => 'Crea';

  @override
  String get createFirstAgent => 'Crea il tuo primo agente per iniziare.';

  @override
  String get createOrSelectWorkspace =>
      'Crea o seleziona uno spazio di lavoro prima di aggiungere repository.';

  @override
  String get createPr => 'Crea PR';

  @override
  String get createPullRequest => 'Crea pull request';

  @override
  String get createdByMe => 'Create da me';

  @override
  String createdLabel(String date) {
    return 'Creato: $date';
  }

  @override
  String get currentParticipants => 'Partecipanti attuali';

  @override
  String get customCapabilitiesDescription =>
      'Capacità personalizzate per questo agente';

  @override
  String get customSystemPrompt =>
      'Prompt di sistema personalizzato per questo agente...';

  @override
  String daysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count giorni fa',
      one: '1 giorno fa',
    );
    return '$_temp0';
  }

  @override
  String get deactivate => 'Disattiva';

  @override
  String get defaultCapabilities =>
      'Capacità predefinite · nuove conversazioni';

  @override
  String get defaultChat => 'Chat predefinita';

  @override
  String defaultPortHint(int port) {
    return 'Predefinito: $port.';
  }

  @override
  String get defaultRunners => 'Runner predefiniti';

  @override
  String get delete => 'Elimina';

  @override
  String get deleteAgent => 'Elimina agente';

  @override
  String deleteAgentConfirm(String name) {
    return 'Eliminare \"$name\"? Questa azione non può essere annullata.';
  }

  @override
  String get deleteChannel => 'Elimina canale';

  @override
  String deleteConfirmName(String name) {
    return 'Eliminare \"$name\"?';
  }

  @override
  String get deleteConversation => 'Elimina conversazione';

  @override
  String get deleteConversationConfirm =>
      'Eliminare questa conversazione? Tutti i messaggi saranno persi.';

  @override
  String get deleteFact => 'Elimina fatto';

  @override
  String get deleteFeedBody =>
      'Questo rimuove il feed e tutti i suoi articoli in cache. Anche gli articoli salvati nei segnalibri di questo feed saranno rimossi.';

  @override
  String deleteFeedConfirm(String name) {
    return 'Eliminare \"$name\"?';
  }

  @override
  String deleteNamedConversation(String name) {
    return 'Eliminare \"$name\"? Tutti i messaggi andranno persi.';
  }

  @override
  String get deletePolicy => 'Elimina regola';

  @override
  String get deletePolicyConfirm =>
      'Eliminare questa regola? Questa azione non può essere annullata.';

  @override
  String deleteTopicConfirm(String topic) {
    return 'Eliminare \"$topic\"? Questa azione non può essere annullata.';
  }

  @override
  String get deleteWorkspace => 'Elimina spazio di lavoro';

  @override
  String get deny => 'Nega';

  @override
  String get descriptionLabel => 'Descrizione';

  @override
  String get detailsLabel => 'Dettagli';

  @override
  String detectedBackend(String label) {
    return 'Rilevato: $label';
  }

  @override
  String detectedRunners(int count) {
    return 'Runner rilevati ($count)';
  }

  @override
  String get detectingAdapters => 'Rilevamento adattatori…';

  @override
  String get detectingGhCli => 'Rilevamento gh CLI…';

  @override
  String get detectingInputDevices => 'Rilevamento dispositivi di ingresso…';

  @override
  String detectionFailed(String error) {
    return 'Rilevamento non riuscito: $error';
  }

  @override
  String diffFailed(String message) {
    return 'Diff non riuscito: $message';
  }

  @override
  String get disabled => 'Disattivato';

  @override
  String get discover => 'Scopri';

  @override
  String get discoverAgents => 'Scopri agenti';

  @override
  String get discoverAgentsDescription =>
      'La scoperta degli agenti cerca file AGENTS.md e TEAM.md nei percorsi dello spazio di lavoro, analizzandoli nel registro degli agenti.\n\nConfigura prima uno spazio di lavoro, poi usa questa funzione per popolare automaticamente gli agenti.';

  @override
  String get dismissed => 'Respinto';

  @override
  String get domainHint => 'es: api-performance';

  @override
  String get domainLabel => 'Dominio';

  @override
  String get download => 'Scarica';

  @override
  String get downloadingLabel => 'Download';

  @override
  String downloadingModel(int pct) {
    return 'Download del modello… $pct%';
  }

  @override
  String get draft => 'Bozza';

  @override
  String get draftLabel => 'Bozza';

  @override
  String get edit => 'Modifica';

  @override
  String get edited => 'modificato';

  @override
  String get editMessage => 'Modifica messaggio';

  @override
  String get deleteMessage => 'Elimina messaggio';

  @override
  String get deleteMessageConfirm =>
      'Eliminare questo messaggio? L\'azione non può essere annullata.';

  @override
  String get messageDeleted => 'Messaggio eliminato';

  @override
  String get searchInConversation => 'Cerca nella conversazione';

  @override
  String get searchMessagesHint => 'Cerca messaggi…';

  @override
  String get noMessagesFound => 'Nessun messaggio trovato';

  @override
  String get editFact => 'Modifica fatto';

  @override
  String get editPolicy => 'Modifica politica';

  @override
  String get editSuggestedCodeHint => 'Modifica il codice suggerito...';

  @override
  String get editSuggestion => 'Modifica suggerimento';

  @override
  String get editTheSuggestedCodeHint => 'Modifica il codice suggerito...';

  @override
  String get egArchitect => 'es. architetto';

  @override
  String get egControlCenter => 'es: control-center';

  @override
  String get egPlatform => 'es: macOS';

  @override
  String get egSamuelAlev => 'es: SamuelAlev';

  @override
  String get egSoftwareArchitect => 'es. Software Architect';

  @override
  String get egTheVerge => 'es. The Verge';

  @override
  String get egTokenLimit => 'es: 128000';

  @override
  String embeddingInstallFailed(String error) {
    return 'Installazione non riuscita: $error';
  }

  @override
  String get embeddingInstalled =>
      'Modello di embedding locale installato. La ricerca ibrida è abilitata.';

  @override
  String get embeddingModel => 'Modello di embedding (ONNX)';

  @override
  String get embeddingNotInstalled =>
      'Non installato. La ricerca passa a solo parole chiave finché non viene abilitato.';

  @override
  String get embeddingRedownloadBody =>
      'I file del modello esistenti saranno eliminati e scaricati di nuovo. La ricerca semantica non sarà disponibile fino al completamento del download.';

  @override
  String get embeddingRemoveBody =>
      'La ricerca semantica sarà disabilitata finché non la reinstalli. Puoi installarla di nuovo in qualsiasi momento.';

  @override
  String get speakerDiarization => 'Diarizzazione dei parlanti';

  @override
  String get diarizationModel => 'Modello di diarizzazione';

  @override
  String get diarizationInstalled =>
      'Installato — assegna un nome a ciascun parlante nelle trascrizioni delle riunioni';

  @override
  String get diarizationNotInstalled =>
      'Non installato — i parlanti delle riunioni non verranno separati';

  @override
  String diarizationInstallFailed(String error) {
    return 'Installazione non riuscita: $error';
  }

  @override
  String get redownloadDiarizationModel =>
      'Scarica di nuovo il modello di diarizzazione';

  @override
  String get diarizationRedownloadBody =>
      'Questo rimuove i modelli di diarizzazione attuali e li scarica di nuovo.';

  @override
  String get removeDiarizationModel => 'Rimuovi il modello di diarizzazione';

  @override
  String get diarizationRemoveBody =>
      'Questo elimina i modelli di diarizzazione sul dispositivo. Le trascrizioni delle riunioni già prodotte non vengono interessate.';

  @override
  String get enableMcpServer => 'Abilita server MCP';

  @override
  String get enableNotifications => 'Abilita notifiche';

  @override
  String get enableSandboxing => 'Abilita sandboxing';

  @override
  String get enabled => 'Attivato';

  @override
  String enterToken(String name) {
    return 'Inserisci token $name';
  }

  @override
  String get enterTokenToAuth =>
      'Inserisci un token per richiedere l\'autenticazione';

  @override
  String errorCreatingAgent(String error) {
    return 'Errore nella creazione dell\'agente: $error';
  }

  @override
  String errorDeletingAgent(String error) {
    return 'Errore nell\'eliminazione dell\'agente: $error';
  }

  @override
  String get errorLoadingAgents => 'Errore durante il caricamento degli agenti';

  @override
  String errorWithDetail(String error) {
    return 'Errore: $error';
  }

  @override
  String get errored => 'Con errori';

  @override
  String get exitSelection => 'Esci dalla selezione';

  @override
  String get expand => 'Espandi';

  @override
  String get extractingLabel => 'Estrazione';

  @override
  String extractingModel(int pct) {
    return 'Estrazione del modello… $pct%';
  }

  @override
  String get fact => 'Fatto';

  @override
  String factCount(int count) {
    return '$count fatto';
  }

  @override
  String factCountPlural(int count) {
    return '$count fatti';
  }

  @override
  String get facts => 'Fatti';

  @override
  String factsPoliciesCount(int factCount, int policyCount) {
    return '$factCount fatti · $policyCount politiche';
  }

  @override
  String get failed => 'Non riuscito';

  @override
  String failedToDispatch(String error) {
    return 'Invio non riuscito: $error';
  }

  @override
  String get failedToLoad => 'Caricamento non riuscito';

  @override
  String failedToLoadAgents(String error) {
    return 'Caricamento agenti non riuscito: $error';
  }

  @override
  String failedToLoadFeeds(String error) {
    return 'Caricamento feed non riuscito: $error';
  }

  @override
  String get failedToLoadGifs => 'Caricamento GIF non riuscito';

  @override
  String failedToLoadLogs(String error) {
    return 'Caricamento log non riuscito: $error';
  }

  @override
  String get failedToLoadRepos => 'Caricamento delle repository non riuscito';

  @override
  String get failedToLoadWorkspaces =>
      'Caricamento spazi di lavoro non riuscito';

  @override
  String failedToStartAiReview(String error) {
    return 'Avvio revisione IA non riuscito: $error';
  }

  @override
  String get failedToStartMicTest =>
      'Impossibile avviare il test del microfono.';

  @override
  String failedToSubmitReview(String error) {
    return 'Invio revisione non riuscito: $error';
  }

  @override
  String failedToUpload(String name, String error) {
    return 'Caricamento di $name non riuscito: $error';
  }

  @override
  String failedWithError(String error) {
    return 'Non riuscito: $error';
  }

  @override
  String get failure => 'Errore';

  @override
  String get feedAlreadyExists => 'Esiste già un feed con questo URL.';

  @override
  String get feedUrl => 'URL del feed';

  @override
  String get feedUrlExample => 'es: https://example.com/feed.xml';

  @override
  String get feedUrlExists => 'Esiste già un feed con questo URL.';

  @override
  String get feedUrlLabel => 'URL del feed';

  @override
  String feedsCount(int count) {
    return 'Feed ($count)';
  }

  @override
  String get feedsLabel => 'Feed';

  @override
  String get filesChanged => 'File modificati';

  @override
  String filesCount(int count) {
    return '$count file';
  }

  @override
  String get filesMentionSection => 'File';

  @override
  String get filterAgents => 'Filtra agenti...';

  @override
  String get filterAgentsPlaceholder => 'Filtra agenti…';

  @override
  String get filterFilesHint => 'Filtra file...';

  @override
  String get filterLists => 'Elenchi di filtri';

  @override
  String get filterSkillsPlaceholder => 'Filtra competenze…';

  @override
  String get finish => 'Fine';

  @override
  String get fix => 'Correggi';

  @override
  String get fixSelected => 'Correggi selezione';

  @override
  String get forward => 'Avanti';

  @override
  String get gatesGithubPatPush =>
      'Controlla l\'iniezione del PAT GitHub. Necessario affinché l\'agente possa eseguire il push.';

  @override
  String get general => 'Generale';

  @override
  String get generalSettingsDescription =>
      'Aspetto, tipografia, integrazioni e server MCP.';

  @override
  String get ghCliAuthButPatOverrideBody =>
      'GitHub CLI è autenticato e pronto, ma un token di accesso personale è impostato sotto e verrà usato al suo posto. Cancella il PAT per usare l\'autenticazione gh CLI.';

  @override
  String get ghCliInstalledAuth =>
      'Installato. Esegui `gh auth login`, poi tocca Aggiorna.';

  @override
  String get ghCliNotInstalled =>
      'gh CLI non installato — installa da cli.github.com.';

  @override
  String get ghCliNotInstalledLabel => 'gh CLI non installato';

  @override
  String get githubCli => 'GitHub CLI';

  @override
  String get githubCliIntegration => 'Integrazione GitHub CLI';

  @override
  String get githubCliReady => 'GitHub CLI è autenticato e pronto.';

  @override
  String get githubLink => 'Link GitHub';

  @override
  String get githubPersonalAccessToken => 'Token di accesso personale GitHub';

  @override
  String get claudeStatusFetchFailed =>
      'Impossibile raggiungere status.claude.com';

  @override
  String get claudeStatusOpenInBrowser => 'Apri status.claude.com';

  @override
  String get githubStatusFetchFailed =>
      'Impossibile raggiungere githubstatus.com';

  @override
  String get githubDegradedTitle => 'GitHub segnala problemi';

  @override
  String githubDegradedStatusLine(String status) {
    return 'Stato di GitHub: $status.';
  }

  @override
  String githubDegradedBody(String status) {
    return 'Stato di GitHub: $status. I dati delle pull request possono essere obsoleti o incompleti fino al ripristino.';
  }

  @override
  String get githubStatusOpenInBrowser => 'Apri githubstatus.com';

  @override
  String get githubStatusRefresh => 'Aggiorna';

  @override
  String githubStatusUpdated(String time) {
    return 'Aggiornato $time';
  }

  @override
  String get kimiStatusFetchFailed =>
      'Impossibile raggiungere status.moonshot.cn';

  @override
  String get kimiStatusOpenInBrowser => 'Apri status.moonshot.cn';

  @override
  String get openaiStatusFetchFailed =>
      'Impossibile raggiungere status.openai.com';

  @override
  String get openaiStatusOpenInBrowser => 'Apri status.openai.com';

  @override
  String get serviceStatusMaintenance => 'Manutenzione';

  @override
  String get serviceStatusMajorIssues => 'Problemi gravi';

  @override
  String get serviceStatusMinorIssues => 'Problemi minori';

  @override
  String get serviceStatusOperational => 'Operativo';

  @override
  String get serviceStatusOutage => 'Interruzione';

  @override
  String get serviceStatusTitle => 'Stato dei servizi';

  @override
  String get serviceStatusUnknown => 'Sconosciuto';

  @override
  String lastChecked(String time) {
    return 'Controllato $time';
  }

  @override
  String get lastCheckedRecently => 'Controllato di recente';

  @override
  String get githubToken => 'Token GitHub';

  @override
  String get giveYourWorkAHome => 'Dai una casa al tuo lavoro.';

  @override
  String get goBack => 'Torna indietro';

  @override
  String get goForward => 'Vai avanti';

  @override
  String get googleFonts => 'Google Fonts';

  @override
  String get hideContainerTerminal => 'Nascondi terminale contenitore';

  @override
  String get hideConversationChanges => 'Nascondi modifiche';

  @override
  String get showConversationChanges => 'Mostra modifiche';

  @override
  String get noConversationChanges =>
      'Nessuna modifica non confermata in questa conversazione.';

  @override
  String get conversationChangesTitle => 'Modifiche';

  @override
  String get high => 'Alto';

  @override
  String hoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ore fa',
      one: '1 ora fa',
    );
    return '$_temp0';
  }

  @override
  String get images => 'Immagini';

  @override
  String get inactive => 'Inattivo';

  @override
  String get install => 'Installa';

  @override
  String get installGhCliBody =>
      'Installa gh da https://cli.github.com/ ed esegui `gh auth login`, poi tocca Aggiorna.';

  @override
  String get installRequired => 'Installazione necessaria';

  @override
  String get installedNotSignedIn => 'Installato - non autenticato';

  @override
  String installedVersion(String version) {
    return 'Installato $version';
  }

  @override
  String get integrations => 'Integrazioni';

  @override
  String get invite => 'Invita';

  @override
  String get inviteAgent => 'Invita agente';

  @override
  String get isolateAgentExecution => 'Isola l\'esecuzione degli agenti.';

  @override
  String get justNow => 'adesso';

  @override
  String get keepSandboxing => 'Mantieni sandboxing';

  @override
  String get keybindingAdapters => 'Adattatori';

  @override
  String get keybindingAddARepositoryDescription => 'Aggiungi una repository';

  @override
  String get keybindingAddRepository => 'Aggiungi repository';

  @override
  String get keybindingAgents => 'Agenti';

  @override
  String get keybindingApprove => 'Approva';

  @override
  String get keybindingApproveThePeerReviewDescription =>
      'Approva la revisione tra pari';

  @override
  String get keybindingBookmarkOrUnbookmarkTheSelectedArticleDescription =>
      'Aggiungi o rimuovi segnalibro dell\'articolo selezionato';

  @override
  String get keybindingCommandPalette => 'Palette dei comandi';

  @override
  String get keybindingConversationTab => 'Scheda panoramica';

  @override
  String get keybindingCreateANewAgentDescription => 'Crea un nuovo agente';

  @override
  String get keybindingCreateANewWorkspaceDescription =>
      'Crea un nuovo spazio di lavoro';

  @override
  String get keybindingDeleteAgent => 'Elimina agente';

  @override
  String get keybindingDeleteChannel => 'Elimina canale';

  @override
  String get keybindingDeleteTheSelectedAgentDescription =>
      'Elimina l\'agente selezionato';

  @override
  String get keybindingDeleteTheSelectedChannelDescription =>
      'Elimina il canale selezionato';

  @override
  String get keybindingDeleteTheSelectedWorkspaceDescription =>
      'Elimina lo spazio di lavoro selezionato';

  @override
  String get keybindingDeleteWorkspace => 'Elimina spazio di lavoro';

  @override
  String get keybindingFilesChangedTab => 'Scheda diff';

  @override
  String get keybindingFocusSearch => 'Vai alla ricerca';

  @override
  String get keybindingFocusThePullRequestSearchFieldDescription =>
      'Attiva il campo di ricerca delle pull request';

  @override
  String get keybindingGeneral => 'Generale';

  @override
  String get keybindingGoToAgents => 'Vai agli agenti';

  @override
  String get keybindingGoToInbox => 'Vai alla posta in arrivo';

  @override
  String get keybindingGoToMemory => 'Vai alla memoria';

  @override
  String get keybindingGoToNewsfeed => 'Vai alle notizie';

  @override
  String get keybindingGoToPipelines => 'Vai alle pipeline';

  @override
  String get keybindingGoToPullRequests => 'Vai alle pull request';

  @override
  String get keybindingGoToTickets => 'Vai ai ticket';

  @override
  String get keybindingKeybindings => 'Tasti rapidi';

  @override
  String get keybindingNavigateToTheAgentsRegistryDescription =>
      'Naviga al registro degli agenti';

  @override
  String get keybindingNavigateToTheInboxDescription =>
      'Naviga alla posta in arrivo';

  @override
  String get keybindingNavigateToTheMemoryDescription =>
      'Vai alla base di conoscenza della memoria';

  @override
  String get keybindingNavigateToTheNewsfeedDescription =>
      'Naviga al feed di notizie';

  @override
  String get keybindingNavigateToThePipelinesListDescription =>
      'Vai all\'elenco delle pipeline';

  @override
  String get keybindingNavigateToThePullRequestListDescription =>
      'Naviga all\'elenco delle pull request';

  @override
  String get keybindingNavigateToTheTicketsBoardDescription =>
      'Vai alla bacheca dei ticket';

  @override
  String get keybindingNewAgent => 'Nuovo agente';

  @override
  String get keybindingNewWorkspace => 'Nuovo spazio di lavoro';

  @override
  String get keybindingNextArticle => 'Articolo successivo';

  @override
  String get keybindingNextChannel => 'Canale successivo';

  @override
  String get keybindingNextPr => 'PR successiva';

  @override
  String get keybindingNextWorkspace => 'Spazio di lavoro successivo';

  @override
  String get keybindingOpenArticle => 'Apri articolo';

  @override
  String
  get keybindingOpenOrCloseTheWorkspaceSwitcherPopupInTheSidebarDescription =>
      'Apri o chiudi il popup del selettore spazio nella barra laterale';

  @override
  String get keybindingOpenPr => 'Apri PR';

  @override
  String get keybindingOpenSettings => 'Apri impostazioni';

  @override
  String get keybindingOpenTheAdaptersSettingsPageDescription =>
      'Apri la pagina delle impostazioni degli adattatori';

  @override
  String get keybindingOpenTheAgentsSettingsPageDescription =>
      'Apri la pagina delle impostazioni degli agenti';

  @override
  String get keybindingOpenTheApplicationSettingsDescription =>
      'Apri le impostazioni dell\'applicazione';

  @override
  String get keybindingOpenTheCommandPaletteDescription =>
      'Apri la palette dei comandi';

  @override
  String get keybindingOpenTheGeneralSettingsPageDescription =>
      'Apri la pagina delle impostazioni generali';

  @override
  String get keybindingOpenTheKeybindingsSettingsPageDescription =>
      'Apri la pagina delle impostazioni dei tasti rapidi';

  @override
  String get keybindingOpenTheRepositoriesSettingsPageDescription =>
      'Apri la pagina delle impostazioni delle repository';

  @override
  String get keybindingOpenTheSelectedArticleDescription =>
      'Apri l\'articolo selezionato';

  @override
  String get keybindingOpenTheSelectedPullRequestDescription =>
      'Apri la pull request selezionata';

  @override
  String get keybindingOpenTheSelectedWorkspaceDescription =>
      'Apri lo spazio di lavoro selezionato';

  @override
  String get keybindingOpenTheSkillsSettingsPageDescription =>
      'Apri la pagina delle impostazioni delle competenze';

  @override
  String get keybindingOpenWorkspace => 'Apri spazio di lavoro';

  @override
  String get keybindingPreviousArticle => 'Articolo precedente';

  @override
  String get keybindingPreviousChannel => 'Canale precedente';

  @override
  String get keybindingPreviousPr => 'PR precedente';

  @override
  String get keybindingPreviousWorkspace => 'Spazio di lavoro precedente';

  @override
  String get keybindingRefresh => 'Aggiorna';

  @override
  String get keybindingRefreshAllFeedsDescription => 'Aggiorna tutti i feed';

  @override
  String get keybindingRefreshThePullRequestListDescription =>
      'Aggiorna l\'elenco delle pull request';

  @override
  String get keybindingRemoveRepository => 'Rimuovi repository';

  @override
  String get keybindingRemoveTheSelectedRepositoryDescription =>
      'Rimuovi la repository selezionata';

  @override
  String get keybindingRepositories => 'Repository';

  @override
  String get keybindingRequestChanges => 'Richiedi modifiche';

  @override
  String get keybindingRequestChangesOnThePeerReviewDescription =>
      'Richiedi modifiche sulla revisione tra pari';

  @override
  String get keybindingRescanForAdaptersDescription =>
      'Riscansiona gli adattatori';

  @override
  String get keybindingSearchInDiff => 'Cerca nel diff';

  @override
  String get keybindingSearchWithinTheDiffViewDescription =>
      'Cerca nella vista del diff';

  @override
  String get keybindingToggleViewed => 'Attiva/disattiva visto';

  @override
  String get keybindingMarkTheFocusedFileAsViewedOrUnviewedDescription =>
      'Segna il file focalizzato come visto o non visto';

  @override
  String get keybindingToggleCollapse => 'Attiva/disattiva comprimi';

  @override
  String get keybindingShowFileList => 'Mostra elenco file';

  @override
  String get keybindingShowFileListDescription =>
      'Riporta la barra laterale del diff all\'albero dei file';

  @override
  String get keybindingCollapseOrExpandTheFocusedFileDescription =>
      'Comprimi o espandi il file focalizzato';

  @override
  String get keybindingSelectTheNextArticleDescription =>
      'Seleziona l\'articolo successivo';

  @override
  String get keybindingSelectTheNextChannelDescription =>
      'Seleziona il canale successivo';

  @override
  String get keybindingSelectTheNextPullRequestDescription =>
      'Seleziona la pull request successiva';

  @override
  String get keybindingSelectThePreviousArticleDescription =>
      'Seleziona l\'articolo precedente';

  @override
  String get keybindingSelectThePreviousChannelDescription =>
      'Seleziona il canale precedente';

  @override
  String get keybindingSelectThePreviousPullRequestDescription =>
      'Seleziona la pull request precedente';

  @override
  String get keybindingSendMessage => 'Invia messaggio';

  @override
  String get keybindingSendTheCurrentMessageDescription =>
      'Invia il messaggio attuale';

  @override
  String get keybindingSkills => 'Competenze';

  @override
  String get keybindingSwitchBetweenLightAndDarkModeDescription =>
      'Cambia tra modalità chiara e scura';

  @override
  String get keybindingSwitchToTheConversationTabDescription =>
      'Passa alla scheda panoramica';

  @override
  String get keybindingSwitchToTheEighthWorkspaceDescription =>
      'Passa all\'ottavo spazio di lavoro';

  @override
  String get keybindingSwitchToTheFifthWorkspaceDescription =>
      'Passa al quinto spazio di lavoro';

  @override
  String get keybindingSwitchToTheFilesChangedTabDescription =>
      'Passa alla scheda diff';

  @override
  String get keybindingSwitchToTheFirstWorkspaceDescription =>
      'Passa al primo spazio di lavoro';

  @override
  String get keybindingSwitchToTheFourthWorkspaceDescription =>
      'Passa al quarto spazio di lavoro';

  @override
  String get keybindingSwitchToTheNextWorkspaceDescription =>
      'Passa allo spazio di lavoro successivo';

  @override
  String get keybindingSwitchToTheNinthWorkspaceDescription =>
      'Passa al nono spazio di lavoro';

  @override
  String get keybindingSwitchToThePreviousWorkspaceDescription =>
      'Passa allo spazio di lavoro precedente';

  @override
  String get keybindingSwitchToTheSecondWorkspaceDescription =>
      'Passa al secondo spazio di lavoro';

  @override
  String get keybindingSwitchToTheSeventhWorkspaceDescription =>
      'Passa al settimo spazio di lavoro';

  @override
  String get keybindingSwitchToTheSixthWorkspaceDescription =>
      'Passa al sesto spazio di lavoro';

  @override
  String get keybindingSwitchToTheThirdWorkspaceDescription =>
      'Passa al terzo spazio di lavoro';

  @override
  String get keybindingToggleBookmark => 'Aggiungi/rimuovi segnalibro';

  @override
  String get keybindingToggleTheme => 'Cambia tema';

  @override
  String get keybindingToggleWorkspaceSwitcher => 'Cambia selettore spazio';

  @override
  String get keybindingWorkspace1 => 'Workspace1';

  @override
  String get keybindingWorkspace2 => 'Workspace2';

  @override
  String get keybindingWorkspace3 => 'Workspace3';

  @override
  String get keybindingWorkspace4 => 'Workspace4';

  @override
  String get keybindingWorkspace5 => 'Workspace5';

  @override
  String get keybindingWorkspace6 => 'Workspace6';

  @override
  String get keybindingWorkspace7 => 'Workspace7';

  @override
  String get keybindingWorkspace8 => 'Workspace8';

  @override
  String get keybindingWorkspace9 => 'Workspace9';

  @override
  String get keybindings => 'Tasti rapidi';

  @override
  String get keybindingsDescription =>
      'Tutti i tasti rapidi. I tasti rapidi sono fissi e non possono essere riassegnati.';

  @override
  String get killRunning => 'Termina in esecuzione';

  @override
  String get klipyNotConfigured => 'KLIPY_APP_KEY non configurata';

  @override
  String get klipyNotConfiguredHint =>
      'Passa --dart-define=KLIPY_APP_KEY=...\no impostala nel .env prima di eseguire.';

  @override
  String get languageDutch => 'Nederlands';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageFrench => 'Français';

  @override
  String get languageGerman => 'Deutsch';

  @override
  String get languageItalian => 'Italiano';

  @override
  String get languagePortuguese => 'Português';

  @override
  String get languageSpanish => 'Español';

  @override
  String get languageSystem => 'Sistema';

  @override
  String get latestLabel => 'Più recenti';

  @override
  String get leaveACommentEllipsis => 'Lascia un commento...';

  @override
  String get legendLabel => 'Legenda';

  @override
  String get lessLabel => 'Meno';

  @override
  String get letsPluginTools => 'Colleghiamo i tuoi strumenti.';

  @override
  String get level => 'Livello';

  @override
  String get loadingAgents => 'Caricamento agenti…';

  @override
  String get loadingModels => 'Caricamento modelli…';

  @override
  String get loadingProviders => 'Caricamento provider…';

  @override
  String get logLevel => 'Livello di registro';

  @override
  String get logs => 'Log';

  @override
  String get low => 'Basso';

  @override
  String get maintenance => 'Manutenzione';

  @override
  String get manageParticipants => 'Gestisci partecipanti';

  @override
  String get createTicketFromConversation => 'Crea ticket dalla conversazione';

  @override
  String get manageWorkspaces => 'Gestisci spazi di lavoro';

  @override
  String get reorderWorkspace => 'Riordina spazio di lavoro';

  @override
  String get masterToggle => 'Interruttore principale';

  @override
  String get matchOsAppearance =>
      'Adatta l\'aspetto al sistema operativo o scegli una modalità fissa.';

  @override
  String get mcpActiveAccepting =>
      'Il server MCP è attivo e accetta connessioni.';

  @override
  String get mcpAuthToken => 'Token di autenticazione MCP';

  @override
  String get mcpAuthentication => 'Autenticazione';

  @override
  String get mcpAutoStartDescription =>
      'Se disattivato, il server rimane fermato finché non lo avvii.';

  @override
  String mcpDefaultPort(int port) {
    return 'Predefinito: $port';
  }

  @override
  String mcpListeningOn(int port) {
    return 'In ascolto su 127.0.0.1:$port';
  }

  @override
  String mcpListeningOnPort(int port) {
    return 'In ascolto sulla porta $port, condivisa con cc_server.';
  }

  @override
  String get mcpNotAvailableOnServer =>
      'Il controllo del server MCP non è disponibile sul server connesso.';

  @override
  String get modelManagedOnServer =>
      'Questo modello viene eseguito sull\'host del server ed è gestito lì.';

  @override
  String get mcpNotRunning =>
      'Il server non è in esecuzione. Avvialo per abilitare le connessioni MCP.';

  @override
  String get mcpRestartPortChanges =>
      'Il server deve essere riavviato per applicare le modifiche alla porta.';

  @override
  String get mcpServer => 'Server MCP';

  @override
  String get mcpServerStopped => 'Il server è fermato';

  @override
  String get mcpStatus => 'Stato';

  @override
  String get medium => 'Medio';

  @override
  String get memoryDataHint =>
      'Fatti e politiche appariranno qui man mano che gli agenti lavorano.';

  @override
  String get memoryLabel => 'MEMORIA';

  @override
  String get merge => 'Merge';

  @override
  String get merged => 'Unita';

  @override
  String get messagePlaceholder =>
      'Messaggio… (@ per menzionare, / per comandi)';

  @override
  String get navConversations => 'Canali';

  @override
  String get microphonePermissionDenied => 'Permesso del microfono negato.';

  @override
  String minutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minuti fa',
      one: '1 minuto fa',
    );
    return '$_temp0';
  }

  @override
  String get modelLabel => 'Modello';

  @override
  String get modified => 'Modificato';

  @override
  String monthsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mesi fa',
      one: '1 mese fa',
    );
    return '$_temp0';
  }

  @override
  String get more => 'Altro';

  @override
  String get moreLabel => 'Altro';

  @override
  String get mozillaUserAgent => 'Mozilla/5.0 …';

  @override
  String get name => 'Nome';

  @override
  String get nameAndTitleRequired => 'Nome e titolo sono obbligatori.';

  @override
  String get nameAndUrlRequired => 'Nome e URL sono obbligatori';

  @override
  String get nameLabel => 'Nome';

  @override
  String nativeSandboxAvailable(String platform) {
    return 'Sandbox nativo disponibile su $platform.';
  }

  @override
  String get nativeSandboxNeedsInstall =>
      'Installazione necessaria per sandbox nativo';

  @override
  String get navObservability => 'Osservabilità';

  @override
  String get navSaved => 'Salvati';

  @override
  String get navSettings => 'Impostazioni';

  @override
  String get navigateLabel => 'Naviga';

  @override
  String networkBlockCount(int count) {
    return '$count blocchi di rete';
  }

  @override
  String get neutral => 'Neutrale';

  @override
  String get newAgent => 'Nuovo agente';

  @override
  String get newCommitsPushed =>
      'Nuovi commit sono stati caricati — clicca per ricaricare il diff';

  @override
  String get newFact => 'Nuovo fatto';

  @override
  String get newLabel => 'Nuovo';

  @override
  String get newPolicy => 'Nuova politica';

  @override
  String get newsfeed => 'Notizie';

  @override
  String get newsfeedLabel => 'Notizie';

  @override
  String get newsfeedSettingsDescription =>
      'Gestisci i feed a cui sei iscritto e le preferenze del lettore.';

  @override
  String get newsfeedSettingsTitle => 'Impostazioni notizie';

  @override
  String get nextMatch => 'Corrispondenza successiva (↵)';

  @override
  String get noAccessGrants => 'Nessuna autorizzazione di accesso configurata';

  @override
  String get noActiveWorkspace =>
      'Nessuno spazio di lavoro o repository attivo selezionato.';

  @override
  String get noActiveWorkspaceCreate => 'Nessuno spazio di lavoro attivo';

  @override
  String get noActiveWorkspaceGithub =>
      'Nessuno spazio di lavoro attivo con una repository GitHub.';

  @override
  String get noAgentAssigned => 'Nessun agente assegnato';

  @override
  String get noAgentProcessesRunning => 'Nessun processo agente in esecuzione';

  @override
  String get noAgents => 'Nessun agente';

  @override
  String get noAgentsDiscovered => 'Nessun agente scoperto';

  @override
  String get noAgentsDiscoveredHint =>
      'Clicca \"Scopri\" per cercare file AGENTS.md o \"Aggiungi agente\" per configurarne uno manualmente';

  @override
  String get noAgentsRegisteredYet => 'Nessun agente registrato ancora';

  @override
  String get noArticlesYet => 'Ancora nessun articolo';

  @override
  String get noArticlesYetBody => 'Gli articoli dei tuoi feed appariranno qui.';

  @override
  String get noData => 'Nessun dato';

  @override
  String get noDomains => 'Ancora nessun dominio';

  @override
  String get noExecutionLogsYet => 'Ancora nessun registro di esecuzione';

  @override
  String get noFacts => 'Ancora nessun fatto';

  @override
  String get noFeedsYet => 'Ancora nessun feed';

  @override
  String get noFileAnchor =>
      'Nessun ancoraggio al file — impossibile pubblicare un commento in linea.';

  @override
  String get noFileChangesInScope =>
      'Nessuna modifica del file in questa portata';

  @override
  String get noGifsFound => 'Nessuna GIF trovata';

  @override
  String get noInputDevicesDetected =>
      'Nessun dispositivo di ingresso rilevato — utilizzo del predefinito di sistema.';

  @override
  String get noMatchingFiles => 'Nessun file corrispondente';

  @override
  String get noMatchingGoogleFonts => 'Nessun Google Fonts corrispondente.';

  @override
  String get noMemoryData => 'Ancora nessun dato di memoria';

  @override
  String get noMessagesYet => 'Nessun messaggio ancora';

  @override
  String get noModelsAdvertised =>
      'Nessun modello pubblicizzato da questo adattatore.';

  @override
  String get noOpenPullRequests => 'Nessuna pull request aperta';

  @override
  String get noPolicies => 'Ancora nessuna politica';

  @override
  String get noReposInWorkspaceYet =>
      'Ancora nessuna repository in questo spazio di lavoro';

  @override
  String get noRunnersDetected =>
      'Nessun runner rilevato. Aggiorna per scansionare di nuovo.';

  @override
  String get noSavedArticles => 'Ancora nessun articolo salvato';

  @override
  String get noSavedArticlesBody =>
      'Gli articoli che salverai appariranno qui.';

  @override
  String noShortcutsMatch(String query) {
    return 'Nessun tasto rapido corrisponde a \"$query\"';
  }

  @override
  String get noSystemFonts => 'Nessun font di sistema rilevato.';

  @override
  String get noTokenSet => 'Nessun token impostato — l\'accesso è illimitato.';

  @override
  String get noTokenSetUnrestricted =>
      'Nessun token impostato — l\'accesso è senza restrizioni.';

  @override
  String get noTokenUnrestricted =>
      'Nessun token — l\'accesso è senza restrizioni';

  @override
  String get noWorkingMemory => 'Ancora nessuna nota di memoria di lavoro.';

  @override
  String get noneAllRoles => 'Nessuno (tutti i ruoli)';

  @override
  String get notAvailable => 'Non disponibile';

  @override
  String get notConfiguredLabel => 'Non configurato.';

  @override
  String get notDetected => 'Non rilevato';

  @override
  String get notFoundLabel => 'Non trovato';

  @override
  String get notes => 'Note';

  @override
  String get notificationAgentFinished => 'Agente completato';

  @override
  String get notificationPrMentioned => 'Menzionato in una pull request';

  @override
  String get notificationNewMessages => 'Nuovi messaggi';

  @override
  String get notificationPrMerged => 'PR unita';

  @override
  String get notificationPrPublished => 'PR pubblicata';

  @override
  String get notificationReviewRequested => 'Revisione richiesta';

  @override
  String get notifications => 'Notifiche';

  @override
  String get notifyAgentRunCompleted =>
      'Notifica quando un agente completa un\'esecuzione.';

  @override
  String get notifyPrMentioned =>
      'Notifica quando vieni menzionato in una pull request.';

  @override
  String get notifyNewMessages =>
      'Notifica per nuovi messaggi degli agenti in altri canali.';

  @override
  String get notifyPrMerged => 'Notifica quando una pull request viene unita.';

  @override
  String get notifyPrPublished =>
      'Notifica quando un agente pubblica una pull request.';

  @override
  String get notifyReviewRequested =>
      'Notifica quando viene richiesta la tua revisione su una pull request.';

  @override
  String get onboardingLinuxDescription =>
      'Control Center può utilizzare container Linux per isolare l\'esecuzione degli agenti.';

  @override
  String get onboardingMacosDescription =>
      'Control Center utilizza il sandbox nativo su macOS per isolare l\'esecuzione degli agenti.';

  @override
  String get onboardingUnsupportedDescription =>
      'Sandbox non disponibile su questa piattaforma. L\'esecuzione degli agenti avverrà senza isolamento.';

  @override
  String get openApplicationSettings => 'Apri impostazioni applicazione';

  @override
  String get openArticlesBrowserFallback => 'Apri articolo nel browser';

  @override
  String get openArticlesInApp => 'Apri articoli nell\'app';

  @override
  String get openContainerTerminal => 'Apri terminale contenitore';

  @override
  String get openFolder => 'Apri cartella';

  @override
  String get openInBrowser => 'Apri nel browser';

  @override
  String get openLabel => 'Aperta';

  @override
  String get openOnGithub => 'Apri su GitHub';

  @override
  String get openStatus => 'Aperta';

  @override
  String get optionalPersonaDescription =>
      'Descrizione opzionale della persona';

  @override
  String get otherLabel => 'Altro';

  @override
  String get ownerOrganization => 'Proprietario / Organizzazione';

  @override
  String get p0 => 'P0';

  @override
  String get p1 => 'P1';

  @override
  String get p2 => 'P2';

  @override
  String get p3 => 'P3';

  @override
  String get parsingDiff => 'Analisi del diff…';

  @override
  String get passed => 'Superato';

  @override
  String get pasteTokenHere => 'Incolla il token qui';

  @override
  String get pasteValueHere => 'Incolla il valore qui';

  @override
  String get patNotNeededGhCli => 'Non necessario — gh CLI è autenticato.';

  @override
  String get patOverridesGhCli => 'Configurato — sovrascrive gh CLI.';

  @override
  String get pathLabel => 'Percorso';

  @override
  String get pendingApproval => 'In attesa della tua approvazione';

  @override
  String get persona => 'Persona';

  @override
  String get personaColon => 'Persona:';

  @override
  String get personaOptional => 'Persona (opzionale)';

  @override
  String get personalAccessTokenOptional =>
      'Token di accesso personale (opzionale)';

  @override
  String get planLabel => 'Piano';

  @override
  String get policies => 'Regole';

  @override
  String get policiesHint =>
      'Le politiche appariranno qui una volta che gli agenti promuoveranno fatti.';

  @override
  String get policy => 'Regola';

  @override
  String get popular => 'Popolari';

  @override
  String get port => 'Porta';

  @override
  String get postingEllipsis => 'Pubblicazione...';

  @override
  String get prCommits => 'Commit';

  @override
  String get prDescriptionPlaceholder => 'Descrizione della PR in markdown...';

  @override
  String get prDraftCreated => 'Bozza di PR creata';

  @override
  String get prMergedBody => 'Una pull request è stata unita';

  @override
  String get prMoreActions => 'More actions';

  @override
  String get prTitle => 'Titolo della PR';

  @override
  String get previewLabel => 'Anteprima';

  @override
  String get previousArticle => 'Articolo precedente';

  @override
  String get previousChannel => 'Canale precedente';

  @override
  String get previousMatch => 'Corrispondenza precedente (⇧↵)';

  @override
  String get previousPr => 'PR precedente';

  @override
  String get previousWorkspace => 'Spazio precedente';

  @override
  String get priorityReviewsDescription =>
      'Revisioni prioritarie e panoramica delle repository.';

  @override
  String get proposeToCreateDomain =>
      'Proponi un fatto o una politica per crearne uno.';

  @override
  String get prsCreated => 'PR create';

  @override
  String get prsMerged => 'PR unite';

  @override
  String get publishToGithub => 'Pubblica su GitHub';

  @override
  String get published => 'Pubblicato';

  @override
  String get pullRequestApproved => 'Pull request approvata';

  @override
  String get pullRequests => 'Pull request';

  @override
  String get questionLabel => 'DOMANDA';

  @override
  String get queued => 'In coda';

  @override
  String get react => 'Reagisci';

  @override
  String get readPrsIssuesMetadata =>
      'Permette all\'agente di leggere PR, issue e metadati della repository.';

  @override
  String get readerPreferences => 'Preferenze lettore';

  @override
  String get reasoningEffort => 'Sforzo di ragionamento';

  @override
  String get recommendLabel => 'RACCOMANDAZIONE';

  @override
  String recordingFromDevice(String device) {
    return 'Registrazione da $device.';
  }

  @override
  String get redownload => 'Scarica di nuovo';

  @override
  String get redownloadEmbeddingModel =>
      'Scaricare di nuovo il modello di embedding?';

  @override
  String get redownloadVoiceModel => 'Scaricare di nuovo il modello vocale?';

  @override
  String get refinePlan => 'Affina il piano';

  @override
  String get refiningPlan => 'Affinamento del piano…';

  @override
  String get refresh => 'Aggiorna';

  @override
  String get refreshAll => 'Aggiorna tutto';

  @override
  String get refreshAllFeeds => 'Aggiorna tutti i feed';

  @override
  String get refreshLabel => 'Aggiorna';

  @override
  String get refreshPrData => 'Aggiorna dati della PR';

  @override
  String get reject => 'Rifiuta';

  @override
  String get rejected => 'Rifiutato';

  @override
  String get reload => 'Ricarica';

  @override
  String get remove => 'Rimuovi';

  @override
  String get removeBookmark => 'Rimuovi segnalibro';

  @override
  String get removeEmbeddingModel => 'Rimuovere il modello di embedding?';

  @override
  String get removeLogo => 'Rimuovi logo';

  @override
  String get removeRepoFromWorkspace =>
      'Rimuovere la repository dallo spazio di lavoro?';

  @override
  String get removeRepository => 'Rimuovi repository';

  @override
  String get removeRepositoryConfirm =>
      'Rimuovere il repository dallo spazio di lavoro?';

  @override
  String get removeVoiceModel => 'Rimuovere il modello vocale?';

  @override
  String get removed => 'Rimosso';

  @override
  String get renamed => 'Rinominato';

  @override
  String get reopen => 'Riapri';

  @override
  String get resolve => 'Risolvi';

  @override
  String get replyEllipsis => 'Rispondi…';

  @override
  String repoRemovedFromWorkspace(String name) {
    return '$name sarà rimosso da questo spazio di lavoro. I file locali su disco non saranno modificati.';
  }

  @override
  String get reportsTo => 'Riferisce a';

  @override
  String get reportsToOptional => 'Riferisce a (opzionale)';

  @override
  String reposCount(int count) {
    return 'Repository ($count)';
  }

  @override
  String get reposDescription =>
      'I checkout locali a cui fa riferimento questo spazio di lavoro.';

  @override
  String get repositories => 'Repository';

  @override
  String repositoriesAddFailed(int count, String error) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# repository',
      one: '1 repository',
    );
    return 'Impossibile aggiungere $_temp0: $error';
  }

  @override
  String repositoriesAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# repository aggiunti',
      one: 'Repository aggiunto',
    );
    return '$_temp0';
  }

  @override
  String get repositoriesSettings => 'Impostazioni repository';

  @override
  String get repositoryName => 'Nome della repository';

  @override
  String get requestChanges => 'Richiedi modifiche';

  @override
  String get requested => 'Richiesto';

  @override
  String get requestedChanges => 'Modifiche richieste';

  @override
  String get requiredIfGhCliUnavailable =>
      'Richiesto se gh CLI non è disponibile';

  @override
  String requiredRoleLabel(String role) {
    return 'Ruolo richiesto: $role';
  }

  @override
  String get requiredRoleOptional => 'Ruolo richiesto (opzionale)';

  @override
  String get requirements => 'Requisiti';

  @override
  String get reset => 'Ripristina';

  @override
  String get resetAllSandboxes => 'Ripristina tutti i sandbox';

  @override
  String get resolved => 'Risolto';

  @override
  String get restartServerToApply =>
      'Riavvia il server per applicare le modifiche.';

  @override
  String get enclosedTerminalTitle => 'Terminale isolato';

  @override
  String get enclosedTerminalStart => 'Apri la shell';

  @override
  String get enclosedTerminalStartHint =>
      'Questa shell viene eseguita nella VM usa e getta di questa conversazione. Si avvia quando la apri, non all’avvio dell’app.';

  @override
  String get terminalStreamReconnecting => 'flusso interrotto — riconnessione…';

  @override
  String get terminalStreamError => 'errore di flusso:';

  @override
  String get terminalShellExited => 'shell terminata';

  @override
  String get restartShell => 'Riavvia shell';

  @override
  String get retry => 'Riprova';

  @override
  String get review => 'Revisione';

  @override
  String get reviewChanges => 'Rivedi le modifiche';

  @override
  String get reviewedByMe => 'Revisionate da me';

  @override
  String get reviewers => 'REVISORI';

  @override
  String get reviewersActive => 'Revisori attivi';

  @override
  String get roleLabel => 'Ruolo';

  @override
  String get ruleHint => 'La regola della politica (markdown supportato)';

  @override
  String get ruleLabel => 'Regola';

  @override
  String get runCompleted => 'Esecuzione completata';

  @override
  String get runGhAuthLoginBody =>
      'Esegui `gh auth login` nel tuo terminale e poi tocca Aggiorna.';

  @override
  String get running => 'In esecuzione';

  @override
  String get runningLabel => 'in esecuzione';

  @override
  String get runs => 'Esecuzioni';

  @override
  String get runsLabel => 'Esecuzioni';

  @override
  String get sandboxBackendNativeLabel => 'Native sandbox';

  @override
  String get sandboxBackendMicrovmLabel => 'VM isolata';

  @override
  String get sandboxBackendNoneLabel => 'No isolation';

  @override
  String get sandboxLinuxInstall =>
      'Il sandbox nativo su Linux/WSL2 utilizza bubblewrap. Installa con:\\n\\n  sudo apt-get install bubblewrap socat ripgrep   # Debian/Ubuntu\\n  sudo dnf install bubblewrap socat ripgrep       # Fedora/RHEL\\n  sudo pacman -S bubblewrap socat ripgrep         # Arch';

  @override
  String get sandboxMacosBuiltIn =>
      'Il sandbox nativo è integrato in macOS — utilizza Apple Seatbelt (`sandbox-exec`). Nessuna installazione richiesta.';

  @override
  String get sandboxPermissions => 'Permessi del sandbox';

  @override
  String get sandboxUnsupported =>
      'Il sandbox nativo non è ancora supportato su questa piattaforma. Torna a \"Nessun isolamento\".';

  @override
  String get sandboxing => 'Sandboxing';

  @override
  String get sandboxingDescription =>
      'Esegui gli agenti all\'interno di un sandbox a livello di sistema operativo in modo che non possano toccare la tua cartella home, chiavi SSH o token che non hai concesso.';

  @override
  String get sandboxingDisabledDescription =>
      'Gli agenti vengono eseguiti direttamente sull\'host con ambiente completo — non consigliato.';

  @override
  String sandboxingEnabledDescription(String backend) {
    return 'Tutte le invocazioni degli agenti vengono instradate attraverso $backend.';
  }

  @override
  String get save => 'Salva';

  @override
  String get saveChanges => 'Salva modifiche';

  @override
  String get adapterArguments => 'Argomenti aggiuntivi';

  @override
  String get adapterArgumentsHint => 'Flag CLI aggiuntivi (es. --yolo)';

  @override
  String get addVariable => 'Aggiungi variabile';

  @override
  String get environmentVariables => 'Variabili d\'ambiente';

  @override
  String get environmentVariablesDescription =>
      'Variabili d\'ambiente personalizzate passate a questo adattatore (es. chiavi API). Salvate nel portachiavi.';

  @override
  String get resetToDefault => 'Ripristina predefinito';

  @override
  String get variableKey => 'Chiave';

  @override
  String get variableValue => 'Valore';

  @override
  String get savedArticlesDescription =>
      'Articoli che hai salvato nei segnalibri.';

  @override
  String get savedLabel => 'Salvati';

  @override
  String get savingChanges => 'Salvataggio modifiche in corso...';

  @override
  String get savingEllipsis => 'Salvataggio…';

  @override
  String get scopeDiffToCommits =>
      'Filtra diff per commit — Maiusc-clic per un intervallo';

  @override
  String get searchAgents => 'Cerca agenti';

  @override
  String get searchAuthors => 'Cerca autori…';

  @override
  String get searchPullRequestsHint => 'Cerca… es. author:@user';

  @override
  String get noPrsMatchSearch => 'Nessuna pull request corrispondente';

  @override
  String get noPrsMatchSearchHint =>
      'Nessuna PR aperta corrisponde alla ricerca. Prova altri termini o cancella la ricerca.';

  @override
  String get searchAuthorsPlaceholder => 'Cerca autori…';

  @override
  String get searchFactsHint => 'Cerca fatti...';

  @override
  String get searchFonts => 'Cerca font…';

  @override
  String get searchGifs => 'Cerca GIF';

  @override
  String get searchGifsHint => 'Cerca GIF...';

  @override
  String get searchInDiff => 'Cerca nel diff';

  @override
  String get searchInDiffHint => 'Cerca nel diff...';

  @override
  String get searchOrTypeModel => 'Cerca o digita il nome di un modello…';

  @override
  String get searchPlaceholder => 'Cerca...';

  @override
  String get searchShortcuts => 'Cerca tasti rapidi…';

  @override
  String get shortcutUnavailableInBrowser => 'Non disponibile nel browser';

  @override
  String get searching => 'Ricerca in corso...';

  @override
  String secondsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count secondi fa',
      one: '1 secondo fa',
    );
    return '$_temp0';
  }

  @override
  String get selectAdapter => 'Seleziona adattatore';

  @override
  String get selectAdapterFirst => 'Seleziona prima un adattatore';

  @override
  String get selectAgentToReportTo => 'Seleziona l\'agente a cui riferire…';

  @override
  String get selectAnAgent => 'Seleziona un agente';

  @override
  String get selectConversation => 'Seleziona una conversazione';

  @override
  String get selectEffortLevel => 'Seleziona il livello di impegno';

  @override
  String get selectLabel => 'Seleziona';

  @override
  String get selectRunner => 'Seleziona un runner';

  @override
  String get semanticSearch => 'Ricerca semantica';

  @override
  String get send => 'Invia';

  @override
  String get sendFirstMessage => 'Invia il primo messaggio';

  @override
  String get sendMessage => 'Invia messaggio';

  @override
  String sentFindingsToAgent(int count) {
    return 'Inviati $count riscontri all\'agente.';
  }

  @override
  String get serverRunning => 'Server in esecuzione';

  @override
  String get serverStopped => 'Server fermato';

  @override
  String setGithubLinkDescription(String name) {
    return 'Imposta il proprietario GitHub e il nome della repository per $name. Questo viene usato per risolvere riferimenti a PR e issue come #123 nei contenuti markdown.';
  }

  @override
  String get setLabel => 'Imposta';

  @override
  String get setToken => 'Imposta token';

  @override
  String get settingsGeneralDescription =>
      'Aspetto, tipografia, integrazioni e server MCP.';

  @override
  String get settingsLabel => 'Impostazioni';

  @override
  String get settingsLanguage => 'Lingua';

  @override
  String get settingsLanguageDescription => 'Scegli la lingua dell\'app.';

  @override
  String get sharedSecretToken => 'Token segreto condiviso';

  @override
  String get shortTask => 'Attività breve';

  @override
  String get showNativeNotifications =>
      'Mostra notifiche native macOS per gli eventi.';

  @override
  String get showSuperseded => 'Mostra sostituiti';

  @override
  String get signInWithGhAuth =>
      'Accedi con gh auth login o aggiungi un token in Impostazioni > Chiavi API';

  @override
  String get signedIn => 'Autenticato.';

  @override
  String signedInAs(String username) {
    return 'Autenticato come $username.';
  }

  @override
  String get skillEditor => 'Editor competenze';

  @override
  String get skillNameRequired => 'Il nome della competenza è obbligatorio.';

  @override
  String skillSaved(String name) {
    return 'Competenza \"$name\" salvata.';
  }

  @override
  String get skillBrowseDisclaimer =>
      'Il registro skills.sh non è attendibile. Autore, numero di installazioni e badge di editore verificato sono solo elementi di provenienza — il verdetto della scansione sottostante è il vero segnale di sicurezza.';

  @override
  String get skillBrowseNoResults =>
      'Nessuna competenza corrisponde alla tua ricerca.';

  @override
  String get skillBrowsePrompt =>
      'Cerca nel registro skills.sh per installare una competenza.';

  @override
  String get skillBrowseSearchHint => 'Cerca in skills.sh…';

  @override
  String get skillFindingLine => 'riga';

  @override
  String get skillInstallAnywayOverride =>
      'Accetto il rischio — installa comunque';

  @override
  String skillInstallCount(int count) {
    return '$count installazioni';
  }

  @override
  String skillInstalled(String slug) {
    return 'Competenza «$slug» installata.';
  }

  @override
  String get skillPreviewCapabilities => 'Capacità';

  @override
  String get skillPreviewFindings => 'Riscontri';

  @override
  String get skillPreviewGuardedActions => 'Azioni protette';

  @override
  String get skillPreviewLlmReviewed => 'Revisionato da LLM';

  @override
  String get skillPreviewNoCapabilities => 'Nessuna capacità dichiarata.';

  @override
  String get skillPreviewNoFindings => 'Nessun riscontro.';

  @override
  String get skillPreviewScanning => 'Scansione della competenza…';

  @override
  String get skillPreviewVerdictLabel => 'Verdetto della scansione';

  @override
  String get skillPreviewVerdictPass => 'Superato';

  @override
  String get skillPreviewVerdictQuarantine => 'In quarantena';

  @override
  String get skillPreviewVerdictWarn => 'Avviso';

  @override
  String get skillQuarantineWarning =>
      'Questa competenza è stata messa in quarantena dallo scanner. L\'installazione esegue codice sul tuo computer. Procedi solo se ti fidi della fonte e hai esaminato i riscontri.';

  @override
  String skillDetachedFromAgents(String agents) {
    return 'In quarantena e scollegato dagli agenti: $agents';
  }

  @override
  String get skillNotScanned => 'Non analizzato';

  @override
  String get skillOriginGithub => 'GitHub';

  @override
  String get skillOriginManual => 'Manuale';

  @override
  String get skillOriginRegistry => 'Registro';

  @override
  String get skillOriginRuntimeLocal => 'Runtime locale';

  @override
  String get skillRulesStale => 'Analisi non aggiornata';

  @override
  String get skillSaveAnywayOverride => 'Comprendo il rischio — salva comunque';

  @override
  String get skillSaveBlockedBody =>
      'Il contenuto è stato bloccato prima di scrivere qualsiasi cosa.';

  @override
  String get skillSaveBlockedTitle => 'Salvataggio bloccato dall\'analisi';

  @override
  String get skillScanAction => 'Analizza';

  @override
  String get skillScanAll => 'Analizza tutto';

  @override
  String skillScanAllSummary(int pass, int warn, int quarantine) {
    return '$pass superati · $warn avvisi · $quarantine in quarantena';
  }

  @override
  String get skillStateDrifted => 'Modificato dopo l\'installazione';

  @override
  String get skillStateUnmanaged => 'Non gestito';

  @override
  String get skillSeverityBlocked => 'Bloccato';

  @override
  String get skillSeverityWarn => 'Avviso';

  @override
  String get skillVerifiedPublisher => 'Editore verificato';

  @override
  String get skillsBrowseTab => 'Esplora';

  @override
  String get skillsInstalledTab => 'Installate';

  @override
  String get skills => 'Competenze';

  @override
  String get skillsColon => 'Competenze:';

  @override
  String get skillsCommaSeparated => 'Competenze (separate da virgola)';

  @override
  String get skillsLabel => 'COMPETENZE';

  @override
  String get skipAcceptRisk => 'Salta — Accetto il rischio';

  @override
  String get skipForNow => 'Salta per ora';

  @override
  String get skipSandboxing => 'Salta sandboxing';

  @override
  String get skipSandboxingDialogContent =>
      'Sei sicuro di voler saltare il sandbox? Questo permette agli agenti di eseguire codice sul tuo sistema senza isolamento.';

  @override
  String get somethingWentWrong => 'Qualcosa è andato storto';

  @override
  String sourceCount(int count) {
    return '$count fonte';
  }

  @override
  String sourceCountPlural(int count) {
    return '$count fonti';
  }

  @override
  String get sourceFacts => 'Fatti di origine:';

  @override
  String get splitDiff => 'Diff affiancato';

  @override
  String get startDmWithAgent => 'Inizia messaggio diretto con agente';

  @override
  String get startLabel => 'Avvia';

  @override
  String get startOnAppLaunch => 'Avvia all\'apertura dell\'app';

  @override
  String get startServerToAccept =>
      'Avvia il server per accettare connessioni MCP.';

  @override
  String get statusLabel => 'Stato';

  @override
  String stepConnect(int number) {
    return 'Passaggio $number · Connetti';
  }

  @override
  String get stop => 'Ferma';

  @override
  String get stopped => 'Arrestato';

  @override
  String get streaks => 'Serie';

  @override
  String get strictIdentityCheck => 'Verifica rigorosa dell\'identità';

  @override
  String get success => 'Successo';

  @override
  String get successLabel => 'Successo';

  @override
  String get suggestAChange => 'Suggerisci una modifica';

  @override
  String get suggestAChangeEllipsis => 'Suggerisci una modifica...';

  @override
  String get suggestLabel => 'SUGGERIMENTO';

  @override
  String get superseded => 'Sostituito';

  @override
  String get synced => 'Sincronizzato';

  @override
  String get systemDefault => 'Predefinito di sistema';

  @override
  String get systemFonts => 'Font di sistema';

  @override
  String get systemPrompt => 'Prompt di sistema';

  @override
  String get systemPromptLabel => 'Prompt di sistema';

  @override
  String get talkToControlCenter => 'Parla con Control Center.';

  @override
  String get tapBadgeDescription =>
      'Tocca un badge per scoprire come salire di livello';

  @override
  String get taskMentionSection => 'Attività';

  @override
  String get testLabel => 'Test';

  @override
  String get theme => 'Tema';

  @override
  String get themeDark => 'Scuro';

  @override
  String get themeLight => 'Chiaro';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get thisCannotBeUndone => 'Questa azione non può essere annullata.';

  @override
  String get thisConversation => 'questa conversazione';

  @override
  String get ticketLabel => 'TICKET';

  @override
  String get titleDescription => 'Descrizione';

  @override
  String get titleLabel => 'Titolo';

  @override
  String get todayLabel => 'Oggi';

  @override
  String get toggleBookmark => 'Aggiungi/rimuovi segnalibro';

  @override
  String get toggleTheme => 'Cambia tema';

  @override
  String get toggleWorkspaceSwitcher => 'Cambia selettore dello spazio';

  @override
  String get tokenConfigured =>
      'Configurato — i client devono presentare questo token.';

  @override
  String get tokenConfiguredClients =>
      'Configurato — i client devono presentare questo token.';

  @override
  String tokenName(String name) {
    return 'Token $name';
  }

  @override
  String get topic => 'Argomento';

  @override
  String get topicHint => 'es: Tech Stack, Design System';

  @override
  String get totalRuns => 'Esecuzioni totali';

  @override
  String trackingParamsCount(int count) {
    return '$count parametri di tracciamento';
  }

  @override
  String get typeCommandOrSearch => 'Digita un comando o cerca…';

  @override
  String get typography => 'Tipografia';

  @override
  String get unavailable => 'Non disponibile';

  @override
  String get unexpectedError => 'Si è verificato un errore imprevisto.';

  @override
  String get unifiedDiff => 'Diff unificato';

  @override
  String get unknownAuthor => 'Sconosciuto';

  @override
  String get unnamedAgent => 'Agente senza nome';

  @override
  String get updateKey => 'Aggiorna chiave';

  @override
  String get updateLabel => 'Aggiorna';

  @override
  String get updateToken => 'Aggiorna token';

  @override
  String updatedDaysAgo(int count) {
    return 'Aggiornato $count g fa';
  }

  @override
  String updatedHoursAgo(int count) {
    return 'Aggiornato $count h fa';
  }

  @override
  String get updatedJustNow => 'Aggiornato ora';

  @override
  String updatedMinutesAgo(int count) {
    return 'Aggiornato $count min fa';
  }

  @override
  String get useSandbox => 'Usa sandbox';

  @override
  String get useWorkspaceDefault => 'Usa predefinito dello spazio di lavoro';

  @override
  String get userAgent => 'User-Agent';

  @override
  String get userAgentDescription =>
      'Lascia vuoto per usare lo User-Agent predefinito dell\'app. Alcuni siti bloccano gli User-Agent non browser.';

  @override
  String get usingSystemDefaultMicrophone =>
      'Utilizzo del microfono predefinito del sistema.';

  @override
  String get viewAll => 'Vedi tutto';

  @override
  String get viewLabel => 'Visualizza';

  @override
  String get viewLog => 'Vedi registro';

  @override
  String get viewLogs => 'Vedi registri';

  @override
  String voiceInstallFailed(String error) {
    return 'Installazione non riuscita: $error';
  }

  @override
  String get voiceModelNotInstalled =>
      'Non installato. Scarica ~200 MB una sola volta; funziona interamente sul dispositivo.';

  @override
  String get voiceModelNotInstalledLabel => 'Modello vocale non installato.';

  @override
  String get voiceRedownloadBody =>
      'I file del modello esistenti saranno eliminati e l\'archivio di ~200 MB scaricato di nuovo. La trascrizione vocale non sarà disponibile fino al completamento del download.';

  @override
  String get voiceRemoveBody =>
      'La trascrizione vocale sarà disabilitata finché non la reinstalli. Puoi reinstallarla in qualsiasi momento.';

  @override
  String get voiceTranscription => 'Trascrizione vocale';

  @override
  String get meetingVad => 'Rilevamento del parlato (Silero VAD)';

  @override
  String get meetingVadDescription =>
      'Un modello appreso di rilevamento dell\'attività vocale che salta i silenzi per trascrivere solo il parlato. Ripiega su una soglia di energia se non installato.';

  @override
  String get meetingVadInstalled =>
      'Installato. La trascrizione è filtrata sul parlato rilevato.';

  @override
  String get meetingVadNotInstalled =>
      'Non installato: si usa la soglia di energia.';

  @override
  String get meetingModelIncluded => 'Incluso';

  @override
  String get weakIsolationDescription =>
      'Isolamento debole — solo limite di namespace, nessun limite di kernel.';

  @override
  String get whenOffNoDefaultRoute =>
      'Se disattivato, il sandbox si avvia senza una rotta predefinita.';

  @override
  String get whenOffServerStaysStopped =>
      'Se disattivato, il server rimane fermato finché non lo avvii.';

  @override
  String get whisperBaseEn => 'Whisper base.en (sherpa-onnx)';

  @override
  String get whisperInstalled =>
      'Whisper base.en installato. Usato dal pulsante microfono del compositore.';

  @override
  String get speechModel => 'Modello vocale';

  @override
  String get speechModelHint =>
      'Usato per la trascrizione delle riunioni e il microfono del compositore.';

  @override
  String get voiceModelInstalled =>
      'Installato. Alimenta la trascrizione delle riunioni e il pulsante microfono del compositore.';

  @override
  String get meetingMicSilentWarning =>
      'Il microfono potrebbe essere disattivato — gli altri parlano ma non arriva nulla al microfono.';

  @override
  String get meetingSummaryPrivacyNotice =>
      'La registrazione e la trascrizione restano su questo computer. Il riepilogo è scritto da un agente, quindi se usa un modello cloud la trascrizione e le note vengono inviate a quel fornitore.';

  @override
  String get meetingTemplates => 'Modelli di note riunione';

  @override
  String get meetingTemplatesHint =>
      'Adatta il riassunto IA a un tipo di riunione. Il modello attivo si applica ai riassunti nuovi e rieseguiti.';

  @override
  String get meetingTemplateActive => 'Modello attivo';

  @override
  String get meetingTemplateAdd => 'Aggiungi modello';

  @override
  String get meetingTemplateNewTitle => 'Nuovo modello';

  @override
  String get meetingTemplateEditTitle => 'Modifica modello';

  @override
  String get meetingTemplateNameLabel => 'Nome';

  @override
  String get meetingTemplateNameHint => 'es. Revisione sprint';

  @override
  String get meetingTemplateInstructionsLabel => 'Istruzioni';

  @override
  String get meetingTemplateInstructionsHint =>
      'Come deve l’IA strutturare ed enfatizzare queste note?';

  @override
  String get workingMemory => 'Memoria di lavoro';

  @override
  String get workspaceName => 'Nome dello spazio di lavoro';

  @override
  String get workspaceNotesScratchpad =>
      'Note dello spazio di lavoro e blocco appunti';

  @override
  String get workspaceScopedSkills =>
      'File di competenze con ambito spazio di lavoro collegati agli agenti.';

  @override
  String get workspaces => 'Spazi di lavoro';

  @override
  String get writeLabel => 'Scrivi';

  @override
  String get writePrivateNotes => 'Scrivi note private, osservazioni, piani...';

  @override
  String get writeSkillContent =>
      'Scrivi il contenuto della competenza qui (Markdown)…';

  @override
  String get xp => 'XP';

  @override
  String yearsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count anni fa',
      one: '1 anno fa',
    );
    return '$_temp0';
  }

  @override
  String get yesterday => 'ieri';

  @override
  String get focusModeStart => 'Inizia sessione di focus';

  @override
  String get focusModeConfigTitle => 'Inizia sessione di focus';

  @override
  String get focusModeGoalLabel => 'Obiettivo';

  @override
  String get focusModeGoalHint => 'Su cosa stai lavorando?';

  @override
  String get focusModeDurationLabel => 'Durata';

  @override
  String get focusModeBlockNotifications => 'Blocca notifiche';

  @override
  String get focusModeStartButton => 'Inizia';

  @override
  String get focusModeEndSession => 'Termina sessione';

  @override
  String get focusModeExpand => 'Espandi l\'app';

  @override
  String get focusModeFloat => 'Minimizza nella barra';

  @override
  String get focusModeActiveTooltip =>
      'Modalità focus attiva — tocca per terminare';

  @override
  String get dismiss => 'Ignora';

  @override
  String get acceptAndResolve => 'Accetta e risolvi';

  @override
  String reviewFatigueWarning(int minutes) {
    return 'Sembra che tu stia facendo molte revisioni consecutive. Fai una pausa!';
  }

  @override
  String get notificationSound => 'Suono di notifica';

  @override
  String get notificationSoundDescription =>
      'Suono riprodotto quando viene mostrata una notifica.';

  @override
  String get notificationSoundNone => 'Nessuno';

  @override
  String get notificationSoundPing => 'Ping';

  @override
  String get notificationSoundChime => 'Chime';

  @override
  String get notificationSoundPop => 'Pop';

  @override
  String get notificationSoundDing => 'Ding';

  @override
  String get notificationSoundWhoosh => 'Whoosh';

  @override
  String get notificationSoundMigrosSoft => 'Migros (soft)';

  @override
  String get notificationSoundMigrosHard => 'Migros (hard)';

  @override
  String get notificationSoundSbb => 'SBB';

  @override
  String get notificationSoundCff => 'CFF';

  @override
  String get notificationSoundFfs => 'FFS';

  @override
  String get notificationSoundPost => 'Post';

  @override
  String get notificationSoundTest => 'Prova';

  @override
  String get notificationVolume => 'Volume';

  @override
  String get viewProfile => 'Visualizza profilo';

  @override
  String get clearAllFilters => '× Cancella tutto';

  @override
  String acrossNRepos(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'In $countString repo',
      one: 'In 1 repo',
    );
    return '$_temp0';
  }

  @override
  String get pullRequestsLabel => 'PR';

  @override
  String noPrsByUserInWorkspace(String login) {
    return 'Nessuna PR di @$login in questo spazio di lavoro';
  }

  @override
  String get usersLabel => 'Utenti';

  @override
  String get mergePullRequest => 'Merge pull request';

  @override
  String get forceMergePullRequest => 'Force merge pull request';

  @override
  String get closePullRequest => 'Close pull request';

  @override
  String get closePullRequestConfirm =>
      'Are you sure you want to close this pull request?';

  @override
  String get stackedPullRequests => 'Pull request in stack';

  @override
  String partOfStack(int position, int total) {
    return 'Parte di uno stack ($position di $total)';
  }

  @override
  String get createStack => 'Crea stack';

  @override
  String get createStackDialogTitle => 'Crea uno stack di pull request';

  @override
  String createStackDialogBody(int count) {
    return 'Queste $count pull request verranno impilate, dal basso verso l\'alto:';
  }

  @override
  String get createStackInvalidSelection =>
      'Seleziona almeno due pull request dello stesso repository per creare uno stack';

  @override
  String get createStackNotAChain =>
      'Le pull request selezionate non formano una catena: il branch base di ognuna deve essere il branch head della precedente';

  @override
  String get createStackAlreadyStacked =>
      'Una o più pull request selezionate sono già in uno stack';

  @override
  String get stackCreated => 'Stack creato';

  @override
  String get stackCreationFailed => 'Impossibile creare lo stack';

  @override
  String get squashAndMerge => 'Squash and merge';

  @override
  String get createMergeCommit => 'Create a merge commit';

  @override
  String get rebaseAndMerge => 'Rebase and merge';

  @override
  String get commitTitle => 'Commit title';

  @override
  String get commitDescription => 'Commit description';

  @override
  String get pullRequestMerged => 'Pull request merged';

  @override
  String get pullRequestClosed => 'Pull request closed';

  @override
  String failedToMergePr(String error) {
    return 'Failed to merge: $error';
  }

  @override
  String failedToClosePr(String error) {
    return 'Failed to close: $error';
  }

  @override
  String get checksFailing => 'Controlli falliti';

  @override
  String get reviewsPending => 'Some reviews are pending';

  @override
  String get confirm => 'Confirm';

  @override
  String get trustedSitesSectionTitle => 'Siti attendibili';

  @override
  String get trustedSitesEmpty =>
      'Nessun sito attendibile. Aggiungi un dominio per disabilitare il blocco.';

  @override
  String get addTrustedSite => 'Aggiungi sito attendibile';

  @override
  String get removeTrustedSite => 'Rimuovi';

  @override
  String get disableBlockingForThisSite => 'Disabilita blocco su questo sito';

  @override
  String get enableBlockingForThisSite => 'Abilita blocco su questo sito';

  @override
  String get enterDomainHint => 'es. esempio.com';

  @override
  String get invalidDomain => 'Inserisci un dominio valido (es. esempio.com)';

  @override
  String get pageLoadTimedOut =>
      'Caricamento pagina scaduto. Ricarica o apri nel browser.';

  @override
  String get pipelinesScreenTitle => 'Pipelines';

  @override
  String get pipelinesScreenSubtitle =>
      'Declarative multi-step agent workflows';

  @override
  String get pipelinesRunHello => 'Run hello pipeline';

  @override
  String get pipelinesRunPipeline => 'Esegui pipeline';

  @override
  String get pipelineRunLauncherTitle => 'Esegui pipeline';

  @override
  String get pipelineRunSubtitle =>
      'Scegli un pipeline e compila i suoi input per avviare un\'esecuzione.';

  @override
  String get pipelineRunNoInputsBadge => 'Nessun input';

  @override
  String pipelineRunInputsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count input',
      one: '1 input',
    );
    return '$_temp0';
  }

  @override
  String get pipelineRunNoInputs => 'Questo pipeline non richiede input.';

  @override
  String get pipelineRunSubmit => 'Esegui pipeline';

  @override
  String get pipelineRunCouldNotStart => 'Impossibile avviare l\'esecuzione.';

  @override
  String pipelineRunStarted(String name) {
    return '$name avviato';
  }

  @override
  String get pipelineRunEmptyTitle =>
      'Nessun pipeline pronto per l\'esecuzione';

  @override
  String get pipelineRunEmptyHint =>
      'Abilita un pipeline e attiva l\'esecuzione manuale nel suo editor per avviarlo qui.';

  @override
  String get pipelineRunManageTemplates => 'Gestisci pipeline';

  @override
  String get pipelineRunSettingsTitle => 'Esecuzione manuale';

  @override
  String get pipelineRunSettingsAllow => 'Consenti esecuzione manuale';

  @override
  String get pipelineRunSettingsAllowHelp =>
      'Mostra questo pipeline nella pagina di esecuzione per poterlo avviare manualmente.';

  @override
  String get pipelineRunSettingsInputsTitle => 'Input';

  @override
  String get pipelineRunSettingsAddInput => 'Aggiungi input';

  @override
  String get pipelineRunSettingsNoInputs => 'Ancora nessun input.';

  @override
  String get pipelineInputEditTitle => 'Campo di input';

  @override
  String get pipelineInputKeyLabel => 'Chiave';

  @override
  String get pipelineInputKeyHelp =>
      'Chiave di stato in cui viene memorizzato il valore (es. repoFullName).';

  @override
  String get pipelineInputLabelLabel => 'Etichetta';

  @override
  String get pipelineInputTypeLabel => 'Tipo';

  @override
  String get pipelineInputOptionsLabel => 'Opzioni (separate da virgole)';

  @override
  String get pipelineInputDefaultLabel => 'Valore predefinito';

  @override
  String get pipelineInputPlaceholderLabel => 'Segnaposto';

  @override
  String get pipelineInputHelpLabel => 'Testo di aiuto';

  @override
  String get pipelineInputRequiredLabel => 'Obbligatorio';

  @override
  String get pipelineInputTypeText => 'Testo';

  @override
  String get pipelineInputTypeMultiline => 'Testo multiriga';

  @override
  String get pipelineInputTypeNumber => 'Numero';

  @override
  String get pipelineInputTypeBoolean => 'Interruttore';

  @override
  String get pipelineInputTypeSelect => 'Selezione';

  @override
  String get pipelinesEmpty => 'No pipeline runs yet';

  @override
  String get pipelinesEmptyHint =>
      'Fai clic su «Esegui pipeline» per avviarne uno.';

  @override
  String get pipelinesSelectRun => 'Select a pipeline run to view steps';

  @override
  String get pipelinesNoSteps => 'No steps recorded yet';

  @override
  String get pipelinesNoActiveWorkspace =>
      'Seleziona uno spazio di lavoro per vedere le sue pipeline';

  @override
  String pipelinesLoadError(String error) {
    return 'Impossibile caricare le pipeline: $error';
  }

  @override
  String pipelinesRunFailed(String error) {
    return 'Impossibile avviare la pipeline: $error';
  }

  @override
  String get pipelineStatusPending => 'Pending';

  @override
  String get pipelineStatusRunning => 'Running';

  @override
  String get pipelineStatusSuspended => 'Suspended';

  @override
  String get pipelineStatusCompleted => 'Completed';

  @override
  String get pipelineStatusFailed => 'Failed';

  @override
  String get pipelineStatusCancelled => 'Cancelled';

  @override
  String get pipelineStatusSkipped => 'Skipped';

  @override
  String pipelineRunDuration(int seconds) {
    return '${seconds}s';
  }

  @override
  String pipelineStepDuration(int seconds) {
    return '${seconds}s';
  }

  @override
  String pipelineRunStepProgress(int completed, int total) {
    return '$completed di $total passaggi';
  }

  @override
  String get pipelineWaterfallTimeline => 'Cronologia';

  @override
  String pipelineWaterfallActive(String duration) {
    return 'Attivo $duration';
  }

  @override
  String pipelineWaterfallIdle(String duration) {
    return 'inattivo $duration';
  }

  @override
  String get pipelineWaterfallIdleTooltip =>
      'Tempo escluso dal totale attivo: l\'esecuzione era interrotta o in attesa tra i passaggi.';

  @override
  String get pipelineStepStarted => 'Avviato';

  @override
  String get pipelineStepFinished => 'Completato';

  @override
  String get pipelineStepDurationLabel => 'Durata';

  @override
  String get pipelineStepBranch => 'Ramo';

  @override
  String get pipelineStepViewConversation => 'Vedi conversazione';

  @override
  String get pipelineStepError => 'Errore';

  @override
  String get pipelineStepInput => 'Input';

  @override
  String get pipelineStepOutput => 'Output';

  @override
  String get pipelineStepNotExecuted => 'Non ancora eseguito';

  @override
  String get pipelineRunViewTimeline => 'Cronologia';

  @override
  String get pipelineRunViewGraph => 'Grafico';

  @override
  String pipelineRunFailedAtStep(String step) {
    return 'Non riuscito in $step';
  }

  @override
  String get pipelineRunTriggerManual => 'Manuale';

  @override
  String get pipelineRunTriggerAuto => 'Automatico';

  @override
  String get pipelineStepSkippedReason => 'Saltato';

  @override
  String get pipelineRunColumnPipeline => 'Pipeline';

  @override
  String get pipelineRunColumnDuration => 'Durata';

  @override
  String get pipelineRunColumnStarted => 'Avviato';

  @override
  String get pipelineRunFilterAll => 'Tutti';

  @override
  String get pipelineRunFilterEmpty =>
      'Nessuna esecuzione corrisponde a questo filtro';

  @override
  String get relativeJustNow => 'proprio ora';

  @override
  String relativeMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count min fa',
      one: '1 min fa',
    );
    return '$_temp0';
  }

  @override
  String relativeHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ore fa',
      one: '1 ora fa',
    );
    return '$_temp0';
  }

  @override
  String relativeDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count giorni fa',
      one: '1 giorno fa',
    );
    return '$_temp0';
  }

  @override
  String get automationsTitle => 'Automazioni';

  @override
  String get automationsSubtitle =>
      'Avvia automaticamente le pipeline quando si verificano eventi di dominio';

  @override
  String get automationsNoTriggers =>
      'Nessun trigger configurato per questo evento.';

  @override
  String get automationsAddTrigger => 'Aggiungi trigger';

  @override
  String get tasksTitle => 'Tasks';

  @override
  String get taskStatusPending => 'Pending';

  @override
  String get taskStatusInProgress => 'In progress';

  @override
  String get taskStatusCompleted => 'Completed';

  @override
  String get taskStatusFailed => 'Failed';

  @override
  String get taskStatusCancelled => 'Cancelled';

  @override
  String get tasksNoTasks => 'Nessun ticket';

  @override
  String get teamsTitle => 'Teams';

  @override
  String get teamsNoTeams => 'No teams configured';

  @override
  String get teamsAddTeam => 'Add team';

  @override
  String get teamsManageSubtitle =>
      'Raggruppa gli agenti in team e instrada il lavoro assegnato tramite un responsabile.';

  @override
  String get teamsLoadError => 'Impossibile caricare i team';

  @override
  String get teamsEmptyTitle => 'Ancora nessun team';

  @override
  String get teamsEmptyDescription =>
      'Raggruppa gli agenti in team così che il lavoro assegnato a un team venga instradato tramite un responsabile che delega.';

  @override
  String get teamCreateTitle => 'Nuovo team';

  @override
  String get teamEditTitle => 'Modifica team';

  @override
  String get teamNameLabel => 'Nome del team';

  @override
  String get teamNameHint => 'ad es. Frontend';

  @override
  String get teamDescriptionLabel => 'Descrizione';

  @override
  String get teamDescriptionHint => 'Di cosa è responsabile questo team';

  @override
  String get teamLeaderLabel => 'Responsabile';

  @override
  String get teamLeaderHelp =>
      'Il coordinatore che riceve il lavoro assegnato al team e lo delega al membro più adatto.';

  @override
  String get teamNoLeader => 'Nessun responsabile';

  @override
  String get teamInstructionsLabel => 'Istruzioni operative';

  @override
  String get teamInstructionsHelp =>
      'Aggiunte al briefing del responsabile: convenzioni del team, regole di escalation, tono.';

  @override
  String get teamInstructionsHint => 'Facoltativo';

  @override
  String get teamSaved => 'Team salvato';

  @override
  String get teamMembersError => 'Impossibile caricare i membri';

  @override
  String teamMemberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count membri',
      one: '1 membro',
      zero: 'Nessun membro',
    );
    return '$_temp0';
  }

  @override
  String get teamAddMember => 'Aggiungi membro';

  @override
  String get teamAddMemberTitle => 'Aggiungi membri';

  @override
  String teamAddMembersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Aggiungi $count',
      one: 'Aggiungi 1',
      zero: 'Aggiungi',
    );
    return '$_temp0';
  }

  @override
  String get teamNoAgentsToAdd => 'Ogni agente fa già parte di questo team.';

  @override
  String get teamRemoveMember => 'Rimuovi dal team';

  @override
  String get teamLeaderBadge => 'Responsabile';

  @override
  String get teamUnknownAgent => 'Agente sconosciuto';

  @override
  String get teamMembersEmpty => 'Ancora nessun membro';

  @override
  String get teamMembersEmptyDescription =>
      'Aggiungi agenti così che il responsabile abbia persone a cui delegare.';

  @override
  String get teamSelectPrompt => 'Seleziona un team';

  @override
  String get teamSelectPromptDescription =>
      'Scegli un team dall\'elenco oppure creane uno nuovo.';

  @override
  String get teamDeleteTitle => 'Eliminare il team?';

  @override
  String teamDeleteBody(String name) {
    return '$name verrà eliminato. I suoi agenti non saranno interessati.';
  }

  @override
  String get teamHasLeaderTooltip => 'Ha un responsabile';

  @override
  String get pipelineRunTitle => 'Pipeline run';

  @override
  String get pipelineNotFound => 'Pipeline run not found';

  @override
  String get pipelineTemplatesNav => 'Modelli di pipeline';

  @override
  String get pipelineTemplatesTitle => 'Modelli di pipeline';

  @override
  String get pipelineTemplatesSubtitle =>
      'Editor drag-and-drop per le pipeline che orchestrano i tuoi agenti.';

  @override
  String get pipelineTemplatesNew => 'Nuovo modello';

  @override
  String get pipelineTemplatesEmpty =>
      'Nessun modello di pipeline. Creane uno per iniziare.';

  @override
  String get pipelineTemplateIdLabel => 'ID modello';

  @override
  String get pipelineTemplateBuiltInBadge => 'Integrato';

  @override
  String get pipelineTemplateDeleteConfirmTitle => 'Eliminare il modello?';

  @override
  String pipelineTemplateDeleteConfirmBody(String name) {
    return 'Eliminare il modello di pipeline $name? Non è possibile annullare.';
  }

  @override
  String get pipelineTemplateSaved => 'Modello di pipeline salvato';

  @override
  String get pipelineTemplateEditorTitle => 'Modifica pipeline';

  @override
  String get pipelineTemplateEditorSubtitle =>
      'Trascina tipi di nodi dalla barra laterale sul canvas e collegali.';

  @override
  String get unsavedChanges => 'Modifiche non salvate';

  @override
  String get nodeLibraryTitle => 'Libreria nodi';

  @override
  String get nodeLibraryHint =>
      'Trascina una voce sul canvas per aggiungere un nodo.';

  @override
  String get editorDragHint =>
      'Trascina dalla libreria, clicca un nodo per modificarlo';

  @override
  String get editorEmptyCanvas =>
      'Trascina un nodo dalla libreria per iniziare.';

  @override
  String get nodeConfigTitle => 'Configurazione nodo';

  @override
  String get nodeConfigKind => 'Tipo';

  @override
  String get nodeConfigLabel => 'Etichetta';

  @override
  String get nodeConfigAgent => 'Agente';

  @override
  String get nodeConfigAgentHint => 'Scegli un agente…';

  @override
  String get nodeConfigInputKeys => 'Chiavi di input (separate da virgole)';

  @override
  String get nodeConfigInputKeysHelp =>
      'Chiavi di stato consumate da questo nodo. Usate per la sostituzione dei segnaposto nel prompt.';

  @override
  String get nodeConfigRepos => 'Repository da clonare';

  @override
  String get nodeConfigReposHelp =>
      'Repository clonati e indicizzati quando questo nodo avvia la sua conversazione. Selezionarli tutti li clona tutti (comportamento predefinito).';

  @override
  String nodeConfigReposDynamic(String entries) {
    return 'Voci dinamiche mantenute: $entries';
  }

  @override
  String get nodeConfigOutputKey => 'Chiave di output';

  @override
  String get nodeConfigPrompt => 'Template del prompt';

  @override
  String get nodeConfigPromptHelp =>
      'Usa segnaposto a doppia parentesi graffa per inserire valori dallo stato a runtime.';

  @override
  String get nodeConfigScript => 'Script bash';

  @override
  String get nodeConfigScriptHelp =>
      'Eseguito con bash -c. GITHUB_TOKEN è impostato. I segnaposto sono sostituiti prima dell\'esecuzione.';

  @override
  String get nodeConfigTriggers => 'Attivato da';

  @override
  String get nodeConfigNoUpstream => 'Non ci sono altri nodi a monte.';

  @override
  String get nodeConfigRouteKeys => 'Chiavi di route';

  @override
  String nodeConfigRouteKeyFrom(String source) {
    return 'Chiave di route da $source';
  }

  @override
  String get conditionSectionTitle => 'Condizione';

  @override
  String get conditionMode => 'Modalità';

  @override
  String get conditionModeFilesAny => 'File presenti — almeno uno';

  @override
  String get conditionModeFilesAll => 'File presenti — tutti';

  @override
  String get conditionModeComparison => 'Confronto';

  @override
  String get conditionModeSwitch => 'Selettore';

  @override
  String get conditionFilePaths => 'Percorsi dei file';

  @override
  String get conditionFilePathsAnyHelp =>
      'Un percorso per riga, relativo alla directory di base. Restituisce true se ne esiste almeno uno.';

  @override
  String get conditionFilePathsAllHelp =>
      'Un percorso per riga, relativo alla directory di base. Restituisce true solo se esistono tutti.';

  @override
  String get conditionBaseKey => 'Chiave della directory di base';

  @override
  String get conditionBaseKeyHelp =>
      'Chiave di stato con la directory in cui risolvere i percorsi (predefinito repoLocalPath).';

  @override
  String get conditionRecursive => 'Cerca nelle sottocartelle';

  @override
  String get conditionNegate => 'Inverti: restituisce true se manca';

  @override
  String get conditionLeft => 'Valore sinistro';

  @override
  String get conditionOperator => 'Operatore';

  @override
  String get conditionRight => 'Valore destro';

  @override
  String get conditionSwitchKey => 'Seleziona sulla chiave di stato';

  @override
  String get conditionCases => 'Casi (separati da virgole)';

  @override
  String get conditionCasesHelp =>
      'Chiavi di route da confrontare con il valore, in ordine.';

  @override
  String get conditionDefaultCase => 'Caso predefinito';

  @override
  String get triggerPanelTitle => 'Trigger';

  @override
  String get triggerPanelHelp => 'Cosa avvia questa pipeline.';

  @override
  String get triggerManualHelp =>
      'Mostra nella pagina di esecuzione e avvia manualmente.';

  @override
  String get triggerSectionAutomatic => 'Trigger automatici';

  @override
  String get triggerAddButton => 'Aggiungi trigger';

  @override
  String get triggerNoneYet => 'Ancora nessun trigger automatico.';

  @override
  String get triggerAddDialogTitle => 'Aggiungi trigger';

  @override
  String get triggerKindLabel => 'Tipo di trigger';

  @override
  String get triggerKindEvent => 'Su un evento';

  @override
  String get triggerKindSchedule => 'Su pianificazione';

  @override
  String get triggerIntervalLabel => 'Esegui ogni (secondi)';

  @override
  String get triggerKindWebhook => 'Tramite un webhook';

  @override
  String get triggerScheduleExprLabel =>
      'Pianificazione (cron o every:secondi)';

  @override
  String get triggerTimezoneLabel => 'Fuso orario (opzionale)';

  @override
  String get triggerCatchUpLabel => 'Esecuzioni mancate';

  @override
  String get triggerCatchUpRunOnce => 'Esegui una volta';

  @override
  String get triggerCatchUpSkip => 'Salta';

  @override
  String get syncHealthTitle => 'Stato sincronizzazione';

  @override
  String get syncHealthNoConfigs => 'Nessuna connessione di sincronizzazione';

  @override
  String get syncHealthNeverSynced => 'Mai sincronizzato';

  @override
  String get syncOutcomeOk => 'Sincronizzato';

  @override
  String get syncOutcomeFailed => 'Non riuscito';

  @override
  String get syncOutcomeSkipped => 'Saltato';

  @override
  String syncHealthFailedStreak(int count) {
    return '$count errori consecutivi';
  }

  @override
  String get triggerWebhookHelp =>
      'Viene generato un URL webhook firmato. I sistemi esterni inviano una POST per avviare questa pipeline.';

  @override
  String get triggerEventFieldLabel => 'Evento';

  @override
  String get triggerNoMoreEvents =>
      'Tutti gli eventi disponibili sono già configurati.';

  @override
  String get triggerMatchStatusLabel => 'Solo quando lo stato è';

  @override
  String get triggerSummaryNone => 'Nessun trigger';

  @override
  String triggerEverySeconds(int seconds) {
    return 'Ogni ${seconds}s';
  }

  @override
  String get triggerEventManual => 'Esecuzione manuale';

  @override
  String get triggerEventSchedule => 'Pianificazione';

  @override
  String get triggerEventPrStatusChanged => 'Stato della PR cambiato';

  @override
  String get triggerEventExternalPr => 'PR esterna aperta';

  @override
  String get triggerEventPrPublished => 'PR pubblicata';

  @override
  String get triggerEventPrMerged => 'PR unita';

  @override
  String get triggerEventRepoAdded => 'Repository aggiunto';

  @override
  String get triggerEventMessageReceived => 'Messaggio ricevuto';

  @override
  String get triggerEventTicketCompleted => 'Attività completata';

  @override
  String get triggerEventTicketFailed => 'Attività non riuscita';

  @override
  String get triggerEventTicketCancelled => 'Attività annullata';

  @override
  String get triggerEventBudgetCrossed => 'Soglia di budget superata';

  @override
  String get automationsManagedHint =>
      'I trigger si configurano per pipeline nel suo editor. Attivali o disattivali qui.';

  @override
  String get automationsEditInPipeline => 'Modifica nella pipeline';

  @override
  String get nodeLibrarySearchHint => 'Cerca nodi';

  @override
  String get nodeLibraryNoMatches => 'Nessun nodo corrispondente';

  @override
  String get nodeCategoryFlow => 'Flusso e logica';

  @override
  String get nodeCategoryPr => 'Revisione PR';

  @override
  String get nodeCategoryAgents => 'Agenti';

  @override
  String get nodeCategoryMessaging => 'Messaggistica';

  @override
  String get nodeCategoryCode => 'Codice';

  @override
  String get nodeCategoryDemo => 'Demo';

  @override
  String get triggerDisabledTag => 'disattivato';

  @override
  String get pipelineInputTypeRepo => 'Repository';

  @override
  String get pipelineRunNoRepos =>
      'Ancora nessun repository in questo workspace.';

  @override
  String get allowTicketingApi => 'Consenti chiamate API dei ticket';

  @override
  String get ticketingApiKey => 'Chiave API ticketing';

  @override
  String get ticketingApiKeySubtitle =>
      'Inietta la chiave API del provider di ticket nella sandbox.';

  @override
  String get ticketingProvider => 'Provider di ticket';

  @override
  String get connectGitHubAndTicketing =>
      'Connetti GitHub così Control Center può leggere le tue pull request, issue e revisioni. Connetti facoltativamente un provider di ticket. Niente lascia questa macchina.';

  @override
  String get triggerEventTicketAssigned => 'Ticket assegnato';

  @override
  String get navTickets => 'Ticket';

  @override
  String get ticketsTitle => 'Ticket';

  @override
  String get newTicket => 'Nuovo ticket';

  @override
  String get noTicketsYet => 'Ancora nessun ticket';

  @override
  String get assignTicket => 'Assegna ticket';

  @override
  String get addCollaborator => 'Aggiungi collaboratore';

  @override
  String get noCollaborators => 'Nessun collaboratore per ora';

  @override
  String get linkedPullRequests => 'Pull request collegate';

  @override
  String get noLinkedPullRequests => 'Nessuna pull request collegata';

  @override
  String get ticketActivity => 'Attività';

  @override
  String get ticketDispatchHint => '@menziona un agente per attivarlo…';

  @override
  String get stopAgent => 'Ferma agente';

  @override
  String get removeQueuedMessage => 'Rimuovi messaggio in coda';

  @override
  String get ticketProperties => 'Proprietà';

  @override
  String get ticketTabIssue => 'Ticket';

  @override
  String get ticketTabActivity => 'Attività';

  @override
  String get ticketTabChanges => 'Modifiche';

  @override
  String get ticketTabTerminal => 'Terminale';

  @override
  String get ticketSelectPrompt =>
      'Seleziona un ticket per visualizzarne i dettagli';

  @override
  String get ticketNoChanges =>
      'Nessuna modifica nei repository collegati per ora';

  @override
  String get ticketTerminalNoAgent =>
      'Assegna un agente per aprire un terminale';

  @override
  String get unassigned => 'Non assegnato';

  @override
  String get ticketStatusBacklog => 'Backlog';

  @override
  String get ticketStatusOpen => 'Da fare';

  @override
  String get ticketStatusInProgress => 'In corso';

  @override
  String get ticketStatusInReview => 'In revisione';

  @override
  String get ticketStatusDone => 'Fatto';

  @override
  String get ticketStatusBlocked => 'Bloccato';

  @override
  String get ticketStatusFailed => 'Fallito';

  @override
  String get ticketStatusCancelled => 'Annullato';

  @override
  String get notificationTicketAssigned => 'Ticket assegnato';

  @override
  String get notificationTicketStatusChanged => 'Stato del ticket cambiato';

  @override
  String get notificationTicketCollaboratorAdded => 'Collaboratore aggiunto';

  @override
  String get priority => 'Priorità';

  @override
  String get status => 'Stato';

  @override
  String get assignee => 'Assegnatario';

  @override
  String get labels => 'Etichette';

  @override
  String get noLabelsYet => 'Nessuna etichetta';

  @override
  String get clearLabels => 'Rimuovi etichette';

  @override
  String get pipelineStepAgentActivity => 'Attività dell\'agente';

  @override
  String get runStatusCompleted => 'Completato';

  @override
  String get runStatusQueued => 'In coda';

  @override
  String get ticketDescription => 'Descrizione';

  @override
  String get ticketPriorityNone => 'Nessuna';

  @override
  String get ticketPriorityUrgent => 'Urgente';

  @override
  String get ticketPriorityHigh => 'Alta';

  @override
  String get ticketPriorityMedium => 'Media';

  @override
  String get ticketPriorityLow => 'Bassa';

  @override
  String get ticketViewList => 'Elenco';

  @override
  String get ticketViewBoard => 'Bacheca';

  @override
  String get ticketTitlePlaceholder => 'Titolo del ticket';

  @override
  String get ticketDescriptionPlaceholder => 'Aggiungi una descrizione…';

  @override
  String get createMore => 'Crea altri';

  @override
  String selectedCount(int count) {
    return '$count selezionati';
  }

  @override
  String get clearSelection => 'Cancella selezione';

  @override
  String get bulkDeleteTitle => 'Elimina ticket';

  @override
  String bulkDeleteMessage(int count) {
    return 'Eliminare $count ticket selezionati? L\'azione è irreversibile.';
  }

  @override
  String get assignTo => 'Assegna a…';

  @override
  String get sectionMembers => 'Membri';

  @override
  String get sectionAgents => 'Agenti';

  @override
  String get sidebarGroupWorkspace => 'Spazio di lavoro';

  @override
  String get notificationsTitle => 'Notifiche';

  @override
  String get notificationsTooltip => 'Notifiche';

  @override
  String get notificationsEmpty => 'Sei al passo con tutto';

  @override
  String get markAllRead => 'Segna tutte come lette';

  @override
  String get toggleThemeLabel => 'Cambia tema';

  @override
  String get teamsNav => 'Team';

  @override
  String get noWorkspace => 'Nessuno spazio di lavoro';

  @override
  String get selectWorkspace => 'Seleziona uno spazio di lavoro';

  @override
  String get allAgentsIdle => 'Tutti gli agenti inattivi';

  @override
  String get statWorkspaces => 'Workspace';

  @override
  String get statAgents => 'Agenti';

  @override
  String get statRunning => 'In esecuzione';

  @override
  String get activeAgentsTitle => 'Agenti attivi';

  @override
  String get noAgentProcessesSubtitle =>
      'L\'attività degli agenti apparirà qui quando inizia un\'esecuzione.';

  @override
  String agentIdShort(String id) {
    return 'ID $id';
  }

  @override
  String runningProcessesLabel(int count) {
    return 'In esecuzione · $count';
  }

  @override
  String get noneLabel => 'Nessuno';

  @override
  String get navMemory => 'Memoria';

  @override
  String get memoryTabFacts => 'Fatti';

  @override
  String get memoryTabPolicies => 'Politiche';

  @override
  String get memoryTabGraph => 'Grafo della conoscenza';

  @override
  String get memoryNoWorkspace =>
      'Seleziona uno spazio di lavoro per visualizzarne la memoria.';

  @override
  String get topStory => 'In primo piano';

  @override
  String get searchArticles => 'Cerca articoli';

  @override
  String get filterAll => 'Tutti';

  @override
  String get filterUnread => 'Non letti';

  @override
  String get filterSaved => 'Salvati';

  @override
  String get saveArticle => 'Salva articolo';

  @override
  String get removeFromSaved => 'Rimuovi dai salvati';

  @override
  String get filterBySource => 'Filtra per fonte';

  @override
  String get viewAsList => 'Vista elenco';

  @override
  String get viewAsGrid => 'Vista griglia';

  @override
  String get noMatchingArticles => 'Nessun articolo corrispondente';

  @override
  String get noMatchingArticlesBody =>
      'Prova una ricerca o un filtro per fonte diverso.';

  @override
  String get allCaughtUp => 'Tutto in pari';

  @override
  String get allCaughtUpBody => 'Nessun articolo da leggere — torna più tardi.';

  @override
  String get openArticlesInAppDescription =>
      'Apri i link nel lettore integrato invece che nel browser predefinito.';

  @override
  String get blockAdsTrackersDescription =>
      'Rimuovi pubblicità, tracker e banner dei cookie dagli articoli aperti nel lettore.';

  @override
  String get agentQuestionHeader => 'Domanda per te';

  @override
  String get agentQuestionAnsweredLabel => 'Risposto';

  @override
  String get agentQuestionSubmit => 'Invia risposta';

  @override
  String get agentQuestionFreeformHint => 'Scrivi la tua risposta…';

  @override
  String get agentQuestionAnswerLabel => 'La tua risposta';

  @override
  String get reviewRequested => 'Revisione richiesta';

  @override
  String get loadMorePrs => 'Carica altri';

  @override
  String get loadingMorePrs => 'Caricamento…';

  @override
  String get noPrsMatchFilters =>
      'Nessuna pull request corrisponde ai filtri in questo repository';

  @override
  String get connectGitHubToLoadPrs =>
      'Collega GitHub per caricare le pull request';

  @override
  String get noRepositoriesConfigured => 'Nessun repository configurato';

  @override
  String get noAuthors => 'Nessun autore';

  @override
  String openedAgo(String age) {
    return 'Aperto $age';
  }

  @override
  String prTimelineOpened(String author) {
    return '$author ha aperto questa pull request';
  }

  @override
  String prTimelineOpenedWithCommits(String author, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count commit',
      one: '1 commit',
    );
    return '$author ha aperto questa pull request con $_temp0';
  }

  @override
  String prTimelineRequestedReview(String actor, String reviewers) {
    return '$actor ha richiesto una revisione a $reviewers';
  }

  @override
  String prTimelineRemovedReviewRequest(String actor, String reviewers) {
    return '$actor ha rimosso la richiesta di revisione per $reviewers';
  }

  @override
  String prTimelineRequestedAndRemovedReview(
    String actor,
    String requested,
    String removed,
  ) {
    return '$actor ha richiesto una revisione a $requested e ha rimosso la richiesta di revisione per $removed';
  }

  @override
  String prTimelineCommitted(String author) {
    return '$author ha fatto commit';
  }

  @override
  String prTimelinePushedCommits(String author, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count commit',
      one: '1 commit',
    );
    return '$author ha inviato $_temp0';
  }

  @override
  String prTimelineApproved(String author) {
    return '$author ha approvato queste modifiche';
  }

  @override
  String prTimelineChangesRequested(String author) {
    return '$author ha richiesto modifiche';
  }

  @override
  String prTimelineCodeComments(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count commenti al codice',
      one: '1 commento al codice',
    );
    return '$_temp0';
  }

  @override
  String prTimelineReviewed(String author) {
    return '$author ha lasciato una revisione';
  }

  @override
  String get prTimelineSomeone => 'Qualcuno';

  @override
  String get prTimelineBotBadge => 'bot';

  @override
  String updatedAgo(String age) {
    return 'Aggiornato $age';
  }

  @override
  String get checksPassing => 'Controlli superati';

  @override
  String get checksRunning => 'Controlli in corso';

  @override
  String get needsYourReview => 'Richiede la tua revisione';

  @override
  String diffSummary(int additions, int deletions) {
    return '+$additions −$deletions righe';
  }

  @override
  String get checks => 'Controlli';

  @override
  String get noReviewersAssigned => 'Nessun revisore assegnato';

  @override
  String get noAssignees => 'Nessun assegnatario';

  @override
  String get noChecksYet => 'Nessun controllo ancora eseguito';

  @override
  String checksFailingCount(int count) {
    return '$count non superati';
  }

  @override
  String get showMore => 'Mostra di più';

  @override
  String get showLess => 'Mostra meno';

  @override
  String get backToPullRequests => 'Torna alle pull request';

  @override
  String get pullRequestNotFound => 'Pull request non trovata';

  @override
  String get pullRequestNotFoundBody =>
      'Potrebbe essere stata unita, chiusa o spostata.';

  @override
  String get couldntLoadPullRequest =>
      'Impossibile caricare questa pull request';

  @override
  String get showDetails => 'Mostra dettagli';

  @override
  String loadingPullRequestNumber(int number) {
    return 'Caricamento della pull request #$number…';
  }

  @override
  String get noDescriptionProvided => 'Nessuna descrizione fornita.';

  @override
  String get factsHint =>
      'I fatti appariranno qui man mano che i tuoi agenti imparano.';

  @override
  String get noFactsMatch => 'Nessun fatto corrisponde alla tua ricerca';

  @override
  String get memoryLoadError => 'Impossibile caricare la memoria';

  @override
  String get sortRecent => 'Recenti';

  @override
  String get sortConfidence => 'Affidabilità';

  @override
  String get confidenceTooltip =>
      'Quanto gli agenti sono sicuri che questo fatto sia vero, da 0 a 100%.';

  @override
  String get supersededTooltip => 'Un fatto più recente ha sostituito questo.';

  @override
  String get domain => 'Dominio';

  @override
  String get fitToView => 'Adatta alla vista';

  @override
  String get project => 'Progetto';

  @override
  String get projects => 'Progetti';

  @override
  String get newProject => 'Nuovo progetto';

  @override
  String get editProject => 'Modifica progetto';

  @override
  String get deleteProject => 'Elimina progetto';

  @override
  String get noProject => 'Nessun progetto';

  @override
  String get allTickets => 'Tutti i ticket';

  @override
  String get projectNamePlaceholder => 'Nome del progetto';

  @override
  String get projectDescriptionPlaceholder => 'Descrizione (facoltativa)';

  @override
  String get projectColorLabel => 'Colore';

  @override
  String get noProjectsYet => 'Ancora nessun progetto';

  @override
  String get projectTicketsEmpty => 'Ancora nessun ticket in questo progetto';

  @override
  String get createProject => 'Crea progetto';

  @override
  String projectProgress(int done, int total) {
    return '$done di $total completati';
  }

  @override
  String deleteProjectConfirm(String name) {
    return 'Eliminare «$name»? I suoi ticket vengono mantenuti e rimossi dal progetto.';
  }

  @override
  String get projectStatusActive => 'Attivo';

  @override
  String get projectStatusCompleted => 'Completato';

  @override
  String get projectStatusArchived => 'Archiviato';

  @override
  String get markProjectCompleted => 'Segna come completato';

  @override
  String get markProjectActive => 'Segna come attivo';

  @override
  String get archiveProject => 'Archivia';

  @override
  String get restoreProject => 'Ripristina';

  @override
  String get relations => 'Relazioni';

  @override
  String get relateTo => 'Collega a';

  @override
  String get relationSubIssueOf => 'Sotto-attività di…';

  @override
  String get relationParentOf => 'Padre di…';

  @override
  String get relationBlockedBy => 'Bloccato da…';

  @override
  String get relationBlocking => 'Blocca…';

  @override
  String get relationRelatedTo => 'Correlato a…';

  @override
  String get relationDuplicateOf => 'Duplicato di…';

  @override
  String get relationGroupParent => 'Padre';

  @override
  String get relationGroupSubIssues => 'Sotto-attività';

  @override
  String get relationGroupBlockedBy => 'Bloccato da';

  @override
  String get relationGroupBlocking => 'Blocca';

  @override
  String get relationGroupRelated => 'Correlato';

  @override
  String get relationGroupDuplicateOf => 'Duplicato di';

  @override
  String get relationGroupDuplicatedBy => 'Duplicato da';

  @override
  String get copyId => 'Copia ID';

  @override
  String get ticketIdCopied => 'ID del ticket copiato';

  @override
  String get selectTicket => 'Seleziona un ticket';

  @override
  String get searchTicketsHint => 'Cerca ticket…';

  @override
  String get noMatchingTickets => 'Nessun ticket corrispondente';

  @override
  String get addToProject => 'Aggiungi al progetto';

  @override
  String get clearAll => 'Cancella tutto';

  @override
  String agentsRunningCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count agenti in esecuzione',
      one: '1 agente in esecuzione',
    );
    return '$_temp0';
  }

  @override
  String blockedCountLabel(int count) {
    return '$count bloccati';
  }

  @override
  String needsYouCountLabel(int count) {
    return '$count per te';
  }

  @override
  String reviewSummary(int prs, int repos) {
    String _temp0 = intl.Intl.pluralLogic(
      prs,
      locale: localeName,
      other: '$prs PR in attesa',
      one: '1 PR in attesa',
    );
    String _temp1 = intl.Intl.pluralLogic(
      repos,
      locale: localeName,
      other: '$repos repository',
      one: '1 repository',
    );
    return '$_temp0 della tua revisione in $_temp1';
  }

  @override
  String get staleLabel => 'Obsoleta';

  @override
  String stepsProgress(int done, int total) {
    return '$done di $total passaggi';
  }

  @override
  String workspaceEyebrow(String name) {
    return 'Spazio $name';
  }

  @override
  String get pipelineTriggerNode => 'Trigger';

  @override
  String get workspaceSettings => 'Impostazioni dello spazio di lavoro';

  @override
  String get manageWorkspacesSubtitle =>
      'Rinomina uno spazio di lavoro e cambia il suo simbolo: selezionane uno a sinistra per modificarlo.';

  @override
  String workspaceCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count spazi di lavoro',
      one: '1 spazio di lavoro',
      zero: 'Nessuno spazio di lavoro',
    );
    return '$_temp0';
  }

  @override
  String workspaceReposAgents(int repos, int agents) {
    String _temp0 = intl.Intl.pluralLogic(
      repos,
      locale: localeName,
      other: '$repos repo',
      one: '1 repo',
      zero: 'Nessun repo',
    );
    String _temp1 = intl.Intl.pluralLogic(
      agents,
      locale: localeName,
      other: '$agents agenti',
      one: '1 agente',
      zero: '0 agenti',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String get identity => 'Identità';

  @override
  String get uploadImage => 'Carica immagine';

  @override
  String get failedToSaveLogo =>
      'Impossibile salvare il logo. Verifica che l\'app possa leggere il file selezionato.';

  @override
  String get workspaceLogoHint =>
      'PNG, JPG o GIF fino a 2 MB. Altrimenti useremo l\'iniziale dello spazio di lavoro.';

  @override
  String get workspaceNameFieldHelp =>
      'Mostrato nel selettore, nel percorso di navigazione e in ogni schermata.';

  @override
  String get dangerZone => 'Zona pericolosa';

  @override
  String get deleteThisWorkspace => 'Elimina questo spazio di lavoro';

  @override
  String deleteWorkspaceLongDescription(String name) {
    return 'Rimuove definitivamente $name, le sue connessioni ai repository, gli agenti e la memoria. L\'operazione non può essere annullata.';
  }

  @override
  String get discard => 'Annulla';

  @override
  String discardChangesQuestion(String name) {
    return 'Vuoi annullare le modifiche non salvate a $name?';
  }

  @override
  String get workspaceUpdated => 'Spazio di lavoro aggiornato';

  @override
  String get editTitle => 'Modifica titolo';

  @override
  String get editDescription => 'Modifica descrizione';

  @override
  String get addDescription => 'Aggiungi una descrizione';

  @override
  String get prTitlePlaceholder => 'Titolo';

  @override
  String get prBodyPlaceholder => 'Aggiungi una descrizione';

  @override
  String get write => 'Scrivi';

  @override
  String get overview => 'Panoramica';

  @override
  String get filesTabShort => 'File';

  @override
  String get noFilesChanged => 'Nessun file modificato';

  @override
  String get diff => 'Diff';

  @override
  String get preview => 'Anteprima';

  @override
  String get outdated => 'Obsoleto';

  @override
  String get outdatedComments => 'Commenti obsoleti';

  @override
  String outdatedCountLabel(int count) {
    return '$count obsoleti';
  }

  @override
  String get prTemplateLabel => 'Modello';

  @override
  String get prTemplateDefault => 'Predefinito';

  @override
  String get addReviewers => 'Aggiungi revisori';

  @override
  String get addAssignees => 'Aggiungi assegnatari';

  @override
  String get searchUsers => 'Cerca persone…';

  @override
  String get searchReviewers => 'Cerca persone e team…';

  @override
  String get usersSectionLabel => 'Persone';

  @override
  String get teamsSectionLabel => 'Team';

  @override
  String get suggestedReviewers => 'Revisori suggeriti';

  @override
  String get noMatchingUsers => 'Nessuna persona corrispondente';

  @override
  String get noMatchingReviewers => 'Nessun risultato';

  @override
  String addCount(int count) {
    return 'Aggiungi ($count)';
  }

  @override
  String get requiredByCodeOwners => 'Richiesto dai proprietari del codice';

  @override
  String reviewedOnBehalfOf(String login) {
    return 'tramite $login';
  }

  @override
  String get team => 'Team';

  @override
  String get markdownBold => 'Grassetto';

  @override
  String get markdownItalic => 'Corsivo';

  @override
  String get markdownHeading => 'Titolo';

  @override
  String get markdownBulletList => 'Elenco puntato';

  @override
  String get markdownChecklist => 'Lista di controllo';

  @override
  String get markdownCode => 'Codice';

  @override
  String get markdownLink => 'Collegamento';

  @override
  String get markdownQuote => 'Citazione';

  @override
  String failedToUpdateTitle(String error) {
    return 'Impossibile aggiornare il titolo: $error';
  }

  @override
  String failedToUpdateDescription(String error) {
    return 'Impossibile aggiornare la descrizione: $error';
  }

  @override
  String failedToUpdateReviewers(String error) {
    return 'Impossibile aggiornare i revisori: $error';
  }

  @override
  String failedToUpdateAssignees(String error) {
    return 'Impossibile aggiornare gli assegnatari: $error';
  }

  @override
  String get discardChangesConfirm => 'Vuoi annullare le modifiche?';

  @override
  String get newPr => 'Nuova PR';

  @override
  String get openPullRequest => 'Apri una pull request';

  @override
  String get composePrSubtitle =>
      'Da un branch che hai pushato — senza agenti né ticket';

  @override
  String get createAsDraft => 'Crea come bozza';

  @override
  String get composePrNoRepo => 'Nessun repository GitHub selezionato';

  @override
  String get composePrNoRepoHint =>
      'Seleziona uno spazio di lavoro con un repository collegato a GitHub per aprire una pull request.';

  @override
  String get composePrPickBranches =>
      'Scegli un branch di base e uno da confrontare per visualizzare l\'anteprima delle modifiche.';

  @override
  String get composePrNothingToCompare =>
      'Non ci sono modifiche tra questi branch.';

  @override
  String get repository => 'Repository';

  @override
  String get baseBranchLabel => 'Base';

  @override
  String get compareBranchLabel => 'Confronta';

  @override
  String get selectBranch => 'Seleziona un branch';

  @override
  String get navMeetings => 'Riunioni';

  @override
  String get meetingsNoWorkspace =>
      'Seleziona uno spazio di lavoro per vedere le riunioni.';

  @override
  String get meetingsEmpty => 'Ancora nessuna riunione';

  @override
  String get meetingsEmptyHint =>
      'Registra la tua prima riunione: l\'audio resta su questo dispositivo e l\'agente la trasforma in note, decisioni e attività.';

  @override
  String get meetingsStartRecording => 'Avvia registrazione';

  @override
  String get meetingsStopRecording => 'Interrompi registrazione';

  @override
  String get meetingsProcessing => 'Riepilogo in corso…';

  @override
  String get meetingEnhancedNotes => 'Note arricchite';

  @override
  String get meetingYourNotes => 'Le tue note';

  @override
  String get meetingNotesHint =>
      'Prendi appunti veloci: l\'agente li amplierà dopo la riunione.';

  @override
  String get meetingTranscriptTitle => 'Trascrizione';

  @override
  String get meetingNoTranscriptYet =>
      'La trascrizione appare qui mentre le persone parlano.';

  @override
  String get meetingSpeakerMe => 'Tu';

  @override
  String get meetingSpeakerThem => 'Loro';

  @override
  String get meetingStatusRecording => 'Registrazione';

  @override
  String get meetingStatusProcessing => 'Elaborazione';

  @override
  String get meetingStatusDone => 'Completato';

  @override
  String get meetingStatusFailed => 'Non riuscito';

  @override
  String get keybindingGoToMeetings => 'Vai alle riunioni';

  @override
  String get keybindingNavigateToTheMeetingsDescription =>
      'Vai all\'elenco delle riunioni';

  @override
  String get meetingsSubtitle =>
      'Cattura locale delle tue riunioni. Captiamo l\'audio della riunione e il tuo microfono, trascriviamo sul dispositivo e lasciamo che un agente trasformi i tuoi appunti sparsi in decisioni e attività — nessun bot si unisce mai alla chiamata.';

  @override
  String get meetingsRecordMeeting => 'Registra riunione';

  @override
  String meetingsProcessingNow(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count in elaborazione ora',
      one: '1 in elaborazione ora',
    );
    return '$_temp0';
  }

  @override
  String get meetingsStatThisWeek => 'Questa settimana';

  @override
  String get meetingsStatThisWeekUnit => 'riunioni catturate';

  @override
  String get meetingsStatRecorded => 'Registrato';

  @override
  String get meetingsStatRecordedUnit => 'trascritto localmente';

  @override
  String get meetingsStatOpen => 'Aperte';

  @override
  String get meetingsStatOpenUnit => 'attività in sospeso';

  @override
  String get meetingsStatLogged => 'Registrate';

  @override
  String get meetingsStatLoggedUnit => 'decisioni estratte';

  @override
  String get meetingsCaptureTitle =>
      'La cattura dell\'audio di sistema senza driver è pronta.';

  @override
  String get meetingsCaptureBody =>
      'Control Center capta l\'uscita degli altoparlanti dell\'app in cui ti trovi — Slack Huddle, Meet, Zoom, Tuple — oltre al microfono, e decodifica entrambi i flussi su questo dispositivo.';

  @override
  String get meetingsCapturePermission => 'Autorizzazione concessa';

  @override
  String get meetingsCaptureOnDevice => '100% sul dispositivo';

  @override
  String get meetingsCaptureNoBot => 'Nessun bot si unisce';

  @override
  String get meetingsScopeAll => 'Tutte le riunioni';

  @override
  String get meetingsFilterAll => 'Tutte';

  @override
  String get meetingsFilterDone => 'Completate';

  @override
  String get meetingsFilterProcessing => 'In corso';

  @override
  String get meetingsSearchHint => 'Filtra per titolo, persona, app…';

  @override
  String get meetingsBucketToday => 'Oggi';

  @override
  String get meetingsBucketYesterday => 'Ieri';

  @override
  String get meetingsBucketEarlierThisWeek => 'Prima questa settimana';

  @override
  String get meetingsBucketLastWeek => 'La settimana scorsa';

  @override
  String get meetingsBucketOlder => 'Più vecchie';

  @override
  String meetingsDecisionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count decisioni',
      one: '1 decisione',
    );
    return '$_temp0';
  }

  @override
  String meetingsActionItemsProgress(int done, int total) {
    return '$done / $total attività';
  }

  @override
  String get meetingsEnhancedPill => 'arricchita';

  @override
  String get meetingsTranscribing => 'trascrizione e sintesi…';

  @override
  String get meetingsOpenAction => 'Apri';

  @override
  String get meetingsStopProcessing => 'Interrompi';

  @override
  String get meetingsStillTranscribing =>
      'Trascrizione in corso — il riepilogo apparirà al termine.';

  @override
  String get meetingsNoMatch => 'Nessuna riunione corrisponde';

  @override
  String get meetingsNoMatchHint =>
      'Prova un altro filtro o termine di ricerca.';

  @override
  String get meetingBackAllMeetings => 'Tutte le riunioni';

  @override
  String meetingPeopleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count persone',
      one: '1 persona',
    );
    return '$_temp0';
  }

  @override
  String get meetingReRunSummary => 'Rigenera riepilogo';

  @override
  String get meetingExport => 'Esporta';

  @override
  String get meetingAugmentingBanner =>
      'Arricchimento degli appunti dalla trascrizione — estrazione di decisioni e attività…';

  @override
  String get meetingTabNotes => 'Note';

  @override
  String get meetingTabTranscript => 'Trascrizione';

  @override
  String get meetingTabActionItems => 'Attività';

  @override
  String get meetingTabDecisions => 'Decisioni';

  @override
  String get meetingNotesEnhancedToggle => 'Arricchite';

  @override
  String get meetingNotesYoursToggle => 'Le tue note';

  @override
  String get meetingEnhancedByAgent =>
      'Arricchito dall\'agente · dalla trascrizione';

  @override
  String get meetingEnhancedPending =>
      'L\'agente sta ancora lavorando a questo riepilogo.';

  @override
  String get meetingNotesEmpty => 'Ancora nessuna nota arricchita.';

  @override
  String get meetingNotesSavedLocally => 'Salvato localmente';

  @override
  String get meetingNotesSaving => 'Salvataggio…';

  @override
  String get meetingViewFullTranscript => 'Vedi la trascrizione completa';

  @override
  String get meetingTranscriptSearchHint => 'Cerca nella trascrizione…';

  @override
  String get meetingSpeakerEveryone => 'Tutti';

  @override
  String get meetingSpeakerOthers => 'Altri';

  @override
  String get meetingTranscriptEmpty => 'Ancora nessuna trascrizione.';

  @override
  String get meetingActionItemsEmpty => 'Nessuna attività estratta.';

  @override
  String get meetingActionItemFrom => 'da questa riunione';

  @override
  String get meetingCreateTicket => 'Crea ticket';

  @override
  String meetingTicketCreated(String key) {
    return 'Ticket $key creato e inviato.';
  }

  @override
  String get meetingTicketFailed => 'Impossibile creare il ticket.';

  @override
  String get meetingDecisionsEmpty => 'Nessuna decisione registrata.';

  @override
  String get meetingEditTitle => 'Modifica titolo';

  @override
  String get meetingTitleLabel => 'Titolo';

  @override
  String get meetingAddActionItem => 'Aggiungi azione';

  @override
  String get meetingEditActionItem => 'Modifica azione';

  @override
  String get meetingDeleteActionItem => 'Elimina azione';

  @override
  String get meetingActionItemContentLabel => 'Azione';

  @override
  String get meetingActionItemContentHint => 'Cosa bisogna fare?';

  @override
  String get meetingActionItemOwnerLabel => 'Responsabile';

  @override
  String get meetingActionItemOwnerHint => 'Chi se ne occupa? (facoltativo)';

  @override
  String get meetingAddDecision => 'Aggiungi decisione';

  @override
  String get meetingEditDecision => 'Modifica decisione';

  @override
  String get meetingDeleteDecision => 'Elimina decisione';

  @override
  String get meetingDecisionContentLabel => 'Decisione';

  @override
  String get meetingDecisionContentHint => 'Cosa è stato deciso?';

  @override
  String get meetingReRunStarted =>
      'Rigenerazione della sintesi sulla trascrizione…';

  @override
  String get meetingReRunDone => 'Riepilogo aggiornato.';

  @override
  String get meetingReRunNoTranscript =>
      'Non c\'è ancora una trascrizione da riepilogare.';

  @override
  String get meetingExportCopied =>
      'Note copiate negli appunti in formato Markdown.';

  @override
  String get meetingExportSaved => 'Riunione esportata.';

  @override
  String meetingExportFailed(String error) {
    return 'Esportazione non riuscita: $error';
  }

  @override
  String get meetingExportNothing => 'Non c\'è ancora nulla da esportare.';

  @override
  String get meetingPlaybackPlay => 'Riproduci';

  @override
  String get meetingPlaybackPause => 'Pausa';

  @override
  String get meetingPlaybackUnavailable =>
      'La riproduzione audio non è disponibile su questo dispositivo.';

  @override
  String get meetingDetectedTitle => 'Riunione rilevata';

  @override
  String meetingDetectedSubtitle(String label) {
    return 'Sembra che «$label» sia in corso. Registrarla?';
  }

  @override
  String get meetingDetectedSubtitleGeneric =>
      'Sembra che sia in corso una riunione. Registrarla?';

  @override
  String get meetingDetectedRecord => 'Registra';

  @override
  String get meetingDetectedDismiss => 'Ignora';

  @override
  String get meetingAutoStopTitle =>
      'Questa riunione sembra finita. Interrompere la registrazione?';

  @override
  String get meetingAutoStopStop => 'Interrompi';

  @override
  String get meetingAutoStopKeep => 'Continua a registrare';

  @override
  String get meetingAutoDetect => 'Rilevamento automatico delle riunioni';

  @override
  String get meetingAutoDetectDescription =>
      'Controlla il calendario e le app di videoconferenza e propone di registrare all\'inizio di una riunione.';

  @override
  String get meetingsRecordingCrumb => 'Registrazione…';

  @override
  String get meetingRecordTitleHint => 'Titolo della riunione';

  @override
  String get meetingRecordTappingLabel => 'Captazione:';

  @override
  String get meetingRecordMic => 'Microfono';

  @override
  String get meetingRecordSystemAudio => 'Audio di sistema';

  @override
  String get meetingRecordPause => 'Pausa';

  @override
  String get meetingRecordResume => 'Riprendi';

  @override
  String get meetingRecordStop => 'Ferma e riepiloga';

  @override
  String get meetingRecordYourNotes => 'Le tue note';

  @override
  String get meetingRecordNotesTagline =>
      'annota l\'essenziale — l\'agente completa il resto';

  @override
  String get meetingRecordNotesPlaceholder =>
      'Scrivi mentre ascolti. Bastano pochi frammenti — dopo lo stop, l\'agente li espande usando la trascrizione.';

  @override
  String get meetingRecordLiveTranscript => 'Trascrizione in tempo reale';

  @override
  String get meetingRecordDecoding => 'decodifica sul dispositivo';

  @override
  String get meetingRecordListening =>
      'In ascolto… il parlato apparirà qui entro un secondo o due, etichettato Tu / Altri.';

  @override
  String get meetingRecordPausedHint =>
      'In pausa — l\'audio viene ignorato finché non riprendi.';

  @override
  String get meetingRecordNotActive => 'Nessuna registrazione attiva.';

  @override
  String get meetingHudRecording => 'registrazione';

  @override
  String get meetingHudPaused => 'in pausa';

  @override
  String get meetingHudOpen => 'Apri';

  @override
  String get meetingHudStop => 'Ferma';

  @override
  String get meetingToolbarPopOut => 'Stacca';

  @override
  String get meetingToolbarHoldToStop =>
      'Tieni premuto per fermare la registrazione';

  @override
  String get meetingToolbarSemanticLabel => 'Barra di registrazione riunione';

  @override
  String get orchestrate => 'Orchestra';

  @override
  String get orchestrationUnavailable => 'Orchestrazione non disponibile';

  @override
  String get orchestrationApprove => 'Approva piano';

  @override
  String get orchestrationReject => 'Rifiuta';

  @override
  String get orchestrationCancel => 'Annulla orchestrazione';

  @override
  String orchestrationRolesSummary(int count, int hires) {
    return '$count ruoli — $hires nuove assunzioni';
  }

  @override
  String orchestrationSubTicketsSummary(int count) {
    return '$count sotto-ticket';
  }

  @override
  String orchestrationEstimatedCost(String amount) {
    return 'Costo stimato: $amount \$';
  }

  @override
  String orchestrationProgress(int done, int total) {
    return '$done/$total sotto-ticket completati';
  }

  @override
  String get orchestrationStatusProposed => 'Proposto';

  @override
  String get orchestrationStatusApproved => 'Approvato';

  @override
  String get orchestrationStatusExecuting => 'In esecuzione';

  @override
  String get orchestrationStatusSynthesizing => 'Sintesi';

  @override
  String get orchestrationStatusCompleted => 'Completato';

  @override
  String get orchestrationStatusFailed => 'Fallito';

  @override
  String get orchestrationStatusCancelled => 'Annullato';

  @override
  String get messageFailed => 'Esecuzione fallita';

  @override
  String get turnLimitReached =>
      'Limite di turni raggiunto — rispondi per continuare';

  @override
  String get retried => 'Riprovato';

  @override
  String replyingTo(String name) {
    return 'in risposta a $name';
  }

  @override
  String get recentRuns => 'Esecuzioni recenti';

  @override
  String get runIdCopied => 'Id esecuzione copiato';

  @override
  String get copyRunId => 'Copia id esecuzione';

  @override
  String get copyLogPath => 'Copia percorso del log';

  @override
  String get silenceTimeoutLabel => 'Timeout di silenzio (minuti)';

  @override
  String get silenceTimeoutHint =>
      'es. 15 — termina un run dopo questo tempo senza output';

  @override
  String get ticketOutput => 'Output';

  @override
  String missingRequiredField(String field) {
    return 'Campo obbligatorio mancante: $field';
  }

  @override
  String get capabilityJsonMode => 'Modalità JSON';

  @override
  String get capabilityModelSelection => 'Selezione modello';

  @override
  String get transcriptThinking => 'Sto pensando…';

  @override
  String transcriptThoughtFor(String duration) {
    return 'Ha pensato per $duration';
  }

  @override
  String get transcriptStatusMakingEdits => 'Modifiche in corso…';

  @override
  String get transcriptStatusReadingFiles => 'Lettura dei file…';

  @override
  String get transcriptStatusSearching => 'Ricerca nel codice…';

  @override
  String get transcriptStatusRunningCommands => 'Esecuzione comandi…';

  @override
  String get transcriptStatusResponding => 'Risposta…';

  @override
  String transcriptStatusRunningTool(String tool) {
    return 'Esecuzione di $tool…';
  }

  @override
  String get transcriptInput => 'Input';

  @override
  String get transcriptOutput => 'Output';

  @override
  String get transcriptShowMore => 'Mostra altro';

  @override
  String get transcriptShowLess => 'Mostra meno';

  @override
  String get transcriptErrorLabel => 'Errore';

  @override
  String get transcriptInterrupted => 'Interrotto';

  @override
  String get transcriptSandboxBlocked => 'La sandbox ha bloccato un\'\'azione';

  @override
  String get transcriptOutputTruncated => 'Output troncato';

  @override
  String transcriptShowFullOutput(int kb) {
    return 'Mostra tutto l\'\'output (+$kb KB)';
  }

  @override
  String transcriptShowAllLines(int count) {
    return 'Mostra tutte le $count righe';
  }

  @override
  String transcriptShowingFirstLines(int count) {
    return 'Mostrate le prime $count righe';
  }

  @override
  String get transcriptGrepNoMatches => 'Nessuna corrispondenza';

  @override
  String transcriptGrepStats(int matches, int files) {
    String _temp0 = intl.Intl.pluralLogic(
      matches,
      locale: localeName,
      other: '$matches corrispondenze',
      one: '1 corrispondenza',
    );
    String _temp1 = intl.Intl.pluralLogic(
      files,
      locale: localeName,
      other: '$files file',
      one: '1 file',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String transcriptDiffStats(int adds, int dels) {
    return '$adds aggiunte, $dels eliminazioni';
  }

  @override
  String meetingSpeakerPerson(int number) {
    return 'Persona $number';
  }

  @override
  String get meetingRenameSpeakerTooltip => 'Rinomina interlocutore';

  @override
  String get meetingRenameSpeakerTitle => 'Rinomina interlocutore';

  @override
  String get meetingSpeakerNameLabel => 'Nome';

  @override
  String get meetingSpeakerSuggestFromCalendar =>
      'Tra gli invitati di questa riunione';

  @override
  String get meetingRenameSpeakerApplyAll =>
      'Applica a tutti i blocchi di questo interlocutore';

  @override
  String get meetingRenameSpeakerScopeHint =>
      'Se disattivato, viene rinominata solo la riga selezionata.';

  @override
  String get meetingLinkEvent => 'Collega a un evento';

  @override
  String get meetingChangeEvent => 'Cambia evento';

  @override
  String get meetingLinkEventTitle => 'Collega a un evento del calendario';

  @override
  String get meetingLinkEventSearchHint => 'Cerca eventi';

  @override
  String get meetingLinkEventEmpty =>
      'Nessun evento del calendario nelle vicinanze';

  @override
  String get meetingUnlinkEvent => 'Rimuovi collegamento';

  @override
  String get calendarLinkExistingMeeting => 'Collega a una riunione esistente';

  @override
  String get calendarLinkMeetingTitle => 'Collega una riunione';

  @override
  String get calendarLinkMeetingSearchHint => 'Cerca riunioni';

  @override
  String get calendarLinkMeetingEmpty => 'Nessuna riunione da collegare';

  @override
  String get meetingRenameSpeakerFailed =>
      'Impossibile rinominare l\'interlocutore';

  @override
  String get calendarLinkUpdateFailed =>
      'Impossibile aggiornare il collegamento con il calendario';

  @override
  String get rename => 'Rinomina';

  @override
  String get notNow => 'Non ora';

  @override
  String get meetingSaveVoiceProfileTitle => 'Salvare il profilo vocale?';

  @override
  String meetingSaveVoiceProfileBody(String name) {
    return 'Riconosci $name automaticamente nelle prossime riunioni salvando la sua impronta vocale.';
  }

  @override
  String meetingVoiceProfileSaved(String name) {
    return 'Profilo vocale salvato per $name';
  }

  @override
  String get meetingVoiceProfileSaveFailed =>
      'Impossibile salvare il profilo vocale';

  @override
  String get voiceProfilesSection => 'Profili vocali';

  @override
  String get voiceProfilesDescription =>
      'Le voci salvate vengono riconosciute automaticamente nelle prossime riunioni.';

  @override
  String get voiceProfilesEmpty =>
      'Nessuna voce salvata. Assegna un nome a un partecipante nella trascrizione di una riunione, poi scegli «Salva profilo vocale».';

  @override
  String voiceProfileSamples(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count campioni',
      one: '1 campione',
    );
    return '$_temp0';
  }

  @override
  String get renameVoiceProfileTitle => 'Rinomina profilo vocale';

  @override
  String get deleteVoiceProfileTitle => 'Eliminare il profilo vocale?';

  @override
  String deleteVoiceProfileBody(String name) {
    return 'Smettere di riconoscere $name? La sua impronta vocale salvata verrà rimossa. I nomi già applicati nelle riunioni passate vengono mantenuti.';
  }

  @override
  String get remoteControl => 'Controllo remoto';

  @override
  String get remoteControlListening => 'In attesa di dispositivi';

  @override
  String get remoteControlListenerStopped => 'Listener fermato';

  @override
  String get remoteControlStartToAccept =>
      'Avvia il listener per accettare le connessioni del telefono.';

  @override
  String get remoteControlStartOnLaunch => 'Avvia al lancio';

  @override
  String get remoteControlWhenOffStaysStopped =>
      'Se disattivato, il listener resta fermo finché non lo avvii.';

  @override
  String get remoteControlRestartToApply =>
      'Riavvia il listener per applicare le modifiche.';

  @override
  String get remoteControlSignalingUrl => 'URL del broker di segnalazione';

  @override
  String get remoteControlSignalingHint =>
      'Broker wss:// che inoltra solo l\'handshake di accoppiamento.';

  @override
  String get remoteControlStunServers => 'Server STUN';

  @override
  String get remoteControlStunHint =>
      'URL STUN separati da virgole. Nessun TURN per scelta.';

  @override
  String get remoteControlPwaHost => 'Host dell\'app telefono';

  @override
  String get remoteControlPwaHostHint =>
      'Dove è ospitata la web app del telefono; codificato nel QR di accoppiamento.';

  @override
  String get remoteControlNotConfigured =>
      'Aggiungi un URL di segnalazione e un host dell\'app per abilitare l\'accoppiamento.';

  @override
  String get remoteControlPairDevice => 'Accoppia un dispositivo';

  @override
  String get remoteControlScanQr =>
      'Scansiona questo codice con la fotocamera del telefono.';

  @override
  String get remoteControlAllWorkspacesWarning =>
      'Questo dispositivo potrà accedere a tutti gli spazi di lavoro di questo Mac.';

  @override
  String get remoteControlCopyLink => 'Copia link';

  @override
  String get remoteControlWantsToConnect => 'Vuole connettersi';

  @override
  String get remoteControlApproveDevice => 'Approva dispositivo';

  @override
  String get remoteControlDeviceConnected =>
      'Dispositivo connesso: approvalo per completare l\'associazione.';

  @override
  String remoteControlQrExpiresIn(int minutes) {
    return 'Scade tra $minutes min';
  }

  @override
  String get remoteControlPairedDevices => 'Dispositivi accoppiati';

  @override
  String get remoteControlNoPairedDevices => 'Nessun dispositivo accoppiato.';

  @override
  String get remoteControlPending => 'In attesa di conferma';

  @override
  String get remoteControlActive => 'Attivo';

  @override
  String get remoteControlRevoked => 'Revocato';

  @override
  String get remoteControlRevoke => 'Revoca';

  @override
  String get remoteControlConfirmDevice => 'Confirma dispositivo';

  @override
  String get remoteControlRevokeConfirm =>
      'Revocare questo dispositivo? Verrà disconnesso immediatamente.';

  @override
  String get devicesSettingsDescription =>
      'Associa e gestisci i telefoni che possono controllare quest\'app in remoto.';

  @override
  String get connectedLabel => 'Connesso';

  @override
  String get ideTabGeneral => 'Generale';

  @override
  String get ideTabExplorer => 'Esplora';

  @override
  String get ideTabSourceControl => 'Controllo sorgente';

  @override
  String get ideTabPullRequests => 'Pull request';

  @override
  String get generalSectionTodos => 'Attività';

  @override
  String get generalSectionGoals => 'Obiettivi';

  @override
  String get goalRunStatusActive => 'Attivo';

  @override
  String get goalRunStatusPaused => 'In pausa';

  @override
  String get goalRunStatusCompleted => 'Completato';

  @override
  String get goalRunStatusFailed => 'Non riuscito';

  @override
  String get goalRunStatusCancelled => 'Annullato';

  @override
  String get goalRunStatusBudgetExhausted => 'Budget esaurito';

  @override
  String goalRunProgress(int run, int max, String cost, String cap) {
    return 'Esecuzione $run di $max · $cost di $cap';
  }

  @override
  String goalRunProgressNoCap(int run, String cost, String cap) {
    return 'Esecuzione $run · $cost di $cap';
  }

  @override
  String goalRunDeadline(String deadline) {
    return 'Scadenza: $deadline';
  }

  @override
  String get goalRunPause => 'Metti in pausa l\'obiettivo';

  @override
  String get goalRunResume => 'Riprendi l\'obiettivo';

  @override
  String goalRunResumeRaise(String cap) {
    return 'Riprendi · aumenta limite a $cap';
  }

  @override
  String get goalRunStop => 'Ferma l\'obiettivo';

  @override
  String get generalSectionPlan => 'Piano';

  @override
  String get generalSectionAgents => 'Agenti';

  @override
  String get generalSectionTerminals => 'Terminali';

  @override
  String get generalTodosEmpty => 'Nessuna attività';

  @override
  String get generalAgentsEmpty => 'Nessun agente in esecuzione';

  @override
  String get generalTerminalsEmpty => 'Nessun terminale aperto';

  @override
  String get pauseAgent => 'Metti in pausa l\'agente';

  @override
  String get resumeAgent => 'Riprendi l\'agente';

  @override
  String get agentCannotPause =>
      'Questo agente non può essere messo in pausa: fermalo invece.';

  @override
  String get goalClear => 'Cancella obiettivo';

  @override
  String get undoLabelGoalClear => 'cancella obiettivo';

  @override
  String get todoStatusPending => 'Non iniziato';

  @override
  String get todoStatusInProgress => 'In corso';

  @override
  String get todoStatusCompleted => 'Fatto';

  @override
  String get reorderTodo => 'Riordina attività';

  @override
  String get focusAgentRun => 'Metti a fuoco l\'esecuzione dell\'agente';

  @override
  String get focusTerminal => 'Metti a fuoco il terminale';

  @override
  String get todoEditorTitle => 'Modifica attività';

  @override
  String get todoEditorHint =>
      'Un elemento per riga. Usa - [ ] per da fare, - [~] per in corso, - [x] per fatto.';

  @override
  String get todoNeedsText => 'Aggiungi del testo dopo il comando';

  @override
  String get todoNotFound => 'Nessuna attività corrispondente';

  @override
  String get todoCleared => 'Elenco attività svuotato';

  @override
  String get todoNothingToCopy => 'Niente da copiare';

  @override
  String todoAdded(String content) {
    return 'Aggiunto \"$content\"';
  }

  @override
  String todoStarted(String content) {
    return 'Avviato \"$content\"';
  }

  @override
  String todoCompleted(String content) {
    return 'Completato \"$content\"';
  }

  @override
  String todoRemoved(String content) {
    return 'Rimosso \"$content\"';
  }

  @override
  String todoCopied(int count) {
    return '$count elementi copiati';
  }

  @override
  String todoImported(int count) {
    return '$count elementi importati';
  }

  @override
  String todoUnknownSubcommand(String name) {
    return 'Comando attività sconosciuto \"$name\"';
  }

  @override
  String generalAgentTurns(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count turni',
      one: '1 turno',
    );
    return '$_temp0';
  }

  @override
  String get terminal => 'Terminale';

  @override
  String get ideNewTerminal => 'Nuovo terminale';

  @override
  String get ideNewVmTerminal => 'Nuovo terminale (VM)';

  @override
  String get ideOpenChat => 'Apri chat';

  @override
  String get ideCloseTab => 'Chiudi scheda';

  @override
  String get ideSplitEditor => 'Dividi editor';

  @override
  String get ideSplitRight => 'Dividi a destra';

  @override
  String get ideSplitDown => 'Dividi in basso';

  @override
  String get ideSplitLeft => 'Dividi a sinistra';

  @override
  String get ideSplitUp => 'Dividi in alto';

  @override
  String get ideCloseGroup => 'Chiudi gruppo';

  @override
  String get ideCloseOthers => 'Chiudi le altre';

  @override
  String get ideCloseToRight => 'Chiudi a destra';

  @override
  String get ideCloseSaved => 'Chiudi salvate';

  @override
  String get ideCloseAll => 'Chiudi tutto';

  @override
  String get ideSplit => 'Dividi';

  @override
  String get ideToggleSidebar => 'Mostra/nascondi barra laterale';

  @override
  String get ideNewTab => 'Apri editor';

  @override
  String get ideReviewCode => 'Rivedi codice';

  @override
  String get ideReviewNoChanges => 'Nessuna modifica da rivedere';

  @override
  String get ideRevert => 'Ripristina';

  @override
  String get ideRevertConfirmTitle => 'Ripristina modifiche';

  @override
  String ideRevertConfirmMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count file',
      one: '1 file',
    );
    return 'Ripristinare $_temp0 a HEAD? Questo elimina le modifiche del worktree.';
  }

  @override
  String get ideRevertConfirmAction => 'Ripristina';

  @override
  String get ideRevertConfirmCancel => 'Annulla';

  @override
  String get ideRevertUntracked =>
      'I file non tracciati non possono essere ripristinati';

  @override
  String get ideRevertFailed =>
      'Impossibile ripristinare i file. Il worktree della conversazione potrebbe non essere disponibile.';

  @override
  String ideRevertSomeSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count file',
      one: '1 file',
    );
    return '$_temp0 non sono stati ripristinati (non tracciati).';
  }

  @override
  String get ideViewSource => 'Vedi sorgente';

  @override
  String get ideSearchMatchCase => 'Maiuscole/minuscole';

  @override
  String get ideSearchWholeWord => 'Parola intera';

  @override
  String get ideSearchRegex => 'Regex';

  @override
  String get ideSearchFilters => 'Filtri di ricerca';

  @override
  String get ideSearchFilesToInclude => 'File da includere';

  @override
  String get ideSearchFilesToExclude => 'File da escludere';

  @override
  String get ideNoOpenTabs => 'Nessuna scheda aperta — usa + per aprire';

  @override
  String get ideBrowserAddressHint => 'Inserisci un indirizzo o cerca';

  @override
  String get ideSimpleWebBrowser => 'Browser web semplice';

  @override
  String get ideWebBrowser => 'Browser web';

  @override
  String get ideBrowserEnterUrl =>
      'Inserisci un URL nella barra degli indirizzi per iniziare a navigare';

  @override
  String get ideCodeServer => 'Editor';

  @override
  String ideUnsavedChangesTitle(String fileName) {
    return 'Salvare le modifiche a $fileName?';
  }

  @override
  String get ideUnsavedChangesBody =>
      'Le modifiche andranno perse se non le salvi.';

  @override
  String get ideDontSave => 'Non salvare';

  @override
  String get editorAutoSave => 'Salvataggio automatico';

  @override
  String get editorAutoSaveDescription =>
      'Salva automaticamente le modifiche nell\'editor integrato.';

  @override
  String get editorAutoSaveOff => 'Disattivato';

  @override
  String get editorAutoSaveAfterDelay => 'Dopo un ritardo';

  @override
  String get editorAutoSaveOnFocusChange => 'Al cambio di focus';

  @override
  String get ideCodeServerUnavailable =>
      'Code-server non è disponibile su questo server';

  @override
  String get ideCodeServerUnavailableHint =>
      'Installa code-server (coder/code-server) sull\'host del server, quindi riapri l\'editor.';

  @override
  String get ideCodeServerInstalling => 'Preparazione dell\'editor…';

  @override
  String get ideCodeServerOpenInBrowser => 'Apri editor nel browser';

  @override
  String get ideCodeServerError => 'Impossibile aprire l\'editor';

  @override
  String get paneSuspendedCaption =>
      'Sospeso per risparmiare risorse — si ricarica quando torna in primo piano';

  @override
  String get ideFileSearchFailed => 'Impossibile cercare file';

  @override
  String get ideSearchFilename => 'Nome file';

  @override
  String get ideSearchContent => 'Contenuto';

  @override
  String get ideSearchInFiles => 'Cerca nei file';

  @override
  String get ideNoContentMatches => 'Nessuna corrispondenza';

  @override
  String get ideSourceControlCreatePr => 'Crea pull request';

  @override
  String get ideSourceControlNoChanges => 'Nessuna modifica';

  @override
  String ideSourceControlChangedFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count modificati',
      one: '1 modificato',
    );
    return '$_temp0';
  }

  @override
  String get ideConnectGithub => 'Connetti GitHub per vedere le pull request';

  @override
  String get ideNoConversationPr =>
      'Nessuna pull request per questa conversazione';

  @override
  String get ideFileLoading => 'Caricamento…';

  @override
  String get ideFileBinary => 'File binario';

  @override
  String get mcpExternalServers => 'Server MCP esterni';

  @override
  String get mcpExternalServersDescription =>
      'Connettiti a server MCP esterni (GitHub, Sentry, Postgres, automazione del browser). I server configurati per Claude, Cursor, VS Code e altri strumenti vengono rilevati automaticamente.';

  @override
  String get mcpApprovalMode => 'Approvazione strumenti';

  @override
  String get mcpApprovalModeDescription =>
      'Quali azioni vengono eseguite senza chiedere. Le letture sono sempre consentite; i livelli superiori richiedono conferma.';

  @override
  String get mcpApprovalAlwaysAsk => 'Chiedi sempre';

  @override
  String get mcpApprovalWrite => 'Approva le scritture';

  @override
  String get mcpApprovalYolo => 'Approva tutto';

  @override
  String get mcpNoExternalServers => 'Nessun server MCP esterno rilevato.';

  @override
  String get mcpAuthorize => 'Autorizza';

  @override
  String get mcpReconnect => 'Riconnetti';

  @override
  String get mcpExternalConnectionsNote =>
      'I server MCP esterni vengono eseguiti sul server degli agenti (condiviso da desktop e web). L\'autorizzazione dei server OAuth è disponibile solo sul desktop.';

  @override
  String mcpToolsSummary(int count) {
    return '$count strumenti';
  }

  @override
  String get mcpStatusConnected => 'Connesso';

  @override
  String get mcpStatusConnecting => 'Connessione…';

  @override
  String get mcpStatusNeedsAuth => 'Autorizzazione necessaria';

  @override
  String get mcpStatusFailed => 'Non riuscito';

  @override
  String get mcpStatusCircuitOpen => 'In pausa';

  @override
  String get mcpStatusDisabled => 'Disattivato';

  @override
  String get providersAndModels => 'Provider e modelli';

  @override
  String get providersAndModelsDescription =>
      'Elenca ogni provider che l\'agente integrato può usare: imposta una chiave API o accedi con il browser, consulta i modelli e i prezzi di ogni provider connesso e controlla quali provider può usare questo workspace.';

  @override
  String modelsCountFromProviders(int count, int providers) {
    return '$count modelli su $providers provider';
  }

  @override
  String get syncNow => 'Sincronizza';

  @override
  String syncNowResult(int applied, int failed) {
    return 'Sincronizzazione completata: $applied applicati, $failed non riusciti';
  }

  @override
  String syncNowFailed(String error) {
    return 'Sincronizzazione non riuscita: $error';
  }

  @override
  String get toggleDetails => 'Mostra dettagli';

  @override
  String get denied => 'Negato';

  @override
  String get allowed => 'Consentito';

  @override
  String allowProviderSemantic(String provider) {
    return 'Consenti $provider';
  }

  @override
  String enabledViaEnv(String key) {
    return 'Attivo tramite $key';
  }

  @override
  String enabledViaAccount(String service) {
    return 'Attivo tramite $service';
  }

  @override
  String get enabledLabel => 'Attivo';

  @override
  String get disabledLabel => 'Disattivato';

  @override
  String disabledSetEnvHint(String keys) {
    return 'Disattivato — imposta $keys o accedi';
  }

  @override
  String costPerMillion(String input, String output) {
    return '$input / $output per 1M';
  }

  @override
  String contextTokens(String tokens) {
    return 'contesto $tokens';
  }

  @override
  String get capabilityTools => 'Strumenti';

  @override
  String get capabilityVision => 'Visione';

  @override
  String get capabilityReasoning => 'Ragionamento';

  @override
  String get statusDeprecated => 'Obsoleto';

  @override
  String get usageAndCost => 'Utilizzo e costo';

  @override
  String get usageAndCostDescription =>
      'Spesa dei tuoi agenti negli ultimi 7 giorni, dai costi di esecuzione osservati.';

  @override
  String get noUsageYet => 'Nessun utilizzo registrato finora.';

  @override
  String get spentThisWeek => 'spesi questa settimana';

  @override
  String get subscriptionUsage => 'Utilizzo dell\'abbonamento';

  @override
  String get subscriptionUsageUnavailable => 'Non disponibile';

  @override
  String get subscriptionUsagePartiallyAvailable => 'Parzialmente disponibile';

  @override
  String resetsIn(String duration) {
    return 'Si azzera tra $duration';
  }

  @override
  String get feedbackHelpful => 'È stato utile';

  @override
  String get feedbackNotHelpful => 'Non è stato utile';

  @override
  String get modeChat => 'Chat';

  @override
  String get modePlan => 'Piano';

  @override
  String get modeReview => 'Revisione';

  @override
  String get modeOrchestrate => 'Orchestrazione';

  @override
  String get commandRules => 'Regole dei comandi';

  @override
  String get commandRulesDescription =>
      'Come Control Center decide quali comandi shell un agente può eseguire, in base alla modalità di conversazione.';

  @override
  String get scopeGlobal => 'Sempre';

  @override
  String get ruleDenied => 'Negato';

  @override
  String get ruleAsk => 'Chiedi prima';

  @override
  String get editorTheme => 'Tema dell\'editor';

  @override
  String get editorThemeDescription =>
      'Importa un tema di colori di VS Code in modo che il diff e l\'editor integrati corrispondano al tuo IDE.';

  @override
  String get editorThemePasteHint =>
      'Incolla il contenuto di un file di tema di colori di VS Code';

  @override
  String get editorThemeImported => 'Tema importato';

  @override
  String get editorThemeInvalid => 'Non sembra un tema VS Code valido';

  @override
  String get importTheme => 'Importa tema';

  @override
  String get clearTheme => 'Cancella tema';

  @override
  String get openInDiffViewer => 'Apri nel visualizzatore diff';

  @override
  String get shellCommand => 'Comando';

  @override
  String get shellOutput => 'Output';

  @override
  String get planReadyToImplement => 'Pronto per implementare?';

  @override
  String get planContinueHere => 'Continua qui';

  @override
  String get planContinueHereDescription =>
      'Implementa il piano in questa sessione';

  @override
  String get planStartNewSession => 'Avvia una nuova sessione';

  @override
  String get planStartNewSessionDescription =>
      'Implementa in una nuova sessione con un contesto pulito';

  @override
  String get revertToHere => 'Torna qui';

  @override
  String get revertConfirmBody =>
      'Nascondere i messaggi dopo questo punto e annullare le modifiche ai file dell\'agente fino a questo turno? Puoi annullare l\'operazione.';

  @override
  String get revert => 'Ripristina';

  @override
  String get revertedToHere => 'Ripristinato a questo punto';

  @override
  String get nothingToRevert => 'Niente da ripristinare';

  @override
  String get undoRevert => 'Annulla ripristino';

  @override
  String get revertUndone => 'Ripristino annullato';

  @override
  String get systemBehavior => 'Comportamento del sistema';

  @override
  String get keepAwakeTitle =>
      'Mantieni il computer attivo mentre gli agenti lavorano';

  @override
  String get keepAwakeOnSubtitle =>
      'Il computer non andrà in sospensione mentre un agente sta lavorando';

  @override
  String get keepAwakeOffSubtitle =>
      'Il computer può andare in sospensione anche mentre un agente sta lavorando';

  @override
  String get syncEngineSectionTitle => 'Motore di sincronizzazione';

  @override
  String get syncEngineDescription =>
      'Ticket, messaggistica e note si aggiornano in tempo reale tramite piccole modifiche incrementali anziché istantanee complete. Disattivando un interruttore quell\'archivio torna alla modalità a istantanea completa: ricarica l\'app perché la modifica abbia effetto.';

  @override
  String get syncEngineTicketsTitle => 'Ticket';

  @override
  String get syncEngineMessagingTitle => 'Messaggistica';

  @override
  String get syncEngineNotesTitle => 'Note';

  @override
  String get syncEngineOnSubtitle =>
      'La sincronizzazione in tempo reale è attiva';

  @override
  String get syncEngineOffSubtitle =>
      'In uso la sincronizzazione a istantanea completa';

  @override
  String get channels => 'Canali';

  @override
  String get channelsHomeDescription =>
      'Scegli un canale dall\'elenco o avviane uno nuovo.';

  @override
  String get noChannelsYet => 'Ancora nessun canale';

  @override
  String get newChannel => 'Nuovo canale';

  @override
  String get channelName => 'Nome del canale';

  @override
  String get channelReposHint => 'Repository da includere';

  @override
  String get ideSourceControl => 'Controllo del codice sorgente';

  @override
  String get stagedChanges => 'Modifiche in staging';

  @override
  String get changes => 'Modifiche';

  @override
  String get stageFile => 'Aggiungi in staging';

  @override
  String get unstageFile => 'Rimuovi dallo staging';

  @override
  String get stageAll => 'Aggiungi tutte le modifiche';

  @override
  String get unstageAll => 'Rimuovi tutto dallo staging';

  @override
  String get stageChangesToCommit => 'Aggiungi modifiche da confermare';

  @override
  String get syncToPrHead => 'Recupera gli ultimi commit della PR';

  @override
  String get syncedToPrHead => 'Sincronizzato con gli ultimi commit della PR';

  @override
  String get syncPrHeadDirty =>
      'Conferma o annulla le modifiche prima di sincronizzare';

  @override
  String get syncPrHeadFailed => 'Impossibile sincronizzare con la PR';

  @override
  String get channelLabel => 'Canale';

  @override
  String get keybindingNewChannel => 'Nuovo canale';

  @override
  String get keybindingCreateANewChannelDescription => 'Crea un nuovo canale';

  @override
  String get jumpToLatest => 'Vai al più recente';

  @override
  String get streaming => 'In corso';

  @override
  String get newMessages => 'Nuovo';

  @override
  String get copyLink => 'Copia link';

  @override
  String get linkCopied => 'Link copiato';

  @override
  String get messageTooFarBack => 'Il messaggio è troppo indietro';

  @override
  String newMessagesCount(int count) {
    return '$count nuovi';
  }

  @override
  String get agentResponding => 'Agente in risposta';

  @override
  String get agentFinished => 'Agente terminato';

  @override
  String get harnessConnectProviderForModels =>
      'Collega un provider per vedere i modelli.';

  @override
  String get providerSignOut => 'Esci';

  @override
  String get providerWaitingForDeviceCode =>
      'In attesa che tu confermi il codice nel browser…';

  @override
  String get providerDeviceCodeHint =>
      'Verifica che questo codice corrisponda a quello mostrato nel browser, poi approva.';

  @override
  String get providerPlanUsageLoading => 'Verifica dell’utilizzo del piano…';

  @override
  String get providerPlanUsageUnavailable =>
      'Questo piano non ha comunicato l’utilizzo.';

  @override
  String providerSignOutConfirmTitle(String provider) {
    return 'Uscire da $provider?';
  }

  @override
  String providerSignOutConfirmBody(String provider) {
    return 'Gli agenti che usano i modelli $provider smetteranno di funzionare finché non accedi di nuovo, il che richiede l’intero accesso da browser.';
  }

  @override
  String providerRemoveKeyConfirmTitle(String provider) {
    return 'Rimuovere la chiave API di $provider?';
  }

  @override
  String providerRemoveKeyConfirmBody(String provider) {
    return 'La chiave salvata viene eliminata e non potrà più essere mostrata. Gli agenti che usano i modelli $provider smetteranno di funzionare finché non ne incolli una nuova.';
  }

  @override
  String providerRemoveConfirmTitle(String provider) {
    return 'Rimuovere $provider?';
  }

  @override
  String providerRemoveConfirmBody(String provider) {
    return 'Il provider e la sua chiave salvata vengono eliminati. Gli agenti agganciati ai suoi modelli smetteranno di funzionare.';
  }

  @override
  String get providerApiKeyHint => 'Incolla una chiave API';

  @override
  String get providerApiKeyStoredHint =>
      'Incolla un\'altra chiave API per aggiungerla';

  @override
  String get providerAddAnotherAccount => 'Aggiungi un altro account';

  @override
  String get providerActiveBadge => 'Attiva';

  @override
  String get providerOauthAccountFallback => 'Account OAuth';

  @override
  String get providerApiKeyFallback => 'Chiave API';

  @override
  String get providerRemoveCredentialConfirmTitle =>
      'Rimuovere questa credenziale?';

  @override
  String get providerSignOutAccountConfirmTitle => 'Uscire da questo account?';

  @override
  String providerCredentialRemoveConfirmBody(String provider) {
    return 'Gli agenti che usano $provider passano alle sue altre chiavi e agli altri account. Se non ne resta nessuno, si fermano finché non ne aggiungi uno.';
  }

  @override
  String get providerBaseUrlHint => 'URL di base (facoltativo)';

  @override
  String get customProviders => 'Provider personalizzati';

  @override
  String get customProvidersDescription =>
      'Qualsiasi endpoint compatibile con OpenAI o Anthropic — Ollama, LM Studio, vLLM o un deployment privato — con una chiave API facoltativa.';

  @override
  String get addProvider => 'Aggiungi provider';

  @override
  String get noCustomProviders => 'Ancora nessun provider personalizzato.';

  @override
  String get providerNameLabel => 'Nome';

  @override
  String get apiTypeLabel => 'Tipo di API';

  @override
  String get providerBaseUrlLabel => 'URL di base';

  @override
  String get providerApiKeyOptionalHint => 'Chiave API (facoltativa)';

  @override
  String get dialectOpenAiCompatible => 'Compatibile con OpenAI';

  @override
  String get dialectAnthropicCompatible => 'Compatibile con Anthropic';

  @override
  String get removeProviderTooltip => 'Rimuovi provider';

  @override
  String get providerLogInWithBrowser => 'Accedi con il browser';

  @override
  String providerLoginDialogTitle(String provider) {
    return 'Accedi a $provider';
  }

  @override
  String get providerLabel => 'Provider';

  @override
  String get selectProviderToLogin => 'Seleziona un provider per accedere';

  @override
  String providerLoginFailed(String error) {
    return 'Accesso non riuscito: $error';
  }

  @override
  String get providerWaitingForBrowser =>
      'In attesa dell\'autorizzazione nel browser…';

  @override
  String get providerPasteCodeHint => 'Oppure incolla il codice dal browser';

  @override
  String get providerCompleteLogin => 'Completa';

  @override
  String get providerConnectedApiKey => 'Connesso tramite chiave API';

  @override
  String get providerConnectedOauth => 'Connesso';

  @override
  String providerConnectedAccount(String account) {
    return 'Connesso · $account';
  }

  @override
  String get providerLocalReady => 'Locale · pronto';

  @override
  String get providerNotConnected => 'Non connesso';

  @override
  String get preparingWorkspace => 'Preparazione dell area di lavoro…';

  @override
  String provisioningCloningRepo(String repo) {
    return 'Clonazione di $repo…';
  }

  @override
  String provisioningCheckingOutPr(String repo) {
    return 'Recupero della pull request in $repo…';
  }

  @override
  String provisioningSettingUpAgent(String agent) {
    return 'Configurazione dell agente $agent…';
  }

  @override
  String get workspacePrepFailed => 'Preparazione non riuscita';

  @override
  String messageWillSendWhenReady(int count) {
    return '$count messaggio/i inviato/i quando pronto';
  }

  @override
  String get membersNav => 'Membri';

  @override
  String get membersSettingsDescription =>
      'Persone con accesso a questo spazio di lavoro: elenco, inviti e registro di controllo';

  @override
  String get memberRosterLabel => 'Elenco dei membri';

  @override
  String get memberRepoAccessAction => 'Accesso ai repository';

  @override
  String memberRepoAccessTitle(String name) {
    return 'Accesso ai repository di $name';
  }

  @override
  String get roleOwner => 'Proprietario';

  @override
  String get roleAdmin => 'Admin';

  @override
  String get roleMember => 'Membro';

  @override
  String get roleViewer => 'Osservatore';

  @override
  String get roleGuest => 'Ospite';

  @override
  String get removeMemberTitle => 'Rimuovi membro';

  @override
  String removeMemberConfirm(String name) {
    return 'Rimuovere $name da questo spazio di lavoro? L\'accesso viene perso immediatamente.';
  }

  @override
  String get unknownUserLabel => 'Utente sconosciuto';

  @override
  String get inviteMember => 'Invita membro';

  @override
  String get inviteRepoAccessHeader => 'Accesso ai repository';

  @override
  String get inviteRepoAccessExplainer =>
      'Solo i repository selezionati vengono condivisi con l\'invitato, al livello scelto. Tutto il resto resta nascosto.';

  @override
  String get grantLevelRead => 'Lettura';

  @override
  String get grantLevelReview => 'Revisione';

  @override
  String get grantLevelWrite => 'Scrittura';

  @override
  String get inviteExpiryLabel => 'Scade tra';

  @override
  String get expiryOneDay => '1 giorno';

  @override
  String get expirySevenDays => '7 giorni';

  @override
  String get expiryThirtyDays => '30 giorni';

  @override
  String get createInviteAction => 'Crea invito';

  @override
  String get inviteOneTimeCodeLabel => 'Codice monouso';

  @override
  String get inviteCodeShownOnce =>
      'Questo codice viene mostrato una sola volta: copialo ora.';

  @override
  String get inviteLinkLabel => 'Link di invito';

  @override
  String get inviteRedeemHint =>
      'Condividi il codice con l\'invitato; lo riscatterà con l\'URL del tuo server.';

  @override
  String get inviteScanQr => 'Oppure scansiona per riscattare';

  @override
  String get inviteLoopbackWarningTitle =>
      'L\'invito punta a un indirizzo locale';

  @override
  String get inviteLoopbackWarningBody =>
      'I collaboratori su altre macchine non potranno raggiungere questo server. Avvia un tunnel (Impostazioni → Integrazioni → Condividi questo server) o connettiti alla tua rete per consentire agli utenti esterni di connettersi.';

  @override
  String get inviteStatusOpen => 'Aperto';

  @override
  String get inviteStatusUsed => 'Usato';

  @override
  String get inviteStatusRevoked => 'Revocato';

  @override
  String get inviteStatusExpired => 'Scaduto';

  @override
  String inviteCreatedTime(String time) {
    return 'Creato $time';
  }

  @override
  String inviteExpiresOn(String date) {
    return 'scade il $date';
  }

  @override
  String get noActivityYet => 'Ancora nessuna attività';

  @override
  String get couldNotLoadMembers => 'Impossibile caricare i membri';

  @override
  String get couldNotLoadInvites => 'Impossibile caricare gli inviti';

  @override
  String get couldNotLoadActivity => 'Impossibile caricare l\'attività';

  @override
  String get yourDevices => 'I tuoi dispositivi';

  @override
  String get yourDevicesDescription =>
      'Client associati al tuo account su questo server.';

  @override
  String get noOwnDevices =>
      'Nessun dispositivo è ancora associato al tuo account';

  @override
  String get renameDeviceTitle => 'Rinomina dispositivo';

  @override
  String get revokeDeviceTitle => 'Revoca dispositivo';

  @override
  String revokeDeviceConfirm(String label) {
    return 'Revocare $label? Viene disconnesso immediatamente e non può più raggiungere questo server.';
  }

  @override
  String devicePairedTime(String time) {
    return 'Associato $time';
  }

  @override
  String deviceLastSeenTime(String time) {
    return 'Ultimo accesso $time';
  }

  @override
  String get deviceNeverSeen => 'Mai connesso';

  @override
  String get profileSectionLabel => 'Profilo';

  @override
  String get profileSectionDescription =>
      'Come appari ai colleghi e nella paternità dei commit git.';

  @override
  String get displayNameLabel => 'Nome visualizzato';

  @override
  String get emailLabel => 'E-mail';

  @override
  String get gitAuthorNameLabel => 'Nome autore git';

  @override
  String get gitAuthorEmailLabel => 'E-mail autore git';

  @override
  String get profileSaved => 'Profilo salvato';

  @override
  String get presenceOnline => 'Online';

  @override
  String get presenceIdle => 'Inattivo';

  @override
  String get presenceTyping => 'Sta scrivendo…';

  @override
  String get presenceAgentThinking => 'Sta pensando';

  @override
  String get presenceAgentRunning => 'In corso';

  @override
  String get presenceAgentBlocked => 'Bloccato';

  @override
  String get presenceAgentDone => 'Completato';

  @override
  String presenceNameStatus(String name, String status) {
    return '$name — $status';
  }

  @override
  String presenceNameStatusCost(String name, String status, String cost) {
    return '$name — $status ($cost)';
  }

  @override
  String get presenceRailLabel => 'Chi è online';

  @override
  String presencePlusCount(int count) {
    return '+$count';
  }

  @override
  String get dndTooltipOn => 'Attiva non disturbare';

  @override
  String get dndTooltipOff => 'Disattiva non disturbare';

  @override
  String get startPresenting => 'Inizia a presentare';

  @override
  String get stopPresenting => 'Interrompi la presentazione';

  @override
  String spotlightPresentingBanner(String name) {
    return '$name sta presentando';
  }

  @override
  String get spotlightLeave => 'Esci';

  @override
  String typingIndicator(String name) {
    return '$name sta scrivendo…';
  }

  @override
  String get ideTabNotes => 'Note';

  @override
  String get ideSidebarAllViews => 'Tutte le viste';

  @override
  String ideSidebarAllViewsHidden(int count) {
    return 'Tutte le viste ($count nascoste)';
  }

  @override
  String get ideSidebarPinView => 'Aggiungi alla barra laterale';

  @override
  String get ideSidebarUnpinView => 'Rimuovi dalla barra laterale';

  @override
  String get notesEmptyHint =>
      'Aggiungi una nota per chi riprenderà questa conversazione…';

  @override
  String get notesEditTooltip => 'Modifica nota';

  @override
  String notesUpdatedBy(String name, String time) {
    return 'Aggiornato da $name · $time';
  }

  @override
  String notesEditingHint(String name) {
    return '$name sta modificando';
  }

  @override
  String get notesSaveFailed => 'Impossibile salvare la nota';

  @override
  String get reactionAddTooltip => 'Aggiungi reazione';

  @override
  String reactionToggleTooltip(String emoji) {
    return 'Reagisci con $emoji';
  }

  @override
  String get autonomyDialLabel => 'Autonomia';

  @override
  String get autonomyProposeOnly => 'Solo proposta';

  @override
  String get autonomyActWithApproval => 'Agisci con approvazione';

  @override
  String get autonomyActFreely => 'Agisci liberamente';

  @override
  String get autonomyDefaultOption => 'Predefinito';

  @override
  String get checkerLabel => 'Revisore';

  @override
  String get checkerNone => 'Nessuno';

  @override
  String get checkerCaption =>
      'Il revisore controlla le esecuzioni completate degli altri agenti.';

  @override
  String get takeoverTooltip => 'Prendi il controllo del worktree';

  @override
  String get takeoverBannerSelf =>
      'Hai preso il controllo del worktree di questa conversazione';

  @override
  String takeoverBannerOther(String name) {
    return '$name ha preso il controllo del worktree di questa conversazione';
  }

  @override
  String get handBackButton => 'Restituisci il controllo';

  @override
  String get handBackDialogTitle => 'Restituisci il controllo del worktree';

  @override
  String get handBackDialogNoteHint => 'Nota facoltativa per l\'agente…';

  @override
  String takeoverFailed(String message) {
    return 'Impossibile prendere il controllo: $message';
  }

  @override
  String handBackFailed(String message) {
    return 'Impossibile restituire il controllo: $message';
  }

  @override
  String get planStudioTitle => 'Studio piano';

  @override
  String get plansTitle => 'Piani';

  @override
  String get plansSubtitle => 'Piani attivi, documenti di piano e playbook';

  @override
  String get plansActiveSection => 'Piani attivi';

  @override
  String get plansDocumentsSection => 'Documenti di piano';

  @override
  String get plansPlaybooksSection => 'Playbook';

  @override
  String get plansNoActive => 'Ancora nessun piano attivo.';

  @override
  String get plansNoDocuments => 'Ancora nessun documento di piano.';

  @override
  String get plansNoPlaybooks => 'Ancora nessun playbook.';

  @override
  String get planNotFound => 'Piano non trovato.';

  @override
  String get planOpenInStudio => 'Apri';

  @override
  String get planNodeTitle => 'Titolo';

  @override
  String get planNodeDescription => 'Descrizione';

  @override
  String get planNodeDescriptionHint => 'Cosa deve fare questo passaggio…';

  @override
  String get planNodeApplyDescription => 'Applica';

  @override
  String get planNodeRole => 'Ruolo';

  @override
  String get planNodeDependencies => 'Dipende da';

  @override
  String get planNodeDependenciesHint => 'Aggiungi una dipendenza';

  @override
  String planNodeDependencyCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dipendenze',
      one: '1 dipendenza',
    );
    return '$_temp0';
  }

  @override
  String get planNodeNoDependencies =>
      'Nessuna dipendenza, parte appena inizia il piano';

  @override
  String get planNodeOutputSchema => 'Schema di output (JSON)';

  @override
  String get planNodeEstimate => 'Stima';

  @override
  String get planNodeProvenance => 'Provenienza';

  @override
  String get planNodeAlreadyExecuted =>
      'Già eseguito — la modifica biforca il piano da qui.';

  @override
  String get planNewNodeTitle => 'Nuovo passaggio';

  @override
  String get planEstimateNoHistory => 'Ancora nessuno storico';

  @override
  String get planEstimateBlastUnknown => 'Raggio d’impatto: sconosciuto';

  @override
  String get planEstimatePartial => 'parziale';

  @override
  String get planEstimateAction => 'Stima';

  @override
  String planEstimateDuration(String range) {
    return 'Durata $range';
  }

  @override
  String planEstimateBlastRadius(int files, int symbols) {
    return 'Raggio d’impatto: $files file, $symbols simboli';
  }

  @override
  String get planApprove => 'Approva piano';

  @override
  String get planApproveSelectedNodes => 'Approva selezionati';

  @override
  String get planReject => 'Rifiuta';

  @override
  String get planCancel => 'Annulla esecuzione';

  @override
  String get planContinueNode => 'Continua nodo';

  @override
  String get planTotalNotEstimated => 'Non ancora stimato';

  @override
  String get planBudgetExceeded => 'oltre budget';

  @override
  String planBudgetCeiling(String amount) {
    return 'budget ≤ $amount \$';
  }

  @override
  String get planVersionsTitle => 'Versioni';

  @override
  String get planNoRevisions => 'Ancora nessuna revisione.';

  @override
  String get planDiffIdentical => 'Nessuna modifica.';

  @override
  String get planDiffGoalChanged => 'Obiettivo modificato';

  @override
  String get planDiffBudgetChanged => 'Budget modificato';

  @override
  String planDiffHeader(int fromRev, int toRev) {
    return 'Modifiche da v$fromRev a v$toRev';
  }

  @override
  String planDiffAdded(String node) {
    return 'Aggiunto $node';
  }

  @override
  String planDiffRemoved(String node) {
    return 'Rimosso $node';
  }

  @override
  String planDiffChanged(String node, String fields) {
    return 'Modificato $node: $fields';
  }

  @override
  String planDiffEdgeAdded(String edge) {
    return 'Arco aggiunto: $edge';
  }

  @override
  String planDiffEdgeRemoved(String edge) {
    return 'Arco rimosso: $edge';
  }

  @override
  String planDiffRoleAdded(String role) {
    return 'Ruolo aggiunto: $role';
  }

  @override
  String planDiffRoleRemoved(String role) {
    return 'Ruolo rimosso: $role';
  }

  @override
  String planDiffRoleReassigned(String role) {
    return 'Ruolo riassegnato: $role';
  }

  @override
  String planReplanBanner(int approved, int current) {
    return 'Piano ripianificato: hai approvato v$approved, ora è v$current. Rivedi le differenze.';
  }

  @override
  String planLiveActualCost(String amount) {
    return 'Costo effettivo: $amount \$';
  }

  @override
  String get planPlaybookRun => 'Esegui';

  @override
  String get planPlaybookDelete => 'Elimina playbook';

  @override
  String get planPlaybookProposed =>
      'Piano proposto — approvalo in Studio piano.';

  @override
  String get planPlaybookAnchorTicket => 'Ticket di ancoraggio';

  @override
  String get planPlaybookPickTicket => 'Scegli un ticket…';

  @override
  String get planPlaybookProposeRun => 'Proponi piano';

  @override
  String get planPlaybookRepoHint => 'Un id di repository';

  @override
  String get planPlaybookAgentHint => 'Un id di agente';

  @override
  String planPlaybookRunTitle(String name) {
    return 'Esegui $name';
  }

  @override
  String planPlaybookParamCount(int count) {
    return '$count parametri';
  }

  @override
  String get reviewStudioTitle => 'Studio di revisione';

  @override
  String get reviewStudioWalkthrough => 'Panoramica';

  @override
  String get reviewStudioContract => 'Contratto API';

  @override
  String get reviewStudioVisual => 'Diff visivo';

  @override
  String get reviewStudioBlastRadius => 'Raggio d\'impatto';

  @override
  String get reviewStudioRecompute => 'Ricalcola';

  @override
  String get reviewStudioCohortsHeader => 'Coorti';

  @override
  String get reviewStudioNoCohorts =>
      'Nessuna coorte — esegui l\'analisi per raggruppare questa PR per significato.';

  @override
  String get reviewStudioGroupedByPath =>
      'Raggruppato per percorso (repo non indicizzato)';

  @override
  String get reviewStudioIndexRepo => 'Indicizza repo';

  @override
  String reviewStudioFilesCount(int count) {
    return '$count file';
  }

  @override
  String get reviewStudioFilesInCohort => 'File in questa coorte';

  @override
  String get reviewStudioSelectCohort =>
      'Seleziona una coorte per vederne il riepilogo.';

  @override
  String get reviewStudioSummaryEmpty => 'Nessun riepilogo per questa coorte.';

  @override
  String get reviewStudioNoAxes => 'Nessun asse di revisione ancora eseguito.';

  @override
  String get reviewAxisCorrectness => 'Correttezza';

  @override
  String get reviewAxisSecurity => 'Sicurezza';

  @override
  String get reviewAxisTestGap => 'Lacune nei test';

  @override
  String get reviewAxisPerformance => 'Prestazioni';

  @override
  String get reviewAxisVisual => 'Visivo';

  @override
  String get reviewAxisApiContract => 'Contratto API';

  @override
  String get reviewAxisPass => 'Superato';

  @override
  String get reviewAxisWarn => 'Avviso';

  @override
  String get reviewAxisFail => 'Fallito';

  @override
  String get reviewAxisPartial => 'Parziale';

  @override
  String get reviewAxisUnavailable => 'Non disponibile';

  @override
  String get reviewStudioVerdictShip => 'Rilascia';

  @override
  String get reviewStudioVerdictHold => 'In attesa';

  @override
  String get reviewStudioVerdictBlock => 'Blocca';

  @override
  String get reviewStudioVerdictClear => 'Nessun asse blocca il merge.';

  @override
  String reviewStudioBlockingAxes(String axes) {
    return '$axes bloccano il merge';
  }

  @override
  String get reviewStudioNoContractChanges =>
      'Nessuna modifica al contratto API in questa PR.';

  @override
  String get reviewStudioBreaking => 'Rottura';

  @override
  String reviewStudioBreakingCount(int count) {
    return '$count di rottura';
  }

  @override
  String get reviewStudioDerivedContract => 'Derivato (indicativo)';

  @override
  String get reviewStudioApprove => 'Approva';

  @override
  String get reviewStudioReject => 'Rifiuta';

  @override
  String get reviewStudioApproved => 'Approvato';

  @override
  String get reviewStudioRejected => 'Rifiutato';

  @override
  String get reviewStudioNoVisualChanges => 'Nessuna modifica visiva rilevata.';

  @override
  String get reviewStudioVisualUnavailable => 'Diff visivo non disponibile';

  @override
  String get reviewStudioApproveChange => 'Approva la modifica prevista';

  @override
  String reviewStudioChangedRegion(String percent) {
    return '$percent% modificato';
  }

  @override
  String get reviewStudioRenderedOnHost => 'Renderizzato sull\'host';

  @override
  String get reviewStudioVisualAdded => 'Aggiunto';

  @override
  String get reviewStudioVisualChanged => 'Modificato';

  @override
  String get reviewStudioVisualRemoved => 'Rimosso';

  @override
  String get reviewStudioVisualApproved => 'Approvato';

  @override
  String get reviewStudioVisualUnchanged => 'Invariato';

  @override
  String get reviewStudioSelectFileForBlast =>
      'Seleziona un file modificato per vederne il raggio d\'impatto.';

  @override
  String get reviewStudioNotIndexed =>
      'Repo non indicizzato — raggio d\'impatto non disponibile.';

  @override
  String reviewStudioAffectedCount(int count) {
    return '$count simboli interessati';
  }

  @override
  String get reviewStudioDirectCallers => 'Chiamanti diretti';

  @override
  String reviewStudioTransitiveAt(int depth) {
    return 'Transitivo (salto $depth)';
  }

  @override
  String get recentLabel => 'Recenti';

  @override
  String get cheatSheetTitle => 'Scorciatoie da tastiera';

  @override
  String get cheatSheetGlobal => 'Globale';

  @override
  String get cheatSheetThisScreen => 'Questa schermata';

  @override
  String get cheatSheetReservedInBrowser => 'Riservato al browser';

  @override
  String get keybindingCheatSheet => 'Scorciatoie da tastiera';

  @override
  String get keybindingShowKeyboardShortcutsDescription =>
      'Mostra il riepilogo delle scorciatoie da tastiera per la schermata corrente';

  @override
  String get runPlaybookLabel => 'Esegui playbook';

  @override
  String get playbooksLabel => 'Playbook';

  @override
  String get keybindingUndo => 'Annulla';

  @override
  String get keybindingRedo => 'Ripeti';

  @override
  String get keybindingUndoLastActionDescription =>
      'Annulla la tua ultima azione reversibile';

  @override
  String get keybindingRedoLastActionDescription =>
      'Ripeti l\'ultima azione annullata';

  @override
  String get undone => 'Annullato';

  @override
  String get redone => 'Ripetuto';

  @override
  String get undoFailed => 'Impossibile annullare';

  @override
  String get undoLabelTicketEdit => 'modifica ticket';

  @override
  String get undoLabelMessageEdit => 'modifica messaggio';

  @override
  String get undoLabelTodoStatus => 'stato attività';

  @override
  String get inboxTitle => 'Posta in arrivo';

  @override
  String get inboxReview => 'Esamina';

  @override
  String get inboxOpen => 'Apri';

  @override
  String get inboxAllCaughtUp => 'Sei in pari';

  @override
  String get inboxGitHubDownTitle => 'GitHub potrebbe essere offline';

  @override
  String inboxGitHubDownBody(String status) {
    return 'GitHub segnala: $status. Alcune pull request potrebbero mancare da questo elenco invece di essere davvero concluse.';
  }

  @override
  String get inboxGitHubIdentityTitle =>
      'Impossibile confermare il tuo account GitHub';

  @override
  String get inboxGitHubIdentityBody =>
      'La posta in arrivo è ordinata in base a chi sei su GitHub. Finché non viene caricato, l\'elenco resta vuoto anche se ci sono pull request in attesa.';

  @override
  String get inboxSeverityBlocking => 'Bloccato';

  @override
  String get inboxSeverityWaiting => 'In attesa';

  @override
  String get inboxSeverityInfo => 'Info';

  @override
  String get inboxSyncFailed => 'Sincronizzazione non riuscita';

  @override
  String get inboxNeedsYourAttention => 'Richiede la tua attenzione';

  @override
  String get inboxSectionNeedsYourReview => 'In attesa della tua revisione';

  @override
  String get inboxSectionReturnedToYou => 'Restituite a te';

  @override
  String get inboxSectionApproved => 'Approvate';

  @override
  String get inboxSectionDrafts => 'Bozze';

  @override
  String get inboxSectionWaitingForReviewers => 'In attesa di revisori';

  @override
  String get inboxSectionMergingAndMerged => 'In fusione e unite di recente';

  @override
  String get inboxSectionWaitingForAuthor => 'In attesa dell\'autore';

  @override
  String get inboxColumnTitle => 'Titolo';

  @override
  String get inboxColumnChanges => 'Modifiche';

  @override
  String get inboxColumnUpdated => 'Aggiornato';

  @override
  String get inboxReviewApproved => 'Approvata';

  @override
  String get inboxReviewChangesRequested => 'Modifiche richieste';

  @override
  String get inboxHeroSubtitle =>
      'Ogni pull request che ti riguarda, in ordine di prossima azione.';

  @override
  String inboxHeroNeedsReview(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pull request attendono la tua revisione',
      one: '1 pull request attende la tua revisione',
    );
    return '$_temp0';
  }

  @override
  String inboxHeroReturnedToYou(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sono tornate a te',
      one: '1 è tornata a te',
    );
    return '$_temp0';
  }

  @override
  String get optimisticChangeReverted =>
      'Quella modifica non è stata salvata ed è stata annullata';

  @override
  String get offlinePendingLabel => 'in sospeso';

  @override
  String get offlineSyncingLabel => 'sincronizzazione';

  @override
  String get copyLinkLabel => 'Copia il link di questa pagina';

  @override
  String get fleetTabLabel => 'Flotta';

  @override
  String get evalsTabLabel => 'Eval';

  @override
  String get agentsSectionLabel => 'Agenti';

  @override
  String get fleetWorkersTitle => 'Worker';

  @override
  String get fleetWorkersSubtitle =>
      'Macchine disponibili per eseguire i lavori';

  @override
  String get fleetJobsTitle => 'Lavori';

  @override
  String get fleetJobsSubtitle => 'Lavoro distribuito sulla flotta';

  @override
  String get fleetNoWorkers =>
      'Ancora nessun worker — una seconda macchina che esegue `cc_worker --server <url>` si unisce alla flotta.';

  @override
  String get fleetNoJobs => 'Nessun lavoro.';

  @override
  String get fleetError => 'Impossibile caricare la flotta';

  @override
  String fleetCores(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count core',
      one: '1 core',
    );
    return '$_temp0';
  }

  @override
  String fleetHeartbeat(String time) {
    return 'Heartbeat $time';
  }

  @override
  String get fleetNoHeartbeat => 'Ancora nessun heartbeat';

  @override
  String fleetLastErrorLabel(String error) {
    return 'Ultimo errore: $error';
  }

  @override
  String get fleetDrain => 'Svuota';

  @override
  String get fleetResume => 'Riprendi';

  @override
  String get fleetRevoke => 'Revoca';

  @override
  String get fleetRemove => 'Rimuovi';

  @override
  String get fleetRevokeTitle => 'Revocare il worker?';

  @override
  String fleetRevokeBody(String name) {
    return 'Revocare $name? La sua sessione termina e i lavori attivi vengono riassegnati.';
  }

  @override
  String get fleetRemoveTitle => 'Rimuovere il worker?';

  @override
  String fleetRemoveBody(String name) {
    return 'Rimuovere $name dalla flotta? Questo elimina il suo record.';
  }

  @override
  String get fleetActionFailed => 'Azione non riuscita';

  @override
  String get fleetJobUnassigned => 'Non assegnato';

  @override
  String fleetJobAttempts(int attempts, int max) {
    return '$attempts/$max tentativi';
  }

  @override
  String get fleetPlacementReasons => 'Decisioni di posizionamento';

  @override
  String get fleetNoPlacements => 'Ancora nessuna decisione di posizionamento.';

  @override
  String get fleetStatusOnline => 'Online';

  @override
  String get fleetStatusDraining => 'Svuotamento';

  @override
  String get fleetStatusOffline => 'Offline';

  @override
  String get fleetStatusIncompatible => 'Incompatibile';

  @override
  String get fleetStatusRevoked => 'Revocato';

  @override
  String get fleetJobStatusQueued => 'In coda';

  @override
  String get fleetJobStatusRunning => 'In esecuzione';

  @override
  String get fleetJobStatusSucceeded => 'Riuscito';

  @override
  String get fleetJobStatusFailed => 'Non riuscito';

  @override
  String get fleetJobStatusCancelled => 'Annullato';

  @override
  String get evalsNoSuites => 'Ancora nessuna suite di valutazione.';

  @override
  String get evalsError => 'Impossibile caricare le valutazioni';

  @override
  String get evalsStarterBadge => 'Iniziale';

  @override
  String evalsDefaultBatch(int count) {
    return 'Batch predefinito di $count';
  }

  @override
  String get evalsRecentRuns => 'Esecuzioni recenti';

  @override
  String get evalsNoRuns => 'Ancora nessuna esecuzione.';

  @override
  String get evalsPassRate => 'Tasso di successo';

  @override
  String evalsBatchTimes(int count) {
    return '× $count';
  }

  @override
  String evalsTriggeredBy(String who) {
    return 'da $who';
  }

  @override
  String evalsRunFinished(String rate) {
    return 'Valutazione completata — $rate superati';
  }

  @override
  String get evalsRunFailed => 'Impossibile eseguire la suite';

  @override
  String get evalsRun => 'Esegui';

  @override
  String get evalsStatusQueued => 'In coda';

  @override
  String get evalsStatusRunning => 'In esecuzione';

  @override
  String get evalsStatusPassed => 'Superato';

  @override
  String get evalsStatusFailed => 'Non riuscito';

  @override
  String get bannerMeetingJoin => 'Partecipa';

  @override
  String get bannerMeetingRecordAndLink => 'Registra e collega';

  @override
  String get bannerCalendarReconnect => 'Riconnetti';

  @override
  String get bannerView => 'Visualizza';

  @override
  String get soundscapeTitle => 'Paesaggi sonori';

  @override
  String get soundscapePlay => 'Riproduci';

  @override
  String get soundscapePause => 'Pausa';

  @override
  String get soundscapeMoodLabel => 'Atmosfera';

  @override
  String get soundscapeMoodFocus => 'Concentrazione';

  @override
  String get soundscapeMoodRelax => 'Relax';

  @override
  String get soundscapeMoodSleep => 'Sonno';

  @override
  String get soundscapeVolumeLabel => 'Volume';

  @override
  String get soundscapeTuneLabel => 'Regolazione';

  @override
  String get soundscapeTuneMellow => 'Morbido';

  @override
  String get soundscapeTuneBright => 'Brillante';

  @override
  String get soundscapeTuneEnergetic => 'Energico';

  @override
  String get soundscapeTuneSpacy => 'Spaziale';

  @override
  String get soundscapeTuneResetHint => 'Tocca due volte per ripristinare';

  @override
  String get soundscapeSceneLabel => 'In riproduzione';

  @override
  String get soundscapeSceneLoading => 'Regolazione dell\'atmosfera…';

  @override
  String soundscapeTemperature(int degrees) {
    return '$degrees °C';
  }

  @override
  String get soundscapeLocationLabel => 'Posizione';

  @override
  String get soundscapeLocationDetecting => 'Rilevamento della posizione…';

  @override
  String get soundscapeLocationAutoNote =>
      'La posizione viene rilevata automaticamente da questo spazio di lavoro.';

  @override
  String get soundscapeRefreshWeather => 'Aggiorna il meteo';

  @override
  String get soundscapeAutoStartLabel => 'Avvia con la modalità concentrazione';

  @override
  String get soundscapeAutoStartDescription =>
      'Riproduci automaticamente un paesaggio sonoro quando avvii una sessione di concentrazione.';

  @override
  String get soundscapeReturnToApp => 'Torna all\'app';

  @override
  String get soundscapePopOut => 'Stacca il lettore';

  @override
  String get newParenthesis => 'Nuova parentesi';

  @override
  String get parenthesisTitleHint => 'es. correzione rapida';

  @override
  String get discussion => 'Discussione';

  @override
  String get chat => 'Chat';

  @override
  String get saving => 'Salvataggio…';

  @override
  String get saved => 'Salvato';

  @override
  String get saveFailed => 'Impossibile salvare';

  @override
  String get commitAndPush => 'Commit e push';

  @override
  String get commit => 'Commit';

  @override
  String get commitAmend => 'Commit (modifica)';

  @override
  String get commitAndSync => 'Commit e sincronizza';

  @override
  String get committed => 'Commit eseguito';

  @override
  String get commitAmended => 'Commit modificato';

  @override
  String get commitFailed => 'Commit non riuscito';

  @override
  String get moreCommitActions => 'Altre azioni di commit';

  @override
  String get sourceControl => 'Controllo del codice';

  @override
  String fixFindingTitle(String location) {
    return 'Correggi: $location';
  }

  @override
  String get reviewSplitLayout => 'Layout di revisione';

  @override
  String get openInEditor => 'Apri nell\'editor';

  @override
  String uncommittedChanges(int count) {
    return '$count modifiche non salvate';
  }

  @override
  String get commitMessageHint => 'Messaggio di commit';

  @override
  String get pushedToPr => 'Inviato alla PR';

  @override
  String get pushFailed => 'Push non riuscito';

  @override
  String get openAtPrHead => 'Apri all’head della PR';

  @override
  String get reviewFindings => 'Risultati';

  @override
  String get treeLabel => 'Albero';

  @override
  String get toggleFileTree => 'Mostra o nascondi l\'albero dei file';

  @override
  String get diffViewSettings => 'Impostazioni vista diff';

  @override
  String get splitViewLabel => 'Affiancata';

  @override
  String get unifiedViewLabel => 'Unificata';

  @override
  String get wrapLines => 'A capo automatico';

  @override
  String get shiftClickSelectRange =>
      'Maiusc-clic per selezionare un intervallo';

  @override
  String diffFilesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count file',
      one: '1 file',
    );
    return '$_temp0';
  }

  @override
  String prComplexityLoc(String loc) {
    return '$loc LOC';
  }

  @override
  String prComplexityTooltipSmall(String files, int minutes) {
    return 'PR piccola — $files, ~$minutes min di revisione';
  }

  @override
  String prComplexityTooltipMedium(String files, int minutes) {
    return 'PR media — $files, prevedi ~$minutes min di revisione';
  }

  @override
  String prComplexityTooltipLarge(String files) {
    return 'PR grande — $files, considera di dividerla prima della revisione';
  }

  @override
  String get searchInFiles => 'Cerca nei file';

  @override
  String get showFileList => 'Mostra elenco file';

  @override
  String get searchInFilesHintField => 'Cerca nei file…';

  @override
  String get searchInFilesHint => 'Cerca nei file della pull request';

  @override
  String get searchNoResults => 'Nessun risultato';

  @override
  String searchResultsCount(int count, int files) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count risultati',
      one: '1 risultato',
    );
    String _temp1 = intl.Intl.pluralLogic(
      files,
      locale: localeName,
      other: '$files file',
      one: '1 file',
    );
    return '$_temp0 in $_temp1';
  }

  @override
  String get discardChangesTitle => 'Annullare le modifiche?';

  @override
  String discardChangesMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count file',
      one: '1 file',
    );
    return 'Ripristinare $_temp0 a HEAD? L\'operazione non può essere annullata.';
  }

  @override
  String get discardAll => 'Annulla tutto';

  @override
  String get discardFailed => 'Impossibile annullare le modifiche';

  @override
  String discardedFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count file annullati',
      one: '1 file annullato',
    );
    return '$_temp0';
  }

  @override
  String discardedWithSkipped(int reverted, int skipped) {
    String _temp0 = intl.Intl.pluralLogic(
      reverted,
      locale: localeName,
      other: '$reverted file annullati',
      one: '1 file annullato',
    );
    return '$_temp0; $skipped ignorato/i (non tracciato/i)';
  }

  @override
  String get prWorktreeUnavailable => 'Spazio di lavoro non pronto';

  @override
  String get prWorktreeUnavailableHint =>
      'Preparazione dei file della pull request non riuscita. Riapri la pull request per riprovare.';

  @override
  String get timestampRelativeLabel => 'Relativo';

  @override
  String get timestampRawLabel => 'Timestamp';

  @override
  String get copyTimestamp => 'Copia timestamp';

  @override
  String get copiedTimestamp => 'Timestamp copiato';

  @override
  String get previewDeployment => 'Deploy di anteprima';

  @override
  String previewDeploymentTab(String site) {
    return 'Anteprima: $site';
  }

  @override
  String get askForReview => 'Richiedi una revisione…';

  @override
  String get closePrsConfirmTitle => 'Chiudere le pull request?';

  @override
  String closePrsConfirmBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Chiudere $count pull request?',
      one: 'Chiudere 1 pull request?',
    );
    return '$_temp0';
  }

  @override
  String closedCountPrs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pull request chiuse',
      one: '1 pull request chiusa',
    );
    return '$_temp0';
  }

  @override
  String assignedCountPrs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pull request assegnate',
      one: '1 pull request assegnata',
    );
    return '$_temp0';
  }

  @override
  String requestedReviewCountPrs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Revisione richiesta su $count pull request',
      one: 'Revisione richiesta su 1 pull request',
    );
    return '$_temp0';
  }

  @override
  String bulkActionPartialFailure(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count azioni non riuscite',
      one: '1 azione non riuscita',
    );
    return '$_temp0';
  }

  @override
  String get diagram => 'Diagramma';

  @override
  String get diagramViewSource => 'Mostra il sorgente';

  @override
  String get diagramHideSource => 'Nascondi il sorgente';

  @override
  String diagramPreviewUnavailable(String reason) {
    return 'Anteprima del diagramma non disponibile ($reason)';
  }

  @override
  String get planUnavailable => 'Piano non disponibile';

  @override
  String planStepCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count passaggi',
      one: '1 passaggio',
    );
    return '$_temp0';
  }

  @override
  String get planApproveAndRun => 'Approva ed esegui';

  @override
  String get planStatusDraft => 'Bozza';

  @override
  String get planStatusProposed => 'Piano';

  @override
  String get planStatusApproved => 'Piano approvato';

  @override
  String get planStatusRejected => 'Piano rifiutato';

  @override
  String get planStatusSuperseded => 'Piano sostituito';

  @override
  String planRevisionLabel(int revision) {
    return 'Revisione $revision';
  }

  @override
  String get adapterEnforcementTitle => 'Che cosa applica questo adattatore';

  @override
  String get enforcementFiltersToolSurface =>
      'Control Center sceglie gli strumenti';

  @override
  String get enforcementInterceptsToolCalls =>
      'Ogni chiamata è controllata prima dell\'esecuzione';

  @override
  String get enforcementObservesCompletionContract =>
      'L\'esecuzione risponde del proprio risultato';

  @override
  String get enforcementNativeToolsInterceptable =>
      'Gli strumenti propri del motore sono visibili';

  @override
  String get enforcementInProcessToolsSandboxed =>
      'Gli strumenti eseguiti nel processo sono isolati';

  @override
  String get enforcementYes => 'Sì';

  @override
  String get enforcementNo => 'No';

  @override
  String get adapterEnforcementCaveats => 'Avvertenze';

  @override
  String get enforcementSummaryModesEnforced => 'Modalità applicate';

  @override
  String get enforcementSummaryModesNotEnforced => 'Modalità non applicate';

  @override
  String enforcementCaveatCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count avvertenze',
      one: '1 avvertenza',
    );
    return '$_temp0';
  }

  @override
  String get caveatToolSurfaceNotFiltered =>
      'Le modalità di sola lettura non sono strutturali: Control Center non può rimuovere gli strumenti propri di questo motore.';

  @override
  String get caveatToolCallsNotIntercepted =>
      'Nessun controllo prima dell\'esecuzione: solo le chiamate agli strumenti MCP passano da Control Center.';

  @override
  String get caveatNativeToolsBypassControlCenter =>
      'Gli strumenti di file e shell propri del motore non raggiungono mai Control Center; l\'isolamento del sistema è la loro unica barriera.';

  @override
  String get caveatInProcessToolsUnsandboxed =>
      'Gli strumenti di file eseguiti nel processo restano fuori dall\'isolamento, quindi la superficie di strumenti è l\'unico confine del file system.';

  @override
  String get caveatCompletionContractUnobservable =>
      'Control Center non può sollecitare né far fallire un\'esecuzione che termina senza produrre il proprio risultato.';

  @override
  String get modeDegraded => 'Ridotto';

  @override
  String modeDegradedTooltip(String mode, String adapter) {
    return 'La modalità $mode su $adapter si affida solo all\'isolamento; gli strumenti di file dell\'agente non vengono intercettati.';
  }

  @override
  String get artifactUnavailable => 'Artefatto non disponibile';

  @override
  String artifactRevisionLabel(int count) {
    return '$count revisioni';
  }

  @override
  String get artifactShowMore => 'Mostra altro';

  @override
  String get artifactShowLess => 'Mostra meno';

  @override
  String get artifactCopy => 'Copia';

  @override
  String get artifactCopied => 'Artefatto copiato';

  @override
  String get artifactsTabLabel => 'Artefatti';

  @override
  String get artifactsEmptyTitle => 'Nessun artefatto';

  @override
  String get artifactsEmptyBody =>
      'Quando un agente pubblica una tabella, un grafico o un diagramma qui, appare in questo elenco.';

  @override
  String get artifactRevisionPickerLabel => 'Revisione';

  @override
  String get artifactRestoreRevision => 'Ripristina questa revisione';

  @override
  String get artifactOpenInTab => 'Apri in una scheda';

  @override
  String get artifactTitleFallback => 'Artefatto';

  @override
  String get providerGenerationLabel => 'Valori di generazione predefiniti';

  @override
  String get providerGenerationHint =>
      'Lascia un campo vuoto per usare il valore predefinito dell\'endpoint. Ogni modello pubblica i propri limiti di output e le proprie ricette di campionamento; altri valori possono degradarlo.';

  @override
  String get providerMaxTokensLabel => 'Token di output max';

  @override
  String get providerTemperatureLabel => 'Temperatura';

  @override
  String get providerTopPLabel => 'Top-p';

  @override
  String get providerTopKLabel => 'Top-k';

  @override
  String get providerGenerationSaved => 'Valori di generazione salvati';

  @override
  String get providerGenerationInvalid =>
      'Controlla i valori: i token di output max e il top-k devono essere positivi, la temperatura 0–2, il top-p 0–1.';

  @override
  String get providerGenerationOverridden => 'Personalizzato';

  @override
  String get channelFlyoutNeedsInput => 'Attende una risposta';

  @override
  String get channelFlyoutPreparing => 'Preparazione';

  @override
  String get channelFlyoutSetupFailed => 'Configurazione non riuscita';

  @override
  String get channelFlyoutNeverRun => 'Nessun agente ha ancora lavorato qui';

  @override
  String channelFlyoutContextUsage(String used, String percent) {
    return 'Finestra di contesto: $used usati, piena al $percent';
  }

  @override
  String subagentsRunningCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count subagenti',
      one: '1 subagente',
    );
    return '$_temp0';
  }

  @override
  String get branchNotPushed => 'non inviato';

  @override
  String branchNotOnRemote(String branch) {
    return '“$branch” esiste solo in questa conversazione';
  }

  @override
  String get branchNotOnRemoteHint =>
      'GitHub non ha mai visto questo branch, quindi una pull request non può ancora usarlo. La pubblicazione invia i commit già presenti nel worktree; le modifiche non committate restano intatte.';

  @override
  String get publishBranch => 'Pubblica branch';

  @override
  String branchPublished(String branch) {
    return '“$branch” pubblicato su origin';
  }

  @override
  String branchPublishedWithUncommitted(int count) {
    return 'Branch pubblicato. $count modifica/modifiche non committate non sono state incluse.';
  }

  @override
  String get composePrLoadingBranches => 'Caricamento dei branch da GitHub…';

  @override
  String get composePrBranchesFailed =>
      'Impossibile caricare i branch da GitHub. Digita il nome di un branch o controlla la connessione a GitHub.';

  @override
  String get composePrSubtitleFromChannel =>
      'Dal branch di questa conversazione — pubblicalo prima se GitHub non lo conosce';

  @override
  String get obsTabInsights => 'Panoramica';

  @override
  String get obsTabLive => 'Dal vivo';

  @override
  String get obsTabQuality => 'Qualità';

  @override
  String get obsScreenSubtitle =>
      'Controllo degli agenti dal vivo, attribuzione dei costi, quote e segnali di qualità';

  @override
  String get obsRangeLast24h => 'Ultime 24 ore';

  @override
  String get obsRangeLast7d => 'Ultimi 7 giorni';

  @override
  String get obsRangeLast30d => 'Ultimi 30 giorni';

  @override
  String get obsRangeAll => 'Tutto';

  @override
  String get obsAddFilter => 'Aggiungi filtro';

  @override
  String get obsFilterAgent => 'Agente';

  @override
  String get obsFilterModel => 'Modello';

  @override
  String get obsFilterStatus => 'Stato';

  @override
  String get obsFilterRole => 'Ruolo';

  @override
  String get obsKpiTotalRuns => 'Esecuzioni totali';

  @override
  String get obsKpiTotalCost => 'Costo totale';

  @override
  String get obsKpiErrorRate => 'Tasso di errore';

  @override
  String get obsKpiCacheRate => 'Tasso di cache';

  @override
  String get obsKpiTokensPerSec => 'Token / s';

  @override
  String get obsKpiAvgLatency => 'Latenza media';

  @override
  String get obsKpiTtft => 'Tempo al primo token';

  @override
  String obsDeltaVsPrevious(String delta) {
    return '$delta rispetto al periodo precedente';
  }

  @override
  String get obsChartActivity => 'Attività';

  @override
  String get obsChartCost => 'Costo nel tempo';

  @override
  String get obsLegendRuns => 'Esecuzioni';

  @override
  String get obsLegendErrors => 'Errori';

  @override
  String get obsAgentsTitle => 'Agenti';

  @override
  String obsShowAllAgents(int count) {
    return 'Mostra tutti i $count agenti';
  }

  @override
  String get obsShowFewerAgents => 'Mostra meno';

  @override
  String get obsRunsTitle => 'Esecuzioni';

  @override
  String get obsNoRunsInRange => 'Nessuna esecuzione in questo periodo';

  @override
  String get obsColTime => 'Ora';

  @override
  String get obsColAgent => 'Agente';

  @override
  String get obsColStatus => 'Stato';

  @override
  String get obsColModel => 'Modello';

  @override
  String get obsColDuration => 'Durata';

  @override
  String get obsColTokens => 'Token';

  @override
  String get obsColCost => 'Costo';

  @override
  String get obsColErrors => 'Errori';

  @override
  String get obsColRuns => 'Esecuzioni';

  @override
  String get obsColAvgLatency => 'Latenza media';

  @override
  String get obsColLastActive => 'Ultima attività';

  @override
  String get obsStatusPending => 'In attesa';

  @override
  String get obsStatusRunning => 'In corso';

  @override
  String get obsStatusCompleted => 'Completata';

  @override
  String get obsStatusError => 'Errore';

  @override
  String get obsRosterLoadError =>
      'Impossibile caricare l\'elenco degli agenti.';

  @override
  String get obsRosterEmpty => 'Ancora nessun agente';

  @override
  String get obsRosterEmptyDescription =>
      'Avvia un agente e apparirà qui dal vivo: stato, strumento corrente, token, costo.';

  @override
  String get obsKillAgent => 'Termina agente';

  @override
  String get obsRosterTokensLabel => 'tok';

  @override
  String get obsCostByRoleTitle => 'Costo per ruolo';

  @override
  String get obsCostByRoleSubtitle =>
      'Dove spende questo spazio di lavoro, per ruolo dell\'agente';

  @override
  String get obsRoleMain => 'Principale';

  @override
  String get obsRoleSubagents => 'Subagenti';

  @override
  String get obsRoleAdvisor => 'Consulente';

  @override
  String obsRoleCaption(String main, String sub, String advisor) {
    return 'Principale: $main · subagenti: $sub · consulente: $advisor';
  }

  @override
  String get obsTotal => 'Totale';

  @override
  String get obsTokenModelTitle => 'Modello dei token (5 assi)';

  @override
  String get obsTokenModelSubtitle =>
      'Tutti i token spesi da questo spazio, per asse';

  @override
  String get obsAxisInput => 'Input';

  @override
  String get obsAxisOutput => 'Output';

  @override
  String get obsAxisReasoning => 'Ragionamento';

  @override
  String get obsAxisCacheRead => 'Lettura cache';

  @override
  String get obsAxisCacheWrite => 'Scrittura cache';

  @override
  String get obsTotalTokens => 'Token totali';

  @override
  String get obsCacheDiscountNote =>
      'I token letti dalla cache sono fatturati con uno sconto, quindi costano molto meno dello stesso volume di nuovo input.';

  @override
  String get obsByModelTitle => 'Per modello';

  @override
  String get obsByModelSubtitle => 'Uso di token e costo per modello';

  @override
  String get obsNoModelUsage => 'Nessun utilizzo di modelli registrato finora.';

  @override
  String obsRunCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count esecuzioni',
      one: '1 esecuzione',
    );
    return '$_temp0';
  }

  @override
  String obsTokensSuffix(String tokens) {
    return '$tokens token';
  }

  @override
  String get obsPerRunTitle => 'Per esecuzione';

  @override
  String get obsPerRunSubtitle =>
      'Costo tipico in token di una singola esecuzione';

  @override
  String get obsMedianRunTokens => 'Token mediani per esecuzione';

  @override
  String get obsMedianRunTokensSub => 'Mediana su tutte le esecuzioni';

  @override
  String get obsRunsInWorkspace => 'In questo spazio';

  @override
  String get obsCostShare => 'Quota del costo';

  @override
  String get obsQuotaConfiguredLimits => 'Limiti configurati';

  @override
  String get obsQuotaConfiguredLimitsSubtitle =>
      'Utilizzo rispetto ai limiti impostati, lo stato peggiore per primo.';

  @override
  String get obsQuotaAddLimit => 'Aggiungi limite';

  @override
  String get obsQuotaNoLimits =>
      'Nessun limite di quota configurato: aggiungine uno per monitorare l\'utilizzo rispetto a un tetto.';

  @override
  String obsQuotaRemoveSemantic(String title) {
    return 'Rimuovi il limite $title';
  }

  @override
  String obsQuotaResetDetail(String duration, String status) {
    return 'Si azzera tra $duration · $status';
  }

  @override
  String get obsQuotaUsageWindows => 'Finestre di utilizzo';

  @override
  String get obsQuotaUsageWindowsSubtitle =>
      'Utilizzo osservato su tutti i provider, senza tetto applicato.';

  @override
  String get obsQuotaNoUsage => 'Nessun utilizzo registrato finora.';

  @override
  String get obsQuotaTokensUsed => 'Token utilizzati';

  @override
  String get obsQuotaRequests => 'Richieste';

  @override
  String get obsQuotaUnitTokens => 'token';

  @override
  String get obsQuotaUnitRequests => 'richieste';

  @override
  String get obsQuotaUnitCost => 'costo';

  @override
  String get obsQuotaAddLimitTitle => 'Aggiungi limite di quota';

  @override
  String get obsQuotaProviderLabel => 'Provider';

  @override
  String get obsQuotaWindowLabel => 'Finestra';

  @override
  String get obsQuotaUnitLabel => 'Unità';

  @override
  String obsQuotaLimitLabel(String unit) {
    return 'Limite ($unit)';
  }

  @override
  String get obsQuotaCentsHint => 'In centesimi statunitensi (500 = 5,00 \$).';

  @override
  String get obsQuotaStatusOk => 'Ok';

  @override
  String get obsQuotaStatusWarning => 'Avviso';

  @override
  String get obsQuotaStatusExhausted => 'Esaurito';

  @override
  String get obsQuotaStatusUnknown => 'Sconosciuto';

  @override
  String get obsGoalNoActiveTitle => 'Nessun obiettivo attivo';

  @override
  String get obsGoalNoActiveBody =>
      'Imposta un obiettivo per dare agli agenti uno scopo e un budget di token opzionale. Man mano che le esecuzioni si completano, il budget si riempie e gli agenti vengono invitati a concludere quando è quasi esaurito.';

  @override
  String get obsGoalSetGoal => 'Imposta un obiettivo';

  @override
  String get obsGoalTokenBudget => 'Budget di token';

  @override
  String obsGoalTokensLeft(String tokens) {
    return '$tokens rimanenti';
  }

  @override
  String obsGoalTokensUsedNoBudget(String tokens) {
    return '$tokens (nessun budget impostato)';
  }

  @override
  String get obsGoalTokensUsed => 'Token utilizzati';

  @override
  String get obsGoalElapsed => 'Trascorso';

  @override
  String get obsGoalWrapUp => 'Concludi';

  @override
  String get obsGoalClear => 'Cancella obiettivo';

  @override
  String get obsGoalFallbackTitle => 'Obiettivo';

  @override
  String get obsGoalSubtitle => 'Budget della modalità obiettivo';

  @override
  String get obsGoalStatusActive => 'Attivo';

  @override
  String get obsGoalStatusPaused => 'In pausa';

  @override
  String get obsGoalStatusBudgetLimited => 'Budget limitato';

  @override
  String get obsGoalStatusComplete => 'Completato';

  @override
  String get obsGoalStatusDropped => 'Abbandonato';

  @override
  String get obsGoalObjectiveLabel => 'Obiettivo';

  @override
  String get obsGoalBudgetLabel => 'Budget di token (opzionale)';

  @override
  String get obsGoalSetAction => 'Imposta obiettivo';

  @override
  String get obsBenchmarkCaption =>
      'Una vista valutata delle esecuzioni recenti degli agenti: successo/fallimento, ricompensa e spesa per attività.';

  @override
  String get obsBenchmarkPassAt1 => 'pass@1';

  @override
  String get obsBenchmarkSuccessPct => 'Successo %';

  @override
  String get obsBenchmarkPassed => 'Superate';

  @override
  String get obsBenchmarkFailed => 'Fallite';

  @override
  String get obsBenchmarkErrors => 'Errori';

  @override
  String get obsBenchmarkSpend => 'Spesa';

  @override
  String get obsBenchmarkCostPerTask => 'Costo / attività';

  @override
  String get obsBenchmarkTrials => 'Prove';

  @override
  String get obsBenchmarkNoTrials => 'Nessuna esecuzione da valutare finora.';

  @override
  String obsBenchmarkAndMore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'e altre $count',
      one: 'e 1 altra',
    );
    return '$_temp0';
  }

  @override
  String get obsBenchmarkTrialPass => 'Superata';

  @override
  String get obsBenchmarkTrialFail => 'Fallita';

  @override
  String get obsBenchmarkTrialError => 'Errore';

  @override
  String get obsBenchmarkTrialRunning => 'In corso';

  @override
  String get obsBenchmarkReward => 'Ricompensa';

  @override
  String get obsBenchmarkReport => 'Report';

  @override
  String get obsBenchmarkCopyMarkdown => 'Copia markdown';

  @override
  String get obsBenchmarkCopied => 'Report copiato negli appunti';

  @override
  String get obsBehaviorCaption =>
      'Questi sono segnali di frustrazione estratti dai tuoi messaggi: una lettura della salute della conversazione, non un voto per gli agenti. Calcolato in locale; nulla lascia questo dispositivo.';

  @override
  String get obsBehaviorMessagesAnalyzed => 'Messaggi analizzati';

  @override
  String get obsBehaviorTotalSignals => 'Segnali totali';

  @override
  String get obsBehaviorYelling => 'Urla';

  @override
  String get obsBehaviorProfanity => 'Volgarità';

  @override
  String get obsBehaviorAnguish => 'Angoscia';

  @override
  String get obsBehaviorNegation => 'Negazione';

  @override
  String get obsBehaviorRepetition => 'Ripetizione';

  @override
  String get obsBehaviorBlame => 'Biasimo';

  @override
  String get obsBehaviorConversationsTitle => 'Conversazioni più frustrate';

  @override
  String get obsBehaviorConversationsSubtitle =>
      'Ordinate per densità di segnali nei tuoi messaggi.';

  @override
  String get obsBehaviorNoSignals =>
      'Nessun segnale di frustrazione rilevato: tutto liscio.';

  @override
  String obsBehaviorMessagesCount(String count) {
    return '$count messaggi analizzati';
  }

  @override
  String obsBehaviorSignalsCount(String count) {
    return '$count segnali';
  }

  @override
  String get obsAgentStatusIdle => 'Inattivo';

  @override
  String get obsAgentStatusParked => 'In pausa';

  @override
  String get obsAgentStatusAborted => 'Interrotto';

  @override
  String get obsAgentKindSub => 'Subagente';

  @override
  String get noChecksOnCommit => 'Nessun check eseguito su questo commit.';

  @override
  String get ciCdChecks => 'CI/CD checks';

  @override
  String checksSummaryRunning(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'In esecuzione — $count job',
      one: 'In esecuzione — 1 job',
    );
    return '$_temp0';
  }

  @override
  String checksSummarySuccess(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Tutti i check sono passati — $count job',
      one: 'Tutti i check sono passati — 1 job',
    );
    return '$_temp0';
  }

  @override
  String checksSummaryNeutral(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Completato — $count job',
      one: 'Completato — 1 job',
    );
    return '$_temp0';
  }

  @override
  String checksSummaryFailure(int failed, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total job',
      one: '1 job',
    );
    return '$failed di $_temp0 non riusciti';
  }

  @override
  String checksFailingBadge(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count in errore',
      one: '1 in errore',
    );
    return '$_temp0';
  }

  @override
  String get checkCompletedSuccessfully => 'Completato con successo';

  @override
  String graphJobsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count job',
      one: '1 job',
    );
    return '$_temp0';
  }

  @override
  String matrixJobLabel(String jobId) {
    return 'Matrice: $jobId';
  }

  @override
  String get jobLogsPending => 'I log appariranno qui al termine del job.';

  @override
  String get jobLogsUnavailable => 'I log non sono disponibili per questo job.';

  @override
  String get noLogsForStep => 'Nessun log catturato per questo passaggio.';

  @override
  String get jobLogsTruncated =>
      'Log troncato — viene mostrato l\'output più recente.';

  @override
  String get fullLog => 'Log completo';

  @override
  String get copyLogs => 'Copia log';

  @override
  String get resizeGraph => 'Trascina per ridimensionare il grafo';

  @override
  String workflowRunStartedAgo(String time) {
    return 'Avviato $time';
  }

  @override
  String workflowRunCompletedAgo(String time) {
    return 'Completato $time';
  }

  @override
  String get chatBridgesTitle => 'Ponti di chat';

  @override
  String chatProviderDescription(String provider, String command) {
    return 'Menziona il bot in $provider per affidare qualcosa a un agente, o apri ticket con $command.';
  }

  @override
  String chatConnectProvider(String provider) {
    return 'Connetti $provider';
  }

  @override
  String get chatDisconnectProvider => 'Disconnetti';

  @override
  String chatConnectedTo(String botName, String teamName) {
    return '$botName in $teamName';
  }

  @override
  String get chatStateLive => 'In linea';

  @override
  String get chatStateConnecting => 'Connessione…';

  @override
  String get chatStateError => 'Errore di connessione';

  @override
  String get chatNotConnected => 'Non connesso';

  @override
  String chatStreamingUnavailable(String provider) {
    return 'Lo streaming in tempo reale è disattivato per questa app $provider: le risposte arrivano in un unico messaggio.';
  }

  @override
  String chatAdminOnly(String provider) {
    return 'Solo un amministratore può connettere $provider per questo spazio di lavoro.';
  }

  @override
  String chatConnectHint(String provider) {
    return 'Crea un\'app $provider, poi incolla qui le sue credenziali. Control Center si connette verso $provider, quindi questo server non ha bisogno di alcun indirizzo pubblico.';
  }

  @override
  String chatOpenConsole(String provider) {
    return 'Apri la console $provider';
  }

  @override
  String get chatOpenSetupGuide => 'Guida alla configurazione';

  @override
  String get chatFieldBotToken => 'Token del bot';

  @override
  String get chatFieldAppToken => 'Token a livello di app';

  @override
  String get chatFieldConfigRefreshToken => 'Token di configurazione dell\'app';

  @override
  String chatFieldOptional(String label) {
    return '$label (facoltativo)';
  }

  @override
  String chatLinkMyAccount(String provider) {
    return 'Collega il mio account $provider';
  }

  @override
  String chatLinkMyAccountDescription(String provider) {
    return 'Collega il tuo account $provider così i messaggi che invii lì sono attribuiti a te.';
  }

  @override
  String chatLinkedAs(String externalUserId) {
    return 'Collegato a $externalUserId';
  }

  @override
  String chatLinkCodeTitle(String provider) {
    return 'Collega il tuo account $provider';
  }

  @override
  String chatLinkCodeInstruction(String provider) {
    return 'Invia questo comando al bot in $provider. Funziona una volta sola e scade tra 15 minuti.';
  }

  @override
  String chatLinkCodeLinked(String provider) {
    return 'Il tuo account $provider è ora collegato: i messaggi che invii lì sono attribuiti a te.';
  }

  @override
  String get chatLinkedAccounts => 'Account collegati';

  @override
  String chatNoLinkedAccounts(String provider) {
    return 'Nessuno ha ancora collegato il proprio account $provider.';
  }

  @override
  String chatLinkedMemberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count account collegati',
      one: '1 account collegato',
    );
    return '$_temp0';
  }

  @override
  String chatLinkMethodEmail(String externalUserId) {
    return '$externalUserId · abbinato via e-mail';
  }

  @override
  String chatLinkMethodCode(String externalUserId) {
    return '$externalUserId · collegato con un codice';
  }

  @override
  String get chatUnlink => 'Scollega';

  @override
  String get chatCustomizeBot => 'Personalizza il bot';

  @override
  String get chatCustomizeBotDescription =>
      'Rinomina il bot, cambia ciò che dice di sé o rinomina il comando.';

  @override
  String get chatCustomizeBotUnavailable =>
      'Control Center ha bisogno di un token di configurazione dell\'app per modificare il bot. Riconnettiti includendone uno.';

  @override
  String chatCreateAppTitle(String provider) {
    return 'Crea l\'app $provider';
  }

  @override
  String chatCreateAppHint(String provider) {
    return 'Control Center può creare l\'app $provider per te, con i permessi e gli eventi giusti già impostati. Finirai in $provider, poi incollerai qui le credenziali.';
  }

  @override
  String get chatCreateApp => 'Crea l\'app';

  @override
  String get chatCreateAppCta => 'Crea l\'app per me';

  @override
  String get chatAppNameLabel => 'Nome dell\'app';

  @override
  String get chatBotDisplayNameLabel =>
      'Nome del bot (ciò che si digita dopo @)';

  @override
  String get chatDescriptionLabel => 'Descrizione breve';

  @override
  String get chatAgentDescriptionLabel => 'Ciò che il bot dice di saper fare';

  @override
  String get chatCommandLabel => 'Comando';

  @override
  String get chatDirectMessages => 'Messaggi diretti';

  @override
  String chatDirectMessagesHint(String provider) {
    return 'Permette di parlare col bot in un messaggio diretto. Può richiedere un piano $provider a pagamento.';
  }

  @override
  String chatAppCreated(String provider, String appId) {
    return '$provider ha creato l\'app $appId.';
  }

  @override
  String chatRemainingSteps(String provider) {
    return 'Restano alcuni passaggi, e solo $provider può farli:';
  }

  @override
  String get chatStepAppToken => 'Genera un token a livello di app';

  @override
  String get chatStepInstall => 'Installa l\'app';

  @override
  String get chatOpenAppSettings => 'Apri le impostazioni dell\'app';

  @override
  String get chatContinueToCredentials => 'Incolla le credenziali';

  @override
  String chatBotUpdated(String provider) {
    return 'Bot aggiornato in $provider.';
  }

  @override
  String chatScopesChangedReinstall(String provider) {
    return '$provider ha modificato i permessi dell\'app. Reinstallala perché abbiano effetto.';
  }

  @override
  String get chatReinstallApp => 'Reinstalla l\'app';

  @override
  String chatIconNotEditable(String provider) {
    return 'L\'icona del bot si può cambiare solo nelle impostazioni app di $provider.';
  }

  @override
  String chatCreateAppLinkHint(String provider) {
    return 'Puoi anche crearla tu in $provider, senza token. Le impostazioni qui sopra viaggiano con il link.';
  }

  @override
  String chatCreateAppWithLink(String provider) {
    return 'Crea in $provider';
  }

  @override
  String chatSetupLinkBody(String provider) {
    return '$provider si è aperto nel browser con questa configurazione precompilata. Crea l\'app lì, completa questi passaggi e torna con i token.';
  }

  @override
  String chatSetupLinkNotManageable(String provider) {
    return '$provider non comunica quale app ha creato, quindi personalizzare il bot da qui richiederà più tardi un token di configurazione dell\'app.';
  }

  @override
  String get chatStepCreateApp =>
      'Crea l\'app dalla configurazione precompilata';

  @override
  String chatStepCreateAppHint(String provider) {
    return 'Scegli uno spazio di lavoro in $provider e conferma.';
  }

  @override
  String get chatStepAppTokenHint =>
      'Basic information → app-level tokens, con l\'ambito connections:write.';

  @override
  String get chatStepInstallHint =>
      'Install app → copia il token OAuth dell\'utente bot.';

  @override
  String get calendarUseBuiltinApp => 'Usa l\'app Google di Control Center';

  @override
  String get calendarUseBuiltinAppHint =>
      'Autorizza con il tuo account Google. Nulla da configurare in Google Cloud.';

  @override
  String get calendarUseOwnClient => 'Usa il mio client Google Cloud';

  @override
  String get calendarUseOwnClientHint =>
      'Inserisci un client OAuth del tuo progetto Google Cloud.';

  @override
  String get aboutTitle => 'Informazioni';

  @override
  String get aboutAppVersion => 'Versione dell\'app';

  @override
  String get aboutServerVersion => 'Server connesso';

  @override
  String get aboutRpcCatalog => 'Catalogo RPC';

  @override
  String get aboutServerUnknown => 'Non segnalato';

  @override
  String get serverStaleTitle =>
      'Il server integrato è precedente a questa app';

  @override
  String serverStaleBody(String serverVersion, String appVersion) {
    return 'Il cc_server in esecuzione è $serverVersion mentre questa app è $appVersion. Riavvia l\'app affinché usi l\'ultima versione del server integrato; in sviluppo, ricompilalo con `dart build cli` in apps/cc_server.';
  }

  @override
  String get updateCheckButton => 'Cerca aggiornamenti';

  @override
  String get updateChecking => 'Ricerca aggiornamenti…';

  @override
  String get updateUpToDate => 'È tutto aggiornato';

  @override
  String get updateDeferredBusy =>
      'Un aggiornamento è pronto ma è in corso la registrazione di una riunione: verrà proposto al termine.';

  @override
  String get updateOpenedReleasesPage =>
      'Pagina delle versioni aperta nel browser.';

  @override
  String get updateCheckFailed => 'Ricerca aggiornamenti non riuscita';

  @override
  String updateAvailableVersion(String version) {
    return 'La versione $version è disponibile.';
  }

  @override
  String get updateBannerTitle =>
      'È disponibile una nuova versione di Control Center';

  @override
  String get updateBannerRefresh => 'Aggiorna';

  @override
  String get updateBlockedRecording =>
      'L\'aggiornamento è in pausa durante la registrazione di una riunione; la pagina si ricaricherà al termine.';

  @override
  String get settingsScopeYou => 'Tu';

  @override
  String get settingsScopeWorkspace => 'Spazio di lavoro';

  @override
  String get settingsScopeServer => 'Server';

  @override
  String get settingsProfile => 'Profilo e identità';

  @override
  String get settingsYourDevices => 'I tuoi dispositivi';

  @override
  String get settingsWorkspaceGeneral => 'Generale';

  @override
  String get settingsServerConnection => 'Connessione e stato';

  @override
  String get settingsModelProviders => 'Fornitori di modelli';

  @override
  String get settingsVoiceModels => 'Modelli vocali e per riunioni';

  @override
  String get settingsDiagnostics => 'Diagnostica e privacy';

  @override
  String get settingsAbout => 'Informazioni';

  @override
  String get settingsScopeBadgeYou => 'TU';

  @override
  String get settingsScopeBadgeDevice => 'QUESTO DISPOSITIVO';

  @override
  String get settingsScopeBadgeWorkspace => 'SPAZIO DI LAVORO';

  @override
  String get settingsScopeBadgeServer => 'SERVER';

  @override
  String get settingsProfileDescription =>
      'Il tuo nome, la tua email e l\'identità git apposta sui commit fatti per tuo conto.';

  @override
  String get settingsServerConnectionDescription =>
      'Il server a cui si connette questo client e come questo server viene condiviso (mDNS, tunnel, relay).';

  @override
  String get settingsAboutDescription =>
      'Identità della build e aggiornamenti.';

  @override
  String get settingsDiagnosticsDescription =>
      'Isolamento, indicizzazione, sincronizzazione, log e segnalazione errori di questa installazione.';

  @override
  String get settingsWorkspaceGeneralDescription =>
      'Identità, criteri e convenzioni condivisi da tutti in questo spazio di lavoro.';

  @override
  String get settingsWorkspacePolicyLabel => 'Criteri dello spazio di lavoro';

  @override
  String get settingsWorkspacePolicyDescription =>
      'Si applica a ogni membro e ogni agente di questo spazio di lavoro.';

  @override
  String get settingsSecretGlobsLabel => 'Percorsi segreti esclusi';

  @override
  String get settingsSecretGlobsHelp =>
      'Un pattern per riga. Questi percorsi sono nascosti a lettori e ospiti sulle superfici di codice, oltre ai valori predefiniti.';

  @override
  String get settingsReviewConcurrencyLabel => 'Revisori in parallelo';

  @override
  String get settingsReviewConcurrencyHelp =>
      'Quanti revisori vengono avviati in parallelo quando non è indicato un numero esplicito.';

  @override
  String get settingsWorkspaceAdminOnly =>
      'Solo gli amministratori dello spazio di lavoro possono modificarli.';

  @override
  String get chatMyAccountsTitle => 'Account di chat collegati';

  @override
  String get settingsServerSso => 'Accesso single sign-on';

  @override
  String get settingsServerSsoDescription =>
      'Accesso SAML e OpenID Connect con provisioning degli utenti';

  @override
  String get ssoProviderSaml => 'SAML';

  @override
  String get ssoProviderOidc => 'OpenID Connect';

  @override
  String get ssoEnabled => 'Attiva questa connessione';

  @override
  String get ssoEnabledDescription =>
      'Gli utenti possono accedere con questo provider';

  @override
  String get ssoEnabledDescriptionOn =>
      'L\'accesso è attivo per questo provider';

  @override
  String get ssoIdpMetadataLabel => 'XML dei metadati dell\'IdP';

  @override
  String get ssoIdpMetadataHint => 'incolla l\'XML EntityDescriptor dell\'IdP';

  @override
  String get ssoSpEntityIdLabel =>
      'Entity ID SP (opzionale, derivato dall\'URL del server)';

  @override
  String get ssoEmailAttributeLabel => 'Attributo email';

  @override
  String get ssoDisplayNameAttributeLabel => 'Attributo nome visualizzato';

  @override
  String get ssoGroupsAttributeLabel => 'Attributo gruppi';

  @override
  String get ssoClockSkewLabel => 'Tolleranza orologio (secondi)';

  @override
  String get ssoIssuerLabel => 'URL dell\'emittente';

  @override
  String get ssoClientIdLabel => 'ID client';

  @override
  String get ssoGroupsClaimLabel => 'Claim dei gruppi';

  @override
  String get ssoDefaultRoleLabel =>
      'Ruolo predefinito (member, admin, viewer, guest)';

  @override
  String get ssoRoleMapLabel => 'Mappa gruppo → ruolo (JSON)';

  @override
  String get ssoAutoMemberLabel =>
      'Aggiungi gli utenti a ogni workspace al primo accesso';

  @override
  String get ssoAutoMemberDescription =>
      'Disattiva per richiedere un invito per ogni workspace';

  @override
  String get ssoAllowJitLabel =>
      'Esegui il provisioning degli utenti sconosciuti al primo accesso';

  @override
  String get ssoAllowJitDescription =>
      'Disattiva per rifiutare gli utenti senza account esistente';

  @override
  String get ssoAllowIdpInitiatedLabel => 'Accetta accessi avviati dall\'IdP';

  @override
  String get ssoAllowIdpInitiatedDescription =>
      'Solo per portali IdP che avviano le app direttamente';

  @override
  String get ssoWantResponseSignedLabel => 'Richiedi busta di risposta firmata';

  @override
  String get ssoWantResponseSignedDescription =>
      'Le firme delle asserzioni sono sempre obbligatorie';

  @override
  String get ssoSaveButton => 'Salva';

  @override
  String get ssoTestConnectionButton => 'Testa connessione';

  @override
  String get ssoTestConnectionOk => 'La connessione funziona:';

  @override
  String get ssoCopySpMetadata => 'Copia metadati SP';

  @override
  String get ssoCopySpMetadataDone => 'Metadati SP copiati negli appunti';

  @override
  String get ssoSavedToast => 'Impostazioni single sign-on salvate';

  @override
  String get ssoUnavailable =>
      'Questo server non espone le impostazioni single sign-on. Aggiorna il binario del server e riprova.';

  @override
  String get ssoScimCardTitle => 'Provisioning utenti (SCIM)';

  @override
  String get ssoScimDescription =>
      'Punta il connettore SCIM del tuo provider di identità all\'endpoint qui sotto con un token bearer. Il deprovisioning revoca sessioni e accessi ai workspace in pochi secondi. Il server deve essere raggiungibile dall\'IdP (tunnel o URL pubblica).';

  @override
  String get ssoScimEndpoint => 'Endpoint SCIM';

  @override
  String get ssoScimEndpointUnknownOrigin =>
      'Imposta prima l\'URL pubblica del server o attiva un tunnel';

  @override
  String get ssoScimRegenerate => 'Rigenera token';

  @override
  String get ssoScimRegenerateConfirm =>
      'Generare un nuovo token bearer SCIM? Il token precedente smetterà subito di funzionare.';

  @override
  String get ssoScimTokenTitle => 'Token bearer';

  @override
  String get ssoScimTokenPresent => 'Un token è configurato';

  @override
  String get ssoScimTokenAbsent => 'Nessun token: genera uno per attivare SCIM';

  @override
  String get ssoScimTokenOnce => 'Token SCIM (mostrato una volta)';

  @override
  String ssoSignInWith(String provider) {
    return 'Accedi con $provider';
  }

  @override
  String get ssoProbeFailed =>
      'Impossibile raggiungere quel server per il single sign-on';

  @override
  String get ssoOpensBrowser => 'Apre il browser per completare l\'accesso';

  @override
  String get ssoWaitingForBrowser =>
      'In attesa che il browser completi l\'accesso…';

  @override
  String get ssoBrowserOpenFailed =>
      'Impossibile aprire il browser per l\'accesso single sign-on';

  @override
  String get ssoUseManualPairing =>
      'Accedi con un codice invito o una chiave di abbinamento';

  @override
  String get ssoHideManualPairing => 'Nascondi l\'abbinamento manuale';

  @override
  String get ssoClientIdHint =>
      'Client pubblico (PKCE) — nessun secret necessario';

  @override
  String get ssoClientSecretLabel => 'Segreto client (opzionale)';

  @override
  String get ssoClientSecretHintUnset =>
      'Necessario solo per client IdP confidenziali';

  @override
  String get ssoClientSecretHintSet =>
      'Un segreto è salvato — lascia vuoto per mantenerlo';

  @override
  String get ssoPairingToggle =>
      'Consenti l\'abbinamento manuale (codici invito e chiavi di abbinamento)';

  @override
  String get ssoPairingToggleDescription =>
      'Disattiva per riservare l\'accesso al single sign-on — i nuovi dispositivi arrivano tramite login SSO; quelli esistenti continuano a funzionare';

  @override
  String get ssoPairConfirmTitle => 'Connettersi al server?';

  @override
  String ssoPairConfirmBody(String server) {
    return 'È arrivata una credenziale di accesso per $server, ma nessun accesso è stato avviato da questa app. Connettersi a questo server?';
  }

  @override
  String get ssoPairConfirmConnect => 'Connetti';

  @override
  String get ssoPairConfirmCancel => 'Ignora';

  @override
  String get forgeConnections => 'Hosting del codice';

  @override
  String get connect => 'Connetti';

  @override
  String get disconnect => 'Disconnetti';

  @override
  String get notConnected => 'Non connesso';

  @override
  String get checkingConnection => 'Verifica della connessione…';

  @override
  String get fromEnvironment => 'dall\'ambiente';

  @override
  String get fromGhCli => 'dalla CLI gh';

  @override
  String forgeTokenTitle(String forge) {
    return 'Token $forge';
  }

  @override
  String get connectAForge =>
      'Collega un host di codice per caricare le pull request';

  @override
  String get settingsAudio => 'Audio';

  @override
  String get settingsAudioDescription =>
      'Microfono, dettatura, rilevamento delle riunioni e uscita dei paesaggi sonori.';

  @override
  String get voiceInputMicrophoneSection => 'Microfono';

  @override
  String get voiceInputBehaviorSection => 'Dettatura e riunioni';

  @override
  String get soundscapeOutputSection => 'Uscita dei paesaggi sonori';

  @override
  String get soundscapeOutputDevice => 'Dispositivo di uscita';

  @override
  String get soundscapeOutputDefaultHint =>
      'L\'audio d\'ambiente viene riprodotto tramite l\'uscita predefinita di sistema.';

  @override
  String get soundscapeOutputGone =>
      'Il dispositivo di uscita selezionato non è più collegato: viene usata l\'uscita predefinita di sistema finché non ne scegli un altro.';

  @override
  String get reviewHubOverview => 'Panoramica';

  @override
  String get reviewHubAreas => 'Aree';

  @override
  String get reviewHubImpact => 'Impatto';

  @override
  String get reviewHubProvisional => 'Provvisorio';

  @override
  String get reviewHubAiSummary => 'Riepilogo IA';

  @override
  String get reviewHubRisks => 'Rischi';

  @override
  String reviewHubAreaFindingsCount(int count) {
    return '$count rilievi';
  }

  @override
  String reviewHubRepoWideCount(int count) {
    return '+$count a livello di repository';
  }

  @override
  String get reviewHubIntroBody =>
      'Gli agenti analizzano il diff, mappano le aree modificate e raggiungono un verdetto consensuale.';

  @override
  String get reviewHubStarted => 'Revisione avviata';

  @override
  String get reviewHubAlreadyRunning =>
      'Una revisione è già in corso per questa pull request';

  @override
  String get reviewHubAutoPublish => 'Pubblicazione automatica';

  @override
  String get reviewHubAutoPublishTooltip =>
      'Pubblica automaticamente su GitHub le revisioni completate';

  @override
  String get reviewHubChangedSymbols => 'Simboli modificati';

  @override
  String get reviewHubReadingOrder => 'Ordine di lettura';

  @override
  String get reviewHubReadingOrderHint =>
      'Prima le fondamenta, poi i consumatori, poi i test';

  @override
  String get reviewHubOpenInDiff => 'Apri nel diff';

  @override
  String reviewHubLayerPosition(int index, int total) {
    return 'Passo $index di $total';
  }

  @override
  String get reviewHubNoReadingOrder =>
      'Nessun ordine di lettura calcolato per quest’area';

  @override
  String get reviewHubSymbolsFromBase => 'Dall’indice di base';

  @override
  String get reviewHubSymbolsFromBaseTooltip =>
      'Il worktree della pull request non è ancora indicizzato, quindi questi intervalli di righe vengono dal ramo di base e possono essere imprecisi.';

  @override
  String reviewHubSymbolLines(int count) {
    return '$count righe';
  }

  @override
  String get reviewHubImpactGraph => 'Grafo';

  @override
  String get reviewHubImpactList => 'Elenco';

  @override
  String get reviewHubImpactChanged => 'Modificato in questa PR';

  @override
  String reviewHubImpactHops(int hops) {
    return 'A $hops salto/i';
  }

  @override
  String reviewHubImpactMore(int count, String file) {
    return '$count altri in $file';
  }

  @override
  String get reviewHubRisk => 'Rischio';

  @override
  String get reviewHubRiskLow => 'Basso';

  @override
  String get reviewHubRiskModerate => 'Moderato';

  @override
  String get reviewHubRiskHigh => 'Alto';

  @override
  String get reviewHubRiskFactors => 'Cosa determina questo punteggio';

  @override
  String get reviewHubOrderByRisk => 'Ordina per rischio';

  @override
  String get reviewHubFactorLinesChanged => 'Righe modificate';

  @override
  String get reviewHubFactorFileCount => 'File';

  @override
  String get reviewHubFactorImpact => 'Dipendenti';

  @override
  String get reviewHubFactorBlockingFindings => 'Rilievi bloccanti';

  @override
  String get reviewHubFactorCriticalPath => 'File del percorso critico';

  @override
  String get reviewHubFactorContractBreaking => 'Modifiche API non compatibili';

  @override
  String get reviewHubFactorVisualChange => 'Modifica visiva';

  @override
  String get reviewHubFactorDependencyChurn => 'Modifiche alle dipendenze';

  @override
  String get reviewHubFactorNoCoveringTests => 'Nessun test di copertura';

  @override
  String get reviewHubStaticRule => 'Regola statica';

  @override
  String reviewHubStaticRuleTooltip(String rule) {
    return 'Trovato da una regola deterministica ($rule) su una riga aggiunta da questa pull request, non da un agente revisore.';
  }

  @override
  String get reviewHubCiSignals => 'Segnali CI';

  @override
  String get reviewHubCiAllPassing => 'Tutti i controlli passano';

  @override
  String get reviewHubCiLogsNotPublished => 'Log non ancora pubblicati';

  @override
  String get reviewHubCiFailingTests => 'Test falliti';

  @override
  String reviewHubCiTouchesFile(String file) {
    return 'Punta a $file';
  }

  @override
  String get reviewHubCiUnavailable =>
      'Questa forge non espone il dettaglio CI per job';

  @override
  String reviewHubCoveringTests(int count) {
    return 'Coperto da $count file di test';
  }

  @override
  String get reviewHubNoCoveringTests =>
      'Nessun file di test fa riferimento a quest’area';

  @override
  String get reviewHubCoverageUnknown =>
      'Impossibile determinare la copertura dei test (repository non indicizzato)';

  @override
  String get reviewHubDependencies => 'Dipendenze';

  @override
  String get reviewHubDepsAdded => 'Aggiunte';

  @override
  String get reviewHubDepsRemoved => 'Rimosse';

  @override
  String get reviewHubDepsUpgraded => 'Versione modificata';

  @override
  String get reviewHubDepsMajorBump => 'Maggiore';

  @override
  String get reviewHubDepsBestEffort =>
      'Questo formato di lockfile è analizzato in modo approssimativo: verifica prima di fidarti';

  @override
  String get reviewHubDepsNone => 'Nessuna dipendenza modificata';

  @override
  String reviewHubDeltaSummary(int resolved, int added, int open) {
    return 'Dall’ultima revisione: $resolved risolti · $added nuovi · $open ancora aperti';
  }

  @override
  String get reviewHubBadgeNew => 'Nuovo';

  @override
  String get reviewHubBadgeStillOpen => 'Ancora aperto';

  @override
  String reviewHubDeltaPreviousSha(String sha) {
    return 'Revisionato in precedenza a $sha';
  }

  @override
  String get reviewHubAskArea => 'Fai una domanda su quest’area';

  @override
  String get reviewHubAskPlaceholder => 'es. perché serve una nuova colonna?';

  @override
  String get reviewHubAskSubmit => 'Chiedi';

  @override
  String get reviewHubAskSent =>
      'Domanda inviata: la risposta apparirà nella conversazione';

  @override
  String get reviewHubAskNoAgent =>
      'Nessun agente disponibile per rispondere in questo workspace';

  @override
  String get reviewHubQuestions => 'Domande';

  @override
  String get reviewHubFixAllInArea =>
      'Correggi tutti i rilievi aperti di quest’area';

  @override
  String get reviewHubLearnings => 'Apprendimenti';

  @override
  String get reviewHubGuidelines => 'Linee guida di revisione';

  @override
  String get reviewHubSuppressions => 'Pattern ignorati';

  @override
  String get reviewHubAddGuideline => 'Aggiungi linea guida';

  @override
  String get reviewHubGuidelineGlobHint =>
      'Glob di percorso (facoltativo), es. lib/api/**';

  @override
  String get reviewHubGuidelineTextHint => 'Cosa devono controllare i revisori';

  @override
  String reviewHubStatsSummary(int made, int addressed) {
    return '$made rilievi · $addressed gestiti';
  }

  @override
  String get reviewHubNoLearnings =>
      'Ancora nulla — ignora un rilievo o aggiungi una linea guida';

  @override
  String get webConnectTitle => 'Connetti a Control Center';

  @override
  String get webConnectSubtitle =>
      'Contatta un cc-server in esecuzione via WebSocket. La tua chiave resta su questo dispositivo.';

  @override
  String get webConnectServerLabel => 'Server';

  @override
  String get webConnectDeviceIdLabel => 'ID dispositivo';

  @override
  String get webConnectPairingKeyLabel => 'Chiave di accoppiamento';

  @override
  String get webConnectPairingKeyHint => 'incolla la PSK';

  @override
  String get webConnectStayConnected => 'Resta connesso su questo dispositivo';

  @override
  String get webConnectStayConnectedDetail =>
      'Resta connesso su questo dispositivo (salva la chiave in questo browser)';

  @override
  String failedToCreateWorkspace(String error) {
    return 'Creazione dello spazio di lavoro non riuscita: $error';
  }

  @override
  String committedRelative(String relative) {
    return 'commit effettuato $relative';
  }

  @override
  String get selectAgents => 'Seleziona agenti';

  @override
  String agentCountPlural(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count agenti',
      one: '1 agente',
    );
    return '$_temp0';
  }
}
