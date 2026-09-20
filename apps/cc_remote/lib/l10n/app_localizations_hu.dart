// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hungarian (`hu`).
class AppLocalizationsHu extends AppLocalizations {
  AppLocalizationsHu([String locale = 'hu']) : super(locale);

  @override
  String get appTitle => 'Control Center';

  @override
  String get back => 'Vissza';

  @override
  String get cancel => 'Mégse';

  @override
  String get retry => 'Újrapróbálás';

  @override
  String get tryAgain => 'Próbálja újra';

  @override
  String get settings => 'Beállítások';

  @override
  String get refresh => 'Frissítés';

  @override
  String get approve => 'Jóváhagyás';

  @override
  String get deny => 'Tiltás';

  @override
  String get continueLabel => 'Folytatás';

  @override
  String get agentQuestionHeader => 'Kérdés Önhöz';

  @override
  String get agentQuestionAnsweredLabel => 'Megválaszolva';

  @override
  String get agentQuestionSkip => 'Kihagyás';

  @override
  String get agentQuestionSkippedLabel => 'Kihagyva';

  @override
  String get agentQuestionFreeformHint => 'Írja be a válaszát…';

  @override
  String get agentApprovalRequired => 'Jóváhagyás szükséges';

  @override
  String get approveAndRemember => 'Jóváhagyás 8 órára';

  @override
  String get decline => 'Elutasítás';

  @override
  String get confirm => 'Megerősítés';

  @override
  String get send => 'Küldés';

  @override
  String get close => 'Bezárás';

  @override
  String get expand => 'Kinyitás';

  @override
  String get zoomIn => 'Nagyítás';

  @override
  String get zoomOut => 'Kicsinyítés';

  @override
  String get resetZoom => 'Nagyítás visszaállítása';

  @override
  String get scanQrPrompt =>
      'Olvassa be a QR-kódot a Control Centerben, hogy párosítsa ezt a telefont.';

  @override
  String get scanQrHelp =>
      'Nyissa meg a kamerát, és irányítsa a Control Centerben megjelenő QR-kódra. Ez a telefon közvetlenül, privát kapcsolaton csatlakozik.';

  @override
  String get connectingToMac => 'Csatlakozás a Control Centerhez…';

  @override
  String get connectingDetail =>
      'Biztonságos, közvetlen kapcsolat létrehozása.';

  @override
  String get identityChangedTitle => 'A szerver identitása megváltozott';

  @override
  String get identityChangedBody =>
      'Ez a szerver már nem egyezik a párosításkor mentett identitással. Ez azt jelentheti, hogy a szervert újratelepítették — vagy hogy valami közbeékelődik a kapcsolatba. Biztonságból ez az eszköz nem csatlakozik. Távolítsa el a párosítást, majd olvasson be egy új QR-kódot a Control Centerben az újbóli párosításhoz.';

  @override
  String get removePairing => 'Párosítás eltávolítása';

  @override
  String get couldntConnect => 'Nem sikerült csatlakozni';

  @override
  String get pendingPairingTitle => 'Csatlakozik ehhez a szerverhez?';

  @override
  String get pendingPairingBody =>
      'Egy link azt kérte a Control Centertől, hogy párosodjon ezzel a szerverrel. Csak akkor folytassa, ha Ön indította.';

  @override
  String get connect => 'Csatlakozás';

  @override
  String get failureNotPaired =>
      'Nincs párosítva — olvassa be a QR-kódot a Control Centerben';

  @override
  String get failureUnreachable =>
      'A szerver egyik úton sem érhető el — ellenőrizze, hogy fut-e, vagy próbálja ugyanazon a hálózaton';

  @override
  String get failureIdentityChanged =>
      'A szerver identitása megváltozott — ha újratelepítették, párosítsa újra ezt az eszközt';

  @override
  String get failureAuthRejected =>
      'A szerver elutasította ezt az eszközt — párosítsa újra a Control Centerben';

  @override
  String get failureUnknown =>
      'Nem sikerült csatlakozni — koppintson az újrapróbáláshoz';

  @override
  String get statusConnected => 'Csatlakoztatva';

  @override
  String get statusConnecting => 'Csatlakozás';

  @override
  String get statusOffline => 'Offline';

  @override
  String get statusIdentityMismatch => 'Identitáseltérés';

  @override
  String get statusNotPaired => 'Nincs párosítva';

  @override
  String get statusConfirmPairing => 'Párosítás megerősítése';

  @override
  String get connectionFailed => 'A kapcsolat sikertelen';

  @override
  String get identityMismatchBanner =>
      'A szerver identitása megváltozott — a kapcsolat leállt. Párosítsa újra ezt az eszközt a folytatáshoz.';

  @override
  String get tabInbox => 'Beérkezett';

