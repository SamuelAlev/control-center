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
  String get cancel => 'Annulla';

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
  String get teammate => 'Collega';

  @override
  String get systemSender => 'Sistema';

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
  String get sentAttachmentUnavailable => 'Allegato non disponibile';

  @override
  String get sentAttachmentLoadFailed => 'Impossibile caricare l\'allegato';

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
  String get mobilePrSelectCommentLine => 'Scegli una riga da commentare';

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
  String get permissionPrPublish => 'Aggiornare o unire pull request';

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
  String get permissionRemembered => 'Approvazione temporanea';

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
  String permissionTools(String tools) {
    return 'Strumenti: $tools';
  }

  @override
  String get permissionNotInEffect =>
      'Senza effetto mentre questa azione è su Nega';

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
  String mobileGoalFailures(String count) {
    return 'Esecuzioni consecutive non riuscite: $count';
  }

  @override
  String get mobileGoalFailedDescription =>
      'Il supervisore si è fermato dopo ripetuti errori di esecuzione. Consulta la conversazione per i dettagli.';

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
  String get transcriptToolTodos => 'Attività da svolgere';

  @override
  String get transcriptToolSearchMemory => 'Cerca nella memoria';

  @override
  String get transcriptToolRenderMedia => 'Mostra contenuti multimediali';

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
      'Il browser segnala che le notifiche sono bloccate. Controlla le autorizzazioni di questo sito e le impostazioni delle notifiche del browser o del dispositivo, poi aggiorna.';

  @override
  String get pushOsHint =>
      'Il browser deve anche avere il permesso di mostrare notifiche nelle impostazioni di sistema del dispositivo.';

  @override
  String get pushServiceUnavailable =>
      'Il servizio push del browser ha rifiutato l’iscrizione. Alcuni browser, come Brave, lo disattivano per impostazione predefinita: cerca un’opzione per i messaggi push nelle impostazioni sulla privacy del browser, poi riprova.';

  @override
  String get pushWorkerUnavailable =>
      'Impossibile avviare il servizio di notifiche in questo browser. Ricarica la pagina e riprova.';

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
  String get credentialsConnectCodePrompt => 'Codice di conferma';

  @override
  String get credentialsConnectCodeMalformed =>
      'Non sembra un codice di accesso. I codici hanno 8 lettere e cifre.';

  @override
  String get credentialsSignInInvalidCode =>
      'Questo codice non corrisponde a questo accesso. Controllalo e riprova.';

  @override
  String get credentialsSignInTooManyCodes =>
      'Troppi codici errati. Avvia di nuovo l\'accesso.';

  @override
  String get credentialsSignInRetryLater =>
      'Il servizio di accesso non risponde in questo momento. Attendi un minuto, poi riprova.';

  @override
  String get credentialsSignInRefused =>
      'L\'accesso è stato rifiutato. Avvialo di nuovo e approva tutte le autorizzazioni richieste.';

  @override
  String get credentialsSignInNotSaved =>
      'L\'accesso è riuscito, ma il server non è riuscito a salvarlo. Riprova.';

  @override
  String credentialsSignInUnavailable(String provider) {
    return 'L\'accesso a $provider non è ancora configurato su questo server.';
  }

  @override
  String get credentialsSignInPhoneUnreachable =>
      'L\'indirizzo di ritorno dell\'accesso di questo server non è raggiungibile in modo sicuro da un telefono. Accedi dall\'app desktop oppure chiedi al proprietario del server di configurare un indirizzo HTTPS pubblico.';

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
  String get credentialsUpdateToken => 'Aggiorna token';

  @override
  String get credentialsAddToken => 'Aggiungi token';

  @override
  String get credentialsPersonalToken => 'Token di accesso personale';

  @override
  String get credentialsPersonalTokenHint =>
      'Incolla un token di accesso personale';

  @override
  String get credentialsStopWatching => 'Interrompi l\'attesa';

  @override
  String get transcriptClaudeSignInExpiredTitle =>
      'Accesso a Claude Code scaduto';

  @override
  String get transcriptClaudeSignInExpiredBody =>
      'L\'esecuzione si è interrotta perché il suo account non si autentica più. Accedi di nuovo, poi riprova il turno.';

  @override
  String get transcriptSignInExpiredTitle => 'Accesso al provider scaduto';

  @override
  String get transcriptSignInExpiredBody =>
      'L\'esecuzione si è interrotta perché la credenziale del provider non funziona più. Ricollegalo in Impostazioni → Provider, poi riprova il turno.';

  @override
  String get permissionHostExecution => 'Eseguire comandi sull\'host';

  @override
  String credentialsSignInLapsed(String provider) {
    return 'Il tuo accesso a $provider è scaduto. Accedi di nuovo.';
  }

  @override
  String get credentialsSignInPaused =>
      'In pausa: il servizio di accesso di questo spazio di lavoro è cambiato. Tornerà a funzionare quando il servizio sarà di nuovo disponibile.';

  @override
  String credentialsProviderUnreachable(String provider) {
    return 'Impossibile raggiungere $provider al momento. Nuovo tentativo in corso.';
  }

  @override
  String get credentialsScopeWorkspace => 'Solo questo spazio di lavoro';

  @override
  String get credentialsScopeAllWorkspaces => 'Tutti gli spazi di lavoro';

  @override
  String get credentialsRemoveConfirmWorkspace =>
      'Rimuovere la credenziale salvata da questo spazio di lavoro? Gli altri mantengono la propria.';

  @override
  String get credentialsRemoveConfirmAllWorkspaces =>
      'Rimuovere la credenziale salvata da ogni spazio di lavoro che la condivide?';

  @override
  String get credentialsSignInServerRestarted =>
      'Il server è stato riavviato. Ricomincia l\'accesso.';

  @override
  String repoAccessInstallApp(String owner, String names) {
    return 'Installa la GitHub App su $owner perché l\'automazione raggiunga $names. Tocca per aprire GitHub.';
  }

  @override
  String repoAccessAskAdminInstall(String owner, String names) {
    return 'La GitHub App non è installata su $owner, quindi l\'automazione non raggiunge $names. Chiedi a un admin dello spazio di lavoro di installarla.';
  }

  @override
  String repoAccessAddToApp(String names) {
    return 'Aggiungi $names ai repository della GitHub App. Tocca per aprire GitHub.';
  }

  @override
  String repoAccessAskAdminAdd(String names) {
    return 'La GitHub App non vede ancora $names. Chiedi a un admin dello spazio di lavoro di aggiungerli ai suoi repository.';
  }

  @override
  String repoAccessSuspended(String names) {
    return 'Installazione della GitHub App sospesa. L\'automazione per $names è in pausa finché un proprietario dell\'account non riprende l\'installazione su GitHub.';
  }

  @override
  String repoAccessOwnerCannotSee(String names) {
    return 'La persona responsabile dell\'automazione di questo spazio di lavoro non vede più $names, quindi lì non viene eseguito nulla a suo nome.';
  }

  @override
  String repoAccessOwnerNotSignedIn(String names) {
    return 'La persona responsabile dell\'automazione di questo spazio di lavoro non ha effettuato l\'accesso alla forge, quindi l\'automazione per $names attende finché non accede.';
  }

  @override
  String repoAccessRetrying(String names) {
    return 'Impossibile verificare l\'accesso a $names. Nuovo tentativo in corso.';
  }

  @override
  String hiddenReposSignIn(int count, String forge) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Accedi a $forge per vedere le pull request di altri $count repository',
      one: 'Accedi a $forge per vedere le pull request di un altro repository',
    );
    return '$_temp0';
  }

  @override
  String hiddenReposNoForgeAccess(int count, String forge) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count repository sono nascosti perché il tuo account $forge non può vederli',
      one:
          '1 repository è nascosto perché il tuo account $forge non può vederlo',
    );
    return '$_temp0';
  }

  @override
  String hiddenReposNoGrant(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count repository sono nascosti perché non hai accesso in questo spazio di lavoro',
      one:
          '1 repository è nascosto perché non hai accesso in questo spazio di lavoro',
    );
    return '$_temp0';
  }

  @override
  String hiddenReposChecking(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Verifica del tuo accesso ad altri $count repository…',
      one: 'Verifica del tuo accesso a un altro repository…',
    );
    return '$_temp0';
  }

  @override
  String get credentialsAtlassianEmail => 'Email dell\'account Atlassian';

  @override
  String get credentialsAtlassianEmailInvalid =>
      'Inserisci l\'indirizzo email del tuo account Atlassian.';

  @override
  String get credentialsBitbucketApiToken => 'Token API';

  @override
  String repoAccessAutomationTokenMissing(String names) {
    return 'Nessun token di automazione può leggere $names, quindi il lavoro in background lì è in pausa. Un admin può aggiungerne uno in Impostazioni → Repository.';
  }

  @override
  String get credentialsSignInConfirmInBrowser =>
      'Conferma nel browser, poi inserisci il codice che mostra.';

  @override
  String get credentialsSignInAccountAlreadyBound =>
      'Questo account è già collegato a un’altra persona su questo server. Accedi con un account diverso.';

  @override
  String credentialsTokenUnreachable(String provider) {
    return 'Impossibile raggiungere $provider per verificare questo token. Riprova tra poco.';
  }

  @override
  String credentialsTokenRejected(String provider) {
    return '$provider non accetta questo token. Controlla di averlo copiato per intero e che non sia stato revocato.';
  }

  @override
  String credentialsTokenWrongKind(String provider) {
    return 'Non è un token personale. Incolla un token di accesso personale del tuo account $provider, non un token di progetto, gruppo, spazio di lavoro o bot.';
  }

  @override
  String credentialsTokenNarrowScope(String scope) {
    return 'A questo token manca l’ambito $scope, necessario per revisionare e commentare. Creane uno che lo abbia.';
  }

  @override
  String get credentialsTokenExpired =>
      'Questo token è scaduto. Creane uno nuovo e incollalo qui.';

  @override
  String get credentialsSignInRateLimited =>
      'Troppe richieste in questo momento. Attendi un po’, poi riprova.';

  @override
  String get credentialsSignInCancelled =>
      'L’accesso è stato annullato o rifiutato. Riavvialo quando sei pronto.';

  @override
  String get credentialsSignInNoLongerOpen =>
      'Questo accesso non è più aperto: è stato annullato, usato o sostituito. Avvialo di nuovo.';

  @override
  String get noWorkspacesYetHint =>
      'Un amministratore dello spazio di lavoro deve invitarti, oppure il proprietario del server può crearne uno per te.';

  @override
  String repoAccessReplaced(String repos, String forge) {
    return '$repos ora punta a un altro repository su $forge. Ricollegalo dall’app desktop o web per continuare a usarlo.';
  }

  @override
  String repoAccessAskAdminRelink(String repos, String forge) {
    return '$repos ora punta a un altro repository su $forge. Un amministratore dello spazio di lavoro deve ricollegarlo prima che possa essere di nuovo usato.';
  }

  @override
  String get runSandboxUnavailableTitle =>
      'Gli agenti hanno bisogno di una sandbox su questo server';

  @override
  String get runSandboxUnavailable =>
      'Questo server non ha una sandbox, quindi solo il suo proprietario può eseguire agenti qui. Il proprietario può installare la sandbox oppure disattivarla per tutti.';

  @override
  String get scriptToolCalls => 'Chiamate a strumenti';

  @override
  String scriptCallCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count chiamate',
      one: '1 chiamata',
    );
    return '$_temp0';
  }

  @override
  String scriptCallsRunning(int count) {
    return '$count in esecuzione';
  }

  @override
  String scriptCallsOk(int count) {
    return '$count riuscite';
  }

  @override
  String scriptCallsFailed(int count) {
    return '$count non riuscite';
  }

  @override
  String scriptCallsDenied(int count) {
    return '$count negate';
  }

  @override
  String scriptCallsCancelled(int count) {
    return '$count annullate';
  }

  @override
  String scriptCallsQueued(int count) {
    return '$count in coda';
  }

  @override
  String scriptCallsSkipped(int count) {
    return '$count saltate';
  }

  @override
  String get scriptStepQueued => 'In coda';

  @override
  String get scriptStepSkipped => 'Saltato';

  @override
  String get scriptGroupLoop => 'Ciclo';

  @override
  String get scriptGroupEach => 'Per ogni';

  @override
  String get scriptGroupParallel => 'In parallelo';

  @override
  String get scriptGroupFunction => 'Funzione';

  @override
  String scriptCallsHidden(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Mostra $count chiamate in più',
      one: 'Mostra 1 chiamata in più',
    );
    return '$_temp0';
  }

  @override
  String get scriptCallsUnplaced => 'Chiamate non collocate nello script';

  @override
  String get scriptToolComputed => 'Strumento';

  @override
  String scriptStepSemantics(String subject, String state) {
    return '$subject, $state';
  }

  @override
  String get scriptSourceLabel => 'Script';

  @override
  String scriptSourceLines(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count righe',
      one: '1 riga',
    );
    return '$_temp0';
  }

  @override
  String get scriptStateRunning => 'In esecuzione';

  @override
  String get scriptStateCompleted => 'Completato';

  @override
  String get scriptStateFailed => 'Non riuscito';

  @override
  String get scriptStateTimedOut => 'Tempo scaduto';

  @override
  String get scriptStateCancelled => 'Annullato';

  @override
  String get scriptStateMemoryExceeded => 'Memoria esaurita';

  @override
  String get scriptStateOutputExceeded => 'Output troppo lungo';

  @override
  String get scriptStateSandboxError => 'Errore della sandbox';

  @override
  String get scriptStateRefused => 'Rifiutato';

  @override
  String get scriptOriginLine => 'Da uno script che l\'agente sta eseguendo';

  @override
  String get codeModeTitle => 'Modalità codice';

  @override
  String get codeModeAvailable => 'Disponibile';

  @override
  String get codeModeUnavailable => 'Non disponibile';

  @override
  String codeModeUnavailableNote(String reason) {
    return 'Questo server non può eseguire script, quindi gli agenti qui chiamano i loro strumenti uno alla volta. Il server indica: $reason';
  }

  @override
  String get codeModeNoReason => 'non è stato fornito alcun motivo.';

  @override
  String get workKindUnknown =>
      'Per un motivo che questa versione non riconosce:';

  @override
  String get workRefusalUnknown => 'Il server ha rifiutato questo:';

  @override
  String workActionFailed(String error) {
    return 'Non ha funzionato: $error';
  }

  @override
  String get wakeKindStopped =>
      'Trattenuto perché una persona ha fermato l\'esecuzione.';

  @override
  String get wakeKindAttempts => 'La consegna è fallita tre volte.';

  @override
  String get wakeKindAgentDeleted => 'L\'agente non esiste più.';

  @override
  String get wakeKindAgentNotDispatchable => 'L\'agente è ritirato.';

  @override
  String get wakeKindAgentPaused => 'L\'agente è in pausa.';

  @override
  String get wakeKindPersonRemoved =>
      'La persona per cui agisce ha lasciato lo spazio di lavoro.';

  @override
  String get wakeKindBudgetBlocked => 'Un budget blocca un\'esecuzione.';

  @override
  String get wakeKindTakeOver =>
      'Una persona ha preso il controllo del worktree.';

  @override
  String get wakeKindRateCapConversation =>
      'Questa conversazione ha avviato 30 esecuzioni da risvegli nell\'ultima ora.';

  @override
  String get wakeKindRateCapWorkspace =>
      'Questo spazio di lavoro ha avviato 300 esecuzioni da risvegli nell\'ultima ora.';

  @override
  String get wakeKindLiveRunNoInput =>
      'L\'esecuzione attiva dell\'agente qui non accetta input.';

  @override
  String get wakeKindLiveRunOtherOptions =>
      'L\'esecuzione attiva dell\'agente qui procede in modo diverso, quindi questa ne avvia una propria dopo di essa.';

  @override
  String get wakeKindLiveRunOtherPerson =>
      'L\'esecuzione attiva dell\'agente qui agisce per un\'altra persona, quindi questa ne avvia una propria dopo di essa.';

  @override
  String get wakeKindDispatchRefused =>
      'Non è stato possibile avviare l\'esecuzione.';

  @override
  String get wakeKindSandboxUnavailable =>
      'Nessuna sandbox è disponibile per un\'esecuzione in sola lettura.';

  @override
  String get wakeKindReadOnlyUnavailable =>
      'Il backend di questo agente non può mantenere un\'esecuzione in sola lettura.';

  @override
  String get wakeKindServerStopped =>
      'Il riavvio del server ha fermato l\'esecuzione.';

  @override
  String get wakeKindServerRestarted =>
      'Il server si è riavviato durante l\'esecuzione di una persona.';

  @override
  String get wakeKindGuardFailed =>
      'Un controllo prima della consegna non è riuscito.';

  @override
  String get wakeKindLimit =>
      'In attesa che il limite di utilizzo del provider si ripristini.';

  @override
  String get wakeKindLimitRunLive =>
      'In attesa che l\'esecuzione al limite di utilizzo termini.';

  @override
  String get wakeKindWakeMissed => 'Perso mentre il server era spento.';

  @override
  String get wakeKindPipelineRunEnded =>
      'La sua esecuzione della pipeline è terminata.';

  @override
  String get wakeKindGoalEnded => 'Il suo obiettivo è terminato.';

  @override
  String get wakeKindGoalBudgetExhausted =>
      'Il suo obiettivo ha esaurito il budget.';

  @override
  String get wakeKindGoalReviewStale =>
      'L\'obiettivo è cambiato da quando è stata richiesta questa revisione.';

  @override
  String get wakeKindGoalPaused => 'Il suo obiettivo è in pausa.';

  @override
  String get wakeKindGoalHeld => 'Il suo obiettivo è trattenuto.';

  @override
  String get wakeKindGoalStopped => 'Il suo obiettivo è stato fermato.';

  @override
  String get wakeKindAskSettled =>
      'La domanda a cui risponde era già stata chiusa.';

  @override
  String get wakeKindRuleEnded => 'La sua pianificazione è terminata.';

  @override
  String get wakeRefusalNotYours =>
      'Questo risveglio agisce per un\'altra persona. Solo lei può consegnarlo o riprenderlo.';

  @override
  String get wakeRefusalSettled => 'Questo risveglio si è già concluso.';

  @override
  String get goalRefusalAlreadyActive =>
      'Questo agente ha già un obiettivo attivo.';

  @override
  String get goalRefusalNotInReview =>
      'Questo obiettivo non è in attesa di revisione.';

  @override
  String get goalRefusalEvidenceIncomplete =>
      'Le prove dell\'obiettivo sono incomplete.';

  @override
  String get goalRefusalClaimPending =>
      'L\'affermazione che è completato è ancora in verifica.';

  @override
  String get goalRefusalNotActiveSegment =>
      'Questo obiettivo non ha nessun segmento in esecuzione.';

  @override
  String get goalRefusalNotYours =>
      'Solo la persona che ha avviato questo obiettivo può farlo.';

  @override
  String get goalRefusalNotPaused => 'Metti prima in pausa l\'obiettivo.';

  @override
  String get goalRefusalContractInvalid =>
      'Il contratto dell\'obiettivo non può essere letto.';

  @override
  String get goalRefusalCheckerUnknown => 'Nessun agente ha quel nome.';

  @override
  String get goalRefusalCheckerAmbiguous => 'Più di un agente ha quel nome.';

  @override
  String get goalRefusalCheckerIsGoalAgent =>
      'Il checker deve essere un agente diverso da quello che svolge il lavoro.';

  @override
  String get goalRefusalCommandInvalid =>
      'Questo obiettivo non può essere letto:';

  @override
  String get wakeRuleRefusalIntervalTooShort =>
      'L\'intervallo è troppo breve. Scegli almeno un minuto.';

  @override
  String get wakeRuleRefusalTooSoon =>
      'Quell\'orario è troppo vicino. Scegline uno successivo.';

  @override
  String get wakeRuleRefusalLineageEnded =>
      'Questa catena di risvegli ha esaurito le sue esecuzioni o il suo tempo.';

  @override
  String get wakeRuleRefusalWatchTargetUnreadable =>
      'Non puoi leggere ciò che questo monitorerebbe.';

  @override
  String get wakeRuleRefusalExpiryRequired =>
      'Dagli una data di fine o un numero di esecuzioni.';

  @override
  String get wakeRuleRefusalLimitReached =>
      'Questa conversazione o questo agente ha già tutte le pianificazioni che può avere.';

  @override
  String get wakeRuleRefusalInvalidWhen => 'Non è possibile leggere l\'orario.';

  @override
  String get wakeRuleRefusalNoteTooLong => 'La nota è troppo lunga.';

  @override
  String get wakeRuleRefusalExpiryTooLong => 'La fine è troppo lontana.';

  @override
  String get wakeRuleRefusalLimitOutOfRange =>
      'Un limite di esecuzioni, giorni o budget è fuori intervallo.';

  @override
  String get wakeRuleRefusalNextOutsideLoop =>
      'Solo un ciclo può scegliere da sé il prossimo orario.';

  @override
  String get wakeRuleRefusalWatchRefused => 'Questo non può essere monitorato.';

  @override
  String get wakeRuleRefusalRuleEnded =>
      'Questa pianificazione è già terminata.';

  @override
  String get wakeRuleRefusalNotYours =>
      'Questa pianificazione appartiene a qualcun altro.';

  @override
  String get wakeRuleEndFired => 'Ha eseguito la sua unica volta.';

  @override
  String get wakeRuleEndExpired => 'Ha raggiunto la data di fine.';

  @override
  String get wakeRuleEndRunCap => 'Ha esaurito le sue esecuzioni.';

  @override
  String get wakeRuleEndCostCap => 'Ha raggiunto il suo limite di costo.';

  @override
  String get wakeRuleEndGoalEnded => 'Il suo obiettivo è terminato.';

  @override
  String get wakeRuleEndCancelled => 'È stata annullata.';

  @override
  String get wakeRuleEndMemberRemoved =>
      'La persona per cui agisce ha lasciato lo spazio di lavoro.';

  @override
  String get wakeRuleEndInvalidRow =>
      'Le sue impostazioni salvate non possono essere lette.';

  @override
  String goalHoldWorking(int segment) {
    final intl.NumberFormat segmentNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String segmentString = segmentNumberFormat.format(segment);

    return 'Lavora sul segmento $segmentString. Nessuno deve intervenire.';
  }

  @override
  String get goalHoldWaiting =>
      'Attende il lavoro che gli spetta. Continua da solo.';

  @override
  String goalHoldWaitingUntil(String time) {
    return 'Attende il lavoro che gli spetta. Continua da solo alle $time al più tardi.';
  }

  @override
  String get goalHoldVerifying =>
      'Dice di essere completato. Il server esegue i suoi controlli, poi decide un revisore.';

  @override
  String get goalHoldLimit =>
      'In pausa al limite di utilizzo del provider. Riprende da solo dopo il ripristino.';

  @override
  String goalHoldLimitUntil(String time) {
    return 'In pausa al limite di utilizzo del provider. Riprende da solo alle $time.';
  }

  @override
  String get goalHoldPerson =>
      'In attesa che una persona risponda nella conversazione. Continua quando qualcuno risponde.';

  @override
  String get goalHoldByPerson =>
      'In pausa per decisione di una persona. Resta in pausa finché qualcuno non lo riprende.';

  @override
  String get goalHoldNeedsReview =>
      'In attesa di revisione: non può andare avanti da solo. Approvalo come completato, riprendilo o annullalo.';

  @override
  String get goalHoldBudget =>
      'Ha esaurito il budget. Alza il budget per farlo continuare.';

  @override
  String goalHoldLimitParks(int count, int max) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);
    final intl.NumberFormat maxNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String maxString = maxNumberFormat.format(max);

    return 'Pause al limite di utilizzo: $countString su $maxString';
  }

  @override
  String get goalHoldDetailStalled => 'Nessun progresso negli ultimi segmenti.';

  @override
  String get goalHoldDetailStalledWaiting =>
      'Ha atteso 24 ore sullo stesso lavoro senza progressi.';

  @override
  String get goalHoldDetailVerificationFailed =>
      'L\'ultimo controllo non è riuscito.';

  @override
  String get goalHoldDetailCannotVerify =>
      'Il checker non è riuscito a stabilire se è completato.';

  @override
  String get goalHoldDetailSandboxUnavailable =>
      'Nessuna sandbox è disponibile per eseguire i suoi controlli.';

  @override
  String get goalHoldDetailCheckerUnavailable =>
      'Il suo agente checker non è disponibile. Scegline un altro, poi riprendi.';

  @override
  String get goalHoldDetailCheckBroken =>
      'Questo controllo non può essere eseguito:';

  @override
  String get goalHoldDetailWakeSkipped =>
      'Il suo risveglio non è stato consegnato.';

  @override
  String get goalHoldDetailClaimPending =>
      'La sua affermazione di essere completato attende un controllo.';

  @override
  String get goalHoldDetailUnanswered =>
      'Una domanda o una richiesta di approvazione a una persona è rimasta senza risposta.';

  @override
  String get goalHoldDetailLimitParks =>
      'Ha raggiunto i limiti di utilizzo troppo spesso. Controllalo, poi riprendi.';

  @override
  String get goalHoldDetailInput =>
      'In attesa di una risposta nella conversazione.';

  @override
  String goalSegments(int run, int max) {
    final intl.NumberFormat runNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String runString = runNumberFormat.format(run);
    final intl.NumberFormat maxNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String maxString = maxNumberFormat.format(max);

    return 'Segmento $runString di $maxString';
  }

  @override
  String goalSegmentsNoCap(int run) {
    final intl.NumberFormat runNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String runString = runNumberFormat.format(run);

    return 'Segmento $runString, senza limite';
  }

  @override
  String goalMoney(String spent, String cap) {
    return 'Speso $spent di $cap';
  }

  @override
  String goalDeadline(String time) {
    return 'Scadenza $time';
  }

  @override
  String get goalPipelineStep =>
      'Un passo della pipeline persegue questo obiettivo.';

  @override
  String get goalSummaryHeading => 'Ultimo riepilogo';

  @override
  String get goalDoneMeans => 'Completato significa';

  @override
  String get goalChecks => 'Controlli';

  @override
  String get goalBoundaries => 'Limiti';

  @override
  String get goalStopWhen => 'Fermati e chiedi quando';

  @override
  String get goalNoMachineCheck =>
      'Nessun controllo automatico. Un revisore giudica da ciò che può leggere.';

  @override
  String get goalCheckEnvironment => 'Attività dell\'ambiente';

  @override
  String goalLastCheck(int round, String time) {
    final intl.NumberFormat roundNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String roundString = roundNumberFormat.format(round);

    return 'Ultimo controllo, giro $roundString, $time';
  }

  @override
  String get goalClaim => 'Cosa ha dichiarato';

  @override
  String get goalCheckPassed => 'Superato';

  @override
  String goalCheckFailed(int code) {
    return 'Non riuscito, uscita $code';
  }

  @override
  String get goalCheckTimedOut => 'Tempo scaduto';

  @override
  String get goalCheckNotRerun => 'Non rieseguito: nulla è cambiato';

  @override
  String get goalCheckBroken => 'Impossibile eseguire';

  @override
  String get goalCriterionMet => 'Soddisfatto';

  @override
  String get goalCriterionUnmet => 'Non soddisfatto';

  @override
  String get goalCriterionCannotTell => 'Impossibile dirlo';

  @override
  String get goalVerdictPass => 'Esito: completato';

  @override
  String get goalVerdictFail => 'Esito: non completato';

  @override
  String get goalVerdictCannotVerify => 'Esito: impossibile stabilirlo';

  @override
  String get goalConcerns => 'Dubbi';

  @override
  String goalVerifiedBy(String agent) {
    return 'Verificato da $agent';
  }

  @override
  String get goalVerifiedBySelf =>
      'Verificato dall\'agente stesso (nessun checker separato)';

  @override
  String get goalClosedByPerson =>
      'Chiuso da una persona senza un controllo superato';

  @override
  String get goalApprove => 'Approva completamento';

  @override
  String get goalApproveTitle => 'Chiudere questo obiettivo come completato?';

  @override
  String get goalApproveBody =>
      'Nessun controllo lo ha confermato. Lo chiudi con la tua parola, e l\'obiettivo registra che una persona lo ha chiuso senza verifica.';

  @override
  String get goalApproveConfirm => 'Chiudi come completato';

  @override
  String get goalResumeNotYours =>
      'Riprenderlo o aumentarne il budget spetta a chi lo ha avviato.';

  @override
  String get goalChooseChecker => 'Scegli un altro checker';

  @override
  String goalCheckerSet(String agent) {
    return '$agent ora lo controlla. Riprendi per verificare di nuovo.';
  }

  @override
  String get goalSchedules => 'Pianificazioni';

  @override
  String get goalRepeat => 'Ripeti';

  @override
  String get goalCreateChecks => 'Controlli (facoltativi)';

  @override
  String get goalCreateCheckHint =>
      'Un comando che passa quando il lavoro è finito';

  @override
  String get goalCreateAddCheck => 'Aggiungi controllo';

  @override
  String get goalCreateRemoveCheck => 'Rimuovi controllo';

  @override
  String get goalCreateSegmentCap => 'Limite di segmenti (facoltativo)';

  @override
  String get goalCreateSegmentInvalid =>
      'Il limite di segmenti è un numero intero, di almeno 1.';

  @override
  String get scheduleCreateTitle => 'Ripeti un prompt';

  @override
  String get scheduleCadence => 'Con quale frequenza';

  @override
  String get scheduleEveryMinutes => 'Ogni N minuti';

  @override
  String get scheduleEveryHours => 'Ogni N ore';

  @override
  String get scheduleSelfPaced => 'Autogestita';

  @override
  String get scheduleSelfPacedHint =>
      'L\'agente sceglie il ritardo dopo ogni esecuzione, tra 1 minuto e 1 ora.';

  @override
  String get scheduleInterval => 'Intervallo';

  @override
  String get scheduleNote => 'Cosa deve fare ogni esecuzione?';

  @override
  String get scheduleCostCap => 'Limite di costo in USD (facoltativo)';

  @override
  String get scheduleExpiryDays => 'Termina dopo N giorni (facoltativo)';

  @override
  String get scheduleCreateInvalid =>
      'Scegli uno spazio e un agente, scrivi cosa deve fare ogni esecuzione e inserisci numeri interi di almeno 1.';

  @override
  String get scheduleCreateButton => 'Avvia pianificazione';

  @override
  String get scheduleCreateConfirmTitle => 'Avviare questa pianificazione?';

  @override
  String scheduleCreateConfirmEveryMinutes(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Si esegue ogni $countString minuti, a partire da ora.',
      one: 'Si esegue ogni minuto, a partire da ora.',
    );
    return '$_temp0';
  }

  @override
  String scheduleCreateConfirmEveryHours(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Si esegue ogni $countString ore, a partire da ora.',
      one: 'Si esegue ogni ora, a partire da ora.',
    );
    return '$_temp0';
  }

  @override
  String get scheduleCreateConfirmSelfPaced =>
      'Parte ora, poi l\'agente sceglie quando eseguirsi di nuovo.';

  @override
  String get scheduleCreated =>
      'Pianificazione avviata. È elencata in Pianificazioni.';

  @override
  String get schedulesTitle => 'Pianificazioni';

  @override
  String get schedulesLoadFailed => 'Impossibile caricare le pianificazioni';

  @override
  String get schedulesEmpty => 'Nessuna pianificazione o monitoraggio';

  @override
  String get schedulesEmptyDescription =>
      'Ripeti un prompt dalla schermata degli obiettivi, oppure invia /loop o /schedule in una conversazione.';

  @override
  String get scheduleMissing =>
      'Questa pianificazione non è più disponibile in questo spazio di lavoro.';

  @override
  String scheduleEvery(String interval) {
    return 'Ogni $interval';
  }

  @override
  String get scheduleSelfPacedLoop => 'Ciclo autogestito';

  @override
  String get scheduleCron => 'Pianificazione cron';

  @override
  String scheduleOnce(String time) {
    return 'Una volta alle $time';
  }

  @override
  String scheduleWatch(String event) {
    return 'Monitoraggio: $event';
  }

  @override
  String get scheduleWatchPrChecks => 'controlli della pull request';

  @override
  String get scheduleWatchPrReview => 'revisioni della pull request';

  @override
  String get scheduleWatchPrMerged => 'unione della pull request';

  @override
  String get scheduleWatchEnvironment => 'ambiente';

  @override
  String get scheduleWatchTicket => 'ticket';

  @override
  String get scheduleWatchPipelineRun => 'esecuzione della pipeline';

  @override
  String get scheduleStatusActive => 'Attiva';

  @override
  String get scheduleStatusPaused => 'In pausa';

  @override
  String get scheduleStatusEnded => 'Terminata';

  @override
  String scheduleWakes(String agent) {
    return 'Risveglia $agent';
  }

  @override
  String scheduleNext(String time) {
    return 'Prossima esecuzione $time';
  }

  @override
  String scheduleLast(String time) {
    return 'Ultima esecuzione $time';
  }

  @override
  String scheduleRuns(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString esecuzioni',
      one: '1 esecuzione',
    );
    return '$_temp0';
  }

  @override
  String scheduleRunsOf(int count, int max) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);
    final intl.NumberFormat maxNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String maxString = maxNumberFormat.format(max);

    return '$countString di $maxString esecuzioni';
  }

  @override
  String scheduleSkipped(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString saltate',
      one: '1 saltata',
    );
    return '$_temp0';
  }

  @override
  String scheduleEnds(String time) {
    return 'Termina $time';
  }

  @override
  String scheduleChain(int count, String time) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Parte di una catena: $countString esecuzioni rimanenti, termina $time';
  }

  @override
  String get scheduleNoteAgent => 'La nota dell\'agente, con parole sue:';

  @override
  String get scheduleNotePerson => 'Una nota di una persona:';

  @override
  String scheduleActsFor(String name) {
    return 'Agisce per $name';
  }

  @override
  String get scheduleActsForBot => 'Non agisce per nessuna persona';

  @override
  String get scheduleGoalBound => 'Termina con il suo obiettivo.';

  @override
  String get schedulePause => 'Pausa';

  @override
  String get scheduleResume => 'Riprendi';

  @override
  String get scheduleDelete => 'Elimina';

  @override
  String get scheduleRemove => 'Rimuovi';

  @override
  String get scheduleDeleteTitle => 'Eliminare questa pianificazione?';

  @override
  String get scheduleDeleteBody =>
      'Si ferma in modo definitivo. Ciò che ha già fatto non viene annullato.';

  @override
  String get scheduleRemoveTitle => 'Rimuovere questa pianificazione?';

  @override
  String get scheduleRemoveBody => 'Scompare dall\'elenco.';

  @override
  String get scheduleResumeNotYours =>
      'Solo la persona per cui agisce questa pianificazione può riprenderla.';

  @override
  String get scheduleResumeAdminOnly =>
      'Solo un admin dello spazio di lavoro può riprendere una pianificazione che non appartiene a nessuna persona.';

  @override
  String get scheduleOpenConversation => 'Apri conversazione';

  @override
  String get progressWaiting => 'In attesa';

  @override
  String get progressNothingWaiting => 'Non c\'è nulla in attesa.';

  @override
  String get wakeOriginGoal => 'Obiettivo';

  @override
  String get wakeOriginGoalCheck => 'Controllo obiettivo';

  @override
  String get wakeOriginGoalReview => 'Revisione obiettivo';

  @override
  String get wakeOriginSchedule => 'Pianificazione';

  @override
  String get wakeOriginWatch => 'Monitoraggio';

  @override
  String get wakeOriginReply => 'Risposta';

  @override
  String get wakeOriginMessage => 'Messaggio';

  @override
  String get wakeOriginWorkFinished => 'Lavoro completato';

  @override
  String get wakeOriginLimitReset => 'Limite ripristinato';

  @override
  String get wakeOriginRecovery => 'Ripristino';

  @override
  String get wakeOriginAssignment => 'Assegnazione';

  @override
  String get wakeOriginPipelineStep => 'Passo della pipeline';

  @override
  String get wakeOriginImprovementReview => 'Revisione dei miglioramenti';

  @override
  String wakeOriginReplyFrom(String agent) {
    return 'Risposta da $agent';
  }

  @override
  String wakeOriginMessageFrom(String agent) {
    return 'Messaggio da $agent';
  }

  @override
  String wakeOriginWorkFinishedBy(String agent) {
    return 'Lavoro completato da $agent';
  }

  @override
  String wakeFor(String agent) {
    return 'Per $agent';
  }

  @override
  String wakeDue(String time) {
    return 'Scadenza $time';
  }

  @override
  String get wakeDueNow => 'In scadenza ora';

  @override
  String get wakeHeld => 'Trattenuto';

  @override
  String wakeExpires(String time) {
    return 'Scade $time';
  }

  @override
  String wakeAttempt(int attempt) {
    final intl.NumberFormat attemptNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String attemptString = attemptNumberFormat.format(attempt);

    return 'Tentativo $attemptString';
  }

  @override
  String get wakeCancel => 'Annulla';

  @override
  String get wakeDeliverNow => 'Consegna ora';

  @override
  String get wakeResume => 'Riprendi';

  @override
  String get wakeDismiss => 'Ignora';

  @override
  String get wakeResumeOnlyTheirs =>
      'Solo la persona la cui esecuzione è questa può riprenderla.';

  @override
  String get wakeRecovery =>
      'Il server si è riavviato durante questa esecuzione. Riprendila per continuarla, oppure ignorala.';

  @override
  String limitParkTitle(String provider, String time) {
    return 'In pausa per il limite di utilizzo di $provider, che si ripristina alle $time. L\'esecuzione attende Riprendi, per un massimo di 7 giorni dal ripristino.';
  }

  @override
  String limitParkTitleUnnamed(String time) {
    return 'In pausa per il limite di utilizzo del provider, che si ripristina alle $time. L\'esecuzione attende Riprendi, per un massimo di 7 giorni dal ripristino.';
  }

  @override
  String get limitParkResumeNow => 'Riprendi ora';

  @override
  String get limitParkCancel => 'Annulla';

  @override
  String limitParkResumed(String provider) {
    return 'Ripreso dopo il limite di utilizzo di $provider.';
  }

  @override
  String limitParkGone(String provider) {
    return 'Non è più in attesa del limite di utilizzo di $provider.';
  }

  @override
  String get limitParkProviderUnknown => 'il provider';

  @override
  String get mobileHeldMessages => 'Messaggi trattenuti';

  @override
  String get heldSteeringTitle =>
      'Trattenuti perché l\'esecuzione è terminata prima che potesse prenderli. Invia ora i tuoi o rimuovili.';

  @override
  String get heldSteeringRelease => 'Invia i messaggi trattenuti';

  @override
  String get notifGoalCompleted => 'Obiettivo completato';

  @override
  String get notifGoalFailed => 'Obiettivo non riuscito';

  @override
  String get notifGoalCancelled => 'Obiettivo annullato';

  @override
  String get notifGoalBudgetExhausted => 'L\'obiettivo ha esaurito il budget';

  @override
  String get notifGoalNeedsReview => 'Un obiettivo attende la tua revisione';

  @override
  String get notifGoalNeedsPerson => 'Un obiettivo ha bisogno di te';

  @override
  String get notifGoalOnHold => 'Un obiettivo è trattenuto';

  @override
  String get notifWakeRuleEnded => 'Una pianificazione è terminata';

  @override
  String notifWaitingDigest(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString cose attendono di te',
      one: '1 cosa attende di te',
    );
    return '$_temp0';
  }

  @override
  String notifImprovementProposed(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Sono stati proposti $countString miglioramenti',
      one: 'È stato proposto un miglioramento',
    );
    return '$_temp0';
  }

  @override
  String get notifPipelineRunHeld =>
      'Un\'esecuzione della pipeline è trattenuta al suo budget';

  @override
  String notifPipelineRunHeldBody(String spent, String cap) {
    return 'Spesi $spent di $cap';
  }

  @override
  String get notifNeedsYou => 'Serve te';

  @override
  String get notifDigestGoalReview => 'L\'obiettivo attende la revisione';

  @override
  String get notifDigestGoalPerson => 'L\'obiettivo ha bisogno di una persona';

  @override
  String get notifDigestHeldWake => 'Risveglio trattenuto';

  @override
  String get notifDigestImprovement => 'Miglioramento proposto';

  @override
  String get wakeKindRulePaused => 'La sua pianificazione è in pausa.';

  @override
  String get wakeKindRuleBusy =>
      'L\'agente era occupato, e questa pianificazione salta i momenti in cui lo è.';

  @override
  String get wakeKindRuleFolded =>
      'Un evento successivo dello stesso monitoraggio ha preso il suo posto.';

  @override
  String get wakeKindRuleSuperseded =>
      'Un orario successivo della sua pianificazione l\'ha sostituito.';

  @override
  String get wakeKindRuleNotified =>
      'La sua pianificazione invia solo una notifica, quindi nessuna esecuzione è partita.';

  @override
  String get wakeKindRuleLimitParked =>
      'La sua pianificazione attende che il limite di utilizzo del provider si ripristini.';

  @override
  String get improvementRefusalCooldown =>
      'Una revisione dei miglioramenti è stata eseguita poco fa in questa conversazione. Riprova più tardi.';

  @override
  String get improvementRefusalQueued =>
      'Una revisione dei miglioramenti di questa conversazione è già in attesa di essere eseguita.';

  @override
  String get improvementRefusalAgentNotFound =>
      'Quell\'agente non fa parte di questo spazio di lavoro.';

  @override
  String get steeringRefusalHeldByLimit =>
      'I messaggi trattenuti da un limite di utilizzo non possono essere inviati a mano. Attendono che l\'esecuzione in pausa riprenda.';

  @override
  String limitParkCancelled(String provider) {
    return 'L\'attesa al limite di utilizzo di $provider è stata annullata.';
  }

  @override
  String limitParkExpired(String provider) {
    return 'L\'attesa al limite di utilizzo di $provider è scaduta prima che l\'esecuzione riprendesse.';
  }

  @override
  String limitParkSkipped(String provider) {
    return 'L\'esecuzione non è ripresa dopo il limite di utilizzo di $provider.';
  }

  @override
  String get heldSteeringLimitTitle =>
      'Trattenuti mentre l\'esecuzione attende il ripristino del limite di utilizzo. Verranno inviati quando la persona per cui lavora la riprende.';

  @override
  String heldSteeringLimitAt(String time) {
    return 'Trattenuti fino al ripristino del limite di utilizzo alle $time. Verranno inviati quando la persona per cui lavora l\'esecuzione la riprende.';
  }

  @override
  String get heldSteeringOtherTitle =>
      'Trattenuti dal server. Puoi rimuoverli.';

  @override
  String workRowWoke(int count, String agent) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ha risvegliato $agent per $countString elementi in attesa',
      one: 'Ha risvegliato $agent',
    );
    return '$_temp0';
  }

  @override
  String workRowWakeMissed(String agent) {
    return 'Un risveglio per $agent è stato perso mentre il server era spento.';
  }

  @override
  String workRowWakeSkipped(String agent) {
    return 'Un risveglio per $agent non è stato consegnato.';
  }

  @override
  String workRowScheduleCreated(String agent) {
    return 'Pianificazione impostata per $agent.';
  }

  @override
  String workRowScheduleEnded(String agent) {
    return 'La pianificazione di $agent è terminata.';
  }

  @override
  String workRowNoteFromAgent(String agent) {
    return 'Nota della pianificazione di $agent:';
  }

  @override
  String get workRowNoteFromPerson =>
      'Nota della pianificazione di una persona:';

  @override
  String workRowCommandRefusedNamed(String command) {
    return 'Il comando $command è stato rifiutato.';
  }

  @override
  String get workRowCommandRefused => 'Un comando è stato rifiutato.';

  @override
  String workRowCapRaised(String person, String from, String to) {
    return '$person ha alzato il limite di spesa della pipeline da $from a $to.';
  }

  @override
  String workRowCapRaisedNoAmounts(String person) {
    return '$person ha alzato il limite di spesa della pipeline.';
  }

  @override
  String get workRowApplyIncomplete =>
      'Una modifica accettata a questa competenza non ha potuto essere completata, perché nel frattempo la competenza è cambiata. La proposta è stata ripristinata.';

  @override
  String get workRowOpenSchedule => 'Apri pianificazione';

  @override
  String get heldSteeringOthersTitle =>
      'Trattenuti perché l\'esecuzione è terminata prima che potesse prenderli. Solo la persona che ha scritto un messaggio può inviarlo.';

  @override
  String get heldSteeringOnlyYours =>
      'Invia solo i tuoi messaggi. Gli altri attendono le persone che li hanno scritti.';

  @override
  String heldSteeringWrittenBy(String name) {
    return 'Scritto da $name';
  }

  @override
  String get steeringRefusalNotYours =>
      'Solo la persona che ha scritto un messaggio trattenuto può inviarlo, e nessuno di questi è tuo.';

  @override
  String get steeringRefusalNeedsWrite =>
      'Serve l\'accesso in scrittura ai repository di questo spazio per guidare un\'esecuzione che agisce per un\'altra persona.';

  @override
  String workRowSchedulePaused(String name, String agent) {
    return '$name ha messo in pausa la pianificazione per $agent.';
  }

  @override
  String get goalVerdictObjective => 'L\'obiettivo nel suo complesso';

  @override
  String get notifDigestRequest => 'In attesa della tua risposta';
}
