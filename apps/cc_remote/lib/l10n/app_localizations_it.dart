// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appTitle => 'Control Center';

  @override
  String get back => 'Indietro';

  @override
  String get cancel => 'Cancel';

  @override
  String get retry => 'Riprova';

  @override
  String get tryAgain => 'Riprova';

  @override
  String get settings => 'Impostazioni';

  @override
  String get refresh => 'Aggiorna';

  @override
  String get approve => 'Approva';

  @override
  String get deny => 'Nega';

  @override
  String get continueLabel => 'Continua';

  @override
  String get agentQuestionHeader => 'Domanda per te';

  @override
  String get agentQuestionAnsweredLabel => 'Risposto';

  @override
  String get agentQuestionSkip => 'Salta';

  @override
  String get agentQuestionSkippedLabel => 'Saltata';

  @override
  String get agentQuestionFreeformHint => 'Scrivi la tua risposta…';

  @override
  String get agentApprovalRequired => 'Approvazione richiesta';

  @override
  String get copyCommand => 'Copia comando';

  @override
  String get approveAndRemember => 'Approva per 8 ore';

  @override
  String get decline => 'Rifiuta';

  @override
  String get confirm => 'Confirm';

  @override
  String get send => 'Invia';

  @override
  String get close => 'Chiudi';

  @override
  String get expand => 'Espandi';

  @override
  String get zoomIn => 'Ingrandisci';

  @override
  String get zoomOut => 'Riduci';

  @override
  String get resetZoom => 'Reimposta lo zoom';

  @override
  String get scanQrPrompt =>
      'Scansiona il QR da Control Center per associare questo telefono.';

  @override
  String get scanQrHelp =>
      'Apri la fotocamera e inquadra il QR mostrato in Control Center. Questo telefono si collega direttamente su un collegamento privato.';

  @override
  String get connectingToMac => 'Connessione a Control Center…';

  @override
  String get connectingDetail =>
      'Creazione di un collegamento diretto e sicuro.';

  @override
  String get identityChangedTitle => 'Identità del server modificata';

  @override
  String get identityChangedBody =>
      'Questo server non corrisponde più all’identità salvata al momento dell’associazione. Potrebbe essere stato reinstallato — oppure qualcosa sta intercettando la connessione. Per sicurezza, questo dispositivo non si connette. Rimuovi l’associazione, poi scansiona un nuovo QR da Control Center per associarti di nuovo.';

  @override
  String get removePairing => 'Rimuovi associazione';

  @override
  String get couldntConnect => 'Impossibile connettersi';

  @override
  String get pendingPairingTitle => 'Connettersi a questo server?';

  @override
  String get pendingPairingBody =>
      'Un link ha chiesto a Control Center di associarsi a questo server. Continua solo se l’hai avviato tu.';

  @override
  String get connect => 'Connetti';

  @override
  String get failureNotPaired =>
      'Non associato — scansiona il QR da Control Center';

  @override
  String get failureUnreachable =>
      'Impossibile raggiungere il server su nessun percorso — verifica che sia in esecuzione o prova sulla stessa rete';

  @override
  String get failureIdentityChanged =>
      'L’identità del server è cambiata — se è stato reinstallato, riassocia questo dispositivo';

  @override
  String get failureAuthRejected =>
      'Il server ha rifiutato questo dispositivo — riassocialo da Control Center';

  @override
  String get failureUnknown => 'Impossibile connettersi — tocca per riprovare';

  @override
  String get statusConnected => 'Connesso';

  @override
  String get statusConnecting => 'Connessione';

  @override
  String get statusOffline => 'Non in linea';

  @override
  String get statusIdentityMismatch => 'Identità diversa';

  @override
  String get statusNotPaired => 'Non associato';

  @override
  String get statusConfirmPairing => 'Conferma associazione';

  @override
  String get connectionFailed => 'Connessione non riuscita';

  @override
  String get identityMismatchBanner =>
      'Identità del server modificata — connessione interrotta. Riassocia questo dispositivo per continuare.';

  @override
  String get tabInbox => 'In arrivo';

  @override
  String get tabTickets => 'Ticket';

  @override
  String get tabChat => 'Chat';

  @override
  String get tabPrs => 'PR';

  @override
  String get tabCalendar => 'Calendario';

  @override
  String get tabNews => 'Notizie';

  @override
  String tabWaitingCount(String label, int count) {
    return '$label, $count in attesa';
  }

  @override
  String get updateAvailable => 'È disponibile un nuovo Control Center';

  @override
  String get appearance => 'Aspetto';

  @override
  String get language => 'Lingua';

  @override
  String get device => 'Dispositivo';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get themeLight => 'Chiaro';

  @override
  String get themeDark => 'Scuro';

  @override
  String get languageSystem => 'Sistema';

  @override
  String get disconnectTapAgain =>
      'Tocca di nuovo per disconnettere questo dispositivo da Control Center';

  @override
  String get disconnectDevice => 'Disconnetti questo dispositivo';

  @override
  String get disconnect => 'Disconnetti';

  @override
  String get chooseWorkspace => 'Scegli spazio di lavoro';

  @override
  String get workspaces => 'Spazi di lavoro';

  @override
  String get workspacesLoadFailed => 'Impossibile caricare gli spazi di lavoro';

  @override
  String get noWorkspacesYet => 'Nessuno spazio di lavoro';

  @override
  String selectWorkspace(String name) {
    return 'Seleziona $name';
  }

  @override
  String get inboxLoadFailed => 'Impossibile caricare la posta in arrivo';

  @override
  String get allCaughtUp => 'Sei in pari';

  @override
  String get inboxNoForgeAccount =>
      'Nessun account forge è collegato sul server, quindi le pull request non possono ancora essere attribuite a te.';

  @override
  String get inboxNothingWaiting =>
      'Niente è bloccato e nessuna pull request è in attesa di te.';

  @override
  String get blocked => 'Bloccato';

  @override
  String get sectionNeedsYourReview => 'Da revisionare';

  @override
  String get sectionReturnedToYou => 'Restituiti a te';

  @override
  String get sectionApprovedAndReady => 'Approvati e pronti';

  @override
  String get sectionYourDrafts => 'Le tue bozze';

  @override
  String get sectionWaitingForReviewers => 'In attesa di revisori';

  @override
  String get sectionMergingAndMerged => 'Merge in corso e merge recenti';

  @override
  String get sectionWaitingForAuthor => 'In attesa dell’autore';

  @override
  String waitingAgo(String ago) {
    return 'in attesa da $ago';
  }

  @override
  String get openConversation => 'Apri la conversazione';

  @override
  String get calendarLoadFailed => 'Impossibile caricare il calendario';

  @override
  String get nothingScheduled => 'Niente in programma';

  @override
  String get calendarEmptyDescription =>
      'Qui compaiono gli eventi dei calendari collegati.';

  @override
  String get agenda => 'Agenda';

  @override
  String get syncCalendarsNow => 'Sincronizza i calendari ora';

  @override
  String get event => 'Evento';

  @override
  String get eventNotFound => 'Evento non trovato';

  @override
  String get eventNotFoundDescription =>
      'Potrebbe essere fuori dalla finestra dell’agenda o essere stato rimosso a monte.';

  @override
  String get joinMeeting => 'Partecipa alla riunione';

  @override
  String get join => 'Partecipa';

  @override
  String attendeesCount(int count) {
    return 'Partecipanti ($count)';
  }

  @override
  String get details => 'Dettagli';

  @override
  String get allDay => 'Tutto il giorno';

  @override
  String get happeningNow => 'In corso';

  @override
  String inDuration(String duration) {
    return 'Tra $duration';
  }

  @override
  String eventTimeRange(String start, String end, String duration) {
    return '$start – $end · $duration';
  }

  @override
  String upNextSemantic(String lead, String title) {
    return '$lead: $title';
  }

  @override
  String get attendeeAccepted => 'accettato';

  @override
  String get attendeeDeclined => 'rifiutato';

  @override
  String get attendeeMaybe => 'forse';

  @override
  String get attendeeNoReply => 'nessuna risposta';

  @override
  String get organizer => 'organizzatore';

  @override
  String get calendarNoAccounts =>
      'Nessun calendario è collegato per questo spazio di lavoro. Collegalo dall’app desktop — l’accesso memorizza il token sul server.';

  @override
  String get calendarReauthNeeded =>
      'Un account calendario va ricollegato — quanto vedi sotto potrebbe non essere aggiornato. Ricollegalo dall’app desktop.';

  @override
  String get spacesLoadFailed => 'Impossibile caricare gli spazi';

  @override
  String get noSpaces => 'Nessuno spazio';

  @override
  String get spacesEmptyDescription =>
      'Qui compaiono gli spazi di questo spazio di lavoro.';

  @override
  String get newSpaceFolder => 'Nuova cartella';

  @override
  String get folderName => 'Nome della cartella';

  @override
  String get renameSpaceFolder => 'Rinomina cartella';

  @override
  String get deleteSpaceFolder => 'Elimina cartella';

  @override
  String get moveSpaceToFolder => 'Sposta in una cartella';

  @override
  String get removeSpaceFromFolder => 'Rimuovi dalla cartella';

  @override
  String get spaceFolderActions => 'Azioni della cartella';

  @override
  String get deleteFolderWithSpacesWarning =>
      'Eliminare definitivamente gli spazi rimuove i loro messaggi e le directory di lavoro per tutti. Questa operazione non può essere annullata.';

  @override
  String get deleteSpacesInFolder =>
      'Elimina definitivamente gli spazi in questa cartella';

  @override
  String get deleteFolderAndSpaces => 'Elimina cartella e spazi';

  @override
  String get keepSpacesInFolder =>
      'Altrimenti gli spazi rimarranno fuori dalle cartelle.';

  @override
  String get create => 'Crea';

  @override
  String get otherSpaces => 'Altri spazi';

  @override
  String get folderUpdateFailed => 'Impossibile aggiornare le cartelle';

  @override
  String get thread => 'Thread';

  @override
  String get agentWorking => 'L’agente sta lavorando';

  @override
  String get messagesLoadFailed => 'Impossibile caricare i messaggi';

  @override
  String get noMessagesYet => 'Nessun messaggio ancora';

  @override
  String get noMessagesDescription =>
      'Invia un messaggio per iniziare la conversazione.';

  @override
  String get agentResponding => 'Agente in risposta';

  @override
  String get agentFinished => 'Agente terminato';

  @override
  String attachmentsTooLarge(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$names sono troppo grandi per essere inviati da qui.',
      one: '$names è troppo grande per essere inviato da qui.',
    );
    return '$_temp0';
  }

  @override
  String attachmentsTooLargeRelay(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$names sono troppo grandi per essere inviati tramite relay da qui.',
      one: '$names è troppo grande per essere inviato tramite relay da qui.',
    );
    return '$_temp0';
  }

  @override
  String get attachmentUploadFailed =>
      'Impossibile caricare l’allegato. Riprova.';

  @override
  String attachmentsLeftOut(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count allegati non sono stati caricati e sono stati esclusi.',
      one: '1 allegato non è stato caricato ed è stato escluso.',
    );
    return '$_temp0';
  }

  @override
  String get teammate => 'Collega';

  @override
  String get agent => 'Agente';

  @override
  String get attachFile => 'Allega un file';

  @override
  String get messageHint => 'Messaggio';

  @override
  String removeAttachment(String name) {
    return 'Rimuovi $name';
  }

  @override
  String get articlesLoadFailed => 'Impossibile caricare gli articoli';

  @override
  String get noArticles => 'Nessun articolo';

  @override
  String get articlesEmptyDescription =>
      'I nuovi articoli appaiono qui man mano che i feed si aggiornano.';

  @override
  String get unread => 'Non letti';

  @override
  String get allFeeds => 'Tutti i feed';

  @override
  String get save => 'Salva';

  @override
  String get unsave => 'Rimuovi dai salvati';

  @override
  String get readFullArticle => 'Leggi l\'articolo completo';

  @override
  String get ticketsLoadFailed => 'Impossibile caricare i ticket';

  @override
  String get noTickets => 'Nessun ticket';

  @override
  String get ticketsEmptyDescription =>
      'I ticket di questo workspace appaiono qui.';

  @override
  String get all => 'Tutto';

  @override
  String get ticket => 'Ticket';

  @override
  String get ticketLoadFailed => 'Impossibile caricare il ticket';

  @override
  String assignedTo(String name) {
    return 'Assegnato a $name';
  }

  @override
  String get openInBrowser => 'Apri nel browser';

  @override
  String get status => 'Stato';

  @override
  String get assign => 'Assegna';

  @override
  String get reassign => 'Riassegna';

  @override
  String get noAgents => 'Nessun agente';

  @override
  String get noAgentsDescription => 'Assegna un agente di questo workspace.';

  @override
  String get statusOpen => 'Aperto';

  @override
  String get statusInProgress => 'In corso';

  @override
  String get statusBlocked => 'Bloccato';

  @override
  String get statusInReview => 'In revisione';

  @override
  String get statusDone => 'Completato';

  @override
  String get statusBacklog => 'Backlog';

  @override
  String get lensNeedsMe => 'Da me';

  @override
  String get lensMine => 'Miei';

  @override
  String get prsLoadFailed => 'Impossibile caricare le pull request';

  @override
  String get noOpenPullRequests => 'Nessuna pull request aperta';

  @override
  String get nothingWaitingOnReview => 'Niente in attesa della tua revisione';

  @override
  String get noOwnOpenPullRequests => 'Non hai pull request aperte';

  @override
  String get nothingBlocked => 'Niente di bloccato';

  @override
  String get prsEmptyDescription =>
      'Le pull request dei repository di questo workspace appaiono qui.';

  @override
  String get refreshPullRequests => 'Aggiorna le pull request';

  @override
  String get noForgeConnected =>
      'Nessuna forge è collegata al server, quindi non è possibile recuperare le pull request. Collegalane una dall\'app desktop.';

  @override
  String reposUnreadable(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count repo non sono stati letti.',
      one: '1 repo non è stato letto.',
    );
    return '$_temp0';
  }

  @override
  String reposNotReadable(String names) {
    return 'Non leggibili: $names';
  }

  @override
  String get installationSuspendedTitle => 'Installazione GitHub App sospesa';

  @override
  String installationSuspendedBody(String names) {
    return 'Vengono mostrati gli ultimi dati noti per $names. Riprendi l\'installazione su GitHub oppure collega un token con accesso.';
  }

  @override
  String installationSuspendedNotice(String names) {
    return 'Installazione GitHub App sospesa. Vengono mostrati gli ultimi dati noti per $names. Riprendi l\'installazione su GitHub oppure collega un token con accesso.';
  }

  @override
  String get draft => 'Bozza';

  @override
  String get merged => 'Unita';

  @override
  String get closed => 'Chiuso';

  @override
  String get open => 'Aperta';

  @override
  String get approved => 'Approvato';

  @override
  String get changesRequested => 'Modifiche richieste';

  @override
  String get reviewRequired => 'Revisione richiesta';

  @override
  String get checksPassing => 'Controlli superati';

  @override
  String get checksFailing => 'Controlli falliti';

  @override
  String get checksRunning => 'Controlli in corso';

  @override
  String prSemanticLabel(String title, String status) {
    return '$title, $status';
  }

  @override
  String get pullRequest => 'Pull request';

  @override
  String get prLoadFailed => 'Impossibile caricare questa pull request';

  @override
  String get openOnForge => 'Apri sulla forge';

  @override
  String get requestChangesNeedsComment =>
      'Aggiungi un commento che spieghi cosa va modificato.';

  @override
  String get conversation => 'Conversazione';

  @override
  String get files => 'File';

  @override
  String get checks => 'Controlli';

  @override
  String labelWithCount(String label, int count) {
    return '$label ($count)';
  }

  @override
  String filesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count file',
      one: '1 file',
    );
    return '$_temp0';
  }

  @override
  String commitsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count commit',
      one: '1 commit',
    );
    return '$_temp0';
  }

  @override
  String get conflicts => 'Conflitti';

  @override
  String get reviewers => 'REVISORI';

  @override
  String get noDescriptionNoComments =>
      'Ancora nessuna descrizione né commenti.';

  @override
  String get noChangedFiles => 'Nessun file modificato.';

  @override
  String get noChecksReported =>
      'Nessun controllo segnalato per il commit di testa.';

  @override
  String get reviewCommentHint => 'Lascia un commento di revisione…';

  @override
  String get comment => 'Commento';

  @override
  String get commentPosted => 'Commento pubblicato';

  @override
  String get request => 'Richiedi';

  @override
  String get squashAndMerge => 'Squash and merge';

  @override
  String noActionsAvailable(String status) {
    return '$status — nessuna azione disponibile.';
  }

  @override
  String get reviewApproved => 'approvata';

  @override
  String get reviewRequestedChanges => 'modifiche richieste';

  @override
  String get reviewCommented => 'revisionata';

  @override
  String get reviewPending => 'in sospeso';

  @override
  String get unknownAuthor => 'sconosciuto';

  @override
  String hideDiffFor(String file) {
    return 'Nascondi il diff di $file';
  }

  @override
  String showDiffFor(String file) {
    return 'Mostra il diff di $file';
  }

  @override
  String get checkRunning => 'in esecuzione';

  @override
  String get checkPassed => 'superato';

  @override
  String get checkFailed => 'non superato';

  @override
  String get checkCancelled => 'annullato';

  @override
  String get checkSkipped => 'saltato';

  @override
  String labelWithDuration(String label, String duration) {
    return '$label · $duration';
  }

  @override
  String checkSemanticLabel(String name, String state) {
    return '$name, $state';
  }

  @override
  String get noTextDiff =>
      'Nessun diff testuale per questo file — è binario o troppo grande perché la forge lo restituisca.';

  @override
  String showRemainingLines(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Mostra le $count righe rimanenti',
      one: 'Mostra la riga rimanente',
    );
    return '$_temp0';
  }

  @override
  String unchangedLines(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count righe invariate',
      one: '1 riga invariata',
    );
    return '$_temp0';
  }

  @override
  String get jumpToLatest => 'Vai al più recente';

  @override
  String get streaming => 'In corso';

  @override
  String get working => 'In elaborazione';

  @override
  String get input => 'Input';

  @override
  String get output => 'Output';

  @override
  String get now => 'ora';

  @override
  String agoMinutes(int count) {
    return '${count}m';
  }

  @override
  String agoHours(int count) {
    return '${count}h';
  }

  @override
  String agoDays(int count) {
    return '${count}g';
  }

  @override
  String get today => 'Oggi';

  @override
  String get tomorrow => 'Domani';

  @override
  String get yesterday => 'ieri';

  @override
  String durationMinutes(int count) {
    return '${count}m';
  }

  @override
  String durationHours(int count) {
    return '${count}h';
  }

  @override
  String durationHoursMinutes(int hours, int minutes) {
    return '${hours}h ${minutes}m';
  }

  @override
  String get mobileConversations => 'Conversazioni';

  @override
  String get mobileNewConversation => 'Nuova conversazione';

  @override
  String get mobileConversationName => 'Nome della conversazione';

  @override
  String get mobileRename => 'Rinomina';

  @override
  String get mobileManageSpace => 'Gestisci spazio';

  @override
  String get mobileArchived => 'Archiviato';

  @override
  String get mobileSearchMessages => 'Cerca tutti i messaggi in questo spazio';

  @override
  String get mobileSearch => 'Cerca';

  @override
  String get mobileNoResults => 'Nessun risultato';

  @override
  String get mobileReopen => 'Riapri';

  @override
  String get mobileArchive => 'Archivia';

  @override
  String get mobileProgress => 'Avanzamento e contesto';

  @override
  String get mobileReadFailed =>
      'Impossibile contrassegnare questa conversazione come letta';

  @override
  String get mobileSendFailed =>
      'Messaggio non inviato. La bozza è ancora qui.';

  @override
  String get mobileActionFailed => 'Azione non riuscita';

  @override
  String get mobileRemove => 'Rimuovi';

  @override
  String get mobileLinkedMessage => 'Messaggio collegato';

  @override
  String get mobileOlderMessages => 'Messaggi precedenti';

  @override
  String get mobileMessageActions => 'Azioni del messaggio';

  @override
  String get mobileOpenThread => 'Apri discussione';

  @override
  String get mobileCopyLink => 'Copia link';

  @override
  String get mobileStopRun => 'Interrompi esecuzione';

  @override
  String get mobileStopRunConfirm =>
      'Interrompere questa esecuzione dell\'agente? Il lavoro già completato verrà conservato.';

  @override
  String get mobileControlUnsupported =>
      'Questa esecuzione è terminata o non supporta questo comando.';

  @override
  String get mobilePauseRequested =>
      'Pausa richiesta alla fine del prossimo turno';

  @override
  String get mobileResumed => 'Esecuzione ripresa';

  @override
  String get mobileStopRequested => 'Interruzione richiesta';

  @override
  String get mobileQueuedMessages => 'Messaggi in coda';

  @override
  String get mobilePauseRun => 'Metti in pausa al prossimo turno';

  @override
  String get mobileResumeRun => 'Riprendi';

  @override
  String get mobileEditQueued => 'Modifica il messaggio in coda';

  @override
  String get mobileSteerNow => 'Dai indicazioni ora';

  @override
  String get mobileMoveUp => 'Sposta su';

  @override
  String get mobileMoveDown => 'Sposta giù';

  @override
  String get mobileQueueChanged =>
      'La coda è cambiata o questa esecuzione non accetta indicazioni in tempo reale. Aggiorna e riprova.';

  @override
  String get mobileActivity => 'Attività';

  @override
  String get mobilePermissions => 'Autorizzazioni e audit';

  @override
  String get mobilePlans => 'Piani';

  @override
  String get mobileGoals => 'Obiettivi supervisionati';

  @override
  String get mobileCredentials => 'Connessioni e credenziali';

  @override
  String get mobileWorkspaceUnavailable =>
      'Questo spazio di lavoro non è disponibile o non hai più accesso.';

  @override
  String get mobilePrReviewThreads => 'Discussioni di revisione';

  @override
  String get mobilePrThreadsLoadFailed =>
      'Impossibile caricare le discussioni di revisione';

  @override
  String get mobilePrNoReviewThreads =>
      'Nessuna discussione di revisione nel codice';

  @override
  String get mobilePrCommentPermissionDenied =>
      'Non hai l\'autorizzazione per commentare questo repository.';

  @override
  String get mobilePrPermissionChecking =>
      'Verifica delle autorizzazioni per i commenti…';

  @override
  String get mobilePrPermissionLoadFailed =>
      'Impossibile verificare le autorizzazioni per i commenti. Riprova per commentare.';

  @override
  String mobilePrThreadLine(String side, String line) {
    return '$side, riga $line';
  }

  @override
  String get mobilePrOriginalSide => 'Originale';

  @override
  String get mobilePrUpdatedSide => 'Aggiornato';

  @override
  String get mobilePrThreadResolved => 'Risolto';

  @override
  String get mobilePrReplyHint => 'Scrivi una risposta…';

  @override
  String get mobilePrCommentRequired =>
      'Scrivi un commento prima di pubblicarlo.';

  @override
  String get mobilePrReply => 'Rispondi';

  @override
  String get mobilePrReopenThread => 'Riapri il thread';

  @override
  String get mobilePrResolveThread => 'Risolvi il thread';

  @override
  String get mobilePrResolvePermissionDenied =>
      'Solo l\'autore della pull request o chi ha accesso in scrittura può risolvere questa discussione.';

  @override
  String mobilePrCommentOnLine(String side, String line) {
    return 'Commenta $side, riga $line';
  }

  @override
  String get mobilePrInlineCommentHint => 'Scrivi un commento nel codice…';

  @override
  String get mobilePrPostInlineComment => 'Pubblica commento';

  @override
  String get mobilePrCommentUnavailable =>
      'I commenti nel codice non sono disponibili per questa pull request.';

  @override
  String get mobilePrPatchUnavailable =>
      'Il servizio Git non ha fornito una patch testuale per questo file.';

  @override
  String get mobilePrNoPatchForFile =>
      'La patch per questo file non è disponibile.';

  @override
  String get mobileTicketNew => 'Nuovo ticket';

  @override
  String get mobileTicketCreate => 'Crea ticket';

  @override
  String get mobileTicketEdit => 'Modifica ticket';

  @override
  String get mobileTicketTitle => 'Titolo';

  @override
  String get mobileTicketTitleRequired =>
      'Inserisci un titolo per salvare il ticket.';

  @override
  String get mobileTicketDescription => 'Descrizione';

  @override
  String get mobileTicketMarkdownHint => 'Aggiungi dettagli in Markdown';

  @override
  String get mobileTicketPriority => 'Priorità';

  @override
  String get mobileTicketPriorityNone => 'Nessuna priorità';

  @override
  String get mobileTicketPriorityUrgent => 'Urgente';

  @override
  String get mobileTicketPriorityHigh => 'Alto';

  @override
  String get mobileTicketPriorityMedium => 'Medio';

  @override
  String get mobileTicketPriorityLow => 'Basso';

  @override
  String get mobileTicketLabels => 'Etichette';

  @override
  String get mobileTicketLabelsHint => 'Un\'etichetta per riga';

  @override
  String get mobileTicketLabelsHelp =>
      'Inserisci ogni etichetta su una riga separata.';

  @override
  String mobileTicketWorkspaceProvider(String provider) {
    return 'Registrato in $provider';
  }

  @override
  String get mobileTicketProviderLocal => 'Control Center';

  @override
  String get mobileTicketUnassigned => 'Non assegnato';

  @override
  String get mobileTicketAssignedFilter => 'Assegnati';

  @override
  String get mobileTicketAgentsLoadFailed => 'Impossibile caricare gli agenti';

  @override
  String get mobileTicketSearch => 'Cerca ticket';

  @override
  String get mobileTicketSearchHint =>
      'Titolo, codice, descrizione, etichetta o assegnatario';

  @override
  String get mobileTicketClearSearch => 'Cancella ricerca ticket';

  @override
  String get mobileTicketNoMatches => 'Nessun ticket corrispondente';

  @override
  String get mobileTicketAdjustFilters =>
      'Prova un\'altra ricerca o modifica i filtri.';

  @override
  String get mobileTicketClearFilters => 'Cancella filtri';

  @override
  String get mobileTicketNotFound => 'Ticket non trovato';

  @override
  String get mobileTicketNotFoundDescription =>
      'Il ticket potrebbe essere stato eliminato o spostato fuori da questo spazio di lavoro.';

  @override
  String get mobileTicketWorkspaceChanged =>
      'Lo spazio di lavoro è cambiato. Torna a quello attuale prima di salvare.';

  @override
  String get mobileTicketOpenLinkedSpace => 'Apri spazio collegato';

  @override
  String get mobileTicketReadOnly =>
      'Per modificare i ticket devi essere membro dello spazio di lavoro.';

  @override
  String get permissionTitle => 'Autorizzazioni';

  @override
  String get permissionWorkspaceFailed =>
      'Impossibile caricare lo spazio di lavoro';

  @override
  String get permissionNoWorkspace =>
      'Seleziona uno spazio di lavoro per esaminare le autorizzazioni.';

  @override
  String get permissionLoading => 'Caricamento autorizzazioni…';

  @override
  String get permissionScopeDescription =>
      'Esamina come viene decisa ogni azione a questo livello. Le regole dello spazio di lavoro possono essere ereditate da agenti e spazi.';

  @override
  String get permissionScope => 'Ambito delle regole';

  @override
  String get permissionWorkspaceScope => 'Spazio di lavoro';

  @override
  String get permissionAgentScope => 'Agente';

  @override
  String get permissionSpaceScope => 'Spazio';

  @override
  String get permissionAgentContext => 'Agente attivo in questo spazio';

  @override
  String get permissionNoAgentContext => 'Nessun agente selezionato';

  @override
  String get permissionTargetsFailed =>
      'Impossibile caricare le destinazioni dell\'ambito';

  @override
  String get permissionNoTargets =>
      'Nessuna destinazione disponibile in questo ambito.';

  @override
  String get permissionRoleFailed =>
      'Impossibile verificare il tuo ruolo nello spazio di lavoro';

  @override
  String get permissionMemberRequired =>
      'Per vedere le regole devi essere membro dello spazio di lavoro.';

  @override
  String get permissionRulesFailed => 'Impossibile caricare le regole';

  @override
  String get permissionAuditAdminOnly =>
      'La cronologia delle autorizzazioni è disponibile solo agli amministratori dello spazio di lavoro.';

  @override
  String get permissionAllow => 'Consenti';

  @override
  String get permissionAsk => 'Chiedi prima';

  @override
  String get permissionDeny => 'Nega';

  @override
  String get permissionFileDelete => 'Elimina file';

  @override
  String get permissionFileWriteOutsideWorktree =>
      'Scrivi fuori dalla directory di lavoro Git';

  @override
  String get permissionGitCommit => 'Crea commit';

  @override
  String get permissionGitPush => 'Invia commit';

  @override
  String get permissionPrCreate => 'Crea pull request';

  @override
  String get permissionPrPublish => 'Pubblica pull request';

  @override
  String get permissionVendorSyncWrite =>
      'Scrivi sincronizzazione del provider';

  @override
  String get permissionNetworkEgress => 'Accedi alla rete';

  @override
  String get permissionSecretAccess => 'Accedi ai segreti';

  @override
  String get permissionPackageInstall => 'Installa pacchetti';

  @override
  String get permissionProcessSpawn => 'Avvia processi';

  @override
  String get permissionWorkspaceMutation => 'Modifica spazio di lavoro';

  @override
  String get permissionEnclosureControl => 'Controlla enclosure';

  @override
  String get permissionChangeFailed => 'Impossibile modificare la regola';

  @override
  String get permissionEffectiveDescription =>
      'Valida per questo ambito senza argomenti dell\'azione. Le autorizzazioni condizionali sotto valgono solo per le richieste corrispondenti; la decisione finale spetta al server.';

  @override
  String get permissionSpaceAgentNote =>
      'Nessun agente selezionato. Scegline uno sopra per vedere le regole specifiche dell\'agente.';

  @override
  String get permissionScopedGrants => 'Regole in questo ambito';

  @override
  String get permissionModePreset => 'Preimpostazione della modalità';

  @override
  String get permissionBuiltInDefault => 'Predefinito';

  @override
  String get permissionRemembered => 'Approvazione memorizzata';

  @override
  String get permissionSource => 'Sorgente';

  @override
  String permissionSetAtThisScope(String source) {
    return '$source · impostata qui';
  }

  @override
  String permissionInheritedFrom(String source) {
    return '$source · ereditata';
  }

  @override
  String permissionExpiresAt(String date) {
    return 'Scade il $date';
  }

  @override
  String get permissionSetHere => 'Imposta una regola qui';

  @override
  String get permissionRevokeBeforeEdit =>
      'Revoca la regola specifica o memorizzata prima di impostare una regola generale per questa azione.';

  @override
  String get permissionConfirmRevoke => 'Conferma revoca';

  @override
  String get permissionRevokeRule => 'Revoca regola';

  @override
  String permissionCommandPrefix(String prefix) {
    return 'Prefisso comando: $prefix';
  }

  @override
  String get permissionNoExpiry => 'Senza scadenza';

  @override
  String get permissionExpired => 'Scaduto';

  @override
  String get permissionExplicitRule => 'Regola esplicita';

  @override
  String get permissionEnforcementAdvisory =>
      'Modalità consultiva: le regole «chiedi prima» vengono registrate senza chiedere conferma';

  @override
  String get permissionEnforcementSoft =>
      'Applicazione flessibile: la deroga richiede autorizzazione';

  @override
  String get permissionEnforcementHard =>
      'Applicazione rigorosa: non sono consentite deroghe';

  @override
  String permissionPaths(String paths) {
    return 'Percorsi: $paths';
  }

  @override
  String permissionRefs(String refs) {
    return 'Riferimenti Git: $refs';
  }

  @override
  String permissionHosts(String hosts) {
    return 'Host: $hosts';
  }

  @override
  String permissionCommands(String commands) {
    return 'Comandi: $commands';
  }

  @override
  String permissionMaxCount(String count) {
    return 'Numero massimo: $count';
  }

  @override
  String permissionMaxCents(String cents) {
    return 'Centesimi massimi: $cents';
  }

  @override
  String get permissionAuditHeading => 'Cronologia delle autorizzazioni';

  @override
  String get permissionAuditDescription =>
      'Decisioni recenti registrate dal server. Solo gli amministratori possono consultare il registro o verificarne la catena di hash.';

  @override
  String permissionOnBehalfOf(String user) {
    return 'per conto di $user';
  }

  @override
  String get permissionPrompted => 'Richiesta approvazione umana';

  @override
  String get permissionVerifyChain => 'Verifica catena di audit';

  @override
  String get permissionVerifyFailed =>
      'Impossibile verificare la catena di audit';

  @override
  String permissionChainIntact(String count) {
    return 'Catena integra · $count voci verificate';
  }

  @override
  String permissionChainBroken(String sequence, String reason) {
    return 'Catena interrotta alla voce $sequence: $reason';
  }

  @override
  String get permissionAuditEmpty =>
      'Nessuna decisione di autorizzazione registrata.';

  @override
  String get permissionAuditFailed =>
      'Impossibile caricare la cronologia delle autorizzazioni';

  @override
  String get mobilePlansLoadFailed => 'Impossibile caricare i piani';

  @override
  String get mobilePlansEmpty => 'Ancora nessun piano';

  @override
  String get mobilePlansEmptyDescription =>
      'I piani presentati dagli agenti appariranno qui per la revisione.';

  @override
  String get mobilePlanTitle => 'Piano';

  @override
  String get mobilePlanMissing =>
      'Questo piano non è più disponibile nello spazio di lavoro.';

  @override
  String mobilePlanStepCount(int count) {
    return '$count passaggi';
  }

  @override
  String get mobilePlanDraft => 'Bozza';

  @override
  String get mobilePlanProposed => 'In attesa di revisione';

  @override
  String get mobilePlanApproved => 'Approvato';

  @override
  String get mobilePlanRejected => 'Rifiutato';

  @override
  String get mobilePlanSuperseded => 'Sostituito';

  @override
  String get mobilePlanExecuting => 'In esecuzione';

  @override
  String get mobilePlanSynthesizing => 'Sintesi';

  @override
  String get mobilePlanCompleted => 'Completed';

  @override
  String get mobilePlanFailed => 'Non riuscito';

  @override
  String get mobilePlanCancelled => 'Cancelled';

  @override
  String mobilePlanRevision(String revision) {
    return 'Revisione $revision';
  }

  @override
  String get mobilePlanSteps => 'Passaggi';

  @override
  String get mobilePlanNoSteps =>
      'Non sono stati presentati passaggi per questo piano.';

  @override
  String get mobilePlanAssumptions => 'Chiarimenti';

  @override
  String mobilePlanDependsOn(String keys) {
    return 'Dipende da $keys';
  }

  @override
  String mobilePlanStepCost(String cost) {
    return 'Stima fino a $cost';
  }

  @override
  String get mobilePlanSelect => 'Seleziona';

  @override
  String get mobilePlanSelected => 'Selezionato';

  @override
  String get mobilePlanEstimate => 'Stima costi';

  @override
  String get mobilePlanEstimateRequired =>
      'Stima il piano prima di approvarne l\'esecuzione.';

  @override
  String mobilePlanEstimatedCost(String low, String high) {
    return 'Costo stimato: $low–$high';
  }

  @override
  String get mobilePlanCostUnknown => 'non disponibile';

  @override
  String get mobilePlanNoHardCap => 'nessun limite rigido';

  @override
  String get mobilePlanExceedsBudget =>
      'La stima supera il budget configurato. Verificala prima di approvare.';

  @override
  String get mobilePlanPartialEstimate =>
      'Questa stima riguarda l\'intero piano; i passaggi selezionati potrebbero costare meno.';

  @override
  String get mobilePlanConfirmAll => 'Avviare l\'intero piano?';

  @override
  String get mobilePlanConfirmSelected => 'Avviare i passaggi selezionati?';

  @override
  String mobilePlanExecutionConfirmation(String cost, String cap) {
    return 'L\'approvazione avvia l\'esecuzione e può comportare costi. Costo massimo stimato: $cost. Limite di spesa: $cap.';
  }

  @override
  String get mobilePlanApproveAll => 'Approva tutto e avvia';

  @override
  String get mobilePlanApproveSelected => 'Approva selezione e avvia';

  @override
  String get mobilePlanWiden => 'Approva altri passaggi';

  @override
  String mobilePlanWidenConfirm(String count, String cap) {
    return 'Consentire l\'esecuzione di altri $count passaggi? Possono comportare costi. Limite di spesa attuale: $cap.';
  }

  @override
  String get mobilePlanChanged =>
      'Il piano è cambiato durante la revisione. Riapri l\'ultima revisione e ripeti la stima.';

  @override
  String get mobilePlanReject => 'Rifiuta piano';

  @override
  String get mobilePlanRejectConfirm =>
      'Rifiutare questo piano? Non verrà eseguito.';

  @override
  String get mobilePlanStop => 'Interrompi esecuzione';

  @override
  String get mobilePlanStopConfirm =>
      'Interrompere l\'esecuzione del piano? Il lavoro già completato non verrà annullato.';

  @override
  String mobilePlanRunId(String runId) {
    return 'Esecuzione: $runId';
  }

  @override
  String get mobilePlanExecutionPending =>
      'Approvazione accettata. In attesa del registro di esecuzione…';

  @override
  String mobilePlanProgress(String completed, String total) {
    return '$completed passaggi di $total completati';
  }

  @override
  String get mobilePlanOpenConversation => 'Apri conversazione';

  @override
  String get mobileGoalsTitle => 'Obiettivi supervisionati';

  @override
  String get mobileGoalsLoadFailed =>
      'Impossibile caricare gli obiettivi supervisionati';

  @override
  String get mobileGoalsEmpty => 'Ancora nessun obiettivo supervisionato';

  @override
  String get mobileGoalsEmptyDescription =>
      'Avviane uno in uno spazio oppure invia /goal in una conversazione.';

  @override
  String get mobileGoalMissing =>
      'Questo obiettivo non è più disponibile nello spazio di lavoro.';

  @override
  String get mobileGoalActive => 'Attivo';

  @override
  String get mobileGoalPaused => 'In pausa';

  @override
  String get mobileGoalCompleted => 'Completed';

  @override
  String get mobileGoalFailed => 'Non riuscito';

  @override
  String get mobileGoalCancelled => 'Cancelled';

  @override
  String get mobileGoalBudgetExhausted => 'Budget raggiunto';

  @override
  String get mobileGoalGoal => 'Obiettivo';

  @override
  String get mobileGoalLoop => 'Ciclo';

  @override
  String mobileGoalKind(String kind) {
    return 'Tipo: $kind';
  }

  @override
  String mobileGoalRuns(String count) {
    return '$count esecuzioni';
  }

  @override
  String get mobileGoalNoRunLimit => 'illimitate';

  @override
  String mobileGoalProgress(
    String runs,
    String maxRuns,
    String spent,
    String cap,
  ) {
    return 'Esecuzioni: $runs / $maxRuns · Spesa: $spent / $cap';
  }

  @override
  String mobileGoalDeadline(String date) {
    return 'Scadenza: $date';
  }

  @override
  String mobileGoalFailures(String count) {
    return 'Esecuzioni consecutive non riuscite: $count';
  }

  @override
  String get mobileGoalSummary => 'Riepilogo finale';

  @override
  String get mobileGoalFailedDescription =>
      'Il supervisore si è fermato dopo ripetuti errori di esecuzione. Consulta la conversazione per i dettagli.';

  @override
  String get mobileGoalBudgetWall =>
      'È stata raggiunta la scadenza o il limite di esecuzioni. Aumentare il limite di spesa non permetterà di riprendere questo obiettivo.';

  @override
  String get mobileGoalPause => 'Metti in pausa l\'obiettivo';

  @override
  String get mobileGoalResume => 'Riprendi l\'obiettivo';

  @override
  String get mobileGoalStop => 'Annulla obiettivo';

  @override
  String get mobileGoalStopConfirm =>
      'Annullare definitivamente questo obiettivo supervisionato? Non potrà essere ripreso.';

  @override
  String get mobileGoalRaiseBudget => 'Aumenta budget e riprendi';

  @override
  String mobileGoalRaiseTo(String amount) {
    return 'Aumenta il budget a $amount e riprendi';
  }

  @override
  String mobileGoalRaiseConfirm(String oldCap, String newCap) {
    return 'Aumentare il limite di spesa dell\'obiettivo da $oldCap a $newCap e riprendere le spese?';
  }

  @override
  String get mobileGoalOpenConversation =>
      'Apri la conversazione dell\'obiettivo';

  @override
  String get mobileGoalCreate => 'Avvia obiettivo supervisionato';

  @override
  String get mobileGoalChooseSpace => 'Esegui nello spazio';

  @override
  String get mobileGoalNoSpaces =>
      'Crea uno spazio prima di avviare un obiettivo.';

  @override
  String get mobileGoalChooseAgent => 'Esegui con l\'agente';

  @override
  String get mobileGoalNoAgents =>
      'Aggiungi un agente attivo prima di avviare un obiettivo.';

  @override
  String mobileGoalSelectedAgent(String name) {
    return '$name selezionato';
  }

  @override
  String get mobileGoalObjectiveHint =>
      'Quale risultato deve perseguire l\'agente?';

  @override
  String get mobileGoalBudgetUsd => 'Limite di spesa (USD)';

  @override
  String get mobileGoalCreateInvalid =>
      'Scegli uno spazio e un agente, inserisci un obiettivo e imposta un limite di spesa positivo in USD.';

  @override
  String mobileGoalCreateConfirm(String cap) {
    return 'Avviare un obiettivo supervisionato con un costo massimo di $cap? L\'agente potrebbe iniziare subito.';
  }

  @override
  String get mobileGoalUnavailable =>
      'La connessione al server non è pronta. Riprova dopo esserti riconnesso.';

  @override
  String get mobileGoalConversationMissing =>
      'La conversazione selezionata non è più disponibile nello spazio di lavoro.';

  @override
  String get mobileGoalCreateSent =>
      'Obiettivo avviato. Lo stato del supervisore apparirà in questo elenco.';

  @override
  String get mobileGoalStartRefused =>
      'Nessuna esecuzione dell\'obiettivo avviata. Consulta la conversazione per conoscere il motivo indicato dal supervisore.';

  @override
  String mobileGoalSelectedSpace(String name) {
    return '$name selezionato';
  }

  @override
  String get requestUnavailable =>
      'Questa richiesta non è più disponibile nello spazio di lavoro attivo.';

  @override
  String get requestAlreadyResolved => 'Questa richiesta è già stata risolta.';

  @override
  String get inboxCredentialsBlocked =>
      'Credenziali che bloccano le esecuzioni';

  @override
  String get inboxSyncFailures =>
      'Sincronizzazioni con i provider non riuscite';

  @override
  String get inboxConfigureCredentials => 'Configura credenziali';

  @override
  String get openTicket => 'Apri ticket';

  @override
  String get activityTitle => 'Attività';

  @override
  String get activityClearAll => 'Cancella attività';

  @override
  String get activityClearConfirm =>
      'Questa azione nasconde su tutti i tuoi dispositivi le attività registrate finora. Le nuove attività continueranno a comparire.';

  @override
  String get activityMarkAllRead => 'Segna tutto come letto';

  @override
  String get activityMarkAllConfirm =>
      'Segnare come lette tutte le attività di questo spazio di lavoro su tutti i tuoi dispositivi?';

  @override
  String get activityMarkRead => 'Segna come letto';

  @override
  String get activityMarkUnread => 'Segna come da leggere';

  @override
  String get activityDismiss => 'Ignora';

  @override
  String get activityResolved => 'Risolto';

  @override
  String get activityOpen => 'Aperta';

  @override
  String get activityEmpty => 'Ancora nessuna attività';

  @override
  String get activityLoadFailed => 'Impossibile caricare le attività';

  @override
  String get activityAgentWaiting => 'L\'agente attende istruzioni';

  @override
  String get activityAgentBlocked => 'Azione dell\'agente bloccata';

  @override
  String get activityMessage => 'Nuovo messaggio';

  @override
  String get activityPullRequest => 'Aggiornamento pull request';

  @override
  String get activityTicket => 'Aggiornamento ticket';

  @override
  String get activityMeeting => 'Aggiornamento riunione';

  @override
  String get activityCalendar => 'Connessione calendario';

  @override
  String get activityRig => 'Aggiornamento enclosure';

  @override
  String get activityEvent => 'Aggiorna';

  @override
  String get activityPrReady => 'Pull request pronta per il merge';

  @override
  String get activityPrBlocked => 'Merge della pull request bloccato';

  @override
  String get activityPrApproved => 'Pull request approvata';

  @override
  String get activityPrChanges => 'Modifiche richieste';

  @override
  String get activityPrChecksFailed =>
      'Controlli della pull request non riusciti';

  @override
  String get activityPrChecksRecovered =>
      'Controlli della pull request ripristinati';

  @override
  String get activityPrComment => 'Commento alla pull request';

  @override
  String get activityPrPublished => 'Pull request pubblicata';

  @override
  String get activityPrMerged => 'Pull request merged';

  @override
  String get activityPrMentioned => 'Menzione in una pull request';

  @override
  String get activityPrReviewRequested => 'Revisione richiesta';

  @override
  String get activityPrReviewStale => 'La revisione va aggiornata';

  @override
  String get activityTicketAssigned => 'Ticket assegnato';

  @override
  String get activityTicketChanged => 'Stato del ticket modificato';

  @override
  String get activityMeetingSoon => 'Riunione in arrivo';

  @override
  String get activityCalendarExpired => 'Connessione al calendario scaduta';

  @override
  String get activityRigControl => 'Controllo dell\'enclosure modificato';

  @override
  String get activityRigClosed => 'Enclosure arrestata';

  @override
  String get mobileSpacesSearch => 'Cerca spazi';

  @override
  String get mobileSpacesArchived => 'Archiviato';

  @override
  String get mobileSpacesActive => 'Attivo';

  @override
  String get mobileSpacesNew => 'Nuovo spazio';

  @override
  String get mobileSpacesManage => 'Gestisci spazio';

  @override
  String get mobileSpacesName => 'Nome dello spazio';

  @override
  String get mobileSpacesAgents => 'Agenti';

  @override
  String get mobileSpacesMembers => 'Persone';

  @override
  String get mobileSpacesRepos => 'Repository';

  @override
  String get mobileSpacesAllRepos => 'Tutti i repository collegati';

  @override
  String get mobileSpacesNoRepos => 'Nessun repository';

  @override
  String get mobileSpacesBaseBranch => 'Branch di base (facoltativo)';

  @override
  String get mobileSpacesDefaultBranch => 'Branch predefinito';

  @override
  String get mobileSpacesMode => 'Modalità';

  @override
  String get mobileSpacesModeChat => 'Chat';

  @override
  String get mobileSpacesModeReview => 'Revisione (sola lettura)';

  @override
  String get mobileSpacesModePlan => 'Pianificazione (sola lettura)';

  @override
  String get mobileSpacesModeOrchestrate => 'Orchestra';

  @override
  String get mobileSpacesAutonomy => 'Personalizzazione dell\'autonomia';

  @override
  String get mobileSpacesAutonomyInherited => 'Ereditato';

  @override
  String get mobileSpacesAutonomyPropose => 'Solo proposta';

  @override
  String get mobileSpacesAutonomyApproval => 'Agisci con approvazione';

  @override
  String get mobileSpacesAutonomyFreely => 'Agisci liberamente';

  @override
  String get mobileSpacesAutonomyNotice =>
      'La personalizzazione non può ignorare le richieste di conferma o i divieti delle regole sulle azioni. Solo gli amministratori dello spazio di lavoro possono modificarla.';

  @override
  String get mobileSpacesArchive => 'Archivia spazio';

  @override
  String get mobileSpacesReopen => 'Riapri spazio';

  @override
  String get mobileSpacesSave => 'Salva modifiche';

  @override
  String get mobileSpacesCreate => 'Crea spazio';

  @override
  String get mobileSpacesOperationFailed => 'Impossibile aggiornare lo spazio';

  @override
  String get mobileSpacesMissing =>
      'Spazio non trovato in questo spazio di lavoro';

  @override
  String get mobileSpacesEmptyName => 'Inserisci un nome per lo spazio';

  @override
  String get mobileSpacesNoMatches => 'Nessuno spazio corrispondente';

  @override
  String get mobileSpacesUnread => 'Risposta dell\'agente non letta';

  @override
  String get mobileSpacesNeedsInput => 'Richiede il tuo intervento';

  @override
  String get mobileSpacesRunning => 'Agente in esecuzione';

  @override
  String get mobileSpacesNoAgents => 'Nessun agente in questo spazio di lavoro';

  @override
  String get mobileSpacesNoMembers =>
      'Nessun altro membro dello spazio di lavoro';

  @override
  String get mobileSpacesRepoError => 'Impossibile caricare i repository';

  @override
  String get mobileSpacesRetry => 'Riprova';

  @override
  String get mobileSpacesBranchUnavailable =>
      'Scegli o digita un branch di base quando crei uno spazio; il branch di base di uno spazio esistente non può essere modificato.';

  @override
  String get mobileSpacesArchivedEmpty => 'Nessuno spazio archiviato';

  @override
  String get mobileSpacesAllRepoWarning =>
      'In questo spazio saranno inclusi anche i repository collegati in futuro allo spazio di lavoro.';

  @override
  String get mobileSpacesCreatedRetry =>
      'Spazio creato. Riprova ad aggiungere persone oppure apri la pagina di gestione.';

  @override
  String get progressTitle => 'Avanzamento';

  @override
  String get progressConversation => 'Conversazione';

  @override
  String get progressLoadFailed => 'Impossibile caricare l\'avanzamento';

  @override
  String get progressUnavailable => 'Conversazione non disponibile';

  @override
  String get progressUnavailableDescription =>
      'Questa conversazione non si trova nello spazio di lavoro e nello spazio attivi. Torna al suo spazio per continuare.';

  @override
  String get progressSaveFailed => 'Impossibile aggiornare l\'avanzamento';

  @override
  String get progressGoal => 'Obiettivo';

  @override
  String get progressNoGoal => 'Nessun obiettivo di lavoro impostato';

  @override
  String get progressSetGoal => 'Imposta obiettivo';

  @override
  String get progressEditGoal => 'Modifica obiettivo';

  @override
  String get progressClearGoal => 'Cancella obiettivo';

  @override
  String get progressGoalRequired => 'Inserisci un obiettivo prima di salvare.';

  @override
  String get progressTodos => 'Attività da svolgere';

  @override
  String get progressNoTodos => 'Ancora nessuna attività da svolgere';

  @override
  String get progressNewTodo => 'Nuova attività';

  @override
  String get progressAddTodo => 'Aggiungi attività';

  @override
  String get progressEditTodo => 'Modifica attività';

  @override
  String get progressTodoRequired => 'Inserisci un\'attività prima di salvare.';

  @override
  String get progressTodoNoLongerExists =>
      'Questa attività è stata rimossa. Ricarica l\'elenco e riprova.';

  @override
  String get progressWorkspaceChanged =>
      'Lo spazio di lavoro attivo è cambiato. Torna a questa conversazione e riprova.';

  @override
  String progressRemoveTodo(String name) {
    return 'Rimuovi attività $name';
  }

  @override
  String get progressPending => 'Pending';

  @override
  String get progressInProgress => 'In corso';

  @override
  String get progressCompleted => 'Completed';

  @override
  String get progressMoveUp => 'Sposta attività su';

  @override
  String get progressMoveDown => 'Sposta attività giù';

  @override
  String get progressRunTree => 'Esecuzioni degli agenti';

  @override
  String get progressNoRuns =>
      'Ancora nessuna esecuzione in questa conversazione';

  @override
  String get progressRunning => 'In esecuzione';

  @override
  String get progressFailed => 'Non riuscito';

  @override
  String get progressUnknown => 'Sconosciuto';

  @override
  String get progressHealthy => 'Attivo';

  @override
  String get progressBlocked => 'Bloccato';

  @override
  String get progressLooping => 'In ciclo';

  @override
  String get progressStalled => 'Bloccato';

  @override
  String get progressDead => 'Interrotto in modo imprevisto';

  @override
  String get progressQuiet => 'Ancora nessun output';

  @override
  String get progressCostReported => 'Addebito dichiarato dal provider';

  @override
  String get progressCostNotional =>
      'Prezzo di listino teorico dell\'abbonamento; non è una fattura';

  @override
  String get progressCostMixed => 'Fonti di costo diverse';

  @override
  String get progressCostEstimated => 'Costo stimato';

  @override
  String progressDurationSeconds(String seconds) {
    return '${seconds}s';
  }

  @override
  String progressRunDetails(String model, String duration, String cost) {
    return 'Modello: $model · Durata: $duration · Costo: $cost';
  }

  @override
  String progressStartedAt(String time) {
    return 'Avviato $time';
  }

  @override
  String progressLiveness(String state) {
    return 'Stato: $state';
  }

  @override
  String progressRunTokens(String input, String output) {
    return 'Input: $input · Output: $output token';
  }

  @override
  String get progressOutputPreviewLimited =>
      'Sono mostrati solo i primi 6.000 caratteri dell\'output strutturato.';

  @override
  String progressRetryOf(String runId) {
    return 'Nuovo tentativo dell\'esecuzione $runId';
  }

  @override
  String get progressContext => 'Contesto e limiti';

  @override
  String get progressNoAgent => 'Nessun agente da esaminare';

  @override
  String progressContextReading(String used, String window) {
    return '$used / $window token';
  }

  @override
  String get progressMeasured =>
      'Contesto dichiarato dal provider nell\'ultima chiamata';

  @override
  String get progressEstimated =>
      'Stima basata sulla conversazione salvata e sul contesto persistente';

  @override
  String get progressContextUnknown =>
      'Utilizzo del contesto non ancora disponibile';

  @override
  String progressContextPercent(String percent) {
    return '$percent% della finestra di contesto';
  }

  @override
  String progressMonthlyBudget(String amount) {
    return 'Limite mensile configurato per l\'agente: $amount';
  }

  @override
  String progressConversationTokens(String tokens) {
    return 'Conversazione attiva salvata: circa $tokens token';
  }

  @override
  String progressInspectionFor(String agent, String model) {
    return 'Contesto persistente di $agent · $model';
  }

  @override
  String get progressContextSystem => 'Prompt di sistema';

  @override
  String get progressContextRules => 'Regole';

  @override
  String get progressContextSkills => 'Competenze';

  @override
  String get progressContextTools => 'Definizioni degli strumenti';

  @override
  String get progressContextMcp => 'Strumenti MCP';

  @override
  String get progressContextDeferred => 'Strumenti differiti';

  @override
  String get progressContextSubagents => 'Subagenti';

  @override
  String get progressContextRunner => 'Esecutore esterno';

  @override
  String get progressContextMemory => 'MEMORIA';

  @override
  String get progressContextHistory => 'Cronologia conversazione';

  @override
  String progressContextSegment(String label, String tokens) {
    return '$label · $tokens token';
  }

  @override
  String progressContextPart(String title, String tokens) {
    return '$title · $tokens token';
  }

  @override
  String get progressOutputs => 'Output recenti';

  @override
  String get progressNoOutputs => 'Nessun output recente degli agenti';

  @override
  String get progressStructuredOutputsAbove =>
      'Gli output strutturati delle esecuzioni sono mostrati sopra, nella sezione dedicata.';

  @override
  String get progressRecentOutputsOnly =>
      'Sono mostrati solo i messaggi recenti. Apri la conversazione per vedere quelli precedenti.';

  @override
  String get progressPlan => 'Piano';

  @override
  String get progressArtifact => 'Artefatto';

  @override
  String get progressResult => 'Risultato';

  @override
  String get progressHideArtifact => 'Nascondi artefatto';

  @override
  String get progressReadArtifact => 'Leggi artefatto';

  @override
  String get progressArtifactUnavailable => 'Artefatto non più disponibile';

  @override
  String get progressArtifactPreviewLimited =>
      'Anteprima limitata di questo artefatto.';

  @override
  String get progressDiagramSource => 'Codice sorgente del diagramma';

  @override
  String progressOpenAttachment(String name) {
    return 'Apri $name';
  }

  @override
  String get progressOpenPlan => 'Apri piano';

  @override
  String progressOpenDiff(String label) {
    return 'Esamina i file modificati: $label';
  }

  @override
  String get progressViewMessage => 'Visualizza messaggio';

  @override
  String get pushTitle => 'Notifiche in background';

  @override
  String get pushIntro =>
      'Ricevi un avviso privato quando qualcosa richiede la tua attenzione, anche ad app chiusa. I dettagli restano nella connessione crittografata.';

  @override
  String get pushLoading => 'Verifica delle impostazioni delle notifiche…';

  @override
  String get pushError =>
      'Impossibile aggiornare le notifiche. Controlla la connessione e riprova.';

  @override
  String get pushEnable => 'Abilita notifiche';

  @override
  String get pushDisable => 'Disattiva notifiche';

  @override
  String get pushQuiet => 'Sospendi gli avvisi su questo dispositivo';

  @override
  String get pushCategories => 'Ricevi notifiche su';

  @override
  String get pushCategoryAgents => 'Agenti';

  @override
  String get pushCategoryMessages => 'Messaggi';

  @override
  String get pushCategoryPullRequests => 'Pull request';

  @override
  String get pushCategoryTickets => 'Ticket';

  @override
  String get pushCategoryCalendar => 'Calendario';

  @override
  String get pushCategoryMachines => 'Macchine';

  @override
  String get pushSecureOrigin => 'Le notifiche richiedono HTTPS.';

  @override
  String get pushInstallIos =>
      'Su iPhone o iPad, aggiungi l\'app alla schermata Home e aprila da lì per attivare le notifiche.';

  @override
  String get pushUnsupported =>
      'Questo browser non supporta le notifiche in background.';

  @override
  String get pushDenied =>
      'Le notifiche sono bloccate nelle impostazioni del browser. Abilitale lì per continuare.';

  @override
  String get pushResubscribe => 'Riconnetti notifiche';

  @override
  String get pushStatusEnabled =>
      'Le notifiche sono attive su questo dispositivo.';

  @override
  String get pushStatusDisabled =>
      'Le notifiche sono disattivate su questo dispositivo.';

  @override
  String get credentialsTitle => 'Connessioni e credenziali';

  @override
  String get credentialsIntro =>
      'Collega gli account usati dalle esecuzioni e dalle integrazioni. I segreti sono conservati sul server, non su questo telefono.';

  @override
  String get credentialsModelProviders => 'Fornitori di modelli';

  @override
  String get credentialsOwnerOnly =>
      'Solo il proprietario del server può aggiungere, collegare o rimuovere le credenziali dei fornitori di modelli. Queste chiavi sono condivise tra gli spazi di lavoro.';

  @override
  String get credentialsContactOwner =>
      'Chiedi al proprietario del server di collegare il fornitore necessario per l\'esecuzione bloccata.';

  @override
  String get credentialsClaudeCode => 'Claude Code';

  @override
  String get credentialsClaudeHostOnly =>
      'Claude Code accede tramite la CLI sul computer host. Chiedi al proprietario del server di completare o rinnovare l\'accesso all\'account nel terminale dell\'host: non è possibile farlo da questo telefono.';

  @override
  String get credentialsYourForgeAccounts => 'I tuoi account dei servizi Git';

  @override
  String get credentialsYourTicketingAccount => 'Il tuo account per i ticket';

  @override
  String get credentialsLocalTicketsNoLogin =>
      'I ticket locali non richiedono l\'accesso. Collega Linear qui se lo usa il tuo spazio di lavoro.';

  @override
  String get credentialsMembershipRequired =>
      'Per gestire le credenziali dei servizi Git o dei ticket devi far parte di uno spazio di lavoro. Chiedi l\'accesso a un amministratore.';

  @override
  String get credentialsSwitchWorkspace =>
      'Questo link rimanda a un altro spazio di lavoro. Passa a quello spazio prima di modificare le credenziali.';

  @override
  String get credentialsReturnToInbox =>
      'Quando la credenziale è collegata, torna alla Posta in arrivo per riprovare l\'esecuzione bloccata. L\'host controlla automaticamente anche le esecuzioni in attesa.';

  @override
  String get credentialsLoadFailed =>
      'Impossibile caricare le connessioni. Verifica il collegamento al server e riprova.';

  @override
  String get credentialsOperationFailed =>
      'Impossibile modificare questa connessione. Verifica il collegamento al server, i tuoi permessi e la credenziale, poi riprova.';

  @override
  String get credentialsConnected => 'Connesso';

  @override
  String get credentialsNotConnected => 'Non connesso';

  @override
  String credentialsSignedInAs(String username) {
    return 'Accesso effettuato come $username';
  }

  @override
  String get credentialsAccount => 'Account collegato';

  @override
  String get credentialsStoredKey => 'Chiave salvata';

  @override
  String get credentialsActive => 'Attivo';

  @override
  String get credentialsRemove => 'Rimuovi';

  @override
  String get credentialsRemoveConfirm =>
      'Rimuovere la credenziale salvata? Potrebbe essere necessario accedere di nuovo.';

  @override
  String get credentialsApiKey => 'Chiave API';

  @override
  String get credentialsApiKeyHint => 'Incolla una chiave API del fornitore';

  @override
  String get credentialsBrowserLogin => 'Accedi dal browser';

  @override
  String get credentialsSignInAgain => 'Accedi di nuovo';

  @override
  String get credentialsWaitingForLogin =>
      'In attesa dell\'autorizzazione nel browser…';

  @override
  String get credentialsLoginTimedOut =>
      'L\'accesso è scaduto. Avvia un nuovo tentativo.';

  @override
  String get credentialsCopyCode => 'Copia codice';

  @override
  String get credentialsDeviceCodeHint =>
      'Conferma questo codice nella pagina del fornitore. Tieni aperta questa schermata mentre il server completa l\'accesso.';

  @override
  String get credentialsPasteRedirect =>
      'Codice di autorizzazione o URL di reindirizzamento';

  @override
  String get credentialsPasteRedirectHint =>
      'Incolla il codice o l\'URL completo di reindirizzamento del fornitore';

  @override
  String get credentialsCompleteLogin => 'Completa l\'accesso';

  @override
  String get credentialsRedirectUnavailable =>
      'Il callback del browser di questo server non è raggiungibile in modo sicuro da un telefono. Chiedi al proprietario del server di configurare un callback HTTPS pubblico oppure aggiungi un token.';

  @override
  String get credentialsUpdateToken => 'Aggiorna token';

  @override
  String get credentialsAddToken => 'Aggiungi token';

  @override
  String get credentialsPersonalToken => 'Token di accesso personale';

  @override
  String get credentialsPersonalTokenHint =>
      'Incolla un token di accesso personale';

  @override
  String get credentialsHostManaged =>
      'Questa connessione proviene dall\'applicazione server o dall\'ambiente. Solo il proprietario del server può modificarla lì; puoi comunque aggiungere un tuo token.';

  @override
  String get credentialsStopWatching => 'Interrompi l\'attesa';
}