  @override
  String get tabTickets => 'Jegyek';

  @override
  String get tabChat => 'Csevegés';

  @override
  String get tabPrs => 'PRs';

  @override
  String get tabCalendar => 'Naptár';

  @override
  String get tabNews => 'Hírek';

  @override
  String tabWaitingCount(String label, int count) {
    return '$label, $count várakozik';
  }

  @override
  String get updateAvailable => 'Új Control Center érhető el';

  @override
  String get appearance => 'Megjelenés';

  @override
  String get language => 'Nyelv';

  @override
  String get device => 'Eszköz';

  @override
  String get themeSystem => 'Rendszer';

  @override
  String get themeLight => 'Világos';

  @override
  String get themeDark => 'Sötét';

  @override
  String get languageSystem => 'Rendszer';

  @override
  String get disconnectTapAgain =>
      'Koppintson újra, hogy leválassza ezt az eszközt a Control Centerről';

  @override
  String get disconnectDevice => 'Eszköz leválasztása';

  @override
  String get disconnect => 'Leválasztás';

  @override
  String get chooseWorkspace => 'Munkaterület kiválasztása';

  @override
  String get workspaces => 'Munkaterületek';

  @override
  String get workspacesLoadFailed =>
      'Nem sikerült betölteni a munkaterületeket';

  @override
  String get noWorkspacesYet => 'Még nincsenek munkaterületek';

  @override
  String selectWorkspace(String name) {
    return '$name kiválasztása';
  }

  @override
  String get inboxLoadFailed => 'Nem sikerült betölteni a beérkezettet';

  @override
  String get allCaughtUp => 'Minden elolvasva';

  @override
  String get inboxNoForgeAccount =>
      'A szerveren nincs csatlakoztatott forge-fiók, ezért a pull requestek még nem rendelhetők Önhöz.';

  @override
  String get inboxNothingWaiting =>
      'Semmi sincs blokkolva, és egyetlen pull request sem vár Önre.';

  @override
  String get blocked => 'Blokkolva';

  @override
  String get sectionNeedsYourReview => 'Az Ön átnézésére van szükség';

  @override
  String get sectionReturnedToYou => 'Visszaküldve Önnek';

  @override
  String get sectionApprovedAndReady => 'Jóváhagyva és kész';

  @override
  String get sectionYourDrafts => 'Az Ön piszkozatai';

  @override
  String get sectionWaitingForReviewers => 'Átnézőkre vár';

  @override
  String get sectionMergingAndMerged => 'Összefésülés és nemrég összefésülve';

  @override
  String get sectionWaitingForAuthor => 'Szerzőre vár';

  @override
  String waitingAgo(String ago) {
    return 'vár $ago';
  }

  @override
  String get openConversation => 'Beszélgetés megnyitása';

  @override
  String get calendarLoadFailed => 'Nem sikerült betölteni a naptárat';

  @override
  String get nothingScheduled => 'Nincs ütemezve semmi';

  @override
  String get calendarEmptyDescription =>
      'A csatlakoztatott naptárak eseményei itt jelennek meg.';

  @override
  String get agenda => 'Napirend';

  @override
  String get syncCalendarsNow => 'Naptárak szinkronizálása most';

  @override
  String get event => 'Esemény';

  @override
  String get eventNotFound => 'Az esemény nem található';

  @override
  String get eventNotFoundDescription =>
      'Lehet, hogy a napirend ablakán kívül esik, vagy forrásoldalon törölték.';

  @override
  String get joinMeeting => 'Csatlakozás a megbeszéléshez';

  @override
  String get join => 'Csatlakozás';

  @override
  String attendeesCount(int count) {
    return 'Résztvevők ($count)';
  }

  @override
  String get details => 'Részletek';

  @override
  String get allDay => 'Egész nap';

  @override
  String get happeningNow => 'Most zajlik';

