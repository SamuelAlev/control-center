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
  String get inboxNoForgeAccount =>
      'Na serveru není připojený účet forge, takže pull requesty k vám zatím nelze přiřadit.';

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
  String get join => 'Připojit se';

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
  String attachmentsTooLargeRelay(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$names jsou příliš velké na odeslání odtud přes relay.',
      few: '$names jsou příliš velké na odeslání odtud přes relay.',
      one: '$names je příliš velký na odeslání odtud přes relay.',
    );
    return '$_temp0';
  }

  @override
  String get attachmentUploadFailed =>
      'Přílohu se nepodařilo nahrát. Zkuste to znovu.';

  @override
  String attachmentsLeftOut(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count příloh se nepodařilo nahrát a byly vynechány.',
      few: '$count přílohy se nepodařilo nahrát a byly vynechány.',
      one: '1 přílohu se nepodařilo nahrát a byla vynechána.',
    );
    return '$_temp0';
  }

  @override
  String get teammate => 'Spolupracovník';

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
  String reposUnreadable(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count rep se nepodařilo přečíst.',
      few: '$count repa se nepodařilo přečíst.',
      one: '1 repo se nepodařilo přečíst.',
    );
    return '$_temp0';
  }

  @override
  String reposNotReadable(String names) {
    return 'Nelze číst: $names';
  }

  @override
  String get installationSuspendedTitle =>
      'Instalace GitHub App je pozastavena';

  @override
  String installationSuspendedBody(String names) {
    return 'Zobrazují se naposledy známá data pro $names. Obnovte instalaci na GitHubu, nebo připojte token s přístupem.';
  }

  @override
  String installationSuspendedNotice(String names) {
    return 'Instalace GitHub App je pozastavena. Zobrazují se naposledy známá data pro $names. Obnovte instalaci na GitHubu, nebo připojte token s přístupem.';
  }

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
  String get permissionPrPublish => 'Publikovat pull requesty';

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
  String get permissionRemembered => 'Zapamatované schválení';

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
  String get permissionRevokeBeforeEdit =>
      'Před nastavením obecného pravidla pro tuto akci zrušte pravidlo v daném rozsahu nebo zapamatované pravidlo.';

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
  String get mobileGoalGoal => 'Cíl';

  @override
  String get mobileGoalLoop => 'Cyklus';

  @override
  String mobileGoalKind(String kind) {
    return 'Typ: $kind';
  }

  @override
  String mobileGoalRuns(String count) {
    return 'Počet běhů: $count';
  }

  @override
  String get mobileGoalNoRunLimit => 'bez omezení';

  @override
  String mobileGoalProgress(
    String runs,
    String maxRuns,
    String spent,
    String cap,
  ) {
    return 'Běhy: $runs / $maxRuns · Utraceno: $spent / $cap';
  }

  @override
  String mobileGoalDeadline(String date) {
    return 'Termín: $date';
  }

  @override
  String mobileGoalFailures(String count) {
    return 'Počet po sobě jdoucích neúspěšných běhů: $count';
  }

  @override
  String get mobileGoalSummary => 'Shrnutí výsledku';

  @override
  String get mobileGoalFailedDescription =>
      'Dohlížející proces se po opakovaných neúspěšných bězích zastavil. Podrobnosti najdete v konverzaci.';

  @override
  String get mobileGoalBudgetWall =>
      'Bylo dosaženo termínu nebo limitu počtu běhů. Zvýšení stropu nákladů tento cíl neobnoví.';

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
  String get activityTicket => 'Aktualizace ticketu';

  @override
  String get activityMeeting => 'Aktualizace schůzky';

  @override
  String get activityCalendar => 'Připojení kalendáře';

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
  String get credentialsRedirectUnavailable =>
      'Z telefonu není možné bezpečně dosáhnout zpětné adresy prohlížeče tohoto serveru. Požádejte vlastníka serveru o nastavení veřejné zpětné adresy HTTPS nebo místo toho přidejte token.';

  @override
  String get credentialsUpdateToken => 'Aktualizovat token';

  @override
  String get credentialsAddToken => 'Přidat token';

  @override
  String get credentialsPersonalToken => 'Osobní přístupový token';

  @override
  String get credentialsPersonalTokenHint => 'Vložte osobní přístupový token';

  @override
  String get credentialsHostManaged =>
      'Toto připojení pochází ze serverové aplikace nebo jejího prostředí. Změnit ho tam může jen vlastník serveru; vlastní token ale můžete přidat i vy.';

  @override
  String get credentialsStopWatching => 'Přestat sledovat';
}
