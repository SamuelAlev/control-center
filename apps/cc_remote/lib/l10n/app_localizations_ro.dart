// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Romanian Moldavian Moldovan (`ro`).
class AppLocalizationsRo extends AppLocalizations {
  AppLocalizationsRo([String locale = 'ro']) : super(locale);

  @override
  String get appTitle => 'Control Center';

  @override
  String get back => 'Înapoi';

  @override
  String get cancel => 'Anulează';

  @override
  String get retry => 'Reîncearcă';

  @override
  String get tryAgain => 'Încearcă din nou';

  @override
  String get settings => 'Setări';

  @override
  String get refresh => 'Reîmprospătează';

  @override
  String get approve => 'Aprobă';

  @override
  String get deny => 'Refuză';

  @override
  String get continueLabel => 'Continuă';

  @override
  String get agentQuestionHeader => 'Întrebare pentru tine';

  @override
  String get agentQuestionAnsweredLabel => 'Răspuns';

  @override
  String get agentQuestionSkip => 'Omite';

  @override
  String get agentQuestionSkippedLabel => 'Omisă';

  @override
  String get agentQuestionFreeformHint => 'Tastează răspunsul…';

  @override
  String get agentApprovalRequired => 'Este necesară aprobarea';

  @override
  String get copyCommand => 'Copiază comanda';

  @override
  String get approveAndRemember => 'Aprobă pentru 8 ore';

  @override
  String get decline => 'Respinge';

  @override
  String get confirm => 'Confirmă';

  @override
  String get send => 'Trimite';

  @override
  String get close => 'Închide';

  @override
  String get expand => 'Extinde';

  @override
  String get zoomIn => 'Mărește';

  @override
  String get zoomOut => 'Micșorează';

  @override
  String get resetZoom => 'Resetează zoomul';

  @override
  String get scanQrPrompt =>
      'Scanează codul QR din Control Center ca să asociezi telefonul acesta.';

  @override
  String get scanQrHelp =>
      'Deschide camera și îndreapt-o spre QR-ul afișat în Control Center. Telefonul acesta se conectează direct printr-o legătură privată.';

  @override
  String get connectingToMac => 'Se conectează la Control Center…';

  @override
  String get connectingDetail => 'Se stabilește o legătură sigură și directă.';

  @override
  String get identityChangedTitle => 'Identitatea serverului s-a schimbat';

  @override
  String get identityChangedBody =>
      'Serverul acesta nu mai corespunde identității salvate la asociere. Poate însemna că serverul a fost reinstalat — sau că ceva interceptează conexiunea. Ca să rămâi în siguranță, dispozitivul acesta nu se va conecta. Elimină asocierea, apoi scanează un QR nou din Control Center ca să asociezi din nou.';

  @override
  String get removePairing => 'Elimină asocierea';

  @override
  String get couldntConnect => 'Nu s-a putut conecta';

  @override
  String get pendingPairingTitle => 'Te conectezi la acest server?';

  @override
  String get pendingPairingBody =>
      'Un link a cerut Control Center să se asocieze cu acest server. Continuă doar dacă tu ai pornit asta.';

  @override
  String get connect => 'Conectează';

  @override
  String get failureNotPaired =>
      'Neasociat — scanează codul QR din Control Center';

  @override
  String get failureUnreachable =>
      'Nu s-a putut ajunge la server pe nicio cale — verifică dacă rulează sau încearcă aceeași rețea';

  @override
  String get failureIdentityChanged =>
      'Identitatea serverului s-a schimbat — dacă a fost reinstalat, asociază din nou dispozitivul';

  @override
  String get failureAuthRejected =>
      'Serverul a respins dispozitivul acesta — asociază-l din nou din Control Center';

  @override
  String get failureUnknown => 'Nu s-a putut conecta — atinge ca să reîncerci';

  @override
  String get statusConnected => 'Conectat';

  @override
  String get statusConnecting => 'Se conectează';

  @override
  String get statusOffline => 'Offline';

  @override
  String get statusIdentityMismatch => 'Neconcordanță de identitate';

  @override
  String get statusNotPaired => 'Neasociat';

  @override
  String get statusConfirmPairing => 'Confirmă asocierea';

  @override
  String get connectionFailed => 'Conexiunea a eșuat';

  @override
  String get identityMismatchBanner =>
      'Identitatea serverului s-a schimbat — conexiunea s-a oprit. Asociază din nou dispozitivul ca să continui.';

  @override
  String get tabInbox => 'Inbox';

  @override
  String get tabTickets => 'Tichete';

  @override
  String get tabChat => 'Chat';

  @override
  String get tabPrs => 'PRs';

  @override
  String get tabCalendar => 'Calendar';

  @override
  String get tabNews => 'Știri';

  @override
  String tabWaitingCount(String label, int count) {
    return '$label, $count în așteptare';
  }

  @override
  String get updateAvailable => 'Un Control Center nou este disponibil';

  @override
  String get appearance => 'Aspect';

  @override
  String get language => 'Limbă';

  @override
  String get device => 'Dispozitiv';

  @override
  String get themeSystem => 'Sistem';

  @override
  String get themeLight => 'Luminos';

  @override
  String get themeDark => 'Întunecat';

  @override
  String get languageSystem => 'Sistem';

  @override
  String get disconnectTapAgain =>
      'Atinge din nou ca să deconectezi dispozitivul acesta de la Control Center';

  @override
  String get disconnectDevice => 'Deconectează dispozitivul acesta';

  @override
  String get disconnect => 'Deconectează';

  @override
  String get chooseWorkspace => 'Alege spațiul de lucru';

  @override
  String get workspaces => 'Spații de lucru';

  @override
  String get workspacesLoadFailed => 'Nu s-au putut încărca spațiile de lucru';

  @override
  String get noWorkspacesYet => 'Niciun spațiu de lucru încă';

  @override
  String selectWorkspace(String name) {
    return 'Selectează $name';
  }

  @override
  String get inboxLoadFailed => 'Nu s-a putut încărca inboxul';

  @override
  String get allCaughtUp => 'Ești la zi';

  @override
  String get inboxNothingWaiting =>
      'Nimic nu este blocat și niciun pull request nu te așteaptă.';

  @override
  String get blocked => 'Blocat';

  @override
  String get sectionNeedsYourReview => 'Necesită revizuirea ta';

  @override
  String get sectionReturnedToYou => 'Returnate ție';

  @override
  String get sectionApprovedAndReady => 'Aprobate și gata';

  @override
  String get sectionYourDrafts => 'Ciornele tale';

  @override
  String get sectionWaitingForReviewers => 'Așteaptă recenzenți';

  @override
  String get sectionMergingAndMerged => 'În fuziune și fuzionate recent';

  @override
  String get sectionWaitingForAuthor => 'Așteaptă autorul';

  @override
  String waitingAgo(String ago) {
    return 'așteaptă $ago';
  }

  @override
  String get openConversation => 'Deschide conversația';

  @override
  String get calendarLoadFailed => 'Nu s-a putut încărca calendarul';

  @override
  String get nothingScheduled => 'Nimic programat';

  @override
  String get calendarEmptyDescription =>
      'Evenimentele din calendarele conectate apar aici.';

  @override
  String get agenda => 'Agendă';

  @override
  String get syncCalendarsNow => 'Sincronizează calendarele acum';

  @override
  String get event => 'Eveniment';

  @override
  String get eventNotFound => 'Evenimentul nu a fost găsit';

  @override
  String get eventNotFoundDescription =>
      'Poate fi în afara ferestrei agendei sau a fost eliminat la sursă.';

  @override
  String get joinMeeting => 'Intră în întâlnire';

  @override
  String get join => 'Intră';

  @override
  String attendeesCount(int count) {
    return 'Participanți ($count)';
  }

  @override
  String get details => 'Detalii';

  @override
  String get allDay => 'Toată ziua';

  @override
  String get happeningNow => 'Are loc acum';

  @override
  String inDuration(String duration) {
    return 'Peste $duration';
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
  String get attendeeAccepted => 'acceptat';

  @override
  String get attendeeDeclined => 'refuzat';

  @override
  String get attendeeMaybe => 'poate';

  @override
  String get attendeeNoReply => 'fără răspuns';

  @override
  String get organizer => 'organizator';

  @override
  String get calendarNoAccounts =>
      'Niciun calendar nu este conectat pentru acest spațiu de lucru. Conectează unul din aplicația desktop — autentificarea stochează tokenul pe server.';

  @override
  String get calendarReauthNeeded =>
      'Un cont de calendar trebuie reconectat — ce vezi mai jos poate fi depășit. Reconectează-l din aplicația desktop.';

  @override
  String get spacesLoadFailed => 'Nu s-au putut încărca spațiile';

  @override
  String get noSpaces => 'Niciun spațiu';

  @override
  String get spacesEmptyDescription =>
      'Spațiile din acest spațiu de lucru apar aici.';

  @override
  String get newSpaceFolder => 'Dosar nou';

  @override
  String get folderName => 'Numele dosarului';

  @override
  String get renameSpaceFolder => 'Redenumește dosarul';

  @override
  String get deleteSpaceFolder => 'Șterge dosarul';

  @override
  String get moveSpaceToFolder => 'Mută în dosar';

  @override
  String get removeSpaceFromFolder => 'Elimină din dosar';

  @override
  String get spaceFolderActions => 'Acțiuni pentru dosar';

  @override
  String get deleteFolderWithSpacesWarning =>
      'Ștergerea definitivă a spațiilor le elimină mesajele și directoarele de lucru pentru toată lumea. Această acțiune nu poate fi anulată.';

  @override
  String get deleteSpacesInFolder =>
      'Șterge definitiv spațiile din acest dosar';

  @override
  String get deleteFolderAndSpaces => 'Șterge dosarul și spațiile';

  @override
  String get keepSpacesInFolder =>
      'Altfel, spațiile vor rămâne în afara dosarelor.';

  @override
  String get create => 'Creează';

  @override
  String get otherSpaces => 'Alte spații';

  @override
  String get folderUpdateFailed => 'Dosarele nu au putut fi actualizate';

  @override
  String get thread => 'Fir';

  @override
  String get agentWorking => 'Agentul lucrează';

  @override
  String get messagesLoadFailed => 'Nu s-au putut încărca mesajele';

  @override
  String get noMessagesYet => 'Niciun mesaj încă';

  @override
  String get noMessagesDescription =>
      'Trimite un mesaj ca să începi conversația.';

  @override
  String get agentResponding => 'Agentul răspunde';

  @override
  String get agentFinished => 'Agentul a terminat';

  @override
  String attachmentsTooLarge(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$names sunt prea mari pentru a fi trimise de aici.',
      few: '$names sunt prea mari pentru a fi trimise de aici.',
      one: '$names este prea mare pentru a fi trimis de aici.',
    );
    return '$_temp0';
  }

  @override
  String get teammate => 'Coleg';

  @override
  String get systemSender => 'Sistem';

  @override
  String get agent => 'Agent';

  @override
  String get attachFile => 'Atașează un fișier';

  @override
  String get messageHint => 'Mesaj';

  @override
  String removeAttachment(String name) {
    return 'Elimină $name';
  }

  @override
  String get articlesLoadFailed => 'Nu s-au putut încărca articolele';

  @override
  String get noArticles => 'Niciun articol';

  @override
  String get articlesEmptyDescription =>
      'Articolele noi apar aici pe măsură ce fluxurile se actualizează.';

  @override
  String get unread => 'Necitite';

  @override
  String get allFeeds => 'Toate fluxurile';

  @override
  String get save => 'Salvează';

  @override
  String get unsave => 'Anulează salvarea';

  @override
  String get readFullArticle => 'Citește articolul complet';

  @override
  String get ticketsLoadFailed => 'Nu s-au putut încărca tichetele';

  @override
  String get noTickets => 'Niciun tichet';

  @override
  String get ticketsEmptyDescription =>
      'Tichetele din acest spațiu de lucru apar aici.';

  @override
  String get all => 'Toate';

  @override
  String get ticket => 'Tichet';

  @override
  String get ticketLoadFailed => 'Nu s-a putut încărca tichetul';

  @override
  String assignedTo(String name) {
    return 'Asignat lui $name';
  }

  @override
  String get openInBrowser => 'Deschide în browser';

  @override
  String get status => 'Stare';

  @override
  String get assign => 'Asignează';

  @override
  String get reassign => 'Reasignează';

  @override
  String get noAgents => 'Niciun agent';

  @override
  String get noAgentsDescription =>
      'Asignează un agent din acest spațiu de lucru.';

  @override
  String get statusOpen => 'Deschis';

  @override
  String get statusInProgress => 'În curs';

  @override
  String get statusBlocked => 'Blocat';

  @override
  String get statusInReview => 'În revizuire';

  @override
  String get statusDone => 'Gata';

  @override
  String get statusBacklog => 'Backlog';

  @override
  String get lensNeedsMe => 'Mă așteaptă';

  @override
  String get lensMine => 'Ale mele';

  @override
  String get prsLoadFailed => 'Nu s-au putut încărca pull request-urile';

  @override
  String get noOpenPullRequests => 'Niciun pull request deschis';

  @override
  String get nothingWaitingOnReview => 'Nimic nu așteaptă revizuirea ta';