  @override
  String inDuration(String duration) {
    return '$duration múlva';
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
  String get attendeeAccepted => 'elfogadva';

  @override
  String get attendeeDeclined => 'elutasítva';

  @override
  String get attendeeMaybe => 'talán';

  @override
  String get attendeeNoReply => 'nincs válasz';

  @override
  String get organizer => 'szervező';

  @override
  String get calendarNoAccounts =>
      'Ehhez a munkaterülethez nincs csatlakoztatott naptár. Csatlakoztasson egyet az asztali alkalmazásból — a bejelentkezés a tokent a szerveren tárolja.';

  @override
  String get calendarReauthNeeded =>
      'Egy naptárfiókot újra kell csatlakoztatni — a lentiek elavultak lehetnek. Csatlakoztassa újra az asztali alkalmazásból.';

  @override
  String get spacesLoadFailed => 'Nem sikerült betölteni a tereket';

  @override
  String get noSpaces => 'Nincsenek terek';

  @override
  String get spacesEmptyDescription => 'A munkaterület terei itt jelennek meg.';

  @override
  String get thread => 'Szál';

  @override
  String get agentWorking => 'Az ügynök dolgozik';

  @override
  String get messagesLoadFailed => 'Nem sikerült betölteni az üzeneteket';

  @override
  String get noMessagesYet => 'Még nincsenek üzenetek';

  @override
  String get noMessagesDescription =>
      'Küldjön üzenetet a beszélgetés indításához.';

  @override
  String get agentResponding => 'Az ügynök válaszol';

  @override
  String get agentFinished => 'Az ügynök befejezte';

  @override
  String attachmentsTooLarge(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$names túl nagy ahhoz, hogy innen küldje.',
      one: '$names túl nagy ahhoz, hogy innen küldje.',
    );
    return '$_temp0';
  }

