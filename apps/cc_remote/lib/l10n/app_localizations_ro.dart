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
  String get inboxNoForgeAccount =>
      'Niciun cont forge nu este conectat pe server, deci pull request-urile nu îți pot fi atribuite încă.';

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
  String attachmentsTooLargeRelay(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$names sunt prea mari pentru a fi trimise prin relay de aici.',
      few: '$names sunt prea mari pentru a fi trimise prin relay de aici.',
      one: '$names este prea mare pentru a fi trimis prin relay de aici.',
    );
    return '$_temp0';
  }

  @override
  String get attachmentUploadFailed =>
      'Nu s-a putut încărca atașamentul. Încearcă din nou.';

  @override
  String attachmentsLeftOut(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count de atașamente nu au putut fi încărcate și au fost omise.',
      few: '$count atașamente nu au putut fi încărcate și au fost omise.',
      one: '1 atașament nu a putut fi încărcat și a fost omis.',
    );
    return '$_temp0';
  }

  @override
  String get teammate => 'Coleg';

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
  String reposUnreadable(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count de repo-uri nu au putut fi citite.',
      few: '$count repo-uri nu au putut fi citite.',
      one: '1 repo nu a putut fi citit.',
    );
    return '$_temp0';
  }

  @override
  String reposNotReadable(String names) {
    return 'Ilizibile: $names';
  }

  @override
  String get installationSuspendedTitle =>
      'Instalarea GitHub App este suspendată';

  @override
  String installationSuspendedBody(String names) {
    return 'Se afișează ultimele date cunoscute pentru $names. Reia instalarea pe GitHub sau conectează un token cu acces.';
  }

  @override
  String installationSuspendedNotice(String names) {
    return 'Instalarea GitHub App este suspendată. Se afișează ultimele date cunoscute pentru $names. Reia instalarea pe GitHub sau conectează un token cu acces.';
  }

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
}