  @override
  String get noOwnOpenPullRequests => 'Nu ai pull request-uri deschise';

  @override
  String get nothingBlocked => 'Nimic nu este blocat';

  @override
  String get prsEmptyDescription =>
      'Pull request-urile din repo-urile acestui spațiu de lucru apar aici.';

  @override
  String get refreshPullRequests => 'Reîmprospătează pull request-urile';

  @override
  String get noForgeConnected =>
      'Niciun forge nu este conectat pe server, deci nu se pot prelua pull request-uri. Conectează unul din aplicația desktop.';

  @override
  String get draft => 'Ciornă';

  @override
  String get merged => 'Fuzionat';

  @override
  String get closed => 'Închis';

  @override
  String get open => 'Deschis';

  @override
  String get approved => 'Aprobat';

  @override
  String get changesRequested => 'Modificări cerute';

  @override
  String get reviewRequired => 'Este necesară o revizuire';

  @override
  String get checksPassing => 'Verificări reușite';

  @override
  String get checksFailing => 'Verificări eșuate';

  @override
  String get checksRunning => 'Verificări în rulare';

  @override
  String prSemanticLabel(String title, String status) {
    return '$title, $status';
  }

  @override
  String get pullRequest => 'Pull request';

  @override
  String get prLoadFailed => 'Nu s-a putut încărca acest pull request';

  @override
  String get openOnForge => 'Deschide pe forge';

  @override
  String get requestChangesNeedsComment =>
      'Adaugă un comentariu care explică ce trebuie schimbat.';

  @override
  String get conversation => 'Conversație';

  @override
  String get files => 'Fișiere';

  @override
  String get checks => 'Verificări';

  @override
  String labelWithCount(String label, int count) {
    return '$label ($count)';
  }

