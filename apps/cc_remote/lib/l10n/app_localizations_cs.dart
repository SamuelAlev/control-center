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
      'Naskenujte QR kód z Macu a spárujte tento telefon.';

  @override
  String get scanQrHelp =>
      'Otevřete fotoaparát a namířte ho na QR kód zobrazený v Control Center na Macu. Tento telefon se k Macu připojí přímo přes soukromé spojení.';

  @override
  String get connectingToMac => 'Připojování k Macu…';

  @override
  String get connectingDetail => 'Navazuje se zabezpečené, přímé spojení.';

  @override
  String get identityChangedTitle => 'Identita serveru se změnila';

  @override
  String get identityChangedBody =>
      'Tento server už neodpovídá identitě uložené při párování. Může to znamenat, že byl server přeinstalován — nebo že něco odposlouchává připojení. Pro jistotu se toto zařízení nepřipojí. Odstraňte párování a pak naskenujte nový QR kód z Macu.';

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
  String get failureNotPaired => 'Nespárováno — naskenujte QR kód z Macu';

  @override
  String get failureUnreachable =>
      'K serveru se nepodařilo dostat žádnou cestou — zkontrolujte, že běží, nebo zkuste stejnou síť';

  @override
  String get failureIdentityChanged =>
      'Identita serveru se změnila — pokud byl přeinstalován, spárujte toto zařízení znovu';

  @override
  String get failureAuthRejected =>
      'Server toto zařízení odmítl — spárujte ho znovu z Macu';

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
      'Klepněte znovu a odpojte toto zařízení od Macu';

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
}
