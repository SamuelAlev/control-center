// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Polish (`pl`).
class AppLocalizationsPl extends AppLocalizations {
  AppLocalizationsPl([String locale = 'pl']) : super(locale);

  @override
  String get appTitle => 'Control Center';

  @override
  String get back => 'Wstecz';

  @override
  String get cancel => 'Anuluj';

  @override
  String get retry => 'Ponów';

  @override
  String get tryAgain => 'Spróbuj ponownie';

  @override
  String get settings => 'Ustawienia';

  @override
  String get refresh => 'Odśwież';

  @override
  String get approve => 'Zatwierdź';

  @override
  String get deny => 'Odmów';

  @override
  String get continueLabel => 'Kontynuuj';

  @override
  String get agentQuestionHeader => 'Pytanie do ciebie';

  @override
  String get agentQuestionAnsweredLabel => 'Odpowiedziano';

  @override
  String get agentQuestionSkip => 'Pomiń';

  @override
  String get agentQuestionSkippedLabel => 'Pominięto';

  @override
  String get agentQuestionFreeformHint => 'Wpisz odpowiedź…';

  @override
  String get agentApprovalRequired => 'Wymagane zatwierdzenie';

  @override
  String get copyCommand => 'Kopiuj polecenie';

  @override
  String get approveAndRemember => 'Zatwierdź na 8 godzin';

  @override
  String get decline => 'Odrzuć';

  @override
  String get confirm => 'Potwierdź';

  @override
  String get send => 'Wyślij';

  @override
  String get close => 'Zamknij';

  @override
  String get expand => 'Rozwiń';

  @override
  String get zoomIn => 'Przybliż';

  @override
  String get zoomOut => 'Oddal';

  @override
  String get resetZoom => 'Resetuj zoom';

  @override
  String get scanQrPrompt =>
      'Zeskanuj kod QR z Control Center, aby sparować ten telefon.';

  @override
  String get scanQrHelp =>
      'Otwórz aparat i skieruj go na QR wyświetlony w Control Center. Ten telefon łączy się bezpośrednio przez prywatne łącze.';

  @override
  String get connectingToMac => 'Łączenie z Control Center…';

  @override
  String get connectingDetail =>
      'Nawiązywanie bezpiecznego, bezpośredniego łącza.';

  @override
  String get identityChangedTitle => 'Tożsamość serwera się zmieniła';

  @override
  String get identityChangedBody =>
      'Ten serwer nie pasuje już do tożsamości zapisanej przy parowaniu. To może oznaczać, że serwer został zainstalowany ponownie — albo że coś przechwytuje połączenie. Dla bezpieczeństwa to urządzenie się nie połączy. Usuń parowanie, a następnie zeskanuj nowy kod QR z Control Center, aby sparować ponownie.';

  @override
  String get removePairing => 'Usuń parowanie';

  @override
  String get couldntConnect => 'Nie udało się połączyć';

  @override
  String get pendingPairingTitle => 'Połączyć z tym serwerem?';

  @override
  String get pendingPairingBody =>
      'Łącze poprosiło Control Center o parowanie z tym serwerem. Kontynuuj tylko, jeśli to Ty to zainicjowałeś.';

  @override
  String get connect => 'Połącz';

  @override
  String get failureNotPaired =>
      'Brak parowania — zeskanuj kod QR z Control Center';

  @override
  String get failureUnreachable =>
      'Nie udało się dotrzeć do serwera żadną ścieżką — sprawdź, czy działa, albo spróbuj w tej samej sieci';

  @override
  String get failureIdentityChanged =>
      'Tożsamość serwera się zmieniła — jeśli został zainstalowany ponownie, sparuj to urządzenie ponownie';

  @override
  String get failureAuthRejected =>
      'Serwer odrzucił to urządzenie — sparuj je ponownie z Control Center';

  @override
  String get failureUnknown =>
      'Nie udało się połączyć — stuknij, aby spróbować ponownie';

  @override
  String get statusConnected => 'Połączono';

  @override
  String get statusConnecting => 'Łączenie';

  @override
  String get statusOffline => 'Offline';

  @override
  String get statusIdentityMismatch => 'Niezgodność tożsamości';

  @override
  String get statusNotPaired => 'Nie sparowano';

  @override
  String get statusConfirmPairing => 'Potwierdź parowanie';

  @override
  String get connectionFailed => 'Połączenie nieudane';

  @override
  String get identityMismatchBanner =>
      'Tożsamość serwera się zmieniła — połączenie przerwane. Sparuj to urządzenie ponownie, aby kontynuować.';

  @override
  String get tabInbox => 'Skrzynka';

  @override
  String get tabTickets => 'Zgłoszenia';

  @override
  String get tabChat => 'Czat';

  @override
  String get tabPrs => 'PRs';

  @override
  String get tabCalendar => 'Kalendarz';

  @override
  String get tabNews => 'Aktualności';

  @override
  String tabWaitingCount(String label, int count) {
    return '$label, $count oczekuje';
  }

  @override
  String get updateAvailable => 'Dostępna jest nowa wersja Control Center';

  @override
  String get appearance => 'Wygląd';

  @override
  String get language => 'Język';

  @override
  String get device => 'Urządzenie';

  @override
  String get themeSystem => 'Systemowy';

  @override
  String get themeLight => 'Jasny';

  @override
  String get themeDark => 'Ciemny';

  @override
  String get languageSystem => 'Systemowy';

  @override
  String get disconnectTapAgain =>
      'Stuknij ponownie, aby odłączyć to urządzenie od Control Center';

  @override
  String get disconnectDevice => 'Odłącz to urządzenie';

  @override
  String get disconnect => 'Rozłącz';

  @override
  String get chooseWorkspace => 'Wybierz obszar roboczy';

  @override
  String get workspaces => 'Obszary robocze';

  @override
  String get workspacesLoadFailed => 'Nie udało się wczytać obszarów roboczych';

  @override
  String get noWorkspacesYet => 'Brak obszarów roboczych';

  @override
  String selectWorkspace(String name) {
    return 'Wybierz $name';
  }

  @override
  String get inboxLoadFailed => 'Nie udało się wczytać skrzynki';

  @override
  String get allCaughtUp => 'Wszystko na bieżąco';

  @override
  String get inboxNothingWaiting =>
      'Nic nie jest zablokowane i żaden pull request na Ciebie nie czeka.';

  @override
  String get blocked => 'Zablokowany';

  @override
  String get sectionNeedsYourReview => 'Wymaga Twojej recenzji';

  @override
  String get sectionReturnedToYou => 'Zwrócone do Ciebie';

  @override
  String get sectionApprovedAndReady => 'Zatwierdzone i gotowe';

  @override
  String get sectionYourDrafts => 'Twoje szkice';

  @override
  String get sectionWaitingForReviewers => 'Oczekuje na recenzentów';

  @override
  String get sectionMergingAndMerged => 'Scalane i niedawno scalone';

  @override
  String get sectionWaitingForAuthor => 'Oczekuje na autora';

  @override
  String waitingAgo(String ago) {
    return 'czeka $ago';
  }

  @override
  String get openConversation => 'Otwórz rozmowę';

  @override
  String get calendarLoadFailed => 'Nie udało się wczytać kalendarza';

  @override
  String get nothingScheduled => 'Nic nie zaplanowano';

  @override
  String get calendarEmptyDescription =>
      'Wydarzenia z połączonych kalendarzy pojawią się tutaj.';

  @override
  String get agenda => 'Agenda';

  @override
  String get syncCalendarsNow => 'Synchronizuj kalendarze teraz';

  @override
  String get event => 'Wydarzenie';

  @override
  String get eventNotFound => 'Nie znaleziono wydarzenia';

  @override
  String get eventNotFoundDescription =>
      'Może być poza oknem agendy albo zostało usunięte u źródła.';

  @override
  String get joinMeeting => 'Dołącz do spotkania';

  @override
  String get join => 'Dołącz';

  @override
  String attendeesCount(int count) {
    return 'Uczestnicy ($count)';
  }

  @override
  String get details => 'Szczegóły';

  @override
  String get allDay => 'Cały dzień';

  @override
  String get happeningNow => 'Trwa teraz';

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
  String get attendeeAccepted => 'zaakceptowano';

  @override
  String get attendeeDeclined => 'odrzucono';

  @override
  String get attendeeMaybe => 'może';

  @override
  String get attendeeNoReply => 'brak odpowiedzi';

  @override
  String get organizer => 'organizator';

  @override
  String get calendarNoAccounts =>
      'W tym obszarze roboczym nie ma połączonego kalendarza. Połącz go w aplikacji desktopowej — logowanie zapisuje token na serwerze.';

  @override
  String get calendarReauthNeeded =>
      'Konto kalendarza wymaga ponownego połączenia — dane poniżej mogą być nieaktualne. Połącz je ponownie w aplikacji desktopowej.';

  @override
  String get spacesLoadFailed => 'Nie udało się wczytać przestrzeni';

  @override
  String get noSpaces => 'Brak przestrzeni';

  @override
  String get spacesEmptyDescription =>
      'Przestrzenie z tego obszaru roboczego pojawią się tutaj.';

  @override
  String get newSpaceFolder => 'Nowy folder';

  @override
  String get folderName => 'Nazwa folderu';

  @override
  String get renameSpaceFolder => 'Zmień nazwę folderu';

  @override
  String get deleteSpaceFolder => 'Usuń folder';

  @override
  String get moveSpaceToFolder => 'Przenieś do folderu';

  @override
  String get removeSpaceFromFolder => 'Usuń z folderu';

  @override
  String get spaceFolderActions => 'Akcje folderu';

  @override
  String get deleteFolderWithSpacesWarning =>
      'Trwałe usunięcie przestrzeni usuwa ich wiadomości i drzewa robocze dla wszystkich. Tej czynności nie można cofnąć.';

  @override
  String get deleteSpacesInFolder => 'Trwale usuń przestrzenie w tym folderze';

  @override
  String get deleteFolderAndSpaces => 'Usuń folder i przestrzenie';

  @override
  String get keepSpacesInFolder =>
      'W przeciwnym razie przestrzenie pozostaną poza folderami.';

  @override
  String get create => 'Utwórz';

  @override
  String get otherSpaces => 'Inne przestrzenie';

  @override
  String get folderUpdateFailed => 'Nie udało się zaktualizować folderów';

  @override
  String get thread => 'Wątek';

  @override
  String get agentWorking => 'Agent pracuje';

  @override
  String get messagesLoadFailed => 'Nie udało się wczytać wiadomości';

  @override
  String get noMessagesYet => 'Brak wiadomości';

  @override
  String get noMessagesDescription =>
      'Wyślij wiadomość, aby rozpocząć rozmowę.';

  @override
  String get agentResponding => 'Agent odpowiada';

  @override
  String get agentFinished => 'Agent zakończył';