  @override
  String filesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count de fișiere',
      few: '$count fișiere',
      one: '1 fișier',
    );
    return '$_temp0';
  }

  @override
  String commitsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count de commit-uri',
      few: '$count commit-uri',
      one: '1 commit',
    );
    return '$_temp0';
  }

  @override
  String get conflicts => 'Conflicte';

  @override
  String get reviewers => 'Recenzenți';

  @override
  String get noDescriptionNoComments =>
      'Nicio descriere și niciun comentariu încă.';

  @override
  String get noChangedFiles => 'Niciun fișier modificat.';

  @override
  String get noChecksReported =>
      'Nicio verificare raportată pentru commit-ul head.';

  @override
  String get reviewCommentHint => 'Lasă un comentariu de revizuire…';

  @override
  String get comment => 'Comentează';

  @override
  String get commentPosted => 'Comentariu publicat';

  @override
  String get request => 'Cere';

  @override
  String get squashAndMerge => 'Squash and merge';

  @override
  String noActionsAvailable(String status) {
    return '$status — nicio acțiune disponibilă.';
  }

  @override
  String get reviewApproved => 'a aprobat';

  @override
  String get reviewRequestedChanges => 'a cerut modificări';

  @override
  String get reviewCommented => 'a revizuit';

  @override
  String get reviewPending => 'în așteptare';

  @override
  String get unknownAuthor => 'necunoscut';

  @override
  String hideDiffFor(String file) {
    return 'Ascunde diff-ul pentru $file';
  }

  @override
  String showDiffFor(String file) {
    return 'Arată diff-ul pentru $file';
  }

  @override
  String get checkRunning => 'în rulare';

  @override
  String get checkPassed => 'reușit';

  @override
  String get checkFailed => 'eșuat';

  @override
  String get checkCancelled => 'anulat';

  @override
  String get checkSkipped => 'omis';

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
      'Nu există diff text pentru acest fișier — este binar sau prea mare ca forge-ul să returneze unul.';

  @override
  String showRemainingLines(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Arată cele $count de linii rămase',
      few: 'Arată cele $count linii rămase',
      one: 'Arată linia rămasă',
    );
    return '$_temp0';
  }

  @override
  String unchangedLines(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count de linii neschimbate',
      few: '$count linii neschimbate',
      one: '1 linie neschimbată',
    );
    return '$_temp0';
  }

  @override
  String get jumpToLatest => 'Sari la cele mai recente';

  @override
  String get streaming => 'Streaming';

  @override
  String get working => 'Lucrează';

  @override
  String get input => 'Intrare';

  @override
  String get output => 'Ieșire';

  @override
  String get now => 'acum';

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
    return '${count}d';
  }

  @override
  String get today => 'Azi';

  @override
  String get tomorrow => 'Mâine';

  @override
  String get yesterday => 'Ieri';

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
  String get mobileConversations => 'Conversații';

  @override
  String get mobileNewConversation => 'Conversație nouă';

  @override
  String get mobileConversationName => 'Nume conversație';

  @override
  String get mobileRename => 'Redenumește';

  @override
  String get mobileManageSpace => 'Gestionează spațiul';

  @override
  String get mobileArchived => 'Arhivat';

  @override
  String get mobileSearchMessages => 'Caută în toate mesajele din acest spațiu';

  @override
  String get mobileSearch => 'Caută';

  @override
  String get mobileNoResults => 'Niciun rezultat';

  @override
  String get mobileReopen => 'Redeschide';

  @override
  String get mobileArchive => 'Arhivează';

  @override
  String get mobileProgress => 'Progres și context';

  @override
  String get mobileReadFailed =>
      'Nu s-a putut marca această conversație ca citită';

  @override
  String get mobileSendFailed =>
      'Mesajul nu a fost trimis. Ciorna ta este încă aici.';

  @override
  String get sentAttachmentUnavailable => 'Atașament indisponibil';

  @override
  String get sentAttachmentLoadFailed => 'Nu s-a putut încărca atașamentul';

  @override
  String get mobileActionFailed => 'Acțiunea a eșuat';

  @override
  String get mobileRemove => 'Elimină';

  @override
  String get mobileLinkedMessage => 'Mesaj asociat';

  @override
  String get mobileOlderMessages => 'Mesaje mai vechi';

  @override
  String get mobileMessageActions => 'Acțiuni pentru mesaj';

  @override
  String get mobileOpenThread => 'Deschide firul';

  @override
  String get mobileCopyLink => 'Copiază linkul';

  @override
  String get mobileStopRun => 'Oprește rularea';

  @override
  String get mobileStopRunConfirm =>
      'Oprești rularea acestui agent? Munca deja finalizată va fi păstrată.';

  @override
  String get mobileControlUnsupported =>
      'Această rulare s-a încheiat sau nu acceptă această comandă.';

  @override
  String get mobilePauseRequested =>
      'Pauză solicitată la sfârșitul următorului pas';

  @override
  String get mobileResumed => 'Rularea a fost reluată';

  @override
  String get mobileStopRequested => 'Oprire solicitată';

  @override
  String get mobileQueuedMessages => 'Mesaje în coadă';

  @override
  String get mobilePauseRun => 'Pauză la următorul pas';

  @override
  String get mobileResumeRun => 'Reia';

  @override
  String get mobileEditQueued => 'Editează mesajul din coadă';

  @override
  String get mobileSteerNow => 'Redirecționează acum';

  @override
  String get mobileMoveUp => 'Mută în sus';

  @override
  String get mobileMoveDown => 'Mută în jos';

  @override
  String get mobileQueueChanged =>
      'Coada s-a schimbat sau această rulare nu acceptă redirecționare în timp real. Reîncarcă și încearcă din nou.';

  @override
  String get mobileActivity => 'Activitate';

  @override
  String get mobilePermissions => 'Permisiuni și audit';

  @override
  String get mobilePlans => 'Planuri';

  @override
  String get mobileGoals => 'Obiective supravegheate';

  @override
  String get mobileCredentials => 'Conexiuni și credențiale';

  @override
  String get mobileWorkspaceUnavailable =>
      'Acest spațiu de lucru nu este disponibil sau nu mai ai acces.';

  @override
  String get mobilePrReviewThreads => 'Fire de revizuire';

  @override
  String get mobilePrThreadsLoadFailed =>
      'Nu s-au putut încărca firele de revizuire';

  @override
  String get mobilePrNoReviewThreads =>
      'Încă nu există fire de revizuire în cod';

  @override
  String get mobilePrCommentPermissionDenied =>
      'Nu ai permisiunea să comentezi în acest depozit.';

  @override
  String get mobilePrPermissionChecking =>
      'Se verifică permisiunile pentru comentarii…';

  @override
  String get mobilePrPermissionLoadFailed =>
      'Nu s-au putut verifica permisiunile. Încearcă din nou pentru a comenta.';

  @override
  String mobilePrThreadLine(String side, String line) {
    return '$side, linia $line';
  }

  @override
  String get mobilePrOriginalSide => 'Original';

  @override
  String get mobilePrSelectCommentLine => 'Alege o linie pentru comentariu';

  @override
  String get mobilePrUpdatedSide => 'Actualizat';

  @override
  String get mobilePrThreadResolved => 'Rezolvat';

  @override
  String get mobilePrReplyHint => 'Scrie un răspuns…';

  @override
  String get mobilePrCommentRequired =>
      'Scrie un comentariu înainte de publicare.';

  @override
  String get mobilePrReply => 'Răspunde';

  @override
  String get mobilePrReopenThread => 'Redeschide firul';

  @override
  String get mobilePrResolveThread => 'Rezolvă firul';

  @override
  String get mobilePrResolvePermissionDenied =>
      'Doar autorul pull request-ului sau cineva cu acces de scriere poate rezolva acest fir.';

  @override
  String mobilePrCommentOnLine(String side, String line) {
    return 'Comentează la $side, linia $line';
  }

  @override
  String get mobilePrInlineCommentHint => 'Scrie un comentariu în cod…';

  @override
  String get mobilePrPostInlineComment => 'Publică comentariul';

  @override
  String get mobilePrCommentUnavailable =>
      'Comentariile în cod nu sunt disponibile pentru acest pull request.';

  @override
  String get mobilePrPatchUnavailable =>
      'Platforma Git nu a furnizat un patch text pentru acest fișier.';

  @override
  String get mobilePrNoPatchForFile =>
      'Patch-ul pentru acest fișier nu este disponibil.';

  @override
  String get mobileTicketNew => 'Tichet nou';

  @override
  String get mobileTicketCreate => 'Creează tichet';

  @override
  String get mobileTicketEdit => 'Editează tichetul';

  @override
  String get mobileTicketTitle => 'Titlu';

  @override
  String get mobileTicketTitleRequired =>
      'Introdu un titlu pentru a salva tichetul.';

  @override
  String get mobileTicketDescription => 'Descriere';

  @override
  String get mobileTicketMarkdownHint => 'Adaugă detalii în Markdown';

  @override
  String get mobileTicketPriority => 'Prioritate';

  @override
  String get mobileTicketPriorityNone => 'Fără prioritate';

  @override
  String get mobileTicketPriorityUrgent => 'Urgent';

  @override
  String get mobileTicketPriorityHigh => 'Ridicat';

  @override
  String get mobileTicketPriorityMedium => 'Mediu';

  @override
  String get mobileTicketPriorityLow => 'Scăzut';

  @override
  String get mobileTicketLabels => 'Etichete';

  @override
  String get mobileTicketLabelsHint => 'O etichetă pe rând';

  @override
  String get mobileTicketLabelsHelp =>
      'Introdu fiecare etichetă pe un rând separat.';

  @override
  String mobileTicketWorkspaceProvider(String provider) {
    return 'Înregistrat în $provider';
  }

  @override
  String get mobileTicketProviderLocal => 'Control Center';

  @override
  String get mobileTicketUnassigned => 'Neasignat';

  @override
  String get mobileTicketAssignedFilter => 'Asignate';

  @override
  String get mobileTicketAgentsLoadFailed => 'Nu s-au putut încărca agenții';

  @override
  String get mobileTicketSearch => 'Caută tichete';

  @override
  String get mobileTicketSearchHint =>
      'Titlu, cheie, descriere, etichetă sau persoană asignată';

  @override
  String get mobileTicketClearSearch => 'Șterge căutarea tichetelor';

  @override
  String get mobileTicketNoMatches => 'Niciun tichet corespunzător';

  @override
  String get mobileTicketAdjustFilters =>
      'Încearcă altă căutare sau schimbă filtrele.';

  @override
  String get mobileTicketClearFilters => 'Șterge filtrele';

  @override
  String get mobileTicketNotFound => 'Tichetul nu a fost găsit';

  @override
  String get mobileTicketNotFoundDescription =>
      'Este posibil ca acest tichet să fi fost șters sau mutat din acest spațiu de lucru.';

  @override
  String get mobileTicketWorkspaceChanged =>
      'Spațiul de lucru s-a schimbat. Revino la cel curent înainte de salvare.';

  @override
  String get mobileTicketOpenLinkedSpace => 'Deschide spațiul asociat';

  @override
  String get mobileTicketReadOnly =>
      'Pentru a modifica tichete, ai nevoie de rolul de membru al spațiului de lucru.';

  @override
  String get permissionTitle => 'Permisiuni';

  @override
  String get permissionWorkspaceFailed =>
      'Nu s-a putut încărca spațiul de lucru';

  @override
  String get permissionNoWorkspace =>
      'Selectează un spațiu de lucru pentru a verifica permisiunile.';

  @override
  String get permissionLoading => 'Se încarcă permisiunile…';

  @override
  String get permissionScopeDescription =>
      'Verifică modul în care este decisă fiecare acțiune la acest nivel. Regulile spațiului de lucru pot fi moștenite de agenți și spații.';

  @override
  String get permissionScope => 'Domeniul politicii';

  @override
  String get permissionWorkspaceScope => 'Spațiu de lucru';

  @override
  String get permissionAgentScope => 'Agent';

  @override
  String get permissionSpaceScope => 'Spațiu';

  @override
  String get permissionAgentContext => 'Agent care acționează în acest spațiu';

  @override
  String get permissionNoAgentContext => 'Niciun agent selectat';

  @override
  String get permissionTargetsFailed =>
      'Nu s-au putut încărca obiectivele domeniului';

  @override
  String get permissionNoTargets =>
      'Nu există obiective disponibile la acest nivel.';

  @override
  String get permissionRoleFailed =>
      'Nu s-a putut confirma rolul tău în spațiul de lucru';

  @override
  String get permissionMemberRequired =>
      'Pentru a vedea regulile politicii, ai nevoie de rolul de membru al spațiului de lucru.';

  @override
  String get permissionRulesFailed =>
      'Nu s-au putut încărca regulile politicii';

  @override
  String get permissionAuditAdminOnly =>
      'Istoricul autorizărilor este disponibil doar administratorilor spațiului de lucru.';

  @override
  String get permissionAllow => 'Permite';

  @override
  String get permissionAsk => 'Întreabă întâi';

  @override
  String get permissionDeny => 'Refuză';

  @override
  String get permissionFileDelete => 'Șterge fișiere';

  @override
  String get permissionFileWriteOutsideWorktree =>
      'Scrie în afara arborelui de lucru';

  @override
  String get permissionGitCommit => 'Creează commituri';

  @override
  String get permissionGitPush => 'Trimite commituri';

  @override
  String get permissionPrCreate => 'Creează pull request-uri';

  @override
  String get permissionPrPublish => 'Actualizează sau unește pull request-uri';

  @override
  String get permissionVendorSyncWrite => 'Scrie sincronizări cu furnizorii';

  @override
  String get permissionNetworkEgress => 'Accesează rețeaua';

  @override
  String get permissionSecretAccess => 'Accesează secrete';

  @override
  String get permissionPackageInstall => 'Instalează pachete';

  @override
  String get permissionProcessSpawn => 'Pornește procese';

  @override
  String get permissionWorkspaceMutation => 'Modifică spațiul de lucru';

  @override
  String get permissionEnclosureControl => 'Controlează mediul izolat';

  @override
  String get permissionChangeFailed => 'Nu s-a putut modifica regula';

  @override
  String get permissionEffectiveDescription =>
      'Valabil la acest nivel fără argumente pentru acțiune. Permisiunile condiționate de mai jos se aplică doar solicitărilor corespunzătoare; serverul ia decizia finală.';

  @override
  String get permissionSpaceAgentNote =>
      'Niciun agent selectat. Regulile specifice agentului nu sunt afișate până când alegi unul mai sus.';

  @override
  String get permissionScopedGrants => 'Reguli la acest nivel';

  @override
  String get permissionModePreset => 'Presetare de mod';

  @override
  String get permissionBuiltInDefault => 'Implicit încorporat';

  @override
  String get permissionRemembered => 'Aprobare temporară';

  @override
  String get permissionSource => 'Sursă';

  @override
  String permissionSetAtThisScope(String source) {
    return '$source · stabilită aici';
  }

  @override
  String permissionInheritedFrom(String source) {
    return '$source · moștenită';
  }

  @override
  String permissionExpiresAt(String date) {
    return 'Expiră la $date';
  }

  @override
  String get permissionSetHere => 'Stabilește o regulă aici';

  @override
  String get permissionConfirmRevoke => 'Confirmă revocarea';

  @override
  String get permissionRevokeRule => 'Revocă regula';

  @override
  String permissionCommandPrefix(String prefix) {
    return 'Prefixul comenzii: $prefix';
  }

  @override
  String get permissionNoExpiry => 'Fără expirare';

  @override
  String get permissionExpired => 'Expirată';

  @override
  String get permissionExplicitRule => 'Regulă explicită';

  @override
  String get permissionEnforcementAdvisory =>
      'Consultativ: regulile „întreabă întâi” sunt înregistrate fără solicitare de aprobare';

  @override
  String get permissionEnforcementSoft =>
      'Aplicare flexibilă: excepțiile necesită autorizare';

  @override
  String get permissionEnforcementHard =>
      'Aplicare strictă: nu se pot face excepții';

  @override
  String permissionPaths(String paths) {
    return 'Căi: $paths';
  }

  @override
  String permissionRefs(String refs) {
    return 'Referințe Git: $refs';
  }

  @override
  String permissionHosts(String hosts) {
    return 'Gazde: $hosts';
  }

  @override
  String permissionCommands(String commands) {
    return 'Comenzi: $commands';
  }

  @override
  String permissionTools(String tools) {
    return 'Instrumente: $tools';
  }

  @override
  String get permissionNotInEffect =>
      'Fără efect cât această acțiune este setată pe Refuză';

  @override
  String permissionMaxCount(String count) {
    return 'Număr maxim: $count';
  }

  @override
  String permissionMaxCents(String cents) {
    return 'Număr maxim de cenți: $cents';
  }

  @override
  String get permissionAuditHeading => 'Istoricul autorizărilor';

  @override
  String get permissionAuditDescription =>
      'Decizii recente înregistrate de server. Doar administratorii pot consulta jurnalul sau verifica lanțul său de hash-uri.';

  @override
  String permissionOnBehalfOf(String user) {
    return 'în numele lui $user';
  }

  @override
  String get permissionPrompted => 'S-a solicitat aprobarea unei persoane';

  @override
  String get permissionVerifyChain => 'Verifică lanțul de audit';

  @override
  String get permissionVerifyFailed => 'Nu s-a putut verifica lanțul de audit';

  @override
  String permissionChainIntact(String count) {
    return 'Lanț intact · $count înregistrări verificate';
  }

  @override
  String permissionChainBroken(String sequence, String reason) {
    return 'Lanț întrerupt la înregistrarea $sequence: $reason';
  }

  @override
  String get permissionAuditEmpty =>
      'Nu există încă decizii de autorizare înregistrate.';

  @override
  String get permissionAuditFailed =>
      'Nu s-a putut încărca istoricul autorizărilor';

  @override
  String get mobilePlansLoadFailed => 'Nu s-au putut încărca planurile';

  @override
  String get mobilePlansEmpty => 'Încă nu există planuri';

  @override
  String get mobilePlansEmptyDescription =>
      'Planurile trimise de agenți vor apărea aici pentru revizuire.';

  @override
  String get mobilePlanTitle => 'Plan';

  @override
  String get mobilePlanMissing =>
      'Acest plan nu mai este disponibil în acest spațiu de lucru.';

  @override
  String mobilePlanStepCount(int count) {
    return '$count pași';
  }

  @override
  String get mobilePlanDraft => 'Ciornă';

  @override
  String get mobilePlanProposed => 'În așteptarea revizuirii';

  @override
  String get mobilePlanApproved => 'Aprobat';

  @override
  String get mobilePlanRejected => 'Respins';

  @override
  String get mobilePlanSuperseded => 'Înlocuit';

  @override
  String get mobilePlanExecuting => 'Se execută';

  @override
  String get mobilePlanSynthesizing => 'Se sintetizează';

  @override
  String get mobilePlanCompleted => 'Finalizat';

  @override
  String get mobilePlanFailed => 'Eșuat';

  @override
  String get mobilePlanCancelled => 'Anulat';

  @override
  String mobilePlanRevision(String revision) {
    return 'Revizia $revision';
  }

  @override
  String get mobilePlanSteps => 'Pași';

  @override
  String get mobilePlanNoSteps => 'Nu au fost trimiși pași pentru acest plan.';

  @override
  String get mobilePlanAssumptions => 'Clarificări';

  @override
  String mobilePlanDependsOn(String keys) {
    return 'Depinde de $keys';
  }

  @override
  String mobilePlanStepCost(String cost) {
    return 'Estimare de până la $cost';
  }

  @override
  String get mobilePlanSelect => 'Selectează';

  @override
  String get mobilePlanSelected => 'Selectat';

  @override
  String get mobilePlanEstimate => 'Estimează costul';

  @override
  String get mobilePlanEstimateRequired =>
      'Estimează planul înainte de a aproba execuția.';

  @override
  String mobilePlanEstimatedCost(String low, String high) {
    return 'Cost estimat: $low–$high';
  }

  @override
  String get mobilePlanCostUnknown => 'indisponibil';

  @override
  String get mobilePlanNoHardCap => 'fără limită strictă';

  @override
  String get mobilePlanExceedsBudget =>
      'Estimarea depășește bugetul configurat. Verifică înainte de aprobare.';

  @override
  String get mobilePlanPartialEstimate =>
      'Această estimare acoperă întregul plan; pașii selectați pot costa mai puțin.';

  @override
  String get mobilePlanConfirmAll => 'Pornești întregul plan?';

  @override
  String get mobilePlanConfirmSelected => 'Pornești pașii selectați?';

  @override
  String mobilePlanExecutionConfirmation(String cost, String cap) {
    return 'Aprobarea pornește execuția și poate genera costuri. Costul maxim estimat: $cost. Limita bugetului: $cap.';
  }

  @override
  String get mobilePlanApproveAll => 'Aprobă tot și pornește';

  @override
  String get mobilePlanApproveSelected => 'Aprobă selecția și pornește';

  @override
  String get mobilePlanWiden => 'Aprobă pași suplimentari';

  @override
  String mobilePlanWidenConfirm(String count, String cap) {
    return 'Permiți executarea a încă $count pași? Aceștia pot genera costuri. Limita actuală a costului execuției: $cap.';
  }

  @override
  String get mobilePlanChanged =>
      'Planul s-a schimbat în timpul revizuirii. Redeschide cea mai recentă revizie și estimeaz-o din nou.';

  @override
  String get mobilePlanReject => 'Respinge planul';

  @override
  String get mobilePlanRejectConfirm =>
      'Respingi acest plan? Nu va fi executat.';

  @override
  String get mobilePlanStop => 'Oprește execuția';

  @override
  String get mobilePlanStopConfirm =>
      'Oprești execuția planului? Munca deja finalizată nu va fi anulată.';

  @override
  String mobilePlanRunId(String runId) {
    return 'Rulare de execuție: $runId';
  }

  @override
  String get mobilePlanExecutionPending =>
      'Aprobarea a fost acceptată. Se așteaptă înregistrarea execuției…';

  @override
  String mobilePlanProgress(String completed, String total) {
    return 'Pași de execuție finalizați: $completed din $total';
  }

  @override
  String get mobilePlanOpenConversation => 'Deschide conversația';

  @override
  String get mobileGoalsTitle => 'Obiective supravegheate';

  @override
  String get mobileGoalsLoadFailed =>
      'Nu s-au putut încărca obiectivele supravegheate';

  @override
  String get mobileGoalsEmpty => 'Încă nu există obiective supravegheate';

  @override
  String get mobileGoalsEmptyDescription =>
      'Începe unul într-un spațiu sau trimite /goal într-o conversație.';

  @override
  String get mobileGoalMissing =>
      'Acest obiectiv nu mai este disponibil în acest spațiu de lucru.';

  @override
  String get mobileGoalActive => 'Activ';

  @override
  String get mobileGoalPaused => 'Pauză';

  @override
  String get mobileGoalCompleted => 'Finalizat';

  @override
  String get mobileGoalFailed => 'Eșuat';

  @override
  String get mobileGoalCancelled => 'Anulat';

  @override
  String get mobileGoalBudgetExhausted => 'Buget atins';

  @override
  String mobileGoalFailures(String count) {
    return 'Rulări eșuate consecutiv: $count';
  }

  @override
  String get mobileGoalFailedDescription =>
      'Supraveghetorul s-a oprit după eșecuri repetate. Verifică detaliile în conversație.';

  @override
  String get mobileGoalPause => 'Pune obiectivul în pauză';

  @override
  String get mobileGoalResume => 'Reia obiectivul';

  @override
  String get mobileGoalStop => 'Anulează obiectivul';

  @override
  String get mobileGoalStopConfirm =>
      'Anulezi definitiv acest obiectiv supravegheat? Nu va putea fi reluat.';

  @override
  String get mobileGoalRaiseBudget => 'Mărește bugetul și reia';

  @override
  String mobileGoalRaiseTo(String amount) {
    return 'Mărește bugetul la $amount și reia';
  }

  @override
  String mobileGoalRaiseConfirm(String oldCap, String newCap) {
    return 'Mărești limita de cost pentru acest obiectiv de la $oldCap la $newCap și reiei cheltuielile?';
  }

  @override
  String get mobileGoalOpenConversation => 'Deschide conversația obiectivului';

  @override
  String get mobileGoalCreate => 'Pornește un obiectiv supravegheat';

  @override
  String get mobileGoalChooseSpace => 'Rulează în spațiul';

  @override
  String get mobileGoalNoSpaces =>
      'Creează un spațiu înainte de a porni un obiectiv.';

  @override
  String get mobileGoalChooseAgent => 'Rulează cu agentul';

  @override
  String get mobileGoalNoAgents =>
      'Adaugă un agent activ înainte de a porni un obiectiv.';

  @override
  String mobileGoalSelectedAgent(String name) {
    return '$name selectat';
  }

  @override
  String get mobileGoalObjectiveHint =>
      'Ce rezultat ar trebui să urmărească agentul?';

  @override
  String get mobileGoalBudgetUsd => 'Limită de cost (USD)';

  @override
  String get mobileGoalCreateInvalid =>
      'Alege un spațiu și un agent, introdu un obiectiv și stabilește o limită de cost pozitivă în USD.';

  @override
  String mobileGoalCreateConfirm(String cap) {
    return 'Pornești un obiectiv supravegheat cu un cost maxim de $cap? Agentul poate începe imediat.';
  }

  @override
  String get mobileGoalUnavailable =>
      'Conexiunea cu serverul nu este pregătită. Încearcă din nou după reconectare.';

  @override
  String get mobileGoalConversationMissing =>
      'Conversația selectată nu mai este disponibilă în acest spațiu de lucru.';

  @override
  String get mobileGoalCreateSent =>
      'Obiectiv pornit. Starea supraveghetorului va apărea în această listă.';

  @override
  String get mobileGoalStartRefused =>
      'Nu a pornit nicio rulare pentru obiectiv. Verifică motivul supraveghetorului în conversație.';

  @override
  String mobileGoalSelectedSpace(String name) {
    return '$name selectat';
  }

  @override
  String get requestUnavailable =>
      'Această solicitare nu mai este disponibilă în spațiul de lucru activ.';

  @override
  String get requestAlreadyResolved =>
      'Această solicitare a fost deja rezolvată.';

  @override
  String get inboxCredentialsBlocked => 'Credențiale care blochează rulări';

  @override
  String get inboxSyncFailures => 'Sincronizări eșuate cu furnizorii';

  @override
  String get inboxConfigureCredentials => 'Configurează credențialele';

  @override
  String get openTicket => 'Deschide tichetul';

  @override
  String get activityTitle => 'Activitate';

  @override
  String get activityClearAll => 'Șterge activitatea';

  @override
  String get activityClearConfirm =>
      'Aceasta ascunde toată activitatea înregistrată până acum pentru tine pe toate dispozitivele. Activitatea nouă va apărea în continuare.';

  @override
  String get activityMarkAllRead => 'Marchează totul ca citit';

  @override
  String get activityMarkAllConfirm =>
      'Marchezi ca citite toate elementele de activitate din acest spațiu de lucru pe toate dispozitivele tale?';

  @override
  String get activityMarkRead => 'Marchează ca citit';

  @override
  String get activityMarkUnread => 'Marchează ca necitit';

  @override
  String get activityDismiss => 'Închide';

  @override
  String get activityResolved => 'Rezolvat';

  @override
  String get activityOpen => 'Deschis';

  @override
  String get activityEmpty => 'Nicio activitate încă';

  @override
  String get activityLoadFailed => 'Nu s-a putut încărca activitatea';

  @override
  String get activityAgentWaiting => 'Agentul așteaptă informații';

  @override
  String get activityAgentBlocked => 'Acțiunea agentului este blocată';

  @override
  String get activityMessage => 'Mesaj nou';

  @override
  String get activityPullRequest => 'Actualizare pull request';

  @override
  String get activityRig => 'Actualizare mediu izolat';

  @override
  String get activityEvent => 'Actualizează';

  @override
  String get activityPrReady => 'Pull request gata de fuzionare';

  @override
  String get activityPrBlocked => 'Fuzionarea pull request-ului este blocată';

  @override
  String get activityPrApproved => 'Pull request aprobat';

  @override
  String get activityPrChanges => 'Modificări cerute';

  @override
  String get activityPrChecksFailed =>
      'Verificările pull request-ului au eșuat';

  @override
  String get activityPrChecksRecovered =>
      'Verificările pull request-ului au fost restabilite';

  @override
  String get activityPrComment => 'Comentariu la pull request';

  @override
  String get activityPrPublished => 'Pull request publicat';

  @override
  String get activityPrMerged => 'Pull request fuzionat';

  @override
  String get activityPrMentioned => 'Menționat într-un pull request';

  @override
  String get activityPrReviewRequested => 'Revizuire solicitată';

  @override
  String get activityPrReviewStale => 'Revizuirea trebuie actualizată';

  @override
  String get activityTicketAssigned => 'Tichet asignat';

  @override
  String get activityTicketChanged => 'Starea tichetului s-a schimbat';

  @override
  String get activityMeetingSoon => 'Întâlnirea începe curând';

  @override
  String get activityCalendarExpired => 'Conexiunea la calendar a expirat';

  @override
  String get activityRigControl => 'Controlul mediului izolat s-a schimbat';

  @override
  String get activityRigClosed => 'Mediul izolat s-a oprit';

  @override
  String get mobileSpacesSearch => 'Caută spații';

  @override
  String get mobileSpacesArchived => 'Arhivat';

  @override
  String get mobileSpacesActive => 'Activ';

  @override
  String get mobileSpacesNew => 'Spațiu nou';

  @override
  String get mobileSpacesManage => 'Gestionează spațiul';

  @override
  String get mobileSpacesName => 'Nume spațiu';

  @override
  String get mobileSpacesAgents => 'Agenți';

  @override
  String get mobileSpacesMembers => 'Persoane';

  @override
  String get mobileSpacesRepos => 'Depozite';

  @override
  String get mobileSpacesAllRepos => 'Toate depozitele asociate';

  @override
  String get mobileSpacesNoRepos => 'Niciun depozit';

  @override
  String get mobileSpacesBaseBranch => 'Ramură de bază (opțional)';

  @override
  String get mobileSpacesDefaultBranch => 'Ramură implicită';

  @override
  String get mobileSpacesMode => 'Mod';

  @override
  String get mobileSpacesModeChat => 'Chat';

  @override
  String get mobileSpacesModeReview => 'Revizuire (doar citire)';

  @override
  String get mobileSpacesModePlan => 'Planificare (doar citire)';

  @override
  String get mobileSpacesModeOrchestrate => 'Orchestrează';

  @override
  String get mobileSpacesAutonomy => 'Suprascrierea autonomiei';

  @override
  String get mobileSpacesAutonomyInherited => 'Moștenit';

  @override
  String get mobileSpacesAutonomyPropose => 'Doar propune';

  @override
  String get mobileSpacesAutonomyApproval => 'Acționează cu aprobare';

  @override
  String get mobileSpacesAutonomyFreely => 'Acționează liber';

  @override
  String get mobileSpacesAutonomyNotice =>
      'O suprascriere nu poate evita cererile de aprobare sau refuzurile politicii de acțiuni. Doar administratorii spațiului de lucru o pot modifica.';

  @override
  String get mobileSpacesArchive => 'Arhivează spațiul';

  @override
  String get mobileSpacesReopen => 'Redeschide spațiul';

  @override
  String get mobileSpacesSave => 'Salvează modificările';

  @override
  String get mobileSpacesCreate => 'Creează spațiul';

  @override
  String get mobileSpacesOperationFailed => 'Nu s-a putut actualiza spațiul';

  @override
  String get mobileSpacesMissing =>
      'Spațiul nu a fost găsit în acest spațiu de lucru';

  @override
  String get mobileSpacesEmptyName => 'Introdu numele spațiului';

  @override
  String get mobileSpacesNoMatches => 'Niciun spațiu corespunzător';

  @override
  String get mobileSpacesUnread => 'Răspuns necitit de la agent';

  @override
  String get mobileSpacesNeedsInput => 'Așteaptă răspunsul tău';

  @override
  String get mobileSpacesRunning => 'Agentul rulează';

  @override
  String get mobileSpacesNoAgents => 'Niciun agent în acest spațiu de lucru';

  @override
  String get mobileSpacesNoMembers => 'Niciun alt membru în spațiul de lucru';

  @override
  String get mobileSpacesRepoError => 'Nu s-au putut încărca depozitele';

  @override
  String get mobileSpacesRetry => 'Reîncearcă';

  @override
  String get mobileSpacesBranchUnavailable =>
      'Alege sau introdu o ramură de bază când creezi un spațiu; ramurile de bază ale spațiilor existente nu pot fi schimbate.';

  @override
  String get mobileSpacesArchivedEmpty => 'Niciun spațiu arhivat';

  @override
  String get mobileSpacesAllRepoWarning =>
      'Depozitele asociate ulterior spațiului de lucru vor fi incluse și în acest spațiu.';

  @override
  String get mobileSpacesCreatedRetry =>
      'Spațiul a fost creat. Încearcă din nou să adaugi persoane sau deschide pagina lui de gestionare.';

  @override
  String get progressTitle => 'Progres';

  @override
  String get progressConversation => 'Conversație';

  @override
  String get progressLoadFailed => 'Nu s-a putut încărca progresul';

  @override
  String get progressUnavailable => 'Conversație indisponibilă';

  @override
  String get progressUnavailableDescription =>
      'Această conversație nu se află în spațiul de lucru și în spațiul activ. Revino în spațiul ei pentru a continua.';

  @override
  String get progressSaveFailed => 'Nu s-a putut actualiza progresul';

  @override
  String get progressGoal => 'Obiectiv';

  @override
  String get progressNoGoal => 'Niciun obiectiv de lucru stabilit';

  @override
  String get progressSetGoal => 'Setează obiectivul';

  @override
  String get progressEditGoal => 'Editează obiectivul';

  @override
  String get progressClearGoal => 'Golește obiectivul';

  @override
  String get progressGoalRequired => 'Introdu un obiectiv înainte de salvare.';

  @override
  String get progressTodos => 'Sarcini';

  @override
  String get transcriptToolTodos => 'Sarcini';

  @override
  String get transcriptToolSearchMemory => 'Caută în memorie';

  @override
  String get transcriptToolRenderMedia => 'Afișează conținutul media';

  @override
  String get progressNoTodos => 'Încă nu există sarcini';

  @override
  String get progressNewTodo => 'Sarcină nouă';

  @override
  String get progressAddTodo => 'Adaugă sarcina';

  @override
  String get progressEditTodo => 'Editează sarcina';

  @override
  String get progressTodoRequired => 'Introdu o sarcină înainte de salvare.';

  @override
  String get progressTodoNoLongerExists =>
      'Această sarcină a fost eliminată. Reîncarcă lista și încearcă din nou.';

  @override
  String get progressWorkspaceChanged =>
      'Spațiul de lucru activ s-a schimbat. Revino la această conversație și încearcă din nou.';

  @override
  String progressRemoveTodo(String name) {
    return 'Elimină sarcina $name';
  }

  @override
  String get progressPending => 'În așteptare';

  @override
  String get progressInProgress => 'În curs';

  @override
  String get progressCompleted => 'Finalizat';

  @override
  String get progressMoveUp => 'Mută sarcina în sus';

  @override
  String get progressMoveDown => 'Mută sarcina în jos';

  @override
  String get progressRunTree => 'Rulările agenților';

  @override
  String get progressNoRuns => 'Încă nu există rulări în această conversație';

  @override
  String get progressRunning => 'În rulare';

  @override
  String get progressFailed => 'Eșuat';

  @override
  String get progressUnknown => 'Necunoscut';

  @override
  String get progressHealthy => 'Activ';

  @override
  String get progressBlocked => 'Blocat';

  @override
  String get progressLooping => 'În ciclu';

  @override
  String get progressStalled => 'Blocat';

  @override
  String get progressDead => 'Oprit pe neașteptate';

  @override
  String get progressQuiet => 'Încă nu există rezultate';

  @override
  String get progressCostReported => 'Cost raportat de furnizor';

  @override
  String get progressCostNotional =>
      'Preț de listă orientativ pentru abonament; nu este o factură';

  @override
  String get progressCostMixed => 'Surse de cost combinate';

  @override
  String get progressCostEstimated => 'Cost estimat';

  @override
  String progressDurationSeconds(String seconds) {
    return '$seconds s';
  }

  @override
  String progressRunDetails(String model, String duration, String cost) {
    return 'Model: $model · Durată: $duration · Cost: $cost';
  }

  @override
  String progressStartedAt(String time) {
    return 'Pornit $time';
  }

  @override
  String progressLiveness(String state) {
    return 'Stare: $state';
  }

  @override
  String progressRunTokens(String input, String output) {
    return 'Intrare: $input · Ieșire: $output tokenuri';
  }

  @override
  String get progressOutputPreviewLimited =>
      'Se afișează doar primele 6.000 de caractere din rezultatul structurat.';

  @override
  String progressRetryOf(String runId) {
    return 'Reîncercare a rulării $runId';
  }

  @override
  String get progressContext => 'Context și limite';

  @override
  String get progressNoAgent => 'Niciun agent de inspectat';

  @override
  String progressContextReading(String used, String window) {
    return '$used / $window tokenuri';
  }

  @override
  String get progressMeasured =>
      'Context raportat de furnizor la cel mai recent apel';

  @override
  String get progressEstimated =>
      'Estimat din conversația stocată și contextul persistent';

  @override
  String get progressContextUnknown =>
      'Utilizarea contextului nu a fost încă raportată';

  @override
  String progressContextPercent(String percent) {
    return '$percent% din fereastra de context';
  }

  @override
  String progressMonthlyBudget(String amount) {
    return 'Limita lunară configurată pentru agent: $amount';
  }

  @override
  String progressConversationTokens(String tokens) {
    return 'Conversație activă stocată: aproximativ $tokens tokenuri';
  }

  @override
  String progressInspectionFor(String agent, String model) {
    return 'Context persistent pentru $agent · $model';
  }

  @override
  String get progressContextSystem => 'Prompt de sistem';

  @override
  String get progressContextRules => 'Reguli';

  @override
  String get progressContextSkills => 'Abilități';

  @override
  String get progressContextTools => 'Definiții de instrumente';

  @override
  String get progressContextMcp => 'Instrumente MCP';

  @override
  String get progressContextDeferred => 'Instrumente amânate';

  @override
  String get progressContextSubagents => 'Subagenți';

  @override
  String get progressContextRunner => 'Executor extern';

  @override
  String get progressContextMemory => 'Memorie';

  @override
  String get progressContextHistory => 'Istoricul conversației';

  @override
  String progressContextSegment(String label, String tokens) {
    return '$label · $tokens tokenuri';
  }

  @override
  String progressContextPart(String title, String tokens) {
    return '$title · $tokens tokenuri';
  }

  @override
  String get progressOutputs => 'Rezultate recente';

  @override
  String get progressNoOutputs => 'Niciun rezultat recent al agenților';

  @override
  String get progressStructuredOutputsAbove =>
      'Rezultatele structurate ale rulărilor sunt afișate mai sus, la rulările agenților.';

  @override
  String get progressRecentOutputsOnly =>
      'Se afișează doar mesajele recente. Deschide conversația pentru activitatea mai veche.';

  @override
  String get progressPlan => 'Plan';

  @override
  String get progressArtifact => 'Artifact';

  @override
  String get progressResult => 'Rezultat';

  @override
  String get progressHideArtifact => 'Ascunde artefactul';

  @override
  String get progressReadArtifact => 'Citește artefactul';

  @override
  String get progressArtifactUnavailable => 'Artefactul nu mai este disponibil';

  @override
  String get progressArtifactPreviewLimited =>
      'Se afișează o previzualizare limitată a acestui artefact.';

  @override
  String get progressDiagramSource => 'Sursa diagramei';

  @override
  String progressOpenAttachment(String name) {
    return 'Deschide $name';
  }

  @override
  String get progressOpenPlan => 'Deschide planul';

  @override
  String progressOpenDiff(String label) {
    return 'Revizuiește fișierele modificate: $label';
  }

  @override
  String get progressViewMessage => 'Vezi mesajul';

  @override
  String get pushTitle => 'Notificări în fundal';

  @override
  String get pushIntro =>
      'Primești o alertă privată când ceva necesită atenția ta, chiar dacă aplicația este închisă. Detaliile rămân în conexiunea ta criptată.';

  @override
  String get pushLoading => 'Se verifică setările notificărilor…';

  @override
  String get pushError =>
      'Nu s-au putut actualiza notificările. Verifică conexiunea și încearcă din nou.';

  @override
  String get pushEnable => 'Activează notificările';

  @override
  String get pushDisable => 'Dezactivează notificările';

  @override
  String get pushQuiet => 'Întrerupe alertele pe acest dispozitiv';

  @override
  String get pushCategories => 'Notifică-mă despre';

  @override
  String get pushCategoryAgents => 'Agenți';

  @override
  String get pushCategoryMessages => 'Mesaje';

  @override
  String get pushCategoryPullRequests => 'Pull request-uri';

  @override
  String get pushCategoryTickets => 'Tichete';

  @override
  String get pushCategoryCalendar => 'Calendar';

  @override
  String get pushCategoryMachines => 'Mașini';

  @override
  String get pushSecureOrigin => 'Notificările necesită HTTPS.';

  @override
  String get pushInstallIos =>
      'Pe iPhone sau iPad, adaugă această aplicație pe ecranul principal și deschide-o de acolo pentru a activa notificările.';

  @override
  String get pushUnsupported =>
      'Acest browser nu acceptă notificări în fundal.';

  @override
  String get pushDenied =>
      'Browserul raportează că notificările sunt blocate. Verifică permisiunea acestui site și setările de notificări ale browserului sau dispozitivului, apoi reîmprospătează pagina.';

  @override
  String get pushOsHint =>
      'Browserul are nevoie și de permisiunea de a afișa notificări în setările de sistem ale dispozitivului.';

  @override
  String get pushServiceUnavailable =>
      'Serviciul push al browserului a refuzat abonarea. Unele browsere, precum Brave, îl dezactivează implicit: căutați o opțiune pentru mesaje push în setările de confidențialitate ale browserului, apoi încercați din nou.';

  @override
  String get pushWorkerUnavailable =>
      'Serviciul de notificări nu a putut porni în acest browser. Reîncărcați pagina și încercați din nou.';

  @override
  String get pushResubscribe => 'Reconectează notificările';

  @override
  String get pushStatusEnabled =>
      'Notificările sunt activate pe acest dispozitiv.';

  @override
  String get pushStatusDisabled =>
      'Notificările sunt dezactivate pe acest dispozitiv.';

  @override
  String get credentialsTitle => 'Conexiuni și credențiale';

  @override
  String get credentialsIntro =>
      'Conectează conturile folosite de rulările și integrările tale. Secretele sunt stocate pe serverul tău, nu pe acest telefon.';

  @override
  String get credentialsModelProviders => 'Provideri de modele';

  @override
  String get credentialsOwnerOnly =>
      'Doar proprietarul serverului poate adăuga, autentifica sau elimina credențialele furnizorilor de modele. Aceste chei sunt partajate între spațiile de lucru.';

  @override
  String get credentialsContactOwner =>
      'Cere proprietarului serverului să conecteze furnizorul necesar rulării blocate.';

  @override
  String get credentialsClaudeCode => 'Claude Code';

  @override
  String get credentialsClaudeHostOnly =>
      'Claude Code se autentifică prin CLI pe gazdă. Cere proprietarului serverului să finalizeze sau să reînnoiască autentificarea contului în terminalul gazdei; acest telefon nu o poate face.';

  @override
  String get credentialsYourForgeAccounts =>
      'Conturile tale de pe platformele Git';

  @override
  String get credentialsYourTicketingAccount => 'Contul tău pentru tichete';

  @override
  String get credentialsLocalTicketsNoLogin =>
      'Tichetele locale nu necesită autentificare. Conectează Linear aici dacă spațiul tău de lucru folosește Linear.';

  @override
  String get credentialsMembershipRequired =>
      'Alătură-te unui spațiu de lucru pentru a gestiona credențialele pentru platformele Git sau tichete. Cere acces unui administrator al spațiului de lucru.';

  @override
  String get credentialsSwitchWorkspace =>
      'Acest link duce la alt spațiu de lucru. Comută la acel spațiu de lucru înainte de a modifica credențialele.';

  @override
  String get credentialsReturnToInbox =>
      'Revino la Mesaje primite pentru a reîncerca o rulare blocată după conectarea credențialei. Gazda verifică automat și rulările puse în așteptare.';

  @override
  String get credentialsLoadFailed =>
      'Nu s-au putut încărca conexiunile. Verifică legătura cu serverul și încearcă din nou.';

  @override
  String get credentialsOperationFailed =>
      'Nu s-a putut modifica această conexiune. Verifică legătura cu serverul, accesul și credențiala, apoi încearcă din nou.';

  @override
  String get credentialsConnected => 'Conectat';

  @override
  String get credentialsNotConnected => 'Neconectat';

  @override
  String credentialsSignedInAs(String username) {
    return 'Autentificat ca $username';
  }

  @override
  String get credentialsAccount => 'Cont conectat';

  @override
  String get credentialsStoredKey => 'Cheie stocată';

  @override
  String get credentialsActive => 'Activ';

  @override
  String get credentialsRemove => 'Elimină';

  @override
  String get credentialsRemoveConfirm =>
      'Elimini credențiala salvată? Poate fi necesar să te autentifici din nou.';

  @override
  String get credentialsApiKey => 'Cheie API';

  @override
  String get credentialsApiKeyHint => 'Lipește o cheie API a furnizorului';

  @override
  String get credentialsBrowserLogin => 'Autentifică-te în browser';

  @override
  String get credentialsSignInAgain => 'Autentifică-te din nou';

  @override
  String get credentialsWaitingForLogin =>
      'Se așteaptă autorizarea în browser…';

  @override
  String get credentialsConnectCodePrompt => 'Cod de confirmare';

  @override
  String get credentialsConnectCodeMalformed =>
      'Nu pare un cod de autentificare. Codurile au 8 litere și cifre.';

  @override
  String get credentialsSignInInvalidCode =>
      'Codul nu corespunde acestei autentificări. Verifică-l și încearcă din nou.';

  @override
  String get credentialsSignInTooManyCodes =>
      'Prea multe coduri greșite. Pornește din nou autentificarea.';

  @override
  String get credentialsSignInRetryLater =>
      'Serviciul de autentificare nu răspunde acum. Așteaptă un minut, apoi încearcă din nou.';

  @override
  String get credentialsSignInRefused =>
      'Autentificarea a fost refuzată. Pornește-o din nou și aprobă toate permisiunile cerute.';

  @override
  String get credentialsSignInNotSaved =>
      'Autentificarea a reușit, dar serverul nu a putut-o salva. Încearcă din nou.';

  @override
  String credentialsSignInUnavailable(String provider) {
    return 'Autentificarea în $provider nu este încă configurată pe acest server.';
  }

  @override
  String get credentialsSignInPhoneUnreachable =>
      'Adresa de revenire pentru autentificare a acestui server nu poate fi accesată în siguranță de pe telefon. Conectează-te din aplicația desktop sau cere proprietarului serverului să configureze o adresă HTTPS publică.';

  @override
  String get credentialsLoginTimedOut =>
      'Autentificarea a expirat. Începe o nouă încercare.';

  @override
  String get credentialsCopyCode => 'Copiază codul';

  @override
  String get credentialsDeviceCodeHint =>
      'Confirmă acest cod pe pagina furnizorului. Păstrează acest ecran deschis cât timp serverul finalizează autentificarea.';

  @override
  String get credentialsPasteRedirect =>
      'Cod de autorizare sau URL de redirecționare';

  @override
  String get credentialsPasteRedirectHint =>
      'Lipește codul sau URL-ul complet de redirecționare de la furnizor';

  @override
  String get credentialsCompleteLogin => 'Finalizează autentificarea';

  @override
  String get credentialsUpdateToken => 'Actualizează tokenul';

  @override
  String get credentialsAddToken => 'Adaugă token';

  @override
  String get credentialsPersonalToken => 'Token de acces personal';

  @override
  String get credentialsPersonalTokenHint =>
      'Lipește un token de acces personal';

  @override
  String get credentialsStopWatching => 'Oprește monitorizarea';

  @override
  String get transcriptClaudeSignInExpiredTitle =>
      'Autentificarea Claude Code a expirat';

  @override
  String get transcriptClaudeSignInExpiredBody =>
      'Rularea s-a oprit deoarece contul ei nu se mai autentifică. Conectează-te din nou, apoi reîncearcă tura.';

  @override
  String get transcriptSignInExpiredTitle =>
      'Autentificarea furnizorului a expirat';

  @override
  String get transcriptSignInExpiredBody =>
      'Rularea s-a oprit deoarece datele de acces ale furnizorului nu mai funcționează. Reconectează-l în Setări → Furnizori, apoi reîncearcă tura.';

  @override
  String get permissionHostExecution => 'Rulează comenzi pe gazdă';

  @override
  String credentialsSignInLapsed(String provider) {
    return 'Autentificarea ta în $provider a expirat. Autentifică-te din nou.';
  }

  @override
  String get credentialsSignInPaused =>
      'În pauză: serviciul de autentificare al acestui spațiu de lucru s-a schimbat. Funcționează din nou când serviciul revine.';

  @override
  String credentialsProviderUnreachable(String provider) {
    return '$provider nu poate fi contactat acum. Se reîncearcă.';
  }

  @override
  String get credentialsScopeWorkspace => 'Doar acest spațiu de lucru';

  @override
  String get credentialsScopeAllWorkspaces => 'Toate spațiile de lucru';

  @override
  String get credentialsRemoveConfirmWorkspace =>
      'Elimini datele de autentificare salvate din acest spațiu de lucru? Celelalte și le păstrează pe ale lor.';

  @override
  String get credentialsRemoveConfirmAllWorkspaces =>
      'Elimini datele de autentificare salvate din toate spațiile de lucru care le folosesc?';

  @override
  String get credentialsSignInServerRestarted =>
      'Serverul a repornit. Începe din nou autentificarea.';

  @override
  String repoAccessInstallApp(String owner, String names) {
    return 'Instalează GitHub App pe $owner ca automatizarea să ajungă la $names. Atinge pentru a deschide GitHub.';
  }

  @override
  String repoAccessAskAdminInstall(String owner, String names) {
    return 'GitHub App nu este instalată pe $owner, așa că automatizarea nu ajunge la $names. Cere unui administrator al spațiului de lucru să o instaleze.';
  }

  @override
  String repoAccessAddToApp(String names) {
    return 'Adaugă $names la depozitele GitHub App. Atinge pentru a deschide GitHub.';
  }

  @override
  String repoAccessAskAdminAdd(String names) {
    return 'GitHub App încă nu vede $names. Cere unui administrator al spațiului de lucru să le adauge la depozitele ei.';
  }

  @override
  String repoAccessSuspended(String names) {
    return 'Instalarea GitHub App este suspendată. Automatizarea pentru $names este în pauză până când un proprietar al contului reia instalarea pe GitHub.';
  }

  @override
  String repoAccessOwnerCannotSee(String names) {
    return 'Persoana responsabilă de automatizarea acestui spațiu de lucru nu mai vede $names, așa că acolo nu rulează nimic în numele ei.';
  }

  @override
  String repoAccessOwnerNotSignedIn(String names) {
    return 'Persoana responsabilă de automatizarea acestui spațiu de lucru nu este autentificată în forge, așa că automatizarea pentru $names așteaptă până se autentifică.';
  }

  @override
  String repoAccessRetrying(String names) {
    return 'Accesul la $names nu a putut fi verificat. Se reîncearcă.';
  }

  @override
  String hiddenReposSignIn(int count, String forge) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Autentifică-te în $forge ca să vezi pull request-urile din alte depozite: $count',
      one:
          'Autentifică-te în $forge ca să vezi pull request-urile din încă 1 depozit',
    );
    return '$_temp0';
  }

  @override
  String hiddenReposNoForgeAccess(int count, String forge) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Depozite ascunse pentru că contul tău $forge nu le vede: $count',
      one: '1 depozit este ascuns pentru că contul tău $forge nu îl vede',
    );
    return '$_temp0';
  }

  @override
  String hiddenReposNoGrant(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Depozite ascunse la care nu ai acces în acest spațiu de lucru: $count',
      one:
          '1 depozit este ascuns pentru că nu ai acces la el în acest spațiu de lucru',
    );
    return '$_temp0';
  }

  @override
  String hiddenReposChecking(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Se verifică accesul tău la alte depozite: $count…',
      one: 'Se verifică accesul tău la încă 1 depozit…',
    );
    return '$_temp0';
  }

  @override
  String get credentialsAtlassianEmail => 'E-mailul contului Atlassian';

  @override
  String get credentialsAtlassianEmailInvalid =>
      'Introdu adresa de e-mail a contului tău Atlassian.';

  @override
  String get credentialsBitbucketApiToken => 'Token API';

  @override
  String repoAccessAutomationTokenMissing(String names) {
    return 'Niciun token de automatizare nu poate citi $names, așa că munca din fundal de acolo este în pauză. Un admin poate adăuga unul în Setări → Depozite.';
  }

  @override
  String get credentialsSignInConfirmInBrowser =>
      'Confirmă în browser, apoi introdu codul afișat.';

  @override
  String get credentialsSignInAccountAlreadyBound =>
      'Acest cont este deja conectat la altă persoană de pe acest server. Autentifică-te cu alt cont.';

  @override
  String credentialsTokenUnreachable(String provider) {
    return '$provider nu a putut fi contactat pentru a verifica acest token. Încearcă din nou peste puțin.';
  }

  @override
  String credentialsTokenRejected(String provider) {
    return '$provider nu acceptă acest token. Verifică dacă l-ai copiat complet și dacă nu a fost revocat.';
  }

  @override
  String credentialsTokenWrongKind(String provider) {
    return 'Acesta nu este un token personal. Lipește un token de acces personal din contul tău $provider, nu un token de proiect, grup, spațiu de lucru sau bot.';
  }

  @override
  String credentialsTokenNarrowScope(String scope) {
    return 'Acestui token îi lipsește scope-ul $scope, necesar pentru revizuire și comentarii. Creează unul care îl are.';
  }

  @override
  String get credentialsTokenExpired =>
      'Acest token a expirat. Creează unul nou și lipește-l aici.';

  @override
  String get credentialsSignInRateLimited =>
      'Prea multe cereri acum. Așteaptă puțin, apoi încearcă din nou.';

  @override
  String get credentialsSignInCancelled =>
      'Autentificarea a fost anulată sau refuzată. Pornește-o din nou când ești gata.';

  @override
  String get credentialsSignInNoLongerOpen =>
      'Această autentificare nu mai este deschisă: a fost anulată, folosită sau înlocuită. Pornește-o din nou.';

  @override
  String get noWorkspacesYetHint =>
      'Un administrator al spațiului de lucru trebuie să te invite, sau proprietarul serverului poate crea un spațiu de lucru pentru tine.';

  @override
  String repoAccessReplaced(String repos, String forge) {
    return '$repos indică acum către un alt depozit de pe $forge. Reconectează-l din aplicația desktop sau web ca să-l poți folosi în continuare.';
  }

  @override
  String repoAccessAskAdminRelink(String repos, String forge) {
    return '$repos indică acum către un alt depozit de pe $forge. Un administrator al spațiului de lucru trebuie să îl reconecteze înainte de a putea fi folosit din nou.';
  }

  @override
  String get runSandboxUnavailableTitle =>
      'Agenții au nevoie de un sandbox pe acest server';

  @override
  String get runSandboxUnavailable =>
      'Acest server nu are sandbox, deci doar proprietarul lui poate rula aici agenți. Proprietarul poate instala sandbox-ul sau poate dezactiva sandboxing-ul pentru toată lumea.';

  @override
  String get scriptToolCalls => 'Apeluri de instrumente';

  @override
  String scriptCallCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count de apeluri',
      few: '$count apeluri',
      one: '1 apel',
    );
    return '$_temp0';
  }

  @override
  String scriptCallsRunning(int count) {
    return '$count în rulare';
  }

  @override
  String scriptCallsOk(int count) {
    return '$count reușite';
  }

  @override
  String scriptCallsFailed(int count) {
    return '$count eșuate';
  }

  @override
  String scriptCallsDenied(int count) {
    return '$count refuzate';
  }

  @override
  String scriptCallsCancelled(int count) {
    return '$count anulate';
  }

  @override
  String scriptCallsQueued(int count) {
    return '$count în coadă';
  }

  @override
  String scriptCallsSkipped(int count) {
    return '$count sărite';
  }

  @override
  String get scriptStepQueued => 'În coadă';

  @override
  String get scriptStepSkipped => 'Sărit';

  @override
  String get scriptGroupLoop => 'Buclă';

  @override
  String get scriptGroupEach => 'Pentru fiecare';

  @override
  String get scriptGroupParallel => 'În paralel';

  @override
  String get scriptGroupFunction => 'Funcție';

  @override
  String scriptCallsHidden(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Afișează $count de apeluri în plus',
      few: 'Afișează $count apeluri în plus',
      one: 'Afișează 1 apel în plus',
    );
    return '$_temp0';
  }

  @override
  String get scriptCallsUnplaced => 'Apeluri nepoziționate în script';

  @override
  String get scriptToolComputed => 'Instrument';

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
      other: '$count de linii',
      few: '$count linii',
      one: '1 linie',
    );
    return '$_temp0';
  }

  @override
  String get scriptStateRunning => 'În rulare';

  @override
  String get scriptStateCompleted => 'Finalizat';

  @override
  String get scriptStateFailed => 'Eșuat';

  @override
  String get scriptStateTimedOut => 'Timpul a expirat';

  @override
  String get scriptStateCancelled => 'Anulat';

  @override
  String get scriptStateMemoryExceeded => 'Memorie insuficientă';

  @override
  String get scriptStateOutputExceeded => 'Prea multă ieșire';

  @override
  String get scriptStateSandboxError => 'Eroare sandbox';

  @override
  String get scriptStateRefused => 'Refuzat';

  @override
  String get scriptOriginLine => 'Dintr-un script pe care îl rulează agentul';

  @override
  String get codeModeTitle => 'Mod cod';

  @override
  String get codeModeAvailable => 'Disponibil';

  @override
  String get codeModeUnavailable => 'Indisponibil';

  @override
  String codeModeUnavailableNote(String reason) {
    return 'Acest server nu poate rula scripturi, deci agenții de aici apelează instrumentele unul câte unul. Serverul spune: $reason';
  }

  @override
  String get codeModeNoReason => 'nu a fost dat niciun motiv.';

  @override
  String get workKindUnknown =>
      'Dintr-un motiv pe care această versiune nu îl cunoaște:';

  @override
  String get workRefusalUnknown => 'Serverul a refuzat acest lucru:';

  @override
  String workActionFailed(String error) {
    return 'Nu a reușit: $error';
  }

  @override
  String get wakeKindStopped => 'Reținută deoarece o persoană a oprit rularea.';

  @override
  String get wakeKindAttempts => 'Livrarea a eșuat de trei ori.';

  @override
  String get wakeKindAgentDeleted => 'Agentul nu mai există.';

  @override
  String get wakeKindAgentNotDispatchable => 'Agentul este retras.';

  @override
  String get wakeKindAgentPaused => 'Agentul este pus pe pauză.';

  @override
  String get wakeKindPersonRemoved =>
      'Persoana în numele căreia acționează a părăsit spațiul de lucru.';

  @override
  String get wakeKindBudgetBlocked => 'Un buget blochează o rulare.';

  @override
  String get wakeKindTakeOver => 'O persoană a preluat worktree-ul.';

  @override
  String get wakeKindRateCapConversation =>
      'Această conversație a pornit 30 de rulări din treziri în ultima oră.';

  @override
  String get wakeKindRateCapWorkspace =>
      'Acest spațiu de lucru a pornit 300 de rulări din treziri în ultima oră.';

  @override
  String get wakeKindLiveRunNoInput =>
      'Rularea live a agentului de aici nu primește intrare.';

  @override
  String get wakeKindLiveRunOtherOptions =>
      'Rularea live a agentului de aici rulează altfel, deci aceasta pornește propria rulare după ea.';

  @override
  String get wakeKindLiveRunOtherPerson =>
      'Rularea live a agentului de aici acționează pentru altcineva, deci aceasta pornește propria rulare după ea.';

  @override
  String get wakeKindDispatchRefused => 'Rularea nu a putut porni.';

  @override
  String get wakeKindSandboxUnavailable =>
      'Niciun sandbox nu este disponibil pentru o rulare doar în citire.';

  @override
  String get wakeKindReadOnlyUnavailable =>
      'Backend-ul acestui agent nu poate menține o rulare doar în citire.';

  @override
  String get wakeKindServerStopped =>
      'O repornire a serverului a oprit rularea.';

  @override
  String get wakeKindServerRestarted =>
      'Serverul a fost repornit în timpul rulării unei persoane.';

  @override
  String get wakeKindGuardFailed => 'O verificare înainte de livrare a eșuat.';

  @override
  String get wakeKindLimit =>
      'Se așteaptă ca limita de utilizare a providerului să se reseteze.';

  @override
  String get wakeKindLimitRunLive =>
      'Se așteaptă ca rularea de la limita de utilizare să se încheie.';

  @override
  String get wakeKindWakeMissed => 'Ratată cât timp serverul a fost oprit.';

  @override
  String get wakeKindPipelineRunEnded => 'Rularea sa de pipeline s-a încheiat.';

  @override
  String get wakeKindGoalEnded => 'Obiectivul său s-a încheiat.';

  @override
  String get wakeKindGoalBudgetExhausted =>
      'Obiectivul său și-a consumat bugetul.';

  @override
  String get wakeKindGoalReviewStale =>
      'Obiectivul s-a schimbat de la cererea acestei revizuiri.';

  @override
  String get wakeKindGoalPaused => 'Obiectivul său este pus pe pauză.';

  @override
  String get wakeKindGoalHeld => 'Obiectivul său este reținut.';

  @override
  String get wakeKindGoalStopped => 'Obiectivul său a fost oprit.';

  @override
  String get wakeKindAskSettled =>
      'Întrebarea la care răspunde a fost deja rezolvată.';

  @override
  String get wakeKindRuleEnded => 'Programul său s-a încheiat.';

  @override
  String get wakeRefusalNotYours =>
      'Această trezire acționează pentru altă persoană. Doar ea o poate livra sau relua.';

  @override
  String get wakeRefusalSettled => 'Această trezire s-a încheiat deja.';

  @override
  String get goalRefusalAlreadyActive =>
      'Acest agent are deja un obiectiv activ.';

  @override
  String get goalRefusalNotInReview => 'Acest obiectiv nu așteaptă revizuire.';

  @override
  String get goalRefusalEvidenceIncomplete =>
      'Dovezile obiectivului sunt incomplete.';

  @override
  String get goalRefusalClaimPending =>
      'Afirmația că este terminat este încă verificată.';

  @override
  String get goalRefusalNotActiveSegment =>
      'Acest obiectiv nu are niciun segment în rulare.';

  @override
  String get goalRefusalNotYours =>
      'Doar persoana care a pornit acest obiectiv poate face asta.';

  @override
  String get goalRefusalNotPaused => 'Pune mai întâi obiectivul pe pauză.';

  @override
  String get goalRefusalContractInvalid =>
      'Contractul obiectivului nu poate fi citit.';

  @override
  String get goalRefusalCheckerUnknown => 'Niciun agent nu are acest nume.';

  @override
  String get goalRefusalCheckerAmbiguous => 'Mai mulți agenți au acest nume.';

  @override
  String get goalRefusalCheckerIsGoalAgent =>
      'Verificatorul trebuie să fie alt agent decât cel care face lucrul.';

  @override
  String get goalRefusalCommandInvalid => 'Acest obiectiv nu poate fi citit:';

  @override
  String get wakeRuleRefusalIntervalTooShort =>
      'Intervalul este prea scurt. Alege cel puțin un minut.';

  @override
  String get wakeRuleRefusalTooSoon =>
      'Ora aceasta este prea devreme. Alege una mai târziu.';

  @override
  String get wakeRuleRefusalLineageEnded =>
      'Acest lanț de treziri și-a consumat rulările sau timpul.';

  @override
  String get wakeRuleRefusalWatchTargetUnreadable =>
      'Nu poți citi ce ar urmări asta.';

  @override
  String get wakeRuleRefusalExpiryRequired =>
      'Stabilește o dată de sfârșit sau un număr de rulări.';

  @override
  String get wakeRuleRefusalLimitReached =>
      'Această conversație sau acest agent are deja câte programe i se permit.';

  @override
  String get wakeRuleRefusalInvalidWhen => 'Ora nu poate fi citită.';

  @override
  String get wakeRuleRefusalNoteTooLong => 'Nota este prea lungă.';

  @override
  String get wakeRuleRefusalExpiryTooLong => 'Sfârșitul este prea departe.';

  @override
  String get wakeRuleRefusalLimitOutOfRange =>
      'O limită de rulări, zile sau buget este în afara intervalului.';

  @override
  String get wakeRuleRefusalNextOutsideLoop =>
      'Doar o buclă își poate alege singură următoarea oră.';

  @override
  String get wakeRuleRefusalWatchRefused => 'Asta nu poate fi urmărită.';

  @override
  String get wakeRuleRefusalRuleEnded => 'Acest program s-a încheiat deja.';

  @override
  String get wakeRuleRefusalNotYours => 'Acest program aparține altcuiva.';

  @override
  String get wakeRuleEndFired => 'A rulat o singură dată.';

  @override
  String get wakeRuleEndExpired => 'A ajuns la data de sfârșit.';

  @override
  String get wakeRuleEndRunCap => 'Și-a consumat rulările.';

  @override
  String get wakeRuleEndCostCap => 'A ajuns la plafonul de cost.';

  @override
  String get wakeRuleEndGoalEnded => 'Obiectivul său s-a încheiat.';

  @override
  String get wakeRuleEndCancelled => 'A fost anulat.';

  @override
  String get wakeRuleEndMemberRemoved =>
      'Persoana sa a părăsit spațiul de lucru.';

  @override
  String get wakeRuleEndInvalidRow => 'Setările salvate nu au putut fi citite.';

  @override
  String goalHoldWorking(int segment) {
    final intl.NumberFormat segmentNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String segmentString = segmentNumberFormat.format(segment);

    return 'Lucrează la segmentul $segmentString. Nu trebuie să facă nimeni nimic.';
  }

  @override
  String get goalHoldWaiting =>
      'Așteaptă lucrul care îi este datorat. Continuă singur.';

  @override
  String goalHoldWaitingUntil(String time) {
    return 'Așteaptă lucrul care îi este datorat. Continuă singur cel târziu la $time.';
  }

  @override
  String get goalHoldVerifying =>
      'Spune că este terminat. Serverul își rulează verificările, apoi un revizor decide.';

  @override
  String get goalHoldLimit =>
      'Pus pe pauză la limita de utilizare a providerului. Se reia singur după resetare.';

  @override
  String goalHoldLimitUntil(String time) {
    return 'Pus pe pauză la limita de utilizare a providerului. Se reia singur la $time.';
  }

  @override
  String get goalHoldPerson =>
      'Se așteaptă ca o persoană să răspundă în conversație. Continuă după ce cineva răspunde.';

  @override
  String get goalHoldByPerson =>
      'Pus pe pauză de o persoană. Rămâne pe pauză până când cineva îl reia.';

  @override
  String get goalHoldNeedsReview =>
      'Așteaptă revizuire: nu poate continua singur. Aprobă-l ca terminat, reia-l sau anulează-l.';

  @override
  String get goalHoldBudget =>
      'Și-a consumat bugetul. Mărește bugetul ca să poată continua.';

  @override
  String goalHoldLimitParks(int count, int max) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);
    final intl.NumberFormat maxNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String maxString = maxNumberFormat.format(max);

    return 'Pauze la limita de utilizare: $countString din $maxString';
  }

  @override
  String get goalHoldDetailStalled => 'Niciun progres în ultimele segmente.';

  @override
  String get goalHoldDetailStalledWaiting =>
      'A așteptat 24 de ore pentru aceeași muncă, fără progres.';

  @override
  String get goalHoldDetailVerificationFailed => 'Ultima verificare a eșuat.';

  @override
  String get goalHoldDetailCannotVerify =>
      'Verificatorul nu a putut stabili dacă este terminat.';

  @override
  String get goalHoldDetailSandboxUnavailable =>
      'Nu este disponibil niciun sandbox pentru a-și rula verificările.';

  @override
  String get goalHoldDetailCheckerUnavailable =>
      'Agentul verificator nu este disponibil. Alege alt verificator, apoi reia.';

  @override
  String get goalHoldDetailCheckBroken => 'Această verificare nu poate rula:';

  @override
  String get goalHoldDetailWakeSkipped => 'Trezirea sa nu a fost livrată.';

  @override
  String get goalHoldDetailClaimPending =>
      'Afirmația sa că este terminat așteaptă o verificare.';

  @override
  String get goalHoldDetailUnanswered =>
      'O întrebare sau o cerere de aprobare adresată unei persoane a rămas fără răspuns.';

  @override
  String get goalHoldDetailLimitParks =>
      'A atins limitele de utilizare prea des. Verifică-l, apoi reia.';

  @override
  String get goalHoldDetailInput => 'Se așteaptă un răspuns în conversație.';

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

    return 'Segmentul $runString din $maxString';
  }

  @override
  String goalSegmentsNoCap(int run) {
    final intl.NumberFormat runNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String runString = runNumberFormat.format(run);

    return 'Segmentul $runString, fără plafon';
  }

  @override
  String goalMoney(String spent, String cap) {
    return 'Cheltuit $spent din $cap';
  }

  @override
  String goalDeadline(String time) {
    return 'Termen $time';
  }

  @override
  String get goalPipelineStep => 'Un pas de pipeline urmărește acest obiectiv.';

  @override
  String get goalSummaryHeading => 'Ultimul rezumat';

  @override
  String get goalDoneMeans => 'Terminat înseamnă';

  @override
  String get goalChecks => 'Verificări';

  @override
  String get goalBoundaries => 'Limite';

  @override
  String get goalStopWhen => 'Oprește-te și întreabă când';

  @override
  String get goalNoMachineCheck =>
      'Nicio verificare automată. Un revizor judecă din ce poate citi.';

  @override
  String get goalCheckEnvironment => 'Sarcină de mediu';

  @override
  String goalLastCheck(int round, String time) {
    final intl.NumberFormat roundNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String roundString = roundNumberFormat.format(round);

    return 'Ultima verificare, runda $roundString, $time';
  }

  @override
  String get goalClaim => 'Ce a afirmat';

  @override
  String get goalCheckPassed => 'Promovată';

  @override
  String goalCheckFailed(int code) {
    return 'Eșuată, cod de ieșire $code';
  }

  @override
  String get goalCheckTimedOut => 'Timpul a expirat';

  @override
  String get goalCheckNotRerun => 'Nerulată din nou: nimic nu s-a schimbat';

  @override
  String get goalCheckBroken => 'Nu poate rula';

  @override
  String get goalCriterionMet => 'Îndeplinit';

  @override
  String get goalCriterionUnmet => 'Neîndeplinit';

  @override
  String get goalCriterionCannotTell => 'Nu se poate spune';

  @override
  String get goalVerdictPass => 'Verdict: terminat';

  @override
  String get goalVerdictFail => 'Verdict: nu este terminat';

  @override
  String get goalVerdictCannotVerify => 'Verdict: nu s-a putut stabili';

  @override
  String get goalConcerns => 'Îngrijorări';

  @override
  String goalVerifiedBy(String agent) {
    return 'Verificat de $agent';
  }

  @override
  String get goalVerifiedBySelf =>
      'Verificat de el însuși (fără verificator separat)';

  @override
  String get goalClosedByPerson =>
      'Închis de o persoană fără o verificare reușită';

  @override
  String get goalApprove => 'Aprobă finalizarea';

  @override
  String get goalApproveTitle => 'Închizi acest obiectiv ca terminat?';

  @override
  String get goalApproveBody =>
      'Nicio verificare nu l-a confirmat. Îl închizi pe cuvântul tău, iar obiectivul înregistrează că o persoană l-a închis neverificat.';

  @override
  String get goalApproveConfirm => 'Închide ca terminat';

  @override
  String get goalResumeNotYours =>
      'Reluarea lui sau mărirea bugetului aparțin celui care l-a pornit.';

  @override
  String get goalChooseChecker => 'Alege alt verificator';

  @override
  String goalCheckerSet(String agent) {
    return '$agent îl verifică acum. Reia ca să verifice din nou.';
  }

  @override
  String get goalSchedules => 'Programe';

  @override
  String get goalRepeat => 'Repetă';

  @override
  String get goalCreateChecks => 'Verificări (opțional)';

  @override
  String get goalCreateCheckHint =>
      'O comandă care reușește când lucrul este terminat';

  @override
  String get goalCreateAddCheck => 'Adaugă verificare';

  @override
  String get goalCreateRemoveCheck => 'Elimină verificarea';

  @override
  String get goalCreateSegmentCap => 'Plafon de segmente (opțional)';

  @override
  String get goalCreateSegmentInvalid =>
      'Plafonul de segmente trebuie să fie un număr întreg, de cel puțin 1.';

  @override
  String get scheduleCreateTitle => 'Repetă un prompt';

  @override
  String get scheduleCadence => 'Cât de des';

  @override
  String get scheduleEveryMinutes => 'La fiecare N minute';

  @override
  String get scheduleEveryHours => 'La fiecare N ore';

  @override
  String get scheduleSelfPaced => 'În ritmul agentului';

  @override
  String get scheduleSelfPacedHint =>
      'Agentul alege întârzierea după fiecare rulare, între 1 minut și 1 oră.';

  @override
  String get scheduleInterval => 'Interval';

  @override
  String get scheduleNote => 'Ce ar trebui să facă fiecare rulare?';

  @override
  String get scheduleCostCap => 'Plafon de cost în USD (opțional)';

  @override
  String get scheduleExpiryDays => 'Se termină după N zile (opțional)';

  @override
  String get scheduleCreateInvalid =>
      'Alege un spațiu și un agent, scrie ce ar trebui să facă fiecare rulare și folosește numere întregi de cel puțin 1.';

  @override
  String get scheduleCreateButton => 'Pornește programul';

  @override
  String get scheduleCreateConfirmTitle => 'Pornești acest program?';

  @override
  String scheduleCreateConfirmEveryMinutes(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Rulează la fiecare $countString de minute, începând acum.',
      few: 'Rulează la fiecare $countString minute, începând acum.',
      one: 'Rulează în fiecare minut, începând acum.',
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
      other: 'Rulează la fiecare $countString de ore, începând acum.',
      few: 'Rulează la fiecare $countString ore, începând acum.',
      one: 'Rulează în fiecare oră, începând acum.',
    );
    return '$_temp0';
  }

  @override
  String get scheduleCreateConfirmSelfPaced =>
      'Rulează acum, apoi agentul alege când să ruleze din nou.';

  @override
  String get scheduleCreated => 'Programul a pornit. Apare în Programe.';

  @override
  String get schedulesTitle => 'Programe';

  @override
  String get schedulesLoadFailed => 'Programele nu au putut fi încărcate';

  @override
  String get schedulesEmpty => 'Niciun program sau urmărire';

  @override
  String get schedulesEmptyDescription =>
      'Repetă un prompt din ecranul obiectivelor sau trimite /loop ori /schedule într-o conversație.';

  @override
  String get scheduleMissing =>
      'Acest program nu mai este disponibil în acest spațiu de lucru.';

  @override
  String scheduleEvery(String interval) {
    return 'La fiecare $interval';
  }

  @override
  String get scheduleSelfPacedLoop => 'Buclă în ritmul agentului';

  @override
  String get scheduleCron => 'Program cron';

  @override
  String scheduleOnce(String time) {
    return 'O dată, la $time';
  }

  @override
  String scheduleWatch(String event) {
    return 'Urmărire: $event';
  }

  @override
  String get scheduleWatchPrChecks => 'verificările pull request-ului';

  @override
  String get scheduleWatchPrReview => 'revizuirile pull request-ului';

  @override
  String get scheduleWatchPrMerged => 'integrarea pull request-ului';

  @override
  String get scheduleWatchEnvironment => 'mediul';

  @override
  String get scheduleWatchTicket => 'tichetul';

  @override
  String get scheduleWatchPipelineRun => 'rularea de pipeline';

  @override
  String get scheduleStatusActive => 'Activ';

  @override
  String get scheduleStatusPaused => 'Pauză';

  @override
  String get scheduleStatusEnded => 'Încheiat';

  @override
  String scheduleWakes(String agent) {
    return 'Trezește $agent';
  }

  @override
  String scheduleNext(String time) {
    return 'Următoarea rulare $time';
  }

  @override
  String scheduleLast(String time) {
    return 'Ultima rulare $time';
  }

  @override
  String scheduleRuns(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString de rulări',
      few: '$countString rulări',
      one: '1 rulare',
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

    return '$countString din $maxString rulări';
  }

  @override
  String scheduleSkipped(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString de sărituri',
      few: '$countString sărituri',
      one: '1 săritură',
    );
    return '$_temp0';
  }

  @override
  String scheduleEnds(String time) {
    return 'Se termină $time';
  }

  @override
  String scheduleChain(int count, String time) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Parte dintr-un lanț: $countString rulări rămase, se termină $time';
  }

  @override
  String get scheduleNoteAgent => 'Nota agentului, în cuvintele lui:';

  @override
  String get scheduleNotePerson => 'Nota unei persoane:';

  @override
  String scheduleActsFor(String name) {
    return 'Acționează pentru $name';
  }

  @override
  String get scheduleActsForBot => 'Nu acționează pentru nicio persoană';

  @override
  String get scheduleGoalBound => 'Se termină odată cu obiectivul său.';

  @override
  String get schedulePause => 'Pune pe pauză';

  @override
  String get scheduleResume => 'Reia';

  @override
  String get scheduleDelete => 'Șterge';

  @override
  String get scheduleRemove => 'Elimină';

  @override
  String get scheduleDeleteTitle => 'Ștergi acest program?';

  @override
  String get scheduleDeleteBody =>
      'Nu mai pornește niciodată. Ce a făcut deja nu se anulează.';

  @override
  String get scheduleRemoveTitle => 'Elimini acest program?';

  @override
  String get scheduleRemoveBody => 'Dispare din listă.';

  @override
  String get scheduleResumeNotYours =>
      'Doar persoana în numele căreia acționează acest program o poate relua.';

  @override
  String get scheduleResumeAdminOnly =>
      'Doar un admin al spațiului de lucru poate relua un program pe care nicio persoană nu îl deține.';

  @override
  String get scheduleOpenConversation => 'Deschide conversația';

  @override
  String get progressWaiting => 'În așteptare';

  @override
  String get progressNothingWaiting => 'Nimic nu așteaptă.';

  @override
  String get wakeOriginGoal => 'Obiectiv';

  @override
  String get wakeOriginGoalCheck => 'Verificare obiectiv';

  @override
  String get wakeOriginGoalReview => 'Revizuire obiectiv';

  @override
  String get wakeOriginSchedule => 'Program';

  @override
  String get wakeOriginWatch => 'Urmărire';

  @override
  String get wakeOriginReply => 'Răspuns';

  @override
  String get wakeOriginMessage => 'Mesaj';

  @override
  String get wakeOriginWorkFinished => 'Lucru terminat';

  @override
  String get wakeOriginLimitReset => 'Limită resetată';

  @override
  String get wakeOriginRecovery => 'Recuperare';

  @override
  String get wakeOriginAssignment => 'Atribuire';

  @override
  String get wakeOriginPipelineStep => 'Pas de pipeline';

  @override
  String get wakeOriginImprovementReview => 'Revizuire de îmbunătățiri';

  @override
  String wakeOriginReplyFrom(String agent) {
    return 'Răspuns de la $agent';
  }

  @override
  String wakeOriginMessageFrom(String agent) {
    return 'Mesaj de la $agent';
  }

  @override
  String wakeOriginWorkFinishedBy(String agent) {
    return 'Lucru terminat de $agent';
  }

  @override
  String wakeFor(String agent) {
    return 'Pentru $agent';
  }

  @override
  String wakeDue(String time) {
    return 'Scadentă $time';
  }

  @override
  String get wakeDueNow => 'Scadentă acum';

  @override
  String get wakeHeld => 'Reținută';

  @override
  String wakeExpires(String time) {
    return 'Expiră $time';
  }

  @override
  String wakeAttempt(int attempt) {
    final intl.NumberFormat attemptNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String attemptString = attemptNumberFormat.format(attempt);

    return 'Încercarea $attemptString';
  }

  @override
  String get wakeCancel => 'Anulează';

  @override
  String get wakeDeliverNow => 'Livrează acum';

  @override
  String get wakeResume => 'Reia';

  @override
  String get wakeDismiss => 'Renunță';

  @override
  String get wakeResumeOnlyTheirs =>
      'Doar persoana a cărei rulare este aceasta o poate relua.';

  @override
  String get wakeRecovery =>
      'Serverul a fost repornit în timpul acestei rulări. Reia-o ca să continue, sau renunță.';

  @override
  String limitParkTitle(String provider, String time) {
    return 'Pusă pe pauză la limita de utilizare a $provider, care se resetează la $time. Rularea așteaptă ca Reia să fie apăsat, timp de până la 7 zile după resetare.';
  }

  @override
  String limitParkTitleUnnamed(String time) {
    return 'Pusă pe pauză la limita de utilizare a providerului, care se resetează la $time. Rularea așteaptă ca Reia să fie apăsat, timp de până la 7 zile după resetare.';
  }

  @override
  String get limitParkResumeNow => 'Reia acum';

  @override
  String get limitParkCancel => 'Anulează';

  @override
  String limitParkResumed(String provider) {
    return 'Reluat după limita de utilizare a $provider.';
  }

  @override
  String limitParkGone(String provider) {
    return 'Nu mai așteaptă la limita de utilizare a $provider.';
  }

  @override
  String get limitParkProviderUnknown => 'providerului';

  @override
  String get mobileHeldMessages => 'Mesaje reținute';

  @override
  String get heldSteeringTitle =>
      'Reținute deoarece rularea s-a încheiat înainte să le poată prelua. Trimite-le pe ale tale acum sau elimină-le.';

  @override
  String get heldSteeringRelease => 'Trimite mesajele reținute';

  @override
  String get notifGoalCompleted => 'Obiectiv terminat';

  @override
  String get notifGoalFailed => 'Obiectiv eșuat';

  @override
  String get notifGoalCancelled => 'Obiectiv anulat';

  @override
  String get notifGoalBudgetExhausted => 'Obiectivul și-a consumat bugetul';

  @override
  String get notifGoalNeedsReview => 'Un obiectiv așteaptă revizuirea ta';

  @override
  String get notifGoalNeedsPerson => 'Un obiectiv are nevoie de tine';

  @override
  String get notifGoalOnHold => 'Un obiectiv este reținut';

  @override
  String get notifWakeRuleEnded => 'Un program s-a încheiat';

  @override
  String notifWaitingDigest(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString de lucruri te așteaptă',
      few: '$countString lucruri te așteaptă',
      one: '1 lucru te așteaptă',
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
      other: 'Au fost propuse $countString de îmbunătățiri',
      few: 'Au fost propuse $countString îmbunătățiri',
      one: 'A fost propusă o îmbunătățire',
    );
    return '$_temp0';
  }

  @override
  String get notifPipelineRunHeld =>
      'O rulare de pipeline este reținută la buget';

  @override
  String notifPipelineRunHeldBody(String spent, String cap) {
    return 'Cheltuit $spent din $cap';
  }

  @override
  String get notifNeedsYou => 'Are nevoie de tine';

  @override
  String get notifDigestGoalReview => 'Obiectivul așteaptă revizuire';

  @override
  String get notifDigestGoalPerson => 'Obiectivul are nevoie de o persoană';

  @override
  String get notifDigestHeldWake => 'Trezire reținută';

  @override
  String get notifDigestImprovement => 'Îmbunătățire propusă';

  @override
  String get wakeKindRulePaused => 'Programul său a fost pus pe pauză.';

  @override
  String get wakeKindRuleBusy =>
      'Agentul era ocupat, iar acest program sare peste o pornire când se întâmplă asta.';

  @override
  String get wakeKindRuleFolded =>
      'A luat locul unui eveniment ulterior al aceleiași urmăriri.';

  @override
  String get wakeKindRuleSuperseded =>
      'A fost înlocuită de un moment ulterior al programului său.';

  @override
  String get wakeKindRuleNotified =>
      'Programul său doar trimite o notificare, deci nu a pornit nicio rulare.';

  @override
  String get wakeKindRuleLimitParked =>
      'Programul său așteaptă ca limita de utilizare a providerului să se reseteze.';

  @override
  String get improvementRefusalCooldown =>
      'O revizuire a îmbunătățirilor a rulat în această conversație nu cu mult timp în urmă. Încearcă din nou mai târziu.';

  @override
  String get improvementRefusalQueued =>
      'O revizuire a îmbunătățirilor din această conversație așteaptă deja să ruleze.';

  @override
  String get improvementRefusalAgentNotFound =>
      'Acest agent nu face parte din acest spațiu de lucru.';

  @override
  String get steeringRefusalHeldByLimit =>
      'Mesajele reținute la limita de utilizare nu pot fi trimise manual. Așteaptă ca rularea pusă pe pauză să reia.';

  @override
  String limitParkCancelled(String provider) {
    return 'Așteptarea la limita de utilizare a $provider a fost anulată.';
  }

  @override
  String limitParkExpired(String provider) {
    return 'Așteptarea la limita de utilizare a $provider a expirat înainte ca rularea să reia.';
  }

  @override
  String limitParkSkipped(String provider) {
    return 'Rularea nu a reluat după limita de utilizare a $provider.';
  }

  @override
  String get heldSteeringLimitTitle =>
      'Reținute cât timp rularea așteaptă resetarea limitei de utilizare. Sunt trimise când persoana pentru care rulează o reia.';

  @override
  String heldSteeringLimitAt(String time) {
    return 'Reținute până când limita de utilizare se resetează la $time. Sunt trimise când persoana pentru care rulează o reia.';
  }

  @override
  String get heldSteeringOtherTitle => 'Reținute de server. Le poți elimina.';

  @override
  String workRowWoke(int count, String agent) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'A trezit $agent pentru $countString de elemente în așteptare',
      few: 'A trezit $agent pentru $countString elemente în așteptare',
      one: 'A trezit $agent',
    );
    return '$_temp0';
  }

  @override
  String workRowWakeMissed(String agent) {
    return 'O trezire pentru $agent a fost ratată cât timp serverul era oprit.';
  }

  @override
  String workRowWakeSkipped(String agent) {
    return 'O trezire pentru $agent nu a fost livrată.';
  }

  @override
  String workRowScheduleCreated(String agent) {
    return 'Program setat pentru $agent.';
  }

  @override
  String workRowScheduleEnded(String agent) {
    return 'Programul lui $agent s-a încheiat.';
  }

  @override
  String workRowNoteFromAgent(String agent) {
    return 'Notă de program de la $agent:';
  }

  @override
  String get workRowNoteFromPerson => 'Notă de program de la o persoană:';

  @override
  String workRowCommandRefusedNamed(String command) {
    return 'Comanda $command a fost refuzată.';
  }

  @override
  String get workRowCommandRefused => 'O comandă a fost refuzată.';

  @override
  String workRowCapRaised(String person, String from, String to) {
    return '$person a mărit plafonul de cheltuieli al pipeline-ului de la $from la $to.';
  }

  @override
  String workRowCapRaisedNoAmounts(String person) {
    return '$person a mărit plafonul de cheltuieli al pipeline-ului.';
  }

  @override
  String get workRowApplyIncomplete =>
      'O modificare acceptată a acestei abilități nu a putut fi finalizată, deoarece abilitatea s-a schimbat între timp. Propunerea a fost anulată.';

  @override
  String get workRowOpenSchedule => 'Deschide programul';

  @override
  String get heldSteeringOthersTitle =>
      'Reținute deoarece rularea s-a încheiat înainte să le poată prelua. Doar persoana care a scris un mesaj îl poate trimite.';

  @override
  String get heldSteeringOnlyYours =>
      'Trimite doar mesajele tale. Celelalte așteaptă persoanele care le-au scris.';

  @override
  String heldSteeringWrittenBy(String name) {
    return 'Scris de $name';
  }

  @override
  String get steeringRefusalNotYours =>
      'Doar persoana care a scris un mesaj reținut îl poate trimite, iar niciunul dintre acestea nu este al tău.';

  @override
  String get steeringRefusalNeedsWrite =>
      'Ai nevoie de acces de scriere la depozitele acestui spațiu pentru a direcționa o rulare care acționează în numele altcuiva.';

  @override
  String workRowSchedulePaused(String name, String agent) {
    return '$name a pus pe pauză programul pentru $agent.';
  }

  @override
  String get goalVerdictObjective => 'Obiectivul în ansamblu';

  @override
  String get notifDigestRequest => 'Așteaptă răspunsul tău';
}
