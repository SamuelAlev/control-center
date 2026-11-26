// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Czech (`cs`).
class AppLocalizationsCs extends AppLocalizations {
  AppLocalizationsCs([String locale = 'cs']) : super(locale);

  @override
  String get appTitle => 'Control Center';

  @override
  String get back => 'Zpět';

  @override
  String get cancel => 'Zrušit';

  @override
  String get retry => 'Zopakovat';

  @override
  String get tryAgain => 'Zkusit znovu';

  @override
  String get settings => 'Nastavení';

  @override
  String get refresh => 'Obnovit';

  @override
  String get approve => 'Schválit';

  @override
  String get deny => 'Zakázat';

  @override
  String get continueLabel => 'Pokračovat';

  @override
  String get agentQuestionHeader => 'Otázka pro vás';

  @override
  String get agentQuestionAnsweredLabel => 'Zodpovězeno';

  @override
  String get agentQuestionSkip => 'Přeskočit';

  @override
  String get agentQuestionSkippedLabel => 'Přeskočeno';

  @override
  String get agentQuestionFreeformHint => 'Napište odpověď…';

  @override
  String get agentApprovalRequired => 'Je potřeba schválení';

  @override
  String get copyCommand => 'Kopírovat příkaz';

  @override
  String get approveAndRemember => 'Schválit na 8 hodin';

  @override
  String get decline => 'Odmítnout';

  @override
  String get confirm => 'Potvrdit';

  @override
  String get send => 'Odeslat';

  @override
  String get close => 'Zavřít';

  @override
  String get expand => 'Rozbalit';

  @override
  String get zoomIn => 'Přiblížit';

  @override
  String get zoomOut => 'Oddálit';

  @override
  String get resetZoom => 'Obnovit přiblížení';

  @override
  String get scanQrPrompt =>
      'Naskenujte QR kód z Control Center a spárujte tento telefon.';

  @override
  String get scanQrHelp =>
      'Otevřete fotoaparát a namířte ho na QR kód zobrazený v Control Center. Tento telefon se připojí přímo přes soukromé spojení.';

  @override
  String get connectingToMac => 'Připojování k Control Center…';

  @override
  String get connectingDetail => 'Navazuje se zabezpečené, přímé spojení.';

  @override
  String get identityChangedTitle => 'Identita serveru se změnila';

  @override
  String get identityChangedBody =>
      'Tento server už neodpovídá identitě uložené při párování. Může to znamenat, že byl server přeinstalován — nebo že něco odposlouchává připojení. Pro jistotu se toto zařízení nepřipojí. Odstraňte párování a pak naskenujte nový QR kód z Control Center.';

  @override
  String get removePairing => 'Odstranit párování';

  @override
  String get couldntConnect => 'Nepodařilo se připojit';

  @override
  String get pendingPairingTitle => 'Připojit k tomuto serveru?';

  @override
  String get pendingPairingBody =>
      'Odkaz požádal Control Center o spárování s tímto serverem. Pokračujte, jen pokud jste to spustili vy.';

  @override
  String get connect => 'Připojit';

  @override
  String get failureNotPaired =>
      'Nespárováno — naskenujte QR kód z Control Center';

  @override
  String get failureUnreachable =>
      'K serveru se nepodařilo dostat žádnou cestou — zkontrolujte, že běží, nebo zkuste stejnou síť';

  @override
  String get failureIdentityChanged =>
      'Identita serveru se změnila — pokud byl přeinstalován, spárujte toto zařízení znovu';

  @override
  String get failureAuthRejected =>
      'Server toto zařízení odmítl — spárujte ho znovu z Control Center';

  @override
  String get failureUnknown =>
      'Nepodařilo se připojit — klepněte pro opakování';

  @override
  String get statusConnected => 'Připojeno';

  @override
  String get statusConnecting => 'Připojování';

  @override
  String get statusOffline => 'Offline';

  @override
  String get statusIdentityMismatch => 'Neshoda identity';

  @override
  String get statusNotPaired => 'Nespárováno';

  @override
  String get statusConfirmPairing => 'Potvrdit párování';

  @override
  String get connectionFailed => 'Připojení selhalo';

  @override
  String get identityMismatchBanner =>
      'Identita serveru se změnila — připojení bylo zastaveno. Spárujte toto zařízení znovu, abyste mohli pokračovat.';

  @override
  String get tabInbox => 'Doručená pošta';

  @override
  String get tabTickets => 'Tickety';

  @override
  String get tabChat => 'Chat';

  @override
  String get tabPrs => 'PRs';

  @override
  String get tabCalendar => 'Kalendář';

  @override
  String get tabNews => 'Novinky';

  @override
  String tabWaitingCount(String label, int count) {
    return '$label, $count čeká';
  }

  @override
  String get updateAvailable => 'Je dostupný nový Control Center';

  @override
  String get appearance => 'Vzhled';

  @override
  String get language => 'Jazyk';

  @override
  String get device => 'Zařízení';

  @override
  String get themeSystem => 'Systém';

  @override
  String get themeLight => 'Světlý';

  @override
  String get themeDark => 'Tmavý';

  @override
  String get languageSystem => 'Systém';

  @override
  String get disconnectTapAgain =>
      'Klepněte znovu a odpojte toto zařízení od Control Center';

  @override
  String get disconnectDevice => 'Odpojit toto zařízení';

  @override
  String get disconnect => 'Odpojit';

  @override
  String get chooseWorkspace => 'Vybrat pracovní prostor';

  @override
  String get workspaces => 'Pracovní prostory';

  @override
  String get workspacesLoadFailed => 'Pracovní prostory se nepodařilo načíst';

  @override
  String get noWorkspacesYet => 'Zatím žádné pracovní prostory';

  @override
  String selectWorkspace(String name) {
    return 'Vybrat $name';
  }

  @override
  String get inboxLoadFailed => 'Doručenou poštu se nepodařilo načíst';

  @override
  String get allCaughtUp => 'Máte všechno přečtené';

  @override
  String get inboxNothingWaiting =>
      'Nic není blokováno a žádný pull request na vás nečeká.';

  @override
  String get blocked => 'Blokováno';

  @override
  String get sectionNeedsYourReview => 'Potřebuje vaši kontrolu';

  @override
  String get sectionReturnedToYou => 'Vráceno vám';

  @override
  String get sectionApprovedAndReady => 'Schváleno a připraveno';

  @override
  String get sectionYourDrafts => 'Vaše koncepty';

  @override
  String get sectionWaitingForReviewers => 'Čeká na recenzenty';

  @override
  String get sectionMergingAndMerged => 'Slučuje se a nedávno sloučené';

  @override
  String get sectionWaitingForAuthor => 'Čeká na autora';

  @override
  String waitingAgo(String ago) {
    return 'čeká $ago';
  }

  @override
  String get openConversation => 'Otevřít konverzaci';

  @override
  String get calendarLoadFailed => 'Kalendář se nepodařilo načíst';

  @override
  String get nothingScheduled => 'Nic naplánováno';

  @override
  String get calendarEmptyDescription =>
      'Události z připojených kalendářů se zobrazí tady.';

  @override
  String get agenda => 'Agenda';

  @override
  String get syncCalendarsNow => 'Synchronizovat kalendáře teď';

  @override
  String get event => 'Událost';

  @override
  String get eventNotFound => 'Událost nenalezena';

  @override
  String get eventNotFoundDescription =>
      'Může být mimo okno agendy, nebo byla odstraněna u zdroje.';

  @override
  String get joinMeeting => 'Připojit se ke schůzce';

  @override
  String attendeesCount(int count) {
    return 'Účastníci ($count)';
  }

  @override
  String get details => 'Podrobnosti';

  @override
  String get allDay => 'Celý den';

  @override
  String get happeningNow => 'Právě probíhá';

  @override
  String inDuration(String duration) {
    return 'Za $duration';
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
  String get attendeeAccepted => 'přijato';

  @override
  String get attendeeDeclined => 'odmítnuto';

  @override
  String get attendeeMaybe => 'možná';

  @override
  String get attendeeNoReply => 'bez odpovědi';

  @override
  String get organizer => 'organizátor';

  @override
  String get calendarNoAccounts =>
      'K tomuto pracovnímu prostoru není připojený žádný kalendář. Připojte ho v desktopové aplikaci — přihlášení uloží token na server.';

  @override
  String get calendarReauthNeeded =>
      'Kalendářový účet je potřeba znovu připojit — údaje níže můžou být zastaralé. Připojte ho znovu v desktopové aplikaci.';

  @override
  String get spacesLoadFailed => 'Prostory se nepodařilo načíst';

  @override
  String get noSpaces => 'Žádné prostory';

  @override
  String get spacesEmptyDescription =>
      'Prostory v tomto pracovním prostoru se zobrazí tady.';

  @override
  String get newSpaceFolder => 'Nová složka';

  @override
  String get folderName => 'Název složky';

  @override
  String get renameSpaceFolder => 'Přejmenovat složku';

  @override
  String get deleteSpaceFolder => 'Smazat složku';

  @override
  String get moveSpaceToFolder => 'Přesunout prostor do složky';

  @override
  String get removeSpaceFromFolder => 'Odebrat prostor ze složky';

  @override
  String get spaceFolderActions => 'Akce složky';

  @override
  String get deleteFolderWithSpacesWarning =>
      'Trvalým smazáním prostorů se všem odstraní jejich zprávy a pracovní stromy. Tuto akci nelze vrátit zpět.';

  @override
  String get deleteSpacesInFolder => 'Trvale smazat prostory v této složce';

  @override
  String get deleteFolderAndSpaces => 'Smazat složku a prostory';

  @override
  String get keepSpacesInFolder => 'Jinak prostory zůstanou nezařazené.';

  @override
  String get create => 'Vytvořit';

  @override
  String get otherSpaces => 'Ostatní prostory';

  @override
  String get folderUpdateFailed => 'Nepodařilo se aktualizovat složky';

  @override
  String get thread => 'Vlákno';

  @override
  String get agentWorking => 'Agent pracuje';

  @override
  String get messagesLoadFailed => 'Zprávy se nepodařilo načíst';

  @override
  String get noMessagesYet => 'Zatím žádné zprávy';

  @override
  String get noMessagesDescription => 'Odešlete zprávu a začněte konverzaci.';

  @override
  String get agentResponding => 'Agent odpovídá';

  @override
  String get agentFinished => 'Agent dokončil';

  @override
  String attachmentsTooLarge(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$names jsou příliš velké na odeslání odtud.',
      few: '$names jsou příliš velké na odeslání odtud.',
      one: '$names je příliš velký na odeslání odtud.',
    );
    return '$_temp0';
  }

  @override
  String get teammate => 'Spolupracovník';

  @override
  String get systemSender => 'Systém';

  @override
  String get agent => 'Agent';

  @override
  String get attachFile => 'Přiložit soubor';

  @override
  String get messageHint => 'Zpráva';

  @override
  String removeAttachment(String name) {
    return 'Odebrat $name';
  }

  @override
  String get articlesLoadFailed => 'Články se nepodařilo načíst';

  @override
  String get noArticles => 'Žádné články';

  @override
  String get articlesEmptyDescription =>
      'Nové články se tu objeví, jak se kanály aktualizují.';

  @override
  String get unread => 'Nepřečtené';

  @override
  String get allFeeds => 'Všechny kanály';

  @override
  String get save => 'Uložit';

  @override
  String get unsave => 'Zrušit uložení';

  @override
  String get readFullArticle => 'Číst celý článek';

  @override
  String get ticketsLoadFailed => 'Tickety se nepodařilo načíst';

  @override
  String get noTickets => 'Žádné tickety';

  @override
  String get ticketsEmptyDescription =>
      'Tickety v tomto pracovním prostoru se zobrazí tady.';

  @override
  String get all => 'Vše';

  @override
  String get ticket => 'Ticket';

  @override
  String get ticketLoadFailed => 'Ticket se nepodařilo načíst';

  @override
  String assignedTo(String name) {
    return 'Přiřazeno: $name';
  }

  @override
  String get openInBrowser => 'Otevřít v prohlížeči';

  @override
  String get status => 'Stav';

  @override
  String get assign => 'Přiřadit';

  @override
  String get reassign => 'Přiřadit znovu';

  @override
  String get noAgents => 'Žádní agenti';

  @override
  String get noAgentsDescription =>
      'Přiřaďte agenta z tohoto pracovního prostoru.';

  @override
  String get statusOpen => 'Otevřený';

  @override
  String get statusInProgress => 'Probíhá';

  @override
  String get statusBlocked => 'Blokováno';

  @override
  String get statusInReview => 'V kontrole';

  @override
  String get statusDone => 'Hotovo';

  @override
  String get statusBacklog => 'Backlog';

  @override
  String get lensNeedsMe => 'Potřebuje mě';

  @override
  String get lensMine => 'Moje';

  @override
  String get prsLoadFailed => 'Pull requesty se nepodařilo načíst';

  @override
  String get noOpenPullRequests => 'Žádné otevřené pull requesty';

  @override
  String get nothingWaitingOnReview => 'Nic nečeká na vaši kontrolu';

  @override
  String get noOwnOpenPullRequests => 'Nemáte žádné otevřené pull requesty';

  @override
  String get nothingBlocked => 'Nic není blokováno';