  @override
  String attachmentsTooLarge(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$names są za duże, aby wysłać je stąd.',
      one: '$names jest za duży, aby wysłać go stąd.',
    );
    return '$_temp0';
  }

  @override
  String get teammate => 'Współpracownik';

  @override
  String get systemSender => 'System';

  @override
  String get agent => 'Agent';

  @override
  String get attachFile => 'Dołącz plik';

  @override
  String get messageHint => 'Wiadomość';

  @override
  String removeAttachment(String name) {
    return 'Usuń $name';
  }

  @override
  String get articlesLoadFailed => 'Nie udało się wczytać artykułów';

  @override
  String get noArticles => 'Brak artykułów';

  @override
  String get articlesEmptyDescription =>
      'Nowe artykuły pojawiają się tutaj wraz z aktualizacją kanałów.';

  @override
  String get unread => 'Nieprzeczytane';

  @override
  String get allFeeds => 'Wszystkie kanały';

  @override
  String get save => 'Zapisz';

  @override
  String get unsave => 'Usuń z zapisanych';

  @override
  String get readFullArticle => 'Czytaj cały artykuł';

  @override
  String get ticketsLoadFailed => 'Nie udało się wczytać zgłoszeń';

  @override
  String get noTickets => 'Brak zgłoszeń';

  @override
  String get ticketsEmptyDescription =>
      'Zgłoszenia z tego obszaru roboczego pojawiają się tutaj.';

  @override
  String get all => 'Wszystkie';

  @override
  String get ticket => 'Zgłoszenie';

  @override
  String get ticketLoadFailed => 'Nie udało się wczytać zgłoszenia';

  @override
  String assignedTo(String name) {
    return 'Przypisane do $name';
  }

  @override
  String get openInBrowser => 'Otwórz w przeglądarce';

  @override
  String get status => 'Status';

  @override
  String get assign => 'Przypisz';

  @override
  String get reassign => 'Przypisz ponownie';

  @override
  String get noAgents => 'Brak agentów';

  @override
  String get noAgentsDescription => 'Przypisz agenta z tego obszaru roboczego.';

  @override
  String get statusOpen => 'Otwarte';

  @override
  String get statusInProgress => 'W toku';

  @override
  String get statusBlocked => 'Zablokowane';

  @override
  String get statusInReview => 'W recenzji';

  @override
  String get statusDone => 'Ukończone';

  @override
  String get statusBacklog => 'Backlog';

  @override
  String get lensNeedsMe => 'Czeka na mnie';

  @override
  String get lensMine => 'Moje';

  @override
  String get prsLoadFailed => 'Nie udało się wczytać pull requestów';

  @override
  String get noOpenPullRequests => 'Brak otwartych pull requestów';

  @override
  String get nothingWaitingOnReview => 'Nic nie czeka na Twoją recenzję';

  @override
  String get noOwnOpenPullRequests => 'Nie masz otwartych pull requestów';

  @override
  String get nothingBlocked => 'Nic nie jest zablokowane';

  @override
  String get prsEmptyDescription =>
      'Pull requesty z repozytoriów tego obszaru roboczego pojawiają się tutaj.';

  @override
  String get refreshPullRequests => 'Odśwież pull requesty';

  @override
  String get noForgeConnected =>
      'Na serwerze nie połączono żadnego forge, więc nie można pobrać pull requestów. Połącz go w aplikacji na komputer.';

  @override
  String get draft => 'Szkic';

  @override
  String get merged => 'Scalono';

  @override
  String get closed => 'Zamknięte';

  @override
  String get open => 'Otwarty';

  @override
  String get approved => 'Zatwierdzono';

  @override
  String get changesRequested => 'Zażądano zmian';

  @override
  String get reviewRequired => 'Wymagana recenzja';

  @override
  String get checksPassing => 'Kontrole przechodzą';

  @override
  String get checksFailing => 'Kontrole nie przechodzą';

  @override
  String get checksRunning => 'Kontrole w toku';

  @override
  String prSemanticLabel(String title, String status) {
    return '$title, $status';
  }

  @override
  String get pullRequest => 'Pull request';

  @override
  String get prLoadFailed => 'Nie udało się wczytać tego pull requesta';

  @override
  String get openOnForge => 'Otwórz w forge';

  @override
  String get requestChangesNeedsComment =>
      'Dodaj komentarz wyjaśniający, co trzeba zmienić.';

  @override
  String get conversation => 'Dyskusja';

  @override
  String get files => 'Pliki';

  @override
  String get checks => 'Kontrole';

  @override
  String labelWithCount(String label, int count) {
    return '$label ($count)';
  }

  @override
  String filesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count plików',
      one: '1 plik',
    );
    return '$_temp0';
  }

  @override
  String commitsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count commitów',
      one: '1 commit',
    );
    return '$_temp0';
  }

  @override
  String get conflicts => 'Konflikty';

  @override
  String get reviewers => 'Recenzenci';

  @override
  String get noDescriptionNoComments => 'Brak opisu i komentarzy.';

  @override
  String get noChangedFiles => 'Brak zmienionych plików.';

  @override
  String get noChecksReported => 'Brak sprawdzeń dla commita HEAD.';

  @override
  String get reviewCommentHint => 'Zostaw komentarz recenzji…';

  @override
  String get comment => 'Komentarz';

  @override
  String get commentPosted => 'Opublikowano komentarz';

  @override
  String get request => 'Zażądaj';

  @override
  String get squashAndMerge => 'Scal ze squashowaniem';

  @override
  String noActionsAvailable(String status) {
    return '$status — brak dostępnych działań.';
  }

  @override
  String get reviewApproved => 'zaakceptowano';

  @override
  String get reviewRequestedChanges => 'zażądano zmian';

  @override
  String get reviewCommented => 'zrecenzowano';

  @override
  String get reviewPending => 'oczekuje';

  @override
  String get unknownAuthor => 'nieznany';

  @override
  String hideDiffFor(String file) {
    return 'Ukryj diff pliku $file';
  }

  @override
  String showDiffFor(String file) {
    return 'Pokaż diff pliku $file';
  }

  @override
  String get checkRunning => 'w toku';

  @override
  String get checkPassed => 'udane';

  @override
  String get checkFailed => 'nieudane';

  @override
  String get checkCancelled => 'anulowane';

  @override
  String get checkSkipped => 'pominięte';

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
      'Brak tekstowego diffa tego pliku — jest binarny albo zbyt duży, by forge go zwrócił.';

  @override
  String showRemainingLines(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Pokaż pozostałe $count linii',
      one: 'Pokaż pozostałą linię',
    );
    return '$_temp0';
  }

  @override
  String unchangedLines(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count niezmienionych linii',
      one: '1 niezmieniona linia',
    );
    return '$_temp0';
  }

  @override
  String get jumpToLatest => 'Przejdź do najnowszych';

  @override
  String get streaming => 'Strumieniowanie';

  @override
  String get working => 'Pracuje';

  @override
  String get input => 'Wejście';

  @override
  String get output => 'Wyjście';

  @override
  String get now => 'teraz';

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
  String get today => 'Dzisiaj';

  @override
  String get tomorrow => 'Jutro';

  @override
  String get yesterday => 'Wczoraj';

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
  String get mobileConversations => 'Rozmowy';

  @override
  String get mobileNewConversation => 'Nowa rozmowa';

  @override
  String get mobileConversationName => 'Nazwa rozmowy';

  @override
  String get mobileRename => 'Zmień nazwę';

  @override
  String get mobileManageSpace => 'Zarządzaj przestrzenią';

  @override
  String get mobileArchived => 'Zarchiwizowany';

  @override
  String get mobileSearchMessages =>
      'Szukaj we wszystkich wiadomościach w tej przestrzeni';

  @override
  String get mobileSearch => 'Szukaj';

  @override
  String get mobileNoResults => 'Brak wyników';

  @override
  String get mobileReopen => 'Otwórz ponownie';

  @override
  String get mobileArchive => 'Archiwizuj';

  @override
  String get mobileProgress => 'Postęp i kontekst';

  @override
  String get mobileReadFailed =>
      'Nie udało się oznaczyć rozmowy jako przeczytanej';

  @override
  String get mobileSendFailed => 'Nie wysłano wiadomości. Szkic nadal tu jest.';

  @override
  String get sentAttachmentUnavailable => 'Załącznik niedostępny';

  @override
  String get sentAttachmentLoadFailed => 'Nie udało się wczytać załącznika';

  @override
  String get mobileActionFailed => 'Działanie nie powiodło się';

  @override
  String get mobileRemove => 'Usuń';

  @override
  String get mobileLinkedMessage => 'Powiązana wiadomość';

  @override
  String get mobileOlderMessages => 'Starsze wiadomości';

  @override
  String get mobileMessageActions => 'Działania dotyczące wiadomości';

  @override
  String get mobileOpenThread => 'Otwórz wątek';

  @override
  String get mobileCopyLink => 'Kopiuj link';

  @override
  String get mobileStopRun => 'Zatrzymaj uruchomienie';

  @override
  String get mobileStopRunConfirm =>
      'Zatrzymać to uruchomienie agenta? Ukończona praca zostanie zachowana.';

  @override
  String get mobileControlUnsupported =>
      'To uruchomienie zakończyło się lub nie obsługuje tego działania.';

  @override
  String get mobilePauseRequested =>
      'Zażądano wstrzymania po zakończeniu bieżącej tury';

  @override
  String get mobileResumed => 'Wznowiono uruchomienie';

  @override
  String get mobileStopRequested => 'Zażądano zatrzymania';

  @override
  String get mobileQueuedMessages => 'Wiadomości w kolejce';

  @override
  String get mobilePauseRun => 'Wstrzymaj po następnej turze';

  @override
  String get mobileResumeRun => 'Wznów';

  @override
  String get mobileEditQueued => 'Edytuj zakolejkowaną wiadomość';

  @override
  String get mobileSteerNow => 'Zmień kierunek teraz';

  @override
  String get mobileMoveUp => 'Przenieś w górę';

  @override
  String get mobileMoveDown => 'Przenieś w dół';

  @override
  String get mobileQueueChanged =>
      'Kolejka się zmieniła lub nie można sterować tym uruchomieniem na żywo. Odśwież i spróbuj ponownie.';

  @override
  String get mobileActivity => 'Aktywność';

  @override
  String get mobilePermissions => 'Uprawnienia i audyt';

  @override
  String get mobilePlans => 'Plany';

  @override
  String get mobileGoals => 'Cele nadzorowane';

  @override
  String get mobileCredentials => 'Połączenia i dane uwierzytelniające';

  @override
  String get mobileWorkspaceUnavailable =>
      'Ten obszar roboczy jest niedostępny lub nie masz już do niego dostępu.';

  @override
  String get mobilePrReviewThreads => 'Wątki recenzji';

  @override
  String get mobilePrThreadsLoadFailed =>
      'Nie udało się wczytać wątków recenzji';

  @override
  String get mobilePrNoReviewThreads =>
      'Nie ma jeszcze wątków recenzji w kodzie';

  @override
  String get mobilePrCommentPermissionDenied =>
      'Nie masz uprawnień do komentowania tego repozytorium.';

  @override
  String get mobilePrPermissionChecking =>
      'Sprawdzanie uprawnień do komentowania…';

  @override
  String get mobilePrPermissionLoadFailed =>
      'Nie udało się sprawdzić uprawnień. Spróbuj ponownie dodać komentarz.';

  @override
  String mobilePrThreadLine(String side, String line) {
    return '$side, wiersz $line';
  }

  @override
  String get mobilePrOriginalSide => 'Oryginał';

  @override
  String get mobilePrSelectCommentLine => 'Wybierz wiersz do skomentowania';

  @override
  String get mobilePrUpdatedSide => 'Zaktualizowano';

  @override
  String get mobilePrThreadResolved => 'Rozwiązane';

  @override
  String get mobilePrReplyHint => 'Napisz odpowiedź…';

  @override
  String get mobilePrCommentRequired =>
      'Napisz komentarz przed opublikowaniem.';

  @override
  String get mobilePrReply => 'Odpowiedz';

  @override
  String get mobilePrReopenThread => 'Otwórz wątek ponownie';

  @override
  String get mobilePrResolveThread => 'Rozwiąż wątek';

  @override
  String get mobilePrResolvePermissionDenied =>
      'Tylko autor pull requestu lub osoba z uprawnieniami do zapisu może zamknąć ten wątek.';

  @override
  String mobilePrCommentOnLine(String side, String line) {
    return 'Skomentuj: $side, wiersz $line';
  }

  @override
  String get mobilePrInlineCommentHint => 'Napisz komentarz do kodu…';

  @override
  String get mobilePrPostInlineComment => 'Opublikuj komentarz';

  @override
  String get mobilePrCommentUnavailable =>
      'Komentarze do kodu są niedostępne dla tego pull requestu.';

  @override
  String get mobilePrPatchUnavailable =>
      'Serwis nie udostępnił poprawki tekstowej dla tego pliku.';

  @override
  String get mobilePrNoPatchForFile =>
      'Poprawka dla tego pliku jest niedostępna.';

  @override
  String get mobileTicketNew => 'Nowe zgłoszenie';

  @override
  String get mobileTicketCreate => 'Utwórz zgłoszenie';

  @override
  String get mobileTicketEdit => 'Edytuj zgłoszenie';

  @override
  String get mobileTicketTitle => 'Tytuł';

  @override
  String get mobileTicketTitleRequired =>
      'Wpisz tytuł, aby zapisać zgłoszenie.';

  @override
  String get mobileTicketDescription => 'Opis';

  @override
  String get mobileTicketMarkdownHint => 'Dodaj szczegóły w Markdown';

  @override
  String get mobileTicketPriority => 'Priorytet';

  @override
  String get mobileTicketPriorityNone => 'Bez priorytetu';

  @override
  String get mobileTicketPriorityUrgent => 'Pilny';

  @override
  String get mobileTicketPriorityHigh => 'Wysoki';

  @override
  String get mobileTicketPriorityMedium => 'Średni';

  @override
  String get mobileTicketPriorityLow => 'Niski';

  @override
  String get mobileTicketLabels => 'Etykiety';

  @override
  String get mobileTicketLabelsHint => 'Jedna etykieta w wierszu';

  @override
  String get mobileTicketLabelsHelp =>
      'Wpisz każdą etykietę w osobnym wierszu.';

  @override
  String mobileTicketWorkspaceProvider(String provider) {
    return 'Zgłoszono w $provider';
  }

  @override
  String get mobileTicketProviderLocal => 'Control Center';

  @override
  String get mobileTicketUnassigned => 'Nieprzypisane';

  @override
  String get mobileTicketAssignedFilter => 'Przypisane';

  @override
  String get mobileTicketAgentsLoadFailed => 'Nie udało się wczytać agentów';

  @override
  String get mobileTicketSearch => 'Szukaj zgłoszeń';

  @override
  String get mobileTicketSearchHint =>
      'Tytuł, klucz, opis, etykieta lub przypisana osoba';

  @override
  String get mobileTicketClearSearch => 'Wyczyść wyszukiwanie zgłoszeń';

  @override
  String get mobileTicketNoMatches => 'Brak pasujących zgłoszeń';

  @override
  String get mobileTicketAdjustFilters =>
      'Spróbuj innego wyszukiwania lub zmień filtry.';

  @override
  String get mobileTicketClearFilters => 'Wyczyść filtry';

  @override
  String get mobileTicketNotFound => 'Nie znaleziono zgłoszenia';

  @override
  String get mobileTicketNotFoundDescription =>
      'Zgłoszenie mogło zostać usunięte lub przeniesione poza ten obszar roboczy.';

  @override
  String get mobileTicketWorkspaceChanged =>
      'Obszar roboczy się zmienił. Wróć do bieżącego obszaru przed zapisaniem.';

  @override
  String get mobileTicketOpenLinkedSpace => 'Otwórz powiązaną przestrzeń';

  @override
  String get mobileTicketReadOnly =>
      'Do zmiany zgłoszeń wymagana jest rola członka obszaru roboczego.';

  @override
  String get permissionTitle => 'Uprawnienia';

  @override
  String get permissionWorkspaceFailed =>
      'Nie udało się wczytać obszaru roboczego';

  @override
  String get permissionNoWorkspace =>
      'Wybierz obszar roboczy, aby sprawdzić uprawnienia.';

  @override
  String get permissionLoading => 'Wczytywanie uprawnień…';

  @override
  String get permissionScopeDescription =>
      'Sprawdź, jak rozstrzygane jest każde działanie w tym zakresie. Agenci i przestrzenie mogą dziedziczyć reguły obszaru roboczego.';

  @override
  String get permissionScope => 'Zakres zasad';

  @override
  String get permissionWorkspaceScope => 'Obszar roboczy';

  @override
  String get permissionAgentScope => 'Agent';

  @override
  String get permissionSpaceScope => 'Przestrzeń';

  @override
  String get permissionAgentContext => 'Agent działający w tej przestrzeni';

  @override
  String get permissionNoAgentContext => 'Nie wybrano agenta';

  @override
  String get permissionTargetsFailed => 'Nie udało się wczytać celów zakresu';

  @override
  String get permissionNoTargets => 'Brak dostępnych celów w tym zakresie.';

  @override
  String get permissionRoleFailed =>
      'Nie udało się potwierdzić Twojej roli w obszarze roboczym';

  @override
  String get permissionMemberRequired =>
      'Do wyświetlania reguł wymagane są uprawnienia członka obszaru roboczego.';

  @override
  String get permissionRulesFailed => 'Nie udało się wczytać reguł zasad';

  @override
  String get permissionAuditAdminOnly =>
      'Historia autoryzacji jest dostępna tylko dla administratorów obszaru roboczego.';

  @override
  String get permissionAllow => 'Zezwól';

  @override
  String get permissionAsk => 'Zapytaj najpierw';

  @override
  String get permissionDeny => 'Odmów';

  @override
  String get permissionFileDelete => 'Usuwanie plików';

  @override
  String get permissionFileWriteOutsideWorktree =>
      'Zapis poza drzewem roboczym';

  @override
  String get permissionGitCommit => 'Zatwierdzanie zmian';

  @override
  String get permissionGitPush => 'Wypychanie commitów';

  @override
  String get permissionPrCreate => 'Tworzenie pull requestów';

  @override
  String get permissionPrPublish =>
      'Aktualizowanie lub scalanie pull requestów';

  @override
  String get permissionVendorSyncWrite => 'Zapis synchronizacji dostawcy';

  @override
  String get permissionNetworkEgress => 'Dostęp do sieci';

  @override
  String get permissionSecretAccess => 'Dostęp do sekretów';

  @override
  String get permissionPackageInstall => 'Instalowanie pakietów';

  @override
  String get permissionProcessSpawn => 'Uruchamianie procesów';

  @override
  String get permissionWorkspaceMutation => 'Zmiana obszaru roboczego';

  @override
  String get permissionEnclosureControl => 'Sterowanie środowiskiem izolowanym';

  @override
  String get permissionChangeFailed => 'Nie udało się zmienić reguły';

  @override
  String get permissionEffectiveDescription =>
      'Obowiązuje w tym zakresie bez parametrów działania. Poniższe warunkowe zezwolenia dotyczą tylko pasujących żądań; ostateczną decyzję podejmuje serwer.';

  @override
  String get permissionSpaceAgentNote =>
      'Nie wybrano agenta. Wybierz go powyżej, aby zobaczyć reguły dotyczące agenta.';

  @override
  String get permissionScopedGrants => 'Reguły w tym zakresie';

  @override
  String get permissionModePreset => 'Preset trybu';

  @override
  String get permissionBuiltInDefault => 'Wbudowana wartość domyślna';

  @override
  String get permissionRemembered => 'Zatwierdzenie czasowe';

  @override
  String get permissionSource => 'Źródło';

  @override
  String permissionSetAtThisScope(String source) {
    return '$source · ustawiono tutaj';
  }

  @override
  String permissionInheritedFrom(String source) {
    return '$source · odziedziczono';
  }

  @override
  String permissionExpiresAt(String date) {
    return 'Wygasa $date';
  }

  @override
  String get permissionSetHere => 'Ustaw tutaj regułę';

  @override
  String get permissionConfirmRevoke => 'Potwierdź cofnięcie';

  @override
  String get permissionRevokeRule => 'Cofnij regułę';

  @override
  String permissionCommandPrefix(String prefix) {
    return 'Prefiks polecenia: $prefix';
  }

  @override
  String get permissionNoExpiry => 'Bez daty wygaśnięcia';

  @override
  String get permissionExpired => 'Wygasłe';

  @override
  String get permissionExplicitRule => 'Reguła jawna';

  @override
  String get permissionEnforcementAdvisory =>
      'Tryb doradczy: reguły wymagające zgody są rejestrowane bez pytania';

  @override
  String get permissionEnforcementSoft =>
      'Miękkie egzekwowanie: obejście wymaga autoryzacji';

  @override
  String get permissionEnforcementHard =>
      'Twarde egzekwowanie: nie można obejść';

  @override
  String permissionPaths(String paths) {
    return 'Ścieżki: $paths';
  }

  @override
  String permissionRefs(String refs) {
    return 'Referencje Git: $refs';
  }

  @override
  String permissionHosts(String hosts) {
    return 'Hosty: $hosts';
  }

  @override
  String permissionCommands(String commands) {
    return 'Polecenia: $commands';
  }

  @override
  String permissionTools(String tools) {
    return 'Narzędzia: $tools';
  }

  @override
  String get permissionNotInEffect =>
      'Bez skutku, gdy to działanie ma ustawienie «Odmów»';

  @override
  String permissionMaxCount(String count) {
    return 'Maksymalna liczba: $count';
  }

  @override
  String permissionMaxCents(String cents) {
    return 'Maksymalna liczba centów: $cents';
  }

  @override
  String get permissionAuditHeading => 'Historia autoryzacji';

  @override
  String get permissionAuditDescription =>
      'Ostatnie decyzje zapisane przez serwer. Tylko administratorzy mogą przeglądać dziennik lub weryfikować jego łańcuch skrótów.';

  @override
  String permissionOnBehalfOf(String user) {
    return 'w imieniu $user';
  }

  @override
  String get permissionPrompted => 'Poproszono o zgodę człowieka';

  @override
  String get permissionVerifyChain => 'Zweryfikuj łańcuch audytu';

  @override
  String get permissionVerifyFailed =>
      'Nie udało się zweryfikować łańcucha audytu';

  @override
  String permissionChainIntact(String count) {
    return 'Łańcuch nienaruszony · sprawdzono $count wpisów';
  }

  @override
  String permissionChainBroken(String sequence, String reason) {
    return 'Łańcuch przerwany przy wpisie $sequence: $reason';
  }

  @override
  String get permissionAuditEmpty =>
      'Nie zapisano jeszcze decyzji autoryzacyjnych.';

  @override
  String get permissionAuditFailed =>
      'Nie udało się wczytać historii autoryzacji';

  @override
  String get mobilePlansLoadFailed => 'Nie udało się wczytać planów';

  @override
  String get mobilePlansEmpty => 'Nie ma jeszcze planów';

  @override
  String get mobilePlansEmptyDescription =>
      'Plany przesłane przez agentów pojawią się tutaj do przejrzenia.';

  @override
  String get mobilePlanTitle => 'Plan';

  @override
  String get mobilePlanMissing =>
      'Ten plan nie jest już dostępny w tym obszarze roboczym.';

  @override
  String mobilePlanStepCount(int count) {
    return 'Liczba kroków: $count';
  }

  @override
  String get mobilePlanDraft => 'Szkic';

  @override
  String get mobilePlanProposed => 'Oczekuje na recenzję';

  @override
  String get mobilePlanApproved => 'Zatwierdzony';

  @override
  String get mobilePlanRejected => 'Odrzucono';

  @override
  String get mobilePlanSuperseded => 'Zastąpiono';

  @override
  String get mobilePlanExecuting => 'Wykonywanie';

  @override
  String get mobilePlanSynthesizing => 'Syntezowanie';

  @override
  String get mobilePlanCompleted => 'Ukończone';

  @override
  String get mobilePlanFailed => 'Niepowodzenie';

  @override
  String get mobilePlanCancelled => 'Anulowane';

  @override
  String mobilePlanRevision(String revision) {
    return 'Wersja $revision';
  }

  @override
  String get mobilePlanSteps => 'Kroki';

  @override
  String get mobilePlanNoSteps => 'Nie przesłano kroków dla tego planu.';

  @override
  String get mobilePlanAssumptions => 'Wyjaśnienia';

  @override
  String mobilePlanDependsOn(String keys) {
    return 'Zależy od $keys';
  }

  @override
  String mobilePlanStepCost(String cost) {
    return 'Szacunkowo do $cost';
  }

  @override
  String get mobilePlanSelect => 'Wybierz';

  @override
  String get mobilePlanSelected => 'Wybrane';

  @override
  String get mobilePlanEstimate => 'Oszacuj koszt';

  @override
  String get mobilePlanEstimateRequired =>
      'Oszacuj plan przed zatwierdzeniem wykonania.';

  @override
  String mobilePlanEstimatedCost(String low, String high) {
    return 'Szacowany koszt: $low–$high';
  }

  @override
  String get mobilePlanCostUnknown => 'niedostępny';

  @override
  String get mobilePlanNoHardCap => 'bez sztywnego limitu';

  @override
  String get mobilePlanExceedsBudget =>
      'Szacunkowy koszt przekracza ustawiony budżet. Sprawdź go przed zatwierdzeniem.';

  @override
  String get mobilePlanPartialEstimate =>
      'Szacunek obejmuje cały plan; wybrane kroki mogą kosztować mniej.';

  @override
  String get mobilePlanConfirmAll => 'Uruchomić cały plan?';

  @override
  String get mobilePlanConfirmSelected => 'Uruchomić wybrane kroki?';

  @override
  String mobilePlanExecutionConfirmation(String cost, String cap) {
    return 'Zatwierdzenie rozpocznie wykonanie i może wiązać się z opłatami. Górny szacowany koszt: $cost. Limit budżetu: $cap.';
  }

  @override
  String get mobilePlanApproveAll => 'Zatwierdź całość i uruchom';

  @override
  String get mobilePlanApproveSelected => 'Zatwierdź wybrane i uruchom';

  @override
  String get mobilePlanWiden => 'Zatwierdź dodatkowe kroki';

  @override
  String mobilePlanWidenConfirm(String count, String cap) {
    return 'Zlecić wykonanie kolejnych $count kroków? Mogą wiązać się z opłatami. Obecny limit kosztu wykonania: $cap.';
  }

  @override
  String get mobilePlanChanged =>
      'Plan zmienił się podczas recenzji. Otwórz najnowszą wersję i ponownie oszacuj koszt.';

  @override
  String get mobilePlanReject => 'Odrzuć plan';

  @override
  String get mobilePlanRejectConfirm =>
      'Odrzucić ten plan? Nie zostanie wykonany.';

  @override
  String get mobilePlanStop => 'Zatrzymaj wykonanie';

  @override
  String get mobilePlanStopConfirm =>
      'Zatrzymać wykonanie planu? Ukończona praca nie zostanie cofnięta.';

  @override
  String mobilePlanRunId(String runId) {
    return 'Uruchomienie wykonania: $runId';
  }

  @override
  String get mobilePlanExecutionPending =>
      'Zatwierdzono. Oczekiwanie na zapis wykonania…';

  @override
  String mobilePlanProgress(String completed, String total) {
    return 'Ukończone kroki wykonania: $completed z $total';
  }

  @override
  String get mobilePlanOpenConversation => 'Otwórz rozmowę';

  @override
  String get mobileGoalsTitle => 'Cele nadzorowane';

  @override
  String get mobileGoalsLoadFailed =>
      'Nie udało się wczytać celów nadzorowanych';

  @override
  String get mobileGoalsEmpty => 'Nie ma jeszcze celów nadzorowanych';

  @override
  String get mobileGoalsEmptyDescription =>
      'Rozpocznij cel w przestrzeni lub wyślij /goal w rozmowie.';

  @override
  String get mobileGoalMissing =>
      'Ten cel nie jest już dostępny w tym obszarze roboczym.';

  @override
  String get mobileGoalActive => 'Aktywny';

  @override
  String get mobileGoalPaused => 'Wstrzymany';

  @override
  String get mobileGoalCompleted => 'Ukończone';

  @override
  String get mobileGoalFailed => 'Niepowodzenie';

  @override
  String get mobileGoalCancelled => 'Anulowane';

  @override
  String get mobileGoalBudgetExhausted => 'Wyczerpano budżet';

  @override
  String mobileGoalFailures(String count) {
    return 'Kolejne nieudane uruchomienia: $count';
  }

  @override
  String get mobileGoalFailedDescription =>
      'Nadzór zatrzymał się po kolejnych nieudanych uruchomieniach. Sprawdź szczegóły w rozmowie.';

  @override
  String get mobileGoalPause => 'Wstrzymaj cel';

  @override
  String get mobileGoalResume => 'Wznów cel';

  @override
  String get mobileGoalStop => 'Anuluj cel';

  @override
  String get mobileGoalStopConfirm =>
      'Trwale anulować ten cel nadzorowany? Nie będzie można go wznowić.';

  @override
  String get mobileGoalRaiseBudget => 'Zwiększ budżet i wznów';

  @override
  String mobileGoalRaiseTo(String amount) {
    return 'Zwiększ budżet do $amount i wznów';
  }

  @override
  String mobileGoalRaiseConfirm(String oldCap, String newCap) {
    return 'Zwiększyć limit kosztów tego celu z $oldCap do $newCap i wznowić wydatki?';
  }

  @override
  String get mobileGoalOpenConversation => 'Otwórz rozmowę dotyczącą celu';

  @override
  String get mobileGoalCreate => 'Rozpocznij cel nadzorowany';

  @override
  String get mobileGoalChooseSpace => 'Uruchom w przestrzeni';

  @override
  String get mobileGoalNoSpaces => 'Utwórz przestrzeń, zanim rozpoczniesz cel.';

  @override
  String get mobileGoalChooseAgent => 'Uruchom z agentem';

  @override
  String get mobileGoalNoAgents =>
      'Dodaj aktywnego agenta, zanim rozpoczniesz cel.';

  @override
  String mobileGoalSelectedAgent(String name) {
    return 'Wybrano: $name';
  }

  @override
  String get mobileGoalObjectiveHint => 'Jaki wynik powinien osiągnąć agent?';

  @override
  String get mobileGoalBudgetUsd => 'Limit kosztów (USD)';

  @override
  String get mobileGoalCreateInvalid =>
      'Wybierz przestrzeń i agenta, wpisz cel oraz ustaw dodatni limit kosztów w USD.';

  @override
  String mobileGoalCreateConfirm(String cap) {
    return 'Rozpocząć cel nadzorowany z limitem kosztów $cap? Agent może zacząć od razu.';
  }

  @override
  String get mobileGoalUnavailable =>
      'Połączenie z serwerem nie jest gotowe. Spróbuj ponownie po połączeniu.';

  @override
  String get mobileGoalConversationMissing =>
      'Wybrana rozmowa nie jest już dostępna w tym obszarze roboczym.';

  @override
  String get mobileGoalCreateSent =>
      'Cel rozpoczęty. Stan nadzoru pojawi się na tej liście.';

  @override
  String get mobileGoalStartRefused =>
      'Nie rozpoczęto realizacji celu. Sprawdź powód podany przez nadzorcę w rozmowie.';

  @override
  String mobileGoalSelectedSpace(String name) {
    return 'Wybrano: $name';
  }

  @override
  String get requestUnavailable =>
      'To żądanie nie jest już dostępne w aktywnym obszarze roboczym.';

  @override
  String get requestAlreadyResolved => 'To żądanie zostało już rozstrzygnięte.';

  @override
  String get inboxCredentialsBlocked =>
      'Dane uwierzytelniające blokują uruchomienia';

  @override
  String get inboxSyncFailures => 'Nieudane synchronizacje dostawców';

  @override
  String get inboxConfigureCredentials => 'Skonfiguruj dane uwierzytelniające';

  @override
  String get openTicket => 'Otwórz zgłoszenie';

  @override
  String get activityTitle => 'Aktywność';

  @override
  String get activityClearAll => 'Wyczyść aktywność';

  @override
  String get activityClearConfirm =>
      'Spowoduje to ukrycie całej dotychczasowej aktywności na wszystkich Twoich urządzeniach. Nowa aktywność nadal będzie się pojawiać.';

  @override
  String get activityMarkAllRead => 'Oznacz wszystkie jako przeczytane';

  @override
  String get activityMarkAllConfirm =>
      'Oznaczyć wszystkie elementy aktywności w tym obszarze roboczym jako przeczytane na wszystkich Twoich urządzeniach?';

  @override
  String get activityMarkRead => 'Oznacz jako przeczytane';

  @override
  String get activityMarkUnread => 'Oznacz jako nieprzeczytane';

  @override
  String get activityDismiss => 'Odrzuć';

  @override
  String get activityResolved => 'Rozwiązane';

  @override
  String get activityOpen => 'Otwarty';

  @override
  String get activityEmpty => 'Brak aktywności';

  @override
  String get activityLoadFailed => 'Nie udało się wczytać aktywności';

  @override
  String get activityAgentWaiting => 'Agent potrzebuje informacji';

  @override
  String get activityAgentBlocked => 'Działanie agenta zablokowane';

  @override
  String get activityMessage => 'Nowa wiadomość';

  @override
  String get activityPullRequest => 'Aktualizacja pull requestu';

  @override
  String get activityRig => 'Aktualizacja środowiska izolowanego';

  @override
  String get activityEvent => 'Aktualizuj';

  @override
  String get activityPrReady => 'Pull request gotowy do scalenia';

  @override
  String get activityPrBlocked => 'Scalenie pull requestu zablokowane';

  @override
  String get activityPrApproved => 'Pull request zatwierdzony';

  @override
  String get activityPrChanges => 'Zażądano zmian';

  @override
  String get activityPrChecksFailed =>
      'Nie powiodły się kontrole pull requestu';

  @override
  String get activityPrChecksRecovered =>
      'Kontrole pull requestu znów przechodzą';

  @override
  String get activityPrComment => 'Komentarz do pull requestu';

  @override
  String get activityPrPublished => 'Opublikowano pull request';

  @override
  String get activityPrMerged => 'Scalono pull request';

  @override
  String get activityPrMentioned => 'Wspomniano o Tobie w pull requeście';

  @override
  String get activityPrReviewRequested => 'Prośba o recenzję';

  @override
  String get activityPrReviewStale => 'Recenzja wymaga odświeżenia';

  @override
  String get activityTicketAssigned => 'Przypisano zgłoszenie';

  @override
  String get activityTicketChanged => 'Zmieniono status zgłoszenia';

  @override
  String get activityMeetingSoon => 'Spotkanie wkrótce się rozpocznie';

  @override
  String get activityCalendarExpired => 'Połączenie z kalendarzem wygasło';

  @override
  String get activityRigControl =>
      'Zmieniono sterowanie środowiskiem izolowanym';

  @override
  String get activityRigClosed => 'Zatrzymano środowisko izolowane';

  @override
  String get mobileSpacesSearch => 'Szukaj przestrzeni';

  @override
  String get mobileSpacesArchived => 'Zarchiwizowany';

  @override
  String get mobileSpacesActive => 'Aktywny';

  @override
  String get mobileSpacesNew => 'Nowa przestrzeń';

  @override
  String get mobileSpacesManage => 'Zarządzaj przestrzenią';

  @override
  String get mobileSpacesName => 'Nazwa przestrzeni';

  @override
  String get mobileSpacesAgents => 'Agenci';

  @override
  String get mobileSpacesMembers => 'Osoby';

  @override
  String get mobileSpacesRepos => 'Repozytoria';

  @override
  String get mobileSpacesAllRepos => 'Wszystkie powiązane repozytoria';

  @override
  String get mobileSpacesNoRepos => 'Brak repozytoriów';

  @override
  String get mobileSpacesBaseBranch => 'Gałąź bazowa (opcjonalnie)';

  @override
  String get mobileSpacesDefaultBranch => 'Gałąź domyślna';

  @override
  String get mobileSpacesMode => 'Tryb';

  @override
  String get mobileSpacesModeChat => 'Czat';

  @override
  String get mobileSpacesModeReview => 'Recenzja (tylko odczyt)';

  @override
  String get mobileSpacesModePlan => 'Plan (tylko odczyt)';

  @override
  String get mobileSpacesModeOrchestrate => 'Orkiestruj';

  @override
  String get mobileSpacesAutonomy => 'Nadpisanie autonomii';

  @override
  String get mobileSpacesAutonomyInherited => 'Odziedziczone';

  @override
  String get mobileSpacesAutonomyPropose => 'Tylko propozycje';

  @override
  String get mobileSpacesAutonomyApproval => 'Działa po zatwierdzeniu';

  @override
  String get mobileSpacesAutonomyFreely => 'Działa swobodnie';

  @override
  String get mobileSpacesAutonomyNotice =>
      'Nadpisanie nie omija pytań o zgodę ani odmów wynikających z zasad działania. Zmienić je mogą tylko administratorzy obszaru roboczego.';

  @override
  String get mobileSpacesArchive => 'Archiwizuj przestrzeń';

  @override
  String get mobileSpacesReopen => 'Otwórz przestrzeń ponownie';

  @override
  String get mobileSpacesSave => 'Zapisz zmiany';

  @override
  String get mobileSpacesCreate => 'Utwórz przestrzeń';

  @override
  String get mobileSpacesOperationFailed =>
      'Nie udało się zaktualizować przestrzeni';

  @override
  String get mobileSpacesMissing =>
      'Nie znaleziono przestrzeni w tym obszarze roboczym';

  @override
  String get mobileSpacesEmptyName => 'Wpisz nazwę przestrzeni';

  @override
  String get mobileSpacesNoMatches => 'Brak pasujących przestrzeni';

  @override
  String get mobileSpacesUnread => 'Nieprzeczytana odpowiedź agenta';

  @override
  String get mobileSpacesNeedsInput => 'Wymaga Twojej odpowiedzi';

  @override
  String get mobileSpacesRunning => 'Agent działa';

  @override
  String get mobileSpacesNoAgents => 'Brak agentów w tym obszarze roboczym';

  @override
  String get mobileSpacesNoMembers => 'Brak innych członków obszaru roboczego';

  @override
  String get mobileSpacesRepoError => 'Nie udało się wczytać repozytoriów';

  @override
  String get mobileSpacesRetry => 'Ponów';

  @override
  String get mobileSpacesBranchUnavailable =>
      'Przy tworzeniu przestrzeni wybierz lub wpisz gałąź bazową; gałęzi bazowych istniejących przestrzeni nie można zmieniać.';

  @override
  String get mobileSpacesArchivedEmpty => 'Brak zarchiwizowanych przestrzeni';

  @override
  String get mobileSpacesAllRepoWarning =>
      'Nowo powiązane repozytoria obszaru roboczego również zostaną dodane do tej przestrzeni.';

  @override
  String get mobileSpacesCreatedRetry =>
      'Utworzono przestrzeń. Spróbuj ponownie dodać osoby lub otwórz stronę zarządzania.';

  @override
  String get progressTitle => 'Postęp';

  @override
  String get progressConversation => 'Rozmowa';

  @override
  String get progressLoadFailed => 'Nie udało się wczytać postępu';

  @override
  String get progressUnavailable => 'Rozmowa niedostępna';

  @override
  String get progressUnavailableDescription =>
      'Ta rozmowa nie należy do aktywnego obszaru roboczego i przestrzeni. Wróć do jej przestrzeni, aby kontynuować.';

  @override
  String get progressSaveFailed => 'Nie udało się zaktualizować postępu';

  @override
  String get progressGoal => 'Cel';

  @override
  String get progressNoGoal => 'Nie ustawiono celu pracy';

  @override
  String get progressSetGoal => 'Ustaw cel';

  @override
  String get progressEditGoal => 'Edytuj cel';

  @override
  String get progressClearGoal => 'Wyczyść cel';

  @override
  String get progressGoalRequired => 'Wpisz cel przed zapisaniem.';

  @override
  String get progressTodos => 'Zadania';

  @override
  String get transcriptToolTodos => 'Zadania';

  @override
  String get transcriptToolSearchMemory => 'Przeszukaj pamięć';

  @override
  String get transcriptToolRenderMedia => 'Wyświetl multimedia';

  @override
  String get progressNoTodos => 'Nie ma jeszcze zadań';

  @override
  String get progressNewTodo => 'Nowe zadanie';

  @override
  String get progressAddTodo => 'Dodaj zadanie';

  @override
  String get progressEditTodo => 'Edytuj zadanie';

  @override
  String get progressTodoRequired => 'Wpisz zadanie przed zapisaniem.';

  @override
  String get progressTodoNoLongerExists =>
      'To zadanie zostało usunięte. Wczytaj listę ponownie i spróbuj jeszcze raz.';

  @override
  String get progressWorkspaceChanged =>
      'Aktywny obszar roboczy się zmienił. Wróć do tej rozmowy i spróbuj ponownie.';

  @override
  String progressRemoveTodo(String name) {
    return 'Usuń zadanie $name';
  }

  @override
  String get progressPending => 'Oczekujące';

  @override
  String get progressInProgress => 'W toku';

  @override
  String get progressCompleted => 'Ukończone';

  @override
  String get progressMoveUp => 'Przenieś zadanie w górę';

  @override
  String get progressMoveDown => 'Przenieś zadanie w dół';

  @override
  String get progressRunTree => 'Uruchomienia agentów';

  @override
  String get progressNoRuns => 'Nie ma jeszcze uruchomień w tej rozmowie';

  @override
  String get progressRunning => 'Działa';

  @override
  String get progressFailed => 'Niepowodzenie';

  @override
  String get progressUnknown => 'Nieznany';

  @override
  String get progressHealthy => 'Aktywny';

  @override
  String get progressBlocked => 'Zablokowany';

  @override
  String get progressLooping => 'W pętli';

  @override
  String get progressStalled => 'Zatrzymany';

  @override
  String get progressDead => 'Zatrzymany nieoczekiwanie';

  @override
  String get progressQuiet => 'Brak danych wyjściowych';

  @override
  String get progressCostReported => 'Opłata podana przez dostawcę';

  @override
  String get progressCostNotional =>
      'Orientacyjna cena katalogowa subskrypcji; to nie rachunek';

  @override
  String get progressCostMixed => 'Mieszane źródła kosztów';

  @override
  String get progressCostEstimated => 'Szacowany koszt';

  @override
  String progressDurationSeconds(String seconds) {
    return '$seconds s';
  }

  @override
  String progressRunDetails(String model, String duration, String cost) {
    return 'Model: $model · Czas: $duration · Koszt: $cost';
  }

  @override
  String progressStartedAt(String time) {
    return 'Rozpoczęto $time';
  }

  @override
  String progressLiveness(String state) {
    return 'Stan: $state';
  }

  @override
  String progressRunTokens(String input, String output) {
    return 'Wejście: $input · Wyjście: $output tokenów';
  }

  @override
  String get progressOutputPreviewLimited =>
      'Wyświetlono tylko pierwsze 6000 znaków danych strukturalnych.';

  @override
  String progressRetryOf(String runId) {
    return 'Ponowienie uruchomienia $runId';
  }

  @override
  String get progressContext => 'Kontekst i limity';

  @override
  String get progressNoAgent => 'Brak agenta do sprawdzenia';

  @override
  String progressContextReading(String used, String window) {
    return '$used / $window tokenów';
  }

  @override
  String get progressMeasured =>
      'Kontekst zgłoszony przez dostawcę dla ostatniego wywołania';

  @override
  String get progressEstimated =>
      'Oszacowano na podstawie zapisanej rozmowy i trwałego kontekstu';

  @override
  String get progressContextUnknown =>
      'Nie podano jeszcze wykorzystania kontekstu';

  @override
  String progressContextPercent(String percent) {
    return '$percent% okna kontekstu';
  }

  @override
  String progressMonthlyBudget(String amount) {
    return 'Ustawiony miesięczny limit agenta: $amount';
  }

  @override
  String progressConversationTokens(String tokens) {
    return 'Zapisana bieżąca rozmowa: szacunkowo $tokens tokenów';
  }

  @override
  String progressInspectionFor(String agent, String model) {
    return 'Trwały kontekst agenta $agent · $model';
  }

  @override
  String get progressContextSystem => 'Prompt systemowy';

  @override
  String get progressContextRules => 'Zasady';

  @override
  String get progressContextSkills => 'Umiejętności';

  @override
  String get progressContextTools => 'Definicje narzędzi';

  @override
  String get progressContextMcp => 'Narzędzia MCP';

  @override
  String get progressContextDeferred => 'Narzędzia odroczone';

  @override
  String get progressContextSubagents => 'Podagenci';

  @override
  String get progressContextRunner => 'Zewnętrzny wykonawca';

  @override
  String get progressContextMemory => 'Pamięć';

  @override
  String get progressContextHistory => 'Historia rozmowy';

  @override
  String progressContextSegment(String label, String tokens) {
    return '$label · $tokens tokenów';
  }

  @override
  String progressContextPart(String title, String tokens) {
    return '$title · $tokens tokenów';
  }

  @override
  String get progressOutputs => 'Ostatnie wyniki';

  @override
  String get progressNoOutputs => 'Brak ostatnich wyników agenta';

  @override
  String get progressStructuredOutputsAbove =>
      'Ustrukturyzowane wyniki uruchomień pokazano powyżej.';

  @override
  String get progressRecentOutputsOnly =>
      'Wyświetlane są tylko ostatnie wiadomości. Otwórz rozmowę, aby zobaczyć wcześniejszą pracę.';

  @override
  String get progressPlan => 'Plan';

  @override
  String get progressArtifact => 'Artefakt';

  @override
  String get progressResult => 'Wynik';

  @override
  String get progressHideArtifact => 'Ukryj artefakt';

  @override
  String get progressReadArtifact => 'Odczytaj artefakt';

  @override
  String get progressArtifactUnavailable => 'Artefakt nie jest już dostępny';

  @override
  String get progressArtifactPreviewLimited =>
      'Pokazano ograniczony podgląd tego artefaktu.';

  @override
  String get progressDiagramSource => 'Kod źródłowy diagramu';

  @override
  String progressOpenAttachment(String name) {
    return 'Otwórz $name';
  }

  @override
  String get progressOpenPlan => 'Otwórz plan';

  @override
  String progressOpenDiff(String label) {
    return 'Przejrzyj zmienione pliki: $label';
  }

  @override
  String get progressViewMessage => 'Wyświetl wiadomość';

  @override
  String get pushTitle => 'Powiadomienia w tle';

  @override
  String get pushIntro =>
      'Otrzymuj prywatne powiadomienia, gdy coś wymaga Twojej uwagi, nawet przy zamkniętej aplikacji. Szczegóły pozostają w zaszyfrowanym połączeniu.';

  @override
  String get pushLoading => 'Sprawdzanie ustawień powiadomień…';

  @override
  String get pushError =>
      'Nie udało się zaktualizować powiadomień. Sprawdź połączenie i spróbuj ponownie.';

  @override
  String get pushEnable => 'Włącz powiadomienia';

  @override
  String get pushDisable => 'Wyłącz powiadomienia';

  @override
  String get pushQuiet => 'Wstrzymaj powiadomienia na tym urządzeniu';

  @override
  String get pushCategories => 'Powiadamiaj mnie o';

  @override
  String get pushCategoryAgents => 'Agenci';

  @override
  String get pushCategoryMessages => 'Wiadomości';

  @override
  String get pushCategoryPullRequests => 'Pull requesty';

  @override
  String get pushCategoryTickets => 'Zgłoszenia';

  @override
  String get pushCategoryCalendar => 'Kalendarz';

  @override
  String get pushCategoryMachines => 'Maszyny';

  @override
  String get pushSecureOrigin => 'Powiadomienia wymagają HTTPS.';

  @override
  String get pushInstallIos =>
      'Na iPhonie lub iPadzie dodaj tę aplikację do ekranu początkowego i uruchom ją stamtąd, aby włączyć powiadomienia.';

  @override
  String get pushUnsupported =>
      'Ta przeglądarka nie obsługuje powiadomień w tle.';

  @override
  String get pushDenied =>
      'Przeglądarka zgłasza, że powiadomienia są zablokowane. Sprawdź uprawnienia tej witryny oraz ustawienia powiadomień przeglądarki lub urządzenia, a potem odśwież stronę.';

  @override
  String get pushOsHint =>
      'Przeglądarka potrzebuje też uprawnienia do wyświetlania powiadomień w ustawieniach systemowych urządzenia.';

  @override
  String get pushServiceUnavailable =>
      'Usługa push przeglądarki odrzuciła subskrypcję. Niektóre przeglądarki, np. Brave, domyślnie ją wyłączają: poszukaj opcji wiadomości push w ustawieniach prywatności przeglądarki i spróbuj ponownie.';

  @override
  String get pushWorkerUnavailable =>
      'Nie udało się uruchomić usługi powiadomień w tej przeglądarce. Odśwież stronę i spróbuj ponownie.';

  @override
  String get pushResubscribe => 'Połącz powiadomienia ponownie';

  @override
  String get pushStatusEnabled =>
      'Powiadomienia na tym urządzeniu są włączone.';

  @override
  String get pushStatusDisabled =>
      'Powiadomienia na tym urządzeniu są wyłączone.';

  @override
  String get credentialsTitle => 'Połączenia i dane uwierzytelniające';

  @override
  String get credentialsIntro =>
      'Połącz konta używane przez uruchomienia i integracje. Sekrety są przechowywane na Twoim serwerze, nie na tym telefonie.';

  @override
  String get credentialsModelProviders => 'Dostawcy modeli';

  @override
  String get credentialsOwnerOnly =>
      'Tylko właściciel serwera może dodawać, logować się i usuwać dane uwierzytelniające dostawców modeli. Klucze te są współdzielone między obszarami roboczymi.';

  @override
  String get credentialsContactOwner =>
      'Poproś właściciela serwera o połączenie z dostawcą wymaganym przez zablokowane uruchomienie.';

  @override
  String get credentialsClaudeCode => 'Claude Code';

  @override
  String get credentialsClaudeHostOnly =>
      'Claude Code wymaga zalogowania się przez CLI na hoście. Poproś właściciela serwera o zalogowanie się lub odnowienie sesji w terminalu hosta; nie można tego zrobić na telefonie.';

  @override
  String get credentialsYourForgeAccounts => 'Twoje konta w serwisach kodu';

  @override
  String get credentialsYourTicketingAccount =>
      'Twoje konto do obsługi zgłoszeń';

  @override
  String get credentialsLocalTicketsNoLogin =>
      'Lokalne zgłoszenia nie wymagają logowania. Połącz tutaj Linear, jeśli korzysta z niego Twój obszar roboczy.';

  @override
  String get credentialsMembershipRequired =>
      'Do zarządzania danymi logowania do serwisów kodu lub obsługi zgłoszeń dołącz do obszaru roboczego. Poproś administratora o dostęp.';

  @override
  String get credentialsSwitchWorkspace =>
      'Ten link prowadzi do innego obszaru roboczego. Przełącz się na niego przed zmianą danych uwierzytelniających.';

  @override
  String get credentialsReturnToInbox =>
      'Wróć do Skrzynki odbiorczej, aby ponowić zablokowane uruchomienie po połączeniu danych uwierzytelniających. Host automatycznie sprawdza też odłożone uruchomienia.';

  @override
  String get credentialsLoadFailed =>
      'Nie udało się wczytać połączeń. Sprawdź połączenie z serwerem i spróbuj ponownie.';

  @override
  String get credentialsOperationFailed =>
      'Nie udało się zmienić tego połączenia. Sprawdź połączenie z serwerem, uprawnienia i dane uwierzytelniające, a następnie spróbuj ponownie.';

  @override
  String get credentialsConnected => 'Połączono';

  @override
  String get credentialsNotConnected => 'Nie połączono';

  @override
  String credentialsSignedInAs(String username) {
    return 'Zalogowano jako $username';
  }

  @override
  String get credentialsAccount => 'Połączone konto';

  @override
  String get credentialsStoredKey => 'Zapisany klucz';

  @override
  String get credentialsActive => 'Aktywny';

  @override
  String get credentialsRemove => 'Usuń';

  @override
  String get credentialsRemoveConfirm =>
      'Usunąć zapisane dane uwierzytelniające? Może być konieczne ponowne zalogowanie.';

  @override
  String get credentialsApiKey => 'Klucz API';

  @override
  String get credentialsApiKeyHint => 'Wklej klucz API dostawcy';

  @override
  String get credentialsBrowserLogin => 'Zaloguj się w przeglądarce';

  @override
  String get credentialsSignInAgain => 'Zaloguj się ponownie';

  @override
  String get credentialsWaitingForLogin =>
      'Oczekiwanie na autoryzację w przeglądarce…';

  @override
  String get credentialsConnectCodePrompt => 'Kod potwierdzenia';

  @override
  String get credentialsConnectCodeMalformed =>
      'To nie wygląda na kod logowania. Kody mają 8 liter i cyfr.';

  @override
  String get credentialsSignInInvalidCode =>
      'Ten kod nie pasuje do tego logowania. Sprawdź go i spróbuj ponownie.';

  @override
  String get credentialsSignInTooManyCodes =>
      'Zbyt wiele błędnych kodów. Rozpocznij logowanie od nowa.';

  @override
  String get credentialsSignInRetryLater =>
      'Usługa logowania w tej chwili nie odpowiada. Odczekaj minutę i spróbuj ponownie.';

  @override
  String get credentialsSignInRefused =>
      'Logowanie zostało odrzucone. Rozpocznij je od nowa i zatwierdź wszystkie wymagane uprawnienia.';

  @override
  String get credentialsSignInNotSaved =>
      'Logowanie się powiodło, ale serwer nie mógł go zapisać. Spróbuj ponownie.';

  @override
  String credentialsSignInUnavailable(String provider) {
    return 'Logowanie do $provider nie jest jeszcze skonfigurowane na tym serwerze.';
  }

  @override
  String get credentialsSignInPhoneUnreachable =>
      'Adres zwrotny logowania tego serwera nie jest bezpiecznie dostępny z telefonu. Zaloguj się w aplikacji na komputer albo poproś właściciela serwera o skonfigurowanie publicznego adresu HTTPS.';

  @override
  String get credentialsLoginTimedOut =>
      'Sesja logowania wygasła. Rozpocznij logowanie ponownie.';

  @override
  String get credentialsCopyCode => 'Kopiuj kod';

  @override
  String get credentialsDeviceCodeHint =>
      'Potwierdź ten kod na stronie dostawcy. Nie zamykaj tego ekranu, dopóki serwer nie zakończy logowania.';

  @override
  String get credentialsPasteRedirect =>
      'Kod autoryzacyjny lub adres URL przekierowania';

  @override
  String get credentialsPasteRedirectHint =>
      'Wklej kod lub pełny adres URL przekierowania od dostawcy';

  @override
  String get credentialsCompleteLogin => 'Dokończ logowanie';

  @override
  String get credentialsUpdateToken => 'Aktualizuj token';

  @override
  String get credentialsAddToken => 'Dodaj token';

  @override
  String get credentialsPersonalToken => 'Osobisty token dostępu';

  @override
  String get credentialsPersonalTokenHint => 'Wklej osobisty token dostępu';

  @override
  String get credentialsStopWatching => 'Przestań obserwować';

  @override
  String get transcriptClaudeSignInExpiredTitle => 'Sesja Claude Code wygasła';

  @override
  String get transcriptClaudeSignInExpiredBody =>
      'Przebieg został zatrzymany, ponieważ jego konto nie uwierzytelnia się już. Zaloguj się ponownie, a następnie ponów turę.';

  @override
  String get transcriptSignInExpiredTitle => 'Sesja dostawcy wygasła';

  @override
  String get transcriptSignInExpiredBody =>
      'Przebieg został zatrzymany, ponieważ dane uwierzytelniające dostawcy już nie działają. Połącz go ponownie w Ustawienia → Dostawcy, a następnie ponów turę.';

  @override
  String get permissionHostExecution => 'Uruchamiaj polecenia na hoście';

  @override
  String credentialsSignInLapsed(String provider) {
    return 'Twoje logowanie do $provider wygasło. Zaloguj się ponownie.';
  }

  @override
  String get credentialsSignInPaused =>
      'Wstrzymane: zmieniła się usługa logowania tego obszaru roboczego. Zadziała ponownie, gdy usługa wróci.';

  @override
  String credentialsProviderUnreachable(String provider) {
    return 'Nie można teraz połączyć się z $provider. Ponawianie.';
  }

  @override
  String get credentialsScopeWorkspace => 'Tylko ten obszar roboczy';

  @override
  String get credentialsScopeAllWorkspaces => 'Wszystkie obszary robocze';

  @override
  String get credentialsRemoveConfirmWorkspace =>
      'Usunąć zapisane dane logowania z tego obszaru roboczego? Inne obszary robocze zachowają swoje.';

  @override
  String get credentialsRemoveConfirmAllWorkspaces =>
      'Usunąć zapisane dane logowania ze wszystkich obszarów roboczych, które je współdzielą?';

  @override
  String get credentialsSignInServerRestarted =>
      'Serwer został uruchomiony ponownie. Zacznij logowanie od nowa.';

  @override
  String repoAccessInstallApp(String owner, String names) {
    return 'Zainstaluj GitHub App w $owner, aby automatyzacja dotarła do $names. Dotknij, aby otworzyć GitHub.';
  }

  @override
  String repoAccessAskAdminInstall(String owner, String names) {
    return 'GitHub App nie jest zainstalowana w $owner, więc automatyzacja nie dociera do $names. Poproś administratora obszaru roboczego o jej instalację.';
  }

  @override
  String repoAccessAddToApp(String names) {
    return 'Dodaj $names do repozytoriów GitHub App. Dotknij, aby otworzyć GitHub.';
  }

  @override
  String repoAccessAskAdminAdd(String names) {
    return 'GitHub App jeszcze nie widzi $names. Poproś administratora obszaru roboczego o dodanie ich do jej repozytoriów.';
  }

  @override
  String repoAccessSuspended(String names) {
    return 'Instalacja GitHub App została wstrzymana. Automatyzacja dla $names jest wstrzymana, dopóki właściciel konta nie wznowi instalacji w GitHub.';
  }

  @override
  String repoAccessOwnerCannotSee(String names) {
    return 'Osoba odpowiedzialna za automatyzację tego obszaru roboczego nie widzi już $names, więc nic nie działa tam w jej imieniu.';
  }

  @override
  String repoAccessOwnerNotSignedIn(String names) {
    return 'Osoba odpowiedzialna za automatyzację tego obszaru roboczego nie jest zalogowana do forge, więc automatyzacja dla $names czeka, aż się zaloguje.';
  }

  @override
  String repoAccessRetrying(String names) {
    return 'Nie udało się sprawdzić dostępu do $names. Ponawianie.';
  }

  @override
  String hiddenReposSignIn(int count, String forge) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Zaloguj się do $forge, aby zobaczyć pull requesty z kolejnych repozytoriów: $count',
      one:
          'Zaloguj się do $forge, aby zobaczyć pull requesty z jeszcze 1 repozytorium',
    );
    return '$_temp0';
  }

  @override
  String hiddenReposNoForgeAccess(int count, String forge) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ukryte repozytoria, których Twoje konto $forge nie widzi: $count',
      one: '1 repozytorium jest ukryte, bo Twoje konto $forge go nie widzi',
    );
    return '$_temp0';
  }

  @override
  String hiddenReposNoGrant(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Ukryte repozytoria, do których nie masz dostępu w tym obszarze roboczym: $count',
      one:
          '1 repozytorium jest ukryte, bo nie masz do niego dostępu w tym obszarze roboczym',
    );
    return '$_temp0';
  }

  @override
  String hiddenReposChecking(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Sprawdzanie Twojego dostępu do kolejnych repozytoriów: $count…',
      one: 'Sprawdzanie Twojego dostępu do jeszcze 1 repozytorium…',
    );
    return '$_temp0';
  }

  @override
  String get credentialsAtlassianEmail => 'E-mail konta Atlassian';

  @override
  String get credentialsAtlassianEmailInvalid =>
      'Wpisz adres e-mail swojego konta Atlassian.';

  @override
  String get credentialsBitbucketApiToken => 'Token API';

  @override
  String repoAccessAutomationTokenMissing(String names) {
    return 'Żaden token automatyzacji nie może odczytać $names, więc praca w tle jest tam wstrzymana. Administrator może dodać token w Ustawienia → Repozytoria.';
  }

  @override
  String get credentialsSignInConfirmInBrowser =>
      'Potwierdź w przeglądarce, a następnie wpisz pokazany tam kod.';

  @override
  String get credentialsSignInAccountAlreadyBound =>
      'To konto jest już połączone z inną osobą na tym serwerze. Zaloguj się innym kontem.';

  @override
  String credentialsTokenUnreachable(String provider) {
    return 'Nie udało się połączyć z $provider, aby sprawdzić ten token. Spróbuj ponownie za chwilę.';
  }

  @override
  String credentialsTokenRejected(String provider) {
    return '$provider nie akceptuje tego tokenu. Sprawdź, czy skopiowano go w całości i czy nie został unieważniony.';
  }

  @override
  String credentialsTokenWrongKind(String provider) {
    return 'To nie jest token osobisty. Wklej osobisty token dostępu z własnego konta $provider, a nie token projektu, grupy, obszaru roboczego ani bota.';
  }

  @override
  String credentialsTokenNarrowScope(String scope) {
    return 'Temu tokenowi brakuje zakresu $scope, który jest potrzebny do przeglądania i komentowania. Utwórz token, który go ma.';
  }

  @override
  String get credentialsTokenExpired =>
      'Ten token wygasł. Utwórz nowy i wklej go tutaj.';

  @override
  String get credentialsSignInRateLimited =>
      'Zbyt wiele żądań w tej chwili. Poczekaj chwilę i spróbuj ponownie.';

  @override
  String get credentialsSignInCancelled =>
      'Logowanie zostało anulowane lub odrzucone. Rozpocznij je ponownie, gdy będziesz gotowy.';

  @override
  String get credentialsSignInNoLongerOpen =>
      'To logowanie nie jest już otwarte: zostało anulowane, wykorzystane lub zastąpione. Rozpocznij je ponownie.';

  @override
  String get noWorkspacesYetHint =>
      'Administrator obszaru roboczego musi cię zaprosić albo właściciel serwera może utworzyć dla ciebie obszar roboczy.';

  @override
  String repoAccessReplaced(String repos, String forge) {
    return '$repos wskazuje teraz na inne repozytorium na $forge. Połącz je ponownie w aplikacji na komputer lub w przeglądarce, aby nadal z niego korzystać.';
  }

  @override
  String repoAccessAskAdminRelink(String repos, String forge) {
    return '$repos wskazuje teraz na inne repozytorium na $forge. Administrator obszaru roboczego musi połączyć je ponownie, zanim będzie można z niego znowu korzystać.';
  }

  @override
  String get runSandboxUnavailableTitle =>
      'Agenty potrzebują piaskownicy na tym serwerze';

  @override
  String get runSandboxUnavailable =>
      'Ten serwer nie ma piaskownicy, więc agenty mogą tu uruchamiać tylko jego właściciel. Właściciel może zainstalować piaskownicę albo wyłączyć piaskownicowanie dla wszystkich.';

  @override
  String get scriptToolCalls => 'Wywołania narzędzi';

  @override
  String scriptCallCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count wywołania',
      many: '$count wywołań',
      few: '$count wywołania',
      one: '1 wywołanie',
    );
    return '$_temp0';
  }

  @override
  String scriptCallsRunning(int count) {
    return '$count w toku';
  }

  @override
  String scriptCallsOk(int count) {
    return '$count OK';
  }

  @override
  String scriptCallsFailed(int count) {
    return '$count nieudane';
  }

  @override
  String scriptCallsDenied(int count) {
    return '$count odrzucone';
  }

  @override
  String scriptCallsCancelled(int count) {
    return '$count anulowane';
  }

  @override
  String scriptCallsQueued(int count) {
    return '$count w kolejce';
  }

  @override
  String scriptCallsSkipped(int count) {
    return '$count pominiętych';
  }

  @override
  String get scriptStepQueued => 'W kolejce';

  @override
  String get scriptStepSkipped => 'Pominięte';

  @override
  String get scriptGroupLoop => 'Pętla';

  @override
  String get scriptGroupEach => 'Dla każdego';

  @override
  String get scriptGroupParallel => 'Równolegle';

  @override
  String get scriptGroupFunction => 'Funkcja';

  @override
  String scriptCallsHidden(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Pokaż $count wywołania więcej',
      many: 'Pokaż $count wywołań więcej',
      few: 'Pokaż $count wywołania więcej',
      one: 'Pokaż 1 wywołanie więcej',
    );
    return '$_temp0';
  }

  @override
  String get scriptCallsUnplaced => 'Wywołania nieprzypisane do skryptu';

  @override
  String get scriptToolComputed => 'Narzędzie';

  @override
  String scriptStepSemantics(String subject, String state) {
    return '$subject, $state';
  }

  @override
  String get scriptSourceLabel => 'Skrypt';

  @override
  String scriptSourceLines(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count wiersza',
      many: '$count wierszy',
      few: '$count wiersze',
      one: '1 wiersz',
    );
    return '$_temp0';
  }

  @override
  String get scriptStateRunning => 'Działa';

  @override
  String get scriptStateCompleted => 'Ukończono';

  @override
  String get scriptStateFailed => 'Niepowodzenie';

  @override
  String get scriptStateTimedOut => 'Upłynął limit czasu';

  @override
  String get scriptStateCancelled => 'Anulowano';

  @override
  String get scriptStateMemoryExceeded => 'Brak pamięci';

  @override
  String get scriptStateOutputExceeded => 'Za dużo danych wyjściowych';

  @override
  String get scriptStateSandboxError => 'Błąd sandboxa';

  @override
  String get scriptStateRefused => 'Odrzucono';

  @override
  String get scriptOriginLine => 'Z skryptu, który uruchomił agent';

  @override
  String get codeModeTitle => 'Tryb kodu';

  @override
  String get codeModeAvailable => 'Dostępne';

  @override
  String get codeModeUnavailable => 'Niedostępne';

  @override
  String codeModeUnavailableNote(String reason) {
    return 'Ten serwer nie może uruchamiać skryptów, więc agenci tutaj wywołują narzędzia jedno po drugim. Serwer podaje: $reason';
  }

  @override
  String get codeModeNoReason => 'nie podano przyczyny.';

  @override
  String get workKindUnknown => 'Z przyczyny, której ta wersja nie zna:';

  @override
  String get workRefusalUnknown => 'Serwer odrzucił to:';

  @override
  String workActionFailed(String error) {
    return 'Nie udało się: $error';
  }

  @override
  String get wakeKindStopped => 'Wstrzymane, bo osoba zatrzymała uruchomienie.';

  @override
  String get wakeKindAttempts => 'Dostarczenie nie udało się trzy razy.';

  @override
  String get wakeKindAgentDeleted => 'Agent już nie istnieje.';

  @override
  String get wakeKindAgentNotDispatchable => 'Agent jest wycofany.';

  @override
  String get wakeKindAgentPaused => 'Agent jest wstrzymany.';

  @override
  String get wakeKindPersonRemoved =>
      'Osoba, w imieniu której działa, opuściła obszar roboczy.';

  @override
  String get wakeKindBudgetBlocked => 'Budżet blokuje uruchomienie.';

  @override
  String get wakeKindTakeOver => 'Osoba przejęła drzewo robocze.';

  @override
  String get wakeKindRateCapConversation =>
      'Ta rozmowa rozpoczęła 30 uruchomień z wybudzeń w ciągu ostatniej godziny.';

  @override
  String get wakeKindRateCapWorkspace =>
      'Ten obszar roboczy rozpoczął 300 uruchomień z wybudzeń w ciągu ostatniej godziny.';

  @override
  String get wakeKindLiveRunNoInput =>
      'Bieżące uruchomienie agenta tutaj nie przyjmuje danych wejściowych.';

  @override
  String get wakeKindLiveRunOtherOptions =>
      'Bieżące uruchomienie agenta tutaj działa inaczej, więc to uruchomi własne po nim.';

  @override
  String get wakeKindLiveRunOtherPerson =>
      'Bieżące uruchomienie agenta tutaj działa w imieniu kogoś innego, więc to uruchomi własne po nim.';

  @override
  String get wakeKindDispatchRefused => 'Uruchomienie nie mogło się rozpocząć.';

  @override
  String get wakeKindSandboxUnavailable =>
      'Brak dostępnego sandboxa dla uruchomienia tylko do odczytu.';

  @override
  String get wakeKindReadOnlyUnavailable =>
      'Backend tego agenta nie może utrzymać uruchomienia tylko do odczytu.';

  @override
  String get wakeKindServerStopped =>
      'Ponowne uruchomienie serwera zatrzymało uruchomienie.';

  @override
  String get wakeKindServerRestarted =>
      'Serwer uruchomił się ponownie podczas uruchomienia osoby.';

  @override
  String get wakeKindGuardFailed =>
      'Sprawdzenie przed dostarczeniem nie powiodło się.';

  @override
  String get wakeKindLimit => 'Czeka, aż zresetuje się limit użycia dostawcy.';

  @override
  String get wakeKindLimitRunLive =>
      'Czeka na zakończenie uruchomienia przy limicie użycia.';

  @override
  String get wakeKindWakeMissed => 'Pominięte, gdy serwer był wyłączony.';

  @override
  String get wakeKindPipelineRunEnded =>
      'Jego uruchomienie potoku się zakończyło.';

  @override
  String get wakeKindGoalEnded => 'Jego cel się zakończył.';

  @override
  String get wakeKindGoalBudgetExhausted => 'Jego cel wykorzystał budżet.';

  @override
  String get wakeKindGoalReviewStale =>
      'Cel zmienił się od czasu zgłoszenia tej recenzji.';

  @override
  String get wakeKindGoalPaused => 'Jego cel jest wstrzymany.';

  @override
  String get wakeKindGoalHeld => 'Jego cel jest na wstrzymaniu.';

  @override
  String get wakeKindGoalStopped => 'Jego cel został zatrzymany.';

  @override
  String get wakeKindAskSettled =>
      'Pytanie, na które odpowiada, zostało już rozstrzygnięte.';

  @override
  String get wakeKindRuleEnded => 'Jego harmonogram się zakończył.';

  @override
  String get wakeRefusalNotYours =>
      'To wybudzenie działa w imieniu innej osoby. Tylko ona może je dostarczyć, wznowić lub anulować.';

  @override
  String get wakeRefusalSettled => 'To wybudzenie już się rozstrzygnęło.';

  @override
  String get goalRefusalAlreadyActive => 'Ten agent ma już aktywny cel.';

  @override
  String get goalRefusalNotInReview => 'Ten cel nie czeka na recenzję.';

  @override
  String get goalRefusalEvidenceIncomplete => 'Dowody celu są niekompletne.';

  @override
  String get goalRefusalClaimPending =>
      'Twierdzenie, że cel jest gotowy, wciąż jest sprawdzane.';

  @override
  String get goalRefusalNotActiveSegment =>
      'Ten cel nie ma działającego segmentu.';

  @override
  String get goalRefusalNotYours =>
      'Tylko osoba, która rozpoczęła ten cel, może to zrobić.';

  @override
  String get goalRefusalNotPaused => 'Najpierw wstrzymaj cel.';

  @override
  String get goalRefusalContractInvalid => 'Kontraktu celu nie można odczytać.';

  @override
  String get goalRefusalCheckerUnknown => 'Nie ma agenta o tej nazwie.';

  @override
  String get goalRefusalCheckerAmbiguous =>
      'Więcej niż jeden agent ma tę nazwę.';

  @override
  String get goalRefusalCheckerIsGoalAgent =>
      'Kontroler musi być innym agentem niż ten, który wykonuje pracę.';

  @override
  String get goalRefusalCommandInvalid => 'Tego celu nie można odczytać:';

  @override
  String get wakeRuleRefusalIntervalTooShort =>
      'Interwał jest zbyt krótki. Wybierz co najmniej minutę.';

  @override
  String get wakeRuleRefusalTooSoon =>
      'Ten czas jest zbyt wcześnie. Wybierz późniejszy.';

  @override
  String get wakeRuleRefusalLineageEnded =>
      'Ten łańcuch wybudzeń wykorzystał swoje uruchomienia lub czas.';

  @override
  String get wakeRuleRefusalWatchTargetUnreadable =>
      'Nie możesz odczytać tego, co miałoby być obserwowane.';

  @override
  String get wakeRuleRefusalExpiryRequired =>
      'Podaj datę końcową albo liczbę uruchomień.';

  @override
  String get wakeRuleRefusalLimitReached =>
      'Ta rozmowa lub agent ma już tyle harmonogramów, ile może mieć.';

  @override
  String get wakeRuleRefusalInvalidWhen => 'Nie można odczytać czasu.';

  @override
  String get wakeRuleRefusalNoteTooLong => 'Notatka jest za długa.';

  @override
  String get wakeRuleRefusalExpiryTooLong => 'Koniec jest zbyt odległy.';

  @override
  String get wakeRuleRefusalLimitOutOfRange =>
      'Limit uruchomień, dni lub budżetu jest poza zakresem.';

  @override
  String get wakeRuleRefusalNextOutsideLoop =>
      'Tylko pętla może sama wybrać swój następny czas.';

  @override
  String get wakeRuleRefusalWatchRefused => 'Tego nie można obserwować.';

  @override
  String get wakeRuleRefusalRuleEnded => 'Ten harmonogram już się zakończył.';

  @override
  String get wakeRuleRefusalNotYours =>
      'Ten harmonogram należy do kogoś innego.';

  @override
  String get wakeRuleEndFired => 'Wykonał swój jeden raz.';

  @override
  String get wakeRuleEndExpired => 'Osiągnął datę końcową.';

  @override
  String get wakeRuleEndRunCap => 'Wykorzystał swoje uruchomienia.';

  @override
  String get wakeRuleEndCostCap => 'Osiągnął limit kosztów.';

  @override
  String get wakeRuleEndGoalEnded => 'Jego cel się zakończył.';

  @override
  String get wakeRuleEndCancelled => 'Został anulowany.';

  @override
  String get wakeRuleEndMemberRemoved =>
      'Osoba, do której należy, opuściła obszar roboczy.';

  @override
  String get wakeRuleEndInvalidRow =>
      'Zapisanych ustawień nie dało się odczytać.';

  @override
  String goalHoldWorking(int segment) {
    final intl.NumberFormat segmentNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String segmentString = segmentNumberFormat.format(segment);

    return 'Pracuje nad segmentem $segmentString. Nikt nie musi nic robić.';
  }

  @override
  String get goalHoldWaiting =>
      'Czeka na należną mu pracę. Kontynuuje samodzielnie.';

  @override
  String goalHoldWaitingUntil(String time) {
    return 'Czeka na należną mu pracę. Najpóźniej o $time kontynuuje samodzielnie.';
  }

  @override
  String get goalHoldVerifying =>
      'Twierdzi, że jest gotowy. Serwer uruchamia jego sprawdzenia, a potem decyduje recenzent.';

  @override
  String get goalHoldLimit =>
      'Wstrzymany przy limicie użycia dostawcy. Wznowi się samodzielnie po resecie.';

  @override
  String goalHoldLimitUntil(String time) {
    return 'Wstrzymany przy limicie użycia dostawcy. Wznowi się samodzielnie o $time.';
  }

  @override
  String get goalHoldPerson =>
      'Czeka, aż osoba odpowie w rozmowie. Kontynuuje, gdy ktoś odpowie.';

  @override
  String get goalHoldByPerson =>
      'Wstrzymany przez osobę. Pozostaje wstrzymany, dopóki ktoś go nie wznowi.';

  @override
  String get goalHoldNeedsReview =>
      'Czeka na recenzję: nie może iść dalej samodzielnie. Zatwierdź jako gotowy, wznów albo anuluj.';

  @override
  String get goalHoldBudget =>
      'Wykorzystał budżet. Podnieś budżet, aby mógł kontynuować.';

  @override
  String goalHoldLimitParks(int count, int max) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);
    final intl.NumberFormat maxNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String maxString = maxNumberFormat.format(max);

    return 'Wstrzymania przy limicie użycia: $countString z $maxString';
  }

  @override
  String get goalHoldDetailStalled => 'Brak postępu w ostatnich segmentach.';

  @override
  String get goalHoldDetailStalledWaiting =>
      'Czekał 24 godziny na tę samą pracę bez postępu.';

  @override
  String get goalHoldDetailVerificationFailed =>
      'Ostatnie sprawdzenie się nie powiodło.';

  @override
  String get goalHoldDetailCannotVerify =>
      'Kontroler nie potrafił ocenić, czy cel jest gotowy.';

  @override
  String get goalHoldDetailSandboxUnavailable =>
      'Brak dostępnego sandboxa do uruchomienia jego sprawdzeń.';

  @override
  String get goalHoldDetailCheckerUnavailable =>
      'Jego agent kontrolujący jest niedostępny. Wybierz innego kontrolera, potem wznów.';

  @override
  String get goalHoldDetailCheckBroken =>
      'To sprawdzenie nie może się uruchomić:';

  @override
  String get goalHoldDetailWakeSkipped =>
      'Jego wybudzenie nie zostało dostarczone.';

  @override
  String get goalHoldDetailClaimPending =>
      'Jego twierdzenie, że jest gotowy, czeka na sprawdzenie.';

  @override
  String get goalHoldDetailUnanswered =>
      'Pytanie albo prośba o zatwierdzenie skierowane do osoby pozostały bez odpowiedzi.';

  @override
  String get goalHoldDetailLimitParks =>
      'Zbyt często trafiał na limity użycia. Przejrzyj go, potem wznów.';

  @override
  String get goalHoldDetailInput => 'Czeka na odpowiedź w rozmowie.';

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
    return 'Wydano $spent z $cap';
  }

  @override
  String goalDeadline(String time) {
    return 'Termin $time';
  }

  @override
  String get goalPipelineStep => 'Ten cel realizuje krok potoku.';

  @override
  String get goalSummaryHeading => 'Ostatnie podsumowanie';

  @override
  String get goalDoneMeans => 'Gotowe oznacza';

  @override
  String get goalChecks => 'Sprawdzenia';

  @override
  String get goalBoundaries => 'Granice';

  @override
  String get goalStopWhen => 'Zatrzymaj się i zapytaj, gdy';

  @override
  String get goalNoMachineCheck =>
      'Brak automatycznego sprawdzenia. Recenzent ocenia na podstawie tego, co może odczytać.';

  @override
  String get goalCheckEnvironment => 'Zadanie środowiska';

  @override
  String goalLastCheck(int round, String time) {
    final intl.NumberFormat roundNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String roundString = roundNumberFormat.format(round);

    return 'Ostatnie sprawdzenie, runda $roundString, $time';
  }

  @override
  String get goalClaim => 'Co twierdził';

  @override
  String get goalCheckPassed => 'Zaliczone';

  @override
  String goalCheckFailed(int code) {
    return 'Niezaliczone, kod $code';
  }

  @override
  String get goalCheckTimedOut => 'Przekroczono limit czasu';

  @override
  String get goalCheckNotRerun =>
      'Nie uruchomiono ponownie: nic się nie zmieniło';

  @override
  String get goalCheckBroken => 'Nie można uruchomić';

  @override
  String get goalCriterionMet => 'Spełnione';

  @override
  String get goalCriterionUnmet => 'Niespełnione';

  @override
  String get goalCriterionCannotTell => 'Nie wiadomo';

  @override
  String get goalVerdictPass => 'Werdykt: gotowe';

  @override
  String get goalVerdictFail => 'Werdykt: nie gotowe';

  @override
  String get goalVerdictCannotVerify => 'Werdykt: nie udało się ocenić';

  @override
  String get goalConcerns => 'Zastrzeżenia';

  @override
  String goalVerifiedBy(String agent) {
    return 'Zweryfikował $agent';
  }

  @override
  String get goalVerifiedBySelf => 'Zweryfikował sam (bez osobnego kontrolera)';

  @override
  String get goalClosedByPerson =>
      'Zamknięte przez osobę bez zaliczonego sprawdzenia';

  @override
  String get goalApprove => 'Zatwierdź ukończenie';

  @override
  String get goalApproveTitle => 'Zamknąć ten cel jako gotowy?';

  @override
  String get goalApproveBody =>
      'Nic tego nie potwierdziło. Zamykasz go na własne słowo, a cel zapisze, że osoba zamknęła go bez weryfikacji.';

  @override
  String get goalApproveConfirm => 'Zamknij jako gotowy';

  @override
  String get goalResumeNotYours =>
      'Wznowienie go lub podniesienie jego budżetu należy do osoby, która go rozpoczęła.';

  @override
  String get goalChooseChecker => 'Wybierz innego kontrolera';

  @override
  String goalCheckerSet(String agent) {
    return 'Sprawdza go teraz $agent. Wznów, aby zweryfikować ponownie.';
  }

  @override
  String get goalSchedules => 'Harmonogramy';

  @override
  String get goalRepeat => 'Powtarzaj';

  @override
  String get goalCreateChecks => 'Sprawdzenia (opcjonalnie)';

  @override
  String get goalCreateCheckHint =>
      'Polecenie, które przechodzi, gdy praca jest gotowa';

  @override
  String get goalCreateAddCheck => 'Dodaj sprawdzenie';

  @override
  String get goalCreateRemoveCheck => 'Usuń sprawdzenie';

  @override
  String get goalCreateSegmentCap => 'Limit segmentów (opcjonalnie)';

  @override
  String get goalCreateSegmentInvalid =>
      'Limit segmentów to liczba całkowita, co najmniej 1.';

  @override
  String get scheduleCreateTitle => 'Powtarzaj polecenie';

  @override
  String get scheduleCadence => 'Jak często';

  @override
  String get scheduleEveryMinutes => 'Co N minut';

  @override
  String get scheduleEveryHours => 'Co N godzin';

  @override
  String get scheduleSelfPaced => 'Samodzielnie';

  @override
  String get scheduleSelfPacedHint =>
      'Agent wybiera opóźnienie po każdym uruchomieniu, między 1 minutą a 1 godziną.';

  @override
  String get scheduleInterval => 'Interwał';

  @override
  String get scheduleNote => 'Co ma robić każde uruchomienie?';

  @override
  String get scheduleCostCap => 'Limit kosztów w USD (opcjonalnie)';

  @override
  String get scheduleExpiryDays => 'Kończy się po N dniach (opcjonalnie)';

  @override
  String get scheduleCreateInvalid =>
      'Wybierz przestrzeń i agenta, napisz, co ma robić każde uruchomienie, i podaj liczby całkowite co najmniej 1.';

  @override
  String get scheduleCreateButton => 'Rozpocznij harmonogram';

  @override
  String get scheduleCreateConfirmTitle => 'Rozpocząć ten harmonogram?';

  @override
  String scheduleCreateConfirmEveryMinutes(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Uruchamia się co $countString minut, od teraz.',
      many: 'Uruchamia się co $countString minut, od teraz.',
      few: 'Uruchamia się co $countString minuty, od teraz.',
      one: 'Uruchamia się co minutę, od teraz.',
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
      other: 'Uruchamia się co $countString godzin, od teraz.',
      many: 'Uruchamia się co $countString godzin, od teraz.',
      few: 'Uruchamia się co $countString godziny, od teraz.',
      one: 'Uruchamia się co godzinę, od teraz.',
    );
    return '$_temp0';
  }

  @override
  String get scheduleCreateConfirmSelfPaced =>
      'Uruchamia się teraz, potem agent wybiera, kiedy uruchomić się ponownie.';

  @override
  String get scheduleCreated =>
      'Harmonogram rozpoczęty. Jest na liście w sekcji Harmonogramy.';

  @override
  String get schedulesTitle => 'Harmonogramy';

  @override
  String get schedulesLoadFailed => 'Nie udało się wczytać harmonogramów';

  @override
  String get schedulesEmpty => 'Brak harmonogramów i obserwacji';

  @override
  String get schedulesEmptyDescription =>
      'Powtórz polecenie z ekranu celów albo wyślij /loop lub /schedule w rozmowie.';

  @override
  String get scheduleMissing =>
      'Ten harmonogram nie jest już dostępny w tym obszarze roboczym.';

  @override
  String scheduleEvery(String interval) {
    return 'Co $interval';
  }

  @override
  String get scheduleSelfPacedLoop => 'Pętla samodzielna';

  @override
  String get scheduleCron => 'Harmonogram cron';

  @override
  String scheduleOnce(String time) {
    return 'Raz, o $time';
  }

  @override
  String scheduleWatch(String event) {
    return 'Obserwacja: $event';
  }

  @override
  String get scheduleWatchPrChecks => 'sprawdzenia pull requesta';

  @override
  String get scheduleWatchPrReview => 'recenzje pull requesta';

  @override
  String get scheduleWatchPrMerged => 'scalenie pull requesta';

  @override
  String get scheduleWatchEnvironment => 'środowisko';

  @override
  String get scheduleWatchTicket => 'zgłoszenie';

  @override
  String get scheduleWatchPipelineRun => 'uruchomienie potoku';

  @override
  String get scheduleStatusActive => 'Aktywny';

  @override
  String get scheduleStatusPaused => 'Wstrzymany';

  @override
  String get scheduleStatusEnded => 'Zakończony';

  @override
  String scheduleWakes(String agent) {
    return 'Wybudza $agent';
  }

  @override
  String scheduleNext(String time) {
    return 'Następne uruchomienie $time';
  }

  @override
  String scheduleLast(String time) {
    return 'Ostatnie uruchomienie $time';
  }

  @override
  String scheduleRuns(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString uruchomień',
      many: '$countString uruchomień',
      few: '$countString uruchomienia',
      one: '1 uruchomienie',
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

    return '$countString z $maxString uruchomień';
  }

  @override
  String scheduleSkipped(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Pominięte: $countString',
      many: 'Pominięte: $countString',
      few: 'Pominięte: $countString',
      one: 'Pominięte: 1',
    );
    return '$_temp0';
  }

  @override
  String scheduleEnds(String time) {
    return 'Kończy się $time';
  }

  @override
  String scheduleChain(int count, String time) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Część łańcucha: pozostało $countString uruchomień, kończy się $time';
  }

  @override
  String get scheduleNoteAgent => 'Notatka agenta, własnymi słowami:';

  @override
  String get scheduleNotePerson => 'Notatka osoby:';

  @override
  String scheduleActsFor(String name) {
    return 'Działa w imieniu: $name';
  }

  @override
  String get scheduleActsForBot => 'Nie działa w imieniu żadnej osoby';

  @override
  String get scheduleGoalBound => 'Kończy się razem z celem.';

  @override
  String get schedulePause => 'Wstrzymaj';

  @override
  String get scheduleResume => 'Wznów';

  @override
  String get scheduleDelete => 'Zakończ';

  @override
  String get scheduleRemove => 'Usuń';

  @override
  String get scheduleDeleteTitle => 'Zakończyć ten harmonogram?';

  @override
  String get scheduleDeleteBody =>
      'Zatrzymuje się na stałe. Nic z tego, co już zrobił, nie jest cofane.';

  @override
  String get scheduleRemoveTitle => 'Usunąć ten harmonogram?';

  @override
  String get scheduleRemoveBody => 'Znika z listy.';

  @override
  String get scheduleResumeNotYours =>
      'Wznowić go może tylko osoba, w imieniu której działa ten harmonogram.';

  @override
  String get scheduleResumeAdminOnly =>
      'Wznowić harmonogram, którego nie posiada żadna osoba, może tylko administrator obszaru roboczego.';

  @override
  String get scheduleOpenConversation => 'Otwórz rozmowę';

  @override
  String get progressWaiting => 'Oczekujące';

  @override
  String get progressNothingWaiting => 'Nic nie czeka.';

  @override
  String get wakeOriginGoal => 'Cel';

  @override
  String get wakeOriginGoalCheck => 'Sprawdzenie celu';

  @override
  String get wakeOriginGoalReview => 'Recenzja celu';

  @override
  String get wakeOriginSchedule => 'Harmonogram';

  @override
  String get wakeOriginWatch => 'Obserwacja';

  @override
  String get wakeOriginReply => 'Odpowiedź';

  @override
  String get wakeOriginMessage => 'Wiadomość';

  @override
  String get wakeOriginWorkFinished => 'Zakończona praca';

  @override
  String get wakeOriginLimitReset => 'Reset limitu';

  @override
  String get wakeOriginRecovery => 'Odzyskanie';

  @override
  String get wakeOriginAssignment => 'Przydział';

  @override
  String get wakeOriginPipelineStep => 'Krok potoku';

  @override
  String get wakeOriginImprovementReview => 'Recenzja usprawnień';

  @override
  String wakeOriginReplyFrom(String agent) {
    return 'Odpowiedź od $agent';
  }

  @override
  String wakeOriginMessageFrom(String agent) {
    return 'Wiadomość od $agent';
  }

  @override
  String wakeOriginWorkFinishedBy(String agent) {
    return 'Zakończona praca od $agent';
  }

  @override
  String wakeFor(String agent) {
    return 'Dla $agent';
  }

  @override
  String wakeDue(String time) {
    return 'Termin $time';
  }

  @override
  String get wakeDueNow => 'Do wykonania teraz';

  @override
  String get wakeHeld => 'Wstrzymane';

  @override
  String wakeExpires(String time) {
    return 'Wygasa $time';
  }

  @override
  String wakeAttempt(int attempt) {
    final intl.NumberFormat attemptNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String attemptString = attemptNumberFormat.format(attempt);

    return 'Próba $attemptString';
  }

  @override
  String get wakeCancel => 'Anuluj';

  @override
  String get wakeDeliverNow => 'Dostarcz teraz';

  @override
  String get wakeResume => 'Wznów';

  @override
  String get wakeDismiss => 'Odrzuć';

  @override
  String get wakeResumeOnlyTheirs =>
      'Wznowić je może tylko osoba, której to uruchomienie jest.';

  @override
  String get wakeRecovery =>
      'Serwer uruchomił się ponownie podczas tego uruchomienia. Wznów, aby je kontynuować, albo odrzuć.';

  @override
  String limitParkTitle(String provider, String time) {
    return 'Wstrzymano z powodu limitu użycia u $provider, który zostanie zresetowany o $time. Uruchomienie czeka na Wznów, przez maksymalnie 7 dni od resetu.';
  }

  @override
  String limitParkTitleUnnamed(String time) {
    return 'Wstrzymano z powodu limitu użycia u dostawcy, który zostanie zresetowany o $time. Uruchomienie czeka na Wznów, przez maksymalnie 7 dni od resetu.';
  }

  @override
  String get limitParkResumeNow => 'Wznów teraz';

  @override
  String get limitParkCancel => 'Anuluj';

  @override
  String limitParkResumed(String provider) {
    return 'Wznowiono po limicie użycia u $provider.';
  }

  @override
  String limitParkGone(String provider) {
    return 'Już nie czeka na limit użycia u $provider.';
  }

  @override
  String get limitParkProviderUnknown => 'dostawcy';

  @override
  String get mobileHeldMessages => 'Wstrzymane wiadomości';

  @override
  String get heldSteeringTitle =>
      'Wstrzymane, bo uruchomienie zakończyło się, zanim mogło je przyjąć. Wyślij swoje teraz albo je usuń.';

  @override
  String get heldSteeringRelease => 'Wyślij wstrzymane wiadomości';

  @override
  String get notifGoalCompleted => 'Cel gotowy';

  @override
  String get notifGoalFailed => 'Cel nie powiódł się';

  @override
  String get notifGoalCancelled => 'Cel anulowany';

  @override
  String get notifGoalBudgetExhausted => 'Cel wykorzystał budżet';

  @override
  String get notifGoalNeedsReview => 'Cel czeka na recenzję';

  @override
  String get notifGoalNeedsPerson => 'Cel potrzebuje osoby';

  @override
  String get notifGoalOnHold => 'Cel jest na wstrzymaniu';

  @override
  String get notifWakeRuleEnded => 'Harmonogram się zakończył';

  @override
  String notifWaitingDigest(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString rzeczy czeka na Ciebie',
      many: '$countString rzeczy czeka na Ciebie',
      few: '$countString rzeczy czekają na Ciebie',
      one: '1 rzecz czeka na Ciebie',
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
      other: 'Zaproponowano $countString usprawnień',
      many: 'Zaproponowano $countString usprawnień',
      few: 'Zaproponowano $countString usprawnienia',
      one: 'Zaproponowano usprawnienie',
    );
    return '$_temp0';
  }

  @override
  String get notifPipelineRunHeld =>
      'Uruchomienie potoku wstrzymane na budżecie';

  @override
  String notifPipelineRunHeldBody(String spent, String cap) {
    return 'Wydano $spent z $cap';
  }

  @override
  String get notifNeedsYou => 'Wymaga Twojej uwagi';

  @override
  String get notifDigestGoalReview => 'Cel czeka na recenzję';

  @override
  String get notifDigestGoalPerson => 'Cel potrzebuje osoby';

  @override
  String get notifDigestHeldWake => 'Wstrzymane wybudzenie';

  @override
  String get notifDigestImprovement => 'Zaproponowane usprawnienie';

  @override
  String get wakeKindRulePaused => 'Jego harmonogram został wstrzymany.';

  @override
  String get wakeKindRuleBusy =>
      'Agent był zajęty, a ten harmonogram pomija takie momenty.';

  @override
  String get wakeKindRuleFolded =>
      'Zastąpiło go późniejsze zdarzenie tej samej obserwacji.';

  @override
  String get wakeKindRuleSuperseded =>
      'Zastąpił go późniejszy czas jego harmonogramu.';

  @override
  String get wakeKindRuleNotified =>
      'Jego harmonogram tylko wysyła powiadomienie, więc żadne uruchomienie nie wystartowało.';

  @override
  String get wakeKindRuleLimitParked =>
      'Jego harmonogram czeka, aż dostawca zresetuje limit użycia.';

  @override
  String get improvementRefusalCooldown =>
      'Recenzja usprawnień tej rozmowy odbyła się niedawno. Spróbuj ponownie później.';

  @override
  String get improvementRefusalQueued =>
      'Recenzja usprawnień tej rozmowy już czeka na uruchomienie.';

  @override
  String get improvementRefusalAgentNotFound =>
      'Ten agent nie jest agentem tego obszaru roboczego.';

  @override
  String get steeringRefusalHeldByLimit =>
      'Wiadomości wstrzymane przy limicie użycia nie mogą być wysłane ręcznie. Czekają, aż wstrzymane uruchomienie się wznowi.';

  @override
  String limitParkCancelled(String provider) {
    return 'Oczekiwanie na limit użycia u $provider zostało anulowane.';
  }

  @override
  String limitParkExpired(String provider) {
    return 'Oczekiwanie na limit użycia u $provider wygasło, zanim uruchomienie wznowiono.';
  }

  @override
  String limitParkSkipped(String provider) {
    return 'Uruchomienie nie wznowiło się po limicie użycia u $provider.';
  }

  @override
  String get heldSteeringLimitTitle =>
      'Wstrzymane, dopóki uruchomienie czeka na zresetowanie limitu użycia. Zostaną wysłane, gdy osoba, dla której działa uruchomienie, je wznowi.';

  @override
  String heldSteeringLimitAt(String time) {
    return 'Wstrzymane do zresetowania limitu użycia o $time. Zostaną wysłane, gdy osoba, dla której działa uruchomienie, je wznowi.';
  }

  @override
  String get heldSteeringOtherTitle =>
      'Wstrzymane przez serwer. Możesz je usunąć.';

  @override
  String workRowWoke(int count, String agent) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Wybudzono $agent dla $countString oczekujących pozycji',
      many: 'Wybudzono $agent dla $countString oczekujących pozycji',
      few: 'Wybudzono $agent dla $countString oczekujących pozycji',
      one: 'Wybudzono $agent',
    );
    return '$_temp0';
  }

  @override
  String workRowWakeMissed(String agent) {
    return 'Wybudzenie dla $agent zostało pominięte, gdy serwer był wyłączony.';
  }

  @override
  String workRowWakeSkipped(String agent) {
    return 'Wybudzenie dla $agent nie zostało dostarczone.';
  }

  @override
  String workRowScheduleCreated(String agent) {
    return 'Ustawiono harmonogram dla $agent.';
  }

  @override
  String workRowScheduleEnded(String agent) {
    return 'Harmonogram dla $agent się zakończył.';
  }

  @override
  String workRowNoteFromAgent(String agent) {
    return 'Notatka do harmonogramu od $agent:';
  }

  @override
  String get workRowNoteFromPerson => 'Notatka do harmonogramu od osoby:';

  @override
  String workRowCommandRefusedNamed(String command) {
    return 'Polecenie $command zostało odrzucone.';
  }

  @override
  String get workRowCommandRefused => 'Polecenie zostało odrzucone.';

  @override
  String workRowCapRaised(String person, String from, String to) {
    return '$person podniósł limit wydatków potoku z $from do $to.';
  }

  @override
  String workRowCapRaisedNoAmounts(String person) {
    return '$person podniósł limit wydatków potoku.';
  }

  @override
  String get workRowApplyIncomplete =>
      'Zaakceptowanej zmiany tej umiejętności nie udało się dokończyć, bo umiejętność zmieniła się w międzyczasie. Propozycję cofnięto.';

  @override
  String get workRowOpenSchedule => 'Otwórz harmonogram';

  @override
  String get heldSteeringOthersTitle =>
      'Wstrzymane, bo uruchomienie zakończyło się, zanim mogło je przyjąć. Wysłać wiadomość może tylko osoba, która ją napisała.';

  @override
  String get heldSteeringOnlyYours =>
      'Wysyła tylko Twoje wiadomości. Pozostałe czekają na ich autorów.';

  @override
  String heldSteeringWrittenBy(String name) {
    return 'Napisana przez $name';
  }

  @override
  String get steeringRefusalNotYours =>
      'Wysłać wstrzymaną wiadomość może tylko osoba, która ją napisała, a żadna z tych nie jest Twoja.';

  @override
  String get steeringRefusalNeedsWrite =>
      'Aby kierować uruchomieniem działającym w imieniu innej osoby, potrzebujesz dostępu do zapisu do repozytoriów tej przestrzeni.';

  @override
  String workRowSchedulePaused(String name, String agent) {
    return 'Harmonogram agenta $agent został wstrzymany przez $name.';
  }

  @override
  String get goalVerdictObjective => 'Zadanie jako całość';

  @override
  String get notifDigestRequest => 'Czeka na twoją odpowiedź';
}
