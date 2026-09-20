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
}
