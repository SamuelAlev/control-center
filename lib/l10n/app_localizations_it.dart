// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

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
  String get serverConnectionRestartHint =>
      'Riavvia Control Center per applicare le modifiche alla connessione.';

  @override
  String get serverConnectionReloadHint =>
      'Ricarica la pagina per riconnetterti con queste modifiche.';

  @override
  String get pairedClients => 'Client associati';

  @override
  String get pairedClientsDescription =>
      'App e dispositivi associati a questo server. Associane un altro per collegare un secondo browser, un\'app desktop o un telefono.';

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
  String get noPairedClients => 'Nessun client associato per ora.';

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
  String get profileStateOpenHint => 'Attualmente aperte';

  @override
  String get profileStateMergedHint => 'Cronologia unita';

  @override
  String get profileStateClosedHint => 'Chiuse, non unite';

  @override
  String get profileNoPrsForFilter =>
      'Nessuna pull request per gli stati selezionati';

  @override
  String get byAuthorPrefix => 'di';

  @override
  String get youLabel => 'tu';

  @override
  String get readyToMerge => 'Pronto per il merge';

  @override
  String get laneReadyHint => 'Controlli verdi';

  @override
  String get laneReviewHint => 'In attesa di te';

  @override
  String get inProgress => 'In corso';

  @override
  String get laneInProgressHint => 'Aperto · in lavorazione';

  @override
  String get needsAttention => 'Richiede attenzione';

  @override
  String get laneAttentionHint => 'In errore o obsoleto';

  @override
  String get drafts => 'Bozze';

  @override
  String get laneDraftsHint => 'Non ancora aperte';

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
  String get mergeReadyAction => 'Unisci pronte';

  @override
  String get nothingInLane => 'Niente in questa corsia';

  @override
  String get nothingInLaneHint =>
      'Scegli un\'altra corsia sopra o mostra tutte le PR aperte.';

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
  String get mergeReadyConfirmTitle => 'Unire le PR pronte?';

  @override
  String mergeReadyConfirmBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Unire con squash $count PR pronte? Azione irreversibile.',
      one: 'Unire con squash 1 PR pronta? Azione irreversibile.',
    );
    return '$_temp0';
  }

  @override
  String mergedCountPrs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count PR unite',
      one: '1 PR unita',
    );
    return '$_temp0';
  }

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
  String get kbSelect => 'seleziona';

  @override
  String get kbMerge => 'unisci';

  @override
  String get kbOpen => 'apri';

  @override
  String get kbPeek => 'anteprima';

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
      'Denominazione dei branch, voce, ricerca semantica, privacy e registrazione.';

  @override
  String get agentRegistry => 'Registro degli agenti';

  @override
  String get settingsGroupGeneral => 'Generale';

  @override
  String get settingsGroupAgents => 'Agenti';

  @override
  String get settingsGroupResources => 'Risorse';

  @override
  String get filterSettingsHint => 'Filtra le impostazioni';

  @override
  String get needsSetupLabel => 'Configurazione necessaria';

  @override
  String noSettingsMatch(String query) {
    return 'Nessuna impostazione corrisponde a «$query»';
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
  String get addRepoBrowseIntro =>
      'Sfoglia le cartelle sulla macchina che esegue il server e scegli un checkout git da registrare.';

  @override
  String get addThisFolder => 'Aggiungi questa cartella';

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
  String get agentsLabel => 'AGENTI';

  @override
  String get agentsMentionSection => 'Agenti';

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
  String allAgentsCount(int count) {
    return 'Tutti gli agenti · $count';
  }

  @override
  String get allCommits => 'Tutti i commit';

  @override
  String get allSessionsReset =>
      'Tutte le sessioni sandbox sono state ripristinate.';

  @override
  String get allSources => 'Tutte le fonti';

  @override
  String get allStarBadge => 'All-Star';

  @override
  String get allTimeLabel => 'Totale';

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
  String get avgDuration => 'Durata media';

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
  String get blockingLabel => 'Bloccante';

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
  String get centurionBadge => 'Centurione';

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
  String get closeThread => 'Chiudi discussione';

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
  String get continueLabel => 'Continua';

  @override
  String get conversationMode => 'Modalità conversazione';

  @override
  String get convertToGroup => 'Convertire in gruppo?';

  @override
  String get convertToGroupBody =>
      'Aggiungere un altro agente trasforma questa conversazione in una conversazione di gruppo.';

  @override
  String cookieRulesCount(int count) {
    return '$count regole cookie';
  }

  @override
  String get copied => 'Copiato!';

  @override
  String get copy => 'Copia';

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
  String defaultPort(int port) {
    return 'Predefinito: $port.';
  }

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
  String get diffWorkerPool => 'Pool di worker';

  @override
  String get directMessage => 'Messaggio diretto';

  @override
  String get directMessages => 'Messaggi diretti';

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
  String get earnTiersDescription => 'Ottieni livelli usando il Control Center';

  @override
  String get edit => 'Modifica';

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
  String get onboardingDiarizationTitle =>
      'Diarizzazione dei parlanti (facoltativa)';

  @override
  String get onboardingDiarizationSubtitle =>
      'Scarica per etichettare ciascun parlante (Persona 1, Persona 2…) nelle note delle riunioni. Puoi aggiungerlo in seguito nelle impostazioni.';

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
  String get erroredLabel => 'Con errori';

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
  String get firstReviewBadge => 'Prima revisione';

  @override
  String get fix => 'Correggi';

  @override
  String get fixSelected => 'Correggi selezione';

  @override
  String get flawlessBadge => 'Senza errori';

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
  String get githubStatusAllOperational => 'Tutti i sistemi operativi';

  @override
  String get githubStatusComponents => 'Componenti';

  @override
  String get githubStatusFetchFailed =>
      'Impossibile raggiungere githubstatus.com';

  @override
  String get githubStatusIncidents => 'Incidenti attivi';

  @override
  String get githubStatusOpenInBrowser => 'Apri githubstatus.com';

  @override
  String get githubStatusRefresh => 'Aggiorna';

  @override
  String get githubStatusTitle => 'Stato di GitHub';

  @override
  String githubStatusUpdated(String time) {
    return 'Aggiornato $time';
  }

  @override
  String lastChecked(String time) {
    return 'Controllato $time';
  }

  @override
  String get lastCheckedRecently => 'Controllato di recente';

  @override
  String get githubToken => 'Token GitHub';

  @override
  String get giveAgentsAMemory => 'Dai una memoria agli agenti.';

  @override
  String get giveYourWorkAHome => 'Dai una casa al tuo lavoro.';

  @override
  String get goBack => 'Torna indietro';

  @override
  String get goForward => 'Vai avanti';

  @override
  String get googleFonts => 'Google Fonts';

  @override
  String get groupLabel => 'Gruppo';

  @override
  String get groupName => 'Nome del gruppo';

  @override
  String get groups => 'Gruppi';

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
  String get hotStreakBadge => 'Serie calda';

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
  String get idleStatus => 'Inattivo';

  @override
  String get images => 'Immagini';

  @override
  String get inFlightLabel => 'In corso';

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
  String jobCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 's',
      one: '',
    );
    return '$count lavoro$_temp0';
  }

  @override
  String get justNow => 'adesso';

  @override
  String get keepMessages => 'Mantieni messaggi';

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
  String get keybindingConversationTab => 'Scheda conversazione';

  @override
  String get keybindingCreateANewAgentDescription => 'Crea un nuovo agente';

  @override
  String get keybindingCreateANewGroupChannelDescription =>
      'Crea un nuovo canale di gruppo';

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
  String get keybindingFilesChangedTab => 'Scheda file modificati';

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
  String get keybindingGoToAnalytics => 'Vai all\'analisi';

  @override
  String get keybindingGoToDashboard => 'Vai alla bacheca';

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
  String get keybindingNavigateToTheAnalyticsDashboardDescription =>
      'Naviga alla bacheca dell\'analisi';

  @override
  String get keybindingNavigateToTheGlobalDashboardDescription =>
      'Naviga alla bacheca globale';

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
  String get keybindingNewDirectMessage => 'Nuovo messaggio diretto';

  @override
  String get keybindingNewGroup => 'Nuovo gruppo';

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
  String get keybindingRefreshAnalyticsDataDescription =>
      'Aggiorna dati dell\'analisi';

  @override
  String get keybindingRefreshDashboardDataDescription =>
      'Aggiorna dati della bacheca';

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
  String get keybindingStartANewDirectMessageDescription =>
      'Inizia un nuovo messaggio diretto';

  @override
  String get keybindingSwitchBetweenLightAndDarkModeDescription =>
      'Cambia tra modalità chiara e scura';

  @override
  String get keybindingSwitchToTheConversationTabDescription =>
      'Passa alla scheda della conversazione';

  @override
  String get keybindingSwitchToTheEighthWorkspaceDescription =>
      'Passa all\'ottavo spazio di lavoro';

  @override
  String get keybindingSwitchToTheFifthWorkspaceDescription =>
      'Passa al quinto spazio di lavoro';

  @override
  String get keybindingSwitchToTheFilesChangedTabDescription =>
      'Passa alla scheda dei file modificati';

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
  String lastMonths(int count) {
    return 'Ultimi $count mesi';
  }

  @override
  String get latestLabel => 'Più recenti';

  @override
  String get leaderboardLabel => 'CLASSIFICA';

  @override
  String get leaderboardLabelShort => 'Classifica';

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
  String levelLabel(int level) {
    return 'Livello $level';
  }

  @override
  String get loadingAgents => 'Caricamento agenti…';

  @override
  String get loadingModels => 'Caricamento modelli…';

  @override
  String get lockedLabel => 'Bloccato';

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
    return 'In ascolto su 127.0.0.1:$port.';
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
  String get mergeMasterBadge => 'Maestro dei merge';

  @override
  String get merged => 'Unita';

  @override
  String get messagePlaceholder =>
      'Messaggio… (@ per menzionare, / per comandi)';

  @override
  String get navConversations => 'Conversazioni';

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
  String get navAnalytics => 'Analisi';

  @override
  String get navDashboard => 'Bacheca';

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
  String get newGroup => 'Nuovo gruppo';

  @override
  String get newLabel => 'Nuovo';

  @override
  String get newMessage => 'Nuovo messaggio';

  @override
  String get newPolicy => 'Nuova politica';

  @override
  String get newPrToReview => 'Nuova PR da revisionare';

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
  String get noAgentsConfigured => 'Nessun agente configurato';

  @override
  String get noAgentsDiscovered => 'Nessun agente scoperto';

  @override
  String get noAgentsDiscoveredHint =>
      'Clicca \"Scopri\" per cercare file AGENTS.md o \"Aggiungi agente\" per configurarne uno manualmente';

  @override
  String get noAgentsMatchSearch => 'Nessun agente corrisponde alla ricerca';

  @override
  String get noAgentsRegisteredYet => 'Nessun agente registrato ancora';

  @override
  String get noArticlesYet => 'Ancora nessun articolo';

  @override
  String get noArticlesYetBody => 'Gli articoli dei tuoi feed appariranno qui.';

  @override
  String get noData => 'Nessun dato';

  @override
  String get noDirectMessagesYet => 'Nessun messaggio diretto ancora';

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
  String get noGroupsYet => 'Nessun gruppo ancora';

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
  String get notEarnedYet => 'Non ancora ottenuto';

  @override
  String get notFoundLabel => 'Non trovato';

  @override
  String get notYetSpawned => 'Non ancora avviato';

  @override
  String get notes => 'Note';

  @override
  String get notificationAgentFinished => 'Agente completato';

  @override
  String get notificationExternalPr => 'PR esterne';

  @override
  String get notificationNewMessages => 'Nuovi messaggi';

  @override
  String get notificationPrMerged => 'PR unita';

  @override
  String get notificationPrPublished => 'PR pubblicata';

  @override
  String get notifications => 'Notifiche';

  @override
  String get notifyAgentRunCompleted =>
      'Notifica quando un agente completa un\'esecuzione.';

  @override
  String get notifyExternalPr =>
      'Notifica quando viene rilevata una nuova PR tramite polling.';

  @override
  String get notifyNewMessages =>
      'Notifica per nuovi messaggi degli agenti in altri canali.';

  @override
  String get notifyPrMerged => 'Notifica quando una pull request viene unita.';

  @override
  String get notifyPrPublished =>
      'Notifica quando un agente pubblica una pull request.';

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
  String get openAction => 'Apri';

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
  String get perfectionistBadge => 'Perfezionista';

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
  String get portLabel => 'Porta';

  @override
  String get postingEllipsis => 'Pubblicazione...';

  @override
  String get prCommits => 'Commit';

  @override
  String get prDescriptionPlaceholder => 'Descrizione della PR in markdown...';

  @override
  String get prDraftCreated => 'Bozza di PR creata';

  @override
  String get prMachineBadge => 'Macchina da PR';

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
  String get priorityReviews => 'Revisioni prioritarie';

  @override
  String get priorityReviewsDescription =>
      'Revisioni prioritarie e panoramica delle repository.';

  @override
  String get progressLabel => 'Progresso';

  @override
  String get proposeToCreateDomain =>
      'Proponi un fatto o una politica per crearne uno.';

  @override
  String get prsCreated => 'PR create';

  @override
  String get prsCreatedLabel => 'PR create';

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
  String get resolve => 'Risolvi';

  @override
  String get resolved => 'Risolto';

  @override
  String get restartServerToApply =>
      'Riavvia il server per applicare le modifiche.';

  @override
  String get restartShell => 'Riavvia shell';

  @override
  String get restartToApply => 'Riavvia il server per applicare le modifiche.';

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
  String get reviewsLabel => 'Revisioni';

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
  String get runningStatus => 'In esecuzione';

  @override
  String get runs => 'Esecuzioni';

  @override
  String get runsAcrossAllAgents => 'Esecuzioni su tutti gli agenti';

  @override
  String get runsLabel => 'Esecuzioni';

  @override
  String get sandboxBackendNativeLabel => 'Native sandbox';

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
  String get sharpshooterBadge => 'Tiratore scelto';

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
  String get startFresh => 'Ricomincia da capo';

  @override
  String get startLabel => 'Avvia';

  @override
  String get startOnAppLaunch => 'Avvia all\'apertura dell\'app';

  @override
  String get startServerToAccept =>
      'Avvia il server per accettare connessioni MCP.';

  @override
  String get stats => 'Statistiche';

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
  String get streaksLabel => 'Serie';

  @override
  String get strictIdentityCheck => 'Verifica rigorosa dell\'identità';

  @override
  String get success => 'Successo';

  @override
  String get successLabel => 'Successo';

  @override
  String get successLabelShort => 'Successo';

  @override
  String get successRate => 'Tasso di successo';

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
  String get tapBadgeToLevelUp =>
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
  String get threadLabel => 'Discussione';

  @override
  String get throughput => 'Produttività';

  @override
  String get ticketLabel => 'TICKET';

  @override
  String tierLabel(String tier) {
    return 'Livello $tier';
  }

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
  String get topPerformerLabel => 'MIGLIOR PERFOMER';

  @override
  String get topPerformersDescription =>
      'Migliori performer, produttività e salute dello spazio di lavoro.';

  @override
  String get topic => 'Argomento';

  @override
  String get topicHint => 'es: Tech Stack, Design System';

  @override
  String get totalRuns => 'Esecuzioni totali';

  @override
  String get totalRunsLabel => 'Esecuzioni totali';

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
  String workerLabel(int index) {
    return 'Worker $index';
  }

  @override
  String workersCount(int count) {
    return '$count workers';
  }

  @override
  String get workingMemory => 'Memoria di lavoro';

  @override
  String get workspaceName => 'Nome dello spazio di lavoro';

  @override
  String get workspaceNotesScratchpad =>
      'Note dello spazio di lavoro e blocco appunti';

  @override
  String get workspacePulse => 'BATTITO SPAZIO DI LAVORO';

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
  String get yourAchievements => 'I TUOI RISULTATI';

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
  String get sidebarGroupWork => 'Lavoro';

  @override
  String get sidebarGroupTeam => 'Team';

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
  String get dashboardGreeting => 'Grüezi';

  @override
  String get dashboardSubtitle => 'Ecco a cosa stanno lavorando i tuoi agenti.';

  @override
  String get recentActivityTitle => 'Attività recente';

  @override
  String get noRecentActivity => 'Ancora nessuna attività recente';

  @override
  String get noRecentActivitySubtitle =>
      'Le esecuzioni degli agenti, le pull request e i messaggi appariranno qui.';

  @override
  String get noWorkspace => 'Nessuno spazio di lavoro';

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
  String get sidebarGroupKnowledge => 'Conoscenza';

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
  String get noAuthorMatches => 'Nessun risultato';

  @override
  String openedAgo(String age) {
    return 'Aperto $age';
  }

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
  String get activeFleet => 'Flotta attiva';

  @override
  String agentsCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count agenti',
      one: '1 agente',
    );
    return '$_temp0';
  }

  @override
  String get blockedStatus => 'Bloccato';

  @override
  String get failedStatus => 'Fallito';

  @override
  String get neverRunStatus => 'Mai eseguito';

  @override
  String get noActiveRun => 'Nessuna esecuzione attiva';

  @override
  String get allPullRequests => 'Tutte le pull request';

  @override
  String get clearAll => 'Cancella tutto';

  @override
  String get needsYouNow => 'Richiede la tua attenzione';

  @override
  String get pipelinesSectionTitle => 'Pipeline';

  @override
  String get allRuns => 'Tutte le esecuzioni';

  @override
  String get triage => 'Valuta';

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
  String reviewsAwaitingYou(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count revisioni',
      one: '1 revisione',
    );
    return '$_temp0 in attesa';
  }

  @override
  String reviewsOverTwoDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count da oltre 2 giorni',
      one: '1 da oltre 2 giorni',
    );
    return '$_temp0';
  }

  @override
  String agentBlockedTitle(String name) {
    return '$name è bloccato';
  }

  @override
  String get agentBlockedSubtitle => 'In attesa della tua conferma';

  @override
  String get pipelineFailedTitle => 'Pipeline fallito';

  @override
  String prStaleTitle(String number) {
    return 'PR $number obsoleta';
  }

  @override
  String get prStaleSubtitle => 'Nessuna attività recente';

  @override
  String get reviewRequestedBadge => 'Revisione richiesta';

  @override
  String get draftBadge => 'Bozza';

  @override
  String get staleLabel => 'Obsoleta';

  @override
  String stepsProgress(int done, int total) {
    return '$done di $total passaggi';
  }

  @override
  String get allCaughtUpSubtitle =>
      'Nessuna revisione, blocco o errore richiede la tua attenzione ora.';

  @override
  String dashboardGreetingNamed(String name) {
    return 'Grüezi, $name';
  }

  @override
  String workspaceEyebrow(String name) {
    return 'Spazio $name';
  }

  @override
  String get pipelineTriggerNode => 'Trigger';

  @override
  String get priorityReviewsTooltip =>
      'PR aperte che richiedono la tua revisione e sono in attesa da più di 24 ore.';

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
  String get diff => 'Diff';

  @override
  String get preview => 'Anteprima';

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
  String get meetingsEmpty =>
      'Ancora nessuna riunione. Avvia una registrazione per acquisirne una.';

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
  String get meetingsOverlineKnowledge => 'Conoscenza';

  @override
  String get meetingsOverlineEngine => 'Riconoscimento vocale sul dispositivo';

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
  String get devices => 'Dispositivi';

  @override
  String get devicesSettingsDescription =>
      'Associa e gestisci i telefoni che possono controllare quest\'app in remoto.';

  @override
  String get connectedLabel => 'Connesso';

  @override
  String get ideTabExplorer => 'Esplora';

  @override
  String get ideTabSourceControl => 'Sorgenti';

  @override
  String get ideTabPullRequests => 'PR';

  @override
  String get ideNewTerminal => 'Nuovo terminale';

  @override
  String get ideOpenChat => 'Apri chat';

  @override
  String get ideCloseTab => 'Chiudi scheda';

  @override
  String get ideSplitEditor => 'Dividi editor';

  @override
  String get ideCloseGroup => 'Chiudi gruppo';

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
  String get ideFileSearchFailed => 'Impossibile cercare file';

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
}