  @override
  String get prsEmptyDescription =>
      'Pull requesty z repozitářů tohoto pracovního prostoru se zobrazí tady.';

  @override
  String get refreshPullRequests => 'Obnovit pull requesty';

  @override
  String get noForgeConnected =>
      'Na serveru není připojený žádný forge, takže pull requesty nelze načíst. Připojte ho v desktopové aplikaci.';

  @override
  String get draft => 'Koncept';

  @override
  String get merged => 'Sloučeno';

  @override
  String get closed => 'Zavřeno';

  @override
  String get open => 'Otevřený';

  @override
  String get approved => 'Schváleno';

  @override
  String get changesRequested => 'Vyžádány změny';

  @override
  String get reviewRequired => 'Vyžadována kontrola';

  @override
  String get checksPassing => 'Kontroly procházejí';

  @override
  String get checksFailing => 'Kontroly selhávají';

  @override
  String get checksRunning => 'Kontroly běží';

  @override
  String prSemanticLabel(String title, String status) {
    return '$title, $status';
  }

  @override
  String get pullRequest => 'Pull request';

  @override
  String get prLoadFailed => 'Tento pull request se nepodařilo načíst';

  @override
  String get openOnForge => 'Otevřít na forge';

  @override
  String get requestChangesNeedsComment =>
      'Přidejte komentář, který vysvětlí, co je potřeba změnit.';

  @override
  String get conversation => 'Konverzace';

  @override
  String get files => 'Soubory';

  @override
  String get checks => 'Kontroly';

  @override
  String labelWithCount(String label, int count) {
    return '$label ($count)';
  }

