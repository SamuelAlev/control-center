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
  String get copyCommand => 'Parancs másolása';

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
  String get newSpaceFolder => 'Új mappa';

  @override
  String get folderName => 'Mappa neve';

  @override
  String get renameSpaceFolder => 'Mappa átnevezése';

  @override
  String get deleteSpaceFolder => 'Mappa törlése';

  @override
  String get moveSpaceToFolder => 'Áthelyezés mappába';

  @override
  String get removeSpaceFromFolder => 'Eltávolítás a mappából';

  @override
  String get spaceFolderActions => 'Mappaműveletek';

  @override
  String get deleteFolderWithSpacesWarning =>
      'A terek végleges törlése mindenki számára eltávolítja az üzeneteiket és a munkafáikat. Ez nem vonható vissza.';

  @override
  String get deleteSpacesInFolder => 'A mappában lévő terek végleges törlése';

  @override
  String get deleteFolderAndSpaces => 'Mappa és terek törlése';

  @override
  String get keepSpacesInFolder =>
      'Ellenkező esetben a terek mappán kívül maradnak.';

  @override
  String get create => 'Létrehozás';

  @override
  String get otherSpaces => 'Egyéb terek';

  @override
  String get folderUpdateFailed => 'Nem sikerült frissíteni a mappákat';

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

  @override
  String get mobileConversations => 'Beszélgetések';

  @override
  String get mobileNewConversation => 'Új beszélgetés';

  @override
  String get mobileConversationName => 'Beszélgetés neve';

  @override
  String get mobileRename => 'Átnevezés';

  @override
  String get mobileManageSpace => 'Tér kezelése';

  @override
  String get mobileArchived => 'Archiválva';

  @override
  String get mobileSearchMessages => 'Keresés a tér összes üzenetében';

  @override
  String get mobileSearch => 'Keresés';

  @override
  String get mobileNoResults => 'Nincs találat';

  @override
  String get mobileReopen => 'Újranyitás';

  @override
  String get mobileArchive => 'Archiválás';

  @override
  String get mobileProgress => 'Haladás és kontextus';

  @override
  String get mobileReadFailed =>
      'Nem sikerült olvasottként megjelölni a beszélgetést';

  @override
  String get mobileSendFailed =>
      'Az üzenet nem ment el. A piszkozat megmaradt.';

  @override
  String get sentAttachmentUnavailable => 'A melléklet nem elérhető';

  @override
  String get sentAttachmentLoadFailed => 'Nem sikerült betölteni a mellékletet';

  @override
  String get mobileActionFailed => 'A művelet sikertelen';

  @override
  String get mobileRemove => 'Eltávolítás';

  @override
  String get mobileLinkedMessage => 'Hivatkozott üzenet';

  @override
  String get mobileOlderMessages => 'Régebbi üzenetek';

  @override
  String get mobileMessageActions => 'Üzenetműveletek';

  @override
  String get mobileOpenThread => 'Szál megnyitása';

  @override
  String get mobileCopyLink => 'Hivatkozás másolása';

  @override
  String get mobileStopRun => 'Futtatás leállítása';

  @override
  String get mobileStopRunConfirm =>
      'Leállítja az ügynök futtatását? Az eddig elvégzett munka megmarad.';

  @override
  String get mobileControlUnsupported =>
      'Ez a futtatás befejeződött, vagy nem támogatja ezt a vezérlést.';

  @override
  String get mobilePauseRequested =>
      'Szüneteltetés kérése a következő forduló végén';

  @override
  String get mobileResumed => 'Futtatás folytatva';

  @override
  String get mobileStopRequested => 'Leállítás kérve';

  @override
  String get mobileQueuedMessages => 'Várólistás üzenetek';

  @override
  String get mobilePauseRun => 'Szüneteltetés a következő forduló után';

  @override
  String get mobileResumeRun => 'Folytatás';

  @override
  String get mobileEditQueued => 'Várólistás üzenet szerkesztése';

  @override
  String get mobileSteerNow => 'Irányítás most';

  @override
  String get mobileMoveUp => 'Mozgatás fel';

  @override
  String get mobileMoveDown => 'Mozgatás le';

  @override
  String get mobileQueueChanged =>
      'A várólista megváltozott, vagy ez a futtatás nem fogad élő irányítást. Frissítsen, és próbálja újra.';

  @override
  String get mobileActivity => 'Tevékenység';

  @override
  String get mobilePermissions => 'Engedélyek és napló';

  @override
  String get mobilePlans => 'Tervek';

  @override
  String get mobileGoals => 'Felügyelt célok';

  @override
  String get mobileCredentials => 'Kapcsolatok és hitelesítő adatok';

  @override
  String get mobileWorkspaceUnavailable =>
      'Ez a munkaterület nem érhető el, vagy már nincs hozzáférése.';

  @override
  String get mobilePrReviewThreads => 'Átnézési szálak';

  @override
  String get mobilePrThreadsLoadFailed =>
      'Nem sikerült betölteni az átnézési szálakat';

  @override
  String get mobilePrNoReviewThreads => 'Még nincsenek sorközi átnézési szálak';

  @override
  String get mobilePrCommentPermissionDenied =>
      'Nincs jogosultsága hozzászólni ehhez a tárolóhoz.';

  @override
  String get mobilePrPermissionChecking =>
      'Hozzászólási jogosultság ellenőrzése…';

  @override
  String get mobilePrPermissionLoadFailed =>
      'Nem sikerült ellenőrizni a hozzászólási jogosultságot. Próbálja újra.';

  @override
  String mobilePrThreadLine(String side, String line) {
    return '$side oldal, $line. sor';
  }

  @override
  String get mobilePrOriginalSide => 'Eredeti';

  @override
  String get mobilePrSelectCommentLine => 'Válasszon sort a hozzászóláshoz';

  @override
  String get mobilePrUpdatedSide => 'Frissítve';

  @override
  String get mobilePrThreadResolved => 'Megoldva';

  @override
  String get mobilePrReplyHint => 'Válasz írása…';

  @override
  String get mobilePrCommentRequired => 'Küldés előtt írjon hozzászólást.';

  @override
  String get mobilePrReply => 'Válasz';

  @override
  String get mobilePrReopenThread => 'Szál újranyitása';

  @override
  String get mobilePrResolveThread => 'Szál lezárása';

  @override
  String get mobilePrResolvePermissionDenied =>
      'Csak a pull request szerzője vagy írási jogosultsággal rendelkező személy zárhatja le ezt a szálat.';

  @override
  String mobilePrCommentOnLine(String side, String line) {
    return 'Hozzászólás: $side oldal, $line. sor';
  }

  @override
  String get mobilePrInlineCommentHint => 'Sorközi hozzászólás írása…';

  @override
  String get mobilePrPostInlineComment => 'Hozzászólás küldése';

  @override
  String get mobilePrCommentUnavailable =>
      'Ehhez a pull requesthez nem lehet sorközi hozzászólást írni.';

  @override
  String get mobilePrPatchUnavailable =>
      'A szolgáltató nem adott szöveges javítást ehhez a fájlhoz.';

  @override
  String get mobilePrNoPatchForFile => 'A fájl javítása nem érhető el.';

  @override
  String get mobileTicketNew => 'Új jegy';

  @override
  String get mobileTicketCreate => 'Jegy létrehozása';

  @override
  String get mobileTicketEdit => 'Jegy szerkesztése';

  @override
  String get mobileTicketTitle => 'Cím';

  @override
  String get mobileTicketTitleRequired => 'A jegy mentéséhez adjon meg címet.';

  @override
  String get mobileTicketDescription => 'Leírás';

  @override
  String get mobileTicketMarkdownHint => 'Részletek hozzáadása Markdownban';

  @override
  String get mobileTicketPriority => 'Prioritás';

  @override
  String get mobileTicketPriorityNone => 'Nincs prioritás';

  @override
  String get mobileTicketPriorityUrgent => 'Sürgős';

  @override
  String get mobileTicketPriorityHigh => 'Magas';

  @override
  String get mobileTicketPriorityMedium => 'Közepes';

  @override
  String get mobileTicketPriorityLow => 'Alacsony';

  @override
  String get mobileTicketLabels => 'Címkék';

  @override
  String get mobileTicketLabelsHint => 'Soronként egy címke';

  @override
  String get mobileTicketLabelsHelp => 'Minden címkét külön sorba írjon.';

  @override
  String mobileTicketWorkspaceProvider(String provider) {
    return 'Rögzítve itt: $provider';
  }

  @override
  String get mobileTicketProviderLocal => 'Control Center';

  @override
  String get mobileTicketUnassigned => 'Nincs hozzárendelve';

  @override
  String get mobileTicketAssignedFilter => 'Hozzárendelve';

  @override
  String get mobileTicketAgentsLoadFailed =>
      'Nem sikerült betölteni az ügynököket';

  @override
  String get mobileTicketSearch => 'Jegyek keresése';

  @override
  String get mobileTicketSearchHint =>
      'Cím, azonosító, leírás, címke vagy felelős';

  @override
  String get mobileTicketClearSearch => 'Jegykeresés törlése';

  @override
  String get mobileTicketNoMatches => 'Nincs megfelelő jegy';

  @override
  String get mobileTicketAdjustFilters =>
      'Próbáljon másik keresést, vagy módosítsa a szűrőket.';

  @override
  String get mobileTicketClearFilters => 'Szűrők törlése';

  @override
  String get mobileTicketNotFound => 'A jegy nem található';

  @override
  String get mobileTicketNotFoundDescription =>
      'Lehet, hogy a jegyet törölték, vagy áthelyezték ebből a munkaterületből.';

  @override
  String get mobileTicketWorkspaceChanged =>
      'A munkaterület megváltozott. Mentés előtt térjen vissza az aktuális munkaterülethez.';

  @override
  String get mobileTicketOpenLinkedSpace => 'Kapcsolódó tér megnyitása';

  @override
  String get mobileTicketReadOnly =>
      'A jegyek módosításához munkaterületi tagság szükséges.';

  @override
  String get permissionTitle => 'Engedélyek';

  @override
  String get permissionWorkspaceFailed =>
      'Nem sikerült betölteni a munkaterületet';

  @override
  String get permissionNoWorkspace =>
      'Válasszon munkaterületet az engedélyek megtekintéséhez.';

  @override
  String get permissionLoading => 'Engedélyek betöltése…';

  @override
  String get permissionScopeDescription =>
      'Nézze meg, hogyan dőlnek el a műveletek ezen a szinten. A munkaterületi szabályokat az ügynökök és terek örökölhetik.';

  @override
  String get permissionScope => 'Szabály hatóköre';

  @override
  String get permissionWorkspaceScope => 'Munkaterület';

  @override
  String get permissionAgentScope => 'Ügynök';

  @override
  String get permissionSpaceScope => 'Tér';

  @override
  String get permissionAgentContext => 'Ebben a térben eljáró ügynök';

  @override
  String get permissionNoAgentContext => 'Nincs kiválasztott ügynök';

  @override
  String get permissionTargetsFailed =>
      'Nem sikerült betölteni a hatókör célpontjait';

  @override
  String get permissionNoTargets => 'Ezen a szinten nincs elérhető célpont.';

  @override
  String get permissionRoleFailed =>
      'Nem sikerült megerősíteni a munkaterületi szerepkörét';

  @override
  String get permissionMemberRequired =>
      'A szabályok megtekintéséhez munkaterületi tagság szükséges.';

  @override
  String get permissionRulesFailed => 'Nem sikerült betölteni a szabályokat';

  @override
  String get permissionAuditAdminOnly =>
      'A jogosultsági előzményeket csak a munkaterület adminisztrátorai láthatják.';

  @override
  String get permissionAllow => 'Engedélyezés';

  @override
  String get permissionAsk => 'Előbb kérdezzen';

  @override
  String get permissionDeny => 'Tiltás';

  @override
  String get permissionFileDelete => 'Fájlok törlése';

  @override
  String get permissionFileWriteOutsideWorktree => 'Írás a munkafán kívül';

  @override
  String get permissionGitCommit => 'Módosítások commitolása';

  @override
  String get permissionGitPush => 'Commitok feltöltése';

  @override
  String get permissionPrCreate => 'Pull requestek létrehozása';

  @override
  String get permissionPrPublish => 'Pull requestek közzététele';

  @override
  String get permissionVendorSyncWrite => 'Szolgáltatói szinkron írása';

  @override
  String get permissionNetworkEgress => 'Hálózati hozzáférés';

  @override
  String get permissionSecretAccess => 'Titkos adatok elérése';

  @override
  String get permissionPackageInstall => 'Csomagok telepítése';

  @override
  String get permissionProcessSpawn => 'Folyamatok indítása';

  @override
  String get permissionWorkspaceMutation => 'Munkaterület módosítása';

  @override
  String get permissionEnclosureControl => 'Elkülönített környezet vezérlése';

  @override
  String get permissionChangeFailed => 'Nem sikerült módosítani a szabályt';

  @override
  String get permissionEffectiveDescription =>
      'Ezen a szinten műveleti argumentumok nélkül érvényes. Az alábbi feltételes engedélyek csak az egyező kérésekre vonatkoznak; a végső döntést a szerver hozza meg.';

  @override
  String get permissionSpaceAgentNote =>
      'Nincs kiválasztott ügynök. Az ügynökspecifikus szabályok a fenti választásig nem láthatók.';

  @override
  String get permissionScopedGrants => 'Szabályok ezen a szinten';

  @override
  String get permissionModePreset => 'Módkészlet';

  @override
  String get permissionBuiltInDefault => 'Beépített alapértelmezett';

  @override
  String get permissionRemembered => 'Megjegyzett jóváhagyás';

  @override
  String get permissionSource => 'Forrás';

  @override
  String permissionSetAtThisScope(String source) {
    return '$source · itt beállítva';
  }

  @override
  String permissionInheritedFrom(String source) {
    return '$source · örökölt';
  }

  @override
  String permissionExpiresAt(String date) {
    return 'Lejár: $date';
  }

  @override
  String get permissionSetHere => 'Szabály beállítása itt';

  @override
  String get permissionRevokeBeforeEdit =>
      'A művelet általános szabályának beállítása előtt vonja vissza a hatókörhöz kötött vagy megjegyzett szabályt.';

  @override
  String get permissionConfirmRevoke => 'Visszavonás megerősítése';

  @override
  String get permissionRevokeRule => 'Szabály visszavonása';

  @override
  String permissionCommandPrefix(String prefix) {
    return 'Parancselőtag: $prefix';
  }

  @override
  String get permissionNoExpiry => 'Nincs lejárat';

  @override
  String get permissionExpired => 'Lejárt';

  @override
  String get permissionExplicitRule => 'Kifejezett szabály';

  @override
  String get permissionEnforcementAdvisory =>
      'Tájékoztató: az előzetes jóváhagyást kérő szabályokat kérdés nélkül naplózzuk';

  @override
  String get permissionEnforcementSoft =>
      'Rugalmas érvényesítés: a felülbíráláshoz engedély szükséges';

  @override
  String get permissionEnforcementHard =>
      'Szigorú érvényesítés: nem bírálható felül';

  @override
  String permissionPaths(String paths) {
    return 'Útvonalak: $paths';
  }

  @override
  String permissionRefs(String refs) {
    return 'Git-referenciák: $refs';
  }

  @override
  String permissionHosts(String hosts) {
    return 'Hosztok: $hosts';
  }

  @override
  String permissionCommands(String commands) {
    return 'Parancsok: $commands';
  }

  @override
  String permissionMaxCount(String count) {
    return 'Legnagyobb darabszám: $count';
  }

  @override
  String permissionMaxCents(String cents) {
    return 'Legnagyobb összeg centben: $cents';
  }

  @override
  String get permissionAuditHeading => 'Jogosultsági előzmények';

  @override
  String get permissionAuditDescription =>
      'A szerver által rögzített legutóbbi döntések. A naplót és a hash-láncot csak adminisztrátorok ellenőrizhetik.';

  @override
  String permissionOnBehalfOf(String user) {
    return '$user nevében';
  }

  @override
  String get permissionPrompted => 'Emberi jóváhagyást kértek';

  @override
  String get permissionVerifyChain => 'Naplólánc ellenőrzése';

  @override
  String get permissionVerifyFailed => 'Nem sikerült ellenőrizni a naplóláncot';

  @override
  String permissionChainIntact(String count) {
    return 'A lánc sértetlen · $count bejegyzés ellenőrizve';
  }

  @override
  String permissionChainBroken(String sequence, String reason) {
    return 'A lánc megszakadt a(z) $sequence. bejegyzésnél: $reason';
  }

  @override
  String get permissionAuditEmpty => 'Még nincs rögzített jogosultsági döntés.';

  @override
  String get permissionAuditFailed =>
      'Nem sikerült betölteni a jogosultsági előzményeket';

  @override
  String get mobilePlansLoadFailed => 'Nem sikerült betölteni a terveket';

  @override
  String get mobilePlansEmpty => 'Még nincsenek tervek';

  @override
  String get mobilePlansEmptyDescription =>
      'Az ügynökök által beküldött tervek itt jelennek meg átnézésre.';

  @override
  String get mobilePlanTitle => 'Terv';

  @override
  String get mobilePlanMissing =>
      'Ez a terv már nem érhető el ebben a munkaterületben.';

  @override
  String mobilePlanStepCount(int count) {
    return '$count lépés';
  }

  @override
  String get mobilePlanDraft => 'Piszkozat';

  @override
  String get mobilePlanProposed => 'Átnézésre vár';

  @override
  String get mobilePlanApproved => 'Jóváhagyva';

  @override
  String get mobilePlanRejected => 'Elutasítva';

  @override
  String get mobilePlanSuperseded => 'Felülírva';

  @override
  String get mobilePlanExecuting => 'Végrehajtás';

  @override
  String get mobilePlanSynthesizing => 'Összegzés';

  @override
  String get mobilePlanCompleted => 'Befejezve';

  @override
  String get mobilePlanFailed => 'Sikertelen';

  @override
  String get mobilePlanCancelled => 'Megszakítva';

  @override
  String mobilePlanRevision(String revision) {
    return '$revision. revízió';
  }

  @override
  String get mobilePlanSteps => 'Lépések';

  @override
  String get mobilePlanNoSteps => 'Ehhez a tervhez nem adtak meg lépéseket.';

  @override
  String get mobilePlanAssumptions => 'Pontosítások';

  @override
  String mobilePlanDependsOn(String keys) {
    return 'Függ ettől: $keys';
  }

  @override
  String mobilePlanStepCost(String cost) {
    return 'Becsült felső költség: $cost';
  }

  @override
  String get mobilePlanSelect => 'Kiválasztás';

  @override
  String get mobilePlanSelected => 'Kiválasztva';

  @override
  String get mobilePlanEstimate => 'Költség becslése';

  @override
  String get mobilePlanEstimateRequired =>
      'A végrehajtás jóváhagyása előtt becsülje meg a terv költségét.';

  @override
  String mobilePlanEstimatedCost(String low, String high) {
    return 'Becsült költség: $low–$high';
  }

  @override
  String get mobilePlanCostUnknown => 'nem érhető el';

  @override
  String get mobilePlanNoHardCap => 'nincs szigorú felső korlát';

  @override
  String get mobilePlanExceedsBudget =>
      'A becslés meghaladja a beállított keretet. Jóváhagyás előtt nézze át.';

  @override
  String get mobilePlanPartialEstimate =>
      'A becslés a teljes tervre vonatkozik; a kiválasztott lépések kevesebbe kerülhetnek.';

  @override
  String get mobilePlanConfirmAll => 'Elindítja a teljes tervet?';

  @override
  String get mobilePlanConfirmSelected => 'Elindítja a kiválasztott lépéseket?';

  @override
  String mobilePlanExecutionConfirmation(String cost, String cap) {
    return 'A jóváhagyás elindítja a végrehajtást, és költséggel járhat. Becsült maximális költség: $cost. Költségkeret: $cap.';
  }

  @override
  String get mobilePlanApproveAll => 'Összes jóváhagyása és futtatása';

  @override
  String get mobilePlanApproveSelected =>
      'Kiválasztottak jóváhagyása és futtatása';

  @override
  String get mobilePlanWiden => 'További lépések jóváhagyása';

  @override
  String mobilePlanWidenConfirm(String count, String cap) {
    return 'Engedélyezi további $count lépés végrehajtását? Ez költséggel járhat. A meglévő végrehajtás költségkorlátja: $cap.';
  }

  @override
  String get mobilePlanChanged =>
      'A terv átnézés közben megváltozott. Nyissa meg a legújabb változatot, és becsülje meg újra.';

  @override
  String get mobilePlanReject => 'Terv elutasítása';

  @override
  String get mobilePlanRejectConfirm =>
      'Elutasítja ezt a tervet? Nem lesz végrehajtva.';

  @override
  String get mobilePlanStop => 'Végrehajtás leállítása';

  @override
  String get mobilePlanStopConfirm =>
      'Leállítja a terv végrehajtását? Az eddig elvégzett munka nem vonható vissza.';

  @override
  String mobilePlanRunId(String runId) {
    return 'Végrehajtási futtatás: $runId';
  }

  @override
  String get mobilePlanExecutionPending =>
      'Jóváhagyás elfogadva. Várakozás a végrehajtási rekordra…';

  @override
  String mobilePlanProgress(String completed, String total) {
    return '$completed / $total végrehajtási lépés kész';
  }

  @override
  String get mobilePlanOpenConversation => 'Beszélgetés megnyitása';

  @override
  String get mobileGoalsTitle => 'Felügyelt célok';

  @override
  String get mobileGoalsLoadFailed =>
      'Nem sikerült betölteni a felügyelt célokat';

  @override
  String get mobileGoalsEmpty => 'Még nincsenek felügyelt célok';

  @override
  String get mobileGoalsEmptyDescription =>
      'Indítson egyet egy térben, vagy küldje el a /goal parancsot egy beszélgetésben.';

  @override
  String get mobileGoalMissing =>
      'Ez a cél már nem érhető el ebben a munkaterületben.';

  @override
  String get mobileGoalActive => 'Aktív';

  @override
  String get mobileGoalPaused => 'Szüneteltetve';

  @override
  String get mobileGoalCompleted => 'Befejezve';

  @override
  String get mobileGoalFailed => 'Sikertelen';

  @override
  String get mobileGoalCancelled => 'Megszakítva';

  @override
  String get mobileGoalBudgetExhausted => 'Költségkeret elérve';

  @override
  String get mobileGoalGoal => 'Cél';

  @override
  String get mobileGoalLoop => 'Ciklus';

  @override
  String mobileGoalKind(String kind) {
    return 'Típus: $kind';
  }

  @override
  String mobileGoalRuns(String count) {
    return '$count futtatás';
  }

  @override
  String get mobileGoalNoRunLimit => 'korlátlan';

  @override
  String mobileGoalProgress(
    String runs,
    String maxRuns,
    String spent,
    String cap,
  ) {
    return 'Futtatások: $runs / $maxRuns · Felhasználva: $spent / $cap';
  }

  @override
  String mobileGoalDeadline(String date) {
    return 'Határidő: $date';
  }

  @override
  String mobileGoalFailures(String count) {
    return 'Egymást követő sikertelen futtatások: $count';
  }

  @override
  String get mobileGoalSummary => 'Befejezési összefoglaló';

  @override
  String get mobileGoalFailedDescription =>
      'A felügyelő az ismétlődő sikertelen futtatások után leállt. A részleteket a beszélgetésben találja.';

  @override
  String get mobileGoalBudgetWall =>
      'Lejárt a határidő, vagy elfogyott a futtatási keret. A cél nem folytatható a költségkorlát emelésével.';

  @override
  String get mobileGoalPause => 'Cél szüneteltetése';

  @override
  String get mobileGoalResume => 'Cél folytatása';

  @override
  String get mobileGoalStop => 'Cél megszakítása';

  @override
  String get mobileGoalStopConfirm =>
      'Végleg megszakítja ezt a felügyelt célt? Nem folytatható.';

  @override
  String get mobileGoalRaiseBudget => 'Keret emelése és folytatás';

  @override
  String mobileGoalRaiseTo(String amount) {
    return 'Keret emelése $amount értékre és folytatás';
  }

  @override
  String mobileGoalRaiseConfirm(String oldCap, String newCap) {
    return '$oldCap értékről $newCap értékre emeli a cél költségkorlátját, és folytatja a költést?';
  }

  @override
  String get mobileGoalOpenConversation => 'Célbeszélgetés megnyitása';

  @override
  String get mobileGoalCreate => 'Felügyelt cél indítása';

  @override
  String get mobileGoalChooseSpace => 'Futtatás térben';

  @override
  String get mobileGoalNoSpaces => 'Cél indítása előtt hozzon létre egy teret.';

  @override
  String get mobileGoalChooseAgent => 'Futtatás ügynökkel';

  @override
  String get mobileGoalNoAgents =>
      'Cél indítása előtt adjon hozzá egy aktív ügynököt.';

  @override
  String mobileGoalSelectedAgent(String name) {
    return 'Kiválasztva: $name';
  }

  @override
  String get mobileGoalObjectiveHint => 'Milyen eredményt érjen el az ügynök?';

  @override
  String get mobileGoalBudgetUsd => 'Költségkorlát (USD)';

  @override
  String get mobileGoalCreateInvalid =>
      'Válasszon teret és ügynököt, adjon meg célt és pozitív USD-költségkorlátot.';

  @override
  String mobileGoalCreateConfirm(String cap) {
    return 'Elindít egy felügyelt célt legfeljebb $cap költséggel? Az ügynök azonnal elkezdheti.';
  }

  @override
  String get mobileGoalUnavailable =>
      'A szerverkapcsolat még nem áll készen. Csatlakozás után próbálja újra.';

  @override
  String get mobileGoalConversationMissing =>
      'A kiválasztott beszélgetés már nem érhető el ebben a munkaterületben.';

  @override
  String get mobileGoalCreateSent =>
      'A cél elindult. A felügyelő állapota megjelenik ebben a listában.';

  @override
  String get mobileGoalStartRefused =>
      'Nem indult célfuttatás. A felügyelő indokát a beszélgetésben találja.';

  @override
  String mobileGoalSelectedSpace(String name) {
    return 'Kiválasztva: $name';
  }

  @override
  String get requestUnavailable =>
      'Ez a kérés már nem érhető el az aktív munkaterületen.';

  @override
  String get requestAlreadyResolved => 'Ezt a kérést már elbírálták.';

  @override
  String get inboxCredentialsBlocked =>
      'Hitelesítő adatok miatt blokkolt futtatások';

  @override
  String get inboxSyncFailures => 'Sikertelen szolgáltatói szinkronok';

  @override
  String get inboxConfigureCredentials => 'Hitelesítő adatok beállítása';

  @override
  String get openTicket => 'Jegy megnyitása';

  @override
  String get activityTitle => 'Tevékenység';

  @override
  String get activityClearAll => 'Tevékenység törlése';

  @override
  String get activityClearConfirm =>
      'Ezzel az eddig rögzített összes tevékenység eltűnik az Ön minden eszközén. Az új tevékenységek továbbra is megjelennek.';

  @override
  String get activityMarkAllRead => 'Összes megjelölése olvasottként';

  @override
  String get activityMarkAllConfirm =>
      'Minden tevékenységet olvasottként jelöl ezen a munkaterületen, minden eszközén?';

  @override
  String get activityMarkRead => 'Megjelölés olvasottként';

  @override
  String get activityMarkUnread => 'Megjelölés olvasatlanként';

  @override
  String get activityDismiss => 'Elvetés';

  @override
  String get activityResolved => 'Megoldva';

  @override
  String get activityOpen => 'Nyitott';

  @override
  String get activityEmpty => 'Még nincs tevékenység';

  @override
  String get activityLoadFailed => 'Nem sikerült betölteni a tevékenységeket';

  @override
  String get activityAgentWaiting => 'Az ügynök bevitelre vár';

  @override
  String get activityAgentBlocked => 'Az ügynök művelete blokkolva';

  @override
  String get activityMessage => 'Új üzenet';

  @override
  String get activityPullRequest => 'Pull request frissítése';

  @override
  String get activityTicket => 'Jegy frissítése';

  @override
  String get activityMeeting => 'Megbeszélés frissítése';

  @override
  String get activityCalendar => 'Naptárkapcsolat';

  @override
  String get activityRig => 'Elkülönített környezet frissítése';

  @override
  String get activityEvent => 'Frissítés';

  @override
  String get activityPrReady => 'A pull request összefésülhető';

  @override
  String get activityPrBlocked => 'A pull request összefésülése blokkolva';

  @override
  String get activityPrApproved => 'Pull request jóváhagyva';

  @override
  String get activityPrChanges => 'Módosítást kértek';

  @override
  String get activityPrChecksFailed =>
      'A pull request ellenőrzései sikertelenek';

  @override
  String get activityPrChecksRecovered =>
      'A pull request ellenőrzései ismét sikeresek';

  @override
  String get activityPrComment => 'Hozzászólás pull requesthez';

  @override
  String get activityPrPublished => 'Pull request közzétéve';

  @override
  String get activityPrMerged => 'Pull request összefésülve';

  @override
  String get activityPrMentioned => 'Megemlítették egy pull requestben';

  @override
  String get activityPrReviewRequested => 'Átnézést kértek';

  @override
  String get activityPrReviewStale => 'Az átnézést frissíteni kell';

  @override
  String get activityTicketAssigned => 'Jegy hozzárendelve';

  @override
  String get activityTicketChanged => 'Jegy állapota megváltozott';

  @override
  String get activityMeetingSoon => 'Hamarosan kezdődő megbeszélés';

  @override
  String get activityCalendarExpired => 'A naptárkapcsolat lejárt';

  @override
  String get activityRigControl =>
      'Az elkülönített környezet vezérlése megváltozott';

  @override
  String get activityRigClosed => 'Az elkülönített környezet leállt';

  @override
  String get mobileSpacesSearch => 'Terek keresése';

  @override
  String get mobileSpacesArchived => 'Archiválva';

  @override
  String get mobileSpacesActive => 'Aktív';

  @override
  String get mobileSpacesNew => 'Új tér';

  @override
  String get mobileSpacesManage => 'Tér kezelése';

  @override
  String get mobileSpacesName => 'Tér neve';

  @override
  String get mobileSpacesAgents => 'Ügynökök';

  @override
  String get mobileSpacesMembers => 'Emberek';

  @override
  String get mobileSpacesRepos => 'Tárolók';

  @override
  String get mobileSpacesAllRepos => 'Összes kapcsolódó tároló';

  @override
  String get mobileSpacesNoRepos => 'Nincsenek tárolók';

  @override
  String get mobileSpacesBaseBranch => 'Alapág (nem kötelező)';

  @override
  String get mobileSpacesDefaultBranch => 'Alapértelmezett ág';

  @override
  String get mobileSpacesMode => 'Mód';

  @override
  String get mobileSpacesModeChat => 'Csevegés';

  @override
  String get mobileSpacesModeReview => 'Átnézés (csak olvasás)';

  @override
  String get mobileSpacesModePlan => 'Tervezés (csak olvasás)';

  @override
  String get mobileSpacesModeOrchestrate => 'Orchestrálás';

  @override
  String get mobileSpacesAutonomy => 'Autonómia felülbírálása';

  @override
  String get mobileSpacesAutonomyInherited => 'Örökölt';

  @override
  String get mobileSpacesAutonomyPropose => 'Csak javaslat';

  @override
  String get mobileSpacesAutonomyApproval => 'Cselekvés jóváhagyással';

  @override
  String get mobileSpacesAutonomyFreely => 'Szabad cselekvés';

  @override
  String get mobileSpacesAutonomyNotice =>
      'A felülbírálás nem kerülheti meg a műveleti szabályok jóváhagyási kéréseit vagy tiltásait. Csak a munkaterület adminisztrátorai módosíthatják.';

  @override
  String get mobileSpacesArchive => 'Tér archiválása';

  @override
  String get mobileSpacesReopen => 'Tér újranyitása';

  @override
  String get mobileSpacesSave => 'Módosítások mentése';

  @override
  String get mobileSpacesCreate => 'Tér létrehozása';

  @override
  String get mobileSpacesOperationFailed => 'Nem sikerült frissíteni a teret';

  @override
  String get mobileSpacesMissing =>
      'A tér nem található ebben a munkaterületben';

  @override
  String get mobileSpacesEmptyName => 'Adja meg a tér nevét';

  @override
  String get mobileSpacesNoMatches => 'Nincs megfelelő tér';

  @override
  String get mobileSpacesUnread => 'Olvasatlan ügynökválasz';

  @override
  String get mobileSpacesNeedsInput => 'Az Ön válaszára vár';

  @override
  String get mobileSpacesRunning => 'Ügynök fut';

  @override
  String get mobileSpacesNoAgents =>
      'Nincsenek ügynökök ebben a munkaterületben';

  @override
  String get mobileSpacesNoMembers => 'Nincsenek más munkaterületi tagok';

  @override
  String get mobileSpacesRepoError => 'Nem sikerült betölteni a tárolókat';

  @override
  String get mobileSpacesRetry => 'Újrapróbálás';

  @override
  String get mobileSpacesBranchUnavailable =>
      'Tér létrehozásakor válasszon vagy adjon meg egy alapágat; a meglévő terek alapága nem módosítható.';

  @override
  String get mobileSpacesArchivedEmpty => 'Nincsenek archivált terek';

  @override
  String get mobileSpacesAllRepoWarning =>
      'Az újonnan kapcsolt munkaterületi tárolók is bekerülnek ebbe a térbe.';

  @override
  String get mobileSpacesCreatedRetry =>
      'A tér létrejött. Próbálja meg újra hozzáadni az embereket, vagy nyissa meg a kezelőoldalát.';

  @override
  String get progressTitle => 'Haladás';

  @override
  String get progressConversation => 'Beszélgetés';

  @override
  String get progressLoadFailed => 'Nem sikerült betölteni a haladást';

  @override
  String get progressUnavailable => 'A beszélgetés nem érhető el';

  @override
  String get progressUnavailableDescription =>
      'Ez a beszélgetés nincs az aktív munkaterületen és térben. A folytatáshoz térjen vissza a terébe.';

  @override
  String get progressSaveFailed => 'Nem sikerült frissíteni a haladást';

  @override
  String get progressGoal => 'Cél';

  @override
  String get progressNoGoal => 'Nincs kitűzött munkacél';

  @override
  String get progressSetGoal => 'Cél beállítása';

  @override
  String get progressEditGoal => 'Cél szerkesztése';

  @override
  String get progressClearGoal => 'Cél törlése';

  @override
  String get progressGoalRequired => 'Mentés előtt adjon meg célt.';

  @override
  String get progressTodos => 'Feladatok';

  @override
  String get transcriptToolTodos => 'Feladatok';

  @override
  String get transcriptToolSearchMemory => 'Keresés a memóriában';

  @override
  String get transcriptToolRenderMedia => 'Média megjelenítése';

  @override
  String get progressNoTodos => 'Még nincsenek feladatok';

  @override
  String get progressNewTodo => 'Új feladat';

  @override
  String get progressAddTodo => 'Feladat hozzáadása';

  @override
  String get progressEditTodo => 'Feladat szerkesztése';

  @override
  String get progressTodoRequired => 'Mentés előtt adjon meg feladatot.';

  @override
  String get progressTodoNoLongerExists =>
      'A feladatot eltávolították. Töltse be újra a listát, és próbálja újra.';

  @override
  String get progressWorkspaceChanged =>
      'Az aktív munkaterület megváltozott. Térjen vissza ehhez a beszélgetéshez, és próbálja újra.';

  @override
  String progressRemoveTodo(String name) {
    return 'Feladat eltávolítása: $name';
  }

  @override
  String get progressPending => 'Függőben';

  @override
  String get progressInProgress => 'Folyamatban';

  @override
  String get progressCompleted => 'Befejezve';

  @override
  String get progressMoveUp => 'Feladat mozgatása fel';

  @override
  String get progressMoveDown => 'Feladat mozgatása le';

  @override
  String get progressRunTree => 'Ügynökfuttatások';

  @override
  String get progressNoRuns => 'Ebben a beszélgetésben még nem volt futtatás';

  @override
  String get progressRunning => 'Fut';

  @override
  String get progressFailed => 'Sikertelen';

  @override
  String get progressUnknown => 'Ismeretlen';

  @override
  String get progressHealthy => 'Aktív';

  @override
  String get progressBlocked => 'Blokkolva';

  @override
  String get progressLooping => 'Ciklusban fut';

  @override
  String get progressStalled => 'Elakadt';

  @override
  String get progressDead => 'Váratlanul leállt';

  @override
  String get progressQuiet => 'Még nincs kimenet';

  @override
  String get progressCostReported => 'Szolgáltató által jelentett költség';

  @override
  String get progressCostNotional => 'Elméleti előfizetési listaár; nem számla';

  @override
  String get progressCostMixed => 'Vegyes költségforrások';

  @override
  String get progressCostEstimated => 'Becsült költség';

  @override
  String progressDurationSeconds(String seconds) {
    return '$seconds mp';
  }

  @override
  String progressRunDetails(String model, String duration, String cost) {
    return 'Modell: $model · Idő: $duration · Költség: $cost';
  }

  @override
  String progressStartedAt(String time) {
    return 'Elindítva $time';
  }

  @override
  String progressLiveness(String state) {
    return 'Állapot: $state';
  }

  @override
  String progressRunTokens(String input, String output) {
    return 'Bemenet: $input · Kimenet: $output token';
  }

  @override
  String get progressOutputPreviewLimited =>
      'A strukturált kimenetnek csak az első 6000 karaktere látható.';

  @override
  String progressRetryOf(String runId) {
    return 'A(z) $runId futtatás újrapróbálása';
  }

  @override
  String get progressContext => 'Kontextus és korlátok';

  @override
  String get progressNoAgent => 'Nincs megtekinthető ügynök';

  @override
  String progressContextReading(String used, String window) {
    return '$used / $window token';
  }

  @override
  String get progressMeasured =>
      'A szolgáltató által jelentett kontextus a legutóbbi híváskor';

  @override
  String get progressEstimated =>
      'A tárolt beszélgetés és az állandó kontextus alapján becsülve';

  @override
  String get progressContextUnknown =>
      'A kontextushasználatot még nem jelentették';

  @override
  String progressContextPercent(String percent) {
    return 'A kontextusablak $percent%-a';
  }

  @override
  String progressMonthlyBudget(String amount) {
    return 'Beállított havi ügynökkorlát: $amount';
  }

  @override
  String progressConversationTokens(String tokens) {
    return 'Tárolt aktív beszélgetés: becslés szerint $tokens token';
  }

  @override
  String progressInspectionFor(String agent, String model) {
    return 'Állandó kontextus: $agent · $model';
  }

  @override
  String get progressContextSystem => 'Rendszerprompt';

  @override
  String get progressContextRules => 'Szabályok';

  @override
  String get progressContextSkills => 'Készségek';

  @override
  String get progressContextTools => 'Eszközdefiníciók';

  @override
  String get progressContextMcp => 'MCP-eszközök';

  @override
  String get progressContextDeferred => 'Késleltetett eszközök';

  @override
  String get progressContextSubagents => 'Alügynökök';

  @override
  String get progressContextRunner => 'Külső futtató';

  @override
  String get progressContextMemory => 'Memória';

  @override
  String get progressContextHistory => 'Beszélgetési előzmények';

  @override
  String progressContextSegment(String label, String tokens) {
    return '$label · $tokens token';
  }

  @override
  String progressContextPart(String title, String tokens) {
    return '$title · $tokens token';
  }

  @override
  String get progressOutputs => 'Legutóbbi kimenetek';

  @override
  String get progressNoOutputs => 'Nincs újabb ügynökkimenet';

  @override
  String get progressStructuredOutputsAbove =>
      'A strukturált futtatási kimenetek a fenti ügynökfuttatásoknál láthatók.';

  @override
  String get progressRecentOutputsOnly =>
      'Csak a legutóbbi üzenetek láthatók. A régebbi munkához nyissa meg a beszélgetést.';

  @override
  String get progressPlan => 'Terv';

  @override
  String get progressArtifact => 'Artifact';

  @override
  String get progressResult => 'Eredmény';

  @override
  String get progressHideArtifact => 'Artifact elrejtése';

  @override
  String get progressReadArtifact => 'Artifact megnyitása';

  @override
  String get progressArtifactUnavailable => 'Az artifact már nem érhető el';

  @override
  String get progressArtifactPreviewLimited =>
      'Az artifactból csak korlátozott előnézet látható.';

  @override
  String get progressDiagramSource => 'Diagram forrása';

  @override
  String progressOpenAttachment(String name) {
    return '$name megnyitása';
  }

  @override
  String get progressOpenPlan => 'Terv megnyitása';

  @override
  String progressOpenDiff(String label) {
    return 'Módosított fájlok átnézése: $label';
  }

  @override
  String get progressViewMessage => 'Üzenet megtekintése';

  @override
  String get pushTitle => 'Háttérértesítések';

  @override
  String get pushIntro =>
      'Privát értesítést kap, ha valami figyelmet igényel, akkor is, ha az alkalmazás zárva van. A részletek a titkosított kapcsolatban maradnak.';

  @override
  String get pushLoading => 'Értesítési beállítások ellenőrzése…';

  @override
  String get pushError =>
      'Nem sikerült frissíteni az értesítéseket. Ellenőrizze a kapcsolatot, és próbálja újra.';

  @override
  String get pushEnable => 'Értesítések engedélyezése';

  @override
  String get pushDisable => 'Értesítések kikapcsolása';

  @override
  String get pushQuiet => 'Értesítések szüneteltetése ezen az eszközön';

  @override
  String get pushCategories => 'Értesítést kérek ezekről';

  @override
  String get pushCategoryAgents => 'Ügynökök';

  @override
  String get pushCategoryMessages => 'Üzenetek';

  @override
  String get pushCategoryPullRequests => 'Pull requestek';

  @override
  String get pushCategoryTickets => 'Jegyek';

  @override
  String get pushCategoryCalendar => 'Naptár';

  @override
  String get pushCategoryMachines => 'Gépek';

  @override
  String get pushSecureOrigin => 'Az értesítésekhez HTTPS szükséges.';

  @override
  String get pushInstallIos =>
      'iPhone-on vagy iPaden adja hozzá az alkalmazást a Főképernyőhöz, és onnan nyissa meg az értesítések engedélyezéséhez.';

  @override
  String get pushUnsupported =>
      'Ez a böngésző nem támogatja a háttérértesítéseket.';

  @override
  String get pushDenied =>
      'A böngésző szerint az értesítések blokkolva vannak. Ellenőrizze a webhely engedélyét és a böngésző vagy az eszköz értesítési beállításait, majd frissítsen.';

  @override
  String get pushResubscribe => 'Értesítések újracsatlakoztatása';

  @override
  String get pushStatusEnabled =>
      'Az értesítések be vannak kapcsolva ezen az eszközön.';

  @override
  String get pushStatusDisabled =>
      'Az értesítések ki vannak kapcsolva ezen az eszközön.';

  @override
  String get credentialsTitle => 'Kapcsolatok és hitelesítő adatok';

  @override
  String get credentialsIntro =>
      'Csatlakoztassa a futtatásokhoz és integrációkhoz használt fiókokat. A titkos adatok a szerveren tárolódnak, nem ezen a telefonon.';

  @override
  String get credentialsModelProviders => 'Modellszolgáltatók';

  @override
  String get credentialsOwnerOnly =>
      'Modellszolgáltatói hitelesítő adatokat csak a szerver tulajdonosa adhat hozzá, jelentkeztethet be és távolíthat el. Ezek a kulcsok a munkaterületek között megosztottak.';

  @override
  String get credentialsContactOwner =>
      'Kérje meg a szerver tulajdonosát, hogy csatlakoztassa a blokkolt futtatáshoz szükséges szolgáltatót.';

  @override
  String get credentialsClaudeCode => 'Claude Code';

  @override
  String get credentialsClaudeHostOnly =>
      'A Claude Code a hoszton futó CLI-n keresztül jelentkezik be. Kérje meg a szerver tulajdonosát, hogy a hoszt terminálján végezze el vagy újítsa meg a bejelentkezést; ez a telefon nem tudja futtatni.';

  @override
  String get credentialsYourForgeAccounts => 'Kódtárszolgáltatói fiókjai';

  @override
  String get credentialsYourTicketingAccount => 'Jegykezelési fiókja';

  @override
  String get credentialsLocalTicketsNoLogin =>
      'A helyi jegyekhez nem kell bejelentkezés. Ha a munkaterület Linear-t használ, itt csatlakoztassa.';

  @override
  String get credentialsMembershipRequired =>
      'A kódtárszolgáltatói vagy jegykezelési hitelesítő adatok kezeléséhez csatlakozzon egy munkaterülethez. Hozzáférésért forduljon a munkaterület adminisztrátorához.';

  @override
  String get credentialsSwitchWorkspace =>
      'Ez a hivatkozás másik munkaterületre mutat. Hitelesítő adatok módosítása előtt váltson arra a munkaterületre.';

  @override
  String get credentialsReturnToInbox =>
      'A hitelesítő adatok csatlakoztatása után térjen vissza a Beérkezett üzenetekhez a blokkolt futtatás újrapróbálásához. A hoszt az álló futtatásokat automatikusan is ellenőrzi.';

  @override
  String get credentialsLoadFailed =>
      'Nem sikerült betölteni a kapcsolatokat. Ellenőrizze a szerverkapcsolatot, és próbálja újra.';

  @override
  String get credentialsOperationFailed =>
      'Nem sikerült módosítani ezt a kapcsolatot. Ellenőrizze a szerverkapcsolatot, a hozzáférését és a hitelesítő adatot, majd próbálja újra.';

  @override
  String get credentialsConnected => 'Csatlakoztatva';

  @override
  String get credentialsNotConnected => 'Nincs csatlakoztatva';

  @override
  String credentialsSignedInAs(String username) {
    return 'Bejelentkezve: $username';
  }

  @override
  String get credentialsAccount => 'Csatlakoztatott fiók';

  @override
  String get credentialsStoredKey => 'Tárolt kulcs';

  @override
  String get credentialsActive => 'Aktív';

  @override
  String get credentialsRemove => 'Eltávolítás';

  @override
  String get credentialsRemoveConfirm =>
      'Eltávolítja a mentett hitelesítő adatát? Lehet, hogy újra be kell jelentkeznie.';

  @override
  String get credentialsApiKey => 'API-kulcs';

  @override
  String get credentialsApiKeyHint => 'Illessze be a szolgáltató API-kulcsát';

  @override
  String get credentialsBrowserLogin => 'Bejelentkezés böngészővel';

  @override
  String get credentialsSignInAgain => 'Jelentkezzen be újra';

  @override
  String get credentialsWaitingForLogin =>
      'Várakozás a böngészőben történő engedélyezésre…';

  @override
  String get credentialsLoginTimedOut =>
      'A bejelentkezés lejárt. Indítson új bejelentkezést.';

  @override
  String get credentialsCopyCode => 'Kód másolása';

  @override
  String get credentialsDeviceCodeHint =>
      'Erősítse meg ezt a kódot a szolgáltató oldalán. Tartsa nyitva ezt a képernyőt, amíg a szerver befejezi a bejelentkezést.';

  @override
  String get credentialsPasteRedirect =>
      'Engedélyezési kód vagy átirányítási URL';

  @override
  String get credentialsPasteRedirectHint =>
      'Illessze be a szolgáltatótól kapott kódot vagy a teljes átirányítási URL-t';

  @override
  String get credentialsCompleteLogin => 'Bejelentkezés befejezése';

  @override
  String get credentialsRedirectUnavailable =>
      'A szerver böngészős visszahívása nem érhető el biztonságosan telefonról. Kérje meg a szerver tulajdonosát egy nyilvános HTTPS-visszahívás beállítására, vagy adjon hozzá tokent.';

  @override
  String get credentialsUpdateToken => 'Token frissítése';

  @override
  String get credentialsAddToken => 'Token hozzáadása';

  @override
  String get credentialsPersonalToken => 'Személyes hozzáférési token';

  @override
  String get credentialsPersonalTokenHint =>
      'Illesszen be egy személyes hozzáférési tokent';

  @override
  String get credentialsHostManaged =>
      'Ez a kapcsolat a szerveralkalmazásból vagy a környezetből származik. Ott csak a szerver tulajdonosa módosíthatja; saját tokent továbbra is hozzáadhat.';

  @override
  String get credentialsStopWatching => 'Figyelés leállítása';
}