  @override
  String attachmentsTooLargeRelay(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$names túl nagy ahhoz, hogy innen a relén keresztül küldje.',
      one: '$names túl nagy ahhoz, hogy innen a relén keresztül küldje.',
    );
    return '$_temp0';
  }

  @override
  String get attachmentUploadFailed =>
      'Nem sikerült feltölteni a mellékletet. Próbálja újra.';

  @override
  String attachmentsLeftOut(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mellékletet nem sikerült feltölteni, ezért kimaradt.',
      one: '1 mellékletet nem sikerült feltölteni, ezért kimaradt.',
    );
    return '$_temp0';
  }

  @override
  String get teammate => 'Csapattárs';

  @override
  String get agent => 'Ügynök';

  @override
  String get attachFile => 'Fájl csatolása';

  @override
  String get messageHint => 'Üzenet';

  @override
  String removeAttachment(String name) {
    return '$name eltávolítása';
  }

  @override
  String get articlesLoadFailed => 'Nem sikerült betölteni a cikkeket';

  @override
  String get noArticles => 'Nincsenek cikkek';

  @override
  String get articlesEmptyDescription =>
      'Az új cikkek a hírfolyamok frissülésekor jelennek meg itt.';

  @override
  String get unread => 'Olvasatlan';

  @override
  String get allFeeds => 'Minden hírfolyam';

  @override
  String get save => 'Mentés';

  @override
  String get unsave => 'Mentés visszavonása';

  @override
  String get readFullArticle => 'Teljes cikk olvasása';

  @override
  String get ticketsLoadFailed => 'Nem sikerült betölteni a jegyeket';

  @override
  String get noTickets => 'Nincsenek jegyek';

  @override
  String get ticketsEmptyDescription =>
      'A munkaterület jegyei itt jelennek meg.';

  @override
  String get all => 'Mind';

  @override
  String get ticket => 'Jegy';

  @override
  String get ticketLoadFailed => 'Nem sikerült betölteni a jegyet';

  @override
  String assignedTo(String name) {
    return 'Hozzárendelve: $name';
  }

  @override
  String get openInBrowser => 'Megnyitás böngészőben';

  @override
  String get status => 'Állapot';

  @override
  String get assign => 'Hozzárendelés';

  @override
  String get reassign => 'Újra-hozzárendelés';

  @override
  String get noAgents => 'Nincsenek ügynökök';

  @override
  String get noAgentsDescription =>
      'Rendeljen hozzá egy ügynököt ebből a munkaterületből.';

  @override
  String get statusOpen => 'Nyitott';

  @override
  String get statusInProgress => 'Folyamatban';

  @override
  String get statusBlocked => 'Blokkolva';

  @override
  String get statusInReview => 'Átnézés alatt';

  @override
  String get statusDone => 'Kész';

  @override
  String get statusBacklog => 'Backlog';

  @override
  String get lensNeedsMe => 'Rám vár';

  @override
  String get lensMine => 'Saját';

  @override
  String get prsLoadFailed => 'Nem sikerült betölteni a pull requesteket';

  @override
  String get noOpenPullRequests => 'Nincsenek nyitott pull requestek';

  @override
  String get nothingWaitingOnReview => 'Semmi sem vár az átnézésére';

  @override
  String get noOwnOpenPullRequests => 'Nincs nyitott pull requestje';

  @override
  String get nothingBlocked => 'Semmi sincs blokkolva';

  @override
  String get prsEmptyDescription =>
      'A munkaterület repóinak pull requestjei itt jelennek meg.';

  @override
  String get refreshPullRequests => 'Pull requestek frissítése';

  @override
  String get noForgeConnected =>
      'A szerveren nincs csatlakoztatott forge, ezért nem lehet pull requesteket lekérni. Csatlakoztasson egyet az asztali alkalmazásból.';

  @override
  String reposUnreadable(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count repót nem sikerült olvasni.',
      one: '1 repót nem sikerült olvasni.',
    );
    return '$_temp0';
  }

  @override
  String reposNotReadable(String names) {
    return 'Nem olvasható: $names';
  }

  @override
  String get installationSuspendedTitle =>
      'A GitHub App telepítése fel van függesztve';

  @override
  String installationSuspendedBody(String names) {
    return 'A $names utoljára ismert adatai jelennek meg. Folytassa a telepítést a GitHubon, vagy csatlakoztasson hozzáféréssel rendelkező tokent.';
  }

  @override
  String installationSuspendedNotice(String names) {
    return 'A GitHub App telepítése fel van függesztve. A $names utoljára ismert adatai jelennek meg. Folytassa a telepítést a GitHubon, vagy csatlakoztasson hozzáféréssel rendelkező tokent.';
  }

  @override
  String get draft => 'Piszkozat';

  @override
  String get merged => 'Összefésülve';

  @override
  String get closed => 'Lezárva';

  @override
  String get open => 'Nyitott';

  @override
  String get approved => 'Jóváhagyva';

  @override
  String get changesRequested => 'Módosítást kértek';

  @override
  String get reviewRequired => 'Átnézés szükséges';

  @override
  String get checksPassing => 'Ellenőrzések rendben';

  @override
  String get checksFailing => 'Ellenőrzések sikertelenek';

  @override
  String get checksRunning => 'Ellenőrzések futnak';

  @override
  String prSemanticLabel(String title, String status) {
    return '$title, $status';
  }

  @override
  String get pullRequest => 'Pull request';

  @override
  String get prLoadFailed => 'Nem sikerült betölteni ezt a pull requestet';

  @override
  String get openOnForge => 'Megnyitás a forge-on';

  @override
  String get requestChangesNeedsComment =>
      'Adjon megjegyzést, amely elmagyarázza, mit kell változtatni.';

  @override
  String get conversation => 'Beszélgetés';

  @override
  String get files => 'Fájlok';

  @override
  String get checks => 'Ellenőrzések';

  @override
  String labelWithCount(String label, int count) {
    return '$label ($count)';
  }

  @override
  String filesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fájl',
      one: '1 fájl',
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
  String get conflicts => 'Ütközések';

  @override
  String get reviewers => 'Átnézők';

  @override
  String get noDescriptionNoComments =>
      'Még nincs leírás és nincsenek megjegyzések.';

  @override
  String get noChangedFiles => 'Nincsenek módosított fájlok.';

  @override
  String get noChecksReported =>
      'A head commithoz nem jelentettek ellenőrzéseket.';

  @override
  String get reviewCommentHint => 'Hagyjon átnézési megjegyzést…';

  @override
  String get comment => 'Megjegyzés';

  @override
  String get commentPosted => 'Megjegyzés közzétéve';

  @override
  String get request => 'Kérés';

  @override
  String get squashAndMerge => 'Squash és összefésülés';

  @override
  String noActionsAvailable(String status) {
    return '$status — nincs elérhető művelet.';
  }

  @override
  String get reviewApproved => 'jóváhagyta';

  @override
  String get reviewRequestedChanges => 'módosítást kért';

  @override
  String get reviewCommented => 'átnézte';

  @override
  String get reviewPending => 'függőben';

  @override
  String get unknownAuthor => 'ismeretlen';

  @override
  String hideDiffFor(String file) {
    return '$file diffjének elrejtése';
  }

  @override
  String showDiffFor(String file) {
    return '$file diffjének megjelenítése';
  }

  @override
  String get checkRunning => 'fut';

  @override
  String get checkPassed => 'sikeres';

  @override
  String get checkFailed => 'sikertelen';

  @override
  String get checkCancelled => 'törölve';

  @override
  String get checkSkipped => 'kihagyva';

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
      'Ehhez a fájlhoz nincs szöveges diff — bináris, vagy túl nagy ahhoz, hogy a forge visszaadja.';

  @override
  String showRemainingLines(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'A maradék $count sor megjelenítése',
      one: 'A maradék sor megjelenítése',
    );
    return '$_temp0';
  }

  @override
  String unchangedLines(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count változatlan sor',
      one: '1 változatlan sor',
    );
    return '$_temp0';
  }

  @override
  String get jumpToLatest => 'Ugrás a legújabbra';

  @override
  String get streaming => 'Streamelés';

  @override
  String get working => 'Dolgozik';

  @override
  String get input => 'Bemenet';

  @override
  String get output => 'Kimenet';

  @override
  String get now => 'most';

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
  String get today => 'Ma';

  @override
  String get tomorrow => 'Holnap';

  @override
  String get yesterday => 'Tegnap';

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