  @override
  String filesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count souborů',
      few: '$count soubory',
      one: '1 soubor',
    );
    return '$_temp0';
  }

  @override
  String commitsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count commitů',
      few: '$count commity',
      one: '1 commit',
    );
    return '$_temp0';
  }

  @override
  String get conflicts => 'Konflikty';

  @override
  String get reviewers => 'Recenzenti';

  @override
  String get noDescriptionNoComments => 'Zatím žádný popis ani komentáře.';

  @override
  String get noChangedFiles => 'Žádné změněné soubory.';

  @override
  String get noChecksReported =>
      'Pro head commit nebyly nahlášeny žádné kontroly.';

  @override
  String get reviewCommentHint => 'Napište komentář k recenzi…';

  @override
  String get comment => 'Komentář';

  @override
  String get commentPosted => 'Komentář odeslán';

  @override
  String get request => 'Vyžádat';

  @override
  String get squashAndMerge => 'Squash a sloučení';

  @override
  String noActionsAvailable(String status) {
    return '$status — žádné dostupné akce.';
  }

  @override
  String get reviewApproved => 'schválil';

  @override
  String get reviewRequestedChanges => 'vyžádal změny';

  @override
  String get reviewCommented => 'zkontroloval';

  @override
  String get reviewPending => 'čeká';

  @override
  String get unknownAuthor => 'neznámý';

  @override
  String hideDiffFor(String file) {
    return 'Skrýt diff souboru $file';
  }

  @override
  String showDiffFor(String file) {
    return 'Zobrazit diff souboru $file';
  }

  @override
  String get checkRunning => 'běží';

  @override
  String get checkPassed => 'prošlo';

  @override
  String get checkFailed => 'selhalo';

  @override
  String get checkCancelled => 'zrušeno';

  @override
  String get checkSkipped => 'přeskočeno';

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
      'Pro tento soubor není textový diff — je binární, nebo příliš velký, aby ho forge vrátil.';

  @override
  String showRemainingLines(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Zobrazit zbývajících $count řádků',
      few: 'Zobrazit zbývající $count řádky',
      one: 'Zobrazit zbývající řádek',
    );
    return '$_temp0';
  }

  @override
  String unchangedLines(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nezměněných řádků',
      few: '$count nezměněné řádky',
      one: '1 nezměněný řádek',
    );
    return '$_temp0';
  }

  @override
  String get jumpToLatest => 'Přejít na nejnovější';

  @override
  String get streaming => 'Streamování';

  @override
  String get working => 'Pracuje';

  @override
  String get input => 'Vstup';

  @override
  String get output => 'Výstup';

  @override
  String get now => 'teď';

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
  String get today => 'Dnes';

  @override
  String get tomorrow => 'Zítra';

  @override
  String get yesterday => 'Včera';

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
  String get mobileConversations => 'Konverzace';

  @override
  String get mobileNewConversation => 'Nová konverzace';

  @override
  String get mobileConversationName => 'Název konverzace';

  @override
  String get mobileRename => 'Přejmenovat';

  @override
  String get mobileManageSpace => 'Spravovat prostor';

  @override
  String get mobileArchived => 'Archivováno';

  @override
  String get mobileSearchMessages =>
      'Hledat ve všech zprávách v tomto prostoru';

  @override
  String get mobileSearch => 'Hledat';

  @override
  String get mobileNoResults => 'Žádné výsledky';

  @override
  String get mobileReopen => 'Znovu otevřít';

  @override
  String get mobileArchive => 'Archivovat';

  @override
  String get mobileProgress => 'Průběh a kontext';

  @override
  String get mobileReadFailed =>
      'Konverzaci se nepodařilo označit jako přečtenou';

  @override
  String get mobileSendFailed =>
      'Zpráva se neodeslala. Koncept tu na vás čeká.';

  @override
  String get sentAttachmentUnavailable => 'Příloha není k dispozici';

  @override
  String get sentAttachmentLoadFailed => 'Přílohu se nepodařilo načíst';

  @override
  String get mobileActionFailed => 'Akce selhala';

  @override
  String get mobileRemove => 'Odebrat';

  @override
  String get mobileLinkedMessage => 'Propojená zpráva';

  @override
  String get mobileOlderMessages => 'Starší zprávy';

  @override
  String get mobileMessageActions => 'Akce se zprávou';

  @override
  String get mobileOpenThread => 'Otevřít vlákno';

  @override
  String get mobileCopyLink => 'Kopírovat odkaz';

  @override
  String get mobileStopRun => 'Zastavit běh';

  @override
  String get mobileStopRunConfirm =>
      'Zastavit tento běh agenta? Dokončená práce zůstane zachována.';

  @override
  String get mobileControlUnsupported =>
      'Tento běh už skončil nebo tento ovládací prvek nepodporuje.';

  @override
  String get mobilePauseRequested => 'Požádáno o pozastavení po dalším tahu';

  @override
  String get mobileResumed => 'Běh pokračuje';

  @override
  String get mobileStopRequested => 'Požádáno o zastavení';

  @override
  String get mobileQueuedMessages => 'Zprávy ve frontě';

  @override
  String get mobilePauseRun => 'Pozastavit po dalším tahu';

  @override
  String get mobileResumeRun => 'Pokračovat';

  @override
  String get mobileEditQueued => 'Upravit zařazenou zprávu';

  @override
  String get mobileSteerNow => 'Nasměrovat nyní';

  @override
  String get mobileMoveUp => 'Posunout nahoru';

  @override
  String get mobileMoveDown => 'Posunout dolů';

  @override
  String get mobileQueueChanged =>
      'Fronta se změnila nebo tento běh nepřijímá průběžné pokyny. Aktualizujte stránku a zkuste to znovu.';

  @override
  String get mobileActivity => 'Aktivita';

  @override
  String get mobilePermissions => 'Oprávnění a audit';

  @override
  String get mobilePlans => 'Plány';

  @override
  String get mobileGoals => 'Cíle pod dohledem';

  @override
  String get mobileCredentials => 'Připojení a přihlašovací údaje';

  @override
  String get mobileWorkspaceUnavailable =>
      'Tento pracovní prostor není dostupný nebo k němu už nemáte přístup.';

  @override
  String get mobilePrReviewThreads => 'Vlákna kontroly';

  @override
  String get mobilePrThreadsLoadFailed =>
      'Vlákna kontroly se nepodařilo načíst';

  @override
  String get mobilePrNoReviewThreads => 'Zatím žádná vlákna komentářů v kódu';

  @override
  String get mobilePrCommentPermissionDenied =>
      'Nemáte oprávnění komentovat tento repozitář.';

  @override
  String get mobilePrPermissionChecking => 'Kontrola oprávnění ke komentování…';

  @override
  String get mobilePrPermissionLoadFailed =>
      'Oprávnění ke komentování se nepodařilo ověřit. Zkuste to znovu.';

  @override
  String mobilePrThreadLine(String side, String line) {
    return '$side, řádek $line';
  }

  @override
  String get mobilePrOriginalSide => 'Původní';

  @override
  String get mobilePrSelectCommentLine => 'Vyberte řádek pro komentář';

  @override
  String get mobilePrUpdatedSide => 'Aktualizováno';

  @override
  String get mobilePrThreadResolved => 'Vyřešeno';

  @override
  String get mobilePrReplyHint => 'Napište odpověď…';

  @override
  String get mobilePrCommentRequired => 'Před odesláním napište komentář.';

  @override
  String get mobilePrReply => 'Odpovědět';

  @override
  String get mobilePrReopenThread => 'Znovu otevřít vlákno';

  @override
  String get mobilePrResolveThread => 'Vyřešit vlákno';

  @override
  String get mobilePrResolvePermissionDenied =>
      'Toto vlákno může vyřešit jen autor pull requestu nebo uživatel s oprávněním k zápisu.';

  @override
  String mobilePrCommentOnLine(String side, String line) {
    return 'Komentovat $side, řádek $line';
  }

  @override
  String get mobilePrInlineCommentHint => 'Napište komentář ke kódu…';

  @override
  String get mobilePrPostInlineComment => 'Odeslat komentář';

  @override
  String get mobilePrCommentUnavailable =>
      'Komentáře v kódu nejsou pro tento pull request dostupné.';

  @override
  String get mobilePrPatchUnavailable =>
      'Hostitelská služba neposkytla pro tento soubor textový patch.';

  @override
  String get mobilePrNoPatchForFile => 'Patch pro tento soubor není dostupný.';

  @override
  String get mobileTicketNew => 'Nový ticket';

  @override
  String get mobileTicketCreate => 'Vytvořit ticket';

  @override
  String get mobileTicketEdit => 'Upravit ticket';

  @override
  String get mobileTicketTitle => 'Název';

  @override
  String get mobileTicketTitleRequired => 'Pro uložení ticketu zadejte název.';

  @override
  String get mobileTicketDescription => 'Popis';

  @override
  String get mobileTicketMarkdownHint =>
      'Přidejte podrobnosti ve formátu Markdown';

  @override
  String get mobileTicketPriority => 'Priorita';

  @override
  String get mobileTicketPriorityNone => 'Bez priority';

  @override
  String get mobileTicketPriorityUrgent => 'Urgentní';

  @override
  String get mobileTicketPriorityHigh => 'Vysoká';

  @override
  String get mobileTicketPriorityMedium => 'Střední';

  @override
  String get mobileTicketPriorityLow => 'Nízká';

  @override
  String get mobileTicketLabels => 'Štítky';

  @override
  String get mobileTicketLabelsHint => 'Jeden štítek na řádek';

  @override
  String get mobileTicketLabelsHelp =>
      'Každý štítek zadejte na samostatný řádek.';

  @override
  String mobileTicketWorkspaceProvider(String provider) {
    return 'Založeno v $provider';
  }

  @override
  String get mobileTicketProviderLocal => 'Control Center';

  @override
  String get mobileTicketUnassigned => 'Nepřiřazeno';

  @override
  String get mobileTicketAssignedFilter => 'Přiřazené';

  @override
  String get mobileTicketAgentsLoadFailed => 'Agenty se nepodařilo načíst';

  @override
  String get mobileTicketSearch => 'Hledat tickety';

  @override
  String get mobileTicketSearchHint =>
      'Název, klíč, popis, štítek nebo řešitel';

  @override
  String get mobileTicketClearSearch => 'Vymazat hledání ticketů';

  @override
  String get mobileTicketNoMatches => 'Žádné odpovídající tickety';

  @override
  String get mobileTicketAdjustFilters =>
      'Zkuste jiné hledání nebo upravte filtry.';

  @override
  String get mobileTicketClearFilters => 'Vymazat filtry';

  @override
  String get mobileTicketNotFound => 'Ticket nebyl nalezen';

  @override
  String get mobileTicketNotFoundDescription =>
      'Ticket mohl být smazán nebo přesunut z tohoto pracovního prostoru.';

  @override
  String get mobileTicketWorkspaceChanged =>
      'Pracovní prostor se změnil. Před uložením se vraťte do aktuálního pracovního prostoru.';

  @override
  String get mobileTicketOpenLinkedSpace => 'Otevřít propojený prostor';

  @override
  String get mobileTicketReadOnly =>
      'Ke změně ticketů je třeba mít roli člena pracovního prostoru.';

  @override
  String get permissionTitle => 'Oprávnění';

  @override
  String get permissionWorkspaceFailed =>
      'Pracovní prostor se nepodařilo načíst';

  @override
  String get permissionNoWorkspace =>
      'Vyberte pracovní prostor, jehož oprávnění chcete prohlédnout.';

  @override
  String get permissionLoading => 'Načítání oprávnění…';

  @override
  String get permissionScopeDescription =>
      'Prohlédněte si, jak se rozhoduje o každé akci v tomto rozsahu. Agenti a prostory mohou dědit pravidla pracovního prostoru.';

  @override
  String get permissionScope => 'Rozsah zásad';

  @override
  String get permissionWorkspaceScope => 'Pracovní prostor';

  @override
  String get permissionAgentScope => 'Agent';

  @override
  String get permissionSpaceScope => 'Prostor';

  @override
  String get permissionAgentContext => 'Agent působící v tomto prostoru';

  @override
  String get permissionNoAgentContext => 'Není vybrán žádný agent';

  @override
  String get permissionTargetsFailed => 'Cíle rozsahu se nepodařilo načíst';

  @override
  String get permissionNoTargets =>
      'V tomto rozsahu nejsou dostupné žádné cíle.';

  @override
  String get permissionRoleFailed =>
      'Vaši roli v pracovním prostoru se nepodařilo potvrdit';

  @override
  String get permissionMemberRequired =>
      'K zobrazení pravidel zásad je třeba mít roli člena pracovního prostoru.';

  @override
  String get permissionRulesFailed => 'Pravidla zásad se nepodařilo načíst';

  @override
  String get permissionAuditAdminOnly =>
      'Historie autorizací je dostupná pouze správcům pracovního prostoru.';

  @override
  String get permissionAllow => 'Povolit';

  @override
  String get permissionAsk => 'Nejdřív se zeptat';

  @override
  String get permissionDeny => 'Zakázat';

  @override
  String get permissionFileDelete => 'Mazat soubory';

  @override
  String get permissionFileWriteOutsideWorktree =>
      'Zapisovat mimo pracovní strom';

  @override
  String get permissionGitCommit => 'Potvrzovat změny commitem';

  @override
  String get permissionGitPush => 'Odesílat commity';

  @override
  String get permissionPrCreate => 'Vytvářet pull requesty';

  @override
  String get permissionPrPublish => 'Aktualizovat nebo sloučit pull requesty';

  @override
  String get permissionVendorSyncWrite =>
      'Zapisovat při synchronizaci dodavatele';

  @override
  String get permissionNetworkEgress => 'Přistupovat k síti';

  @override
  String get permissionSecretAccess => 'Přistupovat k tajným údajům';

  @override
  String get permissionPackageInstall => 'Instalovat balíčky';

  @override
  String get permissionProcessSpawn => 'Spouštět procesy';

  @override
  String get permissionWorkspaceMutation => 'Měnit pracovní prostor';

  @override
  String get permissionEnclosureControl => 'Ovládat zařízení';

  @override
  String get permissionChangeFailed => 'Pravidlo se nepodařilo změnit';

  @override
  String get permissionEffectiveDescription =>
      'Platí pro tento rozsah bez argumentů akce. Podmíněná povolení níže platí jen pro odpovídající požadavky; konečné rozhodnutí dělá server.';

  @override
  String get permissionSpaceAgentNote =>
      'Není vybrán žádný agent. Pravidla pro konkrétního agenta se zobrazí až po jeho výběru výše.';

  @override
  String get permissionScopedGrants => 'Pravidla v tomto rozsahu';

  @override
  String get permissionModePreset => 'Předvolba režimu';

  @override
  String get permissionBuiltInDefault => 'Vestavěný výchozí';

  @override
  String get permissionRemembered => 'Schválení na čas';

  @override
  String get permissionSource => 'Zdroj';

  @override
  String permissionSetAtThisScope(String source) {
    return '$source · nastaveno zde';
  }

  @override
  String permissionInheritedFrom(String source) {
    return '$source · zděděno';
  }

  @override
  String permissionExpiresAt(String date) {
    return 'Platnost vyprší $date';
  }

  @override
  String get permissionSetHere => 'Nastavit zde pravidlo';

  @override
  String get permissionConfirmRevoke => 'Potvrdit zrušení';

  @override
  String get permissionRevokeRule => 'Zrušit pravidlo';

  @override
  String permissionCommandPrefix(String prefix) {
    return 'Předpona příkazu: $prefix';
  }

  @override
  String get permissionNoExpiry => 'Bez omezení platnosti';

  @override
  String get permissionExpired => 'Vypršela';

  @override
  String get permissionExplicitRule => 'Výslovné pravidlo';

  @override
  String get permissionEnforcementAdvisory =>
      'Informativní režim: pravidla vyžadující dotaz se zaznamenají bez vyžádání souhlasu';

  @override
  String get permissionEnforcementSoft =>
      'Mírné vynucení: obejití vyžaduje autorizaci';

  @override
  String get permissionEnforcementHard => 'Přísné vynucení: nelze obejít';

  @override
  String permissionPaths(String paths) {
    return 'Cesty: $paths';
  }

  @override
  String permissionRefs(String refs) {
    return 'Reference Gitu: $refs';
  }

  @override
  String permissionHosts(String hosts) {
    return 'Hostitelé: $hosts';
  }

  @override
  String permissionCommands(String commands) {
    return 'Příkazy: $commands';
  }

  @override
  String permissionTools(String tools) {
    return 'Nástroje: $tools';
  }

  @override
  String get permissionNotInEffect =>
      'Bez účinku, dokud je tato akce nastavena na Zakázat';

  @override
  String permissionMaxCount(String count) {
    return 'Maximální počet: $count';
  }

  @override
  String permissionMaxCents(String cents) {
    return 'Maximum v centech: $cents';
  }

  @override
  String get permissionAuditHeading => 'Historie autorizací';

  @override
  String get permissionAuditDescription =>
      'Nedávná rozhodnutí zaznamenaná serverem. Pouze správci mohou prohlížet protokol nebo ověřovat jeho řetězec hashů.';

  @override
  String permissionOnBehalfOf(String user) {
    return 'za uživatele $user';
  }

  @override
  String get permissionPrompted => 'Vyžádáno schválení člověkem';

  @override
  String get permissionVerifyChain => 'Ověřit auditní řetězec';

  @override
  String get permissionVerifyFailed => 'Auditní řetězec se nepodařilo ověřit';

  @override
  String permissionChainIntact(String count) {
    return 'Řetězec je neporušený · zkontrolováno $count záznamů';
  }

  @override
  String permissionChainBroken(String sequence, String reason) {
    return 'Řetězec je přerušený u záznamu $sequence: $reason';
  }

  @override
  String get permissionAuditEmpty =>
      'Zatím nebyla zaznamenána žádná autorizační rozhodnutí.';

  @override
  String get permissionAuditFailed =>
      'Historii autorizací se nepodařilo načíst';

  @override
  String get mobilePlansLoadFailed => 'Plány se nepodařilo načíst';

  @override
  String get mobilePlansEmpty => 'Zatím žádné plány';

  @override
  String get mobilePlansEmptyDescription =>
      'Plány předložené agenty se zde zobrazí ke kontrole.';

  @override
  String get mobilePlanTitle => 'Plán';

  @override
  String get mobilePlanMissing =>
      'Tento plán už není v tomto pracovním prostoru dostupný.';

  @override
  String mobilePlanStepCount(int count) {
    return 'Počet kroků: $count';
  }

  @override
  String get mobilePlanDraft => 'Koncept';

  @override
  String get mobilePlanProposed => 'Čeká na kontrolu';

  @override
  String get mobilePlanApproved => 'Schváleno';

  @override
  String get mobilePlanRejected => 'Odmítnuto';

  @override
  String get mobilePlanSuperseded => 'Nahrazeno';

  @override
  String get mobilePlanExecuting => 'Provádění';

  @override
  String get mobilePlanSynthesizing => 'Syntéza';

  @override
  String get mobilePlanCompleted => 'Dokončeno';

  @override
  String get mobilePlanFailed => 'Selhalo';

  @override
  String get mobilePlanCancelled => 'Zrušeno';

  @override
  String mobilePlanRevision(String revision) {
    return 'Revize $revision';
  }

  @override
  String get mobilePlanSteps => 'Kroky';

  @override
  String get mobilePlanNoSteps =>
      'Pro tento plán nebyly předloženy žádné kroky.';

  @override
  String get mobilePlanAssumptions => 'Upřesnění';

  @override
  String mobilePlanDependsOn(String keys) {
    return 'Závisí na $keys';
  }

  @override
  String mobilePlanStepCost(String cost) {
    return 'Odhad až $cost';
  }

  @override
  String get mobilePlanSelect => 'Vybrat';

  @override
  String get mobilePlanSelected => 'Vybráno';

  @override
  String get mobilePlanEstimate => 'Odhadnout náklady';

  @override
  String get mobilePlanEstimateRequired =>
      'Před schválením provedení nejdřív odhadněte náklady na plán.';

  @override
  String mobilePlanEstimatedCost(String low, String high) {
    return 'Odhad nákladů: $low–$high';
  }

  @override
  String get mobilePlanCostUnknown => 'není dostupné';

  @override
  String get mobilePlanNoHardCap => 'bez pevného stropu';

  @override
  String get mobilePlanExceedsBudget =>
      'Odhad překračuje nastavený rozpočet. Před schválením ho zkontrolujte.';

  @override
  String get mobilePlanPartialEstimate =>
      'Tento odhad platí pro celý plán; vybrané kroky mohou stát méně.';

  @override
  String get mobilePlanConfirmAll => 'Spustit celý plán?';

  @override
  String get mobilePlanConfirmSelected => 'Spustit vybrané kroky?';

  @override
  String mobilePlanExecutionConfirmation(String cost, String cap) {
    return 'Schválením se spustí provádění a mohou vzniknout náklady. Horní odhad nákladů: $cost. Rozpočtový strop: $cap.';
  }

  @override
  String get mobilePlanApproveAll => 'Schválit vše a spustit';

  @override
  String get mobilePlanApproveSelected => 'Schválit vybrané a spustit';

  @override
  String get mobilePlanWiden => 'Schválit další kroky';

  @override
  String mobilePlanWidenConfirm(String count, String cap) {
    return 'Uvolnit k provedení dalších $count kroků? Mohou vzniknout náklady. Stávající strop nákladů na provedení: $cap.';
  }

  @override
  String get mobilePlanChanged =>
      'Plán se během kontroly změnil. Otevřete nejnovější revizi a znovu odhadněte náklady.';

  @override
  String get mobilePlanReject => 'Zamítnout plán';

  @override
  String get mobilePlanRejectConfirm =>
      'Zamítnout tento plán? Nebude proveden.';

  @override
  String get mobilePlanStop => 'Zastavit provádění';

  @override
  String get mobilePlanStopConfirm =>
      'Zastavit provádění tohoto plánu? Již dokončená práce se nevrátí zpět.';

  @override
  String mobilePlanRunId(String runId) {
    return 'Běh provádění: $runId';
  }

  @override
  String get mobilePlanExecutionPending =>
      'Schválení přijato. Čeká se na záznam o provádění…';

  @override
  String mobilePlanProgress(String completed, String total) {
    return 'Dokončeno $completed z $total kroků provádění';
  }

  @override
  String get mobilePlanOpenConversation => 'Otevřít konverzaci';

  @override
  String get mobileGoalsTitle => 'Cíle pod dohledem';

  @override
  String get mobileGoalsLoadFailed => 'Cíle pod dohledem se nepodařilo načíst';

  @override
  String get mobileGoalsEmpty => 'Zatím žádné cíle pod dohledem';

  @override
  String get mobileGoalsEmptyDescription =>
      'Začněte cíl v prostoru nebo pošlete /goal v konverzaci.';

  @override
  String get mobileGoalMissing =>
      'Tento cíl už není v tomto pracovním prostoru dostupný.';

  @override
  String get mobileGoalActive => 'Aktivní';

  @override
  String get mobileGoalPaused => 'Pozastaveno';

  @override
  String get mobileGoalCompleted => 'Dokončeno';

  @override
  String get mobileGoalFailed => 'Selhalo';

  @override
  String get mobileGoalCancelled => 'Zrušeno';

  @override
  String get mobileGoalBudgetExhausted => 'Vyčerpán rozpočet';

  @override
  String mobileGoalFailures(String count) {
    return 'Počet po sobě jdoucích neúspěšných běhů: $count';
  }

  @override
  String get mobileGoalFailedDescription =>
      'Dohlížející proces se po opakovaných neúspěšných bězích zastavil. Podrobnosti najdete v konverzaci.';

  @override
  String get mobileGoalPause => 'Pozastavit cíl';

  @override
  String get mobileGoalResume => 'Obnovit cíl';

  @override
  String get mobileGoalStop => 'Zrušit cíl';

  @override
  String get mobileGoalStopConfirm =>
      'Trvale zrušit tento cíl pod dohledem? Nebude možné ho obnovit.';

  @override
  String get mobileGoalRaiseBudget => 'Zvýšit rozpočet a pokračovat';

  @override
  String mobileGoalRaiseTo(String amount) {
    return 'Zvýšit rozpočet na $amount a pokračovat';
  }

  @override
  String mobileGoalRaiseConfirm(String oldCap, String newCap) {
    return 'Zvýšit strop nákladů na tento cíl z $oldCap na $newCap a obnovit utrácení?';
  }

  @override
  String get mobileGoalOpenConversation => 'Otevřít konverzaci k cíli';

  @override
  String get mobileGoalCreate => 'Spustit cíl pod dohledem';

  @override
  String get mobileGoalChooseSpace => 'Spustit v prostoru';

  @override
  String get mobileGoalNoSpaces => 'Před spuštěním cíle vytvořte prostor.';

  @override
  String get mobileGoalChooseAgent => 'Spustit s agentem';

  @override
  String get mobileGoalNoAgents =>
      'Před spuštěním cíle přidejte aktivního agenta.';

  @override
  String mobileGoalSelectedAgent(String name) {
    return 'Vybrán agent $name';
  }

  @override
  String get mobileGoalObjectiveHint => 'Jakého výsledku má agent dosáhnout?';

  @override
  String get mobileGoalBudgetUsd => 'Strop nákladů (USD)';

  @override
  String get mobileGoalCreateInvalid =>
      'Vyberte prostor a agenta, zadejte cíl a nastavte kladný strop nákladů v USD.';

  @override
  String mobileGoalCreateConfirm(String cap) {
    return 'Spustit cíl pod dohledem s maximálními náklady $cap? Agent může začít ihned.';
  }

  @override
  String get mobileGoalUnavailable =>
      'Připojení k serveru není připravené. Zkuste to znovu po obnovení spojení.';

  @override
  String get mobileGoalConversationMissing =>
      'Vybraná konverzace už není v tomto pracovním prostoru dostupná.';

  @override
  String get mobileGoalCreateSent =>
      'Cíl spuštěn. Stav dohledu se zobrazí v tomto seznamu.';

  @override
  String get mobileGoalStartRefused =>
      'Běh cíle nezačal. Důvod od dohlížejícího procesu najdete v konverzaci.';

  @override
  String mobileGoalSelectedSpace(String name) {
    return 'Vybrán prostor $name';
  }

  @override
  String get requestUnavailable =>
      'Tento požadavek už není v aktivním pracovním prostoru dostupný.';

  @override
  String get requestAlreadyResolved => 'Tento požadavek už byl vyřešen.';

  @override
  String get inboxCredentialsBlocked => 'Přihlašovací údaje blokující běhy';

  @override
  String get inboxSyncFailures => 'Neúspěšné synchronizace dodavatelů';

  @override
  String get inboxConfigureCredentials => 'Nastavit přihlašovací údaje';

  @override
  String get openTicket => 'Otevřít ticket';

  @override
  String get activityTitle => 'Aktivita';

  @override
  String get activityClearAll => 'Vymazat aktivitu';

  @override
  String get activityClearConfirm =>
      'Tím se skryje veškerá vaše dosud zaznamenaná aktivita na všech zařízeních. Nová aktivita se bude dál zobrazovat.';

  @override
  String get activityMarkAllRead => 'Označit vše jako přečtené';

  @override
  String get activityMarkAllConfirm =>
      'Označit všechny položky aktivity v tomto pracovním prostoru na všech vašich zařízeních jako přečtené?';

  @override
  String get activityMarkRead => 'Označit jako přečtené';

  @override
  String get activityMarkUnread => 'Označit jako nepřečtené';

  @override
  String get activityDismiss => 'Zavřít';

  @override
  String get activityResolved => 'Vyřešeno';

  @override
  String get activityOpen => 'Otevřený';

  @override
  String get activityEmpty => 'Zatím žádná aktivita';

  @override
  String get activityLoadFailed => 'Aktivitu se nepodařilo načíst';

  @override
  String get activityAgentWaiting => 'Agent potřebuje vstup';

  @override
  String get activityAgentBlocked => 'Akce agenta byla zablokována';

  @override
  String get activityMessage => 'Nová zpráva';

  @override
  String get activityPullRequest => 'Aktualizace pull requestu';

  @override
  String get activityRig => 'Aktualizace zařízení';

  @override
  String get activityEvent => 'Aktualizovat';

  @override
  String get activityPrReady => 'Pull request připraven ke sloučení';

  @override
  String get activityPrBlocked => 'Sloučení pull requestu zablokováno';

  @override
  String get activityPrApproved => 'Pull request schválen';

  @override
  String get activityPrChanges => 'Vyžádány změny';

  @override
  String get activityPrChecksFailed => 'Kontroly pull requestu selhaly';

  @override
  String get activityPrChecksRecovered =>
      'Kontroly pull requestu opět procházejí';

  @override
  String get activityPrComment => 'Komentář k pull requestu';

  @override
  String get activityPrPublished => 'Pull request publikován';

  @override
  String get activityPrMerged => 'Pull request sloučen';

  @override
  String get activityPrMentioned => 'Zmínka v pull requestu';

  @override
  String get activityPrReviewRequested => 'Vyžádána kontrola';

  @override
  String get activityPrReviewStale => 'Kontrolu je třeba aktualizovat';

  @override
  String get activityTicketAssigned => 'Ticket přiřazen';

  @override
  String get activityTicketChanged => 'Stav ticketu se změnil';

  @override
  String get activityMeetingSoon => 'Schůzka brzy začíná';

  @override
  String get activityCalendarExpired => 'Platnost připojení kalendáře vypršela';

  @override
  String get activityRigControl => 'Ovládání zařízení změněno';

  @override
  String get activityRigClosed => 'Zařízení se zastavilo';

  @override
  String get mobileSpacesSearch => 'Hledat prostory';

  @override
  String get mobileSpacesArchived => 'Archivováno';

  @override
  String get mobileSpacesActive => 'Aktivní';

  @override
  String get mobileSpacesNew => 'Nový prostor';

  @override
  String get mobileSpacesManage => 'Spravovat prostor';

  @override
  String get mobileSpacesName => 'Název prostoru';

  @override
  String get mobileSpacesAgents => 'Agenti';

  @override
  String get mobileSpacesMembers => 'Lidé';

  @override
  String get mobileSpacesRepos => 'Repozitáře';

  @override
  String get mobileSpacesAllRepos => 'Všechny propojené repozitáře';

  @override
  String get mobileSpacesNoRepos => 'Žádné repozitáře';

  @override
  String get mobileSpacesBaseBranch => 'Výchozí větev pro práci (volitelné)';

  @override
  String get mobileSpacesDefaultBranch => 'Výchozí větev';

  @override
  String get mobileSpacesMode => 'Režim';

  @override
  String get mobileSpacesModeChat => 'Chat';

  @override
  String get mobileSpacesModeReview => 'Kontrola (jen pro čtení)';

  @override
  String get mobileSpacesModePlan => 'Plán (jen pro čtení)';

  @override
  String get mobileSpacesModeOrchestrate => 'Orchestrace';

  @override
  String get mobileSpacesAutonomy => 'Přepsání autonomie';

  @override
  String get mobileSpacesAutonomyInherited => 'Zděděno';

  @override
  String get mobileSpacesAutonomyPropose => 'Jen navrhovat';

  @override
  String get mobileSpacesAutonomyApproval => 'Jednat se schválením';

  @override
  String get mobileSpacesAutonomyFreely => 'Jednat volně';

  @override
  String get mobileSpacesAutonomyNotice =>
      'Přepsání nemůže obejít výzvy ani zákazy podle zásad akcí. Změnit ho mohou jen správci pracovního prostoru.';

  @override
  String get mobileSpacesArchive => 'Archivovat prostor';

  @override
  String get mobileSpacesReopen => 'Znovu otevřít prostor';

  @override
  String get mobileSpacesSave => 'Uložit změny';

  @override
  String get mobileSpacesCreate => 'Vytvořit prostor';

  @override
  String get mobileSpacesOperationFailed =>
      'Prostor se nepodařilo aktualizovat';

  @override
  String get mobileSpacesMissing =>
      'Prostor nebyl v tomto pracovním prostoru nalezen';

  @override
  String get mobileSpacesEmptyName => 'Zadejte název prostoru';

  @override
  String get mobileSpacesNoMatches => 'Žádné odpovídající prostory';

  @override
  String get mobileSpacesUnread => 'Nepřečtená odpověď agenta';

  @override
  String get mobileSpacesNeedsInput => 'Vyžaduje váš vstup';

  @override
  String get mobileSpacesRunning => 'Agent běží';

  @override
  String get mobileSpacesNoAgents =>
      'V tomto pracovním prostoru nejsou žádní agenti';

  @override
  String get mobileSpacesNoMembers => 'Žádní další členové pracovního prostoru';

  @override
  String get mobileSpacesRepoError => 'Repozitáře se nepodařilo načíst';

  @override
  String get mobileSpacesRetry => 'Zopakovat';

  @override
  String get mobileSpacesBranchUnavailable =>
      'Při vytváření prostoru vyberte nebo zadejte výchozí větev pro práci; u existujícího prostoru ji nelze změnit.';

  @override
  String get mobileSpacesArchivedEmpty => 'Žádné archivované prostory';

  @override
  String get mobileSpacesAllRepoWarning =>
      'Nově propojené repozitáře pracovního prostoru budou také zahrnuty v tomto prostoru.';

  @override
  String get mobileSpacesCreatedRetry =>
      'Prostor vytvořen. Zkuste znovu přidat lidi nebo otevřete stránku správy.';

  @override
  String get progressTitle => 'Průběh';

  @override
  String get progressConversation => 'Konverzace';

  @override
  String get progressLoadFailed => 'Průběh se nepodařilo načíst';

  @override
  String get progressUnavailable => 'Konverzace není dostupná';

  @override
  String get progressUnavailableDescription =>
      'Tato konverzace není v aktivním pracovním prostoru a prostoru. Vraťte se do jejího prostoru a pokračujte.';

  @override
  String get progressSaveFailed => 'Průběh se nepodařilo aktualizovat';

  @override
  String get progressGoal => 'Cíl';

  @override
  String get progressNoGoal => 'Není nastaven pracovní cíl';

  @override
  String get progressSetGoal => 'Nastavit cíl';

  @override
  String get progressEditGoal => 'Upravit cíl';

  @override
  String get progressClearGoal => 'Vymazat cíl';

  @override
  String get progressGoalRequired => 'Před uložením zadejte cíl.';

  @override
  String get progressTodos => 'Úkoly';

  @override
  String get transcriptToolTodos => 'Úkoly';

  @override
  String get transcriptToolSearchMemory => 'Prohledat paměť';

  @override
  String get transcriptToolRenderMedia => 'Vykreslit média';

  @override
  String get progressNoTodos => 'Zatím žádné úkoly';

  @override
  String get progressNewTodo => 'Nový úkol';

  @override
  String get progressAddTodo => 'Přidat úkol';

  @override
  String get progressEditTodo => 'Upravit úkol';

  @override
  String get progressTodoRequired => 'Před uložením zadejte úkol.';

  @override
  String get progressTodoNoLongerExists =>
      'Tento úkol byl odstraněn. Načtěte seznam znovu a opakujte akci.';

  @override
  String get progressWorkspaceChanged =>
      'Aktivní pracovní prostor se změnil. Vraťte se do této konverzace a zkuste to znovu.';

  @override
  String progressRemoveTodo(String name) {
    return 'Odebrat úkol $name';
  }

  @override
  String get progressPending => 'Čeká';

  @override
  String get progressInProgress => 'Probíhá';

  @override
  String get progressCompleted => 'Dokončeno';

  @override
  String get progressMoveUp => 'Posunout úkol nahoru';

  @override
  String get progressMoveDown => 'Posunout úkol dolů';

  @override
  String get progressRunTree => 'Běhy agentů';

  @override
  String get progressNoRuns => 'Zatím žádné běhy v této konverzaci';

  @override
  String get progressRunning => 'Běží';

  @override
  String get progressFailed => 'Selhalo';

  @override
  String get progressUnknown => 'Neznámé';

  @override
  String get progressHealthy => 'Aktivní';

  @override
  String get progressBlocked => 'Blokováno';

  @override
  String get progressLooping => 'Opakuje se ve smyčce';

  @override
  String get progressStalled => 'Zaseknutý';

  @override
  String get progressDead => 'Neočekávaně zastaven';

  @override
  String get progressQuiet => 'Zatím žádný výstup';

  @override
  String get progressCostReported => 'Poplatek nahlášený poskytovatelem';

  @override
  String get progressCostNotional =>
      'Orientační ceníková cena předplatného, nikoli vyúčtování';

  @override
  String get progressCostMixed => 'Kombinované zdroje nákladů';

  @override
  String get progressCostEstimated => 'Odhadované náklady';

  @override
  String progressDurationSeconds(String seconds) {
    return '$seconds s';
  }

  @override
  String progressRunDetails(String model, String duration, String cost) {
    return 'Model: $model · Čas: $duration · Náklady: $cost';
  }

  @override
  String progressStartedAt(String time) {
    return 'Spuštěno $time';
  }

  @override
  String progressLiveness(String state) {
    return 'Stav: $state';
  }

  @override
  String progressRunTokens(String input, String output) {
    return 'Vstup: $input · Výstup: $output tokenů';
  }

  @override
  String get progressOutputPreviewLimited =>
      'Zobrazuje se jen prvních 6 000 znaků strukturovaného výstupu.';

  @override
  String progressRetryOf(String runId) {
    return 'Opakování běhu $runId';
  }

  @override
  String get progressContext => 'Kontext a limity';

  @override
  String get progressNoAgent => 'Žádný agent k prohlédnutí';

  @override
  String progressContextReading(String used, String window) {
    return '$used / $window tokenů';
  }

  @override
  String get progressMeasured =>
      'Kontext nahlášený poskytovatelem při posledním volání';

  @override
  String get progressEstimated =>
      'Odhad ze zaznamenané konverzace a trvalého kontextu';

  @override
  String get progressContextUnknown =>
      'Využití kontextu zatím nebylo nahlášeno';

  @override
  String progressContextPercent(String percent) {
    return '$percent % kontextového okna';
  }

  @override
  String progressMonthlyBudget(String amount) {
    return 'Nastavený měsíční limit agenta: $amount';
  }

  @override
  String progressConversationTokens(String tokens) {
    return 'Uložená aktivní konverzace: přibližně $tokens tokenů';
  }

  @override
  String progressInspectionFor(String agent, String model) {
    return 'Trvalý kontext pro $agent · $model';
  }

  @override
  String get progressContextSystem => 'Systémový prompt';

  @override
  String get progressContextRules => 'Pravidla';

  @override
  String get progressContextSkills => 'Dovednosti';

  @override
  String get progressContextTools => 'Definice nástrojů';

  @override
  String get progressContextMcp => 'Nástroje MCP';

  @override
  String get progressContextDeferred => 'Odložené nástroje';

  @override
  String get progressContextSubagents => 'Subagenti';

  @override
  String get progressContextRunner => 'Externí spouštěč';

  @override
  String get progressContextMemory => 'Paměť';

  @override
  String get progressContextHistory => 'Historie konverzace';

  @override
  String progressContextSegment(String label, String tokens) {
    return '$label · $tokens tokenů';
  }

  @override
  String progressContextPart(String title, String tokens) {
    return '$title · $tokens tokenů';
  }

  @override
  String get progressOutputs => 'Nedávné výstupy';

  @override
  String get progressNoOutputs => 'Žádné nedávné výstupy agentů';

  @override
  String get progressStructuredOutputsAbove =>
      'Strukturované výstupy běhů jsou zobrazeny mezi běhy agentů výše.';

  @override
  String get progressRecentOutputsOnly =>
      'Zobrazují se jen nedávné zprávy. Starší práci najdete v konverzaci.';

  @override
  String get progressPlan => 'Plán';

  @override
  String get progressArtifact => 'Artefakt';

  @override
  String get progressResult => 'Výsledek';

  @override
  String get progressHideArtifact => 'Skrýt artefakt';

  @override
  String get progressReadArtifact => 'Přečíst artefakt';

  @override
  String get progressArtifactUnavailable => 'Artefakt už není dostupný';

  @override
  String get progressArtifactPreviewLimited =>
      'Zobrazuje se omezený náhled tohoto artefaktu.';

  @override
  String get progressDiagramSource => 'Zdrojový kód diagramu';

  @override
  String progressOpenAttachment(String name) {
    return 'Otevřít $name';
  }

  @override
  String get progressOpenPlan => 'Otevřít plán';

  @override
  String progressOpenDiff(String label) {
    return 'Zkontrolovat změněné soubory: $label';
  }

  @override
  String get progressViewMessage => 'Zobrazit zprávu';

  @override
  String get pushTitle => 'Oznámení na pozadí';

  @override
  String get pushIntro =>
      'Dostávejte soukromá upozornění, když něco vyžaduje vaši pozornost, i když je aplikace zavřená. Podrobnosti zůstávají ve vašem šifrovaném spojení.';

  @override
  String get pushLoading => 'Kontrola nastavení oznámení…';

  @override
  String get pushError =>
      'Oznámení se nepodařilo aktualizovat. Zkontrolujte připojení a zkuste to znovu.';

  @override
  String get pushEnable => 'Zapnout oznámení';

  @override
  String get pushDisable => 'Vypnout oznámení';

  @override
  String get pushQuiet => 'Pozastavit upozornění na tomto zařízení';

  @override
  String get pushCategories => 'Upozorňovat na';

  @override
  String get pushCategoryAgents => 'Agenti';

  @override
  String get pushCategoryMessages => 'Zprávy';

  @override
  String get pushCategoryPullRequests => 'Pull requesty';

  @override
  String get pushCategoryTickets => 'Tickety';

  @override
  String get pushCategoryCalendar => 'Kalendář';

  @override
  String get pushCategoryMachines => 'Počítače';

  @override
  String get pushSecureOrigin => 'Oznámení vyžadují HTTPS.';

  @override
  String get pushInstallIos =>
      'Na iPhonu nebo iPadu si přidejte aplikaci na plochu a spusťte ji odtud, abyste mohli zapnout oznámení.';

  @override
  String get pushUnsupported =>
      'Tento prohlížeč nepodporuje oznámení na pozadí.';

  @override
  String get pushDenied =>
      'Prohlížeč hlásí zablokovaná oznámení. Zkontrolujte oprávnění tohoto webu a nastavení oznámení v prohlížeči nebo zařízení a pak stránku obnovte.';

  @override
  String get pushOsHint =>
      'Prohlížeč také potřebuje oprávnění zobrazovat oznámení v systémovém nastavení zařízení.';

  @override
  String get pushServiceUnavailable =>
      'Služba push v prohlížeči odmítla odběr. Některé prohlížeče, například Brave, ji mají ve výchozím stavu vypnutou: v nastavení soukromí prohlížeče vyhledejte volbu pro push zprávy a zkuste to znovu.';

  @override
  String get pushWorkerUnavailable =>
      'Službu oznámení se v tomto prohlížeči nepodařilo spustit. Načtěte stránku znovu a zkuste to znovu.';

  @override
  String get pushResubscribe => 'Znovu připojit oznámení';

  @override
  String get pushStatusEnabled => 'Oznámení jsou na tomto zařízení zapnutá.';

  @override
  String get pushStatusDisabled => 'Oznámení jsou na tomto zařízení vypnutá.';

  @override
  String get credentialsTitle => 'Připojení a přihlašovací údaje';

  @override
  String get credentialsIntro =>
      'Propojte účty, které používají vaše běhy a integrace. Tajné údaje se ukládají na vašem serveru, nikoli v tomto telefonu.';

  @override
  String get credentialsModelProviders => 'Poskytovatelé modelů';

  @override
  String get credentialsOwnerOnly =>
      'Pouze vlastník serveru může přidávat nebo odebírat přihlašovací údaje poskytovatelů modelů a přihlašovat se k nim. Tyto klíče se sdílejí mezi pracovními prostory.';

  @override
  String get credentialsContactOwner =>
      'Požádejte vlastníka serveru, aby připojil poskytovatele potřebného pro zablokovaný běh.';

  @override
  String get credentialsClaudeCode => 'Claude Code';

  @override
  String get credentialsClaudeHostOnly =>
      'Claude Code se na hostitelském zařízení přihlašuje přes příkazový řádek. Požádejte vlastníka serveru o dokončení nebo obnovení přihlášení k účtu v terminálu hostitele; z tohoto telefonu to není možné.';

  @override
  String get credentialsYourForgeAccounts => 'Vaše účty služeb pro správu kódu';

  @override
  String get credentialsYourTicketingAccount => 'Váš účet služby pro tickety';

  @override
  String get credentialsLocalTicketsNoLogin =>
      'Místní tickety nevyžadují přihlášení. Pokud váš pracovní prostor používá Linear, připojte ho zde.';

  @override
  String get credentialsMembershipRequired =>
      'Abyste mohli spravovat přihlašovací údaje ke službám pro správu kódu nebo tickety, připojte se k pracovnímu prostoru. O přístup požádejte správce pracovního prostoru.';

  @override
  String get credentialsSwitchWorkspace =>
      'Tento odkaz vede do jiného pracovního prostoru. Před změnou přihlašovacích údajů se do něj přepněte.';

  @override
  String get credentialsReturnToInbox =>
      'Po připojení potřebných přihlašovacích údajů se vraťte do doručené pošty a zkuste zablokovaný běh znovu. Hostitel také automaticky kontroluje pozastavené běhy.';

  @override
  String get credentialsLoadFailed =>
      'Připojení se nepodařilo načíst. Zkontrolujte spojení se serverem a zkuste to znovu.';

  @override
  String get credentialsOperationFailed =>
      'Připojení se nepodařilo změnit. Zkontrolujte spojení se serverem, svůj přístup a přihlašovací údaje a zkuste to znovu.';

  @override
  String get credentialsConnected => 'Připojeno';

  @override
  String get credentialsNotConnected => 'Nepřipojeno';

  @override
  String credentialsSignedInAs(String username) {
    return 'Přihlášeno jako $username';
  }

  @override
  String get credentialsAccount => 'Připojený účet';

  @override
  String get credentialsStoredKey => 'Uložený klíč';

  @override
  String get credentialsActive => 'Aktivní';

  @override
  String get credentialsRemove => 'Odebrat';

  @override
  String get credentialsRemoveConfirm =>
      'Odebrat uložené přihlašovací údaje? Možná se budete muset znovu přihlásit.';

  @override
  String get credentialsApiKey => 'API klíč';

  @override
  String get credentialsApiKeyHint => 'Vložte API klíč poskytovatele';

  @override
  String get credentialsBrowserLogin => 'Přihlásit se v prohlížeči';

  @override
  String get credentialsSignInAgain => 'Přihlaste se znovu';

  @override
  String get credentialsWaitingForLogin => 'Čekání na autorizaci v prohlížeči…';

  @override
  String get credentialsConnectCodePrompt => 'Potvrzovací kód';

  @override
  String get credentialsConnectCodeMalformed =>
      'To nevypadá jako přihlašovací kód. Kódy mají 8 písmen a číslic.';

  @override
  String get credentialsSignInInvalidCode =>
      'Tento kód k tomuto přihlášení nepatří. Zkontrolujte ho a zkuste to znovu.';

  @override
  String get credentialsSignInTooManyCodes =>
      'Příliš mnoho chybných kódů. Spusťte přihlášení znovu.';

  @override
  String get credentialsSignInRetryLater =>
      'Služba přihlášení právě neodpovídá. Počkejte minutu a zkuste to znovu.';

  @override
  String get credentialsSignInRefused =>
      'Přihlášení bylo odmítnuto. Spusťte ho znovu a schvalte všechna požadovaná oprávnění.';

  @override
  String get credentialsSignInNotSaved =>
      'Přihlášení proběhlo, ale server ho nedokázal uložit. Zkuste to znovu.';

  @override
  String credentialsSignInUnavailable(String provider) {
    return 'Přihlášení k $provider zatím na tomto serveru není nastavené.';
  }

  @override
  String get credentialsSignInPhoneUnreachable =>
      'Zpětná adresa přihlášení tohoto serveru není z telefonu bezpečně dostupná. Přihlaste se v desktopové aplikaci, nebo požádejte vlastníka serveru o nastavení veřejné adresy HTTPS.';

  @override
  String get credentialsLoginTimedOut =>
      'Platnost přihlášení vypršela. Začněte nové přihlášení.';

  @override
  String get credentialsCopyCode => 'Kopírovat kód';

  @override
  String get credentialsDeviceCodeHint =>
      'Potvrďte tento kód na stránce poskytovatele. Nechte tuto obrazovku otevřenou, dokud server nedokončí přihlášení.';

  @override
  String get credentialsPasteRedirect =>
      'Autorizační kód nebo adresa URL přesměrování';

  @override
  String get credentialsPasteRedirectHint =>
      'Vložte kód nebo úplnou adresu URL přesměrování od poskytovatele';

  @override
  String get credentialsCompleteLogin => 'Dokončit přihlášení';

  @override
  String get credentialsUpdateToken => 'Aktualizovat token';

  @override
  String get credentialsAddToken => 'Přidat token';

  @override
  String get credentialsPersonalToken => 'Osobní přístupový token';

  @override
  String get credentialsPersonalTokenHint => 'Vložte osobní přístupový token';

  @override
  String get credentialsStopWatching => 'Přestat sledovat';

  @override
  String get transcriptClaudeSignInExpiredTitle =>
      'Přihlášení ke Claude Code vypršelo';

  @override
  String get transcriptClaudeSignInExpiredBody =>
      'Běh se zastavil, protože jeho účet se už neověřuje. Přihlaste se znovu a pak tah zopakujte.';

  @override
  String get transcriptSignInExpiredTitle =>
      'Přihlášení k poskytovateli vypršelo';

  @override
  String get transcriptSignInExpiredBody =>
      'Běh se zastavil, protože přihlašovací údaje poskytovatele už nefungují. Znovu jej připojte v Nastavení → Poskytovatelé a pak tah zopakujte.';

  @override
  String get permissionHostExecution => 'Spouštět příkazy na hostiteli';

  @override
  String credentialsSignInLapsed(String provider) {
    return 'Vaše přihlášení k $provider vypršelo. Přihlaste se znovu.';
  }

  @override
  String get credentialsSignInPaused =>
      'Pozastaveno: přihlašovací služba tohoto pracovního prostoru se změnila. Znovu začne fungovat, jakmile bude služba zpět.';

  @override
  String credentialsProviderUnreachable(String provider) {
    return '$provider teď není dostupný. Zkouší se znovu.';
  }

  @override
  String get credentialsScopeWorkspace => 'Jen tento pracovní prostor';

  @override
  String get credentialsScopeAllWorkspaces => 'Všechny pracovní prostory';

  @override
  String get credentialsRemoveConfirmWorkspace =>
      'Odebrat uložené přihlašovací údaje z tohoto pracovního prostoru? Ostatní si ponechají své.';

  @override
  String get credentialsRemoveConfirmAllWorkspaces =>
      'Odebrat uložené přihlašovací údaje ze všech pracovních prostorů, které je sdílejí?';

  @override
  String get credentialsSignInServerRestarted =>
      'Server se restartoval. Začněte přihlášení znovu.';

  @override
  String repoAccessInstallApp(String owner, String names) {
    return 'Nainstalujte GitHub App na $owner, aby se automatizace dostala k $names. Klepnutím otevřete GitHub.';
  }

  @override
  String repoAccessAskAdminInstall(String owner, String names) {
    return 'GitHub App není na $owner nainstalovaná, takže se automatizace k $names nedostane. Požádejte správce pracovního prostoru o instalaci.';
  }

  @override
  String repoAccessAddToApp(String names) {
    return 'Přidejte $names mezi repozitáře GitHub App. Klepnutím otevřete GitHub.';
  }

  @override
  String repoAccessAskAdminAdd(String names) {
    return 'GitHub App zatím $names nevidí. Požádejte správce pracovního prostoru, aby je přidal mezi její repozitáře.';
  }

  @override
  String repoAccessSuspended(String names) {
    return 'Instalace GitHub App je pozastavena. Automatizace pro $names je pozastavená, dokud vlastník účtu neobnoví instalaci na GitHubu.';
  }

  @override
  String repoAccessOwnerCannotSee(String names) {
    return 'Osoba odpovědná za automatizaci tohoto pracovního prostoru už $names nevidí, takže tam jejím jménem nic neběží.';
  }

  @override
  String repoAccessOwnerNotSignedIn(String names) {
    return 'Osoba odpovědná za automatizaci tohoto pracovního prostoru není přihlášená ke forge, takže automatizace pro $names čeká, dokud se nepřihlásí.';
  }

  @override
  String repoAccessRetrying(String names) {
    return 'Přístup k $names se nepodařilo ověřit. Zkouší se znovu.';
  }

  @override
  String hiddenReposSignIn(int count, String forge) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Přihlaste se k $forge, abyste viděli pull requesty z dalších repozitářů: $count',
      one:
          'Přihlaste se k $forge, abyste viděli pull requesty z dalšího repozitáře',
    );
    return '$_temp0';
  }

  @override
  String hiddenReposNoForgeAccess(int count, String forge) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Skryté repozitáře, které váš účet $forge nevidí: $count',
      one: '1 repozitář je skrytý, protože ho váš účet $forge nevidí',
    );
    return '$_temp0';
  }

  @override
  String hiddenReposNoGrant(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Skryté repozitáře, ke kterým v tomto pracovním prostoru nemáte přístup: $count',
      one:
          '1 repozitář je skrytý, protože k němu v tomto pracovním prostoru nemáte přístup',
    );
    return '$_temp0';
  }

  @override
  String hiddenReposChecking(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ověřuje se váš přístup k dalším repozitářům: $count…',
      one: 'Ověřuje se váš přístup k dalšímu repozitáři…',
    );
    return '$_temp0';
  }

  @override
  String get credentialsAtlassianEmail => 'E-mail účtu Atlassian';

  @override
  String get credentialsAtlassianEmailInvalid =>
      'Zadejte e-mailovou adresu svého účtu Atlassian.';

  @override
  String get credentialsBitbucketApiToken => 'Token API';

  @override
  String repoAccessAutomationTokenMissing(String names) {
    return 'Žádný automatizační token nemůže číst $names, takže práce na pozadí je tam pozastavena. Správce může token přidat v Nastavení → Repozitáře.';
  }

  @override
  String get credentialsSignInConfirmInBrowser =>
      'Potvrďte v prohlížeči a poté zadejte zobrazený kód.';

  @override
  String get credentialsSignInAccountAlreadyBound =>
      'Tento účet je už připojen k jiné osobě na tomto serveru. Přihlaste se jiným účtem.';

  @override
  String credentialsTokenUnreachable(String provider) {
    return '$provider nebyl dostupný, takže nelze tento token ověřit. Zkuste to za chvíli znovu.';
  }

  @override
  String credentialsTokenRejected(String provider) {
    return '$provider tento token nepřijímá. Zkontrolujte, zda jste zkopírovali celý a zda nebyl zrušen.';
  }

  @override
  String credentialsTokenWrongKind(String provider) {
    return 'Toto není osobní token. Vložte osobní přístupový token z vlastního účtu $provider, ne token projektu, skupiny, pracovního prostoru nebo bota.';
  }

  @override
  String credentialsTokenNarrowScope(String scope) {
    return 'Tomuto tokenu chybí oprávnění $scope, které je potřeba k revizím a komentářům. Vytvořte token, který ho má.';
  }

  @override
  String get credentialsTokenExpired =>
      'Platnost tohoto tokenu vypršela. Vytvořte nový a vložte jej sem.';

  @override
  String get credentialsSignInRateLimited =>
      'Právě teď je příliš mnoho požadavků. Počkejte chvilku a zkuste to znovu.';

  @override
  String get credentialsSignInCancelled =>
      'Přihlášení bylo zrušeno nebo odmítnuto. Spusťte je znovu, až budete připraveni.';

  @override
  String get credentialsSignInNoLongerOpen =>
      'Toto přihlášení už není otevřené: bylo zrušeno, použito nebo nahrazeno. Spusťte je znovu.';

  @override
  String get noWorkspacesYetHint =>
      'Správce pracovního prostoru vás musí pozvat, nebo vám vlastník serveru může pracovní prostor vytvořit.';

  @override
  String repoAccessReplaced(String repos, String forge) {
    return '$repos nyní ukazuje na jiný repozitář na $forge. Pokud s ním chcete dál pracovat, znovu jej propojte v desktopové nebo webové aplikaci.';
  }

  @override
  String repoAccessAskAdminRelink(String repos, String forge) {
    return '$repos nyní ukazuje na jiný repozitář na $forge. Správce pracovního prostoru jej musí znovu propojit, než půjde znovu použít.';
  }

  @override
  String get runSandboxUnavailableTitle =>
      'Agenti na tomto serveru potřebují sandbox';

  @override
  String get runSandboxUnavailable =>
      'Tento server nemá sandbox, takže zde agenty může spouštět jen jeho vlastník. Vlastník může sandbox nainstalovat nebo sandboxing vypnout pro všechny.';

  @override
  String get scriptToolCalls => 'Volání nástrojů';

  @override
  String scriptCallCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count volání',
      few: '$count volání',
      one: '1 volání',
    );
    return '$_temp0';
  }

  @override
  String scriptCallsRunning(int count) {
    return '$count běží';
  }

  @override
  String scriptCallsOk(int count) {
    return '$count v pořádku';
  }

  @override
  String scriptCallsFailed(int count) {
    return '$count selhalo';
  }

  @override
  String scriptCallsDenied(int count) {
    return '$count zakázáno';
  }

  @override
  String scriptCallsCancelled(int count) {
    return '$count zrušeno';
  }

  @override
  String scriptCallsQueued(int count) {
    return '$count ve frontě';
  }

  @override
  String scriptCallsSkipped(int count) {
    return '$count přeskočeno';
  }

  @override
  String get scriptStepQueued => 'Ve frontě';

  @override
  String get scriptStepSkipped => 'Přeskočeno';

  @override
  String get scriptGroupLoop => 'Smyčka';

  @override
  String get scriptGroupEach => 'Pro každé';

  @override
  String get scriptGroupParallel => 'Paralelně';

  @override
  String get scriptGroupFunction => 'Funkce';

  @override
  String scriptCallsHidden(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Zobrazit $count dalších volání',
      few: 'Zobrazit $count další volání',
      one: 'Zobrazit 1 další volání',
    );
    return '$_temp0';
  }

  @override
  String get scriptCallsUnplaced => 'Volání neumístěná ve skriptu';

  @override
  String get scriptToolComputed => 'Nástroj';

  @override
  String scriptStepSemantics(String subject, String state) {
    return '$subject, $state';
  }

  @override
  String get scriptSourceLabel => 'Skript';

  @override
  String scriptSourceLines(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count řádků',
      few: '$count řádky',
      one: '1 řádek',
    );
    return '$_temp0';
  }

  @override
  String get scriptStateRunning => 'Běží';

  @override
  String get scriptStateCompleted => 'Dokončeno';

  @override
  String get scriptStateFailed => 'Selhalo';

  @override
  String get scriptStateTimedOut => 'Čas vypršel';

  @override
  String get scriptStateCancelled => 'Zrušeno';

  @override
  String get scriptStateMemoryExceeded => 'Nedostatek paměti';

  @override
  String get scriptStateOutputExceeded => 'Příliš mnoho výstupu';

  @override
  String get scriptStateSandboxError => 'Chyba sandboxu';

  @override
  String get scriptStateRefused => 'Odmítnuto';

  @override
  String get scriptOriginLine => 'Z skriptu, který agent spouští';

  @override
  String get codeModeTitle => 'Režim kódu';

  @override
  String get codeModeAvailable => 'Dostupné';

  @override
  String get codeModeUnavailable => 'Nedostupné';

  @override
  String codeModeUnavailableNote(String reason) {
    return 'Tento server nemůže spouštět skripty, takže agenti tady volají své nástroje jeden po druhém. Server uvádí: $reason';
  }

  @override
  String get codeModeNoReason => 'nebyl uveden žádný důvod.';

  @override
  String get workKindUnknown => 'Z důvodu, který tato verze nezná:';

  @override
  String get workRefusalUnknown => 'Server toto odmítl:';

  @override
  String workActionFailed(String error) {
    return 'To nefungovalo: $error';
  }

  @override
  String get wakeKindStopped => 'Podrženo, protože osoba běh zastavila.';

  @override
  String get wakeKindAttempts => 'Doručení selhalo třikrát.';

  @override
  String get wakeKindAgentDeleted => 'Agent už neexistuje.';

  @override
  String get wakeKindAgentNotDispatchable => 'Agent je vyřazen.';

  @override
  String get wakeKindAgentPaused => 'Agent je pozastaven.';

  @override
  String get wakeKindPersonRemoved =>
      'Osoba, za kterou probuzení jedná, opustila pracovní prostor.';

  @override
  String get wakeKindBudgetBlocked => 'Rozpočet blokuje běh.';

  @override
  String get wakeKindTakeOver => 'Osoba převzala worktree.';

  @override
  String get wakeKindRateCapConversation =>
      'Tato konverzace spustila za poslední hodinu 30 běhů z probuzení.';

  @override
  String get wakeKindRateCapWorkspace =>
      'Tento pracovní prostor spustil za poslední hodinu 300 běhů z probuzení.';

  @override
  String get wakeKindLiveRunNoInput => 'Živý běh agenta zde nepřijímá vstup.';

  @override
  String get wakeKindLiveRunOtherOptions =>
      'Živý běh agenta zde běží jinak, proto tohle spustí vlastní běh až po něm.';

  @override
  String get wakeKindLiveRunOtherPerson =>
      'Živý běh agenta zde jedná za jinou osobu, proto tohle spustí vlastní běh až po něm.';

  @override
  String get wakeKindDispatchRefused => 'Běh se nepodařilo spustit.';

  @override
  String get wakeKindSandboxUnavailable =>
      'Pro běh jen pro čtení není k dispozici sandbox.';

  @override
  String get wakeKindReadOnlyUnavailable =>
      'Backend tohoto agenta nedokáže udržet běh jen pro čtení.';

  @override
  String get wakeKindServerStopped => 'Restart serveru běh zastavil.';

  @override
  String get wakeKindServerRestarted =>
      'Server se restartoval během běhu osoby.';

  @override
  String get wakeKindGuardFailed => 'Kontrola před doručením selhala.';

  @override
  String get wakeKindLimit =>
      'Čeká, až se obnoví limit využití u poskytovatele.';

  @override
  String get wakeKindLimitRunLive => 'Čeká, až skončí běh na limitu využití.';

  @override
  String get wakeKindWakeMissed => 'Zmeškáno, když byl server vypnutý.';

  @override
  String get wakeKindPipelineRunEnded => 'Jeho běh pipeline skončil.';

  @override
  String get wakeKindGoalEnded => 'Jeho cíl skončil.';

  @override
  String get wakeKindGoalBudgetExhausted => 'Jeho cíl vyčerpal rozpočet.';

  @override
  String get wakeKindGoalReviewStale =>
      'Cíl se od vyžádání této kontroly změnil.';

  @override
  String get wakeKindGoalPaused => 'Jeho cíl je pozastaven.';

  @override
  String get wakeKindGoalHeld => 'Jeho cíl je podržen.';

  @override
  String get wakeKindGoalStopped => 'Jeho cíl byl zastaven.';

  @override
  String get wakeKindAskSettled =>
      'Otázka, na kterou odpovídá, už byla vyřešena.';

  @override
  String get wakeKindRuleEnded => 'Jeho plán skončil.';

  @override
  String get wakeRefusalNotYours =>
      'Toto probuzení jedná za jinou osobu. Doručit nebo obnovit ho může jen ona.';

  @override
  String get wakeRefusalSettled => 'Toto probuzení už bylo vyřízeno.';

  @override
  String get goalRefusalAlreadyActive => 'Tento agent už má aktivní cíl.';

  @override
  String get goalRefusalNotInReview => 'Tento cíl nečeká na kontrolu.';

  @override
  String get goalRefusalEvidenceIncomplete => 'Důkazy pro cíl jsou neúplné.';

  @override
  String get goalRefusalClaimPending =>
      'Tvrzení, že je hotovo, se ještě ověřuje.';

  @override
  String get goalRefusalNotActiveSegment =>
      'U tohoto cíle neběží žádný segment.';

  @override
  String get goalRefusalNotYours =>
      'Tohle může udělat jen osoba, která cíl spustila.';

  @override
  String get goalRefusalNotPaused => 'Nejprve cíl pozastavte.';

  @override
  String get goalRefusalContractInvalid => 'Zadání cíle nelze přečíst.';

  @override
  String get goalRefusalCheckerUnknown => 'Žádný agent nemá toto jméno.';

  @override
  String get goalRefusalCheckerAmbiguous => 'Více agentů má toto jméno.';

  @override
  String get goalRefusalCheckerIsGoalAgent =>
      'Ověřovatel musí být jiný agent, než který na cíli pracuje.';

  @override
  String get goalRefusalCommandInvalid => 'Tento cíl nelze přečíst:';

  @override
  String get wakeRuleRefusalIntervalTooShort =>
      'Interval je příliš krátký. Zvolte alespoň jednu minutu.';

  @override
  String get wakeRuleRefusalTooSoon =>
      'Tento čas je příliš brzy. Zvolte pozdější.';

  @override
  String get wakeRuleRefusalLineageEnded =>
      'Tento řetěz probuzení vyčerpal své běhy nebo svůj čas.';

  @override
  String get wakeRuleRefusalWatchTargetUnreadable =>
      'Nelze přečíst, co by to sledovalo.';

  @override
  String get wakeRuleRefusalExpiryRequired =>
      'Zadejte datum konce nebo počet běhů.';

  @override
  String get wakeRuleRefusalLimitReached =>
      'Tato konverzace nebo agent už má maximální povolený počet plánů.';

  @override
  String get wakeRuleRefusalInvalidWhen => 'Čas nelze přečíst.';

  @override
  String get wakeRuleRefusalNoteTooLong => 'Poznámka je příliš dlouhá.';

  @override
  String get wakeRuleRefusalExpiryTooLong => 'Konec je příliš daleko.';

  @override
  String get wakeRuleRefusalLimitOutOfRange =>
      'Limit běhů, dnů nebo rozpočtu je mimo rozsah.';

  @override
  String get wakeRuleRefusalNextOutsideLoop =>
      'Jen smyčka si může sama určit další čas.';

  @override
  String get wakeRuleRefusalWatchRefused => 'Toto nelze sledovat.';

  @override
  String get wakeRuleRefusalRuleEnded => 'Tento plán už skončil.';

  @override
  String get wakeRuleRefusalNotYours => 'Tento plán patří jiné osobě.';

  @override
  String get wakeRuleEndFired => 'Proběhl svůj jednorázový běh.';

  @override
  String get wakeRuleEndExpired => 'Dosáhl data konce.';

  @override
  String get wakeRuleEndRunCap => 'Vyčerpal své běhy.';

  @override
  String get wakeRuleEndCostCap => 'Dosáhl svého limitu nákladů.';

  @override
  String get wakeRuleEndGoalEnded => 'Jeho cíl skončil.';

  @override
  String get wakeRuleEndCancelled => 'Byl zrušen.';

  @override
  String get wakeRuleEndMemberRemoved =>
      'Osoba, které patřil, opustila pracovní prostor.';

  @override
  String get wakeRuleEndInvalidRow => 'Jeho uložená nastavení nešla přečíst.';

  @override
  String goalHoldWorking(int segment) {
    final intl.NumberFormat segmentNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String segmentString = segmentNumberFormat.format(segment);

    return 'Pracuje na segmentu $segmentString. Nikdo nemusí nic dělat.';
  }

  @override
  String get goalHoldWaiting =>
      'Čeká na práci, která mu náleží. Pokračuje sám.';

  @override
  String goalHoldWaitingUntil(String time) {
    return 'Čeká na práci, která mu náleží. Nejpozději v $time pokračuje sám.';
  }

  @override
  String get goalHoldVerifying =>
      'Tvrdí, že je hotovo. Server spustí jeho kontroly a poté rozhodne posuzující.';

  @override
  String get goalHoldLimit =>
      'Pozastaveno na limitu využití u poskytovatele. Po obnovení pokračuje samo.';

  @override
  String goalHoldLimitUntil(String time) {
    return 'Pozastaveno na limitu využití u poskytovatele. Pokračuje sám v $time.';
  }

  @override
  String get goalHoldPerson =>
      'Čeká, až osoba v konverzaci odpoví. Pokračuje, jakmile někdo odpoví.';

  @override
  String get goalHoldByPerson =>
      'Pozastavila osoba. Zůstává pozastaven, dokud ho někdo neobnoví.';

  @override
  String get goalHoldNeedsReview =>
      'Čeká na kontrolu: nemůže pokračovat sám. Schvalte ho jako hotový, obnovte ho, nebo ho zrušte.';

  @override
  String get goalHoldBudget =>
      'Vyčerpal svůj rozpočet. Zvyšte rozpočet, aby mohl pokračovat.';

  @override
  String goalHoldLimitParks(int count, int max) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);
    final intl.NumberFormat maxNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String maxString = maxNumberFormat.format(max);

    return 'Pozastavení kvůli limitu využití: $countString z $maxString';
  }

  @override
  String get goalHoldDetailStalled =>
      'V posledních segmentech nedošlo k žádnému pokroku.';

  @override
  String get goalHoldDetailStalledWaiting =>
      'Čekal 24 hodin na stejnou práci bez pokroku.';

  @override
  String get goalHoldDetailVerificationFailed => 'Poslední kontrola selhala.';

  @override
  String get goalHoldDetailCannotVerify =>
      'Ověřovatel nedokázal posoudit, zda je hotovo.';

  @override
  String get goalHoldDetailSandboxUnavailable =>
      'Pro spuštění jeho kontrol není k dispozici sandbox.';

  @override
  String get goalHoldDetailCheckerUnavailable =>
      'Jeho ověřovatel není dostupný. Vyberte jiného ověřovatele a poté pokračujte.';

  @override
  String get goalHoldDetailCheckBroken => 'Tuto kontrolu nelze spustit:';

  @override
  String get goalHoldDetailWakeSkipped => 'Jeho probuzení nebylo doručeno.';

  @override
  String get goalHoldDetailClaimPending =>
      'Jeho tvrzení, že je hotovo, čeká na kontrolu.';

  @override
  String get goalHoldDetailUnanswered =>
      'Otázka nebo žádost o schválení adresovaná osobě zůstala bez odpovědi.';

  @override
  String get goalHoldDetailLimitParks =>
      'Příliš často narážel na limity využití. Prohlédněte si ho a poté pokračujte.';

  @override
  String get goalHoldDetailInput => 'Čeká na odpověď v konverzaci.';

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

    return 'Segment $runString z $maxString';
  }

  @override
  String goalSegmentsNoCap(int run) {
    final intl.NumberFormat runNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String runString = runNumberFormat.format(run);

    return 'Segment $runString, bez limitu';
  }

  @override
  String goalMoney(String spent, String cap) {
    return 'Utraceno $spent z $cap';
  }

  @override
  String goalDeadline(String time) {
    return 'Termín $time';
  }

  @override
  String get goalPipelineStep => 'Tento cíl sleduje krok pipeline.';

  @override
  String get goalSummaryHeading => 'Poslední shrnutí';

  @override
  String get goalDoneMeans => 'Hotovo znamená';

  @override
  String get goalChecks => 'Kontroly';

  @override
  String get goalBoundaries => 'Hranice';

  @override
  String get goalStopWhen => 'Zastavit a zeptat se, když';

  @override
  String get goalNoMachineCheck =>
      'Bez strojové kontroly. Posuzující soudí z toho, co může přečíst.';

  @override
  String get goalCheckEnvironment => 'Úkol prostředí';

  @override
  String goalLastCheck(int round, String time) {
    final intl.NumberFormat roundNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String roundString = roundNumberFormat.format(round);

    return 'Poslední kontrola, kolo $roundString, $time';
  }

  @override
  String get goalClaim => 'Co tvrdil';

  @override
  String get goalCheckPassed => 'Prošlo';

  @override
  String goalCheckFailed(int code) {
    return 'Selhalo, návratový kód $code';
  }

  @override
  String get goalCheckTimedOut => 'Čas vypršel';

  @override
  String get goalCheckNotRerun => 'Znovu nespuštěno: nic se nezměnilo';

  @override
  String get goalCheckBroken => 'Nelze spustit';

  @override
  String get goalCriterionMet => 'Splněno';

  @override
  String get goalCriterionUnmet => 'Nesplněno';

  @override
  String get goalCriterionCannotTell => 'Nelze posoudit';

  @override
  String get goalVerdictPass => 'Verdikt: hotovo';

  @override
  String get goalVerdictFail => 'Verdikt: není hotovo';

  @override
  String get goalVerdictCannotVerify => 'Verdikt: nelze posoudit';

  @override
  String get goalConcerns => 'Výhrady';

  @override
  String goalVerifiedBy(String agent) {
    return 'Ověřil $agent';
  }

  @override
  String get goalVerifiedBySelf => 'Ověřil sám (bez samostatného ověřovatele)';

  @override
  String get goalClosedByPerson => 'Uzavřela osoba bez úspěšné kontroly';

  @override
  String get goalApprove => 'Schválit dokončení';

  @override
  String get goalApproveTitle => 'Uzavřít tento cíl jako hotový?';

  @override
  String get goalApproveBody =>
      'Žádná kontrola to nepotvrdila. Uzavřete cíl na vlastní slovo a cíl zaznamená, že ho osoba uzavřela neověřený.';

  @override
  String get goalApproveConfirm => 'Uzavřít jako hotové';

  @override
  String get goalResumeNotYours =>
      'Pokračovat v něm nebo zvýšit jeho rozpočet může jen ten, kdo ho spustil.';

  @override
  String get goalChooseChecker => 'Vyberte jiného ověřovatele';

  @override
  String goalCheckerSet(String agent) {
    return 'Kontroluje $agent. Pokračujte, aby se ověřil znovu.';
  }

  @override
  String get goalSchedules => 'Plány';

  @override
  String get goalRepeat => 'Opakovat';

  @override
  String get goalCreateChecks => 'Kontroly (volitelné)';

  @override
  String get goalCreateCheckHint =>
      'Příkaz, který projde, když je práce hotová';

  @override
  String get goalCreateAddCheck => 'Přidat kontrolu';

  @override
  String get goalCreateRemoveCheck => 'Odebrat kontrolu';

  @override
  String get goalCreateSegmentCap => 'Limit segmentů (volitelné)';

  @override
  String get goalCreateSegmentInvalid =>
      'Limit segmentů je celé číslo, nejméně 1.';

  @override
  String get scheduleCreateTitle => 'Opakovat výzvu';

  @override
  String get scheduleCadence => 'Jak často';

  @override
  String get scheduleEveryMinutes => 'Každých N minut';

  @override
  String get scheduleEveryHours => 'Každých N hodin';

  @override
  String get scheduleSelfPaced => 'Vlastní tempo';

  @override
  String get scheduleSelfPacedHint =>
      'Agent po každém běhu zvolí prodlevu mezi 1 minutou a 1 hodinou.';

  @override
  String get scheduleInterval => 'Interval';

  @override
  String get scheduleNote => 'Co má každý běh dělat?';

  @override
  String get scheduleCostCap => 'Limit nákladů v USD (volitelné)';

  @override
  String get scheduleExpiryDays => 'Končí po N dnech (volitelné)';

  @override
  String get scheduleCreateInvalid =>
      'Vyberte prostor a agenta, napište, co má každý běh dělat, a zadejte celá čísla nejméně 1.';

  @override
  String get scheduleCreateButton => 'Spustit plán';

  @override
  String get scheduleCreateConfirmTitle => 'Spustit tento plán?';

  @override
  String scheduleCreateConfirmEveryMinutes(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Běží po $countString minutách, počínaje teď.',
      few: 'Běží po $countString minutách, počínaje teď.',
      one: 'Běží každou minutu, počínaje teď.',
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
      other: 'Běží po $countString hodinách, počínaje teď.',
      few: 'Běží po $countString hodinách, počínaje teď.',
      one: 'Běží každou hodinu, počínaje teď.',
    );
    return '$_temp0';
  }

  @override
  String get scheduleCreateConfirmSelfPaced =>
      'Běží teď, potom agent zvolí, kdy poběží znovu.';

  @override
  String get scheduleCreated => 'Plán byl spuštěn. Je uveden v části Plány.';

  @override
  String get schedulesTitle => 'Plány';

  @override
  String get schedulesLoadFailed => 'Plány se nepodařilo načíst';

  @override
  String get schedulesEmpty => 'Žádné plány ani sledování';

  @override
  String get schedulesEmptyDescription =>
      'Opakujte výzvu z obrazovky cílů, nebo v konverzaci odešlete /loop nebo /schedule.';

  @override
  String get scheduleMissing =>
      'Tento plán už v tomto pracovním prostoru není dostupný.';

  @override
  String scheduleEvery(String interval) {
    return 'Každých $interval';
  }

  @override
  String get scheduleSelfPacedLoop => 'Smyčka s vlastním tempem';

  @override
  String get scheduleCron => 'Plán cron';

  @override
  String scheduleOnce(String time) {
    return 'Jednou v $time';
  }

  @override
  String scheduleWatch(String event) {
    return 'Sledování: $event';
  }

  @override
  String get scheduleWatchPrChecks => 'kontroly pull requestu';

  @override
  String get scheduleWatchPrReview => 'recenze pull requestu';

  @override
  String get scheduleWatchPrMerged => 'sloučení pull requestu';

  @override
  String get scheduleWatchEnvironment => 'prostředí';

  @override
  String get scheduleWatchTicket => 'ticket';

  @override
  String get scheduleWatchPipelineRun => 'běh pipeline';

  @override
  String get scheduleStatusActive => 'Aktivní';

  @override
  String get scheduleStatusPaused => 'Pozastaveno';

  @override
  String get scheduleStatusEnded => 'Ukončeno';

  @override
  String scheduleWakes(String agent) {
    return 'Probouzí $agent';
  }

  @override
  String scheduleNext(String time) {
    return 'Další běh $time';
  }

  @override
  String scheduleLast(String time) {
    return 'Poslední běh $time';
  }

  @override
  String scheduleRuns(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString běhů',
      few: '$countString běhy',
      one: '1 běh',
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

    return '$countString z $maxString běhů';
  }

  @override
  String scheduleSkipped(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString přeskočeno',
      few: '$countString přeskočeno',
      one: '1 přeskočeno',
    );
    return '$_temp0';
  }

  @override
  String scheduleEnds(String time) {
    return 'Končí $time';
  }

  @override
  String scheduleChain(int count, String time) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Součást řetězu: zbývá $countString běhů, končí $time';
  }

  @override
  String get scheduleNoteAgent => 'Vlastní poznámka agenta, jeho slovy:';

  @override
  String get scheduleNotePerson => 'Poznámka osoby:';

  @override
  String scheduleActsFor(String name) {
    return 'Jedná za $name';
  }

  @override
  String get scheduleActsForBot => 'Nejedná za žádnou osobu';

  @override
  String get scheduleGoalBound => 'Skončí spolu se svým cílem.';

  @override
  String get schedulePause => 'Pozastavit';

  @override
  String get scheduleResume => 'Pokračovat';

  @override
  String get scheduleDelete => 'Smazat';

  @override
  String get scheduleRemove => 'Odebrat';

  @override
  String get scheduleDeleteTitle => 'Smazat tento plán?';

  @override
  String get scheduleDeleteBody =>
      'Natrvalo přestane běžet. Nic z toho, co už udělal, se nevrátí zpět.';

  @override
  String get scheduleRemoveTitle => 'Odebrat tento plán?';

  @override
  String get scheduleRemoveBody => 'Zmizí ze seznamu.';

  @override
  String get scheduleResumeNotYours =>
      'Pokračovat v něm může jen osoba, za kterou plán jedná.';

  @override
  String get scheduleResumeAdminOnly =>
      'Plán, který nepatří žádné osobě, může obnovit jen správce pracovního prostoru.';

  @override
  String get scheduleOpenConversation => 'Otevřít konverzaci';

  @override
  String get progressWaiting => 'Čeká';

  @override
  String get progressNothingWaiting => 'Nic nečeká.';

  @override
  String get wakeOriginGoal => 'Cíl';

  @override
  String get wakeOriginGoalCheck => 'Ověření cíle';

  @override
  String get wakeOriginGoalReview => 'Kontrola cíle';

  @override
  String get wakeOriginSchedule => 'Plán';

  @override
  String get wakeOriginWatch => 'Sledování';

  @override
  String get wakeOriginReply => 'Odpověď';

  @override
  String get wakeOriginMessage => 'Zpráva';

  @override
  String get wakeOriginWorkFinished => 'Dokončená práce';

  @override
  String get wakeOriginLimitReset => 'Obnovení limitu';

  @override
  String get wakeOriginRecovery => 'Obnovení';

  @override
  String get wakeOriginAssignment => 'Přiřazení';

  @override
  String get wakeOriginPipelineStep => 'Krok pipeline';

  @override
  String get wakeOriginImprovementReview => 'Kontrola vylepšení';

  @override
  String wakeOriginReplyFrom(String agent) {
    return 'Odpověď od $agent';
  }

  @override
  String wakeOriginMessageFrom(String agent) {
    return 'Zpráva od $agent';
  }

  @override
  String wakeOriginWorkFinishedBy(String agent) {
    return 'Dokončená práce od $agent';
  }

  @override
  String wakeFor(String agent) {
    return 'Pro $agent';
  }

  @override
  String wakeDue(String time) {
    return 'Na $time';
  }

  @override
  String get wakeDueNow => 'Splatné teď';

  @override
  String get wakeHeld => 'Podrženo';

  @override
  String wakeExpires(String time) {
    return 'Vyprší $time';
  }

  @override
  String wakeAttempt(int attempt) {
    final intl.NumberFormat attemptNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String attemptString = attemptNumberFormat.format(attempt);

    return 'Pokus $attemptString';
  }

  @override
  String get wakeCancel => 'Zrušit';

  @override
  String get wakeDeliverNow => 'Doručit hned';

  @override
  String get wakeResume => 'Pokračovat';

  @override
  String get wakeDismiss => 'Zahodit';

  @override
  String get wakeResumeOnlyTheirs =>
      'Pokračovat může jen osoba, jejíž běh to je.';

  @override
  String get wakeRecovery =>
      'Server se během tohoto běhu restartoval. Pokračujte, aby běh pokračoval, nebo ho zahoďte.';

  @override
  String limitParkTitle(String provider, String time) {
    return 'Pozastaveno kvůli limitu využití u $provider, který se resetuje v $time. Běh čeká na tlačítko Pokračovat, nejdéle 7 dní po resetu.';
  }

  @override
  String limitParkTitleUnnamed(String time) {
    return 'Pozastaveno kvůli limitu využití u poskytovatele, který se resetuje v $time. Běh čeká na tlačítko Pokračovat, nejdéle 7 dní po resetu.';
  }

  @override
  String get limitParkResumeNow => 'Pokračovat hned';

  @override
  String get limitParkCancel => 'Zrušit';

  @override
  String limitParkResumed(String provider) {
    return 'Pokračuje po limitu využití u $provider.';
  }

  @override
  String limitParkGone(String provider) {
    return 'Už nečeká na limit využití u $provider.';
  }

  @override
  String get limitParkProviderUnknown => 'poskytovatele';

  @override
  String get mobileHeldMessages => 'Podržené zprávy';

  @override
  String get heldSteeringTitle =>
      'Podrženo, protože běh skončil dřív, než je mohl převzít. Odešlete své hned, nebo je odeberte.';

  @override
  String get heldSteeringRelease => 'Odeslat podržené zprávy';

  @override
  String get notifGoalCompleted => 'Cíl hotový';

  @override
  String get notifGoalFailed => 'Cíl selhal';

  @override
  String get notifGoalCancelled => 'Cíl zrušen';

  @override
  String get notifGoalBudgetExhausted => 'Cíl vyčerpal rozpočet';

  @override
  String get notifGoalNeedsReview => 'Cíl čeká na vaši kontrolu';

  @override
  String get notifGoalNeedsPerson => 'Cíl potřebuje vás';

  @override
  String get notifGoalOnHold => 'Cíl je podržen';

  @override
  String get notifWakeRuleEnded => 'Plán skončil';

  @override
  String notifWaitingDigest(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString věcí na vás čeká',
      few: '$countString věci na vás čekají',
      one: '1 věc na vás čeká',
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
      other: 'Bylo navrženo $countString úprav',
      few: 'Byly navrženy $countString úpravy',
      one: 'Byla navržena jedna úprava',
    );
    return '$_temp0';
  }

  @override
  String get notifPipelineRunHeld => 'Běh pipeline je podržen na svém rozpočtu';

  @override
  String notifPipelineRunHeldBody(String spent, String cap) {
    return 'Utraceno $spent z $cap';
  }

  @override
  String get notifNeedsYou => 'Čeká na vás';

  @override
  String get notifDigestGoalReview => 'Cíl čeká na kontrolu';

  @override
  String get notifDigestGoalPerson => 'Cíl potřebuje osobu';

  @override
  String get notifDigestHeldWake => 'Podržené probuzení';

  @override
  String get notifDigestImprovement => 'Navržená úprava';

  @override
  String get wakeKindRulePaused => 'Jeho plán byl pozastaven.';

  @override
  String get wakeKindRuleBusy =>
      'Agent byl zaneprázdněn a tento plán v takovém případě čas přeskakuje.';

  @override
  String get wakeKindRuleFolded =>
      'Místo něj ji nahradila pozdější událost stejného sledování.';

  @override
  String get wakeKindRuleSuperseded =>
      'Místo něj ji nahradil pozdější čas jeho plánu.';

  @override
  String get wakeKindRuleNotified =>
      'Jeho plán jen posílá upozornění, takže se nespustil žádný běh.';

  @override
  String get wakeKindRuleLimitParked =>
      'Jeho plán čeká, až se obnoví limit využití u poskytovatele.';

  @override
  String get improvementRefusalCooldown =>
      'Kontrola vylepšení v této konverzaci proběhla před chvílí. Zkuste to později.';

  @override
  String get improvementRefusalQueued =>
      'Kontrola vylepšení této konverzace už čeká na spuštění.';

  @override
  String get improvementRefusalAgentNotFound =>
      'Tento agent není agentem tohoto pracovního prostoru.';

  @override
  String get steeringRefusalHeldByLimit =>
      'Zprávy podržené na limitu využití nelze odeslat ručně. Čekají, až se pozastavený běh obnoví.';

  @override
  String limitParkCancelled(String provider) {
    return 'Čekání na limit využití u $provider bylo zrušeno.';
  }

  @override
  String limitParkExpired(String provider) {
    return 'Čekání na limit využití u $provider vypršelo, dřív než běh pokračoval.';
  }

  @override
  String limitParkSkipped(String provider) {
    return 'Běh po limitu využití u $provider nepokračoval.';
  }

  @override
  String get heldSteeringLimitTitle =>
      'Podrženo, dokud běh čeká na reset limitu využití. Odešlou se, až je osoba, pro kterou běh pracuje, obnoví.';

  @override
  String heldSteeringLimitAt(String time) {
    return 'Podrženo do resetu limitu využití v $time. Odešlou se, až je osoba, pro kterou běh pracuje, obnoví.';
  }

  @override
  String get heldSteeringOtherTitle => 'Podrženo serverem. Můžete je odebrat.';

  @override
  String workRowWoke(int count, String agent) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Probudil $agent kvůli $countString čekajícím položkám',
      few: 'Probudil $agent kvůli $countString čekajícím položkám',
      one: 'Probudil $agent',
    );
    return '$_temp0';
  }

  @override
  String workRowWakeMissed(String agent) {
    return 'Probuzení pro $agent bylo zmeškáno, když byl server vypnutý.';
  }

  @override
  String workRowWakeSkipped(String agent) {
    return 'Probuzení pro $agent nebylo doručeno.';
  }

  @override
  String workRowScheduleCreated(String agent) {
    return 'Plán nastaven pro $agent.';
  }

  @override
  String workRowScheduleEnded(String agent) {
    return 'Plán agenta $agent skončil.';
  }

  @override
  String workRowNoteFromAgent(String agent) {
    return 'Poznámka k plánu od $agent:';
  }

  @override
  String get workRowNoteFromPerson => 'Poznámka k plánu od osoby:';

  @override
  String workRowCommandRefusedNamed(String command) {
    return 'Příkaz $command byl odmítnut.';
  }

  @override
  String get workRowCommandRefused => 'Příkaz byl odmítnut.';

  @override
  String workRowCapRaised(String person, String from, String to) {
    return '$person zvýšil limit útraty pipeline z $from na $to.';
  }

  @override
  String workRowCapRaisedNoAmounts(String person) {
    return '$person zvýšil limit útraty pipeline.';
  }

  @override
  String get workRowApplyIncomplete =>
      'Přijatou změnu této dovednosti nebylo možné dokončit, protože se dovednost mezitím změnila. Návrh byl vrácen zpět.';

  @override
  String get workRowOpenSchedule => 'Otevřít plán';

  @override
  String get heldSteeringOthersTitle =>
      'Podrženo, protože běh skončil dřív, než je mohl převzít. Odeslat zprávu může jen osoba, která ji napsala.';

  @override
  String get heldSteeringOnlyYours =>
      'Odešle jen vaše zprávy. Ostatní čekají na lidi, kteří je napsali.';

  @override
  String heldSteeringWrittenBy(String name) {
    return 'Napsal $name';
  }

  @override
  String get steeringRefusalNotYours =>
      'Podržené zprávy může odeslat jen osoba, která je napsala, a žádná z těchto zpráv není vaše.';

  @override
  String get steeringRefusalNeedsWrite =>
      'Pro řízení běhu, který jedná za jiného člověka, potřebujete přístup k zápisu do repozitářů tohoto prostoru.';

  @override
  String workRowSchedulePaused(String name, String agent) {
    return 'Plán pro $agent pozastavil uživatel $name.';
  }

  @override
  String get goalVerdictObjective => 'Cíl jako celek';

  @override
  String get notifDigestRequest => 'Čeká na vaši odpověď';
}
