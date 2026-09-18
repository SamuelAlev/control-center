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
      'Zeskanuj kod QR z Twojego Mac, aby sparować ten telefon.';

  @override
  String get scanQrHelp =>
      'Otwórz aparat i skieruj go na QR wyświetlony w Control Center na Twoim Mac. Ten telefon łączy się bezpośrednio z Twoim Mac przez prywatne łącze.';

  @override
  String get connectingToMac => 'Łączenie z Twoim Mac…';

  @override
  String get connectingDetail =>
      'Nawiązywanie bezpiecznego, bezpośredniego łącza.';

  @override
  String get identityChangedTitle => 'Tożsamość serwera się zmieniła';

  @override
  String get identityChangedBody =>
      'Ten serwer nie pasuje już do tożsamości zapisanej przy parowaniu. To może oznaczać, że serwer został zainstalowany ponownie — albo że coś przechwytuje połączenie. Dla bezpieczeństwa to urządzenie się nie połączy. Usuń parowanie, a następnie zeskanuj nowy kod QR z Twojego Mac, aby sparować ponownie.';

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
      'Brak parowania — zeskanuj kod QR z Twojego Mac';

  @override
  String get failureUnreachable =>
      'Nie udało się dotrzeć do serwera żadną ścieżką — sprawdź, czy działa, albo spróbuj w tej samej sieci';

  @override
  String get failureIdentityChanged =>
      'Tożsamość serwera się zmieniła — jeśli został zainstalowany ponownie, sparuj to urządzenie ponownie';

  @override
  String get failureAuthRejected =>
      'Serwer odrzucił to urządzenie — sparuj je ponownie z Twojego Mac';

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
      'Stuknij ponownie, aby odłączyć to urządzenie od Twojego Mac';

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
  String get inboxNoForgeAccount =>
      'Na serwerze nie połączono konta forge, więc pull requesty nie mogą być jeszcze przypisane do Ciebie.';

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
  String attachmentsTooLargeRelay(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$names są za duże, aby wysłać je stąd przez przekaźnik.',
      one: '$names jest za duży, aby wysłać go stąd przez przekaźnik.',
    );
    return '$_temp0';
  }

  @override
  String get attachmentUploadFailed =>
      'Nie udało się przesłać załącznika. Spróbuj ponownie.';

  @override
  String attachmentsLeftOut(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count załączników nie zostało przesłanych i zostało pominiętych.',
      one: '1 załącznik nie został przesłany i został pominięty.',
    );
    return '$_temp0';
  }

  @override
  String get teammate => 'Współpracownik';

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
  String reposUnreadable(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Nie udało się odczytać $count repo.',
      one: 'Nie udało się odczytać 1 repo.',
    );
    return '$_temp0';
  }

  @override
  String reposNotReadable(String names) {
    return 'Nieczytelne: $names';
  }

  @override
  String get installationSuspendedTitle =>
      'Instalacja GitHub App została wstrzymana';

  @override
  String installationSuspendedBody(String names) {
    return 'Wyświetlane są ostatnio znane dane dla $names. Wznów instalację na GitHubie albo podłącz token z dostępem.';
  }

  @override
  String installationSuspendedNotice(String names) {
    return 'Instalacja GitHub App została wstrzymana. Wyświetlane są ostatnio znane dane dla $names. Wznów instalację na GitHubie albo podłącz token z dostępem.';
  }

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
}
